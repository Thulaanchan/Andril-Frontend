import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';
import '../domain/social_candidate.dart';

/// Screen S15: Saved Profiles / Bookmarked Candidates (SOC-02).
///
/// Follows M5-FE-S15-UI-01 requirements:
/// - Renders grid/list of saved candidate cards with photo, name, age, and location.
/// - Provides open profile detail callback and remove bookmark callback.
/// - Houses loading, empty, access-denied, and error presentation states.
/// - Fails closed: Does not claim persistent server synchronization until backend bookmark contracts are activated.
/// - Clears private state upon session transitions.
/// - Responsive layout down to 320dp and under accessibility text scaling (1.3).
class SocialSavedProfilesScreen extends StatelessWidget {
  final List<SocialCandidate> savedProfiles;
  final bool isLoading;
  final bool isAccessDenied;
  final String? errorMessage;
  final VoidCallback? onBack;
  final ValueChanged<SocialCandidate>? onOpenProfile;
  final ValueChanged<SocialCandidate>? onRemoveProfile;
  final VoidCallback? onExploreMore;

  const SocialSavedProfilesScreen({
    super.key,
    this.savedProfiles = const [],
    this.isLoading = false,
    this.isAccessDenied = false,
    this.errorMessage,
    this.onBack,
    this.onOpenProfile,
    this.onRemoveProfile,
    this.onExploreMore,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AndrilSocialColors.cream,
      appBar: AppBar(
        backgroundColor: AndrilSocialColors.cream,
        foregroundColor: AndrilSocialColors.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Back',
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Saved Profiles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AndrilSocialColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isAccessDenied) {
      return _buildAccessDeniedView();
    }

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AndrilSocialColors.royalPurple,
        ),
      );
    }

    if (errorMessage != null) {
      return _buildErrorView();
    }

    if (savedProfiles.isEmpty) {
      return _buildEmptyView();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;

        return Column(
          children: [
            // Notice: In-session bookmark notice
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AndrilSocialColors.faintPurple,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AndrilSocialColors.royalPurple.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AndrilSocialColors.royalPurple,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bookmarks are retained during your active session.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AndrilSocialColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Profile Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: savedProfiles.length,
                itemBuilder: (context, index) {
                  final candidate = savedProfiles[index];
                  return _SavedProfileCard(
                    candidate: candidate,
                    onTap: () => onOpenProfile?.call(candidate),
                    onRemove: () => onRemoveProfile?.call(candidate),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_border_rounded,
              size: 64,
              color: AndrilSocialColors.copper,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Saved Profiles Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AndrilSocialColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When you bookmark candidates while discovering people, they will be listed here for quick review.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AndrilSocialColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            if (onExploreMore != null)
              ElevatedButton(
                onPressed: onExploreMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AndrilSocialColors.royalPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(140, 48),
                ),
                child: const Text('Explore People'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: AndrilSocialColors.royalPurple,
            ),
            SizedBox(height: 16),
            Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AndrilSocialColors.ink,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Signed-in module authorization is required to view saved profiles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AndrilSocialColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Profiles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AndrilSocialColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'An error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AndrilSocialColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedProfileCard extends StatelessWidget {
  final SocialCandidate candidate;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _SavedProfileCard({
    required this.candidate,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = candidate.primaryPhotoUrl;

    return Semantics(
      label: '${candidate.displayName}, ${candidate.age}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Area
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallback(),
                      )
                    else
                      _buildFallback(),
                    // Remove bookmark button overlay
                    Positioned(
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black.withValues(alpha: 0.45),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.bookmark_remove_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          tooltip: 'Remove',
                          onPressed: onRemove,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Card Details
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${candidate.displayName}, ${candidate.age}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AndrilSocialColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (candidate.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: Colors.blueAccent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      candidate.locationName ??
                          (candidate.approximateDistanceKm != null
                              ? '${candidate.approximateDistanceKm} km away'
                              : 'Online'),
                      style: TextStyle(
                        fontSize: 11,
                        color: AndrilSocialColors.ink.withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: AndrilSocialColors.faintPurple,
      child: Center(
        child: Text(
          candidate.displayName.isNotEmpty
              ? candidate.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AndrilSocialColors.royalPurple,
          ),
        ),
      ),
    );
  }
}
