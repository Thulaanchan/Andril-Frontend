import 'package:flutter/material.dart';

import 'hobbies_colors.dart';
import 'hobbies_typography.dart';

/// Reusable Material 3 theme foundation for the ANDRIL Hobbies module.
///
/// Encapsulates the approved Hobbies branding (primary green `#16A34A`, background
/// mint `#ECFDF5`) and typography with WCAG AA compliant contrast pairings.
abstract final class HobbiesTheme {
  HobbiesTheme._();

  /// Dark text reference for headers, high-emphasis body, and button labels.
  ///
  /// Drawn from prototype reference (`#0F2530`). Provides a WCAG AA compliant
  /// contrast ratio (4.80:1 >= 4.5:1) against [HobbiesColors.primary] (`#16A34A`).
  static const Color textDark = Color(0xFF0F2530);

  /// Secondary muted text reference for subtitles and helper text (`#64748B`).
  static const Color textSecondary = Color(0xFF64748B);

  /// Crisp white surface container (`#FFFFFF`).
  static const Color cardSurface = Color(0xFFFFFFFF);

  /// Error color token (`#DC2626`).
  static const Color errorColor = Color(0xFFDC2626);

  /// Builds a dedicated Material 3 [ThemeData] instance for the Hobbies module.
  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: HobbiesColors.primary,
      onPrimary: textDark, // 4.80:1 contrast on #16A34A (WCAG AA compliant)
      primaryContainer: HobbiesColors.background,
      onPrimaryContainer: textDark,
      surface: cardSurface,
      onSurface: textDark,
      onSurfaceVariant: textSecondary,
      error: errorColor,
      onError: Colors.white,
    );

    final TextTheme textTheme = HobbiesTypography.createTextTheme(
      headingColor: textDark,
      bodyColor: textDark,
      secondaryColor: textSecondary,
      labelColor: textDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: HobbiesColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: HobbiesColors.background,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: HobbiesTypography.screenTitle.copyWith(color: textDark),
        iconTheme: const IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(88, 48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: WidgetStateProperty.all(HobbiesTypography.buttonLabel),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFE2E8F0);
            }
            if (states.contains(WidgetState.focused) ||
                states.contains(WidgetState.hovered)) {
              return const Color(0xFF15803D); // Focused / hovered darker green
            }
            return HobbiesColors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF94A3B8);
            }
            // Accessible dark text #0F2530 (4.80:1 on #16A34A, passing normal-text WCAG AA)
            return textDark;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return 2.0;
            }
            return 0.0;
          }),
        ),
      ),
    );
  }
}
