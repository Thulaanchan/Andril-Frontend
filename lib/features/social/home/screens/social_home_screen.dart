import 'package:flutter/material.dart';
import '../../../../app/themes/social/social_theme.dart';
import '../viewmodels/social_home_viewmodel.dart';
import '../widgets/social_home_action_grid.dart';
import '../widgets/social_home_header.dart';

/// Screen S21: Andril Social Home Dashboard.
///
/// Follows M5-FE-S21-UI-04 architectural requirements:
/// - Fails closed: Displays access denied banner/view if unauthorized.
/// - Houses [SocialHomeHeader] with module badge, user greeting, and notifications.
/// - Houses [SocialHeroBanner] with "Explore People →" CTA and carousel indicators.
/// - Houses [SocialHomeActionGrid] with 2x2 action cards (Connections, Diary, Personality, Saved Profiles).
/// - Houses [SocialRecommendedPeopleSection] with horizontal cards and "View" callbacks.
/// - Houses 5 approved bottom navigation destinations: Home, Zones, Explore, Chat, Profile.
/// - Fully responsive down to 320dp and under accessibility text scaling (1.3) without RenderFlex overflow.
/// - Disables navigation interactions and action dispatching when access is denied.
/// - Supports pull-to-refresh via [RefreshIndicator].
/// - Fully decoupled navigation via callbacks.
class SocialHomeScreen extends StatefulWidget {
  final SocialHomeViewModel? viewModel;
  final VoidCallback? onExplorePeople;
  final ValueChanged<String>? onViewProfile;
  final ValueChanged<SocialHomeActionId>? onQuickAction;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;
  final int currentNavigationIndex;
  final ValueChanged<int>? onDestinationSelected;

  const SocialHomeScreen({
    super.key,
    this.viewModel,
    this.onExplorePeople,
    this.onViewProfile,
    this.onQuickAction,
    this.onNotificationTap,
    this.onSearchTap,
    this.onProfileTap,
    this.currentNavigationIndex = 0,
    this.onDestinationSelected,
  });

  @override
  State<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends State<SocialHomeScreen> {
  late final SocialHomeViewModel _vm;
  bool _isLocalVm = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _vm = widget.viewModel!;
    } else {
      _vm = SocialHomeViewModel();
      _isLocalVm = true;
    }

    _attachCallbacks();

    if (_vm.status == SocialHomeStatus.initial) {
      _vm.initialize();
    }
  }

  void _attachCallbacks() {
    if (widget.onExplorePeople != null) {
      _vm.onExplorePeople = widget.onExplorePeople;
    }
    if (widget.onViewProfile != null) {
      _vm.onViewProfile = widget.onViewProfile;
    }
    if (widget.onQuickAction != null) {
      _vm.onQuickAction = widget.onQuickAction;
    }
    if (widget.onNotificationTap != null) {
      _vm.onNotificationTap = widget.onNotificationTap;
    }
    if (widget.onSearchTap != null) {
      _vm.onSearchTap = widget.onSearchTap;
    }
  }

  @override
  void dispose() {
    if (_isLocalVm) {
      _vm.dispose();
    }
    super.dispose();
  }

  /// Approved 5-destination bottom navigation for Social Module.
  static const List<NavigationDestination> _socialDestinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.diversity_3_outlined),
      selectedIcon: Icon(Icons.diversity_3_rounded),
      label: 'Zones',
    ),
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore_rounded),
      label: 'Explore',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: 'Chat',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final isDenied = _vm.isAccessDenied || !_vm.isAuthorized;
        return Scaffold(
          backgroundColor: AndrilSocialColors.cream,
          body: _buildBody(isDenied),
          bottomNavigationBar: isDenied
              ? null
              : NavigationBar(
                  selectedIndex: widget.currentNavigationIndex,
                  onDestinationSelected: widget.onDestinationSelected,
                  destinations: _socialDestinations,
                ),
        );
      },
    );
  }

  Widget _buildBody(bool isDenied) {
    if (isDenied) {
      return _buildAccessDeniedView();
    }

    if (_vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AndrilSocialColors.royalPurple,
        ),
      );
    }

    if (_vm.status == SocialHomeStatus.error) {
      return _buildErrorView();
    }

    return RefreshIndicator(
      color: AndrilSocialColors.royalPurple,
      backgroundColor: Colors.white,
      onRefresh: _vm.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SocialHomeHeader(
              displayName: _vm.displayName,
              avatarUrl: _vm.avatarUrl,
              unreadNotificationsCount: _vm.unreadNotificationsCount,
              onNotificationTap: _vm.triggerNotificationTap,
              onSearchTap: _vm.triggerSearchTap,
              onProfileTap: widget.onProfileTap,
            ),
            SocialHeroBanner(
              onExploreTap: _vm.triggerExplorePeople,
            ),
            SocialHomeActionGrid(
              actions: _vm.quickActions,
              onActionTap: _vm.triggerQuickAction,
            ),
            if (_vm.recommendedPeople.isNotEmpty)
              SocialRecommendedPeopleSection(
                people: _vm.recommendedPeople,
                onViewProfile: _vm.triggerViewProfile,
                onSeeAll: _vm.triggerSeeAllRecommendations,
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 56,
              color: AndrilSocialColors.royalPurple,
            ),
            const SizedBox(height: 16),
            const Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AndrilSocialColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You must be signed in and opted in to the Social module to access Social Home.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AndrilSocialColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _vm.initialize,
              style: ElevatedButton.styleFrom(
                backgroundColor: AndrilSocialColors.royalPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(140, 48),
              ),
              child: const Text('Try Again'),
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
              size: 56,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _vm.errorMessage ?? 'An error occurred while loading.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AndrilSocialColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _vm.refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AndrilSocialColors.royalPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(140, 48),
              ),
              child: const Text('Reload'),
            ),
          ],
        ),
      ),
    );
  }
}
