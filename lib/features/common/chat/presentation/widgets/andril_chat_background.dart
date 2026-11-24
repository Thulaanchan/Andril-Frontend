import 'package:flutter/material.dart';
import 'package:andril_mobile/app/themes/social/social_theme.dart';
import 'package:andril_mobile/features/common/chat/domain/module_config.dart';

/// Renders the exact background corresponding to the active ANDRIL module.
/// - Learning: Soft Light Blue (#EEF2FF) with subtle radial ellipses.
/// - Hobbies: Soft Mint (#ECFDF5) with subtle teal radial ellipses.
/// - Social: Warm Cream (#FAF7F2) with copper and cream vector waves.
class AndrilChatBackground extends StatelessWidget {
  final AndrilModuleType moduleType;

  const AndrilChatBackground({super.key, required this.moduleType});

  @override
  Widget build(BuildContext context) {
    switch (moduleType) {
      case AndrilModuleType.social:
        return const SocialWaveBackground();
      case AndrilModuleType.learning:
        return const IgnorePointer(
          child: CustomPaint(
            painter: _LearningMeshPainter(),
            child: SizedBox.expand(),
          ),
        );
      case AndrilModuleType.hobbies:
        return const IgnorePointer(
          child: CustomPaint(
            painter: _HobbiesMeshPainter(),
            child: SizedBox.expand(),
          ),
        );
    }
  }
}

class _LearningMeshPainter extends CustomPainter {
  const _LearningMeshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Base gradient matching HTML: linear-gradient(145deg,#f5f7ff,#e8efff 82%)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F7FF), Color(0xFFE8EFFF)],
        ).createShader(rect),
    );

    // Subtle radial accents from reference CSS
    final w = size.width;
    final h = size.height;

    // Ellipse 1: top-right
    final paint1 = Paint()
      ..color = const Color(0xFF6F8DFF).withValues(alpha: 0.11)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(Offset(w * 1.03, h * 0.39), w * 0.35, paint1);

    // Ellipse 2: bottom-left
    final paint2 = Paint()
      ..color = const Color(0xFF7E95F2).withValues(alpha: 0.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(-w * 0.18, h * 0.72), w * 0.45, paint2);

    // Ellipse 3: bottom-right
    final paint3 = Paint()
      ..color = const Color(0xFF6782EF).withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45);
    canvas.drawCircle(Offset(w * 1.15, h * 0.92), w * 0.40, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HobbiesMeshPainter extends CustomPainter {
  const _HobbiesMeshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Base gradient matching HTML: linear-gradient(145deg,#f2fffb,#dff8f2 82%)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF2FFFB), Color(0xFFDFF8F2)],
        ).createShader(rect),
    );

    final w = size.width;
    final h = size.height;

    // Ellipse 1: top-right
    final paint1 = Paint()
      ..color = const Color(0xFF5ADCCC).withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(Offset(w * 1.03, h * 0.39), w * 0.35, paint1);

    // Ellipse 2: bottom-left
    final paint2 = Paint()
      ..color = const Color(0xFF59D1C8).withValues(alpha: 0.11)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(-w * 0.18, h * 0.72), w * 0.45, paint2);

    // Ellipse 3: bottom-right
    final paint3 = Paint()
      ..color = const Color(0xFF40BFB4).withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45);
    canvas.drawCircle(Offset(w * 1.15, h * 0.92), w * 0.40, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
