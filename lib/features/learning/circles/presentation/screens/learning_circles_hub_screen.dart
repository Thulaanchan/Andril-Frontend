import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/features/learning/classrooms/presentation/widgets/classroom_filter_bar.dart';
import '../../domain/entities/learning_circle.dart';
import '../viewmodels/learning_circles_viewmodel.dart';
import '../widgets/circle_details_sheet.dart';
import '../widgets/create_circle_dialog.dart';
import '../widgets/learning_circle_card.dart';

/// Presentation screen for Learning Circles Hub & Collaborative Goals (CF-07, LRN-02).
///
/// Features:
/// 1. Tabbed navigation: "Discover Circles" and "My Circles".
/// 2. Numerical counts on tabs.
/// 3. Reuses [ClassroomFilterBar] for search and category filtering.
/// 4. Disconnected / pending contract notice banner.
/// 5. Circle creation modal via [CreateCircleDialog].
/// 6. Comprehensive states: loading, empty, accessDenied, unavailableService, error, and ready.
/// 7. Responsive across 320dp, 360dp, 412dp viewports and with 1.5x dynamic font scaling.
class LearningCirclesHubScreen extends StatefulWidget {
  final LearningCirclesViewModel viewModel;
  final PreferredSizeWidget? appBar;

  const LearningCirclesHubScreen({
    super.key,
    required this.viewModel,
    this.appBar,
  });

  @override
  State<LearningCirclesHubScreen> createState() =>
      _LearningCirclesHubScreenState();
}

