import 'package:flutter/material.dart';

import '../../../../app/dependencies/registrations/social/social_dependencies.dart';
import '../../../../app/router/routes/social/social_routes.dart';
import '../../../../app/themes/social/social_theme.dart';
import '../../discovery/presentation/social_discovery_screen.dart';
import '../../profile/screens/social_my_profile_screen.dart';
import '../../zones/presentation/social_zones_screen.dart';
import '../viewmodels/social_home_viewmodel.dart';
import '../viewmodels/social_navigation_coordinator.dart';
import 'social_home_screen.dart';

/// Top-level shell screen housing the 5 approved Social destinations (S21).
///
/// Follows M5 Social Shell Governance (Task 148):
/// - Manages the approved 5-destination bottom navigation:
///   0: Home (Hub & dashboard)
///   1: Zones (Community spaces)
///   2: Explore (Candidate discovery)
///   3: Chat (Guarded M4 handoff or explicit unavailable state)
///   4: Profile (Private profile management)
/// - Fails closed: Replaces view with access-denied screen if caller is unauthorized.
/// - Preserves tab state across navigation switches using [IndexedStack].
/// - Deep-links to inner sub-surfaces (search, connections, personality, preferences).
/// - Fully responsive down to 320dp without RenderFlex overflows.
class SocialShellScreen extends StatefulWidget {
  final SocialDependenciesScope scope;
  final SocialNavigationCoordinator? coordinator;
  final ValueChanged<String>? onChatHandoff;
  final VoidCallback? onDiaryHandoff;
  final int initialIndex;

  const SocialShellScreen({
    super.key,
    required this.scope,
    this.coordinator,
    this.onChatHandoff,
    this.onDiaryHandoff,
    this.initialIndex = 0,
  });

  @override
  State<SocialShellScreen> createState() => _SocialShellScreenState();
}

class _SocialShellScreenState extends State<SocialShellScreen> {
  late final SocialNavigationCoordinator _coordinator;
  bool _isLocalCoordinator = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = (widget.initialIndex >= 0 && widget.initialIndex <= 4)
        ? widget.initialIndex
        : 0;

    if (widget.coordinator != null) {
      _coordinator = widget.coordinator!;
    } else {
      _coordinator = widget.scope.createNavigationCoordinator(
        onChatHandoff: widget.onChatHandoff,
      );
      _isLocalCoordinator = true;
    }

    _coordinator.addListener(_onCoordinatorStateChanged);
  }

  void _onCoordinatorStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _coordinator.removeListener(_onCoordinatorStateChanged);
    if (_isLocalCoordinator) {
      _coordinator.dispose();
    }
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (!widget.scope.isSocialAuthorized) return;

    if (index == 3) {
      _handleChatDestination();
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        _coordinator.navigateToHome();
        break;
      case 1:
        _coordinator.navigateToZones();
        break;
      case 2:
        _coordinator.navigateToDiscovery();
        break;
      case 4:
        _coordinator.navigateToProfile();
        break;
    }
  }

  void _handleChatDestination() {
    // Chat requires verified M4 communication evidence for mutual matches
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AndrilSocialColors.faintPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AndrilSocialColors.royalPurple,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Social Messaging (M4)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AndrilSocialColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Direct messaging is enabled for confirmed mutual matches through M4 peer messaging. '
                'Visit your connections to view matched conversations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AndrilSocialColors.royalPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamed(SocialRoutes.connections);
                  },
                  child: const Text('View Connections'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleQuickAction(SocialHomeActionId actionId) {
    switch (actionId) {
      case SocialHomeActionId.myConnections:
        Navigator.of(context).pushNamed(SocialRoutes.connections);
        break;
      case SocialHomeActionId.andrilDiary:
        if (widget.onDiaryHandoff != null) {
          widget.onDiaryHandoff!();
        } else {
          _showDiaryUnavailableDialog();
        }
        break;
      case SocialHomeActionId.personality:
        Navigator.of(context).pushNamed(SocialRoutes.personalityIntro);
        break;
      case SocialHomeActionId.savedProfiles:
        Navigator.of(context).pushNamed(SocialRoutes.savedProfiles);
        break;
    }
  }

  void _showDiaryUnavailableDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Andril Diary'),
        content: const Text(
          'Andril Diary is maintained in your private journal space. '
          'Handoff to M1 Diary is active when configured by application router.',
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

  int get _stackIndex => switch (_currentIndex) {
        0 => 0,
        1 => 1,
        2 => 2,
        4 => 3,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    // Fail closed: enforce authorization at shell boundary
    if (!widget.scope.isSocialAuthorized ||
        _coordinator.currentDestination == SocialDestination.accessDenied) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 64,
                  color: Color(0xFFE63946),
                ),
                SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Active adult opt-in and authentication are required to access Social features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _stackIndex,
        children: [
          // 0: Home (Dashboard)
          SocialHomeScreen(
            viewModel: widget.scope.createHomeViewModel(),
            onExplorePeople: () => _onDestinationSelected(2),
            onSearchTap: () =>
                Navigator.of(context).pushNamed(SocialRoutes.search),
            onQuickAction: _handleQuickAction,
            currentNavigationIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
          ),

          // 1: Zones (Communities)
          SocialZonesScreen(
            viewModel: widget.scope.zonesViewModel,
          ),

          // 2: Explore (Candidate Discovery)
          SocialDiscoveryScreen(
            viewModel: widget.scope.createDiscoveryViewModel(),
            onBack: () => _onDestinationSelected(0),
            onOpenFilters: () =>
                Navigator.of(context).pushNamed(SocialRoutes.discoveryFilters),
          ),

          // 3 in stack (4 in bar): Profile
          SocialMyProfileScreen(
            viewModel: widget.scope.createProfileManagementViewModel(),
            onEditProfile: () =>
                Navigator.of(context).pushNamed(SocialRoutes.editProfile),
            onTakePersonalityQuiz: () =>
                Navigator.of(context).pushNamed(SocialRoutes.personalityIntro),
            onSettings: () =>
                Navigator.of(context).pushNamed(SocialRoutes.preferences),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
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
        ],
      ),
    );
  }
}
