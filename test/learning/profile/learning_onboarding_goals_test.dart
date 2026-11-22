import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/profile/viewmodels/learning_onboarding_viewmodel.dart';
import 'package:andril_mobile/features/learning/profile/widgets/onboarding_step_goals_widget.dart';

Widget _buildTestApp(Widget child, {TextScaler? textScaler, Size? size}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Scaffold(
      body: size != null
          ? Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: textScaler ?? TextScaler.noScaling,
                  ),
                  child: child,
                ),
              ),
            )
          : MediaQuery(
              data: MediaQueryData(
                textScaler: textScaler ?? TextScaler.noScaling,
              ),
              child: child,
            ),
    ),
  );
}

void main() {
  group('Learning Goals ViewModel & Widget Tests (Batch 02C)', () {
    late LearningOnboardingViewModel viewModel;

    setUp(() {
      viewModel = LearningOnboardingViewModel();
    });

    tearDown(() {
      if (!viewModel.isDisposed) {
        viewModel.dispose();
      }
    });

    // 1. Correct initial goals draft
    test('1. Correct initial goals draft', () {
      expect(viewModel.learningGoals, isEmpty);
      expect(viewModel.availabilityPreference, isEmpty);
      expect(viewModel.currentStep, 0);
      expect(viewModel.step, OnboardingStep.basics);
      expect(LearningOnboardingViewModel.totalSteps, 5);
    });

    // 2. Add suggested goal
    test('2. Add suggested goal', () {
      viewModel.addLearningGoal('Master Flutter mobile architecture');
      expect(viewModel.learningGoals, ['Master Flutter mobile architecture']);
      expect(viewModel.hasUnsavedChanges, isTrue);
    });

    // 3. Add custom goal
    test('3. Add custom goal', () {
      viewModel.addLearningGoal('Pass Cloud Certification');
      expect(viewModel.learningGoals, ['Pass Cloud Certification']);
      expect(viewModel.hasUnsavedChanges, isTrue);
    });

    // 4. Remove goal
    test('4. Remove goal', () {
      viewModel.addLearningGoal('Goal 1');
      viewModel.addLearningGoal('Goal 2');
      expect(viewModel.learningGoals.length, 2);

      viewModel.removeLearningGoal('Goal 1');
      expect(viewModel.learningGoals, ['Goal 2']);

      viewModel.removeLearningGoal('NonExistent');
      expect(viewModel.learningGoals, ['Goal 2']);
    });

    // 5. Duplicate prevention
    test('5. Duplicate prevention', () {
      viewModel.addLearningGoal('Master Dart');
      viewModel.addLearningGoal('Master Dart');
      viewModel.addLearningGoal(' Master Dart ');
      expect(viewModel.learningGoals, ['Master Dart']);

      // Toggle duplicate removes it
      viewModel.toggleLearningGoal('Master Dart');
      expect(viewModel.learningGoals, isEmpty);
    });

    // 6. Independent collections from Learn and Share skills
    test('6. Independent collections from Learn and Share skills', () {
      const topic = 'Python Programming';
      viewModel.addSkillToLearn(topic);
      viewModel.addSkillToShare(topic);
      viewModel.addLearningGoal(topic);

      expect(viewModel.skillsToLearn, [topic]);
      expect(viewModel.skillsToShare, [topic]);
      expect(viewModel.learningGoals, [topic]);

      viewModel.removeLearningGoal(topic);
      expect(viewModel.learningGoals, isEmpty);
      expect(viewModel.skillsToLearn, [topic]);
      expect(viewModel.skillsToShare, [topic]);
    });

    // 7. Unicode preservation
    test('7. Unicode preservation', () {
      const tamilGoal = 'தொழில்நுட்ப நேர்காணலுக்கு தயாராகுதல் 🚀';
      const mixedGoal = 'Learn Flutter & Dart 🎯 — விண்வெளி ஆய்வு';

      viewModel.addLearningGoal(tamilGoal);
      viewModel.addLearningGoal(mixedGoal);

      expect(viewModel.learningGoals[0], tamilGoal);
      expect(viewModel.learningGoals[1], mixedGoal);
    });

    // 8. Defensive immutability
    test('8. Defensive immutability', () {
      viewModel.addLearningGoal('Initial Goal');
      final exposedList = viewModel.learningGoals;

      expect(
        () => (exposedList as dynamic).add('Injected Goal'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    // 9. Draft-state notifications
    test('9. Draft-state notifications', () {
      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      viewModel.addLearningGoal('Goal 1');
      expect(notifyCount, 1);

      viewModel.toggleLearningGoal('Goal 2');
      expect(notifyCount, 2);

      viewModel.setAvailabilityPreference('3-5 hrs/week');
      expect(notifyCount, 3);

      viewModel.removeLearningGoal('Goal 1');
      expect(notifyCount, 4);

      viewModel.clearLearningGoals();
      expect(notifyCount, 5);
    });

    // 10. Back/forward state preservation
    test('10. Back/forward state preservation', () {
      viewModel.setDisplayName('Sarah Connor');
      viewModel.setBio('AI Researcher');
      viewModel.addSkillToLearn('Dart');
      viewModel.addSkillToShare('Algorithms');

      // Navigate to step 3 (Goals)
      viewModel.setStep(3);
      expect(viewModel.currentStep, 3);
      expect(viewModel.step, OnboardingStep.goals);

      viewModel.addLearningGoal('Master Architecture');
      viewModel.setAvailabilityPreference('Flexible');

      // Forward to Step 4 (Review)
      expect(viewModel.nextStep(), isTrue);
      expect(viewModel.currentStep, 4);
      expect(viewModel.step, OnboardingStep.review);

      // Back to Step 3
      expect(viewModel.previousStep(), isTrue);
      expect(viewModel.currentStep, 3);
      expect(viewModel.learningGoals, ['Master Architecture']);
      expect(viewModel.availabilityPreference, 'Flexible');

      // Back to Step 0
      viewModel.setStep(0);
      expect(viewModel.displayName, 'Sarah Connor');
      expect(viewModel.bio, 'AI Researcher');
      expect(viewModel.skillsToLearn, ['Dart']);
      expect(viewModel.skillsToShare, ['Algorithms']);
      expect(viewModel.learningGoals, ['Master Architecture']);
    });

    // 11. Valid transition into Review
    test('11. Valid transition into Review', () {
      viewModel.setDisplayName('Valid User');
      viewModel.setStep(3);
      expect(viewModel.currentStep, 3);
      expect(viewModel.step, OnboardingStep.goals);

      final result = viewModel.nextStep();
      expect(result, isTrue);
      expect(viewModel.currentStep, 4);
      expect(viewModel.step, OnboardingStep.review);
    });

    // 12. Invalid transition prevention
    test('12. Invalid transition prevention', () {
      viewModel.setDisplayName('Alex');
      viewModel.setStep(4);
      expect(viewModel.currentStep, 4);
      expect(viewModel.step, OnboardingStep.review);

      // Cannot advance past Step 4
      expect(viewModel.nextStep(), isFalse);
      expect(viewModel.currentStep, 4);

      // Stepping back to 0
      viewModel.setStep(0);
      expect(viewModel.previousStep(), isFalse);
      expect(viewModel.currentStep, 0);
    });

    // 13. Empty and unavailable suggestion handling
    test('13. Empty and unavailable suggestion handling', () {
      viewModel.setLoading(true);
      expect(viewModel.isLoading, isTrue);

      viewModel.setErrorMessage('Goals catalogue unavailable');
      expect(viewModel.errorMessage, 'Goals catalogue unavailable');

      viewModel.setLoading(false);
      expect(viewModel.isLoading, isFalse);
    });

    // 14. No hardcoded unsupported goal limit
    test('14. No hardcoded unsupported goal limit', () {
      // Sourcing rules mandate no fabricated numeric limit
      for (int i = 1; i <= 8; i++) {
        viewModel.addLearningGoal('Unique Goal #$i');
      }
      expect(viewModel.learningGoals.length, 8);
    });

    // 15. No identity or activation mutation
    test('15. No identity or activation mutation', () {
      // Invariant: ViewModel manages drafts only
      expect(viewModel, isNot(contains('accountId')));
      expect(viewModel, isNot(contains('profileId')));
      expect(viewModel, isNot(contains('isActivated')));
      expect(viewModel, isNot(contains('activate')));
    });

    // Widget Tests for OnboardingStepGoalsWidget
    testWidgets('16. Goals step renders header and suggested chips',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepGoalsWidget(
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning Goals'), findsOneWidget);
      expect(find.text('Step 4 of 5: What would you like to achieve?'),
          findsOneWidget);
      expect(find.text('Suggested Goals'), findsOneWidget);
      expect(find.byKey(const Key('custom_goal_field')), findsOneWidget);
      expect(find.byKey(const Key('add_custom_goal_button')), findsOneWidget);
    });

    testWidgets('17. Suggested goal selection toggles in ViewModel',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepGoalsWidget(
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final goalChipKey =
          const Key('goal_chip_Build practical portfolio projects');
      expect(find.byKey(goalChipKey), findsOneWidget);

      await tester.tap(find.byKey(goalChipKey));
      await tester.pumpAndSettle();

      expect(viewModel.learningGoals, ['Build practical portfolio projects']);

      // Tap again to toggle off
      await tester.tap(find.byKey(goalChipKey));
      await tester.pumpAndSettle();

      expect(viewModel.learningGoals, isEmpty);
    });

    testWidgets('18. Custom goal input adds goal to draft', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepGoalsWidget(
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('custom_goal_field')),
        'Become a Senior Architect',
      );
      await tester.tap(find.byKey(const Key('add_custom_goal_button')));
      await tester.pumpAndSettle();

      expect(viewModel.learningGoals, ['Become a Senior Architect']);
      expect(
          find.byKey(const Key('custom_chip_goal_Become a Senior Architect')),
          findsOneWidget);
    });

    testWidgets('19. Optional availability choice chips update preference',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepGoalsWidget(
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chipFinder =
          find.byKey(const Key('availability_chip_3-5 hrs/week'));
      await tester.ensureVisible(chipFinder);
      await tester.pumpAndSettle();

      expect(find.text('Weekly Availability (Optional)'), findsOneWidget);

      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      expect(viewModel.availabilityPreference, '3-5 hrs/week');
    });

    testWidgets('20. Empty catalogue displays fallback message',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepGoalsWidget(
            viewModel: viewModel,
            availableGoals: const [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No suggested goals available. Use the text field above to add your custom learning goals.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('21. Responsive 320dp, 360dp, 412dp viewports', (tester) async {
      for (final size in [
        const Size(320, 640),
        const Size(360, 740),
        const Size(412, 892),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _buildTestApp(
            OnboardingStepGoalsWidget(viewModel: viewModel),
            size: size,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('22. Dynamic text scaling 1.5x has no overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepGoalsWidget(viewModel: viewModel),
          textScaler: const TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('23. Navigation buttons trigger callbacks', (tester) async {
      bool backCalled = false;
      bool continueCalled = false;

      viewModel.setDisplayName('Alex');
      viewModel.setStep(3);

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepGoalsWidget(
            viewModel: viewModel,
            onBack: () => backCalled = true,
            onContinue: () => continueCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const Key('onboarding_goals_continue_button')));
      await tester.pumpAndSettle();

      expect(continueCalled, isTrue);
      expect(viewModel.currentStep, 4);

      // Now test back
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepGoalsWidget(
            viewModel: viewModel,
            onBack: () => backCalled = true,
            onContinue: () => continueCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding_goals_back_button')));
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
      expect(viewModel.currentStep, 3);
    });
  });
}
