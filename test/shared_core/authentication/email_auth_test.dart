import 'dart:async';
import 'dart:convert';

import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/shared_core/account/account_handoff_controller.dart';
import 'package:andril_mobile/shared_core/authentication/data/repositories/supabase_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/email_auth_controller.dart';
import 'package:andril_mobile/shared_core/authentication/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'foundation_fakes.dart';

const _email = 'synthetic@example.invalid';
const _password = 'synthetic-password';
const _code = '001234';

class _Auth extends Mock implements GoTrueClient {}

class _SessionSource extends FakeSessionSource implements BackendSessionSource {
  @override
  BackendCredential? backendCredential;

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}

  void publish(Session session,
      {bool confirmed = true, bool recovery = false}) {
    backendCredential = BackendCredential(session.user.id, session.accessToken,
        emailConfirmed: confirmed);
    signals.add(SessionEvent(
        recovery ? SessionEventKind.recovery : SessionEventKind.signedIn,
        subject: session.user.id));
  }

  void logout() {
    backendCredential = null;
    signals.add(const SessionEvent(SessionEventKind.signedOut));
  }
}

Session _responseSession([String subject = 'a']) => Session(
    accessToken: 'fake.$subject.token',
    tokenType: 'bearer',
    user: User(
        id: subject,
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z'));

class _HandoffAdapter implements HttpClientAdapter {
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    paths.add(options.uri.path);
    expect(options.headers['Authorization'], 'Bearer fake.a.token');
    final body = options.uri.path.endsWith('/me')
        ? {
            'accountId': '016f6ec2-c23e-49b1-ae12-35edf9759ed4',
            'createdAtUtc': '2026-11-22T03:00:00Z',
            'updatedAtUtc': '2026-11-22T03:00:00Z',
          }
        : {
            'nextStep': 'complete_demographics',
            'selectedModule': null,
            'blockingDependency': null,
            'onboardingComplete': false,
            'moduleHomeAuthorized': false,
            'progress': {
              'identityVerified': true,
              'accountInitialized': true,
              'demographicsComplete': false,
              'currentPoliciesAccepted': false,
              'starterModuleSelected': false,
              'privateProfileComplete': false,
            }
          };
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      'content-type': ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<
    ({
      _Auth sdk,
      _SessionSource source,
      SessionController session,
      EmailAuthController flow
    })> _fixture({bool otp = true}) async {
  final sdk = _Auth();
  final source = _SessionSource();
  final session = SessionController(source);
  await session.start();
  final flow = EmailAuthController(
      SupabaseAuthRepository.forContractTests(sdk, signupOtpSupported: otp),
      session,
      sessionWait: const Duration(seconds: 2));
  addTearDown(() async {
    flow.dispose();
    session.dispose();
    await source.signals.close();
  });
  when(() => sdk.signUp(email: _email, password: _password))
      .thenAnswer((_) async => AuthResponse(user: _responseSession().user));
  return (sdk: sdk, source: source, session: session, flow: flow);
}

void main() {
  test('valid signup and user-only response open neutral pending verification',
      () async {
    final f = await _fixture();
    final result = await f.flow.register('  $_email  ', _password);
    expect(result.state, EmailAuthState.verificationPending);
    expect(result.issue, isNull);
    expect(f.session.phase, SessionPhase.signedOut);
    expect(f.flow.awaitingVerification, isTrue);
    verify(() => f.sdk.signUp(email: _email, password: _password)).called(1);
  });

  for (final (email, password, confirmation, issue) in [
    ('not-an-email', _password, null, EmailAuthIssue.invalidEmail),
    (_email, '', null, EmailAuthIssue.passwordRequired),
    (_email, _password, 'mismatch', EmailAuthIssue.passwordMismatch),
  ]) {
    test('local input rejection ${issue.name}', () async {
      final f = await _fixture();
      expect(
          (await f.flow.register(email, password,
                  passwordConfirmation: confirmation))
              .issue,
          issue);
      verifyNever(() => f.sdk.signUp(
          email: any(named: 'email'), password: any(named: 'password')));
    });
  }

  test(
      'provider password rejection does not introduce a client password policy',
      () async {
    final f = await _fixture();
    when(() => f.sdk.signUp(email: _email, password: 'x')).thenThrow(
        const AuthApiException('synthetic private detail',
            code: 'weak_password'));
    expect((await f.flow.register(_email, 'x')).issue,
        EmailAuthIssue.passwordRejected);
    verify(() => f.sdk.signUp(email: _email, password: 'x')).called(1);
  });

  test('duplicate signup submission does not reach the SDK', () async {
    final f = await _fixture();
    final reply = Completer<AuthResponse>();
    when(() => f.sdk.signUp(email: _email, password: _password))
        .thenAnswer((_) => reply.future);
    final first = f.flow.register(_email, _password);
    expect(f.flow.busy, isTrue);
    expect(
        (await f.flow.register(_email, _password)).issue, EmailAuthIssue.busy);
    reply.complete(AuthResponse());
    expect((await first).state, EmailAuthState.verificationPending);
    verify(() => f.sdk.signUp(email: _email, password: _password)).called(1);
  });

  test('explicit account existence responses match the neutral signup state',
      () async {
    final f = await _fixture();
    when(() => f.sdk.signUp(email: _email, password: _password)).thenThrow(
        const AuthApiException('synthetic private detail',
            code: 'user_already_exists'));
    expect((await f.flow.register(_email, _password)).state,
        EmailAuthState.verificationPending);
    expect(f.flow.outcome.issue, isNull);
  });

  test(
      'signup provider error is sanitized and does not create a verification flow',
      () async {
    final f = await _fixture();
    when(() => f.sdk.signUp(email: _email, password: _password))
        .thenThrow(AuthRetryableFetchException(message: _password));
    final logs = <String>[];
    final result = await runZoned(() => f.flow.register(_email, _password),
        zoneSpecification:
            ZoneSpecification(print: (_, __, ___, line) => logs.add(line)));
    expect(result.issue, EmailAuthIssue.unavailable);
    expect(f.flow.awaitingVerification, isFalse);
    expect(logs, isEmpty);
    expect(result.toString(), isNot(contains(_password)));
  });

  test('provider configuration gate prevents OTP and resend SDK calls',
      () async {
    final f = await _fixture(otp: false);
    await f.flow.register(_email, _password);
    expect((await f.flow.verifyCode(_code)).issue,
        EmailAuthIssue.configurationPending);
    expect(
        (await f.flow.resendCode()).issue, EmailAuthIssue.configurationPending);
    verifyNever(() =>
        f.sdk.verifyOTP(email: _email, token: _code, type: OtpType.email));
    verifyNever(() => f.sdk.resend(email: _email, type: OtpType.signup));
  });

  test('only the active signup address can verify; cancel drops the flow',
      () async {
    final f = await _fixture();
    expect((await f.flow.verifyCode(_code)).issue, EmailAuthIssue.invalidFlow);
    await f.flow.register(_email, _password);
    expect((await f.flow.verifyCode('１２３４５６')).issue,
        EmailAuthIssue.invalidOrExpiredCode);
    expect((await f.flow.verifyCode('123456\n')).issue,
        EmailAuthIssue.invalidOrExpiredCode);
    f.flow.cancel();
    expect((await f.flow.verifyCode(_code)).issue, EmailAuthIssue.invalidFlow);
    verifyNever(() => f.sdk.verifyOTP(
        email: any(named: 'email'),
        token: any(named: 'token'),
        type: OtpType.email));
  });

  test(
      'leading zeroes reach email verification and exact ordinary session starts handoff once',
      () async {
    final f = await _fixture();
    final adapter = _HandoffAdapter();
    final api = AndrilApiClient(
        AppConfig.fromValues(
          environment: 'development',
          supabaseUrl: 'https://synthetic.supabase.co',
          publicKey: 'sb_publishable_synthetic',
          apiBaseUrl: 'https://backend.invalid',
        ),
        f.session,
        adapter: adapter);
    final handoff = AccountHandoffController(f.session, api);
    addTearDown(handoff.dispose);
    await f.flow.register(_email, _password);
    expect(adapter.paths, isEmpty);
    final session = _responseSession();
    when(() =>
            f.sdk.verifyOTP(email: _email, token: _code, type: OtpType.email))
        .thenAnswer((_) async => AuthResponse(session: session));
    final verifying = f.flow.verifyCode(_code);
    await flushSessionWork();
    expect(f.flow.busy, isTrue);
    expect(adapter.paths, isEmpty);
    f.source.publish(session);
    expect((await verifying).state, EmailAuthState.authenticated);
    await handoff.retry();
    expect(adapter.paths, ['/api/v1/account/me', '/api/v1/onboarding/status']);
    expect(handoff.status?.moduleHomeAuthorized, isFalse);
    expect(f.flow.awaitingVerification, isFalse);
  });

  for (final providerCode in ['otp_expired', 'invalid_otp']) {
    test(
        'expired, reused, and invalid code responses stay in the verification flow $providerCode',
        () async {
      final f = await _fixture();
      await f.flow.register(_email, _password);
      when(() =>
              f.sdk.verifyOTP(email: _email, token: _code, type: OtpType.email))
          .thenThrow(
              AuthApiException('synthetic private $_code', code: providerCode));
      expect((await f.flow.verifyCode(_code)).issue,
          EmailAuthIssue.invalidOrExpiredCode);
      expect(f.flow.awaitingVerification, isTrue);
      expect(f.session.phase, SessionPhase.signedOut);
    });
  }

  test('verification without a session does not infer confirmation', () async {
    final f = await _fixture();
    await f.flow.register(_email, _password);
    when(() =>
            f.sdk.verifyOTP(email: _email, token: _code, type: OtpType.email))
        .thenAnswer((_) async => AuthResponse());
    expect((await f.flow.verifyCode(_code)).issue,
        EmailAuthIssue.confirmationRequired);
    expect(f.flow.awaitingVerification, isTrue);
  });

  test('resend uses signup type, blocks duplicate taps, and honors throttling',
      () async {
    final f = await _fixture();
    await f.flow.register(_email, _password);
    final reply = Completer<ResendResponse>();
    when(() => f.sdk.resend(email: _email, type: OtpType.signup))
        .thenAnswer((_) => reply.future);
    final first = f.flow.resendCode();
    expect((await f.flow.resendCode()).issue, EmailAuthIssue.busy);
    reply.complete(ResendResponse());
    expect((await first).state, EmailAuthState.verificationPending);
    verify(() => f.sdk.resend(email: _email, type: OtpType.signup)).called(1);
    when(() => f.sdk.resend(email: _email, type: OtpType.signup))
        .thenThrow(const AuthApiException('private', statusCode: '429'));
    expect((await f.flow.resendCode()).issue, EmailAuthIssue.rateLimited);
  });

  test(
      'password login waits for the SDK session and permits subsequent different identities after logout',
      () async {
    final f = await _fixture();
    for (final subject in ['a', 'a', 'b']) {
      final session = _responseSession(subject);
      when(() => f.sdk.signInWithPassword(email: _email, password: _password))
          .thenAnswer((_) async => AuthResponse(session: session));
      final working = f.flow.signIn(_email, _password);
      expect(
          (await f.flow.signIn(_email, _password)).issue, EmailAuthIssue.busy);
      f.source.publish(session);
      expect((await working).state, EmailAuthState.authenticated);
      expect(f.session.subject, subject);
      f.source.logout();
      await flushSessionWork();
      expect(f.flow.outcome.state, EmailAuthState.idle);
    }
  });

  test(
      'a same-subject session with a different token cannot satisfy an outstanding login',
      () async {
    final f = await _fixture();
    final response = _responseSession();
    when(() => f.sdk.signInWithPassword(email: _email, password: _password))
        .thenAnswer((_) async => AuthResponse(session: response));
    final working = f.flow.signIn(_email, _password);
    f.source.publish(Session(
        accessToken: 'different.token.value',
        tokenType: 'bearer',
        user: response.user));
    expect((await working).issue, EmailAuthIssue.confirmationRequired);
  });

  test('invalid credentials and offline login return safe typed errors',
      () async {
    final f = await _fixture();
    for (final (error, issue) in [
      (
        const AuthApiException('private', code: 'invalid_credentials'),
        EmailAuthIssue.invalidCredentials
      ),
      (TimeoutException('private'), EmailAuthIssue.unavailable),
    ]) {
      when(() => f.sdk.signInWithPassword(email: _email, password: _password))
          .thenThrow(error);
      expect((await f.flow.signIn(_email, _password)).issue, issue);
      expect(f.session.phase, SessionPhase.signedOut);
    }
  });

  test('unconfirmed password login enters neutral verification pending',
      () async {
    final f = await _fixture();
    when(() => f.sdk.signInWithPassword(email: _email, password: _password))
        .thenThrow(
            const AuthApiException('private', code: 'email_not_confirmed'));
    expect((await f.flow.signIn(_email, _password)).state,
        EmailAuthState.verificationPending);
    expect(f.session.phase, SessionPhase.signedOut);
  });

  test(
      'logout invalidates delayed login completion and leaves no ordinary session',
      () async {
    final f = await _fixture();
    final delayed = Completer<AuthResponse>();
    when(() => f.sdk.signInWithPassword(email: _email, password: _password))
        .thenAnswer((_) => delayed.future);
    final working = f.flow.signIn(_email, _password);
    f.source.logout();
    delayed.complete(AuthResponse(session: _responseSession()));
    expect((await working).issue, EmailAuthIssue.sessionChanged);
    expect(f.session.backendSession, isNull);
  });

  test('recovery is never an ordinary verification success', () async {
    final f = await _fixture();
    await f.flow.register(_email, _password);
    final response = _responseSession();
    when(() =>
            f.sdk.verifyOTP(email: _email, token: _code, type: OtpType.email))
        .thenAnswer((_) async => AuthResponse(session: response));
    final working = f.flow.verifyCode(_code);
    f.source.publish(response, recovery: true);
    expect((await working).issue, EmailAuthIssue.sessionChanged);
    expect(f.session.backendSession, isNull);
  });
  test('verification with an unconfirmed SDK session is never a success',
      () async {
    final f = await _fixture();
    await f.flow.register(_email, _password);
    final response = _responseSession();
    when(() =>
            f.sdk.verifyOTP(email: _email, token: _code, type: OtpType.email))
        .thenAnswer((_) async => AuthResponse(session: response));
    final working = f.flow.verifyCode(_code);
    f.source.publish(response, confirmed: false);
    expect((await working).issue, EmailAuthIssue.confirmationRequired);
    expect(f.flow.outcome.state, EmailAuthState.failed);
    expect(f.session.moduleHomeAuthorized, isFalse);
  });
}
