import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/shared_core/components/m2_buttons.dart';
import 'package:andril_mobile/shared_core/authentication/password_recovery/screens/password_reset_screen.dart';
import 'package:andril_mobile/shared_core/authentication/password_recovery/viewmodels/password_reset_viewmodel.dart';
import 'test_doubles/mock_auth_repository.dart';

void main() {
  group('PasswordResetViewModel Unit Tests', () {
    late MockAuthRepository repo;
    late PasswordResetViewModel vm;

    setUp(() {
      repo = MockAuthRepository(hasActiveRecovery: true);
      vm = PasswordResetViewModel(
        repository: repo,
        recoveryToken: 'valid-test-token',
      );
    });

    tearDown(() {
      vm.dispose();
    });

    test('Initial state is empty and cannot submit', () {
      expect(vm.newPassword, isEmpty);
      expect(vm.confirmPassword, isEmpty);
      expect(vm.canSubmit, isFalse);
      expect(vm.isLoading, isFalse);
      expect(vm.isSuccess, isFalse);
    });

    test('Validates empty password and confirmation mismatch', () async {
      await vm.submitPasswordReset();
      expect(vm.newPasswordError, contains('enter a new password'));

      vm.setNewPassword('SecurePass123!');
      vm.setConfirmPassword('MismatchPass456!');
      await vm.submitPasswordReset();
      expect(vm.confirmPasswordError, contains('Passwords do not match'));
    });

    test('Rejects reset when recovery authorization context is missing or expired',
        () async {
      repo.hasActiveRecovery = false;
      vm.setNewPassword('SecurePass123!');
      vm.setConfirmPassword('SecurePass123!');

      await vm.submitPasswordReset();
      expect(vm.errorMessage, contains('expired or is invalid'));
      expect(vm.isSuccess, isFalse);
    });

    test('Successfully updates password with valid recovery context', () async {
      vm.setNewPassword('SecurePass123!');
      vm.setConfirmPassword('SecurePass123!');

      var successCallbackTriggered = false;
      await vm.submitPasswordReset(
        onSuccess: () => successCallbackTriggered = true,
      );

      expect(successCallbackTriggered, isTrue);
      expect(vm.isSuccess, isTrue);
      expect(vm.errorMessage, isNull);
    });

    test('Toggles password visibility independently', () {
      expect(vm.isPasswordVisible, isFalse);
      expect(vm.isConfirmPasswordVisible, isFalse);

      vm.togglePasswordVisibility();
      expect(vm.isPasswordVisible, isTrue);
      expect(vm.isConfirmPasswordVisible, isFalse);

      vm.toggleConfirmPasswordVisibility();
      expect(vm.isConfirmPasswordVisible, isTrue);
    });
  });

  group('PasswordResetScreen Widget Tests', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository(hasActiveRecovery: true);
    });

    testWidgets('Renders all finalized visual elements on Screen 08',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PasswordResetScreen(
            authRepository: repo,
            recoveryToken: 'valid-token',
          ),
        ),
      );
      await tester.pump();

      // Heading and subtitle
      expect(find.text('Create New Password'), findsOneWidget);
      expect(
        find.text('Choose a new password for your account.'),
        findsOneWidget,
      );

      // Input labels
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Confirm new password'), findsOneWidget);

      // Policy guidance callout
      expect(
        find.text(
          'Use a strong and unique password. Follow the approved password policy.',
        ),
        findsOneWidget,
      );

      // Primary Button
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('Submitting valid passwords displays success banner',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PasswordResetScreen(
            authRepository: repo,
            recoveryToken: 'valid-token',
          ),
        ),
      );
      await tester.pump();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'BrandNewPass123!');
      await tester.enterText(textFields.at(1), 'BrandNewPass123!');
      await tester.pump();

      final updateBtn =
          find.widgetWithText(M2PrimaryButton, 'Update Password');
      await tester.ensureVisible(updateBtn);
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Your password has been updated successfully.'),
        findsOneWidget,
      );
      expect(find.text('Return to Log In'), findsOneWidget);
    });
  });
}
