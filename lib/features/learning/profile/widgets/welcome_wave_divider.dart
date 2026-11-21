import 'package:flutter/material.dart';

/// An asymmetric layered decorative wave divider for the Learning module.
///
/// Paints three overlapping cubic Bezier wave layers using the approved Learning
/// palette: Purple accent (#A78BFA), Light blue accent (#93B4FA), Bright blue
/// accent (#0057FF), and Primary blue (#2563EB).
class WelcomeWaveDivider extends StatelessWidget {
  /// Default wave height across standard mobile viewports.
  static const double defaultHeight = 48.0;

  /// Height of the wave divider component.
  final double height;

  /// Creates a [WelcomeWaveDivider].
  const WelcomeWaveDivider({
    super.key,
    this.height = defaultHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: const _WavePainter(),
        size: Size(double.infinity, height),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  // Color tokens specified for the layered wave divider.
  static const Color purpleAccent = Color(0xFFA78BFA);
  static const Color lightBlueAccent = Color(0xFF93B4FA);
  static const Color brightBlueAccent = Color(0xFF0057FF);
  static const Color primaryBlue = Color(0xFF2563EB);

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Layer 1 (Back wave): Purple accent (#A78BFA) with soft opacity
    final Paint paint1 = Paint()
      ..color = purpleAccent.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path path1 = Path()
      ..moveTo(0, height * 0.45)
      ..cubicTo(
        width * 0.22,
        height * 0.10,
        width * 0.48,
        height * 0.70,
        width * 0.76,
        height * 0.30,
      )
      ..cubicTo(
        width * 0.90,
        height * 0.12,
        width * 0.96,
        height * 0.25,
        width,
        height * 0.20,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(path1, paint1);

    // Layer 2 (Middle wave): Light blue accent blending into bright blue
    final Paint paint2 = Paint()
      ..color = lightBlueAccent.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path path2 = Path()
      ..moveTo(0, height * 0.60)
      ..cubicTo(
        width * 0.28,
        height * 0.35,
        width * 0.52,
        height * 0.85,
        width * 0.80,
        height * 0.45,
      )
      ..cubicTo(
        width * 0.92,
        height * 0.30,
        width * 0.98,
        height * 0.40,
        width,
        height * 0.35,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(path2, paint2);

    // Layer 3 (Foreground wave): Primary blue transitioning to bright blue
    final Paint paint3 = Paint()
      ..shader = const LinearGradient(
        colors: [primaryBlue, brightBlueAccent],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path path3 = Path()
      ..moveTo(0, height * 0.75)
      ..cubicTo(
        width * 0.25,
        height * 0.55,
        width * 0.55,
        height * 0.95,
        width * 0.82,
        height * 0.65,
      )
      ..cubicTo(
        width * 0.92,
        height * 0.52,
        width * 0.97,
        height * 0.60,
        width,
        height * 0.55,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => false;
}
