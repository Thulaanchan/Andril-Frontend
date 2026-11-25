import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_doubles/mock_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/entities/auth_config.dart';
import 'package:andril_mobile/shared_core/authentication/domain/entities/auth_user.dart';
import 'package:andril_mobile/shared_core/authentication/verification/screens/account_verification_screen.dart';
import 'package:andril_mobile/shared_core/authentication/verification/viewmodels/verification_viewmodel.dart';
import 'package:andril_mobile/shared_core/authentication/widgets/auth_otp_input.dart';

void main() {
  group('VerificationViewModel Unit Tests', () {
    late MockAuthRepository repo;
    late VerificationViewModel vm;

    setUp(() {
      repo = MockAuthRepository();
      vm = VerificationViewModel(
        repository: repo,
        email: 'john.doe@example.com',
        config: AuthConfig.testFixture,
      );
    });

    tearDown(() {
      vm.dispose();
    });

    test('Masks email address preserving user privacy', () {
      expect(vm.maskedEmail, equals('jo***@example.com'));

      final shortVm = VerificationViewModel(
        repository: repo,
        email: 'a@example.com',
        config: AuthConfig.testFixture,
      );
      expect(shortVm.maskedEmail, equals('a***@example.com'));
      shortVm.dispose();
    });

    test('Rejects incomplete verification code', () async {
      vm.updateOtp('123');
      expect(vm.canSubmit, isFalse);

      await vm.verify(onSuccess: (_) {});
      expect(vm.errorMessage, contains('6 digits'));
    });

    test('Verifies valid OTP code and triggers onSuccess', () async {
      vm.updateOtp('123456');
      expect(vm.canSubmit, isTrue);

      AuthUser? verifiedUser;
      await vm.verify(onSuccess: (u) => verifiedUser = u);

      expect(verifiedUser, isNotNull);
      expect(verifiedUser!.isEmailVerified, isTrue);
      expect(vm.errorMessage, isNull);
    });

    test('Rejects incorrect OTP code with user-facing error', () async {
      vm.updateOtp('000000');
      AuthUser? verifiedUser;
      await vm.verify(onSuccess: (u) => verifiedUser = u);

      expect(verifiedUser, isNull);
      expect(vm.errorMessage, isNotNull);
    });

    test('Resending OTP activates cooldown', () async {
      expect(vm.isResendCooldownActive, isFalse);
      await vm.resendOtp();
      expect(vm.isResendCooldownActive, isTrue);
      expect(vm.resendCooldownSeconds, greaterThan(0));
    });
  });

  group('AccountVerificationScreen Widget Tests', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
    });

    testWidgets('Renders all finalized visual elements on Screen 05',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AccountVerificationScreen(
            email: 'student@andril.app',
            authRepository: repo,
          ),
        ),
      );
      await tester.pump();

      // Heading and masked email
      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(
        find.text("We've sent a 6-digit verification code to"),
        findsOneWidget,
      );
      expect(find.text('st***@andril.app'), findsOneWidget);

      // 6-digit OTP Input
      expect(find.byType(AuthOtpInput), findsOneWidget);

      // Verify button
      expect(find.text('Verify & Continue'), findsOneWidget);

      // Resend prompt
      expect(find.text("Didn't receive code? "), findsOneWidget);

      // Security Notice banner
      expect(find.text('Security Notice'), findsOneWidget);
      expect(
        find.text(
          'Never share your verification code with anyone. ANDRIL staff will never ask for your code.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Submitting 6-digit code triggers verification callback',
        (tester) async {
      AuthUser? completedUser;
      await tester.pumpWidget(
        MaterialApp(
          home: AccountVerificationScreen(
            email: 'student@andril.app',
            authRepository: repo,
            onVerificationSuccess: (u) => completedUser = u,
          ),
        ),
      );
      await tester.pump();

      // Enter 6 digits
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));

      for (var i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '${i + 1}');
      }
      await tester.pump();

      // Tap Verify & Continue
      await tester.tap(find.text('Verify & Continue'));
      await tester.pumpAndSettle();

      expect(completedUser, isNotNull);
      expect(completedUser!.email, equals('student@andril.app'));
    });
  });
}
