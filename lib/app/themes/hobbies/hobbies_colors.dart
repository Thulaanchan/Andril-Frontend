import 'package:flutter/material.dart';

/// Design colour tokens for the ANDRIL Hobbies module.
///
/// Contains immutable compile-time colour constants matching the explicitly
/// approved Hobbies module visual identity under ANDRIL BRD v2.4-R1 Section 15.1.
abstract final class HobbiesColors {
  HobbiesColors._();

  /// Official Hobbies primary brand colour (#16A34A) - BRD Section 15.1.
  static const Color primary = Color(0xFF16A34A);

  /// Default background canvas for Hobbies screens (#ECFDF5) - BRD Section 15.1.
  static const Color background = Color(0xFFECFDF5);
}
