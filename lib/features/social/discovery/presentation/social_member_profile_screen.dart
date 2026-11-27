import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';
import '../domain/social_candidate.dart';

/// Screen S10: Member Profile Expanded Inspection (SOC-02).
///
/// Follows M5-FE-S10-UI-01 requirements:
/// - Renders rich profile photo presentation with carousel / fallback.
/// - Presents verified badge, display name, age, coarse location, and distance pill.
/// - Presents "About Me" biography, "Interests" chips, and "Looking For" connection goals.
/// - Provides Report and Block entry points via top overflow menu without duplicating M6 functionality.
/// - Provides bottom action bar with Pass, Bookmark / Save, and Like callbacks.
/// - Fails closed: Prevents other-module identity disclosure, raw personality responses, or precise GPS coordinates.
/// - Responsive layout down to 320dp and under accessibility text scaling (1.3).
class SocialMemberProfileScreen extends StatefulWidget {
  final SocialCandidate candidate;
  final VoidCallback? onBack;
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;
  final bool isBookmarked;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final ValueChanged<int>? onPhotoTap;
  final VoidCallback? onOpenGallery;

  const SocialMemberProfileScreen({
    super.key,
    required this.candidate,
    this.onBack,
    this.onPass,
    this.onLike,
    this.onBookmark,
    this.isBookmarked = false,
    this.onReport,
    this.onBlock,
    this.onPhotoTap,
    this.onOpenGallery,
  });

  @override
  State<SocialMemberProfileScreen> createState() =>
      _SocialMemberProfileScreenState();
}

class _SocialMemberProfileScreenState extends State<SocialMemberProfileScreen> {
  int _activePhotoIndex = 0;

  SocialCandidate get _candidate => widget.candidate;

  @override
  Widget build(BuildContext context) {
    final photos = _candidate.photoUrls;

    return Scaffold(
      backgroundColor: AndrilSocialColors.cream,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Scrollable Content
            CustomScrollView(
              slivers: [
                // Collapsible Photo Header
                SliverAppBar(
                  expandedHeight: 380,
                  pinned: true,
                  backgroundColor: AndrilSocialColors.cream,
                  foregroundColor: Colors.white,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        tooltip: 'Back',
                        onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.45),
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Options',
                          onSelected: (value) {
                            if (value == 'report') {
                              widget.onReport?.call();
                            } else if (value == 'block') {
                              widget.onBlock?.call();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  Icon(Icons.flag_outlined, size: 20, color: Color(0xFFE63946)),
                                  SizedBox(width: 10),
                                  Text('Report Profile'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'block',
                              child: Row(
                                children: [
                                  Icon(Icons.block_rounded, size: 20, color: AndrilSocialColors.ink),
                                  SizedBox(width: 10),
                                  Text('Block Member'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photos.isNotEmpty)
                          PageView.builder(
                            itemCount: photos.length,
                            onPageChanged: (index) {
                              setState(() {
                                _activePhotoIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  if (widget.onPhotoTap != null) {
                                    widget.onPhotoTap!(index);
                                  } else {
                                    widget.onOpenGallery?.call();
                                  }
                                },
                                child: Image.network(
                                  photos[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                                ),
                              );
                            },
                          )
                        else
                          _buildAvatarFallback(),
                        // Top gradient overlay for app bar readability
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Bottom gradient scrim
                        const Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 80,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AndrilSocialColors.cream,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Photo gallery badge if multiple photos
                        if (photos.length > 1)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => widget.onOpenGallery?.call(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.photo_library_outlined, size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${photos.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Photo dots indicator if multiple photos
                        if (photos.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(photos.length, (index) {
                                final isActive = index == _activePhotoIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: isActive ? 16 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AndrilSocialColors.royalPurple
                                        : Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Profile Details Sections
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Verified Badge
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${_candidate.displayName}, ${_candidate.age}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AndrilSocialColors.ink,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            if (_candidate.isVerified) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.blueAccent,
                                size: 24,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Location and Distance Row
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (_candidate.locationName != null &&
                                _candidate.locationName!.isNotEmpty)
                              _buildPill(
                                icon: Icons.location_on_outlined,
                                label: _candidate.locationName!,
                              ),
                            if (_candidate.approximateDistanceKm != null)
                              _buildPill(
                                icon: Icons.near_me_outlined,
                                label: '${_candidate.approximateDistanceKm} km away',
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // About Me Section
                        if (_candidate.biography != null &&
                            _candidate.biography!.isNotEmpty) ...[
                          const Text(
                            'About Me',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AndrilSocialColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _candidate.biography!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AndrilSocialColors.ink,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        // Shared Connection Goals Section
                        if (_candidate.sharedConnectionGoals.isNotEmpty) ...[
                          const Text(
                            'Looking For',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AndrilSocialColors.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _candidate.sharedConnectionGoals.map((goal) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AndrilSocialColors.faintPurple,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AndrilSocialColors.royalPurple.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  goal,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AndrilSocialColors.royalPurple,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                        // Interests Section
                        if (_candidate.interests.isNotEmpty) ...[
                          const Text(
                            'Interests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AndrilSocialColors.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _candidate.interests.map((interest) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AndrilSocialColors.border,
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  interest,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AndrilSocialColors.ink,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                        // Languages Section
                        if (_candidate.sharedLanguages.isNotEmpty) ...[
                          const Text(
                            'Languages',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AndrilSocialColors.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _candidate.sharedLanguages.map((lang) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AndrilSocialColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.language_rounded,
                                      size: 14,
                                      color: AndrilSocialColors.copper,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      lang,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AndrilSocialColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Bottom Sticky Action Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // PASS Button (Red Outlined, 56dp)
                    Semantics(
                      label: 'Pass on ${_candidate.displayName}',
                      button: true,
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: widget.onPass,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE63946), width: 2),
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            foregroundColor: const Color(0xFFE63946),
                          ),
                          child: const Icon(Icons.close_rounded, size: 28),
                        ),
                      ),
                    ),
                    // BOOKMARK / SAVE Button (Copper Outlined, 48dp)
                    Semantics(
                      label: widget.isBookmarked
                          ? 'Remove bookmark for ${_candidate.displayName}'
                          : 'Save profile ${_candidate.displayName}',
                      button: true,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: widget.onBookmark,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: widget.isBookmarked
                                  ? AndrilSocialColors.royalPurple
                                  : AndrilSocialColors.copper,
                              width: 1.5,
                            ),
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            foregroundColor: widget.isBookmarked
                                ? AndrilSocialColors.royalPurple
                                : AndrilSocialColors.copper,
                          ),
                          child: Icon(
                            widget.isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    // LIKE Button (Royal Purple Filled, 56dp)
                    Semantics(
                      label: 'Like ${_candidate.displayName}',
                      button: true,
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: widget.onLike,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AndrilSocialColors.royalPurple,
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            elevation: 4,
                          ),
                          child: const Icon(Icons.favorite_rounded, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: AndrilSocialColors.faintPurple,
      child: Center(
        child: Text(
          _candidate.displayName.isNotEmpty
              ? _candidate.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: AndrilSocialColors.royalPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AndrilSocialColors.border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AndrilSocialColors.copper),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AndrilSocialColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
