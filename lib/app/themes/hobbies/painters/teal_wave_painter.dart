import 'package:andril_mobile/app/themes/hobbies/hobbies_colors.dart';
import 'package:flutter/material.dart';

/// ANDRIL Hobbies Reusable Wave Vector Painter.
///
/// Renders the multi-stop flowing curved wave header for Hobbies screens,
/// based on the existing Hobbies 2.0 prototype (`03.png / Teal Andril App Home Screen.png`).
///
/// Design & Branding Notes:
/// - Purely decorative vector painting using three overlapping Bezier curve layers.
/// - Default [startColor] (`#01999A`) and [endColor] (`#006D77`) are decorative prototype
///   reference accents, NOT BRD-approved brand primary colors. The approved Hobbies
///   primary color is [HobbiesColors.primary] (`#16A34A`).
/// - The undertone layer safely transitions into the approved [HobbiesColors.background] (`#ECFDF5`).
/// - Pointer handling: Because this painter is purely decorative, parent widgets
///   (such as a future Hobbies scaffold header) should wrap the [CustomPaint] in an
///   [IgnorePointer] when touch pass-through is desired.
class TealWavePainter extends CustomPainter {
  /// Default decorative accent teal from prototype reference (header start).
  static const Color defaultStartColor = Color(0xFF01999A);

  /// Default decorative deep teal from Shared Core / prototype reference (header end).
  static const Color defaultEndColor = Color(0xFF006D77);

  /// Soft light wave start color from prototype reference.
  static const Color defaultLightWaveStart = Color(0xFFBDF5F2);

  /// Soft light wave end color from prototype reference.
  static const Color defaultLightWaveEnd = Color(0xFFD9FBF5);

  /// Default base wave header height.
  static const double defaultWaveHeight = 220.0;

  /// Base nominal height of the wave header.
  final double waveHeight;

  /// Starting gradient color for the primary wave (top-left).
  final Color startColor;

  /// Ending gradient color for the primary wave (bottom-right).
  final Color endColor;

  /// Whether to scale the wave height down for compact viewports or sub-headers.
  final bool isCompact;

  /// Whether to render a softer, translucent light-wave variation.
  final bool isLightWave;

  /// Creates a [TealWavePainter] with configurable or prototype reference default dimensions and colors.
  const TealWavePainter({
    this.waveHeight = defaultWaveHeight,
    this.startColor = defaultStartColor,
    this.endColor = defaultEndColor,
    this.isCompact = false,
    this.isLightWave = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double effectiveHeight = isCompact ? waveHeight * 0.75 : waveHeight;

    // Safety guard: do not attempt to paint on non-positive or empty dimensions.
    if (size.width <= 0 || effectiveHeight <= 0) {
      return;
    }

    final Rect rect = Rect.fromLTWH(0, 0, size.width, effectiveHeight);

    final Color effectiveStart =
        isLightWave ? defaultLightWaveStart : startColor;
    final Color effectiveEnd = isLightWave ? defaultLightWaveEnd : endColor;

    // Layer 1: Soft Undertone Wave blending into approved Hobbies background
    final Paint undertonePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          effectiveStart.withValues(alpha: isLightWave ? 0.45 : 0.25),
          HobbiesColors.background.withValues(alpha: 0.8),
        ],
      ).createShader(rect);

    final Path path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(0, effectiveHeight * 0.95)
      ..quadraticBezierTo(
        size.width * 0.28,
        effectiveHeight * 1.08,
        size.width * 0.65,
        effectiveHeight * 0.92,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        effectiveHeight * 0.82,
        size.width,
        effectiveHeight * 0.98,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path1, undertonePaint);

    // Layer 2: Main Wave Gradient
    final Paint mainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[effectiveStart, effectiveEnd],
      ).createShader(rect);

    final Path path2 = Path()
      ..moveTo(0, 0)
      ..lineTo(0, effectiveHeight * 0.82)
      ..quadraticBezierTo(
        size.width * 0.35,
        effectiveHeight * 0.98,
        size.width * 0.70,
        effectiveHeight * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        effectiveHeight * 0.68,
        size.width,
        effectiveHeight * 0.85,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path2, mainPaint);

    // Layer 3: Subtle Translucent Highlight Crest
    final Paint highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(rect);

    final Path path3 = Path()
      ..moveTo(0, 0)
      ..lineTo(0, effectiveHeight * 0.55)
      ..quadraticBezierTo(
        size.width * 0.45,
        effectiveHeight * 0.72,
        size.width,
        effectiveHeight * 0.52,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path3, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant TealWavePainter oldDelegate) {
    return oldDelegate.waveHeight != waveHeight ||
        oldDelegate.startColor != startColor ||
        oldDelegate.endColor != endColor ||
        oldDelegate.isCompact != isCompact ||
        oldDelegate.isLightWave != isLightWave;
  }
}
