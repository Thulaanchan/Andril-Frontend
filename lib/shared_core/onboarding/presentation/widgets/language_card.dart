import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';
import '../../../../app/themes/shared_core/typography/m2_typography.dart';
import '../../../language_selection/domain/models/app_language.dart';

/// Interactive Language Selection Card.
///
/// Displays a language option with its colored language badge, bilingual
/// title/subtitle, and interactive radio selection indicator.
class LanguageCard extends StatelessWidget {
  const LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(M2Spacing.radiusLg),
        border: Border.all(
          color: isSelected ? M2Colors.primaryTeal : M2Colors.cardBorder,
          width: isSelected ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? M2Colors.primaryTeal.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isSelected ? 12.0 : 6.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(M2Spacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: M2Spacing.md,
              vertical: M2Spacing.md,
            ),
            child: Row(
              children: [
                // Colored Language Badge
                Container(
                  width: 52.0,
                  height: 52.0,
                  decoration: BoxDecoration(
                    gradient: language.badgeGradient,
                    borderRadius: BorderRadius.circular(M2Spacing.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: language.badgeGradient.colors.last.withValues(alpha: 0.3),
                        blurRadius: 8.0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      language.badgeLabel,
                      style: M2Typography.badgeText,
                    ),
                  ),
                ),
                const SizedBox(width: M2Spacing.md),

                // Language Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        language.title,
                        style: M2Typography.cardTitle,
                      ),
                      const SizedBox(height: M2Spacing.xxs),
                      Text(
                        language.subtitle,
                        style: M2Typography.cardSubtitle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: M2Spacing.xs),

                // Radio Button Indicator
                Container(
                  width: 24.0,
                  height: 24.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? M2Colors.primaryTeal
                          : const Color(0xFF94A3B8),
                      width: 2.0,
                    ),
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: isSelected ? 12.0 : 0.0,
                      height: isSelected ? 12.0 : 0.0,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: M2Colors.primaryTeal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
