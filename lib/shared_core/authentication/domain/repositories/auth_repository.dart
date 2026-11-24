import '../entities/auth_result.dart';
import '../entities/auth_user.dart';

/// Domain contract for authentication operations in ANDRIL Member-02.
///
/// Designed to decouple presentation from specific authentication providers
/// (such as Supabase Auth or test doubles).
abstract interface class AuthRepository {
  /// Registers a new user account with email and password (Screen 04).
  ///
  /// Navigates to email verification when the authentication provider returns
  /// [AuthResult.verificationRequired].
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
  });

  /// Verifies an email OTP code (Screen 05).
  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String token,
  });

  /// Resends an email OTP verification code (Screen 05).
  Future<AuthResult> resendVerificationOtp({
    required String email,
  });

  /// Logs in an existing user with email and password (Screen 06).
  Future<AuthResult> logInWithEmail({
    required String email,
    required String password,
  });

  /// Initiates Google Sign-In.
  Future<AuthResult> logInWithGoogle();

  /// Requests a password reset link for the provided email (Screen 07).
  ///
  /// Always returns a generic response that does not disclose whether
  /// an email exists in the system.
  Future<AuthResult> sendPasswordResetEmail({
    required String email,
  });

  /// Resets and updates the password using an active recovery session or token (Screen 08).
  ///
  /// Requires a valid recovery authorization context. Returns [AuthFailureType.serviceUnavailable]
  /// or [AuthFailureType.invalidCredentials] if recovery context is missing or expired.
  Future<AuthResult> resetPasswordWithRecovery({
    required String newPassword,
    String? recoveryToken,
  });

  /// Validates whether a valid password recovery authorization context is currently active.
  Future<bool> hasValidRecoveryContext({String? recoveryToken});

  /// Retrieves the currently authenticated session user, or null if unauthenticated.
  Future<AuthUser?> getCurrentUser();

  /// Logs out the current session.
  Future<void> logOut();
}
