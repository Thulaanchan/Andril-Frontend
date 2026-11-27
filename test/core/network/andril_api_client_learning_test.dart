import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared_core/authentication/foundation_fakes.dart';

const _token = 'fake.a.token';

AppConfig _config([String origin = 'https://andril.invalid:8443/']) =>
    AppConfig.fromValues(
        environment: 'development',
        supabaseUrl: 'https://synthetic.supabase.co',
        publicKey: 'sb_publishable_synthetic',
        apiBaseUrl: origin);

ResponseBody _response(int status, Object? payload,
        {String type = 'application/json',
        Map<String, List<String>> extra = const {}}) =>
    ResponseBody.fromString(payload == null ? '' : jsonEncode(payload), status,
        headers: {
          'content-type': [type],
          ...extra
        });

ResponseBody _problem(int status, String title) =>
    _response(status, {'status': status, 'title': title},
        type: 'application/problem+json');

class _TestTransport implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  late FutureOr<ResponseBody> Function(RequestOptions) reply;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

class _Source extends FakeSessionSource implements BackendSessionSource {
  _Source()
      : super(
            restored:
                const SessionEvent(SessionEventKind.initial, subject: 'A'));

  @override
  BackendCredential? backendCredential =
      const BackendCredential('A', _token, emailConfirmed: true);

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}
}

Future<({SessionController session, AndrilApiClient api, _TestTransport http})>
    _setup() async {
  final source = _Source();
  final session = SessionController(source);
  final http = _TestTransport();
  final api = AndrilApiClient(_config(), session, adapter: http);
  await session.start();
  addTearDown(() async {
    api.close();
    session.dispose();
    await source.signals.close();
  });
  return (session: session, api: api, http: http);
}

TypeMatcher<HandoffFailure> _issue(HandoffIssue issue) =>
    isA<HandoffFailure>().having((e) => e.issue, 'issue', issue);

void main() {
  test('requestLearning setup GET succeeds and decodes JSON response',
      () async {
    final harness = await _setup();
    harness.http.reply = (options) {
      expect(options.method, 'GET');
      expect(options.path, 'https://andril.invalid:8443/api/v1/learning/setup');
      expect(options.headers['Authorization'], 'Bearer $_token');
      return _response(200, {
        'revision': 'rev-001',
        'teachingSkills': ['skill-1'],
        'learningSkills': ['skill-2'],
        'goals': [
          {'goalId': 'g-1', 'text': 'Learn Flutter'}
        ],
      });
    };

    final result = await harness.api.requestLearning(
      LearningEndpoint.setup,
      harness.session.backendSession!,
    );

    expect(result['revision'], 'rev-001');
    expect(result['teachingSkills'], ['skill-1']);
    expect(result['learningSkills'], ['skill-2']);
  });

  test(
      'requestLearning setupSelections PUT sends body, header and returns empty map on 204',
      () async {
    final harness = await _setup();
    harness.http.reply = (options) {
      expect(options.method, 'PUT');
      expect(options.path,
          'https://andril.invalid:8443/api/v1/learning/setup/selections');
      expect(options.headers['Idempotency-Key'], 'uuid-key-1');
      expect(options.headers['Content-Type'], 'application/json');
      expect(jsonDecode(options.data as String), {
        'expectedRevision': 'rev-001',
        'teachingSkills': ['skill-1'],
        'learningSkills': ['skill-2'],
      });
      return _response(204, null);
    };

    final result = await harness.api.requestLearning(
      LearningEndpoint.setupSelections,
      harness.session.backendSession!,
      headers: {'Idempotency-Key': 'uuid-key-1'},
      body: {
        'expectedRevision': 'rev-001',
        'teachingSkills': ['skill-1'],
        'learningSkills': ['skill-2'],
      },
    );

    expect(result, isEmpty);
  });

  test('requestLearning returns 409 conflict as HandoffIssue.conflict',
      () async {
    final harness = await _setup();
    harness.http.reply = (options) => _problem(409, 'Conflict');

    expect(
      () => harness.api.requestLearning(
        LearningEndpoint.setupSelections,
        harness.session.backendSession!,
      ),
      throwsA(_issue(HandoffIssue.conflict)),
    );
  });

  test('requestLearning returns 400 bad request as HandoffIssue.badRequest',
      () async {
    final harness = await _setup();
    harness.http.reply = (options) => _problem(400, 'Invalid request');

    expect(
      () => harness.api.requestLearning(
        LearningEndpoint.setupGoalCreate,
        harness.session.backendSession!,
      ),
      throwsA(_issue(HandoffIssue.badRequest)),
    );
  });

  test('requestLearning returns 503 as HandoffIssue.unavailable', () async {
    final harness = await _setup();
    harness.http.reply = (options) => _problem(503, 'Service unavailable');

    expect(
      () => harness.api.requestLearning(
        LearningEndpoint.setup,
        harness.session.backendSession!,
      ),
      throwsA(_issue(HandoffIssue.unavailable)),
    );
  });

  test('requestLearningPath rejects unapproved paths outside learning',
      () async {
    final harness = await _setup();

    expect(
      () => harness.api.requestLearningPath(
        'GET',
        '/api/v1/unauthorized/path',
        harness.session.backendSession!,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('requestLearningPath allows approved learning parameterized path',
      () async {
    final harness = await _setup();
    const goalId = '11111111-2222-3333-4444-555555555555';
    harness.http.reply = (options) {
      expect(options.method, 'DELETE');
      expect(options.path,
          'https://andril.invalid:8443/api/v1/learning/setup/goals/$goalId');
      return _response(204, null);
    };

    final result = await harness.api.requestLearningPath(
      'DELETE',
      '/api/v1/learning/setup/goals/$goalId',
      harness.session.backendSession!,
    );

    expect(result, isEmpty);
  });
}
