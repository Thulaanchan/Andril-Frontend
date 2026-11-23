import 'dart:math' as math;

import 'package:flutter/material.dart';

/// BRD v2.4-R1, section 15.1. These are the selected Social palette tokens.
abstract final class AndrilSocialColors {
  static const royalPurple = Color(0xFF330099);
  static const copper = Color(0xFFC47A44);
  static const cream = Color(0xFFFAF7F2);
  static const canvasCream = Color(0xFFFFFCFA);
  static const ink = Color(0xFF1B1047);
  static const border = Color(0xFFE5DDE8);
  static const giftTile = Color(0xFFF7EDF4);
  static const faintPurple = Color(0xFFF2EAF3);
}

/// Replicates the v6 copper/cream background waves without SVG plugins.
class SocialWaveBackground extends StatelessWidget {
  const SocialWaveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _SocialWavePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SocialWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AndrilSocialColors.cream,
    );
    final top = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * .17)
      ..cubicTo(w * .75, h * .21, w * .65, h * .13, w * .45, h * .18)
      ..cubicTo(w * .27, h * .22, w * .18, h * .15, 0, h * .20)
      ..close();
    canvas.drawPath(
      top,
      Paint()..color = AndrilSocialColors.copper.withValues(alpha: .14),
    );
    final topCream = Path()
      ..moveTo(0, h * .115)
      ..cubicTo(w * .24, h * .08, w * .36, h * .16, w * .57, h * .13)
      ..cubicTo(w * .80, h * .10, w * .86, h * .16, w, h * .12)
      ..lineTo(w, h * .24)
      ..cubicTo(w * .78, h * .20, w * .65, h * .27, w * .43, h * .22)
      ..cubicTo(w * .25, h * .19, w * .13, h * .25, 0, h * .22)
      ..close();
    canvas.drawPath(
      topCream,
      Paint()..color = AndrilSocialColors.cream.withValues(alpha: .95),
    );
    final lower = Path()
      ..moveTo(0, h * .79)
      ..cubicTo(w * .24, h * .75, w * .35, h * .83, w * .57, h * .79)
      ..cubicTo(w * .78, h * .76, w * .90, h * .83, w, h * .78)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      lower,
      Paint()..color = AndrilSocialColors.copper.withValues(alpha: .12),
    );
    final bottomWave = Path()
      ..moveTo(0, h * .89)
      ..cubicTo(w * .18, h * .86, w * .32, h * .94, w * .55, h * .9)
      ..cubicTo(w * .78, h * .87, w * .90, h * .93, w, h * .89)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      bottomWave,
      Paint()..color = AndrilSocialColors.cream.withValues(alpha: .97),
    );
    // Top/bottom edges stay smooth at high DPI, no visible dark seams.
    final tiny = math.min(w, h) * .0001;
    if (tiny > 0) {
      canvas.drawLine(
        Offset(0, h),
        Offset(w, h),
        Paint()..color = AndrilSocialColors.cream,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
