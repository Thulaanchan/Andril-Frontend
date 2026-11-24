enum PasswordOperation { forgot, reset, change }

enum PasswordOutcome {
  idle,
  requestAccepted,
  passwordUpdated,
  invalidEmail,
  passwordRequired,
  passwordMismatch,
  passwordRejected,
  sessionRequired,
  recoveryRequired,
  recoveryInvalid,
  reauthenticationRequired,
  configurationPending,
  sessionChanged,
  rateLimited,
  unavailable,
  busy,
}

/// Outputs contain only typed states. No passwords, links or provider messages.
abstract interface class PasswordSecurityRepository {
  Future<PasswordOutcome> requestRecovery(String email);
  Future<PasswordOutcome> updatePassword(
      PasswordOperation operation, String password);
}
