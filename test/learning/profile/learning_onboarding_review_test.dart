import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/profile/viewmodels/learning_onboarding_viewmodel.dart';
import 'package:andril_mobile/features/learning/profile/widgets/onboarding_step_review_widget.dart';

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
  group('Onboarding Step Review Widget Tests (Batch 02C)', () {
    late LearningOnboardingViewModel viewModel;

    setUp(() {
      viewModel = LearningOnboardingViewModel();
    });

    tearDown(() {
      if (!viewModel.isDisposed) {
        viewModel.dispose();
      }
    });

    // 1. Displays current display-name draft
    testWidgets('1. Displays current display-name draft', (tester) async {
      viewModel.setDisplayName('Kavitha Shanmugam');

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('review_display_name_text')), findsOneWidget);
      expect(find.text('Kavitha Shanmugam'), findsOneWidget);
    });

    // 2. Displays optional bio safely
    testWidgets('2. Displays optional bio safely', (tester) async {
      viewModel.setBio('Exploring mobile app architectures and UX patterns');

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('review_bio_text')), findsOneWidget);
      expect(
        find.text('Exploring mobile app architectures and UX patterns'),
        findsOneWidget,
      );
    });

    // 3. Displays Skills to Learn
    testWidgets('3. Displays Skills to Learn', (tester) async {
      viewModel.addSkillToLearn('Flutter');
      viewModel.addSkillToLearn('GraphQL');

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('review_skills_to_learn_section')),
          findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('GraphQL'), findsOneWidget);
    });

    // 4. Displays Skills to Share
    testWidgets('4. Displays Skills to Share', (tester) async {
      viewModel.addSkillToShare('Python');
      viewModel.addSkillToShare('UI/UX Design');

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('review_skills_to_share_section')),
          findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('UI/UX Design'), findsOneWidget);
    });

    // 5. Displays Learning Goals
    testWidgets('5. Displays Learning Goals', (tester) async {
      viewModel.addLearningGoal('Master State Management');
      viewModel.addLearningGoal('Build Open Source Library');

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('review_learning_goals_section')),
          findsOneWidget);
      expect(find.text('Master State Management'), findsOneWidget);
      expect(find.text('Build Open Source Library'), findsOneWidget);
    });

    // 6. Displays optional verified availability draft
    testWidgets('6. Displays optional verified availability draft',
        (tester) async {
      viewModel.setAvailabilityPreference('5-10 hrs/week');

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('review_availability_text')), findsOneWidget);
      expect(find.text('5-10 hrs/week'), findsOneWidget);
    });

    // 7. Handles missing optional fields
    testWidgets('7. Handles missing optional fields gracefully',
        (tester) async {
      // Empty bio, no availability, empty skills, empty goals
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not provided'), findsOneWidget);
      expect(find.text('None provided'), findsOneWidget);
      expect(find.text('No skills selected'), findsOneWidget);
      expect(find.text('No skills specified'), findsOneWidget);
      expect(find.text('No goals selected'), findsOneWidget);
      expect(find.text('Not specified'), findsOneWidget);
    });

    // 8. Handles long Unicode text
    testWidgets('8. Handles long Unicode text', (tester) async {
      const tamilName = 'சிவா ஆனந்தன் 🌟';
      const tamilBio =
          'தமிழ்நாட்டின் மென்பொருள் கட்டமைப்பு ஆர்வலர் மற்றும் கற்றல் வழிநடத்துநர் 🚀';
      const tamilSkill = 'செயற்கை நுண்ணறிவு & இயந்திர கற்றல்';
      const tamilGoal = 'முழுமையான மொபைல் செயலியை உருவாக்குதல் ✨';

      viewModel.setDisplayName(tamilName);
      viewModel.setBio(tamilBio);
      viewModel.addSkillToLearn(tamilSkill);
      viewModel.addLearningGoal(tamilGoal);

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(tamilName), findsOneWidget);
      expect(find.text(tamilBio), findsOneWidget);
      expect(find.text(tamilSkill), findsOneWidget);
      expect(find.text(tamilGoal), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 9. Back/Edit callback works
    testWidgets('9. Back/Edit callback works', (tester) async {
      bool backInvoked = false;
      int? editedStep;

      viewModel.setStep(4);

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(
            viewModel: viewModel,
            onBack: () => backInvoked = true,
            onEditStep: (step) => editedStep = step,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Edit on Profile Basics
      final editButtons = find.text('Edit');
      expect(editButtons, findsWidgets);

      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(editedStep, 0);

      // Tap Back button (ensure visible first in scroll view)
      final backButton = find.byKey(const Key('onboarding_review_back_button'));
      await tester.ensureVisible(backButton);
      await tester.pumpAndSettle();
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(backInvoked, isTrue);
      expect(viewModel.currentStep, 3);
    });

    // 10. Does not expose account IDs or JWT values
    testWidgets('10. Does not expose account IDs or JWT values',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('accountId'), findsNothing);
      expect(find.textContaining('profileId'), findsNothing);
      expect(find.textContaining('Bearer'), findsNothing);
      expect(find.textContaining('eyJ'), findsNothing);
    });

    // 11. Does not grant local activation
    testWidgets('11. Does not grant local activation (submit is disabled)',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      final submitButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('onboarding_review_submit_button')),
      );

      // Invariant: Submit button is disabled because backend activation is pending
      expect(submitButton.onPressed, isNull);
    });

    // 12. Does not navigate to Home
    testWidgets('12. Does not navigate to Home', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no home route was pushed or rendered
      expect(find.text('Learning Home'), findsNothing);
      expect(find.text('Classrooms'), findsNothing);
    });

    // 13. Does not call a backend
    testWidgets('13. Does not call a backend', (tester) async {
      // Invariant: widget is purely presentational
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    // 14. Shows an appropriate pending activation state
    testWidgets('14. Shows an appropriate pending activation state',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('review_activation_disclaimer')),
          findsOneWidget);
      expect(
          find.byKey(const Key('review_submit_pending_note')), findsOneWidget);
      expect(
        find.text(
          'Proposed Review Layout: Profile activation is managed by M2 and requires backend authentication. This is an unpersisted draft review.',
        ),
        findsOneWidget,
      );
    });

    // 15. Supports narrow width and text scaling
    testWidgets('15. Supports narrow width (320dp) and text scaling (1.5x)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepReviewWidget(viewModel: viewModel),
          textScaler: const TextScaler.linear(1.5),
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // 16. No uncaught exceptions or overflow across viewports
    testWidgets('16. No uncaught exceptions or overflow across viewports',
        (tester) async {
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
            OnboardingStepReviewWidget(viewModel: viewModel),
            size: size,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });
  });
}
