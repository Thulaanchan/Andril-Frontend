import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';

/// Supported application language in ANDRIL Member-02 Onboarding.
enum AppLanguage {
  english(
    code: 'en',
    title: 'English',
    subtitle: 'Use Andril in English.',
    badgeLabel: 'EN',
    badgeGradient: M2Colors.englishBadgeGradient,
  ),
  tamil(
    code: 'ta',
    title: 'தமிழ் — Tamil',
    subtitle: 'Andril-ஐ தமிழில்\nபயன்படுத்தவும்.',
    badgeLabel: 'த',
    badgeGradient: M2Colors.tamilBadgeGradient,
  ),
  sinhala(
    code: 'si',
    title: 'සිංහල — Sinhala',
    subtitle: 'Andril භාවිතය කිරීමට\nසිංහල තෝරන්න.',
    badgeLabel: 'සි',
    badgeGradient: M2Colors.sinhalaBadgeGradient,
  );

  const AppLanguage({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeGradient,
  });

  final String code;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final LinearGradient badgeGradient;

  /// Validates whether the given code corresponds to a supported language.
  static bool isValidCode(String? code) {
    if (code == null || code.trim().isEmpty) return false;
    final normalized = code.trim().toLowerCase();
    return AppLanguage.values.any((lang) => lang.code.toLowerCase() == normalized);
  }

  /// Safely attempts to parse a language from code, returning null if invalid or unsupported.
  static AppLanguage? tryFromCode(String? code) {
    if (code == null) return null;
    final normalized = code.trim().toLowerCase();
    for (final lang in AppLanguage.values) {
      if (lang.code.toLowerCase() == normalized) return lang;
    }
    return null;
  }

  static AppLanguage fromCode(String? code) {
    return tryFromCode(code) ?? AppLanguage.english;
  }
}
