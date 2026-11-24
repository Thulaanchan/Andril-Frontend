import 'package:andril_mobile/shared_core/authentication/domain/repositories/password_security_repository.dart';
import 'dart:async';
import 'dart:convert';

import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/shared_core/authentication/data/repositories/supabase_password_security_repository.dart';
import 'package:andril_mobile/shared_core/authentication/password_recovery/viewmodels/password_security_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'foundation_fakes.dart';

const _email = 'synthetic@example.invalid';
const _password = 'synthetic-password';
final _redirect = Uri.parse('https://synthetic.invalid/recovery-test');

class _Auth extends Mock implements GoTrueClient {}

class _Source extends FakeSessionSource implements BackendSessionSource {
  @override
  BackendCredential? backendCredential;

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}
}

Session _session(String subject, {bool expired = false, int revision = 1}) {
  final expiry =
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + (expired ? -60 : 3600);
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({
        'sub': subject,
        'exp': expiry,
        'rev': revision,
      })))
      .replaceAll('=', '');
  return Session(
      accessToken: 'synthetic.$payload.signature',
      tokenType: 'bearer',
      user: User(
          id: subject,
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: '2026-11-22T00:00:00Z'));
}

class _Fixture {
  final sdk = _Auth();
  final source = _Source();
  late final SessionController sessions = SessionController(source);
  Session? current;
  RecoveryEvidence? receipt;
  late final SupabasePasswordSecurityRepository repository;
  late final PasswordSecurityController controller;

  Future<void> start({bool configured = true}) async {
    when(() => sdk.currentSession).thenAnswer((_) => current);
    repository = SupabasePasswordSecurityRepository.forContractTests(
      sdk,
      sessions,
      syntheticRecoveryRedirect: configured ? _redirect : null,
      recoveryEvidence: () => receipt,
    );
    await sessions.start();
    controller = PasswordSecurityController(sessions, repository);
  }

  Future<void> publish(Session session,
      {bool recovering = false, bool confirmed = true}) async {
    current = session;
    source.backendCredential = BackendCredential(
        session.user.id, session.accessToken,
        emailConfirmed: confirmed);
    source.signals.add(SessionEvent(
        recovering ? SessionEventKind.recovery : SessionEventKind.signedIn,
        subject: session.user.id));
    await flushSessionWork();
    if (recovering) {
      receipt = (
        generation: sessions.generation,
        event: AuthState(AuthChangeEvent.passwordRecovery, session)
      );
    }
  }

  void logout() {
    current = null;
    source.backendCredential = null;
    source.signals.add(const SessionEvent(SessionEventKind.signedOut));
  }

  Future<void> close() async {
    controller.dispose();
    sessions.dispose();
    await source.signals.close();
  }

  void stubUpdate(Session owner) {
    when(() => sdk.updateUser(any()))
        .thenAnswer((_) async => UserResponse.fromJson(owner.user.toJson()));
  }
}

Future<_Fixture> _fixture({bool configured = true}) async {
  final f = _Fixture();
  await f.start(configured: configured);
  addTearDown(f.close);
  return f;
}

