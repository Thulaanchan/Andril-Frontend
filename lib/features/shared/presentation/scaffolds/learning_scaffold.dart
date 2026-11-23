import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/themes/learning/learning_colors.dart';
import '../widgets/andril_module_app_bar.dart';

/// Top-level responsive scaffold and navigation shell for the ANDRIL Learning module.
///
/// Houses the official [AndrilModuleAppBar] top bar and the five-tab
/// [NavigationBar] bottom navigation shell. Supports integration with
/// [StatefulNavigationShell] from GoRouter as well as standalone test fixtures.
class LearningScaffold extends StatelessWidget {
  /// The stateful navigation shell driving branch navigation.
  final StatefulNavigationShell? navigationShell;

  /// Optional standalone child widget when used outside [StatefulNavigationShell].
  final Widget? child;

  /// Active tab index when [navigationShell] is null.
  final int currentIndex;

  /// Callback when a tab is selected when [navigationShell] is null.
  final ValueChanged<int>? onDestinationSelected;

  /// Optional top app bar. Defaults to [AndrilModuleAppBar].
  final PreferredSizeWidget? appBar;

  /// Creates a [LearningScaffold].
  const LearningScaffold({
    super.key,
    this.navigationShell,
    this.child,
    this.currentIndex = 0,
    this.onDestinationSelected,
    this.appBar = const AndrilModuleAppBar(),
  });

  /// The five approved Learning module navigation destinations in strict order.
  static const List<NavigationDestination> destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
      tooltip: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school),
      label: 'Classrooms',
      tooltip: 'Classrooms',
    ),
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Explore',
      tooltip: 'Explore',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: 'Chat',
      tooltip: 'Chat',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
      tooltip: 'Profile',
    ),
  ];

  void _handleDestinationSelected(int index) {
    if (navigationShell != null) {
      navigationShell!.goBranch(
        index,
        initialLocation: index == navigationShell!.currentIndex,
      );
    } else {
      onDestinationSelected?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int activeIndex = navigationShell?.currentIndex ?? currentIndex;

    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: appBar,
      body: SafeArea(
        top: false,
        bottom: false,
        child: navigationShell ?? child ?? const SizedBox.shrink(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeIndex,
        onDestinationSelected: _handleDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}
