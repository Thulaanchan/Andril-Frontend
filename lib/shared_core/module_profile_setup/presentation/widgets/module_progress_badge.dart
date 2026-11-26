import 'package:flutter/material.dart';

/// Renders the module identity badge and optional progress step indicator.
class ModuleProgressBadge extends StatelessWidget {
  const ModuleProgressBadge({
    super.key,
    required this.moduleTitle,
    required this.moduleIcon,
    required this.badgeBackgroundColor,
    required this.badgeTextColor,
    this.progressText,
  });

  final String moduleTitle;
  final IconData moduleIcon;
  final Color badgeBackgroundColor;
  final Color badgeTextColor;
  final String? progressText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Module Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                moduleIcon,
                size: 15,
                color: badgeTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                moduleTitle,
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        // Progress Step Indicator (e.g. '01 / 03')
        if (progressText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Text(
              progressText!,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

