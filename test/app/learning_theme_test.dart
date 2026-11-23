import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';

/// Calculates the WCAG 2.1 relative luminance of a [Color].
///
/// Follows W3C formula: https://www.w3.org/WAI/GL/wiki/Relative_luminance
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
///
/// Returns a value between 1.0 and 21.0.
double _contrastRatio(Color c1, Color c2) {
  final double lum1 = _relativeLuminance(c1);
  final double lum2 = _relativeLuminance(c2);
  final double lighter = math.max(lum1, lum2);
  final double darker = math.min(lum1, lum2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('LearningColors tokens', () {
    test('declares all six exact colour values', () {
      expect(LearningColors.primary, const Color(0xFF2563EB));
      expect(LearningColors.background, const Color(0xFFEEF2FF));
      expect(LearningColors.cardSurface, const Color(0xFFFFFFFF));
      expect(LearningColors.heading, const Color(0xFF090D2B));
      expect(LearningColors.secondaryText, const Color(0xFF475569));
      expect(LearningColors.waveAccent, const Color(0xFFA78BFA));
    });
  });

  group('WCAG AA Contrast Ratio Requirements', () {
    test('heading on background canvas meets WCAG AA (>= 4.5:1)', () {
      final double ratio = _contrastRatio(
        LearningColors.heading,
        LearningColors.background,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('heading on card surface meets WCAG AA (>= 4.5:1)', () {
      final double ratio = _contrastRatio(
        LearningColors.heading,
        LearningColors.cardSurface,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('secondary text on background canvas meets WCAG AA (>= 4.5:1)', () {
      final double ratio = _contrastRatio(
        LearningColors.secondaryText,
        LearningColors.background,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('secondary text on card surface meets WCAG AA (>= 4.5:1)', () {
      final double ratio = _contrastRatio(
        LearningColors.secondaryText,
        LearningColors.cardSurface,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('white foreground on primary button meets WCAG AA (>= 4.5:1)', () {
      final double ratio = _contrastRatio(Colors.white, LearningColors.primary);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('LearningTheme Material 3 configuration', () {
    late ThemeData theme;

    setUp(() {
      theme = LearningTheme.theme;
    });

    test('initializes with Material 3 enabled', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('configures scaffold background and card surface', () {
      expect(theme.scaffoldBackgroundColor, LearningColors.background);
      expect(theme.cardTheme.color, LearningColors.cardSurface);
      expect(theme.cardTheme.elevation, 0);
      expect(
        theme.cardTheme.shape,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
    });

    test('configures primary colorScheme correctly', () {
      expect(theme.colorScheme.primary, LearningColors.primary);
      expect(theme.colorScheme.onPrimary, Colors.white);
      expect(theme.colorScheme.surface, LearningColors.cardSurface);
      expect(theme.colorScheme.onSurface, LearningColors.heading);
    });

    test('configures AppBarTheme to match background canvas', () {
      expect(theme.appBarTheme.backgroundColor, LearningColors.background);
      expect(theme.appBarTheme.foregroundColor, LearningColors.heading);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.titleTextStyle?.color, LearningColors.heading);
      expect(theme.appBarTheme.titleTextStyle?.fontWeight, FontWeight.bold);
    });

    test(
      'preserves typography hierarchy and applies Learning text colours',
      () {
        expect(theme.textTheme.headlineLarge?.color, LearningColors.heading);
        expect(theme.textTheme.headlineLarge?.fontWeight, FontWeight.bold);
        expect(theme.textTheme.titleLarge?.color, LearningColors.heading);
        expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w600);
        expect(theme.textTheme.bodyMedium?.color, LearningColors.secondaryText);
        expect(theme.textTheme.bodyLarge?.color, LearningColors.secondaryText);
      },
    );

    test('elevated button avoids globally forced infinite width', () {
      final buttonStyle = theme.elevatedButtonTheme.style;
      expect(buttonStyle, isNotNull);
      final Size? minSize = buttonStyle?.minimumSize?.resolve({});
      expect(minSize?.width, isNot(double.infinity));
      expect(minSize?.height, 48);
    });

    test('elevated button verifies enabled, disabled and focused states', () {
      final buttonStyle = theme.elevatedButtonTheme.style;
      expect(buttonStyle, isNotNull);

      // Enabled state
      expect(buttonStyle?.backgroundColor?.resolve({}), LearningColors.primary);
      expect(buttonStyle?.foregroundColor?.resolve({}), Colors.white);
      expect(buttonStyle?.elevation?.resolve({}), 0.0);

      // Disabled state
      expect(
        buttonStyle?.backgroundColor?.resolve({WidgetState.disabled}),
        const Color(0xFFE2E8F0),
      );
      expect(
        buttonStyle?.foregroundColor?.resolve({WidgetState.disabled}),
        const Color(0xFF94A3B8),
      );

      // Focused state
      expect(
        buttonStyle?.backgroundColor?.resolve({WidgetState.focused}),
        const Color(0xFF1D4ED8),
      );
      expect(buttonStyle?.elevation?.resolve({WidgetState.focused}), 2.0);
    });

    test('outlined button verifies enabled, disabled and focused states', () {
      final buttonStyle = theme.outlinedButtonTheme.style;
      expect(buttonStyle, isNotNull);

      // Enabled state
      expect(buttonStyle?.foregroundColor?.resolve({}), LearningColors.primary);
      expect(buttonStyle?.side?.resolve({})?.color, LearningColors.primary);

      // Disabled state
      expect(
        buttonStyle?.foregroundColor?.resolve({WidgetState.disabled}),
        const Color(0xFF94A3B8),
      );
      expect(
        buttonStyle?.side?.resolve({WidgetState.disabled})?.color,
        const Color(0xFFE2E8F0),
      );

      // Focused state
      expect(
        buttonStyle?.side?.resolve({WidgetState.focused})?.color,
        const Color(0xFF1D4ED8),
      );
    });

    test('text button verifies enabled, disabled and focused states', () {
      final buttonStyle = theme.textButtonTheme.style;
      expect(buttonStyle, isNotNull);

      // Enabled state
      expect(buttonStyle?.foregroundColor?.resolve({}), LearningColors.primary);

      // Disabled state
      expect(
        buttonStyle?.foregroundColor?.resolve({WidgetState.disabled}),
        const Color(0xFF94A3B8),
      );

      // Focused state
      expect(
        buttonStyle?.foregroundColor?.resolve({WidgetState.focused}),
        const Color(0xFF1D4ED8),
      );
    });

    test('input decoration theme applies clean border radius and colours', () {
      final inputTheme = theme.inputDecorationTheme;
      expect(inputTheme.filled, isTrue);
      expect(inputTheme.fillColor, LearningColors.cardSurface);
      expect(inputTheme.hintStyle?.color, LearningColors.secondaryText);
      expect(inputTheme.border, isA<OutlineInputBorder>());
    });

    test('progress indicator uses learning primary colour', () {
      expect(theme.progressIndicatorTheme.color, LearningColors.primary);
      expect(
        theme.progressIndicatorTheme.linearTrackColor,
        const Color(0xFFDBEAFE),
      );
    });

    test('navigation bar theme configures selected and unselected states', () {
      final navTheme = theme.navigationBarTheme;
      expect(navTheme.backgroundColor, LearningColors.cardSurface);
      expect(navTheme.indicatorColor, const Color(0xFFDBEAFE));

      final selectedLabelStyle = navTheme.labelTextStyle?.resolve({
        WidgetState.selected,
      });
      expect(selectedLabelStyle?.color, LearningColors.primary);

      final unselectedLabelStyle = navTheme.labelTextStyle?.resolve({});
      expect(unselectedLabelStyle?.color, LearningColors.secondaryText);

      final selectedIcon = navTheme.iconTheme?.resolve({WidgetState.selected});
      expect(selectedIcon?.color, LearningColors.primary);

      final unselectedIcon = navTheme.iconTheme?.resolve({});
      expect(unselectedIcon?.color, LearningColors.secondaryText);
    });
  });
}
