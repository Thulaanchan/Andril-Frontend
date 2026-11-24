import 'auth_user.dart';

/// Categorized failure causes for authentication actions.
enum AuthFailureType {
  invalidCredentials,
  emailAlreadyInUse,
  invalidEmailFormat,
  passwordMismatch,
  verificationCodeInvalid,
  verificationCodeExpired,
  rateLimitExceeded,
  networkError,
  googleSignInCancelled,
  serviceUnavailable, // Rule 04: Missing policy documents or 503
  unknown,
}

/// Represents an authentication error with categorized type and user-facing message.
class AuthFailure {
  const AuthFailure({
    required this.type,
    required this.message,
  });

  final AuthFailureType type;
  final String message;
}

/// Discriminated union result of an authentication operation.
sealed class AuthResult {
  const AuthResult();

  const factory AuthResult.success(AuthUser user) = AuthSuccess;
  const factory AuthResult.verificationRequired({
    required String email,
    String? message,
  }) = AuthVerificationRequired;
  const factory AuthResult.failure(AuthFailure failure) = AuthFailureResult;
}

final class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user);
  final AuthUser user;
}

final class AuthVerificationRequired extends AuthResult {
  const AuthVerificationRequired({
    required this.email,
    this.message,
  });
  final String email;
  final String? message;
}

final class AuthFailureResult extends AuthResult {
  const AuthFailureResult(this.failure);
  final AuthFailure failure;
}
