import 'dart:async';
import 'dart:convert';

import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/interactive_session_admission.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/core/security/session/supabase_session_source.dart';
import 'package:andril_mobile/core/storage/secure/supabase_secure_storage.dart';
import 'package:andril_mobile/shared_core/account/account_handoff_controller.dart';
import 'package:andril_mobile/shared_core/authentication/data/repositories/native_google_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/data/repositories/supabase_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/email_auth_controller.dart';
import 'package:andril_mobile/shared_core/authentication/domain/google_auth_controller.dart';
import 'package:andril_mobile/shared_core/authentication/domain/repositories/auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/repositories/google_auth_repository.dart';
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
import 'google_contract_fakes.dart';

const _email = 'synthetic@example.invalid';
const _password = 'synthetic';
const _code = '001234';
final _expiry =
    DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

Map<String, Object?> _user(String subject) => {
      'id': subject,
      'aud': 'authenticated',
      'email': _email,
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
  bool needsAccount = false;
  final authorization = <Object?>[];
  final meHeld = Completer<void>();
  Completer<void>? releaseNextMe;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options.uri.path);
    authorization.add(options.headers['Authorization']);
    if (options.uri.path.endsWith('/me') && releaseNextMe != null) {
      final release = releaseNextMe!;
      releaseNextMe = null;
      meHeld.complete();
      await release.future;
    }
    if (options.uri.path.endsWith('/me') && needsAccount) {
      return ResponseBody.fromString(
          jsonEncode({'status': 404, 'title': 'Account not initialized'}), 404,
          headers: {
            'content-type': ['application/problem+json']
          });
    }
    final initializes = options.uri.path.endsWith('/initialize');
    if (initializes) needsAccount = false;
    final data = options.uri.path.endsWith('/me') || initializes
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

class _HoldGoogleReceipt implements GoogleAuthRepository {
  _HoldGoogleReceipt(this._delegate);
  final GoogleAuthRepository _delegate;
  final received = Completer<void>();
  final release = Completer<void>();

  @override
  Future<GoogleAuthResult> signIn(
      {required bool Function() mayExchange}) async {
    final result = await _delegate.signIn(mayExchange: mayExchange);
    received.complete();
    await release.future;
    return result;
  }
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
  final googleFlows = <GoogleAuthController>[];

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

  NativeGoogleAuthRepository googleRepository() =>
      NativeGoogleAuthRepository.forContractTests(syntheticGoogle(), sdk,
          syntheticServerClientId: googleClientId);

