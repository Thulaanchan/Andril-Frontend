import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';

/// Variant types for empty discovery presentation.
enum SocialDiscoveryEmptyType {
  /// S26: No candidates match current active filter criteria.
  noCandidates,

  /// S83: All available candidates in the active queue have been reviewed.
  endOfDeck,
}

/// Screens S26 (No People Found) and S83 (End of Discovery).
///
/// Follows M5 requirements:
/// - Explicitly distinguishes exhausted queue from restrictive filter criteria.
/// - S26: Provides clear filter adjustment action to expand candidate pool.
/// - S83: Acknowledges daily discovery completion without manufacturing infinite candidates.
/// - Responsive layout and accessible action buttons across all screen widths.
class SocialDiscoveryEmptyState extends StatelessWidget {
  final SocialDiscoveryEmptyType type;
  final VoidCallback? onOpenFilters;
  final VoidCallback? onRefresh;

  const SocialDiscoveryEmptyState({
    super.key,
    required this.type,
    this.onOpenFilters,
    this.onRefresh,
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
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: _badgeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconData,
                color: _iconColor,
                size: 42,
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

            // Subtitle
            Text(
              _bodyText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),

            // Primary Action
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: _primaryAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AndrilSocialColors.royalPurple,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Secondary Action
            if (_hasSecondaryAction) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 220,
                child: TextButton(
                  onPressed: _secondaryAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AndrilSocialColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _secondaryButtonText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _badgeColor => switch (type) {
        SocialDiscoveryEmptyType.noCandidates => AndrilSocialColors.copper.withValues(alpha: 0.12),
        SocialDiscoveryEmptyType.endOfDeck => AndrilSocialColors.royalPurple.withValues(alpha: 0.12),
      };

  Color get _iconColor => switch (type) {
        SocialDiscoveryEmptyType.noCandidates => AndrilSocialColors.copper,
        SocialDiscoveryEmptyType.endOfDeck => AndrilSocialColors.royalPurple,
      };

  IconData get _iconData => switch (type) {
        SocialDiscoveryEmptyType.noCandidates => Icons.search_off_rounded,
        SocialDiscoveryEmptyType.endOfDeck => Icons.done_all_rounded,
      };

  String get _titleText => switch (type) {
        SocialDiscoveryEmptyType.noCandidates => 'No One Nearby Right Now',
        SocialDiscoveryEmptyType.endOfDeck => 'You\'re All Caught Up',
      };

  String get _bodyText => switch (type) {
        SocialDiscoveryEmptyType.noCandidates =>
          'We couldn\'t find anyone matching your current filters. Try expanding your search distance or relaxing preference settings.',
        SocialDiscoveryEmptyType.endOfDeck =>
          'You\'ve reviewed all available discovery profiles for today. Check back later as new members join and update their profiles!',
      };

  String get _primaryButtonText => switch (type) {
        SocialDiscoveryEmptyType.noCandidates => 'Adjust Filters',
        SocialDiscoveryEmptyType.endOfDeck => 'Refresh Feed',
      };

  VoidCallback? get _primaryAction => switch (type) {
        SocialDiscoveryEmptyType.noCandidates => onOpenFilters ?? onRefresh,
        SocialDiscoveryEmptyType.endOfDeck => onRefresh ?? onOpenFilters,
      };

  bool get _hasSecondaryAction => switch (type) {
        SocialDiscoveryEmptyType.noCandidates => onRefresh != null && onOpenFilters != null,
        SocialDiscoveryEmptyType.endOfDeck => onOpenFilters != null,
      };

  String get _secondaryButtonText => switch (type) {
        SocialDiscoveryEmptyType.noCandidates => 'Refresh Feed',
        SocialDiscoveryEmptyType.endOfDeck => 'Adjust Filters',
      };

  VoidCallback? get _secondaryAction => switch (type) {
        SocialDiscoveryEmptyType.noCandidates => onRefresh,
        SocialDiscoveryEmptyType.endOfDeck => onOpenFilters,
      };
}
