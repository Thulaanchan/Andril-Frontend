import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';

/// Variant status types for discovery operational feedback.
enum SocialDiscoveryStatusType {
  /// S84: Network or operational error loading discovery feed.
  networkError,

  /// S85: Inspected profile is no longer available or has updated visibility.
  profileUnavailable,

  /// Session unauthenticated or user lacks adult Social opt-in.
  accessDenied,

  /// Backend service is temporarily dormant or preparing.
  servicePreparing,
}

/// Screens S84 (Discovery Error) and S85 (Profile Unavailable).
///
/// Follows M5 requirements:
/// - S84: Friendly error state with safe retry action, without exposing raw exception traces.
/// - S85: Sanitized profile unavailable state, preserving other members' privacy.
/// - Fail-closed: Never exposes raw stack traces, DB keys, or confidential member accounts.
/// - Responsive layout and accessible action buttons across all screen widths.
class SocialDiscoveryStatusView extends StatelessWidget {
  final SocialDiscoveryStatusType type;
  final String? customMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onReturn;

  const SocialDiscoveryStatusView({
    super.key,
    required this.type,
    this.customMessage,
    this.onRetry,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon illustration
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _badgeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconData,
                color: _iconColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

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

            // Description
            Text(
              customMessage ?? _bodyText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: _actionCallback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _buttonText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _badgeColor => switch (type) {
        SocialDiscoveryStatusType.networkError => const Color(0xFFE63946).withValues(alpha: 0.12),
        SocialDiscoveryStatusType.profileUnavailable => const Color(0xFF9E9E9E).withValues(alpha: 0.14),
        SocialDiscoveryStatusType.accessDenied => const Color(0xFFE63946).withValues(alpha: 0.12),
        SocialDiscoveryStatusType.servicePreparing => AndrilSocialColors.copper.withValues(alpha: 0.14),
      };

  Color get _iconColor => switch (type) {
        SocialDiscoveryStatusType.networkError => const Color(0xFFE63946),
        SocialDiscoveryStatusType.profileUnavailable => const Color(0xFF6B7280),
        SocialDiscoveryStatusType.accessDenied => const Color(0xFFE63946),
        SocialDiscoveryStatusType.servicePreparing => AndrilSocialColors.copper,
      };

  IconData get _iconData => switch (type) {
        SocialDiscoveryStatusType.networkError => Icons.cloud_off_rounded,
        SocialDiscoveryStatusType.profileUnavailable => Icons.person_off_outlined,
        SocialDiscoveryStatusType.accessDenied => Icons.lock_outline_rounded,
        SocialDiscoveryStatusType.servicePreparing => Icons.construction_rounded,
      };

  String get _titleText => switch (type) {
        SocialDiscoveryStatusType.networkError => 'Unable to Load Discovery',
        SocialDiscoveryStatusType.profileUnavailable => 'Profile Unavailable',
        SocialDiscoveryStatusType.accessDenied => 'Access Restricted',
        SocialDiscoveryStatusType.servicePreparing => 'Discovery Service Preparing',
      };

  String get _bodyText => switch (type) {
        SocialDiscoveryStatusType.networkError =>
          'We encountered an issue communicating with the discovery service. Please check your connection and try again.',
        SocialDiscoveryStatusType.profileUnavailable =>
          'This profile is no longer available or has updated their discovery visibility preferences.',
        SocialDiscoveryStatusType.accessDenied =>
          'Adult verification and an active Social opt-in are required to browse discovery candidates.',
        SocialDiscoveryStatusType.servicePreparing =>
          'The discovery feed is currently preparing recommendations. Please check back in a few moments.',
      };

  Color get _buttonColor => switch (type) {
        SocialDiscoveryStatusType.networkError => AndrilSocialColors.royalPurple,
        SocialDiscoveryStatusType.profileUnavailable => AndrilSocialColors.ink,
        SocialDiscoveryStatusType.accessDenied => AndrilSocialColors.royalPurple,
        SocialDiscoveryStatusType.servicePreparing => AndrilSocialColors.copper,
      };

  String get _buttonText => switch (type) {
        SocialDiscoveryStatusType.networkError => 'Retry',
        SocialDiscoveryStatusType.profileUnavailable => 'Back to Discovery',
        SocialDiscoveryStatusType.accessDenied => 'Check Access',
        SocialDiscoveryStatusType.servicePreparing => 'Refresh',
      };

  VoidCallback? get _actionCallback => switch (type) {
        SocialDiscoveryStatusType.networkError => onRetry,
        SocialDiscoveryStatusType.profileUnavailable => onReturn,
        SocialDiscoveryStatusType.accessDenied => onRetry ?? onReturn,
        SocialDiscoveryStatusType.servicePreparing => onRetry,
      };
}
