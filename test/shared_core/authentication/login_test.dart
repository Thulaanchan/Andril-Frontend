import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_doubles/mock_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/entities/auth_user.dart';
import 'package:andril_mobile/shared_core/authentication/login/screens/login_screen.dart';
import 'package:andril_mobile/shared_core/authentication/login/viewmodels/login_viewmodel.dart';

void main() {
  group('LoginViewModel Unit Tests', () {
    late MockAuthRepository repo;
    late LoginViewModel vm;

    setUp(() {
      repo = MockAuthRepository();
      vm = LoginViewModel(repository: repo);
    });

    tearDown(() {
      vm.dispose();
    });

    test('Initial state is unauthenticated and cannot submit without input', () {
      expect(vm.email, isEmpty);
      expect(vm.password, isEmpty);
      expect(vm.canSubmit, isFalse);
      expect(vm.isLoading, isFalse);
    });

    test('Validates empty and malformed email inputs', () async {
      await vm.logIn(
        onSuccess: (_) {},
        onVerificationRequired: (_) {},
      );
      expect(vm.emailError, contains('enter your email'));

      vm.setEmail('invalid-email');
      await vm.logIn(
        onSuccess: (_) {},
        onVerificationRequired: (_) {},
      );
      expect(vm.emailError, contains('valid email'));
    });

    test('Successful login returns authenticated user', () async {
      vm.setEmail('verified@andril.app');
      vm.setPassword('Pass1234!');

      AuthUser? loggedInUser;
      await vm.logIn(
        onSuccess: (u) => loggedInUser = u,
        onVerificationRequired: (_) {},
      );

      expect(loggedInUser, isNotNull);
      expect(loggedInUser!.email, equals('verified@andril.app'));
      expect(vm.errorMessage, isNull);
    });

    test('Unverified email triggers onVerificationRequired callback', () async {
      vm.setEmail('unverified@andril.app');
      vm.setPassword('Pass1234!');

      String? verificationTarget;
      await vm.logIn(
        onSuccess: (_) {},
        onVerificationRequired: (email) => verificationTarget = email,
      );

      expect(verificationTarget, equals('unverified@andril.app'));
    });

    test('Google sign-in succeeds and returns user', () async {
      AuthUser? googleUser;
      await vm.continueWithGoogle(
        onSuccess: (u) => googleUser = u,
      );

      expect(googleUser, isNotNull);
      expect(googleUser!.email, equals('google.user@andril.app'));
    });
  });

  group('LoginScreen Widget Tests', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
    });

    testWidgets('Renders all finalized visual elements on Screen 06',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authRepository: repo),
        ),
      );
      await tester.pump();

      // Heading and subtitle
      expect(find.text('Log In'), findsNWidgets(2)); // Title & button
      expect(find.text('Welcome back. Continue your journey.'), findsOneWidget);

      // Input labels
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // "Forgot Password?" right aligned
      expect(find.text('Forgot Password?'), findsOneWidget);

      // "OR" Divider and Google Sign-In
      expect(find.text('OR'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // Module isolation banner
      expect(
        find.text('One account. Three private module profiles.'),
        findsOneWidget,
      );

      // Footer switch link
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('Taps Forgot Password and triggers callback', (tester) async {
      var forgotPasswordTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            authRepository: repo,
            onNavigateToForgotPassword: () => forgotPasswordTapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Forgot Password?'));
      await tester.pump();

      expect(forgotPasswordTapped, isTrue);
    });

    testWidgets('Taps Create Account link and triggers navigation',
        (tester) async {
      var createAccountTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            authRepository: repo,
            onNavigateToRegister: () => createAccountTapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(createAccountTapped, isTrue);
    });
  });
}
