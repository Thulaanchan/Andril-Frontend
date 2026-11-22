import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';

/// SDK contract adapter exercised with an injected mock. GoTrue's interactive
/// methods install a returned session before completing their Futures. Live
/// composition needs an approved guard against late SDK session mutation.
class SupabaseAuthRepository implements AuthRepository {
  @visibleForTesting
  const SupabaseAuthRepository.forContractTests(
    this._auth, {
    this.signupOtpSupported = false,
  });

  final GoTrueClient _auth;
  final bool signupOtpSupported;

  @override
  Future<AuthRepositoryResult> register(String email, String password) =>
      _sessionCall(() => _auth.signUp(email: email, password: password),
          neutralExistence: true);

  @override
  Future<AuthRepositoryResult> signIn(String email, String password) =>
      _sessionCall(
          () => _auth.signInWithPassword(email: email, password: password),
          passwordLogin: true);

  @override
  Future<AuthRepositoryResult> verifySignupCode(String email, String code) =>
      signupOtpSupported
          ? _sessionCall(() =>
              _auth.verifyOTP(email: email, token: code, type: OtpType.email))
          : Future.value(_configurationPending);

  @override
  Future<AuthRepositoryResult> resendSignupCode(String email) async {
    if (!signupOtpSupported) return _configurationPending;
    try {
      await _auth.resend(type: OtpType.signup, email: email);
      return const AuthRepositoryResult();
    } catch (error) {
      return _classify(error, neutralExistence: true);
    }
  }

  static const _configurationPending =
      AuthRepositoryResult(issue: EmailAuthIssue.configurationPending);

  Future<AuthRepositoryResult> _sessionCall(
      Future<AuthResponse> Function() call,
      {bool neutralExistence = false,
      bool passwordLogin = false}) async {
    try {
      final response = await call();
      final session = response.session;
      if (session == null || session.accessToken.isEmpty) {
        return const AuthRepositoryResult();
      }
      final subject = session.user.id;
      final token = session.accessToken;
      return AuthRepositoryResult(
          session: AuthSessionReceipt((credential) =>
              credential.subject == subject &&
              credential.accessToken == token));
    } catch (error) {
      return _classify(error,
          neutralExistence: neutralExistence, passwordLogin: passwordLogin);
    }
  }

  AuthRepositoryResult _classify(Object error,
      {required bool neutralExistence, bool passwordLogin = false}) {
    if (error is TimeoutException || error is AuthRetryableFetchException) {
      return const AuthRepositoryResult(issue: EmailAuthIssue.unavailable);
    }
    if (error is AuthWeakPasswordException) {
      return const AuthRepositoryResult(issue: EmailAuthIssue.passwordRejected);
    }
    if (error is AuthException) {
      final code = error.code;
      if (neutralExistence &&
          const {'user_already_exists', 'email_exists', 'user_not_found'}
              .contains(code)) {
        return const AuthRepositoryResult();
      }
      if (error.statusCode == '429' ||
          const {
            'over_email_send_rate_limit',
            'over_request_rate_limit',
          }.contains(code)) {
        return const AuthRepositoryResult(issue: EmailAuthIssue.rateLimited);
      }
      return AuthRepositoryResult(
          issue: switch (code) {
        'weak_password' => EmailAuthIssue.passwordRejected,
        'email_address_invalid' => EmailAuthIssue.invalidEmail,
        'user_not_found' when passwordLogin =>
          EmailAuthIssue.invalidCredentials,
        'invalid_credentials' => EmailAuthIssue.invalidCredentials,
        'email_not_confirmed' => EmailAuthIssue.confirmationRequired,
        'otp_expired' || 'invalid_otp' => EmailAuthIssue.invalidOrExpiredCode,
        _ => EmailAuthIssue.unavailable,
      });
    }
    return const AuthRepositoryResult(issue: EmailAuthIssue.unavailable);
  }
}
