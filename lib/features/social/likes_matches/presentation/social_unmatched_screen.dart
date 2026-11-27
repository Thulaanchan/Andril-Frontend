import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';

/// Screen S57: Unmatched / Revoked Connection State.
///
/// Follows M5 requirements:
/// - Authoritative successful unmatch presentation.
/// - Demonstrates revoked communication standing: chat channels closed.
/// - Clear return navigation to Connections feed.
/// - Fails closed: Prevents obsolete match authorization or orphaned message routing.
class SocialUnmatchedScreen extends StatelessWidget {
  final String targetName;
  final VoidCallback? onReturnToConnections;

  const SocialUnmatchedScreen({
    super.key,
    required this.targetName,
    this.onReturnToConnections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AndrilSocialColors.cream,
      appBar: AppBar(
        backgroundColor: AndrilSocialColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AndrilSocialColors.ink,
          tooltip: 'Back',
          onPressed: onReturnToConnections ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon illustration
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3EDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.heart_broken_rounded,
                    color: AndrilSocialColors.copper,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Connection Removed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AndrilSocialColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'You and $targetName are no longer connected. Direct messaging has been closed and removed from your active conversations.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // Return to Connections Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onReturnToConnections ?? () => Navigator.of(context).maybePop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AndrilSocialColors.royalPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Return to Connections',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
