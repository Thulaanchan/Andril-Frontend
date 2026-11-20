import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/profile/widgets/welcome_wave_divider.dart';
import 'package:andril_mobile/features/learning/profile/widgets/welcome_feature_card.dart';
import 'package:andril_mobile/features/learning/profile/widgets/welcome_page_indicator.dart';

Widget _buildTestApp(Widget child, {TextScaler? textScaler, Size? size}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: size?.width ?? 360,
          height: size?.height ?? 640,
          child: MediaQuery(
            data: MediaQueryData(
              size: size ?? const Size(360, 640),
              textScaler: textScaler ?? TextScaler.noScaling,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('WelcomeWaveDivider Widget', () {
    testWidgets('renders successfully with default height', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WelcomeWaveDivider(),
            ],
          ),
        ),
      );

      expect(find.byType(WelcomeWaveDivider), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(WelcomeWaveDivider),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      final Size size = tester.getSize(find.byType(WelcomeWaveDivider));
      expect(size.height, WelcomeWaveDivider.defaultHeight);
    });

    testWidgets('supports various viewport widths without layout overflow',
        (tester) async {
      final List<double> widths = [300.0, 360.0, 412.0, 600.0];

      for (final width in widths) {
        await tester.pumpWidget(
          _buildTestApp(
            const WelcomeWaveDivider(height: 48),
            size: Size(width, 48),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(WelcomeWaveDivider), findsOneWidget);
      }
    });
  });

  group('WelcomeFeatureCard Widget', () {
    testWidgets(
        'renders Variant 01 (Share & Learn Skills) with exact text and labels',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const WelcomeFeatureCard(
              variant: WelcomeFeatureVariant.shareAndLearn),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share & Learn Skills'), findsOneWidget);
      expect(
        find.text('Teach what you know and learn what you need.'),
        findsOneWidget,
      );
      expect(find.text('Teach'), findsOneWidget);
      expect(find.text('UI Design'), findsOneWidget);
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Data Analytics'), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'renders Variant 02 (Join Learning Circles) with overlapping portraits',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const WelcomeFeatureCard(
              variant: WelcomeFeatureVariant.learningCircles),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Join Learning Circles'), findsOneWidget);
      expect(
        find.text('Study with people who share your goals.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.groups_rounded), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'renders Variant 03 (Track Your Growth) with CV, Portfolio, and Progress labels',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const WelcomeFeatureCard(variant: WelcomeFeatureVariant.trackGrowth),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Track Your Growth'), findsOneWidget);
      expect(
        find.text('Build your CV, portfolio, and learning progress.'),
        findsOneWidget,
      );
      expect(find.text('CV'), findsOneWidget);
      expect(find.text('Portfolio'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.insights_rounded), findsOneWidget);
      // Assert that completion checkmarks are NOT present
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'supports narrow layouts and increased text scaling without overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const SingleChildScrollView(
            child: Column(
              children: [
                WelcomeFeatureCard(
                    variant: WelcomeFeatureVariant.shareAndLearn),
                SizedBox(height: 12),
                WelcomeFeatureCard(
                    variant: WelcomeFeatureVariant.learningCircles),
                SizedBox(height: 12),
                WelcomeFeatureCard(variant: WelcomeFeatureVariant.trackGrowth),
              ],
            ),
          ),
          size: const Size(280, 800),
          textScaler: const TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('WelcomePageIndicator Widget', () {
    testWidgets('renders exactly three indicators with correct active styling',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const WelcomePageIndicator(activeIndex: 0),
        ),
      );

      final indicators = find.byType(AnimatedContainer);
      expect(indicators, findsNWidgets(3));

      // Inspect first indicator decoration
      final AnimatedContainer first = tester.widget(indicators.at(0));
      final BoxDecoration firstDecoration = first.decoration as BoxDecoration;
      expect(firstDecoration.color, WelcomePageIndicator.activeColor);

      // Inspect second indicator decoration
      final AnimatedContainer second = tester.widget(indicators.at(1));
      final BoxDecoration secondDecoration = second.decoration as BoxDecoration;
      expect(secondDecoration.color, WelcomePageIndicator.inactiveColor);
    });

    testWidgets('invokes callback when indicator is tapped', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        _buildTestApp(
          WelcomePageIndicator(
            activeIndex: 1,
            onIndicatorTapped: (index) {
              tappedIndex = index;
            },
          ),
        ),
      );

      final indicators = find.byType(InkResponse);
      expect(indicators, findsNWidgets(3));

      await tester.tap(indicators.at(0));
      await tester.pump();
      expect(tappedIndex, 0);

      await tester.tap(indicators.at(2));
      await tester.pump();
      expect(tappedIndex, 2);
    });

    testWidgets(
        'provides minimum 48x48 dp touch targets while keeping 8 dp visible dot',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          WelcomePageIndicator(
            activeIndex: 0,
            onIndicatorTapped: (_) {},
          ),
        ),
      );

      final inkResponse = find.byType(InkResponse).first;
      final Size touchSize = tester.getSize(inkResponse);
      expect(touchSize.width >= 48.0, isTrue);
      expect(touchSize.height >= 48.0, isTrue);

      final animatedContainer = find.byType(AnimatedContainer).first;
      final Size dotSize = tester.getSize(animatedContainer);
      expect(dotSize.width, 8.0);
      expect(dotSize.height, 8.0);
    });

    testWidgets('safely handles out-of-range active indices', (tester) async {
      // Test negative index
      await tester.pumpWidget(
        _buildTestApp(const WelcomePageIndicator(activeIndex: -5)),
      );
      expect(tester.takeException(), isNull);
      final AnimatedContainer clampedFirst =
          tester.widget(find.byType(AnimatedContainer).at(0));
      expect(
        (clampedFirst.decoration as BoxDecoration).color,
        WelcomePageIndicator.activeColor,
      );

      // Test overflow index
      await tester.pumpWidget(
        _buildTestApp(const WelcomePageIndicator(activeIndex: 99)),
      );
      expect(tester.takeException(), isNull);
      final AnimatedContainer clampedLast =
          tester.widget(find.byType(AnimatedContainer).at(2));
      expect(
        (clampedLast.decoration as BoxDecoration).color,
        WelcomePageIndicator.activeColor,
      );
    });

    testWidgets('provides accessible semantic labels for indicators',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          WelcomePageIndicator(
            activeIndex: 1,
            onIndicatorTapped: (_) {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 2 of 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 3 of 3'), findsOneWidget);
    });
  });
}
