import 'dart:async';
import 'dart:convert';

import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/shared_core/account/account_handoff_controller.dart';
import 'package:andril_mobile/shared_core/authentication/domain/offline_current_device_logout.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_fakes.dart';

class _Source extends FakeSessionSource implements BackendSessionSource {
  _Source()
      : super(
            restored:
                const SessionEvent(SessionEventKind.initial, subject: 'A'));

  @override
  BackendCredential? backendCredential =
      const BackendCredential('A', 'fake.a.token', emailConfirmed: true);

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}

  void signOut() {
    backendCredential = null;
    signals.add(const SessionEvent(SessionEventKind.signedOut));
  }

  Future<void> switchAccount() async {
    backendCredential =
        const BackendCredential('B', 'fake.b.token', emailConfirmed: true);
    signals.add(const SessionEvent(SessionEventKind.signedIn, subject: 'B'));
    await flushSessionWork();
  }
}

class _Boundary implements OfflineLogoutBoundary {
  _Boundary(this.source);

  final _Source source;
  final pending = Completer<LogoutCleanup>();
  bool revokes = true;
  int revokeCalls = 0;
  int cleanupCalls = 0;
  final cleaned = <String>[];

  @override
  Future<LogoutCleanup> Function() revokeCurrentDevice() {
    revokeCalls++;
    final ended = source.backendCredential?.subject;
    if (revokes) source.signOut();
    return () async {
      cleanupCalls++;
      final result = await pending.future;
      if (result == LogoutCleanup.completed && ended != null)
        cleaned.add(ended);
      return result;
    };
  }
}

class _Transport implements HttpClientAdapter {
  final first = Completer<void>();
  final delayed = Completer<ResponseBody>();
  final nextStarted = Completer<void>();
  final next = Completer<ResponseBody>();
  final List<(String, String?)> calls = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final authorization = options.headers['Authorization'] as String?;
    calls.add((options.uri.path, authorization));
    if (authorization == 'Bearer fake.a.token') {
      first.complete();
      return delayed.future;
    }
    nextStarted.complete();
    return next.future;
  }

  @override
  void close({bool force = false}) {}
}

Future<
    ({
      _Source source,
      SessionController sessions,
      _Boundary boundary,
      OfflineCurrentDeviceLogout logout
    })> _fixture({Stream<void>? failures}) async {
  final source = _Source();
  final sessions = SessionController(source, storageFailures: failures);
  await sessions.start();
  final boundary = _Boundary(source);
  final logout =
      OfflineCurrentDeviceLogout.forContractTests(sessions, boundary);
  addTearDown(() async {
    logout.dispose();
    sessions.dispose();
    await source.signals.close();
  });
  return (
    source: source,
    sessions: sessions,
    boundary: boundary,
    logout: logout
  );
}

