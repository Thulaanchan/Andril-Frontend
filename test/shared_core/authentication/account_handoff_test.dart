import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:andril_mobile/app/andril_app.dart';
import 'package:andril_mobile/app/router/learning_router.dart';
import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/features/learning/profile/screens/learning_welcome_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/shared_core/account/account_handoff_controller.dart';
import 'package:andril_mobile/shared_core/account/data/account_repository.dart';
import 'package:andril_mobile/shared_core/onboarding/domain/onboarding_status_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_fakes.dart';

const _account = {
  'accountId': '10213243-5465-7687-98a9-bacbdcedfe0f',
  'createdAtUtc': '2026-11-22T03:00:00+00:00',
  'updatedAtUtc': '2026-11-22T03:00:00+00:00',
};
const _progress = {
  'identityVerified': true,
  'accountInitialized': true,
  'demographicsComplete': true,
  'currentPoliciesAccepted': true,
  'starterModuleSelected': true,
  'privateProfileComplete': true,
};
const _status = {
  'nextStep': 'profile_setup',
  'progress': _progress,
  'selectedModule': 'social',
  'blockingDependency': null,
  'onboardingComplete': true,
  'moduleHomeAuthorized': false,
};
const _originalToken = 'fake.a.original';
const _rotatedToken = 'fake.a.rotated';

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
ResponseBody _missing() => _problem(404, 'Account not initialized');

class _Source extends FakeSessionSource implements BackendSessionSource {
  _Source({bool recovery = false})
      : super(
            restored:
                const SessionEvent(SessionEventKind.initial, subject: 'A')) {
    restoredRecovery = recovery;
  }

  @override
  BackendCredential? backendCredential =
      const BackendCredential('A', _originalToken, emailConfirmed: true);
  int refreshes = 0;
  Future<void> Function()? rotate;

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {
    refreshes++;
    await rotate?.call();
  }

  void token(String value, {bool notify = true}) {
    backendCredential = BackendCredential('A', value, emailConfirmed: true);
    if (notify)
      signals.add(const SessionEvent(SessionEventKind.refreshed, subject: 'A'));
  }

  void logout() {
    backendCredential = null;
    signals.add(const SessionEvent(SessionEventKind.signedOut));
  }

  void switchToB() {
    backendCredential =
        const BackendCredential('B', 'fake.b.token', emailConfirmed: true);
    signals.add(const SessionEvent(SessionEventKind.signedIn, subject: 'B'));
  }
}

class _Transport implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  late FutureOr<ResponseBody> Function(RequestOptions) reply;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options);
    expect(options.uri.origin, 'https://andril.invalid:8443');
    expect(options.uri.query, isEmpty);
    expect(options.data, isNull);
    expect(requestStream, isNull);
    expect(options.followRedirects, isFalse);
    expect(options.maxRedirects, 0);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

Future<
    ({
      _Source source,
      SessionController session,
      AndrilApiClient api,
      _Transport http
    })> _setup({bool recovery = false}) async {
  final source = _Source(recovery: recovery);
  final session = SessionController(source);
  final http = _Transport();
  final api = AndrilApiClient(_config(), session, adapter: http);
  await session.start();
  addTearDown(() async {
    api.close();
    session.dispose();
    await source.signals.close();
  });
  return (source: source, session: session, api: api, http: http);
}

TypeMatcher<HandoffFailure> _issue(HandoffIssue issue) =>
    isA<HandoffFailure>().having((e) => e.issue, 'issue', issue);

