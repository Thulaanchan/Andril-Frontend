import 'package:flutter/material.dart';
import '../colors/m2_colors.dart';

/// ANDRIL Member-02 Background Scaffold.
///
/// Provides the signature light mint/cyan ambient gradient and subtle
/// decorative curves seen across all Member-02 onboarding screens.
class M2BackgroundScaffold extends StatelessWidget {
  const M2BackgroundScaffold({
    required this.body,
    super.key,
    this.safeArea = true,
    this.bottomNavigationBar,
  });

  final Widget body;
  final bool safeArea;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: M2Colors.backgroundTop,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: M2Colors.backgroundGradient,
            ),
          ),

          // Ambient soft decorative curved lines
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _AmbientCurvesPainter(),
              ),
            ),
          ),

          // Main Body
          if (safeArea)
            SafeArea(
              child: body,
            )
          else
            body,
        ],
      ),
    );
  }
}

class _AmbientCurvesPainter extends CustomPainter {
  const _AmbientCurvesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = M2Colors.ambientCurve
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Top subtle concentric arcs
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.9, -size.height * 0.05),
        radius: size.width * 0.75,
      ),
      0,
      3.14159,
      false,
      paint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.9, -size.height * 0.05),
        radius: size.width * 1.05,
      ),
      0,
      3.14159,
      false,
      paint,
    );

    // Bottom subtle concentric arcs
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 1.02),
        radius: size.width * 0.65,
      ),
      3.14159,
      3.14159,
      false,
      paint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 1.02),
        radius: size.width * 0.85,
      ),
      3.14159,
      3.14159,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