  GoogleAuthController newGoogle({GoogleAuthRepository? repository}) {
    final flow = GoogleAuthController(
        repository ?? googleRepository(), controller, gate);
    googleFlows.add(flow);
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
    for (final flow in googleFlows.reversed) {
      flow.dispose();
    }
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

  group('Google with the pinned SDK', () {
    test('SDK event precedes the receipt; only admission starts AUTH-03C',
        () async {
      final f = await _fixture();
      final delayed = _HoldGoogleReceipt(f.googleRepository());
      final flow = f.newGoogle(repository: delayed);
      final states = <GoogleAuthState>[];
      flow.addListener(() => states.add(flow.state));
      final request = f.next('token', 'id_token');
      final pending = flow.signIn();
      final sent = await request.started.future;
      final body = jsonDecode(sent.body) as Map;
      expect(body['provider'], 'google');
      expect(body['id_token'], googleId);
      expect(body['access_token'], googleAccess);
      expect(
          body.keys,
          everyElement(isIn([
            'provider',
            'id_token',
            'nonce',
            'gotrue_meta_security',
            'access_token'
          ])));
      expect((await flow.signIn()), GoogleAuthState.busy);
      expect((await f.newFlow().signIn(_email, _password)).issue,
          EmailAuthIssue.busy);

      request.reply(_session('google-owner'));
      await delayed.received.future;
      await flushSessionWork();
      expect(f.sdk.currentSession?.user.id, 'google-owner');
      expect(f.controller.backendSession, isNull);
      expect(f.backend.calls, isEmpty);
      delayed.release.complete();
      expect(await pending, GoogleAuthState.admitted);
      await f.handoff.retry();
      expect(
          states,
          containsAllInOrder([
            GoogleAuthState.loading,
            GoogleAuthState.pendingAdmission,
            GoogleAuthState.admitted
          ]));
      expect(f.controller.subject, 'google-owner');
      expect(
          f.backend.calls, ['/api/v1/account/me', '/api/v1/onboarding/status']);
      expect(f.handoff.status?.moduleHomeAuthorized, isFalse);

      final duplicate = f.next('token', 'id_token');
      final repeated = f.sdk.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleId,
          accessToken: googleAccess);
      await duplicate.started.future;
      duplicate.reply(_session('google-owner'));
      await repeated;
      await flushSessionWork();
      expect(f.controller.subject, 'google-owner');
      expect(
          f.backend.authorization,
          everyElement('Bearer ' +
              (_session('google-owner')['access_token'] as String)));
      expect(f.backend.calls, hasLength(2));
    });

    test('new account initializes once; existing identity resumes without POST',
        () async {
      final f = await _fixture();
      f.backend.needsAccount = true;
      final flow = f.newGoogle();
      final first = f.next('token', 'id_token');
      final signup = flow.signIn();
      await first.started.future;
      first.reply(_session('google-owner'));
      expect(await signup, GoogleAuthState.admitted);
      await f.handoff.retry();
      expect(f.backend.calls, [
        '/api/v1/account/me',
        '/api/v1/account/initialize',
        '/api/v1/onboarding/status'
      ]);
      await f.source.signOutInteractive();
      await flushSessionWork();
      expect(f.handoff.account, isNull);
      final repeat = f.next('token', 'id_token');
      final login = flow.signIn();
      await repeat.started.future;
      repeat.reply(_session('google-owner', 2));
      expect(await login, GoogleAuthState.admitted);
      await f.handoff.retry();
      expect(f.controller.subject, 'google-owner');
      expect(f.backend.calls.where((path) => path.endsWith('/initialize')),
          hasLength(1));
    });

    test(
        'real SDK rejects token and sessionless responses without backend access',
        () async {
      final f = await _fixture();
      final flow = f.newGoogle();
      final invalid = f.next('token', 'id_token');
      final rejection = flow.signIn();
      await invalid.started.future;
      invalid.result.complete(http.Response(
          jsonEncode({'code': 400, 'msg': 'Synthetic invalid credentials'}),
          400,
          headers: {'content-type': 'application/json'}));
      expect(await rejection, GoogleAuthState.exchangeRejected);

      final absent = f.next('token', 'id_token');
      final login = flow.signIn();
      await absent.started.future;
      absent.reply(_user('no-session'));
      // This GoTrue version throws before returning a sessionless response.
      expect(await login, GoogleAuthState.exchangeRejected);
      expect(f.backend.calls, isEmpty);
      expect(f.controller.backendSession, isNull);
    });

    test('unconfirmed SDK session is never admitted', () async {
      final f = await _fixture();
      final request = f.next('token', 'id_token');
      final pending = f.newGoogle().signIn();
      await request.started.future;
      final unconfirmed = _user('unconfirmed')..remove('email_confirmed_at');
      request.reply(_session('unconfirmed')..['user'] = unconfirmed);
      expect(await pending, GoogleAuthState.confirmationRequired);
      await flushSessionWork();
      expect(f.sdk.currentSession?.user.id, 'unconfirmed');
      expect(f.controller.backendSession, isNull);
      expect(f.backend.calls, isEmpty);
    });

    test('late Google token response after logout cannot start handoff',
        () async {
      final f = await _fixture();
      final request = f.next('token', 'id_token');
      final flow = f.newGoogle();
      final pending = flow.signIn();
      await request.started.future;
      await f.source.signOutInteractive();
      request.reply(_session('late-owner'));
      expect(await pending, GoogleAuthState.superseded);
      await flushSessionWork();
      expect(f.sdk.currentSession?.user.id, 'late-owner');
      expect(await f.storage.accessToken(), isNotNull);
      expect(f.store.values['test.flow'], isNull);
      final restored = SupabaseSessionSource(f.sdk, f.storage);
      await expectLater(restored.resolve(await restored.restore()),
          throwsA(isA<SessionUnavailableException>()));
      expect(f.controller.backendSession, isNull);
      expect(f.backend.calls, isEmpty);
    });

    test(
        'late Google A cannot replace admitted Google B, even with matching emails',
        () async {
      final f = await _fixture();
      final a = f.next('token', 'id_token');
      final first = f.newGoogle().signIn();
      await a.started.future;
      await f.source.signOutInteractive();
      await flushSessionWork();
      final b = f.next('token', 'id_token');
      final latest = f.newGoogle().signIn();
      await b.started.future;
      b.reply(_session('google-b'));
      expect(await latest, GoogleAuthState.admitted);
      await f.handoff.retry();
      expect(f.controller.subject, 'google-b');
      expect(f.handoff.account, isNotNull);
      a.reply(_session('google-a'));
      expect(await first, GoogleAuthState.superseded);
      await flushSessionWork();
      expect(f.sdk.currentSession?.user.id, 'google-a');
      expect(f.controller.phase, SessionPhase.unavailable);
      expect(f.handoff.account, isNull);
      expect(f.handoff.status, isNull);
      expect(f.backend.calls, hasLength(2));
    });

    test('email and Google use one lease and the Supabase UUID owns handoff',
        () async {
      final f = await _fixture();
      final email = f.newFlow();
      final google = f.newGoogle();
      final request = f.next('token', 'password');
      final pending = email.signIn(_email, _password);
      await request.started.future;
      expect(await google.signIn(), GoogleAuthState.busy);
      request.reply(_session('email-owner'));
      expect((await pending).state, EmailAuthState.authenticated);
      await f.handoff.retry();
      expect(await google.signIn(), GoogleAuthState.blocked);
      expect(f.controller.subject, 'email-owner');
      await f.source.signOutInteractive();
      await flushSessionWork();
      expect(f.handoff.account, isNull);

      final exchange = f.next('token', 'id_token');
      final login = google.signIn();
      await exchange.started.future;
      expect(f.handoff.account, isNull);
      exchange.reply(_session('different-google-owner'));
      expect(await login, GoogleAuthState.admitted);
      await f.handoff.retry();
      expect(f.controller.subject, 'different-google-owner');
      expect(f.backend.calls, [
        '/api/v1/account/me',
        '/api/v1/onboarding/status',
        '/api/v1/account/me',
        '/api/v1/onboarding/status'
      ]);
    });

    test('recovery blocks Google and invalidates an outstanding exchange',
        () async {
      final f = await _fixture();
      final flow = f.newGoogle();
      final request = f.next('token', 'id_token');
      final pending = flow.signIn();
      await request.started.future;
      final recovery = f.next('verify', 'recovery');
      final recovering =
          f.sdk.verifyOTP(email: _email, token: _code, type: OtpType.recovery);
      await recovery.started.future;
      recovery.reply(_session('recovering'));
      await recovering;
      await flushSessionWork();
      request.reply(_session('late-google'));
      expect(await pending, GoogleAuthState.superseded);
      expect(await flow.signIn(), GoogleAuthState.blocked);
      await flushSessionWork();
      expect(f.controller.phase, SessionPhase.recovery);
      expect(f.controller.backendSession, isNull);
      expect(f.backend.calls, isEmpty);
    });

    test('refresh pending across logout cannot claim the Google lease',
        () async {
      final f = await _fixture();
      await f.login(f.newFlow(), 'retiring-owner');
      final refresh = f.next('token', 'refresh_token');
      final refreshing = f.sdk.refreshSession();
      await refresh.started.future;
      await f.source.signOutInteractive();
      await flushSessionWork();
      final request = f.next('token', 'id_token');
      final google = f.newGoogle();
      final pending = google.signIn();
      await request.started.future;
      refresh.reply(_session('retiring-owner', 2));
      await refreshing;
      await flushSessionWork();
      expect(f.controller.backendSession, isNull);
      expect(f.handoff.account, isNull);
      request.reply(_session('new-google-owner'));
      expect(await pending, GoogleAuthState.admitted);
      expect(f.controller.subject, 'new-google-owner');
    });

    test('failed secure-storage cleanup rejects an in-flight Google session',
        () async {
      final f = await _fixture();
      final request = f.next('token', 'id_token');
      final pending = f.newGoogle().signIn();
      await request.started.future;
      f.store.failFlowDelete = true;
      await expectLater(f.source.signOutInteractive(),
          throwsA(isA<SessionUnavailableException>()));
      request.reply(_session('late-google'));
      expect(await pending, GoogleAuthState.superseded);
      await flushSessionWork();
      expect(f.storage.hasFailed, isTrue);
      expect(f.controller.phase, SessionPhase.unavailable);
      expect(f.controller.backendSession, isNull);
      expect(f.backend.calls, isEmpty);
    });

    test(
        'a stale Google account read cannot resume handoff after account switch',
        () async {
      final f = await _fixture();
      final release = Completer<void>();
      f.backend.releaseNextMe = release;
      const oldSubject = '10000000-0000-4000-8000-000000000001';
      const newSubject = '10000000-0000-4000-8000-000000000002';

      final first = f.next('token', 'id_token');
      final initial = f.newGoogle().signIn();
      await first.started.future;
      first.reply(_session(oldSubject));
      expect(await initial, GoogleAuthState.admitted);
      await f.backend.meHeld.future;

      try {
        await f.source.signOutInteractive();
        await flushSessionWork();
        expect(f.handoff.account, isNull);
        final second = f.next('token', 'id_token');
        final latest = f.newGoogle().signIn();
        await second.started.future;
        second.reply(_session(newSubject));
        expect(await latest, GoogleAuthState.admitted);
        await f.handoff.retry();
      } finally {
        release.complete();
      }
      await flushSessionWork();
      expect(f.controller.subject, newSubject);
      expect(f.handoff.account, isNotNull);
      expect(f.backend.calls, [
        '/api/v1/account/me',
        '/api/v1/account/me',
        '/api/v1/onboarding/status'
      ]);
    });

    test('disposing a pending Google controller releases admission', () async {
      final f = await _fixture();
      final flow = f.newGoogle();
      final request = f.next('token', 'id_token');
      final pending = flow.signIn();
      await request.started.future;
      f.googleFlows.remove(flow);
      flow.dispose();
      request.reply(_session('disposed-owner'));
      expect(await pending, GoogleAuthState.superseded);
      await flushSessionWork();
      expect(f.controller.backendSession, isNull);
      expect(f.backend.calls, isEmpty);
    });
  });
}
