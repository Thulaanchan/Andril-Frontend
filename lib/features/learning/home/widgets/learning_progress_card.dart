import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';

/// Presentation-only card widget displaying active goal progress for the ANDRIL Learning Home.
///
/// Displays the active learning goal title, an externally supplied completion percentage,
/// a visual progress indicator, an optional weekly commitment summary, and an optional
/// action button to resume learning.
///
/// Architecture & Security Constraints (BRD §04.3, §05 CF-01, CF-02, CF-03, §06 LRN-04):
/// - Purely presentational; receives all progress and goal data via constructor arguments.
/// - Does NOT calculate, estimate, or extrapolate progress percentages, XP, or streaks.
/// - Does NOT verify growth achievements or claim evidence-based certification.
/// - Does NOT contact backend APIs, Supabase, or M2 authentication services.
/// - Does NOT execute navigation or mutate router state independently.
/// - Strictly scoped to the Learning module; no cross-module profile or data leakage.
/// - Fully responsive across 320dp, 360dp, and 412dp viewports with dynamic text scaling.
class LearningProgressCard extends StatelessWidget {
  /// The active learning goal title to display.
  ///
  /// When null, empty, or whitespace-only, the card displays a neutral empty state.
  final String? goalTitle;

  /// Externally supplied completion percentage from 0 through 100.
  ///
  /// - `0..100`: Renders a determinate progress bar and percentage label.
  /// - `null`: Treated as progress unavailable without showing a fake percentage.
  /// - `< 0` or `> 100`: Treated as invalid; renders an unavailable state safely.
  final int? completionPercent;

  /// Optional caller-provided summary of the weekly learning commitment (e.g. '3 hrs/week').
  ///
  /// Only rendered when non-null and non-empty after trimming.
  final String? weeklyCommitmentText;

  /// Optional callback invoked when the user taps the 'Resume Learning' button.
  ///
  /// When null or when no valid goal exists, the resume button is omitted.
  final VoidCallback? onResume;

  /// Internal padding for the card container.
  ///
  /// Defaults to `EdgeInsets.all(16.0)`.
  final EdgeInsetsGeometry padding;

  /// Optional outer margin around the card container.
  final EdgeInsetsGeometry? margin;

  /// Creates an immutable [LearningProgressCard].
  const LearningProgressCard({
    super.key,
    this.goalTitle,
    this.completionPercent,
    this.weeklyCommitmentText,
    this.onResume,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final String? trimmedGoal = goalTitle?.trim();
    final bool hasGoal = trimmedGoal != null && trimmedGoal.isNotEmpty;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: LearningColors.primary.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: LearningColors.heading.withValues(alpha: 0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasGoal
          ? _buildActiveGoalContent(context, trimmedGoal)
          : _buildEmptyStateContent(context),
    );
  }

  /// Builds the active goal content when a valid goal title is present.
  Widget _buildActiveGoalContent(BuildContext context, String goal) {
    final bool isValidPercent = completionPercent != null &&
        completionPercent! >= 0 &&
        completionPercent! <= 100;
    final bool isInvalidPercent = completionPercent != null &&
        (completionPercent! < 0 || completionPercent! > 100);

    final String? trimmedCommitment = weeklyCommitmentText?.trim();
    final bool hasCommitment =
        trimmedCommitment != null && trimmedCommitment.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderRow(isValidPercent, isInvalidPercent),
        const SizedBox(height: 10.0),
        Text(
          goal,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: LearningColors.heading,
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12.0),
        _buildProgressBar(isValidPercent, isInvalidPercent),
        if (hasCommitment) ...[
          const SizedBox(height: 12.0),
          _buildCommitmentRow(trimmedCommitment),
        ],
        if (onResume != null) ...[
          const SizedBox(height: 16.0),
          _buildResumeButton(),
        ],
      ],
    );
  }

  /// Top row with section label icon and percentage text.
  Widget _buildHeaderRow(bool isValidPercent, bool isInvalidPercent) {
    return Row(
      children: [
        Container(
          width: 28.0,
          height: 28.0,
          decoration: BoxDecoration(
            color: LearningColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.track_changes_rounded,
            size: 16.0,
            color: LearningColors.primary,
          ),
        ),
        const SizedBox(width: 8.0),
        const Expanded(
          child: Text(
            'ACTIVE GOAL',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: LearningColors.secondaryText,
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        _buildPercentageLabel(isValidPercent, isInvalidPercent),
      ],
    );
  }

  /// Percentage label displayed on the right of the header row.
  Widget _buildPercentageLabel(bool isValidPercent, bool isInvalidPercent) {
    if (isValidPercent) {
      return Text(
        '$completionPercent%',
        style: const TextStyle(
          color: LearningColors.primary,
          fontSize: 15.0,
          fontWeight: FontWeight.w700,
        ),
      );
    } else if (isInvalidPercent) {
      return Text(
        'Invalid progress',
        style: TextStyle(
          color: Colors.amber.shade800,
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      return const Text(
        'Progress unavailable',
        style: TextStyle(
          color: LearningColors.secondaryText,
          fontSize: 12.0,
          fontStyle: FontStyle.italic,
        ),
      );
    }
  }

  /// Visual progress bar with semantic descriptions and out-of-range protection.
  Widget _buildProgressBar(bool isValidPercent, bool isInvalidPercent) {
    if (isValidPercent) {
      final double progressFraction = completionPercent! / 100.0;
      return Semantics(
        label: 'Goal progress: $completionPercent%',
        value: '$completionPercent%',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: progressFraction,
            minHeight: 8.0,
            backgroundColor: LearningColors.primary.withValues(alpha: 0.15),
            valueColor:
                const AlwaysStoppedAnimation<Color>(LearningColors.primary),
          ),
        ),
      );
    }

    final String semanticsLabel = isInvalidPercent
        ? 'Invalid goal progress value'
        : 'Goal progress unavailable';

    return Semantics(
      label: semanticsLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: Container(
          height: 8.0,
          decoration: BoxDecoration(
            color: LearningColors.secondaryText.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }

  /// Row showing the weekly learning commitment summary.
  Widget _buildCommitmentRow(String commitment) {
    return Row(
      children: [
        const Icon(
          Icons.schedule_outlined,
          size: 15.0,
          color: LearningColors.secondaryText,
        ),
        const SizedBox(width: 6.0),
        Expanded(
          child: Text(
            commitment,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: LearningColors.secondaryText,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Resume button action invoking caller-injected callback.
  Widget _buildResumeButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onResume,
        icon: const Icon(Icons.play_arrow_rounded, size: 20.0),
        label: const Text(
          'Resume Learning',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.0,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: LearningColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          minimumSize: const Size.fromHeight(48.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  /// Empty state rendered when goalTitle is null, empty, or whitespace-only.
  Widget _buildEmptyStateContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 28.0,
              height: 28.0,
              decoration: BoxDecoration(
                color: LearningColors.secondaryText.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.track_changes_outlined,
                size: 16.0,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(width: 8.0),
            const Expanded(
              child: Text(
                'LEARNING GOAL',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: LearningColors.secondaryText,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        const Text(
          'No active learning goal',
          style: TextStyle(
            color: LearningColors.heading,
            fontSize: 15.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4.0),
        const Text(
          'Set a goal to track your progress and resume your learning journey.',
          style: TextStyle(
            color: LearningColors.secondaryText,
            fontSize: 13.0,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
