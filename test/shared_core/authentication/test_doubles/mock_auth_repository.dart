import 'package:andril_mobile/shared_core/authentication/domain/entities/auth_result.dart';
import 'package:andril_mobile/shared_core/authentication/domain/entities/auth_user.dart';
import 'package:andril_mobile/shared_core/authentication/domain/repositories/onboarding_auth_repository.dart';

/// Test double implementation of [OnboardingAuthRepository] for isolated unit and widget tests.
///
/// Restricted to test and isolated preview contexts. Never used as a silent fallback
/// in the default application runtime.
class MockAuthRepository implements OnboardingAuthRepository {
  MockAuthRepository({
    this.defaultOtpCode = '123456',
    this.hasActiveRecovery = true,
  });

  final String defaultOtpCode;
  bool hasActiveRecovery;

  final Map<String, String> _userPasswords = {};
  final Map<String, AuthUser> _users = {};
  final Map<String, String> _pendingOtps = {};
  AuthUser? _currentUser;

  // Injection points for testing deterministic failure responses
  AuthResult? forcedRegisterResult;
  AuthResult? forcedVerifyResult;
  AuthResult? forcedResendResult;
  AuthResult? forcedLoginResult;
  AuthResult? forcedGoogleResult;
  AuthResult? forcedPasswordResetResult;
  AuthResult? forcedPasswordUpdateResult;

  @override
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
  }) async {
    if (forcedRegisterResult != null) return forcedRegisterResult!;

    final normalized = email.trim().toLowerCase();
    if (_userPasswords.containsKey(normalized)) {
      return const AuthResult.failure(
        AuthFailure(
          type: AuthFailureType.emailAlreadyInUse,
          message: 'An account with this email address already exists.',
        ),
      );
    }

    _userPasswords[normalized] = password;
    final user = AuthUser(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: normalized,
      isEmailVerified: false,
      createdAt: DateTime.now(),
    );
    _users[normalized] = user;
    _pendingOtps[normalized] = defaultOtpCode;

    return AuthResult.verificationRequired(
      email: normalized,
      message: 'A verification code has been sent to your email.',
    );
  }

  @override
  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    if (forcedVerifyResult != null) return forcedVerifyResult!;

    final normalized = email.trim().toLowerCase();
    final expected = _pendingOtps[normalized] ?? defaultOtpCode;

    if (token.trim() != expected) {
      return const AuthResult.failure(
        AuthFailure(
          type: AuthFailureType.verificationCodeInvalid,
          message: 'The verification code entered is invalid. Please try again.',
        ),
      );
    }

    final existingUser = _users[normalized] ??
        AuthUser(
          id: 'mock-user-verified',
          email: normalized,
          isEmailVerified: true,
        );

    final verifiedUser = AuthUser(
      id: existingUser.id,
      email: existingUser.email,
      isEmailVerified: true,
      createdAt: existingUser.createdAt,
    );

    _users[normalized] = verifiedUser;
    _currentUser = verifiedUser;
    _pendingOtps.remove(normalized);

    return AuthResult.success(verifiedUser);
  }

  @override
  Future<AuthResult> resendVerificationOtp({
    required String email,
  }) async {
    if (forcedResendResult != null) return forcedResendResult!;

    final normalized = email.trim().toLowerCase();
    _pendingOtps[normalized] = defaultOtpCode;

    return AuthResult.verificationRequired(
      email: normalized,
      message: 'A new verification code has been resent to your email.',
    );
  }

  @override
  Future<AuthResult> logInWithEmail({
    required String email,
    required String password,
  }) async {
    if (forcedLoginResult != null) return forcedLoginResult!;

    final normalized = email.trim().toLowerCase();
    final storedPassword = _userPasswords[normalized];

    // Seed dummy user for standard testing if not already present
    if (storedPassword == null &&
        (password == 'Pass1234!' || password == 'ValidPass123!')) {
      final isVerified = !normalized.contains('unverified');
      final user = AuthUser(
        id: 'mock-seeded-user',
        email: normalized,
        isEmailVerified: isVerified,
      );
      _users[normalized] = user;
      if (!isVerified) {
        return AuthResult.verificationRequired(
          email: normalized,
          message: 'Please verify your email before logging in.',
        );
      }
      _currentUser = user;
      return AuthResult.success(user);
    }

    if (storedPassword == null || storedPassword != password) {
      return const AuthResult.failure(
        AuthFailure(
          type: AuthFailureType.invalidCredentials,
          message: 'Invalid email address or password.',
        ),
      );
    }

    final user = _users[normalized];
    if (user != null && !user.isEmailVerified) {
      return AuthResult.verificationRequired(
        email: normalized,
        message: 'Please verify your email before logging in.',
      );
    }

    _currentUser = user;
    return AuthResult.success(user!);
  }

  @override
  Future<AuthResult> logInWithGoogle() async {
    if (forcedGoogleResult != null) return forcedGoogleResult!;

    final user = AuthUser(
      id: 'mock-google-user',
      email: 'google.user@andril.app',
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    return AuthResult.success(user);
  }

  @override
  Future<AuthResult> sendPasswordResetEmail({
    required String email,
  }) async {
    if (forcedPasswordResetResult != null) return forcedPasswordResetResult!;

    // Generic response that preserves privacy (does not disclose if email exists)
    final user = AuthUser(
      id: 'mock-recovery-user',
      email: email.trim().toLowerCase(),
      isEmailVerified: true,
    );
    return AuthResult.success(user);
  }

  @override
  Future<AuthResult> resetPasswordWithRecovery({
    required String newPassword,
    String? recoveryToken,
  }) async {
    if (forcedPasswordUpdateResult != null) return forcedPasswordUpdateResult!;

    if (!hasActiveRecovery) {
      return const AuthResult.failure(
        AuthFailure(
          type: AuthFailureType.invalidCredentials,
          message: 'Password recovery session has expired or is invalid.',
        ),
      );
    }

    final user = AuthUser(
      id: 'mock-recovered-user',
      email: 'recovered.user@andril.app',
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    return AuthResult.success(user);
  }

  @override
  Future<bool> hasValidRecoveryContext({String? recoveryToken}) async =>
      hasActiveRecovery;

  @override
  Future<AuthUser?> getCurrentUser() async => _currentUser;

  @override
  Future<void> logOut() async {
    _currentUser = null;
  }
}
