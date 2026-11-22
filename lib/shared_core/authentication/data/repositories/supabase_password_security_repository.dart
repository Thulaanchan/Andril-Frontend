import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/security/session/session_controller.dart';
import '../../domain/repositories/password_security_repository.dart';

typedef RecoveryEvidence = ({int generation, AuthState event});

/// Contract test adapter only. GoTrue's password update may mutate its current
/// SDK session after awaiting the response. This boundary can discard an
/// obsolete result; it cannot prevent the SDK mutation or durable writes.
class SupabasePasswordSecurityRepository implements PasswordSecurityRepository {
  @visibleForTesting
  const SupabasePasswordSecurityRepository.forContractTests(
      this._auth, this._sessions,
      {this.syntheticRecoveryRedirect, this.recoveryEvidence});

  final GoTrueClient _auth;
  final SessionController _sessions;
  final Uri? syntheticRecoveryRedirect;
  final RecoveryEvidence? Function()? recoveryEvidence;

  @override
  Future<PasswordOutcome> requestRecovery(String email) async {
    final redirect = syntheticRecoveryRedirect;
    // Even the mock adapter has no unstated default callback target.
    if (redirect == null) return PasswordOutcome.configurationPending;
    if (_sessions.phase != SessionPhase.signedOut ||
        _auth.currentSession != null) {
      return PasswordOutcome.sessionChanged;
    }
    final generation = _sessions.generation;
    PasswordOutcome result;
    try {
      await _auth.resetPasswordForEmail(email, redirectTo: redirect.toString());
      result = PasswordOutcome.requestAccepted;
    } catch (error) {
      result = _classify(error, PasswordOperation.forgot);
    }
    return _sessions.isCurrent(generation) && _auth.currentSession == null
        ? result
        : PasswordOutcome.sessionChanged;
  }

  @override
  Future<PasswordOutcome> updatePassword(
      PasswordOperation operation, String password) async {
    if (operation == PasswordOperation.forgot) {
      return PasswordOutcome.sessionRequired;
    }
    final generation = _sessions.generation;
    final current = _auth.currentSession;
    final required = operation == PasswordOperation.reset
        ? PasswordOutcome.recoveryRequired
        : PasswordOutcome.sessionRequired;
    if (current == null || current.isExpired || current.accessToken.isEmpty) {
      return required;
    }
    final subject = current.user.id;
    final token = current.accessToken;
    if (_sessions.subject != subject) return required;
    if (operation == PasswordOperation.reset) {
      final evidence = recoveryEvidence?.call();
      if (_sessions.phase != SessionPhase.recovery ||
          evidence == null ||
          evidence.generation != generation ||
          evidence.event.event != AuthChangeEvent.passwordRecovery ||
          evidence.event.session?.accessToken != token ||
          evidence.event.session?.user.id != subject) {
        return required;
      }
    } else {
      final owner = _sessions.backendSession;
      final credential = owner == null ? null : _sessions.credentialFor(owner);
      if (credential == null ||
          !credential.emailConfirmed ||
          credential.accessToken != token ||
          credential.subject != subject) {
        return required;
      }
    }
    PasswordOutcome result;
    try {
      final response =
          await _auth.updateUser(UserAttributes(password: password));
      result = response.user?.id == subject
          ? PasswordOutcome.passwordUpdated
          : PasswordOutcome.sessionChanged;
    } catch (error) {
      result = _classify(error, operation);
    }
    final latest = _auth.currentSession;
    return _sessions.isCurrent(generation) &&
            latest?.user.id == subject &&
            latest?.accessToken == token
        ? result
        : PasswordOutcome.sessionChanged;
  }

  static PasswordOutcome _classify(Object error, PasswordOperation operation) {
    if (error is AuthException) {
      final code = error.code;
      if (error.statusCode == '429' ||
          const {'over_email_send_rate_limit', 'over_request_rate_limit'}
              .contains(code)) {
        return PasswordOutcome.rateLimited;
      }
      if (operation == PasswordOperation.forgot &&
          (code == 'user_not_found' || code == 'email_not_found')) {
        return PasswordOutcome.requestAccepted;
      }
      if (error is AuthWeakPasswordException || code == 'weak_password') {
        return PasswordOutcome.passwordRejected;
      }
      if (const {
        'reauthentication_needed',
        'reauthentication_not_valid',
        'insufficient_aal',
        'current_password_required',
        'current_password_mismatch',
      }.contains(code)) {
        return PasswordOutcome.reauthenticationRequired;
      }
      if (error is AuthSessionMissingException ||
          const {
            'otp_expired',
            'flow_state_expired',
            'flow_state_not_found',
            'bad_jwt',
            'session_not_found',
            'session_expired'
          }.contains(code)) {
        return operation == PasswordOperation.reset
            ? PasswordOutcome.recoveryInvalid
            : PasswordOutcome.sessionRequired;
      }
    }

    return PasswordOutcome.unavailable;
  }
}
