import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';

/// Reusable informational/security callout banner.
class AuthInfoBanner extends StatelessWidget {
  const AuthInfoBanner({
    required this.message,
    super.key,
    this.title,
    this.icon = Icons.info_outline_rounded,
    this.iconColor = M2Colors.primaryTealLight,
  });

  final String? title;
  final String message;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(M2Spacing.md),
      decoration: BoxDecoration(
        color: M2Colors.primaryTealSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(M2Spacing.radiusMd),
        border: Border.all(
          color: M2Colors.primaryTealBorder.withValues(alpha: 0.7),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22.0,
            color: iconColor,
          ),
          const SizedBox(width: M2Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: M2Colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: M2Spacing.xxs),
                ],
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: M2Colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
