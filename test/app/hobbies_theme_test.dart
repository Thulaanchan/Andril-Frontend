import 'dart:math' as math;

import 'package:andril_mobile/app/themes/hobbies/hobbies_colors.dart';
import 'package:andril_mobile/app/themes/hobbies/hobbies_theme.dart';
import 'package:andril_mobile/app/themes/hobbies/hobbies_typography.dart';
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
  group('HobbiesTheme Material 3 Configuration & Brightness', () {
    late ThemeData theme;

    setUp(() {
      theme = HobbiesTheme.lightTheme;
    });

    test('1. initializes with Material 3 enabled', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('2. configures light brightness', () {
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('3. configures correct approved scaffold background', () {
      expect(theme.scaffoldBackgroundColor, HobbiesColors.background);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFECFDF5));
    });

    test('4. configures correct primary branding', () {
      expect(theme.colorScheme.primary, HobbiesColors.primary);
      expect(theme.colorScheme.primary, const Color(0xFF16A34A));
    });
  });

  group('HobbiesTheme Typography Role Binding & Component Themes', () {
    late ThemeData theme;

    setUp(() {
      theme = HobbiesTheme.lightTheme;
    });

    test('5. binds typography hierarchy with accessible colors', () {
      expect(theme.textTheme.headlineMedium?.fontSize,
          HobbiesTypography.screenTitle.fontSize);
      expect(theme.textTheme.headlineMedium?.fontWeight,
          HobbiesTypography.screenTitle.fontWeight);
      expect(theme.textTheme.headlineMedium?.color, HobbiesTheme.textDark);

      expect(theme.textTheme.titleLarge?.fontSize,
          HobbiesTypography.sectionTitle.fontSize);
      expect(theme.textTheme.titleLarge?.color, HobbiesTheme.textDark);

      expect(theme.textTheme.bodyLarge?.fontSize,
          HobbiesTypography.bodyText.fontSize);
      expect(theme.textTheme.bodyLarge?.color, HobbiesTheme.textDark);

      expect(theme.textTheme.bodyMedium?.fontSize,
          HobbiesTypography.secondaryText.fontSize);
      expect(theme.textTheme.bodyMedium?.color, HobbiesTheme.textSecondary);

      expect(theme.textTheme.labelLarge?.fontSize,
          HobbiesTypography.buttonLabel.fontSize);
      expect(theme.textTheme.labelLarge?.color, HobbiesTheme.textDark);
    });

    test(
        '6. ensures accessible button foreground/background contrast across all interactive states (WCAG AA >= 4.5:1)',
        () {
      final buttonStyle = theme.elevatedButtonTheme.style;
      expect(buttonStyle, isNotNull);

      // A. Default Enabled State
      final Color? defaultBg = buttonStyle?.backgroundColor?.resolve({});
      final Color? defaultFg = buttonStyle?.foregroundColor?.resolve({});
      expect(defaultBg, HobbiesColors.primary);
      expect(defaultFg, HobbiesTheme.textDark);

      // Default state contrast: #0F2530 on #16A34A meets normal-text WCAG AA (>= 4.5:1)
      final double defaultRatio = _contrastRatio(defaultFg!, defaultBg!);
      expect(defaultRatio, greaterThanOrEqualTo(4.5));
      expect(defaultRatio, closeTo(4.80, 0.05));

      // Confirm white on #16A34A would fail normal-text AA (~3.30:1 < 4.5:1)
      final double whiteOnPrimary =
          _contrastRatio(Colors.white, HobbiesColors.primary);
      expect(whiteOnPrimary, lessThan(4.5));

      // B. Hovered State
      const Set<WidgetState> hoveredStates = {WidgetState.hovered};
      final Color? hoveredBg =
          buttonStyle?.backgroundColor?.resolve(hoveredStates);
      final Color? hoveredFg =
          buttonStyle?.foregroundColor?.resolve(hoveredStates);
      expect(hoveredBg, const Color(0xFF15803D));
      expect(hoveredFg, Colors.white);

      // Hovered state contrast: Colors.white on #15803D meets WCAG AA (>= 4.5:1)
      final double hoveredRatio = _contrastRatio(hoveredFg!, hoveredBg!);
      expect(hoveredRatio, greaterThanOrEqualTo(4.5));
      expect(hoveredRatio, closeTo(5.02, 0.05));

      // Confirm dark text #0F2530 on darker green #15803D would fail AA (~3.15:1 < 4.5:1)
      final double darkOnHovered =
          _contrastRatio(HobbiesTheme.textDark, hoveredBg);
      expect(darkOnHovered, lessThan(4.5));

      // C. Focused State
      const Set<WidgetState> focusedStates = {WidgetState.focused};
      final Color? focusedBg =
          buttonStyle?.backgroundColor?.resolve(focusedStates);
      final Color? focusedFg =
          buttonStyle?.foregroundColor?.resolve(focusedStates);
      expect(focusedBg, const Color(0xFF15803D));
      expect(focusedFg, Colors.white);

      // Focused state contrast: Colors.white on #15803D meets WCAG AA (>= 4.5:1)
      final double focusedRatio = _contrastRatio(focusedFg!, focusedBg!);
      expect(focusedRatio, greaterThanOrEqualTo(4.5));
      expect(focusedRatio, closeTo(5.02, 0.05));

      // D. Simultaneously Hovered and Focused State
      const Set<WidgetState> hoveredFocusedStates = {
        WidgetState.hovered,
        WidgetState.focused,
      };
      final Color? hfBg =
          buttonStyle?.backgroundColor?.resolve(hoveredFocusedStates);
      final Color? hfFg =
          buttonStyle?.foregroundColor?.resolve(hoveredFocusedStates);
      expect(hfBg, const Color(0xFF15803D));
      expect(hfFg, Colors.white);
      final double hfRatio = _contrastRatio(hfFg!, hfBg!);
      expect(hfRatio, greaterThanOrEqualTo(4.5));
      expect(hfRatio, closeTo(5.02, 0.05));

      // E. Disabled State
      const Set<WidgetState> disabledStates = {WidgetState.disabled};
      final Color? disabledBg =
          buttonStyle?.backgroundColor?.resolve(disabledStates);
      final Color? disabledFg =
          buttonStyle?.foregroundColor?.resolve(disabledStates);
      expect(disabledBg, const Color(0xFFE2E8F0));
      expect(disabledFg, const Color(0xFF94A3B8));
    });

    test('7. configures AppBarTheme to match background canvas', () {
      expect(theme.appBarTheme.backgroundColor, HobbiesColors.background);
      expect(theme.appBarTheme.foregroundColor, HobbiesTheme.textDark);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
      expect(theme.appBarTheme.titleTextStyle?.color, HobbiesTheme.textDark);
      expect(theme.appBarTheme.titleTextStyle?.fontSize, 22.0);
    });

    test('8. configures CardThemeData with rounded border and zero elevation',
        () {
      expect(theme.cardTheme.color, HobbiesTheme.cardSurface);
      expect(theme.cardTheme.color, const Color(0xFFFFFFFF));
      expect(theme.cardTheme.elevation, 0);
      expect(
        theme.cardTheme.shape,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
      expect(theme.cardTheme.margin, EdgeInsets.zero);
    });
  });

  group('HobbiesTheme Regression Guards & Module Isolation', () {
    test('9. existing HobbiesColors constants remain unmodified', () {
      expect(HobbiesColors.primary, const Color(0xFF16A34A));
      expect(HobbiesColors.background, const Color(0xFFECFDF5));
    });

    test('10. existing HobbiesTypography behavior remains intact', () {
      expect(HobbiesTypography.screenTitle.fontSize, 22.0);
      expect(HobbiesTypography.sectionTitle.fontSize, 18.0);
      expect(HobbiesTypography.bodyText.fontSize, 15.0);
      expect(HobbiesTypography.secondaryText.fontSize, 14.0);
      expect(HobbiesTypography.buttonLabel.fontSize, 14.0);
      expect(HobbiesTypography.caption.fontSize, 12.0);
    });

    testWidgets('11. theme can be applied to a MaterialApp without exceptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: HobbiesTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Hobbies Test')),
            body: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Card Content'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Action Button'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hobbies Test'), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
      expect(find.text('Action Button'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('12. ensures no Learning, Dating or Shared Core theme leakage', () {
      final theme = HobbiesTheme.lightTheme;

      // Ensure no Learning module primary (#2563EB), heading (#090D2B), or wave (#A78BFA)
      const Color learningPrimary = Color(0xFF2563EB);
      const Color learningHeading = Color(0xFF090D2B);
      const Color learningWave = Color(0xFFA78BFA);

      expect(theme.colorScheme.primary, isNot(learningPrimary));
      expect(theme.scaffoldBackgroundColor, isNot(const Color(0xFFEEF2FF)));
      expect(theme.colorScheme.onSurface, isNot(learningHeading));
      expect(theme.textTheme.headlineMedium?.color, isNot(learningWave));

      // Ensure no Dating or Shared Core primary (#006D77) leakage into primary brand role
      const Color sharedCorePrimary = Color(0xFF006D77);
      expect(theme.colorScheme.primary, isNot(sharedCorePrimary));
    });
  });
}
