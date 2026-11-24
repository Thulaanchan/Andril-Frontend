import 'dart:math' as math;

import 'package:andril_mobile/app/themes/hobbies/hobbies_colors.dart';
import 'package:andril_mobile/app/themes/hobbies/hobbies_theme.dart';
import 'package:andril_mobile/app/themes/hobbies/painters/teal_wave_painter.dart';
import 'package:andril_mobile/features/hobbies/presentation/widgets/andril_hobbies_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Calculates the WCAG 2.1 relative luminance of a [Color].
double _relativeLuminance(Color color) {
  double channelLuminance(int channelValue) {
    final double sRGB = channelValue / 255.0;
    return sRGB <= 0.04045
        ? sRGB / 12.92
        : math.pow((sRGB + 0.055) / 1.055, 2.4).toDouble();
  }

  final double r = channelLuminance((color.r * 255).round());
  final double g = channelLuminance((color.g * 255).round());
  final double b = channelLuminance((color.b * 255).round());

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Calculates the contrast ratio between two [Color] instances.
double _contrastRatio(Color c1, Color c2) {
  final double lum1 = _relativeLuminance(c1);
  final double lum2 = _relativeLuminance(c2);
  final double lighter = math.max(lum1, lum2);
  final double darker = math.min(lum1, lum2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AndrilHobbiesScaffold Rendering & Structure', () {
    testWidgets('1. AndrilHobbiesScaffold builds successfully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            body: Text('Hobbies Body Content'),
          ),
        ),
      );

      expect(find.byType(AndrilHobbiesScaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. caller-provided body is rendered',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            body: Center(child: Text('Custom Body Identifier')),
          ),
        ),
      );

      expect(find.text('Custom Body Identifier'), findsOneWidget);
    });

    testWidgets('3. correct Hobbies background is applied',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            body: SizedBox.expand(),
          ),
        ),
      );

      final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, HobbiesColors.background);
      expect(scaffold.backgroundColor, const Color(0xFFECFDF5));
    });

    testWidgets(
        '4. Hobbies-specific ThemeData is available within the scaffold',
        (WidgetTester tester) async {
      late ThemeData capturedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: AndrilHobbiesScaffold(
            body: Builder(
              builder: (BuildContext context) {
                capturedTheme = Theme.of(context);
                return const Text('Theme Inspector');
              },
            ),
          ),
        ),
      );

      expect(capturedTheme.useMaterial3, isTrue);
      expect(capturedTheme.colorScheme.primary, HobbiesColors.primary);
      expect(capturedTheme.scaffoldBackgroundColor, HobbiesColors.background);
      expect(capturedTheme.brightness, Brightness.light);
    });
  });

  group('AndrilHobbiesScaffold Header Contrast & Predictable Surface', () {
    testWidgets(
        '5. AppBar title and icon contrast with wave enabled meets WCAG AAA (>= 7.0:1)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            title: 'Hobbies Dashboard',
            showWave: true,
            actions: [
              Icon(Icons.search, key: Key('app_bar_icon')),
            ],
            body: SizedBox(),
          ),
        ),
      );

      final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
      final Color surfaceColor =
          appBar.backgroundColor ?? HobbiesColors.background;
      expect(surfaceColor, HobbiesColors.background);

      final Text titleText =
          tester.widget<Text>(find.text('Hobbies Dashboard'));
      final Color titleColor = titleText.style?.color ?? HobbiesTheme.textDark;
      expect(titleColor, HobbiesTheme.textDark);

      // Contrast of title on predictable AppBar surface meets WCAG AAA
      final double contrast = _contrastRatio(titleColor, surfaceColor);
      expect(contrast, greaterThanOrEqualTo(7.0));
      expect(contrast, greaterThanOrEqualTo(14.0));
    });

    testWidgets('6. AppBar contrast with wave disabled meets WCAG AAA',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            title: 'Plain Header',
            showWave: false,
            body: SizedBox(),
          ),
        ),
      );

      final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
      final Color surfaceColor =
          appBar.backgroundColor ?? HobbiesColors.background;
      expect(surfaceColor, HobbiesColors.background);

      final Text titleText = tester.widget<Text>(find.text('Plain Header'));
      final Color titleColor = titleText.style?.color ?? HobbiesTheme.textDark;

      final double contrast = _contrastRatio(titleColor, surfaceColor);
      expect(contrast, greaterThanOrEqualTo(7.0));
    });

    testWidgets('7. AppBar actions are rendered and interactive',
        (WidgetTester tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AndrilHobbiesScaffold(
            title: 'Hobbies with Actions',
            actions: [
              IconButton(
                key: const Key('search_action_btn'),
                icon: const Icon(Icons.search),
                onPressed: () => actionTapped = true,
              ),
            ],
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.byKey(const Key('search_action_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('search_action_btn')));
      await tester.pump();
      expect(actionTapped, isTrue);
    });
  });

  group('AndrilHobbiesScaffold Body Geometry & SafeArea Protection', () {
    testWidgets(
        '8. body starts strictly below AppBar with zero overlap when AppBar is supplied',
        (WidgetTester tester) async {
      const double simulatedTopPadding = 44.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(top: simulatedTopPadding),
            ),
            child: AndrilHobbiesScaffold(
              title: 'Geometry Test',
              showWave: true,
              body: Container(
                key: const Key('top_body_container'),
                height: 100,
                color: Colors.amber,
              ),
            ),
          ),
        ),
      );

      final Rect appBarRect = tester.getRect(find.byType(AppBar));
      final Rect bodyRect =
          tester.getRect(find.byKey(const Key('top_body_container')));

      // Body top must be exactly at or below the bottom of the AppBar (zero vertical collision)
      expect(bodyRect.top, greaterThanOrEqualTo(appBarRect.bottom));
      expect(appBarRect.bottom, simulatedTopPadding + kToolbarHeight);
      expect(bodyRect.top, simulatedTopPadding + kToolbarHeight);
    });

    testWidgets(
        '9. body respects status-bar safe-area when no AppBar is supplied',
        (WidgetTester tester) async {
      const double simulatedTopPadding = 44.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(top: simulatedTopPadding),
            ),
            child: AndrilHobbiesScaffold(
              showWave: true,
              body: Container(
                key: const Key('top_no_appbar_container'),
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      final Rect bodyRect =
          tester.getRect(find.byKey(const Key('top_no_appbar_container')));

      // Body top must be positioned at or below the simulated status-bar inset
      expect(bodyRect.top, greaterThanOrEqualTo(simulatedTopPadding));
    });
  });

  group('AndrilHobbiesScaffold Wave Integration & Interactivity', () {
    testWidgets('10. wave painter is present when showWave == true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            showWave: true,
            body: SizedBox(),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget w) => w is CustomPaint && w.painter is TealWavePainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets('11. wave painter is absent when showWave == false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            showWave: false,
            body: SizedBox(),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget w) => w is CustomPaint && w.painter is TealWavePainter,
        ),
        findsNothing,
      );
    });

    testWidgets('12. decorative wave does not intercept interactive taps',
        (WidgetTester tester) async {
      bool buttonTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AndrilHobbiesScaffold(
            showWave: true,
            body: Align(
              alignment: Alignment.topCenter,
              child: ElevatedButton(
                key: const Key('tap_target_button'),
                onPressed: () => buttonTapped = true,
                child: const Text('Interactive Button'),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('tap_target_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('tap_target_button')));
      await tester.pump();
      expect(buttonTapped, isTrue);
    });
  });

  group('AndrilHobbiesScaffold Responsive Layouts & Text Scaling', () {
    testWidgets('13. screen renders at a compact mobile width (320 x 568)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            title: 'Compact Screen',
            body: Column(
              children: [
                Text('Compact content row 1'),
                Text('Compact content row 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Compact Screen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. screen renders at a standard mobile width (390 x 844)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            title: 'Standard Mobile',
            body: Center(child: Text('Standard Mobile Body')),
          ),
        ),
      );

      expect(find.text('Standard Mobile'), findsOneWidget);
      expect(find.text('Standard Mobile Body'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '15. text scaling does not produce layout exceptions with realistic insets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              padding: EdgeInsets.only(top: 44.0),
              textScaler: TextScaler.linear(2.0),
            ),
            child: AndrilHobbiesScaffold(
              title: 'Scaled Header',
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                        'Scaled body text paragraph that tests dynamic font sizing.'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Scaled Header'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group(
      'AndrilHobbiesScaffold Content Placeholders, API Compatibility & Isolation',
      () {
    testWidgets(
        '16. caller-provided empty/loading/error placeholders render without scaffold exceptions',
        (WidgetTester tester) async {
      // Loading State
      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            title: 'Loading',
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Empty State
      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            title: 'Empty State',
            body: Center(child: Text('No hobbies discovered yet')),
          ),
        ),
      );
      expect(find.text('No hobbies discovered yet'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Error State
      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            title: 'Error State',
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline),
                  Text('Failed to load content'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Failed to load content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('17. existing public constructor compatibility is preserved', () {
      const scaffold = AndrilHobbiesScaffold(
        body: SizedBox(),
        title: 'Title',
        showWave: true,
        actions: [],
        waveHeight: 220.0,
      );
      expect(scaffold.title, 'Title');
      expect(scaffold.showWave, isTrue);
      expect(scaffold.waveHeight, 220.0);
    });

    test('18. existing approved colors remain unchanged', () {
      expect(HobbiesColors.primary, const Color(0xFF16A34A));
      expect(HobbiesColors.background, const Color(0xFFECFDF5));
    });

    test('19. no foreign module dependencies are introduced', () {
      final ThemeData scaffoldTheme = HobbiesTheme.lightTheme;
      const Color learningPrimary = Color(0xFF2563EB);
      const Color sharedCorePrimary = Color(0xFF006D77);

      expect(scaffoldTheme.colorScheme.primary, isNot(learningPrimary));
      expect(scaffoldTheme.colorScheme.primary, isNot(sharedCorePrimary));
      expect(scaffoldTheme.colorScheme.primary, HobbiesColors.primary);
    });
  });
}
