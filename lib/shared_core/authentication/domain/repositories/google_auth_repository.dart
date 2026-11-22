import 'auth_repository.dart';

enum GoogleAuthState {
  idle,
  loading,
  cancelled,
  unavailable,
  configurationPending,
  credentialMissing,
  providerTokenMissing,
  googleRejected,
  exchangeRejected,
  sessionMissing,
  confirmationRequired,
  pendingAdmission,
  admitted,
  superseded,
  blocked,
  busy,
}

/// No provider objects or credentials are exposed in the view state. The
/// existing opaque receipt can recognize an exact ordinary SDK session.
class GoogleAuthResult {
  const GoogleAuthResult(this.state) : receipt = null;
  const GoogleAuthResult.candidate(AuthSessionReceipt this.receipt)
      : state = GoogleAuthState.pendingAdmission;

  final GoogleAuthState state;
  final AuthSessionReceipt? receipt;
}

abstract interface class GoogleAuthRepository {
  Future<GoogleAuthResult> signIn({required bool Function() mayExchange});
}
