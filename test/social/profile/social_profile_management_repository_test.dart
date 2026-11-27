import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_draft.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_management_repository.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared_core/authentication/foundation_fakes.dart';

const _originalToken = 'fake.a.original';
const _rotatedToken = 'fake.a.rotated';

AppConfig _config([String origin = 'https://andril.invalid:8443/']) =>
    AppConfig.fromValues(
      environment: 'development',
      supabaseUrl: 'https://synthetic.supabase.co',
      publicKey: 'sb_publishable_synthetic',
      apiBaseUrl: origin,
    );

const _validProfileJson = {
  'profileId': 'prof_123',
  'module': 'social',
  'createdAtUtc': '2026-11-26T12:00:00Z',
  'displayName': 'ElenaR',
  'bio': 'Photographer and traveler',
  'visibility': 'private',
  'isComplete': false,
  'blockingDependency': 'approved_profile_contract',
};

ResponseBody _response(
  int status,
  Object? payload, {
  String type = 'application/json',
  Map<String, List<String>> extra = const {},
}) =>
    ResponseBody.fromString(
      payload == null ? '' : jsonEncode(payload),
      status,
      headers: {
        'content-type': [type],
        ...extra,
      },
    );

ResponseBody _problem(int status, String title) =>
    _response(status, {'status': status, 'title': title},
        type: 'application/problem+json');

class _TestBackendSource extends FakeSessionSource implements BackendSessionSource {
  _TestBackendSource({bool recovery = false})
      : super(
          restored: const SessionEvent(SessionEventKind.initial, subject: 'user-a'),
        ) {
    restoredRecovery = recovery;
  }

  @override
  BackendCredential? backendCredential =
      const BackendCredential('user-a', _originalToken, emailConfirmed: true);
  int refreshes = 0;
  Future<void> Function()? onRefresh;

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {
    refreshes++;
    await onRefresh?.call();
  }

  void token(String value, {bool notify = true}) {
    backendCredential = BackendCredential('user-a', value, emailConfirmed: true);
    if (notify) {
      signals.add(const SessionEvent(SessionEventKind.refreshed, subject: 'user-a'));
    }
  }

  void logout() {
    backendCredential = null;
    signals.add(const SessionEvent(SessionEventKind.signedOut));
  }

  void switchUser(String newSubject, String newToken) {
    backendCredential =
        BackendCredential(newSubject, newToken, emailConfirmed: true);
    signals.add(SessionEvent(SessionEventKind.signedIn, subject: newSubject));
  }
}

class _TestTransport implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  late FutureOr<ResponseBody> Function(RequestOptions) reply;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

Future<
    ({
      _TestBackendSource source,
      SessionController session,
      _TestTransport transport,
      SocialProfileManagementRepository repo,
    })> _setup({
  bool recovery = false,
  AppConfig? config,
  SocialProfileRepository? innerRepository,
}) async {
  final source = _TestBackendSource(recovery: recovery);
  final session = SessionController(source);
  final transport = _TestTransport();
  final repo = SocialProfileManagementRepository(
    sessionController: session,
    config: config ?? _config(),
    adapter: transport,
    innerRepository: innerRepository,
  );
  await session.start();
  addTearDown(() async {
    repo.dispose();
    session.dispose();
    await source.signals.close();
  });
  return (source: source, session: session, transport: transport, repo: repo);
}

