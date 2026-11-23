import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';
import '../widgets/learning_home_action_grid.dart';
import '../widgets/learning_home_header.dart';
import '../widgets/learning_progress_card.dart';

/// Cohesive vertical dashboard screen assembling the ANDRIL Learning Home.
///
/// Composes the three presentation bricks:
/// 1. [LearningHomeHeader] — learner greeting, display name, avatar, and notification action.
/// 2. [LearningProgressCard] — active learning goal, completion progress, weekly commitment.
/// 3. [LearningHomeActionGrid] — fail-closed quick action shortcuts.
///
/// Architecture & Security Constraints (BRD §04.3, §05 CF-01, CF-02, CF-03, §06, §15, §17):
/// - Purely presentational; receives all state and callbacks via constructor arguments.
/// - Does NOT execute direct navigation (context.go, Navigator.push).
/// - Does NOT query Supabase, read session tokens, or verify M2 authorization.
/// - Does NOT calculate fake XP, daily streaks, or unverified growth achievements.
/// - Fully responsive across 320dp, 360dp, 412dp, and tablet viewports with dynamic text scaling.
class LearningHomeScreen extends StatelessWidget {
  /// The learner's display name to show in the header.
  final String displayName;

  /// Optional greeting phrase displayed in the header.
  ///
  /// Defaults to 'Welcome back'.
  final String greeting;

  /// Optional avatar image provider for the learner.
  final ImageProvider<Object>? avatarImage;

  /// Optional presentation status badge text (e.g. 'Active Learner').
  final String? statusText;

  /// Active learning goal title to display on the progress card.
  final String? goalTitle;

  /// Completion percentage from 0 to 100 for the active goal.
  final int? completionPercent;

  /// Caller-supplied summary of the weekly learning commitment (e.g. '3 hrs/week').
  final String? weeklyCommitmentText;

  /// The list of shortcut actions to display in the grid.
  final List<LearningHomeActionItem> actions;

  /// Section heading title for the action grid.
  ///
  /// Defaults to 'My Learning Hub'.
  final String actionsTitle;

  /// Optional callback invoked when the header notification action is tapped.
  final VoidCallback? onNotificationTap;

  /// Optional callback invoked when the progress card 'Resume' button is tapped.
  final VoidCallback? onResume;

  /// Whether the screen is in a loading state.
  final bool isLoading;

  /// Whether module access is denied by the parent authorization policy.
  final bool isAccessDenied;

  /// Optional error message to display in a recoverable error state.
  final String? errorMessage;

  /// Optional retry callback invoked when retrying from an error state.
  final VoidCallback? onRetry;

  /// Creates an immutable [LearningHomeScreen].
  const LearningHomeScreen({
    super.key,
    required this.displayName,
    this.greeting = 'Welcome back',
    this.avatarImage,
    this.statusText,
    this.goalTitle,
    this.completionPercent,
    this.weeklyCommitmentText,
    this.actions = const [],
    this.actionsTitle = 'My Learning Hub',
    this.onNotificationTap,
    this.onResume,
    this.isLoading = false,
    this.isAccessDenied = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    final trimmedError = errorMessage?.trim();
    if (trimmedError != null && trimmedError.isNotEmpty) {
      return _buildErrorState(trimmedError);
    }

    if (isAccessDenied) {
      return _buildAccessDeniedState();
    }

    return _buildContent(context);
  }

  /// Normal ready/content state assembling the three dashboard bricks.
  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LearningHomeHeader(
            displayName: displayName,
            greeting: greeting,
            avatarImage: avatarImage,
            statusText: statusText,
            onNotificationTap: onNotificationTap,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: LearningProgressCard(
              goalTitle: goalTitle,
              completionPercent: completionPercent,
              weeklyCommitmentText: weeklyCommitmentText,
              onResume: onResume,
            ),
          ),
          LearningHomeActionGrid(
            actions: actions,
            title: actionsTitle,
          ),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  /// Presentation loading state.
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: LearningColors.primary,
          ),
          SizedBox(height: 16.0),
          Text(
            'Loading Learning Home...',
            style: TextStyle(
              color: LearningColors.secondaryText,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Presentation error state with optional retry.
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: LearningColors.primary,
              size: 48.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: LearningColors.heading,
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18.0),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Presentation access-denied state preventing disclosure of private data.
  Widget _buildAccessDeniedState() {
    return const Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: LearningColors.secondaryText,
              size: 48.0,
            ),
            SizedBox(height: 16.0),
            Text(
              'Access Restricted',
              style: TextStyle(
                color: LearningColors.heading,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'Learning Home requires active module activation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LearningColors.secondaryText,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
