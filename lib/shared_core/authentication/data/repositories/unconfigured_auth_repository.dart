import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Default runtime implementation of [AuthRepository] when live Supabase configuration is absent.
///
/// Ensures production security:
/// - The default ANDRIL application CANNOT authenticate a user using mock credentials.
/// - Unconfigured operations consistently return [AuthFailureType.serviceUnavailable].
/// - Production authentication never silently falls back to mock behavior.
class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  static const _serviceUnavailableFailure = AuthResult.failure(
    AuthFailure(
      type: AuthFailureType.serviceUnavailable,
      message:
          'Authentication service is unconfigured. Live Supabase provider configuration is required.',
    ),
  );

  @override
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
  }) async =>
      _serviceUnavailableFailure;

  @override
  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String token,
  }) async =>
      _serviceUnavailableFailure;

  @override
  Future<AuthResult> resendVerificationOtp({
    required String email,
  }) async =>
      _serviceUnavailableFailure;

  @override
  Future<AuthResult> logInWithEmail({
    required String email,
    required String password,
  }) async =>
      _serviceUnavailableFailure;

  @override
  Future<AuthResult> logInWithGoogle() async => _serviceUnavailableFailure;

  @override
  Future<AuthResult> sendPasswordResetEmail({
    required String email,
  }) async =>
      _serviceUnavailableFailure;

  @override
  Future<AuthResult> resetPasswordWithRecovery({
    required String newPassword,
    String? recoveryToken,
  }) async =>
      _serviceUnavailableFailure;

  @override
  Future<bool> hasValidRecoveryContext({String? recoveryToken}) async => false;

  @override
  Future<AuthUser?> getCurrentUser() async => null;

  @override
  Future<void> logOut() async {}
}
