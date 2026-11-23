import 'package:flutter/material.dart';

/// Design tokens for the ANDRIL Learning module.
///
/// Contains immutable compile-time colour constants matching the approved
/// Learning module visual identity.
abstract final class LearningColors {
  LearningColors._();

  /// Primary action, active indicators, and educational brand colour (#2563EB).
  static const Color primary = Color(0xFF2563EB);

  /// Default background canvas for Learning screens (#EEF2FF).
  static const Color background = Color(0xFFEEF2FF);

  /// Surface background for cards, sheets, and elevated dialogs (#FFFFFF).
  static const Color cardSurface = Color(0xFFFFFFFF);

  /// Primary typography, high-emphasis titles, and app bar headings (#090D2B).
  static const Color heading = Color(0xFF090D2B);

  /// Subtitles, body copy, unselected navigation tabs, and metadata (#475569).
  static const Color secondaryText = Color(0xFF475569);

  /// Decorative layered wave accent and transitional highlights (#A78BFA).
  static const Color waveAccent = Color(0xFFA78BFA);
}
