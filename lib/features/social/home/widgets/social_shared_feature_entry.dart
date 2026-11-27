import 'package:flutter/material.dart';
import '../../../../app/themes/social/social_theme.dart';

/// Supported cross-module shared feature contracts and handoffs.
enum SocialSharedFeatureType {
  /// M1 Diary: Personal reflections and emotional wellbeing journal.
  diary,

  /// M2 Identity: Account settings, security, and global privacy controls.
  accountSettings,

  /// M4 Messaging: Direct chat channels for confirmed mutual matches.
  chat,

  /// M4 Notifications: Global application and social activity notifications.
  notifications,

  /// M4 Rich Media: MoodTone and audio/video calls during active sessions.
  moodTone,

  /// M4 Virtual Economy: Virtual gifts exchange within verified channels.
  virtualGifts,

  /// M6 Safety: User reporting, content moderation, and safety boundaries.
  safetyReporting,
}

/// Metadata describing a shared feature and its governing module contract.
class SocialSharedFeatureInfo {
  final SocialSharedFeatureType type;
  final String title;
  final String moduleOwner;
  final String description;
  final IconData icon;

  const SocialSharedFeatureInfo({
    required this.type,
    required this.title,
    required this.moduleOwner,
    required this.description,
    required this.icon,
  });

  static SocialSharedFeatureInfo infoFor(SocialSharedFeatureType type) =>
      switch (type) {
        SocialSharedFeatureType.diary => const SocialSharedFeatureInfo(
            type: SocialSharedFeatureType.diary,
            title: 'Andril Diary',
            moduleOwner: 'M1 Personal Diary',
            description:
                'Andril Diary is your private space for emotional reflections. '
                'Access is managed through your personal journal dashboard.',
            icon: Icons.auto_stories_outlined,
          ),
        SocialSharedFeatureType.accountSettings =>
          const SocialSharedFeatureInfo(
            type: SocialSharedFeatureType.accountSettings,
            title: 'Account & Privacy Settings',
            moduleOwner: 'M2 Identity & Security',
            description:
                'Global privacy preferences, account verification, and security controls '
                'are managed by Andril Account Services.',
            icon: Icons.shield_outlined,
          ),
        SocialSharedFeatureType.chat => const SocialSharedFeatureInfo(
            type: SocialSharedFeatureType.chat,
            title: 'Direct Messaging',
            moduleOwner: 'M4 Communication Services',
            description:
                'Direct messaging is available for confirmed mutual matches. '
                'Connect with members to unlock verified messaging channels.',
            icon: Icons.chat_bubble_outline_rounded,
          ),
        SocialSharedFeatureType.notifications => const SocialSharedFeatureInfo(
            type: SocialSharedFeatureType.notifications,
            title: 'Notifications Hub',
            moduleOwner: 'M4 Communication Services',
            description:
                'Notification preferences and alert delivery are managed through '
                'the global notifications coordinator.',
            icon: Icons.notifications_none_rounded,
          ),
        SocialSharedFeatureType.moodTone => const SocialSharedFeatureInfo(
            type: SocialSharedFeatureType.moodTone,
            title: 'MoodTone & Calls',
            moduleOwner: 'M4 Rich Communication',
            description:
                'MoodTone emotional indicators and voice/video calling are activated '
                'during live sessions with matched connections.',
            icon: Icons.graphic_eq_rounded,
          ),
        SocialSharedFeatureType.virtualGifts => const SocialSharedFeatureInfo(
            type: SocialSharedFeatureType.virtualGifts,
            title: 'Virtual Gifts',
            moduleOwner: 'M4 Economy & Rewards',
            description:
                'Virtual gift interactions are supported in active chat conversations '
                'with verified connections.',
            icon: Icons.card_giftcard_rounded,
          ),
        SocialSharedFeatureType.safetyReporting =>
          const SocialSharedFeatureInfo(
            type: SocialSharedFeatureType.safetyReporting,
            title: 'Community Safety & Reporting',
            moduleOwner: 'M6 Community Safety',
            description:
                'Member safety, profile reporting, and content moderation are enforced '
                'by the independent M6 Trust & Safety framework.',
            icon: Icons.flag_outlined,
          ),
      };
}

/// Helper and dialog provider for shared-feature handoffs.
///
/// Follows Task 149 Cross-Module Boundary Governance:
/// - Reuses authoritative callbacks when supplied by the parent application router.
/// - Does not invent mock success, fake API handoffs, or unapproved shared routes.
/// - Fails closed: presents explicit unavailable notice if shared feature is unconfigured.
class SocialSharedFeatureHandoff {
  /// Dispatches or presents handoff for an approved shared feature.
  static void invokeHandoff({
    required BuildContext context,
    required SocialSharedFeatureType type,
    VoidCallback? onHandoff,
  }) {
    if (onHandoff != null) {
      onHandoff();
      return;
    }

    showUnavailableDialog(context, type);
  }

  /// Presents an approved modal dialog explaining shared feature status and ownership.
  static void showUnavailableDialog(
    BuildContext context,
    SocialSharedFeatureType type,
  ) {
    final info = SocialSharedFeatureInfo.infoFor(type);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AndrilSocialColors.faintPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                info.icon,
                size: 20,
                color: AndrilSocialColors.royalPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                info.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AndrilSocialColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AndrilSocialColors.canvasCream,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AndrilSocialColors.border),
              ),
              child: Text(
                info.moduleOwner,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AndrilSocialColors.copper,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              info.description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
