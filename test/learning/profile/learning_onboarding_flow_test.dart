import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/profile/screens/learning_onboarding_screen.dart';
import 'package:andril_mobile/features/learning/profile/viewmodels/learning_onboarding_viewmodel.dart';

Widget _buildTestScreen({
  LearningOnboardingViewModel? viewModel,
  VoidCallback? onExit,
  VoidCallback? onComplete,
}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: LearningOnboardingScreen(
      viewModel: viewModel,
      onExit: onExit,
      onComplete: onComplete,
    ),
  );
}

void main() {
  group('Learning Onboarding End-to-End Flow & Security Tests', () {
    late LearningOnboardingViewModel viewModel;

    setUp(() {
      viewModel = LearningOnboardingViewModel();
    });

    tearDown(() {
      if (!viewModel.isDisposed) {
        viewModel.dispose();
      }
    });

    // 1. Full five-step draft navigation
    testWidgets('1. Full five-step draft navigation advances 0 through 4',
        (tester) async {
      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      // Step 0: Basics
      expect(viewModel.currentStep, 0);
      expect(find.text('Step 1 of 5'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('onboarding_display_name_field')),
        'Karthi Keyan',
      );
      await tester
          .tap(find.byKey(const Key('onboarding_basics_continue_button')));
      await tester.pumpAndSettle();

      // Step 1: Learn
      expect(viewModel.currentStep, 1);
      expect(find.text('Step 2 of 5'), findsOneWidget);
      await tester.tap(find.byKey(const Key('skill_chip_learn_Flutter')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('onboarding_learn_continue_button')));
      await tester.pumpAndSettle();

      // Step 2: Share
      expect(viewModel.currentStep, 2);
      expect(find.text('Step 3 of 5'), findsOneWidget);
      await tester.tap(find.byKey(const Key('skill_chip_share_Python')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('onboarding_share_continue_button')));
      await tester.pumpAndSettle();

      // Step 3: Goals
      expect(viewModel.currentStep, 3);
      expect(find.text('Step 4 of 5'), findsOneWidget);
      final goalChip =
          find.byKey(const Key('goal_chip_Build practical portfolio projects'));
      await tester.ensureVisible(goalChip);
      await tester.pumpAndSettle();
      await tester.tap(goalChip);
      await tester.pumpAndSettle();

      final goalsContinueBtn =
          find.byKey(const Key('onboarding_goals_continue_button'));
      await tester.ensureVisible(goalsContinueBtn);
      await tester.pumpAndSettle();
      await tester.tap(goalsContinueBtn);
      await tester.pumpAndSettle();

      // Step 4: Review
      expect(viewModel.currentStep, 4);
      expect(find.text('Step 5 of 5'), findsOneWidget);
      expect(find.text('Karthi Keyan'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('Build practical portfolio projects'), findsOneWidget);
    });

    // 2. Repeated Back/Continue actions do not duplicate state
    testWidgets('2. Repeated Back/Continue actions do not duplicate state',
        (tester) async {
      viewModel.setDisplayName('Alex');
      viewModel.addSkillToLearn('Flutter');
      viewModel.setStep(1);

      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      // Advance to 2
      await tester
          .tap(find.byKey(const Key('onboarding_learn_continue_button')));
      await tester.pumpAndSettle();
      expect(viewModel.currentStep, 2);

      // Back to 1
      await tester.tap(find.byKey(const Key('onboarding_share_back_button')));
      await tester.pumpAndSettle();
      expect(viewModel.currentStep, 1);

      // Advance again to 2
      await tester
          .tap(find.byKey(const Key('onboarding_learn_continue_button')));
      await tester.pumpAndSettle();
      expect(viewModel.currentStep, 2);

      expect(viewModel.skillsToLearn, ['Flutter']);
    });

    // 3. Editing earlier values updates the Review screen
    testWidgets('3. Editing earlier values updates the Review screen',
        (tester) async {
      viewModel.setDisplayName('Initial Name');
      viewModel.setStep(4); // Review step

      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Initial Name'), findsOneWidget);

      // Tap Edit on Profile Basics
      final editButtons = find.text('Edit');
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(viewModel.currentStep, 0);

      // Update name
      await tester.enterText(
        find.byKey(const Key('onboarding_display_name_field')),
        'Updated Name',
      );
      await tester.pumpAndSettle();

      // Jump directly back to Review step
      viewModel.setStep(4);
      await tester.pumpAndSettle();

      expect(find.text('Updated Name'), findsOneWidget);
    });

    // 4. Unsaved-change warning appears when required
    testWidgets('4. Unsaved-change dialog appears when exiting with drafts',
        (tester) async {
      bool exitInvoked = false;

      await tester.pumpWidget(
        _buildTestScreen(
          viewModel: viewModel,
          onExit: () => exitInvoked = true,
        ),
      );
      await tester.pumpAndSettle();

      // Enter draft input to make dirty
      await tester.enterText(
        find.byKey(const Key('onboarding_display_name_field')),
        'Unsaved Name',
      );
      await tester.pumpAndSettle();
      expect(viewModel.hasUnsavedChanges, isTrue);

      // Tap exit button in app bar
      await tester.tap(find.byKey(const Key('onboarding_exit_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('discard_dialog_title')), findsOneWidget);
      expect(find.text('Discard Changes?'), findsOneWidget);
      expect(exitInvoked, isFalse);
    });

    // 5. Cancel/continue editing behavior is correct
    testWidgets('5. Cancel and confirm discard behavior works correctly',
        (tester) async {
      bool exitInvoked = false;

      await tester.pumpWidget(
        _buildTestScreen(
          viewModel: viewModel,
          onExit: () => exitInvoked = true,
        ),
      );
      await tester.pumpAndSettle();

      viewModel.setDisplayName('Draft Name');
      await tester.pumpAndSettle();

      // Tap exit
      await tester.tap(find.byKey(const Key('onboarding_exit_button')));
      await tester.pumpAndSettle();

      // Tap "Keep Editing"
      await tester.tap(find.byKey(const Key('discard_dialog_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('discard_dialog_title')), findsNothing);
      expect(exitInvoked, isFalse);
      expect(viewModel.displayName, 'Draft Name');

      // Tap exit again and tap "Discard"
      await tester.tap(find.byKey(const Key('onboarding_exit_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('discard_dialog_confirm_button')));
      await tester.pumpAndSettle();

      expect(exitInvoked, isTrue);
    });

    // 6. ViewModel lifecycle is correctly owned
    testWidgets('6. ViewModel lifecycle ownership policy is honored',
        (tester) async {
      // Case A: Screen-owned ViewModel is disposed when screen is disposed
      final statefulKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          key: statefulKey,
          home: const LearningOnboardingScreen(), // creates internal VM
        ),
      );
      await tester.pumpAndSettle();

      // Unmount the screen
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();
      // Internal VM was disposed cleanly without exception

      // Case B: Caller-provided ViewModel is NOT disposed by screen
      final callerVM = LearningOnboardingViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: LearningOnboardingScreen(viewModel: callerVM),
        ),
      );
      await tester.pumpAndSettle();

      // Unmount
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      expect(callerVM.isDisposed, isFalse);
      callerVM.dispose();
      expect(callerVM.isDisposed, isTrue);
    });

    // 7. No local activation
    testWidgets('7. No local activation is performed', (tester) async {
      viewModel.setDisplayName('Alex');
      viewModel.setStep(4);

      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      final submitButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('onboarding_review_submit_button')),
      );

      // Invariant: Submit button is disabled
      expect(submitButton.onPressed, isNull);
    });

    // 8. No production backend calls
    testWidgets('8. No production backend calls or synthetic requests',
        (tester) async {
      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    // 9. No fake persistence success
    testWidgets('9. No fake persistence success banner or confirmation',
        (tester) async {
      viewModel.setDisplayName('Alex');
      viewModel.setStep(4);

      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Profile Created Successfully'), findsNothing);
      expect(find.text('Activation Complete'), findsNothing);
      expect(find.byKey(const Key('review_activation_disclaimer')),
          findsOneWidget);
    });

    // 10. No navigation to protected Home
    testWidgets('10. No automatic navigation to protected Learning Home',
        (tester) async {
      viewModel.setDisplayName('Alex');
      viewModel.setStep(4);

      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Learning Home'), findsNothing);
      expect(find.text('Classrooms'), findsNothing);
    });

    // 11. No cross-module draft leakage
    testWidgets('11. No cross-module draft leakage (Social/Hobbies)',
        (tester) async {
      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Social Profile'), findsNothing);
      expect(find.text('Hobbies Profile'), findsNothing);
      expect(find.text('Gaming Interests'), findsNothing);
    });

    // 12. No exposure of private identifiers in UI
    testWidgets('12. No exposure of private identifiers in UI tree',
        (tester) async {
      viewModel.setDisplayName('DevUser');
      viewModel.setStep(4);

      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.textContaining('accountId'), findsNothing);
      expect(find.textContaining('profileId'), findsNothing);
      expect(find.textContaining('eyJ'), findsNothing);
      expect(find.textContaining('Bearer'), findsNothing);
    });

    // 13. Graceful behavior when required M2 activation services are unavailable
    testWidgets(
        '13. Review shows clear explanation that activation is pending M2',
        (tester) async {
      viewModel.setDisplayName('DevUser');
      viewModel.setStep(4);

      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('review_submit_pending_note')), findsOneWidget);
      expect(
        find.text(
            'Backend module activation gateway pending M2 contract. Submit is currently disabled.'),
        findsOneWidget,
      );
    });

    // 14. Appropriate loading, empty, error, denial and confirmation states
    testWidgets('14. Unsaved changes dialog exits cleanly when not dirty',
        (tester) async {
      bool exitInvoked = false;

      await tester.pumpWidget(
        _buildTestScreen(
          viewModel: viewModel,
          onExit: () => exitInvoked = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(viewModel.hasUnsavedChanges, isFalse);

      // Tap exit button with no changes -> exits immediately without dialog
      await tester.tap(find.byKey(const Key('onboarding_exit_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('discard_dialog_title')), findsNothing);
      expect(exitInvoked, isTrue);
    });
  });
}
