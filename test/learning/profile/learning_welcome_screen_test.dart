import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/profile/screens/learning_welcome_screen.dart';
import 'package:andril_mobile/features/learning/profile/viewmodels/learning_welcome_viewmodel.dart';
import 'package:andril_mobile/features/learning/profile/widgets/welcome_page_indicator.dart';
import 'package:andril_mobile/features/learning/profile/widgets/welcome_wave_divider.dart';

void _setDeviceSize(WidgetTester tester, {Size size = const Size(412, 915)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _buildTestApp(
  Widget child, {
  TextScaler? textScaler,
}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: MediaQuery(
      data: MediaQueryData(
        textScaler: textScaler ?? TextScaler.noScaling,
      ),
      child: child,
    ),
  );
}

void main() {
  group('LearningWelcomeScreen - Structure and Visual Elements', () {
    testWidgets('renders all core UI elements and branding assets',
        (tester) async {
      _setDeviceSize(tester);

      await tester.pumpWidget(_buildTestApp(const LearningWelcomeScreen()));
      await tester.pumpAndSettle();

      // Screen is rendered without errors
      expect(find.byType(LearningWelcomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify official branding logo asset and semantic label
      final imageWidgets =
          tester.widgetList<Image>(find.byType(Image)).toList();
      final assetNames = imageWidgets
          .map((img) => img.image is AssetImage
              ? (img.image as AssetImage).assetName
              : null)
          .whereType<String>()
          .toList();

      expect(assetNames, contains('assets/branding/andril_black_logo.png'));
      expect(
        assetNames,
        contains('assets/images/learning/profile/welcome_study_desk.webp'),
      );

      final logoImage = imageWidgets.firstWhere(
        (img) =>
            img.image is AssetImage &&
            (img.image as AssetImage).assetName ==
                'assets/branding/andril_black_logo.png',
      );
      expect(logoImage.semanticLabel, 'ANDRIL');

      // Verify Learning module badge with graduation cap icon
      expect(find.text('Learning'), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsWidgets);

      // Verify RichText heading text and token colors
      final richTextFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          return widget.text.toPlainText() == 'Start Your Learning Journey';
        }
        return false;
      });
      expect(richTextFinder, findsOneWidget);

      final richText = tester.widget<RichText>(richTextFinder);
      final rootSpan = richText.text as TextSpan;
      expect(rootSpan.children?.length, 2);

      final firstSpan = rootSpan.children![0] as TextSpan;
      expect(firstSpan.text, 'Start Your ');
      expect(firstSpan.style?.color, LearningColors.heading);

      final secondSpan = rootSpan.children![1] as TextSpan;
      expect(secondSpan.text, 'Learning Journey');
      expect(secondSpan.style?.color, LearningColors.primary);

      // Verify subtitle
      expect(
        find.text('Connect, collaborate, and grow through Learning.'),
        findsOneWidget,
      );

      // Verify Wave Divider
      expect(find.byType(WelcomeWaveDivider), findsOneWidget);

      // Verify PageView and PageIndicator
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(WelcomePageIndicator), findsOneWidget);

      // Verify initial feature card (Variant 01)
      expect(find.text('Share & Learn Skills'), findsOneWidget);

      // Verify action buttons
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Back'), findsOneWidget);

      // Verify Privacy notice
      expect(
        find.text('Your Learning profile stays private within this module.'),
        findsOneWidget,
      );
    });
  });

  group('LearningWelcomeScreen - Carousel Interaction & State Sync', () {
    testWidgets('horizontal swipe updates active card and page indicator',
        (tester) async {
      _setDeviceSize(tester);

      await tester.pumpWidget(_buildTestApp(const LearningWelcomeScreen()));
      await tester.pumpAndSettle();

      // Card 1 initially active
      expect(find.text('Share & Learn Skills'), findsOneWidget);

      // Swipe to Card 2
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.text('Join Learning Circles'), findsOneWidget);

      // Swipe to Card 3
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.text('Track Your Growth'), findsOneWidget);
    });

    testWidgets('tapping page indicator navigates to corresponding card',
        (tester) async {
      _setDeviceSize(tester);

      await tester.pumpWidget(_buildTestApp(const LearningWelcomeScreen()));
      await tester.pumpAndSettle();

      final indicator3Finder = find.bySemanticsLabel('Page 3 of 3');
      await tester.ensureVisible(indicator3Finder);
      await tester.tap(indicator3Finder);
      await tester.pumpAndSettle();

      expect(find.text('Track Your Growth'), findsOneWidget);

      final indicator1Finder = find.bySemanticsLabel('Page 1 of 3');
      await tester.ensureVisible(indicator1Finder);
      await tester.tap(indicator1Finder);
      await tester.pumpAndSettle();

      expect(find.text('Share & Learn Skills'), findsOneWidget);
    });

    testWidgets('syncs with externally provided LearningWelcomeViewModel',
        (tester) async {
      _setDeviceSize(tester);

      final customViewModel = LearningWelcomeViewModel();

      await tester.pumpWidget(
        _buildTestApp(LearningWelcomeScreen(viewModel: customViewModel)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share & Learn Skills'), findsOneWidget);

      // Update external viewmodel programmatically
      customViewModel.setIndex(1);
      await tester.pumpAndSettle();

      expect(find.text('Join Learning Circles'), findsOneWidget);

      customViewModel.setIndex(2);
      await tester.pumpAndSettle();

      expect(find.text('Track Your Growth'), findsOneWidget);

      customViewModel.dispose();
    });
  });

  group('LearningWelcomeScreen - Action Buttons & Navigation Callbacks', () {
    testWidgets('triggers onContinue callback when Continue is tapped',
        (tester) async {
      _setDeviceSize(tester);

      int continueCallCount = 0;

      await tester.pumpWidget(
        _buildTestApp(
          LearningWelcomeScreen(
            onContinue: () => continueCallCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(continueCallCount, 1);
    });

    testWidgets('triggers onBack callback when Back is tapped', (tester) async {
      _setDeviceSize(tester);

      int backCallCount = 0;

      await tester.pumpWidget(
        _buildTestApp(
          LearningWelcomeScreen(
            onBack: () => backCallCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.widgetWithText(TextButton, 'Back');
      await tester.ensureVisible(backButton);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(backCallCount, 1);
    });

    testWidgets('prevents duplicate callbacks on rapid consecutive taps',
        (tester) async {
      _setDeviceSize(tester);

      int continueCallCount = 0;

      await tester.pumpWidget(
        _buildTestApp(
          LearningWelcomeScreen(
            onContinue: () => continueCallCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger multiple calls rapidly
      final buttonFinder = find.widgetWithText(ElevatedButton, 'Continue');
      final buttonWidget = tester.widget<ElevatedButton>(buttonFinder);

      buttonWidget.onPressed?.call();
      buttonWidget.onPressed?.call();

      await tester.pumpAndSettle();
      expect(continueCallCount, 1);
    });
  });

  group('LearningWelcomeScreen - Responsiveness & Accessibility', () {
    testWidgets(
        'renders on compact 320x568 screen with 1.5x text scale without overflow',
        (tester) async {
      _setDeviceSize(tester, size: const Size(320, 568));

      await tester.pumpWidget(
        _buildTestApp(
          const LearningWelcomeScreen(),
          textScaler: const TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LearningWelcomeScreen), findsOneWidget);

      // Verify that content can scroll without error
      await tester.drag(
          find.byType(SingleChildScrollView).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('buttons meet minimum touch target height recommendations',
        (tester) async {
      _setDeviceSize(tester);

      await tester.pumpWidget(_buildTestApp(const LearningWelcomeScreen()));
      await tester.pumpAndSettle();

      final Size continueSize =
          tester.getSize(find.widgetWithText(ElevatedButton, 'Continue'));
      expect(continueSize.height, greaterThanOrEqualTo(48.0));

      final Size backSize =
          tester.getSize(find.widgetWithText(TextButton, 'Back'));
      expect(backSize.height, greaterThanOrEqualTo(44.0));
    });
  });
}
