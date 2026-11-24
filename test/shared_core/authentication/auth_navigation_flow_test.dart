import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/shared_core/components/m2_buttons.dart';
import 'test_doubles/mock_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/entities/auth_user.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/onboarding_flow_coordinator.dart';

void main() {
  group('Onboarding & Authentication Navigation Flow Integration', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
    });

    testWidgets(
        'Flow 1: Welcome -> Create Account -> Registration -> Verification -> Complete',
        (tester) async {
      AuthUser? completedUser;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            initialStep: 2, // Start at Welcome
            authRepository: repo,
            onAuthSuccess: (u) => completedUser = u,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On Welcome Screen: Click Create Account button
      expect(find.text('Welcome to Andril'), findsOneWidget);
      final createAccountBtn =
          find.widgetWithText(M2PrimaryButton, 'Create Account');
      await tester.ensureVisible(createAccountBtn);
      await tester.tap(createAccountBtn);
      await tester.pumpAndSettle();

      // On Registration Screen: Fill out registration
      expect(
        find.text('Start your journey with one secure account.'),
        findsOneWidget,
      );

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(3)); // email, password, confirm

      await tester.enterText(textFields.at(0), 'alex@andril.app');
      await tester.enterText(textFields.at(1), 'Secret123!');
      await tester.enterText(textFields.at(2), 'Secret123!');
      await tester.pump();

      // Agree to terms checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final regSubmitBtn =
          find.widgetWithText(M2PrimaryButton, 'Create Account');
      await tester.ensureVisible(regSubmitBtn);
      await tester.tap(regSubmitBtn);
      await tester.pumpAndSettle();

      // On Account Verification Screen: Verify target email
      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.text('al***@andril.app'), findsOneWidget);

      final otpBoxes = find.byType(TextField);
      expect(otpBoxes, findsNWidgets(6));

      for (var i = 0; i < 6; i++) {
        await tester.enterText(otpBoxes.at(i), '${i + 1}');
      }
      await tester.pumpAndSettle();

      expect(completedUser, isNotNull);
      expect(completedUser!.email, equals('alex@andril.app'));
    });

    testWidgets(
        'Flow 2: Welcome -> Log In -> Login Screen -> Forgot Password -> Password Recovery -> Back to Log In',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            initialStep: 2, // Start at Welcome
            authRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Log In on Welcome
      final loginBtn = find.widgetWithText(M2SecondaryButton, 'Log In');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      // Verify on Login screen
      expect(
        find.text('Welcome back. Continue your journey.'),
        findsOneWidget,
      );

      // Tap Forgot Password?
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Verify on Password Recovery screen
      expect(
        find.text(
          "Enter your registered email address and we'll send you instructions to reset your password.",
        ),
        findsOneWidget,
      );

      // Tap Back to Log In
      final backToLoginBtn =
          find.widgetWithText(M2SecondaryButton, 'Back to Log In');
      await tester.ensureVisible(backToLoginBtn);
      await tester.tap(backToLoginBtn);
      await tester.pumpAndSettle();

      // Verify returned to Login screen
      expect(
        find.text('Welcome back. Continue your journey.'),
        findsOneWidget,
      );
    });

    testWidgets('Flow 3: Logging in with unverified email routes to Verification',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            initialStep: 5, // Start directly at Login Screen
            authRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'unverified@andril.app');
      await tester.enterText(textFields.at(1), 'ValidPass123!');
      await tester.pump();

      final loginBtn = find.widgetWithText(M2PrimaryButton, 'Log In');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      // Should automatically transition to Account Verification Screen
      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.text('un***@andril.app'), findsOneWidget);
    });
  });

  group('Responsive Layout Verification for Screens 04-07', () {
    const testViewports = [
      Size(360, 640), // Compact Phone
      Size(393, 852), // Modern Standard Phone
      Size(412, 915), // Large Aspect Phone (Pixel 7 Pro)
      Size(768, 1024), // Tablet
    ];

    for (final size in testViewports) {
      testWidgets(
          'Renders Screens 04 through 07 without overflow on ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;

        for (final step in [3, 4, 5, 6]) {
          await tester.pumpWidget(
            MaterialApp(
              home: OnboardingFlowCoordinator(
                initialStep: step,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Screen step $step threw exception on $size',
          );
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }
  });
}

