import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/interests_preferences/data/social_preferences_repository.dart';
import 'package:andril_mobile/features/social/interests_preferences/domain/social_preferences_model.dart';

import '../../shared_core/authentication/foundation_fakes.dart';

const _originalToken = 'fake.token.pref.original';

AppConfig _config([String origin = 'https://andril.invalid:8443/']) =>
    AppConfig.fromValues(
      environment: 'development',
      supabaseUrl: 'https://synthetic.supabase.co',
      publicKey: 'sb_publishable_synthetic',
      apiBaseUrl: origin,
    );

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
  _TestBackendSource()
      : super(
          restored: const SessionEvent(SessionEventKind.initial, subject: 'user-pref'),
        );

  @override
  BackendCredential? backendCredential =
      const BackendCredential('user-pref', _originalToken, emailConfirmed: true);

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}

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
      SocialPreferencesRepository repo,
    })> _setup({
  AppConfig? config,
}) async {
  final source = _TestBackendSource();
  final session = SessionController(source);
  final transport = _TestTransport();
  final repo = SocialPreferencesRepository(
    sessionController: session,
    config: config ?? _config(),
    adapter: transport,
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
  group('SocialPreferencesRepository (Task 153)', () {
    group('getAccountLanguage', () {
      test('sends GET to /api/v1/account/preferences/language with bearer token', () async {
        final f = await _setup();
        f.transport.reply = (_) => _response(200, {'language': 'ta', 'mode': 'settings'});

        final result = await f.repo.getAccountLanguage();

        expect(result.isSuccess, isTrue);
        expect(result.data, 'ta');
        expect(f.transport.calls.length, 1);
        final call = f.transport.calls.single;
        expect(call.method, 'GET');
        expect(call.uri.path, '/api/v1/account/preferences/language');
        expect(call.headers['Authorization'], 'Bearer $_originalToken');
        expect(call.followRedirects, isFalse);
      });

      test('401 returns unauthorized failure', () async {
        final f = await _setup();
        f.transport.reply = (_) => _problem(401, 'Unauthorized');

        final result = await f.repo.getAccountLanguage();

        expect(result.isFailure, isTrue);
        expect(result.failureType, SocialPreferencesFailureType.unauthorized);
      });

      test('503 returns serviceUnavailable failure', () async {
        final f = await _setup();
        f.transport.reply = (_) => _problem(503, 'Service Unavailable');

        final result = await f.repo.getAccountLanguage();

        expect(result.isFailure, isTrue);
        expect(result.failureType, SocialPreferencesFailureType.serviceUnavailable);
      });

      test('session change during inflight GET returns sessionExpired', () async {
        final f = await _setup();
        final completer = Completer<ResponseBody>();
        f.transport.reply = (_) => completer.future;

        final futureResult = f.repo.getAccountLanguage();
        f.source.switchUser('user-b', 'fake.token.b');
        completer.complete(_response(200, {'language': 'en', 'mode': 'settings'}));

        final result = await futureResult;

        expect(result.isFailure, isTrue);
        expect(result.failureType, SocialPreferencesFailureType.sessionExpired);
      });
    });

    group('updateAccountLanguage', () {
      test('sends PATCH with supported language code en', () async {
        final f = await _setup();
        f.transport.reply = (opts) {
          final body = opts.data as Map<String, dynamic>;
          expect(body['language'], 'en');
          expect(body['mode'], 'settings');
          return _response(200, {'language': 'en', 'mode': 'settings'});
        };

        final result = await f.repo.updateAccountLanguage('en');

        expect(result.isSuccess, isTrue);
        expect(result.data, 'en');
        expect(f.transport.calls.single.method, 'PATCH');
      });

      test('rejects unsupported language code with badRequest without network call', () async {
        final f = await _setup();

        final result = await f.repo.updateAccountLanguage('de');

        expect(result.isFailure, isTrue);
        expect(result.failureType, SocialPreferencesFailureType.badRequest);
        expect(f.transport.calls, isEmpty);
      });
    });

    group('getPreferences and updatePreferences', () {
      test('getPreferences returns default preferences model with synchronized language', () async {
        final f = await _setup();
        f.transport.reply = (_) => _response(200, {'language': 'ta', 'mode': 'settings'});

        final result = await f.repo.getPreferences();

        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.minAge, 18);
        expect(result.data!.languages, contains('Tamil'));
      });

      test('updatePreferences rejects minAge < 18 with badRequest', () async {
        final f = await _setup();

        final invalid = SocialPreferencesModel(
          minAge: 16,
          selectedInterests: const {'music'},
        );
        final result = await f.repo.updatePreferences(invalid);

        expect(result.isFailure, isTrue);
        expect(result.failureType, SocialPreferencesFailureType.badRequest);
        expect(result.errorMessage, contains('18'));
      });

      test('updatePreferences rejects empty selectedInterests with badRequest', () async {
        final f = await _setup();

        final invalid = SocialPreferencesModel(
          minAge: 20,
          selectedInterests: const {},
        );
        final result = await f.repo.updatePreferences(invalid);

        expect(result.isFailure, isTrue);
        expect(result.failureType, SocialPreferencesFailureType.badRequest);
        expect(result.errorMessage, contains('at least one interest'));
      });

      test('updatePreferences validates and updates cached preferences', () async {
        final f = await _setup();
        f.transport.reply = (_) => _response(200, {'language': 'en', 'mode': 'settings'});

        final valid = SocialPreferencesModel(
          minAge: 22,
          maxAge: 35,
          maxDistanceKm: 25,
          selectedInterests: const {'coffee', 'travel'},
          languages: const ['English'],
        );
        final result = await f.repo.updatePreferences(valid);

        expect(result.isSuccess, isTrue);
        expect(result.data!.minAge, 22);
        expect(result.data!.selectedInterests, containsAll(['coffee', 'travel']));
      });

      test('unauthenticated caller is rejected with unauthorized', () async {
        final f = await _setup();
        f.source.logout();

        final result = await f.repo.getPreferences();

        expect(result.isFailure, isTrue);
        expect(result.failureType, SocialPreferencesFailureType.unauthorized);
      });
    });
  });
}