void main() {
  test('restoration exposes no credential until the mock resolves the session',
      () async {
    final source = _Source();
    final restore = Completer<SessionEvent>();
    source.pendingRestore = restore.future;
    final sessions = SessionController(source);
    addTearDown(() async {
      sessions.dispose();
      await source.signals.close();
    });
    final pending = sessions.start();
    expect(sessions.phase, SessionPhase.restoring);
    expect(sessions.backendSession, isNull);
    restore.complete(source.restored);
    await pending;
    expect(sessions.backendSession?.subject, 'A');
    expect(sessions.moduleHomeAuthorized, isFalse);
  });

  test('logout clears prior scope synchronously and coalesces repeated taps',
      () async {
    final f = await _fixture();
    final owner = f.sessions.backendSession!;
    var clearCount = 0;
    f.sessions.registerPrivateStateClearer(() => clearCount++);
    final pending = f.logout.run();

    expect(f.sessions.credentialFor(owner), isNull);
    expect(f.sessions.backendSession, isNull);
    expect(clearCount, 1);
    expect(f.logout.busy, isTrue);
    expect(await f.logout.run(), LogoutOutcome.busy);
    f.boundary.pending.complete(LogoutCleanup.completed);
    expect(await pending, LogoutOutcome.signedOut);
    expect(f.sessions.phase, SessionPhase.signedOut);
    expect(f.boundary.revokeCalls, 1);
    expect(f.boundary.cleanupCalls, 1);
    expect(f.boundary.cleaned, ['A']);
  });

  test('an unrevoked boundary cannot start asynchronous cleanup', () async {
    final f = await _fixture();
    f.boundary.revokes = false;
    expect(await f.logout.run(), LogoutOutcome.boundaryUnavailable);
    expect(f.boundary.cleanupCalls, 0);
    expect(f.sessions.backendSession?.subject, 'A');
  });

  test('failed cleanup never reports a successful logout', () async {
    final f = await _fixture();
    final pending = f.logout.run();
    f.boundary.pending
        .completeError(StateError('synthetic provider network failure'));
    expect(await pending, LogoutOutcome.cleanupFailed);
    expect(f.sessions.backendSession, isNull);
    expect(f.logout.busy, isFalse);
  });

  test('cleanup that reports failure after local revocation stays failed',
      () async {
    final f = await _fixture();
    final pending = f.logout.run();
    f.boundary.pending.complete(LogoutCleanup.failed);
    expect(await pending, LogoutOutcome.cleanupFailed);
    expect(f.sessions.backendSession, isNull);
  });

  test('storage failure leaves the existing controller unavailable', () async {
    final failures = StreamController<void>.broadcast(sync: true);
    final f = await _fixture(failures: failures.stream);
    addTearDown(failures.close);
    final pending = f.logout.run();
    failures.add(null);
    f.boundary.pending.complete(LogoutCleanup.failed);
    expect(await pending, LogoutOutcome.cleanupFailed);
    expect(f.sessions.phase, SessionPhase.unavailable);
    expect(f.sessions.backendSession, isNull);
  });

  test('old cleanup owns A only after the next account becomes B', () async {
    final f = await _fixture();
    final pending = f.logout.run();
    await f.source.switchAccount();
    f.boundary.pending.complete(LogoutCleanup.completed);
    expect(await pending, LogoutOutcome.superseded);
    expect(f.sessions.backendSession?.subject, 'B');
    expect(f.boundary.cleaned, ['A']);
    expect(f.logout.outcome, LogoutOutcome.idle);
    expect(f.sessions.moduleHomeAuthorized, isFalse);
  });

  test('logout and account switch discard a late account-missing response',
      () async {
    final f = await _fixture();
    final transport = _Transport();
    final api = AndrilApiClient(
        AppConfig.fromValues(
          environment: 'development',
          supabaseUrl: 'https://synthetic.supabase.co',
          publicKey: 'sb_publishable_synthetic',
          apiBaseUrl: 'https://backend.invalid',
        ),
        f.sessions,
        adapter: transport);
    final handoff = AccountHandoffController(f.sessions, api);
    addTearDown(handoff.dispose);
    await transport.first.future;
    final previous = handoff.retry();
    final logout = f.logout.run();
    expect(handoff.account, isNull);
    expect(handoff.status, isNull);
    await f.source.switchAccount();
    transport.delayed.complete(ResponseBody.fromString(
      jsonEncode({'status': 404, 'title': 'Account not initialized'}),
      404,
      headers: {
        'content-type': ['application/problem+json']
      },
    ));
    await previous;
    await transport.nextStarted.future;
    final next = handoff.retry();
    transport.next.complete(ResponseBody.fromString('', 503));
    await next;
    f.boundary.pending.complete(LogoutCleanup.completed);
    expect(await logout, LogoutOutcome.superseded);
    expect(transport.calls, [
      ('/api/v1/account/me', 'Bearer fake.a.token'),
      ('/api/v1/account/me', 'Bearer fake.b.token'),
    ]);
    expect(handoff.account, isNull);
    expect(handoff.status, isNull);
    expect(f.sessions.backendSession?.subject, 'B');
  });
}
