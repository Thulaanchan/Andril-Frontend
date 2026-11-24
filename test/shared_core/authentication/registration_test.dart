import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_doubles/mock_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/entities/auth_user.dart';
import 'package:andril_mobile/shared_core/authentication/registration/screens/registration_screen.dart';
import 'package:andril_mobile/shared_core/authentication/registration/viewmodels/registration_viewmodel.dart';

void main() {
  group('RegistrationViewModel Unit Tests', () {
    late MockAuthRepository repo;
    late RegistrationViewModel vm;

    setUp(() {
      repo = MockAuthRepository();
      vm = RegistrationViewModel(repository: repo);
    });

    tearDown(() {
      vm.dispose();
    });

    test('Initial state is empty, not loading and cannot submit', () {
      expect(vm.email, isEmpty);
      expect(vm.password, isEmpty);
      expect(vm.confirmPassword, isEmpty);
      expect(vm.isLoading, isFalse);
      expect(vm.isGoogleLoading, isFalse);
      expect(vm.canSubmit, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('Validates empty and invalid email formats', () async {
      vm.setPassword('Secret123!');
      vm.setConfirmPassword('Secret123!');

      // Empty email
      await vm.register();
      expect(vm.emailError, contains('required'));

      // Invalid format
      vm.setEmail('not-an-email');
      await vm.register();
      expect(vm.emailError, contains('valid email'));
    });

    test('Validates password mismatch', () async {
      vm.setEmail('test@andril.app');
      vm.setPassword('Password123');
      vm.setConfirmPassword('DifferentPassword');

      await vm.register();
      expect(vm.confirmPasswordError, contains('Passwords do not match'));
    });

    test('Validates terms of service agreement', () async {
      vm.setEmail('test@andril.app');
      vm.setPassword('ValidPass123!');
      vm.setConfirmPassword('ValidPass123!');
      vm.setTermsAgreed(false);

      await vm.register();
      expect(vm.errorMessage, contains('Terms of Service'));
      expect(vm.canSubmit, isFalse);

      vm.setTermsAgreed(true);
      expect(vm.canSubmit, isTrue);
    });

    test('Successful registration triggers onVerificationRequired', () async {
      vm.setEmail('newuser@andril.app');
      vm.setPassword('ValidPass123!');
      vm.setConfirmPassword('ValidPass123!');
      vm.setTermsAgreed(true);

      String? targetEmail;
      await vm.register(
        onVerificationRequired: (email) => targetEmail = email,
      );

      expect(targetEmail, equals('newuser@andril.app'));
      expect(vm.errorMessage, isNull);
    });

    test('Google sign-in succeeds and returns authenticated user', () async {
      AuthUser? user;
      await vm.continueWithGoogle(
        onSuccess: (u) => user = u,
      );

      expect(user, isNotNull);
      expect(user!.email, equals('google.user@andril.app'));
    });
  });

  group('RegistrationScreen Widget Tests', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
    });

    testWidgets('Renders all finalized visual elements on Screen 04',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(authRepository: repo),
        ),
      );
      await tester.pump();

      // Heading and subtitle
      expect(find.text('Create Account'), findsNWidgets(2)); // Heading & button
      expect(
        find.text('Start your journey with one secure account.'),
        findsOneWidget,
      );

      // Input labels
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Divider & Google Sign-In
      expect(find.text('OR'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // Footer switch link
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('Toggles password visibility on eye icon tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(authRepository: repo),
        ),
      );
      await tester.pump();

      final visibilityToggles = find.byTooltip('Show password');
      expect(visibilityToggles, findsNWidgets(2)); // Password & confirm password

      // Tap first visibility toggle
      await tester.tap(visibilityToggles.first);
      await tester.pump();

      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('Navigates to login on footer link tap', (tester) async {
      var navigatedToLogin = false;
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(
            authRepository: repo,
            onNavigateToLogin: () => navigatedToLogin = true,
          ),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pump();

      expect(navigatedToLogin, isTrue);
    });
  });
}
