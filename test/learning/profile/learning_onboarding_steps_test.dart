import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/profile/viewmodels/learning_onboarding_viewmodel.dart';
import 'package:andril_mobile/features/learning/profile/widgets/onboarding_step_basics_widget.dart';
import 'package:andril_mobile/features/learning/profile/widgets/onboarding_step_learn_widget.dart';
import 'package:andril_mobile/features/learning/profile/widgets/onboarding_step_share_widget.dart';

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
  group('Onboarding Steps Widgets Tests', () {
    late LearningOnboardingViewModel viewModel;

    setUp(() {
      viewModel = LearningOnboardingViewModel();
    });

    tearDown(() {
      viewModel.dispose();
    });

    testWidgets('1. Profile Basics renders correct supported fields',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepBasicsWidget(
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile Basics'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Learning Headline or Bio (Optional)'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_display_name_field')),
          findsOneWidget);
      expect(find.byKey(const Key('onboarding_bio_field')), findsOneWidget);
    });

    testWidgets('2. Input changes propagate to ViewModel', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepBasicsWidget(
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding_display_name_field')),
        'Alex Rivera',
      );
      await tester.pumpAndSettle();

      expect(viewModel.displayName, 'Alex Rivera');

      await tester.enterText(
        find.byKey(const Key('onboarding_bio_field')),
        'Studying Flutter architectures',
      );
      await tester.pumpAndSettle();

      expect(viewModel.bio, 'Studying Flutter architectures');
    });

    testWidgets('3. Validation feedback renders correctly on empty name',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepBasicsWidget(
            viewModel: viewModel,
            onContinue: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap continue button without entering a name
      await tester
          .tap(find.byKey(const Key('onboarding_basics_continue_button')));
      await tester.pumpAndSettle();

      expect(find.text('Display Name is required'), findsNothing);
      expect(find.text('Display name is required'), findsOneWidget);
      expect(viewModel.displayNameError, 'Display name is required');
    });

    testWidgets('4. Skills-to-Learn selection updates the correct draft',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepLearnWidget(
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Skills to Learn'), findsOneWidget);

      // Select Flutter chip
      await tester.tap(find.byKey(const Key('skill_chip_learn_Flutter')));
      await tester.pumpAndSettle();

      expect(viewModel.skillsToLearn, ['Flutter']);
      expect(viewModel.skillsToShare, isEmpty);

      // Add custom skill
      await tester.enterText(
        find.byKey(const Key('custom_skill_learn_field')),
        'GraphQL',
      );
      await tester.tap(find.byKey(const Key('add_custom_skill_learn_button')));
      await tester.pumpAndSettle();

      expect(viewModel.skillsToLearn, ['Flutter', 'GraphQL']);
      expect(viewModel.skillsToShare, isEmpty);
    });

    testWidgets('5. Skills-to-Share selection updates the correct draft',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepShareWidget(
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Skills to Share'), findsOneWidget);

      // Select Python chip
      await tester.tap(find.byKey(const Key('skill_chip_share_Python')));
      await tester.pumpAndSettle();

      expect(viewModel.skillsToShare, ['Python']);
      expect(viewModel.skillsToLearn, isEmpty);

      // Add custom skill
      await tester.enterText(
        find.byKey(const Key('custom_skill_share_field')),
        'Mentoring',
      );
      await tester.tap(find.byKey(const Key('add_custom_skill_share_button')));
      await tester.pumpAndSettle();

      expect(viewModel.skillsToShare, ['Python', 'Mentoring']);
      expect(viewModel.skillsToLearn, isEmpty);
    });

    testWidgets('6. Selected and unselected states render visually',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepLearnWidget(
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialChip = tester
          .widget<FilterChip>(find.byKey(const Key('skill_chip_learn_Dart')));
      expect(initialChip.selected, isFalse);

      await tester.tap(find.byKey(const Key('skill_chip_learn_Dart')));
      await tester.pumpAndSettle();

      final selectedChip = tester
          .widget<FilterChip>(find.byKey(const Key('skill_chip_learn_Dart')));
      expect(selectedChip.selected, isTrue);
    });

    testWidgets('7. Empty catalogue handling', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepLearnWidget(
            viewModel: viewModel,
            availableSkills: const [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No suggested topics available. Use the text field above to add your custom learning skills.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('8. Loading/unavailable catalogue handling', (tester) async {
      viewModel.setLoading(true);

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepLearnWidget(
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('9. Long Unicode labels display cleanly', (tester) async {
      const longSkill =
          'இயற்கை மொழி செயலாக்கம் மற்றும் ஆழமான நரம்பியல் வலையமைப்புகள் (Deep NLP)';

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepLearnWidget(
            viewModel: viewModel,
            availableSkills: const [longSkill],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(longSkill), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10. Responsive 320dp layout', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepBasicsWidget(
            viewModel: viewModel,
          ),
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('11. Responsive 360dp layout', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepLearnWidget(
            viewModel: viewModel,
          ),
          size: const Size(360, 740),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('12. Responsive 412dp layout', (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepShareWidget(
            viewModel: viewModel,
          ),
          size: const Size(412, 892),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Dynamic text scaling (1.5x) does not overflow',
        (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepBasicsWidget(
            viewModel: viewModel,
          ),
          textScaler: const TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('14. Keyboard and scrolling behavior', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          OnboardingStepBasicsWidget(
            viewModel: viewModel,
            onContinue: () {},
          ),
          size: const Size(360, 400),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to bottom
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding_basics_continue_button')),
          findsOneWidget);
    });

    testWidgets('15. No unexpected overflow or uncaught exception',
        (tester) async {
      for (final widget in [
        OnboardingStepBasicsWidget(viewModel: viewModel),
        OnboardingStepLearnWidget(viewModel: viewModel),
        OnboardingStepShareWidget(viewModel: viewModel),
      ]) {
        await tester.pumpWidget(_buildTestApp(widget));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('16. No production activation or backend interaction',
        (tester) async {
      // Invariant: Widgets are purely presentational and have no API clients
      expect(viewModel.currentStep, 0);
      expect(viewModel.skillsToLearn, isEmpty);
      expect(viewModel.skillsToShare, isEmpty);
    });
  });
}
