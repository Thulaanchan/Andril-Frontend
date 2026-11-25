import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/authentication/data/repositories/unconfigured_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/entities/auth_config.dart';
import 'package:andril_mobile/shared_core/authentication/domain/entities/auth_result.dart';
import 'test_doubles/mock_auth_repository.dart';

void main() {
  group('Authentication Security & Configuration Policy Enforcement', () {
    test('UnconfiguredAuthRepository refuses mock credentials with serviceUnavailable',
        () async {
      const repo = UnconfiguredAuthRepository();

      // Register
      final regResult = await repo.registerWithEmail(
        email: 'test@andril.app',
        password: 'Password123!',
      );
      expect(regResult, isA<AuthFailureResult>());
      final regFailure = (regResult as AuthFailureResult).failure;
      expect(regFailure.type, equals(AuthFailureType.serviceUnavailable));
      expect(regFailure.message, contains('Live Supabase'));

      // Login
      final loginResult = await repo.logInWithEmail(
        email: 'test@andril.app',
        password: 'Password123!',
      );
      expect(loginResult, isA<AuthFailureResult>());
      expect(
        (loginResult as AuthFailureResult).failure.type,
        equals(AuthFailureType.serviceUnavailable),
      );

      // Google Sign-In
      final googleResult = await repo.logInWithGoogle();
      expect(googleResult, isA<AuthFailureResult>());
      expect(
        (googleResult as AuthFailureResult).failure.type,
        equals(AuthFailureType.serviceUnavailable),
      );

      // Password Reset Request
      final resetResult = await repo.sendPasswordResetEmail(
        email: 'test@andril.app',
      );
      expect(resetResult, isA<AuthFailureResult>());
      expect(
        (resetResult as AuthFailureResult).failure.type,
        equals(AuthFailureType.serviceUnavailable),
      );

      // Password Update
      final updateResult = await repo.resetPasswordWithRecovery(
        newPassword: 'NewPassword123!',
      );
      expect(updateResult, isA<AuthFailureResult>());
      expect(
        (updateResult as AuthFailureResult).failure.type,
        equals(AuthFailureType.serviceUnavailable),
      );

      // Recovery context check
      expect(await repo.hasValidRecoveryContext(), isFalse);
      expect(await repo.getCurrentUser(), isNull);
    });

    test('AuthConfig does not hardcode unapproved production defaults', () {
      const config = AuthConfig();

      // Production defaults must remain unconfirmed and null
      expect(config.resendCooldownSeconds, isNull);
      expect(config.otpLength, isNull);
      expect(config.otpExpirationMinutes, isNull);
      expect(config.minPasswordLength, isNull);
      expect(config.requireSpecialCharacter, isNull);

      // Explicit test fixtures can be injected for automated test suites
      expect(AuthConfig.testFixture.resendCooldownSeconds, equals(30));
      expect(AuthConfig.testFixture.otpLength, equals(6));
    });

    test('MockAuthRepository rejects password update without active recovery context',
        () async {
      final mock = MockAuthRepository(hasActiveRecovery: false);
      expect(await mock.hasValidRecoveryContext(), isFalse);

      final result = await mock.resetPasswordWithRecovery(
        newPassword: 'SecureNewPassword123!',
      );

      expect(result, isA<AuthFailureResult>());
      expect(
        (result as AuthFailureResult).failure.type,
        equals(AuthFailureType.invalidCredentials),
      );
    });
  });
}