void main() {
  group('SocialProfileManagementRepository (Task 152)', () {
    group('getProfile', () {
      test('sends GET to configured origin with bearer token and decodes profile', () async {
        final f = await _setup();
        f.transport.reply = (_) => _response(200, _validProfileJson);

        final result = await f.repo.getProfile();

        expect(result, isA<SocialProfileSuccess>());
        final draft = (result as SocialProfileSuccess).draft;
        expect(draft.displayName, 'ElenaR');
        expect(draft.bio, 'Photographer and traveler');
        expect(draft.visibility, 'private');

        expect(f.transport.calls.length, 1);
        final call = f.transport.calls.single;
        expect(call.method, 'GET');
        expect(call.uri.origin, 'https://andril.invalid:8443');
        expect(call.uri.path, '/api/v1/account/profiles/social');
        expect(call.headers['Authorization'], 'Bearer $_originalToken');
        expect(call.headers['Accept'], contains('application/json'));
        expect(call.followRedirects, isFalse);
        expect(call.maxRedirects, 0);
      });

      test('profile with null displayName defaults to empty string', () async {
        final f = await _setup();
        f.transport.reply = (_) => _response(200, {
              ..._validProfileJson,
              'displayName': null,
            });

        final result = await f.repo.getProfile();

        expect(result, isA<SocialProfileSuccess>());
        final draft = (result as SocialProfileSuccess).draft;
        expect(draft.displayName, '');
        expect(draft.bio, 'Photographer and traveler');
      });

      test('profile with null bio preserves null', () async {
        final f = await _setup();
        f.transport.reply = (_) => _response(200, {
              ..._validProfileJson,
              'bio': null,
            });

        final result = await f.repo.getProfile();

        expect(result, isA<SocialProfileSuccess>());
        final draft = (result as SocialProfileSuccess).draft;
        expect(draft.displayName, 'ElenaR');
        expect(draft.bio, isNull);
      });

      test('400 bad request returns validationFailure', () async {
        final f = await _setup();
        f.transport.reply = (_) => _problem(400, 'Invalid request structure');

        final result = await f.repo.getProfile();

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.type, SocialProfileFailureType.validationFailure);
      });

      test('401 triggers token refresh once and replays GET', () async {
        final f = await _setup();
        var callCount = 0;
        f.source.onRefresh = () async {
          f.source.token(_rotatedToken, notify: false);
        };
        f.transport.reply = (opts) {
          callCount++;
          if (callCount == 1) {
            return _response(401, null);
          }
          return _response(200, _validProfileJson);
        };

        final result = await f.repo.getProfile();

        expect(result, isA<SocialProfileSuccess>());
        expect(callCount, 2);
        expect(f.source.refreshes, 1);
        expect(f.transport.calls[0].headers['Authorization'], 'Bearer $_originalToken');
        expect(f.transport.calls[1].headers['Authorization'], 'Bearer $_rotatedToken');
      });

      test('403 forbidden returns authorizationDenied', () async {
        final f = await _setup();
        f.transport.reply = (_) => _problem(403, 'Forbidden');

        final result = await f.repo.getProfile();

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.type, SocialProfileFailureType.authorizationDenied);
      });

      test('404 profile not found returns dependencyFailure with explicit message', () async {
        final f = await _setup();
        f.transport.reply = (_) => _problem(404, 'Profile Not Found');

        final result = await f.repo.getProfile();

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.type, SocialProfileFailureType.dependencyFailure);
        expect(err.failure.message, 'Private Social profile not found.');
      });

      test('429 rate limited returns dependencyFailure with retry after message', () async {
        final f = await _setup();
        f.transport.reply = (_) => _response(429, null, extra: {
              'retry-after': ['30']
            });

        final result = await f.repo.getProfile();

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.type, SocialProfileFailureType.dependencyFailure);
        expect(err.failure.message, contains('30 seconds'));
      });

      test('503 service unavailable maps to dependencyFailure', () async {
        final f = await _setup();
        f.transport.reply = (_) => _response(503, null);

        final result = await f.repo.getProfile();

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.type, SocialProfileFailureType.dependencyFailure);
      });

      test('malformed payload maps safely to unknown failure', () async {
        final f = await _setup();
        f.transport.reply = (_) => ResponseBody.fromString(
              'not-valid-json',
              200,
              headers: {
                'content-type': ['application/json']
              },
            );

        final result = await f.repo.getProfile();

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.type, SocialProfileFailureType.unknown);
      });

      test('session change during inflight GET discards late response and returns sessionExpired', () async {
        final f = await _setup();
        final completer = Completer<ResponseBody>();
        f.transport.reply = (_) => completer.future;

        final futureResult = f.repo.getProfile();

        f.source.switchUser('user-b', 'fake.b.token');
        completer.complete(_response(200, _validProfileJson));

        final result = await futureResult;

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.type, SocialProfileFailureType.sessionExpired);
      });
    });

    group('updateProfile', () {
      test('sends PUT to configured origin with exact payload {displayName, bio, visibility}', () async {
        final f = await _setup();
        f.transport.reply = (opts) {
          final body = jsonDecode(opts.data as String) as Map<String, dynamic>;
          expect(body['displayName'], 'ElenaUpdated');
          expect(body['bio'], 'New bio description');
          expect(body['visibility'], 'private');
          expect(body.containsKey('profilePhotoPath'), isFalse);
          return _response(200, {
            ..._validProfileJson,
            'displayName': body['displayName'],
            'bio': body['bio'],
          });
        };

        const draftToSave = SocialProfileDraft(
          displayName: 'ElenaUpdated',
          bio: 'New bio description',
          profilePhotoPath: 'local/path/ignore.jpg',
        );

        final result = await f.repo.updateProfile(draftToSave);

        expect(result, isA<SocialProfileSuccess>());
        final saved = (result as SocialProfileSuccess).draft;
        expect(saved.displayName, 'ElenaUpdated');
        expect(saved.bio, 'New bio description');
        expect(saved.visibility, 'private');

        expect(f.transport.calls.length, 1);
        final call = f.transport.calls.single;
        expect(call.method, 'PUT');
        expect(call.uri.path, '/api/v1/account/profiles/social');
        expect(call.headers['Authorization'], 'Bearer $_originalToken');
        expect(call.headers['Content-Type'], contains('application/json'));
      });

      test('preserves null bio in PUT payload', () async {
        final f = await _setup();
        f.transport.reply = (opts) {
          final body = jsonDecode(opts.data as String) as Map<String, dynamic>;
          expect(body['displayName'], 'ElenaUpdated');
          expect(body['bio'], isNull);
          expect(body['visibility'], 'private');
          return _response(200, {
            ..._validProfileJson,
            'displayName': body['displayName'],
            'bio': null,
          });
        };

        const draftToSave = SocialProfileDraft(
          displayName: 'ElenaUpdated',
          bio: null,
        );

        final result = await f.repo.updateProfile(draftToSave);

        expect(result, isA<SocialProfileSuccess>());
        final saved = (result as SocialProfileSuccess).draft;
        expect(saved.displayName, 'ElenaUpdated');
        expect(saved.bio, isNull);
      });

      test('409 display name unavailable maps to displayNameUnavailable failure', () async {
        final f = await _setup();
        f.transport.reply = (_) => _problem(409, 'Display name already taken');

        const draftToSave = SocialProfileDraft(displayName: 'TakenName');
        final result = await f.repo.updateProfile(draftToSave);

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.type, SocialProfileFailureType.displayNameUnavailable);
      });

      test('400 bad request on update maps to validationFailure', () async {
        final f = await _setup();
        f.transport.reply = (_) => _problem(400, 'Display name contains invalid characters');

        const draftToSave = SocialProfileDraft(displayName: 'Invalid*Name');
        final result = await f.repo.updateProfile(draftToSave);

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.type, SocialProfileFailureType.validationFailure);
      });

      test('404 missing profile on update maps to dependencyFailure', () async {
        final f = await _setup();
        f.transport.reply = (_) => _problem(404, 'Profile Not Found');

        const draftToSave = SocialProfileDraft(displayName: 'Elena');
        final result = await f.repo.updateProfile(draftToSave);

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.type, SocialProfileFailureType.dependencyFailure);
        expect(err.failure.message, 'Private Social profile not found.');
      });

      test('session change during inflight PUT discards late response', () async {
        final f = await _setup();
        final completer = Completer<ResponseBody>();
        f.transport.reply = (_) => completer.future;

        const draftToSave = SocialProfileDraft(displayName: 'Elena');
        final futureResult = f.repo.updateProfile(draftToSave);

        f.source.switchUser('user-b', 'fake.b.token');
        completer.complete(_response(200, _validProfileJson));

        final result = await futureResult;

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.type, SocialProfileFailureType.sessionExpired);
      });
    });

    group('security and safeguards', () {
      test('unconfigured config fails closed with dependencyFailure', () async {
        final source = _TestBackendSource();
        final session = SessionController(source);
        await session.start();
        addTearDown(() async {
          session.dispose();
          await source.signals.close();
        });

        final unconfiguredRepo = SocialProfileManagementRepository(
          sessionController: session,
        );

        final result = await unconfiguredRepo.getProfile();

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.type, SocialProfileFailureType.dependencyFailure);
        expect(err.failure.message, contains('not configured'));
      });

      test('does not follow redirects (301, 307, 308) and fails closed', () async {
        for (final code in [301, 307, 308]) {
          final f = await _setup();
          f.transport.reply = (_) => _response(code, null, extra: {
                'location': ['https://external-leak.invalid/profile']
              });

          final result = await f.repo.getProfile();

          expect(result, isA<SocialProfileError>());
          expect(f.transport.calls.length, 1);
          expect(f.transport.calls.single.uri.origin, 'https://andril.invalid:8443');
        }
      });

      test('errors never disclose credentials or sensitive payloads', () async {
        final f = await _setup();
        f.transport.reply = (options) => throw DioException(
              requestOptions: options,
              error: 'sensitive-raw-body-content',
              message: _originalToken,
            );

        final result = await f.repo.getProfile();

        expect(result, isA<SocialProfileError>());
        final err = result as SocialProfileError;
        expect(err.failure.message, isNot(contains(_originalToken)));
        expect(err.failure.message, isNot(contains('sensitive-raw-body-content')));
        expect(err.failure.message, isNot(contains('https://')));
      });
    });
  });
}
