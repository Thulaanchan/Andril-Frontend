import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/personality/data/repositories/personality_questionnaire_repository.dart';
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

const _validQuestionnaireJson = {
  'version': 'v1',
  'questions': [
    {
      'id': 'q01',
      'prompt': 'How do you prefer to spend your weekend?',
      'isRequired': true,
      'options': [
        {'id': 'opt1', 'label': 'Quiet night in with a book'},
        {'id': 'opt2', 'label': 'Social gathering with close friends'},
      ],
    },
    {
      'id': 'q02',
      'prompt': 'What style of communication do you value?',
      'isRequired': false,
      'options': [
        {'id': 'opt1', 'label': 'Direct and concise'},
        {'id': 'opt2', 'label': 'Deep and thoughtful'},
      ],
    },
  ],
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
      PersonalityQuestionnaireRepository repo,
    })> _setup({
  bool recovery = false,
  AppConfig? config,
}) async {
  final source = _TestBackendSource(recovery: recovery);
  final session = SessionController(source);
  final transport = _TestTransport();
  final repo = PersonalityQuestionnaireRepository(
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
  group('PersonalityQuestionnaireRepository (Task 151)', () {
    test('valid session sends GET to configured origin with bearer token and decodes response', () async {
      final f = await _setup();
      f.transport.reply = (_) => _response(200, _validQuestionnaireJson);

      final result = await f.repo.getActiveQuestionnaire();

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.version, 'v1');
      expect(result.data!.questions.length, 2);
      expect(result.data!.questions[0].id, 'q01');
      expect(result.data!.questions[0].options.length, 2);

      expect(f.transport.calls.length, 1);
      final call = f.transport.calls.single;
      expect(call.method, 'GET');
      expect(call.uri.origin, 'https://andril.invalid:8443');
      expect(call.uri.path, '/api/v1/social/questionnaires/active');
      expect(call.headers['Authorization'], 'Bearer $_originalToken');
      expect(call.headers['Accept'], contains('application/json'));
      expect(call.followRedirects, isFalse);
      expect(call.maxRedirects, 0);
    });

    test('missing API configuration fails closed with serviceUnavailable', () async {
      final source = _TestBackendSource();
      final session = SessionController(source);
      await session.start();
      addTearDown(() async {
        session.dispose();
        await source.signals.close();
      });

      // No config and no apiClient provided
      final unconfiguredRepo = PersonalityQuestionnaireRepository(
        sessionController: session,
      );

      final result = await unconfiguredRepo.getActiveQuestionnaire();

      expect(result.isSuccess, isFalse);
      expect(result.failureType, QuestionnaireFailureType.serviceUnavailable);
      expect(result.errorMessage, contains('not configured'));
    });

    test('invalid session phase (signedOut) fails closed with unauthorized', () async {
      final f = await _setup();
      f.source.logout();

      final result = await f.repo.getActiveQuestionnaire();

      expect(result.isSuccess, isFalse);
      expect(result.failureType, QuestionnaireFailureType.unauthorized);
      expect(f.transport.calls, isEmpty);
    });

    test('does not forward bearer token across redirect (301, 307, 308) and fails unavailable', () async {
      for (final code in [301, 307, 308]) {
        final f = await _setup();
        f.transport.reply = (_) => _response(code, null, extra: {
              'location': ['https://external-leak.invalid/active']
            });

        final result = await f.repo.getActiveQuestionnaire();

        expect(result.isSuccess, isFalse);
        expect(result.failureType, QuestionnaireFailureType.serviceUnavailable);
        // Only the initial request was sent; redirect was never followed
        expect(f.transport.calls.length, 1);
        expect(f.transport.calls.single.uri.origin, 'https://andril.invalid:8443');
      }
    });

    test('401 triggers token refresh once and replays GET on successful token rotation', () async {
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
        return _response(200, _validQuestionnaireJson);
      };

      final result = await f.repo.getActiveQuestionnaire();

      expect(result.isSuccess, isTrue);
      expect(result.data!.version, 'v1');
      expect(callCount, 2);
      expect(f.source.refreshes, 1);
      expect(f.transport.calls[0].headers['Authorization'], 'Bearer $_originalToken');
      expect(f.transport.calls[1].headers['Authorization'], 'Bearer $_rotatedToken');
    });

    test('401 failure without valid replacement token returns unauthorized', () async {
      final f = await _setup();
      f.transport.reply = (_) => _response(401, null);

      final result = await f.repo.getActiveQuestionnaire();

      expect(result.isSuccess, isFalse);
      expect(result.failureType, QuestionnaireFailureType.unauthorized);
    });

    test('403 forbidden (unconfirmed identity or Social access denied) returns unauthorized', () async {
      final f = await _setup();
      f.transport.reply = (_) => _problem(403, 'Forbidden');

      final result = await f.repo.getActiveQuestionnaire();

      expect(result.isSuccess, isFalse);
      expect(result.failureType, QuestionnaireFailureType.unauthorized);
    });

    test('503 service unavailable maps to serviceUnavailable failure', () async {
      final f = await _setup();
      f.transport.reply = (_) => _response(503, null);

      final result = await f.repo.getActiveQuestionnaire();

      expect(result.isSuccess, isFalse);
      expect(result.failureType, QuestionnaireFailureType.serviceUnavailable);
    });

    test('malformed payload (empty string, corrupted JSON, missing fields) maps safely to unknown failure', () async {
      // 1. Non-JSON string
      final f1 = await _setup();
      f1.transport.reply = (_) => ResponseBody.fromString(
            'not-a-valid-json',
            200,
            headers: {
              'content-type': ['application/json']
            },
          );
      final r1 = await f1.repo.getActiveQuestionnaire();
      expect(r1.isSuccess, isFalse);
      expect(r1.failureType, QuestionnaireFailureType.unknown);

      // 2. Missing questions list
      final f2 = await _setup();
      f2.transport.reply = (_) => _response(200, {'version': 'v1'});
      final r2 = await f2.repo.getActiveQuestionnaire();
      expect(r2.isSuccess, isFalse);
      expect(r2.failureType, QuestionnaireFailureType.unknown);

      // 3. Duplicate question IDs in questions array
      final f3 = await _setup();
      f3.transport.reply = (_) => _response(200, {
            'version': 'v1',
            'questions': [
              {
                'id': 'dup-id',
                'prompt': 'Question 1',
                'isRequired': true,
                'options': [
                  {'id': 'opt1', 'label': 'Option 1'}
                ]
              },
              {
                'id': 'dup-id',
                'prompt': 'Question 2',
                'isRequired': true,
                'options': [
                  {'id': 'opt2', 'label': 'Option 2'}
                ]
              },
            ],
          });
      final r3 = await f3.repo.getActiveQuestionnaire();
      expect(r3.isSuccess, isFalse);
      expect(r3.failureType, QuestionnaireFailureType.unknown);
    });

    test('session change during inflight request discards late response and returns unauthorized', () async {
      final f = await _setup();
      final completer = Completer<ResponseBody>();
      f.transport.reply = (_) => completer.future;

      final futureResult = f.repo.getActiveQuestionnaire();

      // Session switch happens while request is still pending
      f.source.switchUser('user-b', 'fake.b.token');

      // Now server responds to the old request
      completer.complete(_response(200, _validQuestionnaireJson));

      final result = await futureResult;

      expect(result.isSuccess, isFalse);
      expect(result.failureType, QuestionnaireFailureType.unauthorized);
    });

    test('transport errors and diagnostic output never disclose credentials or raw response bodies', () async {
      final f = await _setup();
      f.transport.reply = (options) => throw DioException(
            requestOptions: options,
            error: 'synthetic-secret-payload',
            message: _originalToken,
          );

      final result = await f.repo.getActiveQuestionnaire();

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNot(contains(_originalToken)));
      expect(result.errorMessage, isNot(contains('synthetic-secret-payload')));
      expect(result.errorMessage, isNot(contains('https://')));
    });
  });
}
