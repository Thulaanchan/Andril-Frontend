import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_doubles/mock_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/password_recovery/screens/password_recovery_screen.dart';
import 'package:andril_mobile/shared_core/authentication/password_recovery/viewmodels/password_recovery_viewmodel.dart';

void main() {
  group('PasswordRecoveryViewModel Unit Tests', () {
    late MockAuthRepository repo;
    late PasswordRecoveryViewModel vm;

    setUp(() {
      repo = MockAuthRepository();
      vm = PasswordRecoveryViewModel(repository: repo);
    });

    tearDown(() {
      vm.dispose();
    });

    test('Initial state is not submitted and cannot submit without input', () {
      expect(vm.email, isEmpty);
      expect(vm.isSubmitted, isFalse);
      expect(vm.isLoading, isFalse);
      expect(vm.canSubmit, isFalse);
    });

    test('Validates empty and invalid email format', () async {
      await vm.sendResetLink();
      expect(vm.emailError, contains('enter your email'));

      vm.setEmail('not-valid');
      await vm.sendResetLink();
      expect(vm.emailError, contains('valid email'));
    });

    test('Submitting valid email sends reset link and preserves privacy',
        () async {
      vm.setEmail('user@andril.app');
      expect(vm.canSubmit, isTrue);

      var successCalled = false;
      await vm.sendResetLink(onSuccess: () => successCalled = true);

      expect(successCalled, isTrue);
      expect(vm.isSubmitted, isTrue);
      expect(vm.errorMessage, isNull);
    });
  });

  group('PasswordRecoveryScreen Widget Tests', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
    });

    testWidgets('Renders all finalized visual elements on Screen 07',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PasswordRecoveryScreen(authRepository: repo),
        ),
      );
      await tester.pump();

      // Heading and instructions
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(
        find.text(
          "Enter your registered email address and we'll send you instructions to reset your password.",
        ),
        findsOneWidget,
      );

      // Email field
      expect(find.text('Email Address'), findsOneWidget);

      // Privacy banner
      expect(
        find.text(
          "If the address is registered, we'll send recovery instructions. Check your spam folder if you don't see it.",
        ),
        findsOneWidget,
      );

      // Action buttons
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Back to Log In'), findsOneWidget);
    });

    testWidgets('Submitting valid email displays confirmation message',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PasswordRecoveryScreen(authRepository: repo),
        ),
      );
      await tester.pump();

      final emailField = find.byType(TextField);
      await tester.enterText(emailField, 'recovery@andril.app');
      await tester.pump();

      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'If an account exists for this email, recovery instructions have been sent.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Back to Log In triggers navigation callback',
        (tester) async {
      var backToLoginTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PasswordRecoveryScreen(
            authRepository: repo,
            onBackToLogin: () => backToLoginTapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Back to Log In'));
      await tester.tap(find.text('Back to Log In'));
      await tester.pump();

      expect(backToLoginTapped, isTrue);
    });
  });
}
