import 'package:flutter/material.dart';
import '../colors/m2_colors.dart';

/// ANDRIL Member-02 Typography Tokens.
abstract final class M2Typography {
  static const TextStyle splashTagline = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: M2Colors.textTagline,
    letterSpacing: 1.4,
  );

  static const TextStyle heroTitle = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w800,
    color: M2Colors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle heroSubtitle = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w500,
    color: M2Colors.textSecondary,
    height: 1.4,
  );

  static const TextStyle welcomeHeadline = TextStyle(
    fontSize: 30.0,
    fontWeight: FontWeight.w800,
    fontStyle: FontStyle.italic,
    color: M2Colors.textTealDark,
    letterSpacing: -0.6,
  );

  static const TextStyle welcomeDescription = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w500,
    color: Color(0xFF2D4B54),
    height: 1.4,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: M2Colors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: M2Colors.textMuted,
    height: 1.35,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle infoText = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: M2Colors.textPrimary,
    height: 1.3,
  );

  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w700,
    color: M2Colors.primaryTeal,
    letterSpacing: 0.2,
  );

  static const TextStyle pillarTitle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: M2Colors.textPrimary,
  );

  static const TextStyle pillarSubtitle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w400,
    color: M2Colors.textSecondary,
    height: 1.2,
  );
}