void main() {
  test(
      'sends only the token current at dispatch and parses authoritative account',
      () async {
    final f = await _setup();
    final bound = f.session.backendSession!;
    f.source.token(_rotatedToken, notify: false);
    f.http.reply = (_) => _response(200, _account);
    final account = await AccountRepository(f.api).loadOrInitialize(bound);
    expect(account.accountId, _account['accountId']);
    expect(f.http.calls.single.uri.path, '/api/v1/account/me');
    expect(f.http.calls.single.headers['Authorization'],
        'Bearer ' + _rotatedToken);
    expect(f.http.calls.single.method, 'GET');
  });

  test('rejects a configured path rather than sending to an ambiguous origin',
      () async {
    final f = await _setup();
    expect(
        () => AndrilApiClient(
            _config('https://andril.invalid/proxy/'), f.session,
            adapter: f.http),
        throwsA(isA<ConfigurationException>()));
    expect(f.http.calls, isEmpty);
  });

  for (final code in [301, 307, 308]) {
    test('does not forward a token across redirect ' + code.toString(),
        () async {
      final f = await _setup();
      f.http.reply = (_) => _response(code, null, extra: {
            'location': ['https://unexpected.invalid/']
          });
      await expectLater(
          f.api.request(AccountEndpoint.me, f.session.backendSession!),
          throwsA(_issue(HandoffIssue.unavailable)));
      expect(f.http.calls, hasLength(1));
    });
  }

  test('transport errors do not disclose credentials or provider details',
      () async {
    final f = await _setup();
    f.http.reply = (options) => throw DioException(
        requestOptions: options,
        error: 'synthetic-secret',
        message: _originalToken);
    final logs = <String>[];
    await runZoned(() async {
      await expectLater(
          f.api.request(AccountEndpoint.me, f.session.backendSession!),
          throwsA(_issue(HandoffIssue.unavailable).having((e) => e.toString(),
              'safe exception', 'HandoffFailure(unavailable)')));
    },
        zoneSpecification:
            ZoneSpecification(print: (_, __, ___, text) => logs.add(text)));
    expect(logs, isEmpty);
    expect(
        f.source.backendCredential.toString(), 'BackendCredential(redacted)');
  });

  test(
      'recognized 404 initializes once, with no identity body, then reads status',
      () async {
    final f = await _setup();
    f.http.reply = (r) => switch (r.uri.path) {
          '/api/v1/account/me' => _missing(),
          '/api/v1/account/initialize' => _response(200, _account),
          '/api/v1/onboarding/status' => _response(200, _status),
          _ => throw StateError('unexpected endpoint'),
        };
    final handoff = AccountHandoffController(f.session, f.api);
    addTearDown(handoff.dispose);
    await Future.wait([handoff.retry(), handoff.retry()]);
    expect(f.http.calls.map((r) => (r.method, r.uri.path)), [
      ('GET', '/api/v1/account/me'),
      ('POST', '/api/v1/account/initialize'),
      ('GET', '/api/v1/onboarding/status'),
    ]);
    expect(
        handoff.status?.setupEvidence, SetupEvidence.completeEntryUnavailable);
    expect(handoff.status?.nextStep, 'profile_setup');
    expect(handoff.status?.moduleHomeAuthorized, isFalse);
    expect(f.session.moduleHomeAuthorized, isFalse);
  });

  test('uncertain initialize is recovered by a new GET, not a repeated POST',
      () async {
    final f = await _setup();
    f.http.reply =
        (r) => r.method == 'POST' ? _response(503, null) : _missing();
    final handoff = AccountHandoffController(f.session, f.api);
    addTearDown(handoff.dispose);
    await handoff.retry();
    expect(handoff.failure?.issue, HandoffIssue.unavailable);
    expect(handoff.status, isNull);
    f.http.reply =
        (r) => _response(200, r.uri.path.endsWith('/me') ? _account : _status);
    await handoff.retry();
    expect(handoff.account?.accountId, _account['accountId']);
    expect(f.http.calls.where((r) => r.method == 'POST'), hasLength(1));
  });

  for (final (code, title, issue) in [
    (401, null, HandoffIssue.reauthenticationRequired),
    (403, 'Email confirmation required', HandoffIssue.verificationRequired),
    (403, 'Forbidden', HandoffIssue.forbidden),
    (404, 'Not Found', HandoffIssue.unavailable),
    (429, null, HandoffIssue.rateLimited),
    (503, null, HandoffIssue.unavailable),
  ]) {
    test('does not initialize on ' + code.toString() + ' ' + (title ?? ''),
        () async {
      final f = await _setup();
      f.http.reply =
          (_) => title == null ? _response(code, null) : _problem(code, title);
      await expectLater(
          AccountRepository(f.api).loadOrInitialize(f.session.backendSession!),
          throwsA(_issue(issue)));
      expect(f.http.calls.single.method, 'GET');
    });
  }

  test('untrusted generic 404 JSON never triggers initialization', () async {
    final f = await _setup();
    f.http.reply = (_) =>
        _response(404, {'title': 'Account not initialized', 'status': 404});
    await expectLater(
        AccountRepository(f.api).loadOrInitialize(f.session.backendSession!),
        throwsA(_issue(HandoffIssue.unavailable)));
    expect(f.http.calls, hasLength(1));
  });

  test('retains Retry-After and suppresses immediate explicit retry', () async {
    final f = await _setup();
    f.http.reply = (_) => _response(429, null, extra: {
          'retry-after': ['12']
        });
    final handoff = AccountHandoffController(f.session, f.api);
    addTearDown(handoff.dispose);
    await handoff.retry();
    expect(handoff.failure?.retryAfter, const Duration(seconds: 12));
    await handoff.retry();
    expect(f.http.calls, hasLength(1));
  });

  test('rejects malformed Retry-After values safely', () async {
    final f = await _setup();
    f.http.reply = (_) => _response(429, null, extra: {
          'retry-after': ['-1']
        });
    await expectLater(
        f.api.request(AccountEndpoint.me, f.session.backendSession!),
        throwsA(_issue(HandoffIssue.rateLimited)
            .having((e) => e.retryAfter, 'delay', isNull)));
  });

  for (final module
      in StarterModule.values.where((m) => m != StarterModule.social)) {
    test('keeps incomplete ' + module.name + ' separate', () {
      final status = OnboardingStatus.fromJson({
        ..._status,
        'selectedModule': module.name,
        'onboardingComplete': false,
        'progress': {..._progress, 'privateProfileComplete': false},
        'blockingDependency': 'approved_profile_contract',
      });
      expect(status.starterModule, module);
      expect(status.setupEvidence, SetupEvidence.incomplete);
      expect(status.moduleHomeAuthorized, isFalse);
    });
  }

  test(
      'preserves future strings without interpreting them as entry or setup instructions',
      () {
    final status = OnboardingStatus.fromJson({
      ..._status,
      'selectedModule': 'future',
      'nextStep': 'future_step',
      'blockingDependency': 'future_requirement',
    });
    expect(status.selectedModule, 'future');
    expect(status.nextStep, 'future_step');
    expect(status.blockingDependency, 'future_requirement');
    expect(status.setupEvidence, SetupEvidence.unknown);
    expect(status.moduleHomeAuthorized, isFalse);
  });

  test(
      'rejects missing fields, invalid timestamps and unexpected Home authorization',
      () async {
    for (final body in [
      {..._status, 'moduleHomeAuthorized': true},
      {
        ..._status,
        'progress': {'privateProfileComplete': true}
      },
      Map<String, Object?>.of(_status)..remove('blockingDependency'),
    ]) {
      expect(() => OnboardingStatus.fromJson(body),
          throwsA(_issue(HandoffIssue.invalidResponse)));
    }
    expect(
        () => Account.fromJson(
            {..._account, 'createdAtUtc': '2026-02-31T00:00:00Z'}),
        throwsA(_issue(HandoffIssue.invalidResponse)));
    final f = await _setup();
    f.http.reply = (_) => ResponseBody.fromString('{', 200, headers: {
          'content-type': ['application/json']
        });
    await expectLater(
        f.api.request(AccountEndpoint.me, f.session.backendSession!),
        throwsA(_issue(HandoffIssue.invalidResponse)));
  });

  for (final kind in [
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError
  ]) {
    test('handles ' + kind.name + ' without fallback writes', () async {
      final f = await _setup();
      f.http.reply = (r) => throw DioException(requestOptions: r, type: kind);
      await expectLater(
          AccountRepository(f.api).loadOrInitialize(f.session.backendSession!),
          throwsA(_issue(HandoffIssue.unavailable)));
      expect(f.http.calls.single.method, 'GET');
    });
  }

  test(
      '401 retries one GET and remains reauthentication-required on another 401',
      () async {
    final f = await _setup();
    f.source.rotate = () async => f.source.token(_rotatedToken);
    f.http.reply = (_) => _response(401, null);
    await expectLater(
        f.api.request(AccountEndpoint.me, f.session.backendSession!),
        throwsA(_issue(HandoffIssue.reauthenticationRequired)));
    expect(f.source.refreshes, 1);
    expect(f.http.calls.map((r) => r.headers['Authorization']),
        ['Bearer ' + _originalToken, 'Bearer ' + _rotatedToken]);
  });

  test('concurrent 401s share one refresh and retry with its token', () async {
    final f = await _setup();
    final gate = Completer<void>();
    f.source.rotate = () async {
      await gate.future;
      f.source.token(_rotatedToken);
    };
    f.http.reply = (r) =>
        r.headers['Authorization'] == 'Bearer ' + _originalToken
            ? _response(401, null)
            : _response(200, _account);
    final bound = f.session.backendSession!;
    final reads = Future.wait(
        [for (var i = 0; i < 3; i++) f.api.request(AccountEndpoint.me, bound)]);
    await flushSessionWork();
    expect(f.source.refreshes, 1);
    gate.complete();
    expect(await reads, hasLength(3));
    expect(f.http.calls, hasLength(6));
  });

  test('never automatically replays initialize on 401', () async {
    final f = await _setup();
    f.http.reply = (r) => r.method == 'GET' ? _missing() : _response(401, null);
    await expectLater(
        AccountRepository(f.api).loadOrInitialize(f.session.backendSession!),
        throwsA(_issue(HandoffIssue.reauthenticationRequired)));
    expect(f.http.calls, hasLength(2));
    expect(f.source.refreshes, 0);
  });

  test('an account switch during GET discards its late 404', () async {
    final f = await _setup();
    final delayed = Completer<ResponseBody>();
    f.http.reply = (_) => delayed.future;
    final read =
        AccountRepository(f.api).loadOrInitialize(f.session.backendSession!);
    final checked =
        expectLater(read, throwsA(_issue(HandoffIssue.sessionChanged)));
    await flushSessionWork();
    f.source.switchToB();
    delayed.complete(_missing());
    await checked;
    expect(f.http.calls.single.method, 'GET');
  });

  test('logout during initialize clears state and prevents onboarding request',
      () async {
    final f = await _setup();
    final delayed = Completer<ResponseBody>();
    final postStarted = Completer<void>();
    f.http.reply = (r) {
      if (r.method != 'POST') return _missing();
      postStarted.complete();
      return delayed.future;
    };
    final handoff = AccountHandoffController(f.session, f.api);
    addTearDown(handoff.dispose);
    final load = handoff.retry();
    await postStarted.future;
    expect(f.http.calls.last.method, 'POST');
    f.source.logout();
    delayed.complete(_response(200, _account));
    await load;
    expect(handoff.account, isNull);
    expect(handoff.status, isNull);
    expect(f.http.calls, hasLength(2));
  });

  test('recovery causes no ordinary account work', () async {
    final f = await _setup(recovery: true);
    final handoff = AccountHandoffController(f.session, f.api);
    addTearDown(handoff.dispose);
    await handoff.retry();
    expect(f.session.phase, SessionPhase.recovery);
    expect(f.http.calls, isEmpty);
  });

  test(
      'unconfirmed session produces verification-required without backend writes',
      () async {
    final f = await _setup();
    f.source.backendCredential =
        const BackendCredential('A', _originalToken, emailConfirmed: false);
    final handoff = AccountHandoffController(f.session, f.api);
    addTearDown(handoff.dispose);
    await handoff.retry();
    expect(handoff.failure?.issue, HandoffIssue.verificationRequired);
    expect(f.http.calls, isEmpty);
  });

  test(
      'refresh preserves current private state; account switch clears it immediately',
      () async {
    final f = await _setup();
    final delayed = Completer<ResponseBody>();
    final switchedRequestStarted = Completer<void>();
    f.http.reply = (r) {
      if (r.headers['Authorization'] == 'Bearer fake.b.token') {
        switchedRequestStarted.complete();
        return delayed.future;
      }
      return _response(200, r.uri.path.endsWith('/me') ? _account : _status);
    };
    final handoff = AccountHandoffController(f.session, f.api);
    addTearDown(handoff.dispose);
    await handoff.retry();
    final account = handoff.account;
    f.source.token(_rotatedToken);
    await flushSessionWork();
    expect(handoff.account, same(account));
    expect(f.http.calls, hasLength(2));
    f.source.switchToB();
    expect(handoff.account, isNull);
    expect(handoff.status, isNull);
    await switchedRequestStarted.future;
    final switchedLoad = handoff.retry();
    delayed.complete(_response(503, null));
    await switchedLoad;
    expect(handoff.failure?.issue, HandoffIssue.unavailable);
  });
  test('rotation between scheduling and adapter dispatch uses the new token',
      () async {
    final f = await _setup();
    f.http.reply = (_) => _response(200, _account);
    final pending =
        f.api.request(AccountEndpoint.me, f.session.backendSession!);
    f.source.token(_rotatedToken, notify: false);
    await pending;
    expect(f.http.calls.single.headers['Authorization'],
        'Bearer ' + _rotatedToken);
  });

  testWidgets('the shared Learning guard stays closed after Social handoff',
      (tester) async {
    final source = _Source();
    final session = SessionController(source);
    final router = createLearningRouter(initialLocation: '/learning/home');
    final http = _Transport();
    http.reply =
        (r) => _response(200, r.uri.path.endsWith('/me') ? _account : _status);
    AccountHandoffController? handoff;
    await tester.pumpWidget(AndrilApp(
      routerConfig: router,
      initialize: () async {
        await session.start();
        return session;
      },
      createHandoff: (controller) => handoff = AccountHandoffController(
          controller, AndrilApiClient(_config(), controller, adapter: http)),
    ));
    await tester.pumpAndSettle();
    expect(
        handoff?.status?.setupEvidence, SetupEvidence.completeEntryUnavailable);
    expect(find.byType(LearningWelcomeScreen), findsOneWidget);
    expect(find.text('Learning Home'), findsNothing);
    router.go('/learning/access-denied');
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    source.token(_rotatedToken);
    await tester.pumpAndSettle();
    expect(
        tester.state<NavigatorState>(find.byType(Navigator)), same(navigator));
    expect(http.calls, hasLength(2));
    await tester.pumpWidget(const SizedBox());
    await source.signals.close();
    router.dispose();
  });
}
