import '../../../../core/security/session/session_controller.dart';

enum EmailAuthIssue {
  invalidEmail,
  passwordRequired,
  passwordMismatch,
  passwordRejected,
  invalidCredentials,
  confirmationRequired,
  invalidOrExpiredCode,
  invalidFlow,
  rateLimited,
  unavailable,
  configurationPending,
  busy,
  sessionChanged,
}

enum EmailAuthState { idle, verificationPending, authenticated, failed }

class EmailAuthOutcome {
  const EmailAuthOutcome(this.state, {this.issue});

  final EmailAuthState state;
  final EmailAuthIssue? issue;
}

/// Repository results carry no provider messages or raw SDK objects.
class AuthRepositoryResult {
  const AuthRepositoryResult({this.session, this.issue});
  final AuthSessionReceipt? session;
  final EmailAuthIssue? issue;
}

/// Matches the specific SDK response against the classified ordinary session.
/// The opaque predicate stays within the authentication boundary.
class AuthSessionReceipt {
  const AuthSessionReceipt(this._matches);
  final bool Function(BackendSession, BackendCredential) _matches;

  bool recognizes(BackendSession owner, BackendCredential credential) =>
      credential.emailConfirmed && _matches(owner, credential);
}

abstract interface class AuthRepository {
  Future<AuthRepositoryResult> register(String email, String password);
  Future<AuthRepositoryResult> signIn(String email, String password);
  Future<AuthRepositoryResult> verifySignupCode(String email, String code);
  Future<AuthRepositoryResult> resendSignupCode(String email);
}
