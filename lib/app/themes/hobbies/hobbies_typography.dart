import 'package:flutter/material.dart';

/// Master typography foundation for the ANDRIL Hobbies module.
///
/// Declares immutable, compile-time [TextStyle] definitions for standard
/// Hobbies screen roles while preserving system text scaling and accessible contrast.
///
/// Metric notes:
/// - Uses platform default fonts; does not introduce undeclared font assets.
/// - Font metrics reflect prototype reference hierarchy without claiming unverified BRD approval.
/// - Conforms to Flutter Material 3 typography standards.
abstract final class HobbiesTypography {
  HobbiesTypography._();

  /// Prominent screen title style (e.g. top screen headers, primary page titles).
  static const TextStyle screenTitle = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  );

  /// Section title style for grouping cards, list sections, and feature headers.
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  /// Primary body text style for descriptions, journal entries, and discussions.
  static const TextStyle bodyText = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  /// Secondary text style for subtitles, metadata, and helper text.
  static const TextStyle secondaryText = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Action button label style for CTAs, dialog buttons, and interactive chips.
  static const TextStyle buttonLabel = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  /// Caption and supporting text style for timestamps, badges, and small hints.
  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  // --- Prototype Role Aliases for Backward Compatibility ---

  /// Prototype alias for [screenTitle].
  static const TextStyle displayMedium = screenTitle;

  /// Prototype alias for [sectionTitle].
  static const TextStyle titleLarge = sectionTitle;

  /// Prototype alias for [bodyText].
  static const TextStyle bodyLarge = bodyText;

  /// Prototype alias for [secondaryText].
  static const TextStyle bodyMedium = secondaryText;

  /// Prototype alias for [buttonLabel].
  static const TextStyle labelLarge = buttonLabel;

  /// Prototype alias for [caption].
  static const TextStyle labelSmall = caption;

  /// Builds a Material 3 [TextTheme] mapped to the Hobbies typography hierarchy.
  ///
  /// Merges default typography metrics with Hobbies-specific roles and accessible colors.
  static TextTheme createTextTheme({
    Color headingColor = const Color(0xFF0F2530),
    Color bodyColor = const Color(0xFF0F2530),
    Color secondaryColor = const Color(0xFF64748B),
    Color onPrimaryColor = Colors.white,
  }) {
    return TextTheme(
      headlineMedium: screenTitle.copyWith(color: headingColor),
      titleLarge: sectionTitle.copyWith(color: headingColor),
      bodyLarge: bodyText.copyWith(color: bodyColor),
      bodyMedium: secondaryText.copyWith(color: secondaryColor),
      labelLarge: buttonLabel.copyWith(color: onPrimaryColor),
      bodySmall: caption.copyWith(color: secondaryColor),
    );
  }
}
