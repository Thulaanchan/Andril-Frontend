import 'dart:math' as math;

import 'package:andril_mobile/app/themes/hobbies/hobbies_colors.dart';
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

/// Calculates the WCAG 2.1 contrast ratio between two [Color] instances.
double _contrastRatio(Color c1, Color c2) {
  final double lum1 = _relativeLuminance(c1);
  final double lum2 = _relativeLuminance(c2);
  final double lighter = math.max(lum1, lum2);
  final double darker = math.min(lum1, lum2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('HobbiesTypography Token Declarations & Prototype Aliases', () {
    test(
        'declares all 6 essential Hobbies typography roles as compile-time constants',
        () {
      expect(HobbiesTypography.screenTitle.fontSize, 22.0);
      expect(HobbiesTypography.screenTitle.fontWeight, FontWeight.w700);

      expect(HobbiesTypography.sectionTitle.fontSize, 18.0);
      expect(HobbiesTypography.sectionTitle.fontWeight, FontWeight.w600);

      expect(HobbiesTypography.bodyText.fontSize, 15.0);
      expect(HobbiesTypography.bodyText.fontWeight, FontWeight.w400);

      expect(HobbiesTypography.secondaryText.fontSize, 14.0);
      expect(HobbiesTypography.secondaryText.fontWeight, FontWeight.w400);

      expect(HobbiesTypography.buttonLabel.fontSize, 14.0);
      expect(HobbiesTypography.buttonLabel.fontWeight, FontWeight.w600);

      expect(HobbiesTypography.caption.fontSize, 12.0);
      expect(HobbiesTypography.caption.fontWeight, FontWeight.w500);
    });

    test('maintains backward-compatible prototype aliases for existing code',
        () {
      expect(
          identical(
              HobbiesTypography.displayMedium, HobbiesTypography.screenTitle),
          isTrue);
      expect(
          identical(
              HobbiesTypography.titleLarge, HobbiesTypography.sectionTitle),
          isTrue);
      expect(identical(HobbiesTypography.bodyLarge, HobbiesTypography.bodyText),
          isTrue);
      expect(
          identical(
              HobbiesTypography.bodyMedium, HobbiesTypography.secondaryText),
          isTrue);
      expect(
          identical(
              HobbiesTypography.labelLarge, HobbiesTypography.buttonLabel),
          isTrue);
      expect(identical(HobbiesTypography.labelSmall, HobbiesTypography.caption),
          isTrue);
    });
  });

  group('Typography Hierarchy and Visual Sizing', () {
    test('text roles follow a consistent size hierarchy', () {
      expect(HobbiesTypography.screenTitle.fontSize!,
          greaterThan(HobbiesTypography.sectionTitle.fontSize!));
      expect(HobbiesTypography.sectionTitle.fontSize!,
          greaterThan(HobbiesTypography.bodyText.fontSize!));
      expect(HobbiesTypography.bodyText.fontSize!,
          greaterThan(HobbiesTypography.secondaryText.fontSize!));
      expect(HobbiesTypography.secondaryText.fontSize!,
          greaterThan(HobbiesTypography.caption.fontSize!));
      expect(HobbiesTypography.buttonLabel.fontSize, 14.0);
    });

    test('font weights enforce clear typographical emphasis', () {
      expect(
          HobbiesTypography.screenTitle.fontWeight!.value,
          greaterThanOrEqualTo(
              HobbiesTypography.sectionTitle.fontWeight!.value));
      expect(HobbiesTypography.sectionTitle.fontWeight!.value,
          greaterThan(HobbiesTypography.caption.fontWeight!.value));
      expect(HobbiesTypography.caption.fontWeight!.value,
          greaterThan(HobbiesTypography.bodyText.fontWeight!.value));
      expect(HobbiesTypography.bodyText.fontWeight,
          HobbiesTypography.secondaryText.fontWeight);
    });
  });

  group('Color Independence and Accessibility', () {
    test('base typography styles do not hardcode unrelated module colours', () {
      // Base styles must remain color-agnostic to prevent foreign module bleed (e.g. Learning blue #2563EB)
      expect(HobbiesTypography.screenTitle.color, isNull);
      expect(HobbiesTypography.sectionTitle.color, isNull);
      expect(HobbiesTypography.bodyText.color, isNull);
      expect(HobbiesTypography.secondaryText.color, isNull);
      expect(HobbiesTypography.buttonLabel.color, isNull);
      expect(HobbiesTypography.caption.color, isNull);
    });

    test(
        'createTextTheme defaults labelLarge to accessible dark text meeting WCAG AA on Hobbies green',
        () {
      final TextTheme theme = HobbiesTypography.createTextTheme();

      // 1. Default labelLarge uses accessible dark text #0F2530
      expect(theme.labelLarge!.color, const Color(0xFF0F2530));

      // 2. Dark text on approved Hobbies green (#16A34A) passes WCAG AA for normal text (>= 4.5:1)
      final double darkOnPrimary =
          _contrastRatio(theme.labelLarge!.color!, HobbiesColors.primary);
      expect(darkOnPrimary, greaterThanOrEqualTo(4.5));
    });

    test(
        'white text on Hobbies green fails normal-text WCAG AA but passes large-text threshold',
        () {
      // 3. White text on Hobbies green fails normal-text WCAG AA (< 4.5:1)
      final double whiteOnPrimary =
          _contrastRatio(Colors.white, HobbiesColors.primary);
      expect(whiteOnPrimary, lessThan(4.5));
      expect(whiteOnPrimary, greaterThanOrEqualTo(3.0));
    });

    test('explicit white labels can be used on a verified dark surface', () {
      // 4. Explicit white labels can be used on a verified dark surface (#064E3B)
      final TextTheme themeWithWhiteLabel =
          HobbiesTypography.createTextTheme(labelColor: Colors.white);
      expect(themeWithWhiteLabel.labelLarge!.color, Colors.white);

      const Color primaryDarkCta = Color(0xFF064E3B);
      final double whiteOnDarkCta = _contrastRatio(
          themeWithWhiteLabel.labelLarge!.color!, primaryDarkCta);
      expect(whiteOnDarkCta, greaterThanOrEqualTo(7.0));
    });

    test('onPrimaryColor named parameter remains compatible', () {
      // 5. The onPrimaryColor named parameter remains compatible
      final TextTheme legacyTheme =
          HobbiesTypography.createTextTheme(onPrimaryColor: Colors.white);
      expect(legacyTheme.labelLarge!.color, Colors.white);
    });

    test(
        'createTextTheme applies accessible colors without foreign module bleed',
        () {
      final TextTheme theme = HobbiesTypography.createTextTheme();

      // Heading on Hobbies background meets WCAG AAA (>= 7.0:1)
      final double headingContrast = _contrastRatio(
          theme.headlineMedium!.color!, HobbiesColors.background);
      expect(headingContrast, greaterThanOrEqualTo(7.0));

      // Secondary text on Hobbies background meets WCAG AA (>= 4.5:1)
      final double secondaryContrast =
          _contrastRatio(theme.bodyMedium!.color!, HobbiesColors.background);
      expect(secondaryContrast, greaterThanOrEqualTo(4.5));

      // Does not contain Learning module primary (#2563EB) or heading (#090D2B)
      const Color learningPrimary = Color(0xFF2563EB);
      const Color learningHeading = Color(0xFF090D2B);
      expect(theme.headlineMedium!.color, isNot(learningPrimary));
      expect(theme.headlineMedium!.color, isNot(learningHeading));
      expect(theme.bodyLarge!.color, isNot(learningPrimary));
    });
  });

  group('Font Independence & Text Scaling Support', () {
    test(
        'styles rely on platform default fonts without undeclared font dependencies',
        () {
      expect(HobbiesTypography.screenTitle.fontFamily, isNull);
      expect(HobbiesTypography.sectionTitle.fontFamily, isNull);
      expect(HobbiesTypography.bodyText.fontFamily, isNull);
      expect(HobbiesTypography.secondaryText.fontFamily, isNull);
      expect(HobbiesTypography.buttonLabel.fontFamily, isNull);
      expect(HobbiesTypography.caption.fontFamily, isNull);
    });

    testWidgets('text widgets scale dynamically with TextScaler',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Standard Scale', style: HobbiesTypography.screenTitle),
              ],
            ),
          ),
        ),
      );

      final Size standardSize = tester.getSize(find.text('Standard Scale'));

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: Column(
                children: [
                  Text('Standard Scale', style: HobbiesTypography.screenTitle),
                ],
              ),
            ),
          ),
        ),
      );

      final Size scaledSize = tester.getSize(find.text('Standard Scale'));

      expect(scaledSize.width, greaterThan(standardSize.width));
      expect(scaledSize.height, greaterThan(standardSize.height));
    });
  });

  group('Regression Guard: Approved Hobbies Color Tokens', () {
    test('existing HobbiesColors constants remain unmodified and verified', () {
      expect(HobbiesColors.primary, const Color(0xFF16A34A));
      expect(HobbiesColors.background, const Color(0xFFECFDF5));
    });
  });
}
