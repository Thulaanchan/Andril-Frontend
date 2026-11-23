import 'package:andril_mobile/app/themes/hobbies/hobbies_colors.dart';
import 'package:andril_mobile/app/themes/hobbies/hobbies_theme.dart';
import 'package:andril_mobile/app/themes/hobbies/painters/teal_wave_painter.dart';
import 'package:andril_mobile/features/hobbies/presentation/widgets/andril_hobbies_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('AndrilHobbiesScaffold Header, Title & Actions', () {
    testWidgets('5. AppBar title is displayed when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AndrilHobbiesScaffold(
            title: 'Hobbies Dashboard',
            body: SizedBox(),
          ),
        ),
      );

      expect(find.text('Hobbies Dashboard'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('6. AppBar actions are rendered when provided',
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

  group('AndrilHobbiesScaffold Wave Integration & Interactivity', () {
    testWidgets('7. wave painter is present when showWave == true',
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

    testWidgets('8. wave painter is absent when showWave == false',
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

    testWidgets('9. decorative wave does not intercept interactive taps',
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
    testWidgets('10. screen renders at a compact mobile width (320 x 568)',
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

    testWidgets('11. screen renders at a standard mobile width (390 x 844)',
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
        '12. text scaling does not produce layout exceptions in representative cases',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
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

  group('AndrilHobbiesScaffold Content Placeholders & Isolation', () {
    testWidgets(
        '13. caller-provided empty/loading/error placeholders render without scaffold exceptions',
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

    test('14. existing approved colors remain unchanged', () {
      expect(HobbiesColors.primary, const Color(0xFF16A34A));
      expect(HobbiesColors.background, const Color(0xFFECFDF5));
    });

    test('15. no foreign module dependencies are introduced', () {
      // Verify scaffold theme does not leak Learning, Dating or Shared Core colors
      final ThemeData scaffoldTheme = HobbiesTheme.lightTheme;
      const Color learningPrimary = Color(0xFF2563EB);
      const Color sharedCorePrimary = Color(0xFF006D77);

      expect(scaffoldTheme.colorScheme.primary, isNot(learningPrimary));
      expect(scaffoldTheme.colorScheme.primary, isNot(sharedCorePrimary));
      expect(scaffoldTheme.colorScheme.primary, HobbiesColors.primary);
    });
  });
}
