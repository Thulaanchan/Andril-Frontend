import 'dart:async';
import 'dart:convert';

import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/interactive_session_admission.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/core/security/session/supabase_session_source.dart';
import 'package:andril_mobile/core/storage/secure/supabase_secure_storage.dart';
import 'package:andril_mobile/shared_core/account/account_handoff_controller.dart';
import 'package:andril_mobile/shared_core/authentication/data/repositories/supabase_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/email_auth_controller.dart';
import 'package:andril_mobile/shared_core/authentication/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
// The actual locked SDK accepts HTTP's Client. Use its transitive test transport
// here without changing the application dependency or lockfile.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'foundation_fakes.dart';

const _email = 'synthetic@example.invalid';
const _password = 'synthetic';
const _code = '001234';
final _expiry =
    DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

Map<String, Object?> _user(String subject) => {
      'id': subject,
      'aud': 'authenticated',
      'created_at': '2026-01-01T00:00:00Z',
      'email_confirmed_at': '2026-01-01T00:00:00Z',
    };

Map<String, Object?> _session(String subject, [int revision = 1]) {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({
        'sub': subject,
        'exp': _expiry,
        'revision': revision,
      })))
      .replaceAll('=', '');
  return {
    'access_token': 'fake.$payload.signature',
    'refresh_token': 'synthetic-refresh-$subject',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': _user(subject),
  };
}

http.Response _ok(Map<String, Object?> body) =>
    http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json'});

class _Exchange {
  _Exchange(this.path, this.operation);
  final String path;
  final String operation;
  final started = Completer<http.Request>();
  final result = Completer<http.Response>();

  void reply(Map<String, Object?> body) => result.complete(_ok(body));
}

class _Store extends MemorySecureStore {
  Completer<void>? blockPkceDelete;
  bool failFlowDelete = false;

  @override
  Future<void> delete(String key) async {
    if (key.endsWith('-code-verifier')) await blockPkceDelete?.future;
    if (failFlowDelete && key.endsWith('.flow')) {
      throw StateError('synthetic storage failure');
    }
    await super.delete(key);
  }
}

/// Stand-in for the existing backend, not a test of provider email delivery.
class _Backend implements HttpClientAdapter {
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options.uri.path);
    final data = options.uri.path.endsWith('/me')
        ? {
            'accountId': '016f6ec2-c23e-49b1-ae12-35edf9759ed4',
            'createdAtUtc': '2026-11-22T03:00:00Z',
            'updatedAtUtc': '2026-11-22T03:00:00Z',
          }
        : {
            'nextStep': 'profile_setup',
            'selectedModule': 'social',
            'blockingDependency': null,
            'onboardingComplete': true,
            'moduleHomeAuthorized': false,
            'progress': {
              'identityVerified': true,
              'accountInitialized': true,
              'demographicsComplete': true,
              'currentPoliciesAccepted': true,
              'starterModuleSelected': true,
              'privateProfileComplete': true,
            },
          };
    return ResponseBody.fromString(jsonEncode(data), 200, headers: {
      'content-type': ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

class _Fixture {
  final exchange = <_Exchange>[];
  final store = _Store();
  final backend = _Backend();
  final gate = InteractiveSessionAdmission();
  late final SupabaseSecureStorage storage;
  late final GoTrueClient sdk;
  late final SupabaseSessionSource source;
  late final SessionController controller;
  late final AccountHandoffController handoff;
  late final StreamSubscription<void> persistence;
  final flows = <EmailAuthController>[];

  _Exchange next(String path, [String operation = '']) {
    final item = _Exchange(path, operation);
    exchange.add(item);
    return item;
  }

  EmailAuthController newFlow() {
    final flow = EmailAuthController(
        SupabaseAuthRepository.forContractTests(sdk, signupOtpSupported: true),
        controller,
        interactiveAdmission: gate);
    flows.add(flow);
    return flow;
  }

  Future<void> start() async {
    storage = SupabaseSecureStorage(store: store, namespace: 'test');
    sdk = GoTrueClient(
        url: 'https://synthetic.invalid/auth/v1',
        autoRefreshToken: false,
        asyncStorage: SecurePkceStorage(storage),
        httpClient: MockClient((request) async {
          expect(request.url.origin, 'https://synthetic.invalid');
          final path = request.url.pathSegments.last;
          if (path == 'logout') return http.Response('', 204);
          final item = exchange.removeAt(0);
          expect(path, item.path);
          if (path == 'token') {
            expect(request.url.queryParameters['grant_type'], item.operation);
          } else if (item.operation.isNotEmpty) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['type'], item.operation);
          }
          item.started.complete(request);
          return item.result.future;
        }));
    // Model Flutter's separate SDK-event persistence subscriber. The actual
    // GoTrue client, event order, and secure-storage adapter run unmocked.
    persistence = sdk.onAuthStateChange.asyncMap<void>((event) async {
      try {
        final current = event.session;
        if (current != null) {
          await storage.persistSession(jsonEncode(current.toJson()));
        } else if (event.event == AuthChangeEvent.signedOut) {
          await storage.removePersistedSession();
        }
      } on SecureStorageException {
        // SessionController receives the actual failure from the storage latch.
      }
    }).listen((_) {});
    source = SupabaseSessionSource(sdk, storage, interactiveAdmission: gate);
    controller = SessionController(source, storageFailures: storage.failures);
    await controller.start();
    handoff = AccountHandoffController(
        controller,
        AndrilApiClient(
            AppConfig.fromValues(
                environment: 'development',
                supabaseUrl: 'https://synthetic.supabase.co',
                publicKey: 'sb_publishable_synthetic',
                apiBaseUrl: 'https://backend.invalid'),
            controller,
            adapter: backend));
  }

  Future<void> close() async {
    for (final flow in flows.reversed) {
      flow.dispose();
    }
    handoff.dispose();
    controller.dispose();
    await persistence.cancel();
    sdk.dispose();
    await storage.dispose();
  }

  Future<void> login(EmailAuthController flow, String subject) async {
    final request = next('token', 'password');
    final login = flow.signIn(_email, _password);
    await request.started.future;
    request.reply(_session(subject));
    expect((await login).state, EmailAuthState.authenticated);
    await handoff.retry();
  }
}