class _LearningCirclesHubScreenState extends State<LearningCirclesHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;

  final List<String> _categories = const [
    'All',
    'Programming',
    'System Design',
    'Algorithms',
    'Design',
    'Data Science',
    'Mobile Dev',
    'Languages',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _searchController = TextEditingController(
      text: widget.viewModel.searchQuery,
    );
    widget.viewModel.addListener(_onViewModelChanged);

    if (widget.viewModel.status == LearningCirclesViewStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.viewModel.initialize();
      });
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      widget.viewModel.switchTab(LearningCirclesTab.discover);
    } else {
      widget.viewModel.switchTab(LearningCirclesTab.myCircles);
    }
  }

  void _onViewModelChanged() {
    if (mounted) {
      if (_searchController.text != widget.viewModel.searchQuery) {
        _searchController.text = widget.viewModel.searchQuery;
      }
      final expectedIndex = widget.viewModel.activeTab.index;
      if (_tabController.index != expectedIndex) {
        _tabController.animateTo(expectedIndex);
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateCircleDialog() {
    CreateCircleDialog.show(
      context,
      onCreate: widget.viewModel.createCircle,
    );
  }

  void _openCircleDetails(LearningCircle circle) {
    CircleDetailsSheet.show(
      context,
      circle: circle,
      onJoin: () => widget.viewModel.joinCircle(circle.id),
      onLeave: () => widget.viewModel.leaveCircle(circle.id),
      onAddGoal: (text) =>
          widget.viewModel.addSharedGoal(circleId: circle.id, goalText: text),
      onUpdateGoalProgress: (goalId, prog) =>
          widget.viewModel.updateGoalProgress(
        circleId: circle.id,
        goalId: goalId,
        progressPercent: prog,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: widget.appBar ??
          AppBar(
            title: const Text('Learning Circles Hub'),
            backgroundColor: LearningColors.cardSurface,
            foregroundColor: LearningColors.heading,
            elevation: 0,
            actions: [
              TextButton.icon(
                key: const ValueKey('btn_appbar_create_circle'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create'),
                style: TextButton.styleFrom(
                  foregroundColor: LearningColors.primary,
                ),
                onPressed: _openCreateCircleDialog,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: LearningColors.primary,
              unselectedLabelColor: LearningColors.secondaryText,
              indicatorColor: LearningColors.primary,
              indicatorWeight: 3.0,
              tabs: [
                Tab(
                  key: const ValueKey('tab_discover_circles'),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Discover Circles'),
                        if (widget.viewModel.discoverCount > 0) ...[
                          const SizedBox(width: 6),
                          _buildBadge(widget.viewModel.discoverCount),
                        ],
                      ],
                    ),
                  ),
                ),
                Tab(
                  key: const ValueKey('tab_my_circles'),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('My Circles'),
                        if (widget.viewModel.myCirclesCount > 0) ...[
                          const SizedBox(width: 6),
                          _buildBadge(widget.viewModel.myCirclesCount),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      body: SafeArea(
        child: Column(
          children: [
            // Notice banner when disconnected / pending backend contract
            _buildDisconnectedNotice(),

            // Reused ClassroomFilterBar for search and category chips
            ClassroomFilterBar(
              searchController: _searchController,
              onSearchChanged: (val) => widget.viewModel.setSearchQuery(val),
              onClearSearch: () {
                _searchController.clear();
                widget.viewModel.clearSearch();
              },
              selectedCategory: widget.viewModel.selectedCategory,
              onCategorySelected: (cat) => widget.viewModel.setCategory(cat),
              categories: _categories,
            ),

            // Main Tab Content
            Expanded(
              child: _buildBodyContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('fab_create_circle'),
        backgroundColor: LearningColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Create Learning Circle',
        onPressed: _openCreateCircleDialog,
        child: const Icon(Icons.group_add_outlined),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: LearningColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDisconnectedNotice() {
    return Container(
      key: const ValueKey('banner_disconnected_notice'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.amber.shade50,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              LearningCirclesViewModel.disconnectedNotice,
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    final vm = widget.viewModel;

    if (vm.isLoading) {
      return const Center(
        key: ValueKey('loading_circles_indicator'),
        child: CircularProgressIndicator(),
      );
    }

    if (vm.isAccessDenied) {
      return _buildAccessDeniedState();
    }

    if (vm.isServiceUnavailable) {
      return _buildUnavailableState();
    }

    if (vm.status == LearningCirclesViewStatus.error) {
      return _buildErrorState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildDiscoverList(),
        _buildMyCirclesList(),
      ],
    );
  }

  Widget _buildDiscoverList() {
    final list = widget.viewModel.filteredDiscoverCircles;
    if (list.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('empty_discover_circles_view'),
        icon: Icons.groups_outlined,
        title: 'No Circles Found',
        subtitle:
            'Be the first to create a peer study circle and collaborate towards shared goals!',
        actionLabel: 'Create a Circle',
        onAction: _openCreateCircleDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.viewModel.initialize(force: true),
      child: ListView.builder(
        key: const ValueKey('list_discover_circles'),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final circle = list[index];
          return LearningCircleCard(
            circle: circle,
            isProcessing: widget.viewModel.isOperationInProgress(circle.id),
            onJoin: () => widget.viewModel.joinCircle(circle.id),
            onLeave: () => widget.viewModel.leaveCircle(circle.id),
            onViewDetails: () => _openCircleDetails(circle),
          );
        },
      ),
    );
  }

  Widget _buildMyCirclesList() {
    final list = widget.viewModel.filteredMyCircles;
    if (list.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('empty_my_circles_view'),
        icon: Icons.school_outlined,
        title: 'No Enrolled Circles',
        subtitle:
            'Join study circles from the Discover tab or start your own peer study circle.',
        actionLabel: 'Discover Circles',
        onAction: () => _tabController.animateTo(0),
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.viewModel.initialize(force: true),
      child: ListView.builder(
        key: const ValueKey('list_my_circles'),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final circle = list[index];
          return LearningCircleCard(
            circle: circle,
            isProcessing: widget.viewModel.isOperationInProgress(circle.id),
            onJoin: () => widget.viewModel.joinCircle(circle.id),
            onLeave: () => widget.viewModel.leaveCircle(circle.id),
            onViewDetails: () => _openCircleDetails(circle),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      key: key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: LearningColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: LearningColors.primary),
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24.0),
              SizedBox(
                height: 44.0,
                child: ElevatedButton.icon(
                  key: const ValueKey('btn_empty_action_circle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LearningColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text(actionLabel),
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedState() {
    return Center(
      key: const ValueKey('access_denied_circles_view'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16.0),
            const Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ??
                  'You must be signed in with an activated Learning profile to view and join study circles.',
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableState() {
    return Center(
      key: const ValueKey('service_unavailable_circles_view'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 48, color: Colors.amber.shade700),
            const SizedBox(height: 16.0),
            const Text(
              'Service Notice',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ??
                  LearningCirclesViewModel.disconnectedNotice,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              height: 44.0,
              child: OutlinedButton(
                onPressed: () => widget.viewModel.initialize(force: true),
                child: const Text('Check Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('error_circles_view'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16.0),
            const Text(
              'Unable to Load Circles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ??
                  'An unexpected error occurred while loading learning circles.',
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              height: 44.0,
              child: ElevatedButton(
                key: const ValueKey('btn_retry_circles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () => widget.viewModel.initialize(force: true),
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
