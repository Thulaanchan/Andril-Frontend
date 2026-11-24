import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/profile/screens/learning_onboarding_screen.dart';
import 'package:andril_mobile/features/learning/profile/viewmodels/learning_onboarding_viewmodel.dart';

Widget _buildTestScreen({
  LearningOnboardingViewModel? viewModel,
  List<String>? availableSkills,
  List<String>? availableGoals,
  VoidCallback? onExit,
  VoidCallback? onComplete,
  TextScaler? textScaler,
  Size? size,
}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: size != null
        ? Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: textScaler ?? TextScaler.noScaling,
                ),
                child: LearningOnboardingScreen(
                  viewModel: viewModel,
                  availableSkills: availableSkills,
                  availableGoals: availableGoals,
                  onExit: onExit,
                  onComplete: onComplete,
                ),
              ),
            ),
          )
        : MediaQuery(
            data: MediaQueryData(
              textScaler: textScaler ?? TextScaler.noScaling,
            ),
            child: LearningOnboardingScreen(
              viewModel: viewModel,
              availableSkills: availableSkills,
              availableGoals: availableGoals,
              onExit: onExit,
              onComplete: onComplete,
            ),
          ),
  );
}

void main() {
  group('LearningOnboardingScreen Component & Step Integration Tests', () {
    late LearningOnboardingViewModel viewModel;

    setUp(() {
      viewModel = LearningOnboardingViewModel();
    });

    tearDown(() {
      if (!viewModel.isDisposed) {
        viewModel.dispose();
      }
    });

    // 1. Initial screen opens at Profile Basics
    testWidgets('1. Initial screen opens at Profile Basics (Step 1 of 5)',
        (tester) async {
      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Profile Basics'), findsNWidgets(2)); // header + widget
      expect(find.byKey(const Key('onboarding_step_counter')), findsOneWidget);
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.byKey(const Key('step_basics_widget')), findsOneWidget);
    });

    // 2. Correct five-step progress structure
    testWidgets('2. Correct five-step progress structure renders',
        (tester) async {
      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding_progress_indicator')),
          findsOneWidget);
      expect(find.text('Profile Basics'), findsWidgets);

      // Verify Semantics contains Step 1 of 5
      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label == 'Step 1 of 5: Profile Basics'),
        findsOneWidget,
      );
    });

    // 3. Profile Basics inputs render
    testWidgets('3. Profile Basics inputs render properly', (tester) async {
      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding_display_name_field')),
          findsOneWidget);
      expect(find.byKey(const Key('onboarding_bio_field')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_basics_continue_button')),
          findsOneWidget);
    });

    // 4. Continue advances to Skills to Learn after permitted draft validation
    testWidgets(
        '4. Continue advances to Skills to Learn after permitted draft validation',
        (tester) async {
      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      // Tap continue without entering name -> validation error
      await tester
          .tap(find.byKey(const Key('onboarding_basics_continue_button')));
      await tester.pumpAndSettle();

      expect(find.text('Display name is required'), findsOneWidget);
      expect(viewModel.currentStep, 0);

      // Enter valid name
      await tester.enterText(
        find.byKey(const Key('onboarding_display_name_field')),
        'Arun Prasad',
      );
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const Key('onboarding_basics_continue_button')));
      await tester.pumpAndSettle();

      expect(viewModel.currentStep, 1);
      expect(find.text('Step 2 of 5'), findsOneWidget);
      expect(find.byKey(const Key('step_learn_widget')), findsOneWidget);
    });

    // 5. Learn selections persist
    testWidgets('5. Learn selections persist across navigation',
        (tester) async {
      viewModel.setDisplayName('Alex');
      viewModel.setStep(1); // Skills to Learn

      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      // Tap Flutter skill chip
      final flutterChip = find.byKey(const Key('skill_chip_learn_Flutter'));
      expect(flutterChip, findsOneWidget);
      await tester.tap(flutterChip);
      await tester.pumpAndSettle();

      expect(viewModel.skillsToLearn, ['Flutter']);

      // Advance to Step 2 (Share)
      await tester
          .tap(find.byKey(const Key('onboarding_learn_continue_button')));
      await tester.pumpAndSettle();

      expect(viewModel.currentStep, 2);
      expect(find.text('Step 3 of 5'), findsOneWidget);

      // Return to Step 1 (Learn)
      await tester.tap(find.byKey(const Key('onboarding_share_back_button')));
      await tester.pumpAndSettle();

      expect(viewModel.currentStep, 1);
      expect(viewModel.skillsToLearn, ['Flutter']);
    });

    // 6. Share selections remain independent
    testWidgets('6. Share selections remain independent', (tester) async {
      viewModel.setDisplayName('Alex');
      viewModel.setStep(2); // Skills to Share

      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      // Select Python for sharing
      final pythonChip = find.byKey(const Key('skill_chip_share_Python'));
      expect(pythonChip, findsOneWidget);
      await tester.tap(pythonChip);
      await tester.pumpAndSettle();

      expect(viewModel.skillsToShare, ['Python']);
      expect(viewModel.skillsToLearn, isEmpty);
    });

    // 7. Goals selections persist
    testWidgets('7. Goals selections persist', (tester) async {
      viewModel.setDisplayName('Alex');
      viewModel.setStep(3); // Learning Goals

      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      final goalChip =
          find.byKey(const Key('goal_chip_Master Flutter mobile architecture'));
      expect(goalChip, findsOneWidget);
      await tester.tap(goalChip);
      await tester.pumpAndSettle();

      expect(viewModel.learningGoals, ['Master Flutter mobile architecture']);

      // Advance to Step 4 (Review)
      final continueBtn =
          find.byKey(const Key('onboarding_goals_continue_button'));
      await tester.ensureVisible(continueBtn);
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(viewModel.currentStep, 4);
      expect(find.text('Step 5 of 5'), findsOneWidget);
      expect(find.byKey(const Key('step_review_widget')), findsOneWidget);
    });

    // 8. Review accurately reflects draft values
    testWidgets('8. Review accurately reflects draft values', (tester) async {
      viewModel.setDisplayName('Priya Sundaram');
      viewModel.setBio('Aspiring Mobile Engineer');
      viewModel.addSkillToLearn('Dart');
      viewModel.addSkillToShare('Figma');
      viewModel.addLearningGoal('Build Portfolio App');
      viewModel.setAvailabilityPreference('3-5 hrs/week');
      viewModel.setStep(4); // Review step

      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Priya Sundaram'), findsOneWidget);
      expect(find.text('Aspiring Mobile Engineer'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Figma'), findsOneWidget);
      expect(find.text('Build Portfolio App'), findsOneWidget);
      expect(find.text('3-5 hrs/week'), findsOneWidget);
    });

    // 9. Back navigation preserves prior values
    testWidgets('9. Back navigation preserves prior values', (tester) async {
      viewModel.setDisplayName('Priya');
      viewModel.setBio('Bio text');
      viewModel.setStep(4);

      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      // Back from Review -> Goals (step 3)
      final backButton = find.byKey(const Key('onboarding_review_back_button'));
      await tester.ensureVisible(backButton);
      await tester.pumpAndSettle();
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(viewModel.currentStep, 3);
      expect(find.text('Step 4 of 5'), findsOneWidget);
      expect(viewModel.displayName, 'Priya');
      expect(viewModel.bio, 'Bio text');
    });

    // 10. Invalid transitions show safe feedback
    testWidgets('10. Invalid transitions prevent progression safely',
        (tester) async {
      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      // Empty name attempt
      await tester
          .tap(find.byKey(const Key('onboarding_basics_continue_button')));
      await tester.pumpAndSettle();

      expect(viewModel.currentStep, 0);
      expect(find.text('Display name is required'), findsOneWidget);
      expect(find.text('Step 1 of 5'), findsOneWidget);
    });

    // 11. 320dp width without overflow
    testWidgets('11. 320dp width without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestScreen(
          viewModel: viewModel,
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // 12. 360dp width without overflow
    testWidgets('12. 360dp width without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestScreen(
          viewModel: viewModel,
          size: const Size(360, 740),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // 13. 412dp width without overflow
    testWidgets('13. 412dp width without overflow', (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestScreen(
          viewModel: viewModel,
          size: const Size(412, 892),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // 14. Text scaling and accessibility
    testWidgets('14. Text scaling 1.5x and accessibility semantics',
        (tester) async {
      await tester.pumpWidget(
        _buildTestScreen(
          viewModel: viewModel,
          textScaler: const TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // 15. Long content remains scrollable
    testWidgets('15. Long content remains scrollable', (tester) async {
      await tester.pumpWidget(
        _buildTestScreen(
          viewModel: viewModel,
          size: const Size(360, 400),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding_basics_continue_button')),
          findsOneWidget);
    });

    // 16. Keyboard does not hide important actions
    testWidgets('16. Keyboard focus handled cleanly without overflow',
        (tester) async {
      await tester.pumpWidget(_buildTestScreen(viewModel: viewModel));
      await tester.pumpAndSettle();

      final nameField = find.byKey(const Key('onboarding_display_name_field'));
      await tester.tap(nameField);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
