import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';

/// Feedback variant for interest interactions (S11, S54, S55).
enum SocialInterestFeedbackType {
  /// S11: Authoritative Interest Sent confirmation.
  sent,

  /// S54: Interest already pending / unreciprocated state.
  pending,

  /// S55: Target profile is unavailable or inactive.
  unavailable,
}

/// Screens S11 / S54 / S55: Interest Decision Feedback.
///
/// Follows M5 requirements:
/// - Explicitly distinguishes interest sent, pending, and unavailable states.
/// - S11: Confirms directional interest sent without fabricating mutual match or chat channels.
/// - S54: Explains pending standing safely without revealing confidential member decisions.
/// - S55: Gracefully presents unavailable profiles without exposing private member data.
/// - Responsive layout and accessible button targets down to 320dp.
class SocialInterestFeedbackSheet extends StatelessWidget {
  final SocialInterestFeedbackType type;
  final String candidateName;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final String? customMessage;

  const SocialInterestFeedbackSheet({
    super.key,
    required this.type,
    required this.candidateName,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.customMessage,
  });

  /// Presents the interest feedback as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required SocialInterestFeedbackType type,
    required String candidateName,
    VoidCallback? onPrimaryAction,
    VoidCallback? onSecondaryAction,
    String? customMessage,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SocialInterestFeedbackSheet(
        type: type,
        candidateName: candidateName,
        onPrimaryAction: onPrimaryAction,
        onSecondaryAction: onSecondaryAction,
        customMessage: customMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AndrilSocialColors.canvasCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AndrilSocialColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Feedback Icon Badge
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _badgeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconData,
                color: _iconColor,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            _titleText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AndrilSocialColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Subtitle / Body
          Text(
            customMessage ?? _bodyText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

          // Primary Action Button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).maybePop();
              onPrimaryAction?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryButtonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              _primaryButtonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (onSecondaryAction != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(context).maybePop();
                onSecondaryAction?.call();
              },
              style: TextButton.styleFrom(
                foregroundColor: AndrilSocialColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _secondaryButtonText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _badgeColor => switch (type) {
        SocialInterestFeedbackType.sent => AndrilSocialColors.royalPurple.withValues(alpha: 0.12),
        SocialInterestFeedbackType.pending => AndrilSocialColors.copper.withValues(alpha: 0.14),
        SocialInterestFeedbackType.unavailable => const Color(0xFF9E9E9E).withValues(alpha: 0.14),
      };

  Color get _iconColor => switch (type) {
        SocialInterestFeedbackType.sent => AndrilSocialColors.royalPurple,
        SocialInterestFeedbackType.pending => AndrilSocialColors.copper,
        SocialInterestFeedbackType.unavailable => const Color(0xFF6B7280),
      };

  IconData get _iconData => switch (type) {
        SocialInterestFeedbackType.sent => Icons.favorite_rounded,
        SocialInterestFeedbackType.pending => Icons.schedule_rounded,
        SocialInterestFeedbackType.unavailable => Icons.person_off_outlined,
      };

  String get _titleText => switch (type) {
        SocialInterestFeedbackType.sent => 'Interest Sent!',
        SocialInterestFeedbackType.pending => 'Interest Pending',
        SocialInterestFeedbackType.unavailable => 'Profile Unavailable',
      };

  String get _bodyText => switch (type) {
        SocialInterestFeedbackType.sent =>
          'We\'ve notified $candidateName that you like them. If they like you back, you\'ll form a mutual match!',
        SocialInterestFeedbackType.pending =>
          'You already expressed interest in $candidateName. We\'ll let you know as soon as they decide.',
        SocialInterestFeedbackType.unavailable =>
          'This profile is no longer available or has recently updated their discovery visibility preferences.',
      };

  Color get _primaryButtonColor => switch (type) {
        SocialInterestFeedbackType.sent => AndrilSocialColors.royalPurple,
        SocialInterestFeedbackType.pending => AndrilSocialColors.copper,
        SocialInterestFeedbackType.unavailable => AndrilSocialColors.ink,
      };

  String get _primaryButtonText => switch (type) {
        SocialInterestFeedbackType.sent => 'Keep Exploring',
        SocialInterestFeedbackType.pending => 'Got It',
        SocialInterestFeedbackType.unavailable => 'Continue Exploring',
      };

  String get _secondaryButtonText => 'View Sent Likes';
}
