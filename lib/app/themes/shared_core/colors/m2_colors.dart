import 'package:flutter/material.dart';

/// ANDRIL Member-02 Theme Color Tokens.
///
/// Extracted directly from the finalized onboarding design references
/// (`01-Splash_Screen_modified.png`, `02 Choose Your Language App Screen.png`,
/// `03 Andril Welcome_screen.png`).
abstract final class M2Colors {
  // Background gradient tones
  static const Color backgroundTop = Color(0xFFF0FDF9);
  static const Color backgroundMid1 = Color(0xFFE6F7F2);
  static const Color backgroundMid2 = Color(0xFFE1F4F0);
  static const Color backgroundBottom = Color(0xFFD4EDE7);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.35, 0.70, 1.0],
    colors: [
      backgroundTop,
      backgroundMid1,
      backgroundMid2,
      backgroundBottom,
    ],
  );

  // Primary Brand Teal (Action buttons, active highlights)
  static const Color primaryTeal = Color(0xFF007A78);
  static const Color primaryTealDark = Color(0xFF006461);
  static const Color primaryTealLight = Color(0xFF0D9488);
  static const Color primaryTealSurface = Color(0xFFE0F7F6);
  static const Color primaryTealBorder = Color(0xFF99F6E4);

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF006D68),
      Color(0xFF00897B),
    ],
  );

  // Typography Tones
  static const Color textPrimary = Color(0xFF0A1E3F);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textTealDark = Color(0xFF0F2E3B);
  static const Color textTagline = Color(0xFF1D4D4F);

  // Module Identity Colors
  // Module 01: Learning (Electric / Deep Blue)
  static const Color moduleLearning = Color(0xFF0284C7);
  static const Color moduleLearningBadge = Color(0xFF0284C7);
  static const LinearGradient moduleLearningGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
  );

  // Module 02: Hobbies (Fresh Emerald Green)
  static const Color moduleHobbies = Color(0xFF059669);
  static const Color moduleHobbiesBadge = Color(0xFF059669);
  static const LinearGradient moduleHobbiesGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF059669)],
  );

  // Module 03: Social (Vibrant Violet / Purple)
  static const Color moduleSocial = Color(0xFF7E22CE);
  static const Color moduleSocialBadge = Color(0xFF7E22CE);
  static const LinearGradient moduleSocialGradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
  );

  // Language Badges
  static const LinearGradient englishBadgeGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
  );
  static const LinearGradient tamilBadgeGradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
  );
  static const LinearGradient sinhalaBadgeGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF059669)],
  );

  // Cards and Surfacing
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color cardSelectedBorder = Color(0xFF007A78);
  static const Color cardSelectedGlow = Color(0x33007A78);

  // Ambient decoration lines
  static const Color ambientCurve = Color(0x26007A78);
}
