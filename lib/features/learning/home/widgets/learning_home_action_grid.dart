import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';

/// Immutable model representing an individual shortcut item in [LearningHomeActionGrid].
@immutable
class LearningHomeActionItem {
  /// Unique identifier for this action item.
  final String id;

  /// Human-readable title displayed on the action card.
  final String title;

  /// Material icon representing the shortcut feature.
  final IconData icon;

  /// Optional callback invoked when the user taps this action card.
  ///
  /// If null or if [unavailableReason] is non-empty, the card is non-interactive.
  final VoidCallback? onTap;

  /// Optional explanation of why this action is currently unavailable.
  ///
  /// When non-null and non-empty, the card renders in a disabled state
  /// displaying this explanation.
  final String? unavailableReason;

  /// Creates an immutable [LearningHomeActionItem].
  const LearningHomeActionItem({
    required this.id,
    required this.title,
    required this.icon,
    this.onTap,
    this.unavailableReason,
  });

  /// Whether this action is interactive and available for user interaction.
  bool get isAvailable =>
      onTap != null &&
      (unavailableReason == null || unavailableReason!.trim().isEmpty);
}

/// Presentation-only grid displaying feature shortcuts for the ANDRIL Learning Home.
///
/// Architecture & Security Constraints (BRD §04.3, §05 CF-03, §06 LRN-01..LRN-06):
/// - Purely presentational; receives all action items and callbacks via constructor.
/// - Does NOT execute router navigation, context.go, or Navigator.push independently.
/// - Does NOT check M2 authentication, user membership, or backend permissions.
/// - Does NOT calculate XP, level up, or award growth badges.
/// - Responsive across 320dp, 360dp, and 412dp viewports using adaptive column constraints.
class LearningHomeActionGrid extends StatelessWidget {
  /// The list of shortcut actions to display in the grid.
  final List<LearningHomeActionItem> actions;

  /// Section title displayed above the grid.
  ///
  /// Defaults to 'My Learning Hub'.
  final String title;

  /// Outer padding around the entire section.
  ///
  /// Defaults to `EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)`.
  final EdgeInsetsGeometry padding;

  /// Spacing between action cards in the grid.
  ///
  /// Defaults to 12.0.
  final double spacing;

  /// Creates an immutable [LearningHomeActionGrid].
  const LearningHomeActionGrid({
    super.key,
    required this.actions,
    this.title = 'My Learning Hub',
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 12.0),
          LayoutBuilder(
            builder: (context, constraints) {
              final double availableWidth = constraints.maxWidth;
              final int crossAxisCount =
                  availableWidth < 260 ? 1 : (availableWidth < 500 ? 2 : 3);
              final double itemWidth =
                  (availableWidth - (crossAxisCount - 1) * spacing) /
                      crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: actions.map((item) {
                  return SizedBox(
                    key: Key(item.id),
                    width: itemWidth,
                    child: _buildActionCard(context, item),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Section heading.
  Widget _buildHeader() {
    return Text(
      title,
      style: const TextStyle(
        color: LearningColors.heading,
        fontSize: 16.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Builds an individual action card widget.
  Widget _buildActionCard(BuildContext context, LearningHomeActionItem item) {
    final bool isAvailable = item.isAvailable;
    final String? trimmedReason = item.unavailableReason?.trim();
    final bool hasReason = trimmedReason != null && trimmedReason.isNotEmpty;

    return Semantics(
      button: isAvailable,
      enabled: isAvailable,
      label: item.title,
      hint: isAvailable ? null : (hasReason ? trimmedReason : 'Unavailable'),
      child: Material(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: isAvailable ? item.onTap : null,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isAvailable
                    ? LearningColors.primary.withValues(alpha: 0.12)
                    : LearningColors.secondaryText.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? LearningColors.primary.withValues(alpha: 0.1)
                        : LearningColors.secondaryText.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20.0,
                    color: isAvailable
                        ? LearningColors.primary
                        : LearningColors.secondaryText.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isAvailable
                        ? LearningColors.heading
                        : LearningColors.secondaryText.withValues(alpha: 0.6),
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                if (!isAvailable && hasReason) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    trimmedReason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LearningColors.secondaryText,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Empty state content when [actions] is empty.
  Widget _buildEmptyState() {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 12.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            decoration: BoxDecoration(
              color: LearningColors.cardSurface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: LearningColors.secondaryText.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: const Center(
              child: Text(
                'No learning actions available',
                style: TextStyle(
                  color: LearningColors.secondaryText,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
