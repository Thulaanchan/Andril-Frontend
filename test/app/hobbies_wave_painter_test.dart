import 'package:andril_mobile/app/themes/hobbies/hobbies_colors.dart';
import 'package:andril_mobile/app/themes/hobbies/painters/teal_wave_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TealWavePainter Rendering inside CustomPaint', () {
    testWidgets(
        'renders successfully inside CustomPaint at standard mobile viewport (390 x 220)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: Size(390, 220),
              painter: TealWavePainter(),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders successfully at compact size (100 x 50)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: Size(100, 50),
              painter: TealWavePainter(waveHeight: 50.0),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders successfully at large viewport (800 x 600)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: Size(800, 600),
              painter: TealWavePainter(waveHeight: 300.0),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles compact mode (isCompact: true) cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: Size(390, 165),
              painter: TealWavePainter(isCompact: true),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles light-wave mode (isLightWave: true) cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: Size(390, 220),
              painter: TealWavePainter(isLightWave: true),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'safely handles zero-sized and edge-case canvases without exceptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CustomPaint(
                  size: Size.zero,
                  painter: TealWavePainter(),
                ),
                CustomPaint(
                  size: Size(390, 0),
                  painter: TealWavePainter(waveHeight: 0),
                ),
                CustomPaint(
                  size: Size(0, 220),
                  painter: TealWavePainter(),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('TealWavePainter Repaint Behavior (shouldRepaint)', () {
    test('identical constructor properties return shouldRepaint == false', () {
      const TealWavePainter painter1 = TealWavePainter();
      const TealWavePainter painter2 = TealWavePainter();

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('changing waveHeight triggers repaint', () {
      const TealWavePainter painter1 = TealWavePainter(waveHeight: 220.0);
      const TealWavePainter painter2 = TealWavePainter(waveHeight: 260.0);

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('changing startColor triggers repaint', () {
      const TealWavePainter painter1 =
          TealWavePainter(startColor: Color(0xFF01999A));
      const TealWavePainter painter2 =
          TealWavePainter(startColor: Color(0xFF16A34A));

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('changing endColor triggers repaint', () {
      const TealWavePainter painter1 =
          TealWavePainter(endColor: Color(0xFF006D77));
      const TealWavePainter painter2 =
          TealWavePainter(endColor: Color(0xFF064E3B));

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('changing isCompact triggers repaint', () {
      const TealWavePainter painter1 = TealWavePainter(isCompact: false);
      const TealWavePainter painter2 = TealWavePainter(isCompact: true);

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('changing isLightWave triggers repaint', () {
      const TealWavePainter painter1 = TealWavePainter(isLightWave: false);
      const TealWavePainter painter2 = TealWavePainter(isLightWave: true);

      expect(painter1.shouldRepaint(painter2), isTrue);
    });
  });

  group('TealWavePainter Branding and Module Isolation', () {
    test(
        'approved Hobbies brand tokens remain unmodified (#16A34A and #ECFDF5)',
        () {
      expect(HobbiesColors.primary, const Color(0xFF16A34A));
      expect(HobbiesColors.background, const Color(0xFFECFDF5));
    });

    testWidgets(
        'allows injecting custom colors such as approved HobbiesColors.primary',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: Size(390, 220),
              painter: TealWavePainter(
                startColor: HobbiesColors.primary,
                endColor: Color(0xFF064E3B),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    test(
        'maintains isolated decorative default colors without foreign module dependencies',
        () {
      expect(TealWavePainter.defaultStartColor, const Color(0xFF01999A));
      expect(TealWavePainter.defaultEndColor, const Color(0xFF006D77));
      expect(TealWavePainter.defaultLightWaveStart, const Color(0xFFBDF5F2));
      expect(TealWavePainter.defaultLightWaveEnd, const Color(0xFFD9FBF5));
    });
  });
}
