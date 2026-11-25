import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';
import '../../../../features/shared/presentation/widgets/andril_module_app_bar.dart';
import '../domain/social_candidate.dart';
import 'social_discovery_viewmodel.dart';

/// Screen S09: Discover People / Ranked Discovery Feed (SOC-02).
///
/// Follows M5-FE-S09-UI-01 requirements:
/// - Fails closed: Displays access denied view if unauthorized or unauthenticated.
/// - Renders top branded [AndrilModuleAppBar] with filter icon and optional back navigation.
/// - Renders candidate card with photo, verified badge, display name, age, distance pill,
///   shared languages, and connection goals.
/// - Houses accessible floating action buttons: Pass (X), Filter (tune), and Like (heart).
/// - Displays loading, empty, unavailable service, and error states gracefully.
/// - Responsive layout down to 320dp and under accessibility text scaling (1.3).
class SocialDiscoveryScreen extends StatefulWidget {
  final SocialDiscoveryViewModel viewModel;
  final VoidCallback? onBack;
  final ValueChanged<SocialCandidate>? onViewProfileDetails;
  final VoidCallback? onOpenFilters;

  const SocialDiscoveryScreen({
    super.key,
    required this.viewModel,
    this.onBack,
    this.onViewProfileDetails,
    this.onOpenFilters,
  });

  @override
  State<SocialDiscoveryScreen> createState() => _SocialDiscoveryScreenState();
}

