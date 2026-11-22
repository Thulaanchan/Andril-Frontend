import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';

/// Presentation-only header widget for the ANDRIL Learning Home dashboard.
///
/// Displays a learner greeting, the current Learning profile display name,
/// an optional avatar image with safe fallback, an optional status label,
/// and an optional notification action.
///
/// Architecture & Security Constraints (BRD §04.3, §05 CF-01, CF-03, §06):
/// - Purely presentational; receives all values via constructor arguments.
/// - Does NOT access M2 authentication state, session tokens, or account identity.
/// - Does NOT initiate network requests or construct remote avatar URLs.
/// - Does NOT invent or calculate XP, daily streaks, or account activation status.
/// - Strictly scoped to the Learning module; no access to Social or Hobbies data.
/// - Designed for responsive constraints down to 320dp and dynamic text scaling.
class LearningHomeHeader extends StatelessWidget {
  /// The learner's display name to show in the header.
  ///
  /// If empty or whitespace-only, falls back to a neutral 'Learner' label.
  final String displayName;

  /// The greeting phrase displayed above the learner's name.
  ///
  /// Defaults to 'Welcome back'.
  final String greeting;

  /// Optional caller-supplied avatar image provider.
  ///
  /// When null or when image loading fails, falls back to a neutral icon placeholder.
  final ImageProvider<Object>? avatarImage;

  /// Optional presentation-only status label displayed below the name.
  ///
  /// Only rendered when non-null and non-empty after trimming.
  final String? statusText;

  /// Optional callback invoked when the notification action icon is tapped.
  ///
  /// When null, the notification action button is not rendered.
  final VoidCallback? onNotificationTap;

  /// Outer padding for the header container.
  ///
  /// Defaults to `EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)`.
  final EdgeInsetsGeometry padding;

  /// Creates an immutable [LearningHomeHeader].
  const LearningHomeHeader({
    super.key,
    required this.displayName,
    this.greeting = 'Welcome back',
    this.avatarImage,
    this.statusText,
    this.onNotificationTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    final String trimmedName = displayName.trim();
    final String effectiveName =
        trimmedName.isNotEmpty ? trimmedName : 'Learner';

    final String? trimmedStatus = statusText?.trim();
    final bool hasStatus = trimmedStatus != null && trimmedStatus.isNotEmpty;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(effectiveName),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LearningColors.secondaryText,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  effectiveName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LearningColors.heading,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasStatus) ...[
                  const SizedBox(height: 4.0),
                  _buildStatusBadge(trimmedStatus),
                ],
              ],
            ),
          ),
          if (onNotificationTap != null) ...[
            const SizedBox(width: 8.0),
            _buildNotificationAction(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String effectiveName) {
    return Semantics(
      label: 'Profile avatar for $effectiveName',
      image: true,
      child: CircleAvatar(
        radius: 22.0,
        backgroundColor: LearningColors.primary.withValues(alpha: 0.1),
        foregroundImage: avatarImage,
        onForegroundImageError: avatarImage != null ? (_, __) {} : null,
        child: const Icon(
          Icons.person_rounded,
          color: LearningColors.primary,
          size: 24.0,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: LearningColors.waveAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: LearningColors.heading,
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotificationAction() {
    return Semantics(
      label: 'Learning notifications',
      button: true,
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined),
        tooltip: 'Notifications',
        onPressed: onNotificationTap,
        color: LearningColors.heading,
        iconSize: 24.0,
        constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
        splashRadius: 24.0,
      ),
    );
  }
}
