import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';

/// ANDRIL Member-02 Overlapping Three-Module Visual Showcase.
///
/// Faithfully reproduces the Screen 03 hero illustration:
/// Three overlapping themed circular frames for Learning (Blue),
/// Hobbies (Green), and Social (Purple), with distinctive icons,
/// badges, and decorative ray accents.
class ModuleShowcaseWidget extends StatelessWidget {
  const ModuleShowcaseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 320.0,
        height: 310.0,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Top Circle: Learning (Blue)
            Positioned(
              top: 0,
              child: _buildCircleFrame(
                size: 140.0,
                glowColor: M2Colors.moduleLearning.withValues(alpha: 0.35),
                borderColor: M2Colors.moduleLearning.withValues(alpha: 0.5),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFF7DD3FC)],
                ),
                icon: Icons.menu_book_rounded,
                iconColor: M2Colors.moduleLearning,
                badgeWidget: _buildBadge(
                  label: 'Learning',
                  icon: Icons.menu_book_rounded,
                  color: M2Colors.moduleLearning,
                ),
                badgeAlignment: const Alignment(1.35, 0.1),
                burstRayOffset: const Offset(-20, -10),
                burstRayColor: M2Colors.moduleLearning,
              ),
            ),

            // Bottom-Left Circle: Hobbies (Green)
            Positioned(
              bottom: 12.0,
              left: 10.0,
              child: _buildCircleFrame(
                size: 132.0,
                glowColor: M2Colors.moduleHobbies.withValues(alpha: 0.35),
                borderColor: M2Colors.moduleHobbies.withValues(alpha: 0.5),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0), Color(0xFF6EE7B7)],
                ),
                icon: Icons.palette_rounded,
                iconColor: M2Colors.moduleHobbies,
                badgeWidget: _buildBadge(
                  label: 'Hobbies',
                  icon: Icons.palette_rounded,
                  color: M2Colors.moduleHobbies,
                ),
                badgeAlignment: const Alignment(0.4, 1.25),
              ),
            ),

            // Bottom-Right Circle: Social (Purple)
            Positioned(
              bottom: 12.0,
              right: 10.0,
              child: _buildCircleFrame(
                size: 132.0,
                glowColor: M2Colors.moduleSocial.withValues(alpha: 0.35),
                borderColor: M2Colors.moduleSocial.withValues(alpha: 0.5),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF), Color(0xFFD8B4FE)],
                ),
                icon: Icons.people_alt_rounded,
                iconColor: M2Colors.moduleSocial,
                badgeWidget: _buildBadge(
                  label: 'Social',
                  icon: Icons.people_alt_rounded,
                  color: M2Colors.moduleSocial,
                ),
                badgeAlignment: const Alignment(0.4, 1.25),
                burstRayOffset: const Offset(40, -15),
                burstRayColor: M2Colors.moduleSocial,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleFrame({
    required double size,
    required Color glowColor,
    required Color borderColor,
    required LinearGradient gradient,
    required IconData icon,
    required Color iconColor,
    required Widget badgeWidget,
    required Alignment badgeAlignment,
    Offset? burstRayOffset,
    Color? burstRayColor,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Decorative burst accent lines
        if (burstRayOffset != null && burstRayColor != null)
          Positioned(
            left: burstRayOffset.dx < 0 ? burstRayOffset.dx : null,
            right: burstRayOffset.dx > 0 ? burstRayOffset.dx : null,
            top: burstRayOffset.dy,
            child: _BurstRays(color: burstRayColor),
          ),

        // Main Circle
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            border: Border.all(
              color: borderColor,
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 20.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.42,
              color: iconColor,
            ),
          ),
        ),

        // Floating Module Badge
        Positioned.fill(
          child: Align(
            alignment: badgeAlignment,
            child: badgeWidget,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(M2Spacing.radiusPill),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15.0,
            color: Colors.white,
          ),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _BurstRays extends StatelessWidget {
  const _BurstRays({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24.0,
      height: 24.0,
      child: CustomPaint(
        painter: _BurstPainter(color: color),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(center, center + const Offset(-6, -6), paint);
    canvas.drawLine(center, center + const Offset(0, -9), paint);
    canvas.drawLine(center, center + const Offset(6, -6), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
