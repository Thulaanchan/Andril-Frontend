import 'dart:math' as math;

import 'package:andril_mobile/app/themes/hobbies/hobbies_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Calculates the WCAG 2.1 relative luminance of a [Color].
///
/// Follows the W3C definition: https://www.w3.org/WAI/GL/wiki/Relative_luminance
double relativeLuminance(Color color) {
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

/// Calculates the WCAG 2.1 contrast ratio between two [Color] instances.
///
/// Returns a value between 1.0 and 21.0.
double contrastRatio(Color c1, Color c2) {
  final double lum1 = relativeLuminance(c1);
  final double lum2 = relativeLuminance(c2);
  final double lighter = math.max(lum1, lum2);
  final double darker = math.min(lum1, lum2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('HobbiesColors token declarations', () {
    test('declares exact approved primary and background colour values', () {
      expect(HobbiesColors.primary, const Color(0xFF16A34A));
      expect(HobbiesColors.background, const Color(0xFFECFDF5));
    });

    test('color constants are compile-time constants', () {
      const primaryConstant = HobbiesColors.primary;
      const backgroundConstant = HobbiesColors.background;
      expect(identical(primaryConstant, const Color(0xFF16A34A)), isTrue);
      expect(identical(backgroundConstant, const Color(0xFFECFDF5)), isTrue);
    });
  });

  group('WCAG 2.1 Contrast Calculations and Accessibility Requirements', () {
    test(
      'WCAG contrast helper correctly implements sRGB linearization and relative luminance',
      () {
        // Pure black relative luminance is exactly 0.0
        expect(
          relativeLuminance(const Color(0xFF000000)),
          closeTo(0.0, 0.0001),
        );
        // Pure white relative luminance is exactly 1.0
        expect(
          relativeLuminance(const Color(0xFFFFFFFF)),
          closeTo(1.0, 0.0001),
        );
        // Contrast ratio between white and black is exactly 21:1
        expect(
          contrastRatio(const Color(0xFFFFFFFF), const Color(0xFF000000)),
          closeTo(21.0, 0.001),
        );
        // Contrast ratio between identical colors is exactly 1:1
        expect(
          contrastRatio(HobbiesColors.primary, HobbiesColors.primary),
          closeTo(1.0, 0.001),
        );
      },
    );

    test(
      'white text on primary green does not meet normal-text WCAG AA (ratio < 4.5:1)',
      () {
        final double ratio = contrastRatio(Colors.white, HobbiesColors.primary);
        // Approximately 3.30:1 — fails normal-text AA (4.5:1), passes large-text (3.0:1)
        expect(ratio, lessThan(4.5));
        expect(ratio, greaterThanOrEqualTo(3.0));
      },
    );

    test(
      'dark reference text #0F2530 on primary green meets normal-text WCAG AA (ratio >= 4.5:1)',
      () {
        const darkReferenceText = Color(0xFF0F2530);
        final double ratio = contrastRatio(
          darkReferenceText,
          HobbiesColors.primary,
        );
        // Approximately 4.80:1 — meets normal-text AA threshold
        expect(ratio, greaterThanOrEqualTo(4.5));
      },
    );
  });
}