class _SocialDiscoveryScreenState extends State<SocialDiscoveryScreen> {
  SocialDiscoveryViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _attachCallbacks();
    if (_vm.status == SocialDiscoveryStatus.initial) {
      _vm.initialize();
    }
  }

  void _attachCallbacks() {
    if (widget.onViewProfileDetails != null) {
      _vm.onViewProfileDetails = widget.onViewProfileDetails;
    }
    if (widget.onOpenFilters != null) {
      _vm.onOpenFilters = widget.onOpenFilters;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AndrilSocialColors.cream,
          appBar: AndrilModuleAppBar(
            moduleName: 'Social',
            badgeColor: AndrilSocialColors.royalPurple,
            badgeTextColor: Colors.white,
            backgroundColor: AndrilSocialColors.cream,
            foregroundColor: AndrilSocialColors.ink,
            leading: widget.onBack != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    tooltip: 'Back',
                    onPressed: widget.onBack,
                  )
                : null,
            automaticallyImplyLeading: false,
            onNotificationTap: null,
            onSearchTap: widget.onOpenFilters != null
                ? widget.onOpenFilters
                : _vm.triggerOpenFilters,
          ),
          body: SafeArea(
            child: _buildBody(),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_vm.isAccessDenied) {
      return _buildAccessDeniedView();
    }

    if (_vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AndrilSocialColors.royalPurple,
        ),
      );
    }

    if (_vm.isServiceUnavailable) {
      return _buildServiceUnavailableView();
    }

    if (_vm.status == SocialDiscoveryStatus.error) {
      return _buildErrorView();
    }

    if (_vm.status == SocialDiscoveryStatus.empty || !_vm.hasMoreCandidates) {
      return _buildEmptyView();
    }

    final candidate = _vm.currentCandidate;
    if (candidate == null) {
      return _buildEmptyView();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Main Candidate Card
                _buildCandidateCard(candidate),
                const SizedBox(height: 16),
                // Action Buttons Row (Pass, Info, Like)
                _buildActionButtonsRow(candidate),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCandidateCard(SocialCandidate candidate) {
    final photoUrl = candidate.primaryPhotoUrl;

    return Semantics(
      label: '${candidate.displayName}, ${candidate.age} years old',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo Area with Fallback and Scrim
            SizedBox(
              height: 340,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photoUrl != null && photoUrl.isNotEmpty)
                    Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarFallback(candidate),
                    )
                  else
                    _buildAvatarFallback(candidate),
                  // Bottom gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.5, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Name and Age overlay at bottom of photo
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '${candidate.displayName}, ${candidate.age}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (candidate.isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.lightBlueAccent,
                            size: 22,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Information Section below photo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance & Location Pill
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (candidate.approximateDistanceKm != null)
                        _buildInfoChip(
                          icon: Icons.near_me_outlined,
                          label: '${candidate.approximateDistanceKm} km away',
                        ),
                      if (candidate.locationName != null &&
                          candidate.locationName!.isNotEmpty)
                        _buildInfoChip(
                          icon: Icons.location_on_outlined,
                          label: candidate.locationName!,
                        ),
                    ],
                  ),
                  if (candidate.biography != null &&
                      candidate.biography!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      candidate.biography!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AndrilSocialColors.ink,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (candidate.sharedConnectionGoals.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: candidate.sharedConnectionGoals.map((goal) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AndrilSocialColors.faintPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            goal,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AndrilSocialColors.royalPurple,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Details link button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _vm.triggerViewDetails(candidate),
                      icon: const Text(
                        'View Full Profile',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AndrilSocialColors.royalPurple,
                        ),
                      ),
                      label: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AndrilSocialColors.royalPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(SocialCandidate candidate) {
    return Container(
      color: AndrilSocialColors.faintPurple,
      child: Center(
        child: Text(
          candidate.displayName.isNotEmpty
              ? candidate.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: AndrilSocialColors.royalPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AndrilSocialColors.cream,
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

  Widget _buildActionButtonsRow(SocialCandidate candidate) {
    final isBusy = _vm.isActionInProgress;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // PASS Button (Red / Copper outlined circle, minimum 56dp)
        Semantics(
          label: 'Pass on ${candidate.displayName}',
          button: true,
          child: SizedBox(
            width: 60,
            height: 60,
            child: OutlinedButton(
              onPressed: isBusy ? null : () => _vm.pass(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE63946), width: 2),
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                foregroundColor: const Color(0xFFE63946),
              ),
              child: const Icon(Icons.close_rounded, size: 30),
            ),
          ),
        ),
        // Filter Button (Center small circle, 48dp)
        Semantics(
          label: 'Open discovery filters',
          button: true,
          child: SizedBox(
            width: 48,
            height: 48,
            child: OutlinedButton(
              onPressed: isBusy ? null : () => _vm.triggerOpenFilters(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AndrilSocialColors.copper, width: 1.5),
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                foregroundColor: AndrilSocialColors.copper,
              ),
              child: const Icon(Icons.tune_rounded, size: 22),
            ),
          ),
        ),
        // LIKE Button (Royal purple filled circle, minimum 56dp)
        Semantics(
          label: 'Like ${candidate.displayName}',
          button: true,
          child: SizedBox(
            width: 60,
            height: 60,
            child: ElevatedButton(
              onPressed: isBusy ? null : () => _vm.like(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AndrilSocialColors.royalPurple,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                elevation: 4,
              ),
              child: const Icon(Icons.favorite_rounded, size: 30),
            ),
          ),
        ),
      ],
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
              Icons.explore_off_outlined,
              size: 64,
              color: AndrilSocialColors.copper,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Profiles Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AndrilSocialColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have reviewed all available profiles for your current filters. Adjust your radius or preferences to see more people.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AndrilSocialColors.ink),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _vm.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AndrilSocialColors.royalPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(140, 48),
              ),
              child: const Text('Refresh Feed'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceUnavailableView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AndrilSocialColors.copper,
            ),
            const SizedBox(height: 16),
            const Text(
              'Discovery Preparing',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AndrilSocialColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _vm.errorMessage ??
                  'Social discovery service is currently preparing and unavailable.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AndrilSocialColors.ink),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _vm.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AndrilSocialColors.royalPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(140, 48),
              ),
              child: const Text('Check Again'),
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
              'Signed-in module authorization is required to access Social Discovery.',
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
              'Unable to Load Feed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AndrilSocialColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _vm.errorMessage ?? 'An error occurred while loading candidates.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AndrilSocialColors.ink),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _vm.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AndrilSocialColors.royalPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(140, 48),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