void main() {
  setUpAll(() => registerFallbackValue(UserAttributes()));

  for (final email in ['wrong', '', ' ']) {
    test('forgot password refuses invalid email $email', () async {
      final f = await _fixture();
      expect(await f.controller.forgotPassword(email),
          PasswordOutcome.invalidEmail);
      verifyNever(() => f.sdk
          .resetPasswordForEmail(any(), redirectTo: any(named: 'redirectTo')));
    });
  }

  test('recovery request needs an explicitly provided callback fixture',
      () async {
    final f = await _fixture(configured: false);
    expect(await f.controller.forgotPassword(_email),
        PasswordOutcome.configurationPending);
    verifyNever(() => f.sdk
        .resetPasswordForEmail(any(), redirectTo: any(named: 'redirectTo')));
  });

  test(
      'accepted recovery is neutral, scoped to the provider, and does not sign in',
      () async {
    final f = await _fixture();
    when(() => f.sdk.resetPasswordForEmail(_email,
        redirectTo: _redirect.toString())).thenAnswer((_) async {});
    final accepted = await f.controller.forgotPassword(' $_email ');
    when(() => f.sdk
            .resetPasswordForEmail(_email, redirectTo: _redirect.toString()))
        .thenThrow(const AuthApiException('synthetic private address',
            code: 'user_not_found'));
    expect(await f.controller.forgotPassword(_email), accepted);
    expect(accepted, PasswordOutcome.requestAccepted);
    expect(f.sessions.phase, SessionPhase.signedOut);
    expect(f.sessions.backendSession, isNull);
  });

  for (final (ex, expected) in [
    (
      const AuthApiException('private', statusCode: '429'),
      PasswordOutcome.rateLimited
    ),
    (
      const AuthApiException('private', code: 'unexpected_failure'),
      PasswordOutcome.unavailable
    ),
    (
      AuthRetryableFetchException(message: 'private'),
      PasswordOutcome.unavailable
    ),
    (TimeoutException('private'), PasswordOutcome.unavailable),
  ]) {
    test('forgot password maps provider failure to $expected', () async {
      final f = await _fixture();
      when(() => f.sdk.resetPasswordForEmail(_email,
          redirectTo: _redirect.toString())).thenThrow(ex);
      expect(await f.controller.forgotPassword(_email), expected);
    });
  }

  test('duplicate forgot password taps perform one provider call', () async {
    final f = await _fixture();
    final response = Completer<void>();
    when(() => f.sdk.resetPasswordForEmail(_email,
        redirectTo: _redirect.toString())).thenAnswer((_) => response.future);
    final pending = f.controller.forgotPassword(_email);
    expect(f.controller.busy, isTrue);
    expect(await f.controller.forgotPassword(_email), PasswordOutcome.busy);
    response.complete();
    expect(await pending, PasswordOutcome.requestAccepted);
    verify(() => f.sdk.resetPasswordForEmail(_email,
        redirectTo: _redirect.toString())).called(1);
  });

  test(
      'reset requires the exact recovery event and never promotes it to ordinary',
      () async {
    final f = await _fixture();
    final recovery = _session('recovery-user');
    await f.publish(recovery, recovering: true);
    f.stubUpdate(recovery);
    expect(await f.controller.resetPassword(_password, _password),
        PasswordOutcome.passwordUpdated);
    final captured = verify(() => f.sdk.updateUser(captureAny()))
        .captured
        .single as UserAttributes;
    expect(captured.password, _password);
    expect(captured.currentPassword, isNull);
    expect(captured.nonce, isNull);
    expect(f.sessions.phase, SessionPhase.recovery);
    expect(f.sessions.backendSession, isNull);
    expect(f.sessions.moduleHomeAuthorized, isFalse);
  });

  test('required password and confirmation are validated before provider calls',
      () async {
    final f = await _fixture();
    await f.publish(_session('recovery-user'), recovering: true);
    expect(await f.controller.resetPassword('', ''),
        PasswordOutcome.passwordRequired);
    expect(await f.controller.resetPassword(_password, 'different'),
        PasswordOutcome.passwordMismatch);
    verifyNever(() => f.sdk.updateUser(any()));
  });

  test(
      'no recovery receipt, token rotation without a receipt, and expired recovery are denied',
      () async {
    final f = await _fixture();
    final recovery = _session('recovery-user');
    await f.publish(recovery, recovering: true);
    f.receipt = null;
    expect(await f.controller.resetPassword(_password, _password),
        PasswordOutcome.recoveryRequired);
    await f.publish(recovery, recovering: true);
    f.current = _session('recovery-user', revision: 2);
    expect(await f.controller.resetPassword(_password, _password),
        PasswordOutcome.recoveryRequired);
    await f.publish(_session('recovery-user', expired: true), recovering: true);
    expect(await f.controller.resetPassword(_password, _password),
        PasswordOutcome.recoveryRequired);
    verifyNever(() => f.sdk.updateUser(any()));
  });

  for (final code in [
    'otp_expired',
    'flow_state_not_found',
    'session_not_found',
    'bad_jwt'
  ]) {
    test(
        'invalid, expired, or reused provider recovery maps to recoveryInvalid ($code)',
        () async {
      final f = await _fixture();
      await f.publish(_session('recovery-user'), recovering: true);
      when(() => f.sdk.updateUser(any()))
          .thenThrow(AuthApiException('private', code: code));
      expect(await f.controller.resetPassword(_password, _password),
          PasswordOutcome.recoveryInvalid);
      expect(f.sessions.backendSession, isNull);
    });
  }

  for (final switchAccount in [false, true]) {
    test(
        'late reset result is discarded after ${switchAccount ? 'account switch' : 'logout'}',
        () async {
      final f = await _fixture();
      final old = _session('A');
      await f.publish(old, recovering: true);
      final response = Completer<UserResponse>();
      when(() => f.sdk.updateUser(any())).thenAnswer((_) => response.future);
      final pending = f.controller.resetPassword(_password, _password);
      expect(await f.controller.resetPassword(_password, _password),
          PasswordOutcome.busy);
      f.logout();
      await flushSessionWork();
      if (switchAccount) await f.publish(_session('B'));
      response.complete(UserResponse.fromJson(old.user.toJson()));
      expect(await pending, PasswordOutcome.sessionChanged);
      expect(f.controller.outcome, PasswordOutcome.idle);
      expect(f.sessions.subject, switchAccount ? 'B' : null);
    });
  }

  test('ordinary verified password change works without granting module access',
      () async {
    final f = await _fixture();
    final owner = _session('A');
    await f.publish(owner);
    f.stubUpdate(owner);
    expect(await f.controller.changePassword(_password),
        PasswordOutcome.passwordUpdated);
    expect(f.sessions.backendSession?.subject, 'A');
    expect(f.sessions.moduleHomeAuthorized, isFalse);
  });

  test(
      'unauthenticated, ordinary unconfirmed and recovery-only changes are denied',
      () async {
    final f = await _fixture();
    expect(await f.controller.changePassword(_password),
        PasswordOutcome.sessionRequired);
    await f.publish(_session('A'), confirmed: false);
    expect(await f.controller.changePassword(_password),
        PasswordOutcome.sessionRequired);
    await f.publish(_session('A'), recovering: true);
    expect(await f.controller.changePassword(_password),
        PasswordOutcome.sessionRequired);
    verifyNever(() => f.sdk.updateUser(any()));
  });

  for (final (code, result) in [
    ('reauthentication_needed', PasswordOutcome.reauthenticationRequired),
    ('insufficient_aal', PasswordOutcome.reauthenticationRequired),
    ('current_password_required', PasswordOutcome.reauthenticationRequired),
    ('weak_password', PasswordOutcome.passwordRejected),
    ('provider_failure', PasswordOutcome.unavailable),
  ]) {
    test('ordinary password change redacts provider errors ($code)', () async {
      final f = await _fixture();
      await f.publish(_session('A'));
      when(() => f.sdk.updateUser(any()))
          .thenThrow(AuthApiException(_password, code: code));
      final logs = <String>[];
      final outcome = await runZoned(
          () => f.controller.changePassword(_password),
          zoneSpecification: ZoneSpecification(
              print: (_, __, ___, message) => logs.add(message)));
      expect(outcome, result);
      expect(logs, isEmpty);
      expect(outcome.toString(), isNot(contains(_password)));
      verify(() => f.sdk.updateUser(any())).called(1);
    });
  }

  test('ordinary password change cannot publish success to a different account',
      () async {
    final f = await _fixture();
    final old = _session('A');
    await f.publish(old);
    final response = Completer<UserResponse>();
    when(() => f.sdk.updateUser(any())).thenAnswer((_) => response.future);
    final pending = f.controller.changePassword(_password);
    await f.publish(_session('B'));
    response.complete(UserResponse.fromJson(old.user.toJson()));
    expect(await pending, PasswordOutcome.sessionChanged);
    expect(f.controller.outcome, PasswordOutcome.idle);
  });

  test('a replacement SDK token invalidates a change for the same subject',
      () async {
    final f = await _fixture();
    final old = _session('A');
    await f.publish(old);
    final response = Completer<UserResponse>();
    when(() => f.sdk.updateUser(any())).thenAnswer((_) => response.future);
    final pending = f.controller.changePassword(_password);
    f.current = _session('A', revision: 2);
    response.complete(UserResponse.fromJson(old.user.toJson()));
    expect(await pending, PasswordOutcome.sessionChanged);
  });
}