Future<_Fixture> _fixture() async {
  final f = _Fixture();
  await f.start();
  addTearDown(f.close);
  return f;
}

void main() {
  test('real SDK installs late login after logout, application rejects it',
      () async {
    final f = await _fixture();
    final flow = f.newFlow();
    final request = f.next('token', 'password');
    final result = flow.signIn(_email, _password);
    await request.started.future;

    final cleanup = Completer<void>();
    f.store.blockPkceDelete = cleanup;
    final logout = f.source.signOutInteractive();
    try {
      await flushSessionWork();
      expect(f.controller.phase, SessionPhase.signedOut);
      expect((await flow.signIn(_email, _password)).issue, EmailAuthIssue.busy);

      request.reply(_session('late-login'));
      expect((await result).issue, EmailAuthIssue.sessionChanged);
      await flushSessionWork();
      expect(f.sdk.currentSession?.user.id, 'late-login');
      expect(f.controller.backendSession, isNull);
      expect(f.backend.calls, isEmpty);
      expect(f.store.values['test.flow'], isNull);
    } finally {
      cleanup.complete();
      await logout;
    }
    await flushSessionWork();
    // Flutter's separate subscriber can still persist the SDK session. The
    // exact ordinary flow receipt needed on restoration was never created.
    expect(await f.storage.accessToken(), isNotNull);
    final restored = SupabaseSessionSource(f.sdk, f.storage);
    await expectLater(restored.resolve(await restored.restore()),
        throwsA(isA<SessionUnavailableException>()));
  });

  test('real SDK late OTP response cannot reopen the application session',
      () async {
    final f = await _fixture();
    final flow = f.newFlow();
    final registration = f.next('signup');
    final signup = flow.register(_email, _password);
    await registration.started.future;
    registration.reply(_user('otp-owner'));
    expect((await signup).state, EmailAuthState.verificationPending);

    final request = f.next('verify', 'email');
    final verifying = flow.verifyCode(_code);
    final sent = await request.started.future;
    expect((jsonDecode(sent.body) as Map)['token'], _code);
    await f.source.signOutInteractive();
    request.reply(_session('otp-owner'));
    expect((await verifying).issue, EmailAuthIssue.sessionChanged);
    await flushSessionWork();
    expect(f.sdk.currentSession?.user.id, 'otp-owner');
    expect(f.controller.backendSession, isNull);
    expect(f.handoff.status, isNull);
    expect(f.backend.calls, isEmpty);
  });

  test(
      'new owner is admitted once, then an SDK overwrite by older login fails closed',
      () async {
    final f = await _fixture();
    final a = f.newFlow();
    final requestA = f.next('token', 'password');
    final pendingA = a.signIn(_email, _password);
    await requestA.started.future;
    final b = f.newFlow();
    expect((await b.signIn(_email, _password)).issue, EmailAuthIssue.busy);

    await f.source.signOutInteractive();
    await flushSessionWork();
    await f.login(b, 'owner-b');
    expect(f.controller.subject, 'owner-b');
    expect(f.handoff.account, isNotNull);
    expect(f.handoff.status?.moduleHomeAuthorized, isFalse);
    expect(
        f.backend.calls, ['/api/v1/account/me', '/api/v1/onboarding/status']);

    requestA.reply(_session('owner-a'));
    expect((await pendingA).issue, EmailAuthIssue.sessionChanged);
    await flushSessionWork();
    expect(f.sdk.currentSession?.user.id, 'owner-a');
    expect(f.controller.phase, SessionPhase.unavailable);
    expect(f.handoff.account, isNull);
    expect(f.handoff.status, isNull);
    expect(f.backend.calls, hasLength(2));
  });

  test('duplicate SDK sign-in event for the same token does not repeat handoff',
      () async {
    final f = await _fixture();
    final flow = f.newFlow();
    await f.login(flow, 'owner');
    final owner = f.controller.backendSession;
    final duplicate = f.next('token', 'password');
    final raw = f.sdk.signInWithPassword(email: _email, password: _password);
    await duplicate.started.future;
    duplicate.reply(_session('owner'));
    await raw;
    await flushSessionWork();
    expect(f.controller.backendSession, owner);
    expect(f.backend.calls, hasLength(2));
  });

  test('the actual SDK discards an in-flight refresh after sign-out', () async {
    final f = await _fixture();
    await f.login(f.newFlow(), 'owner');
    final refresh = f.next('token', 'refresh_token');
    final pending = f.sdk.refreshSession();
    await refresh.started.future;
    await f.source.signOutInteractive();
    refresh.reply(_session('owner', 2));
    await pending;
    await flushSessionWork();
    expect(f.sdk.currentSession, isNull);
    expect(f.controller.phase, SessionPhase.signedOut);
    expect(f.handoff.account, isNull);
    expect(f.backend.calls, hasLength(2));
  });

  test('recovery interleaving wins over an ordinary login response', () async {
    final f = await _fixture();
    final flow = f.newFlow();
    final login = f.next('token', 'password');
    final pending = flow.signIn(_email, _password);
    await login.started.future;
    final recovery = f.next('verify', 'recovery');
    final raw =
        f.sdk.verifyOTP(email: _email, token: _code, type: OtpType.recovery);
    await recovery.started.future;
    recovery.reply(_session('recovery'));
    await raw;
    await flushSessionWork();
    login.reply(_session('login'));
    expect((await pending).issue, EmailAuthIssue.sessionChanged);
    await flushSessionWork();
    expect(f.controller.phase, SessionPhase.recovery);
    expect(f.controller.backendSession, isNull);
    expect(f.backend.calls, isEmpty);
  });

  test('failed secure receipt cleanup latches the application unavailable',
      () async {
    final f = await _fixture();
    await f.login(f.newFlow(), 'owner');
    f.store.failFlowDelete = true;
    await expectLater(f.source.signOutInteractive(),
        throwsA(isA<SessionUnavailableException>()));
    await flushSessionWork();
    expect(f.storage.hasFailed, isTrue);
    expect(f.controller.phase, SessionPhase.unavailable);
    expect(f.controller.backendSession, isNull);
    expect(f.handoff.account, isNull);
  });

  test('disposal ignores pending SDK events and outstanding outcomes',
      () async {
    final f = await _fixture();
    final flow = f.newFlow();
    final request = f.next('token', 'password');
    final pending = flow.signIn(_email, _password);
    await request.started.future;
    flow.dispose();
    f.flows.remove(flow);
    f.controller.dispose();
    request.reply(_session('late-disposal'));
    expect((await pending).issue, EmailAuthIssue.sessionChanged);
    await flushSessionWork();
    expect(f.controller.backendSession, isNull);
    expect(f.backend.calls, isEmpty);
  });

  test('a late signup session cannot turn confirmation into authentication',
      () async {
    final f = await _fixture();
    final flow = f.newFlow();
    final request = f.next('signup');
    final pending = flow.register(_email, _password);
    await request.started.future;
    await f.source.signOutInteractive();
    request.reply(_session('late-signup'));
    expect((await pending).issue, EmailAuthIssue.sessionChanged);
    await flushSessionWork();
    expect(f.sdk.currentSession?.user.id, 'late-signup');
    expect(f.controller.backendSession, isNull);
    expect(f.backend.calls, isEmpty);
  });
}
