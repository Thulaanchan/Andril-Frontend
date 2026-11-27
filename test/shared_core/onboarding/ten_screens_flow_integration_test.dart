import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/shared_core/components/m2_buttons.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/onboarding_flow_coordinator.dart';
import '../authentication/test_doubles/mock_auth_repository.dart';
import '../module_activation/test_doubles/mock_starter_module_repository.dart';
import '../privacy/test_doubles/mock_eligibility_repository.dart';

void main() {
  group('Ten-Screen Onboarding Navigation Integration', () {
    late MockAuthRepository authRepo;
    late MockEligibilityRepository eligRepo;
    late MockStarterModuleRepository moduleRepo;

    setUp(() {
      authRepo = MockAuthRepository(hasActiveRecovery: true);
      eligRepo = MockEligibilityRepository();
      moduleRepo = MockStarterModuleRepository(isSocialAuthorized: true);
    });

    testWidgets(
        'Complete Journey: Welcome -> Register -> Verify -> Eligibility -> Starter Selection -> Complete',
        (tester) async {
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      String? completedNextStep;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            initialStep: 2, // Welcome
            authRepository: authRepo,
            eligibilityRepository: eligRepo,
            starterModuleRepository: moduleRepo,
            onOnboardingCompleted: (step) => completedNextStep = step,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 2: Welcome Screen -> Create Account
      final welcomeCreateBtn =
          find.widgetWithText(M2PrimaryButton, 'Create Account');
      await tester.ensureVisible(welcomeCreateBtn);
      await tester.tap(welcomeCreateBtn);
      await tester.pumpAndSettle();

      // Step 3: Registration Screen
      expect(
        find.text('Start your journey with one secure account.'),
        findsOneWidget,
      );

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'student@andril.app');
      await tester.enterText(textFields.at(1), 'ValidPass123!');
      await tester.enterText(textFields.at(2), 'ValidPass123!');
      await tester.pump();

      // Agree to registration terms
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final regSubmitBtn =
          find.widgetWithText(M2PrimaryButton, 'Create Account');
      await tester.ensureVisible(regSubmitBtn);
      await tester.tap(regSubmitBtn);
      await tester.pumpAndSettle();

      // Step 4: Verification Screen
      expect(find.text('Verify Your Email'), findsOneWidget);
      final otpBoxes = find.byType(TextField);
      for (var i = 0; i < 6; i++) {
        await tester.enterText(otpBoxes.at(i), '${i + 1}');
      }
      // Entering all 6 digits automatically completes verification and advances to Eligibility
      await tester.pumpAndSettle();

      // Step 8: Eligibility & Policies Screen
      expect(find.text('Before You Continue'), findsOneWidget);

      // Select Date of Birth via native date picker
      await tester.ensureVisible(find.text('Select your date of birth'));
      await tester.tap(find.text('Select your date of birth'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select Gender via dropdown
      await tester.ensureVisible(find.text('Select your gender'));
      await tester.tap(find.text('Select your gender'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Female').last);
      await tester.pumpAndSettle();

      // Agree to terms & privacy checkboxes
      final eligCheckboxes = find.byType(Checkbox);
      for (var i = 0; i < eligCheckboxes.evaluate().length; i++) {
        await tester.ensureVisible(eligCheckboxes.at(i));
        await tester.tap(eligCheckboxes.at(i));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final continueEligBtn =
          find.widgetWithText(M2PrimaryButton, 'Continue');
      await tester.ensureVisible(continueEligBtn);
      await tester.pumpAndSettle();
      await tester.tap(continueEligBtn);
      await tester.pumpAndSettle();

      // Step 9: Starter Module Selection Screen
      expect(find.text('Choose Your Path'), findsOneWidget);

      final continueModuleBtn =
          find.widgetWithText(M2PrimaryButton, 'Continue');
      await tester.ensureVisible(continueModuleBtn);
      await tester.tap(continueModuleBtn);
      await tester.pumpAndSettle();

      // Confirmed next onboarding step is 'profile_setup' (Rule 05)
      expect(completedNextStep, equals('profile_setup'));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Password Recovery Journey: Request -> Reset -> Success to Login',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            initialStep: 6, // Password Recovery Request
            authRepository: authRepo,
            recoveryToken: 'active-test-recovery-token',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final emailField = find.byType(TextField);
      await tester.enterText(emailField, 'recovery@andril.app');
      await tester.pump();

      final sendLinkBtn =
          find.widgetWithText(M2PrimaryButton, 'Send Reset Link');
      await tester.ensureVisible(sendLinkBtn);
      await tester.tap(sendLinkBtn);
      await tester.pumpAndSettle();

      // Navigates to Screen 08 (Password Reset) with recovery context
      expect(find.text('Create New Password'), findsOneWidget);

      final passFields = find.byType(TextField);
      await tester.enterText(passFields.at(0), 'BrandNewPass123!');
      await tester.enterText(passFields.at(1), 'BrandNewPass123!');
      await tester.pump();

      final updateBtn =
          find.widgetWithText(M2PrimaryButton, 'Update Password');
      await tester.ensureVisible(updateBtn);
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      // Displays update success banner
      expect(
        find.text('Your password has been updated successfully.'),
        findsOneWidget,
      );

      // Return to Log In
      final returnBtn =
          find.widgetWithText(M2PrimaryButton, 'Return to Log In');
      await tester.ensureVisible(returnBtn);
      await tester.tap(returnBtn);
      await tester.pumpAndSettle();

      // Back on Login Screen
      expect(
        find.text('Welcome back. Continue your journey.'),
        findsOneWidget,
      );
    });
  });

  group('Responsive Layout & Localization Verification for All 10 Screens', () {
    const testViewports = [
      Size(320, 568), // Ultra-compact (iPhone SE 1st gen)
      Size(360, 640), // Standard Android compact
      Size(390, 844), // Standard modern phone (iPhone 12/13/14)
      Size(412, 915), // Large Android flagship (Pixel 7 Pro)
      Size(768, 1024), // Tablet
    ];

    const testLocales = ['en', 'ta', 'si'];

    for (final size in testViewports) {
      testWidgets(
          'Renders all ten screens without overflow on ${size.width}x${size.height} across EN, TA, SI',
          (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;

        for (final lang in testLocales) {
          for (var step = 0; step <= 9; step++) {
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(lang),
                home: OnboardingFlowCoordinator(
                  initialStep: step,
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason: 'Screen step $step threw exception on $size in $lang',
            );
          }
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }
  });
}
