import 'package:flutter/material.dart';

/// Reusable decorative wave divider supporting configurable multi-stop wave palettes.
///
/// Paints up to 4 overlapping cubic Bezier wave curves matching the visual flow
/// established in the finalized module welcome designs.
class ModuleWelcomeWaveDivider extends StatelessWidget {
  const ModuleWelcomeWaveDivider({
    super.key,
    required this.waveColors,
    this.height = 48.0,
  });

  /// Colors for the layered waves, ordered from back to front.
  final List<Color> waveColors;

  /// Height of the wave divider.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _MultiLayerWavePainter(waveColors),
        size: Size(double.infinity, height),
      ),
    );
  }
}

class _MultiLayerWavePainter extends CustomPainter {
  const _MultiLayerWavePainter(this.colors);

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    // Layer 1 (Back wave)
    if (colors.isNotEmpty) {
      final Paint paint1 = Paint()
        ..color = colors[0].withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;

      final Path path1 = Path()
        ..moveTo(0, height * 0.45)
        ..cubicTo(
          width * 0.22,
          height * 0.05,
          width * 0.48,
          height * 0.95,
          width * 0.78,
          height * 0.35,
        )
        ..cubicTo(
          width * 0.88,
          height * 0.15,
          width * 0.96,
          height * 0.25,
          width,
          height * 0.30,
        )
        ..lineTo(width, height)
        ..lineTo(0, height)
        ..close();

      canvas.drawPath(path1, paint1);
    }

    // Layer 2 (Middle wave)
    if (colors.length > 1) {
      final Paint paint2 = Paint()
        ..color = colors[1].withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;

      final Path path2 = Path()
        ..moveTo(0, height * 0.60)
        ..cubicTo(
          width * 0.28,
          height * 0.85,
          width * 0.58,
          height * 0.15,
          width * 0.82,
          height * 0.60,
        )
        ..cubicTo(
          width * 0.90,
          height * 0.72,
          width * 0.96,
          height * 0.68,
          width,
          height * 0.55,
        )
        ..lineTo(width, height)
        ..lineTo(0, height)
        ..close();

      canvas.drawPath(path2, paint2);
    }

    // Layer 3 (Foreground accent wave)
    if (colors.length > 2) {
      final Paint paint3 = Paint()
        ..color = colors[2].withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      final Path path3 = Path()
        ..moveTo(0, height * 0.75)
        ..cubicTo(
          width * 0.20,
          height * 0.40,
          width * 0.52,
          height * 0.90,
          width * 0.74,
          height * 0.65,
        )
        ..cubicTo(
          width * 0.85,
          height * 0.52,
          width * 0.94,
          height * 0.75,
          width,
          height * 0.70,
        )
        ..lineTo(width, height)
        ..lineTo(0, height)
        ..close();

      canvas.drawPath(path3, paint3);
    }

    // Layer 4 (Bottom-most anchor wave if provided)
    if (colors.length > 3) {
      final Paint paint4 = Paint()
        ..color = colors[3]
        ..style = PaintingStyle.fill;

      final Path path4 = Path()
        ..moveTo(0, height * 0.90)
        ..cubicTo(
          width * 0.35,
          height * 0.75,
          width * 0.65,
          height * 0.98,
          width,
          height * 0.85,
        )
        ..lineTo(width, height)
        ..lineTo(0, height)
        ..close();

      canvas.drawPath(path4, paint4);
    }
  }

  @override
  bool shouldRepaint(covariant _MultiLayerWavePainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

