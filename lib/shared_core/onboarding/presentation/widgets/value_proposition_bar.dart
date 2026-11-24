import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';
import '../../../../app/themes/shared_core/typography/m2_typography.dart';

/// ANDRIL Member-02 Three-Pillar Value Proposition Bar.
///
/// Highlights "Real people", "Safe & private", and "Multiple ways"
/// in a translucent rounded container with clean separation.
class ValuePropositionBar extends StatelessWidget {
  const ValuePropositionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(M2Spacing.radiusLg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: M2Spacing.sm,
        vertical: M2Spacing.md,
      ),
      child: Row(
        children: [
          // Pillar 1: Real people
          Expanded(
            child: _buildPillar(
              icon: Icons.groups_outlined,
              title: 'Real people',
              subtitle: 'Connect with\ngenuine people',
            ),
          ),
          _buildDivider(),

          // Pillar 2: Safe & private
          Expanded(
            child: _buildPillar(
              icon: Icons.shield_outlined,
              title: 'Safe & private',
              subtitle: 'Your privacy\ncomes first',
            ),
          ),
          _buildDivider(),

          // Pillar 3: Multiple ways
          Expanded(
            child: _buildPillar(
              icon: Icons.spa_outlined,
              title: 'Multiple ways',
              subtitle: 'Learn, explore\nand connect',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillar({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 24.0,
          color: M2Colors.primaryTealLight,
        ),
        const SizedBox(height: M2Spacing.xs),
        Text(
          title,
          style: M2Typography.pillarTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: M2Spacing.xxs),
        Text(
          subtitle,
          style: M2Typography.pillarSubtitle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 48.0,
      width: 1.0,
      color: const Color(0xFFE2E8F0),
    );
  }
}
