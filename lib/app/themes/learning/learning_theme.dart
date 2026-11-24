import 'package:flutter/material.dart';

import 'learning_colors.dart';

/// Reusable Material 3 theme factory for the ANDRIL Learning module.
abstract final class LearningTheme {
  LearningTheme._();

  /// Builds a dedicated Material 3 [ThemeData] instance for the Learning module.
  static ThemeData get theme {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: LearningColors.primary,
      onPrimary: Colors.white,
      surface: LearningColors.cardSurface,
      onSurface: LearningColors.heading,
      error: Color(0xFFDC2626),
      onError: Colors.white,
    );

    // Preserve default Typography metrics from the Flutter SDK while applying
    // Learning-specific colours and weights.
    final TextTheme baseTypography = Typography.material2021().black;
    final TextTheme textTheme = baseTypography.copyWith(
      displayLarge: baseTypography.displayLarge?.copyWith(
        color: LearningColors.heading,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: baseTypography.displayMedium?.copyWith(
        color: LearningColors.heading,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: baseTypography.displaySmall?.copyWith(
        color: LearningColors.heading,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: baseTypography.headlineLarge?.copyWith(
        color: LearningColors.heading,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: baseTypography.headlineMedium?.copyWith(
        color: LearningColors.heading,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: baseTypography.headlineSmall?.copyWith(
        color: LearningColors.heading,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: baseTypography.titleLarge?.copyWith(
        color: LearningColors.heading,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTypography.titleMedium?.copyWith(
        color: LearningColors.heading,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: baseTypography.titleSmall?.copyWith(
        color: LearningColors.heading,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTypography.bodyLarge?.copyWith(
        color: LearningColors.secondaryText,
      ),
      bodyMedium: baseTypography.bodyMedium?.copyWith(
        color: LearningColors.secondaryText,
      ),
      bodySmall: baseTypography.bodySmall?.copyWith(
        color: LearningColors.secondaryText,
      ),
      labelLarge: baseTypography.labelLarge?.copyWith(
        color: LearningColors.heading,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseTypography.labelMedium?.copyWith(
        color: LearningColors.secondaryText,
      ),
      labelSmall: baseTypography.labelSmall?.copyWith(
        color: LearningColors.secondaryText,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LearningColors.background,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: LearningColors.background,
        foregroundColor: LearningColors.heading,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: LearningColors.heading,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: LearningColors.heading),
      ),
      cardTheme: CardThemeData(
        color: LearningColors.cardSurface,
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
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFE2E8F0);
            }
            if (states.contains(WidgetState.focused) ||
                states.contains(WidgetState.hovered)) {
              return const Color(0xFF1D4ED8);
            }
            return LearningColors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF94A3B8);
            }
            return Colors.white;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return 2.0;
            }
            return 0.0;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(88, 48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF94A3B8);
            }
            return LearningColors.primary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const BorderSide(color: Color(0xFFE2E8F0), width: 1.5);
            }
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: Color(0xFF1D4ED8), width: 2.0);
            }
            return const BorderSide(color: LearningColors.primary, width: 1.5);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(64, 40)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF94A3B8);
            }
            if (states.contains(WidgetState.focused)) {
              return const Color(0xFF1D4ED8);
            }
            return LearningColors.primary;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LearningColors.cardSurface,
        hintStyle: const TextStyle(color: LearningColors.secondaryText),
        labelStyle: const TextStyle(color: LearningColors.secondaryText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: LearningColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: LearningColors.primary,
        linearTrackColor: Color(0xFFDBEAFE),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LearningColors.cardSurface,
        indicatorColor: const Color(0xFFDBEAFE),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: LearningColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: LearningColors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.normal,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: LearningColors.primary);
          }
          return const IconThemeData(color: LearningColors.secondaryText);
        }),
      ),
    );
  }
}
