import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_connection.dart';
import '../viewmodels/learning_connections_viewmodel.dart';
import '../widgets/learning_connection_card.dart';
import '../widgets/learning_request_card.dart';

/// Presentation screen for Learning Connections & Requests (CF-05, BRD v2.4-R1).
///
/// Features:
/// 1. Tabbed navigation: "My Connections", "Incoming", "Sent".
/// 2. Numerical request badges for incoming and sent tabs.
/// 3. Search and filtering within active tab.
/// 4. Disconnected / pending contract notice banner.
/// 5. Comprehensive states: loading, empty, accessDenied, unavailableService, error, and ready.
/// 6. Decoupled navigation / action callbacks: [onViewProfile], [onMessage], [onExplorePartners].
/// 7. Responsive across 320dp, 360dp, 412dp viewports and with 1.5x dynamic font scaling.
class LearningConnectionsScreen extends StatefulWidget {
  final LearningConnectionsViewModel viewModel;
  final ValueChanged<LearningConnection>? onViewProfile;
  final ValueChanged<LearningConnection>? onMessage;
  final VoidCallback? onExplorePartners;
  final PreferredSizeWidget? appBar;

  const LearningConnectionsScreen({
    super.key,
    required this.viewModel,
    this.onViewProfile,
    this.onMessage,
    this.onExplorePartners,
    this.appBar,
  });

  @override
  State<LearningConnectionsScreen> createState() =>
      _LearningConnectionsScreenState();
}

class _LearningConnectionsScreenState extends State<LearningConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _searchController = TextEditingController(
      text: widget.viewModel.searchQuery,
    );
    widget.viewModel.addListener(_onViewModelChanged);

    if (widget.viewModel.status == LearningConnectionsViewStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.viewModel.initialize();
      });
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        widget.viewModel.switchTab(LearningConnectionsTab.myConnections);
        break;
      case 1:
        widget.viewModel.switchTab(LearningConnectionsTab.incomingRequests);
        break;
      case 2:
        widget.viewModel.switchTab(LearningConnectionsTab.sentRequests);
        break;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: widget.appBar ??
          AppBar(
            title: const Text('Learning Connections'),
            backgroundColor: LearningColors.cardSurface,
            foregroundColor: LearningColors.heading,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: LearningColors.primary,
              unselectedLabelColor: LearningColors.secondaryText,
              indicatorColor: LearningColors.primary,
              indicatorWeight: 3.0,
              tabs: [
                Tab(
                  key: const ValueKey('tab_my_connections'),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Connections'),
                        if (widget.viewModel.connectionsCount > 0) ...[
                          const SizedBox(width: 6),
                          _buildBadge(widget.viewModel.connectionsCount),
                        ],
                      ],
                    ),
                  ),
                ),
                Tab(
                  key: const ValueKey('tab_incoming_requests'),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Incoming'),
                        if (widget.viewModel.incomingCount > 0) ...[
                          const SizedBox(width: 6),
                          _buildBadge(widget.viewModel.incomingCount),
                        ],
                      ],
                    ),
                  ),
                ),
                Tab(
                  key: const ValueKey('tab_sent_requests'),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sent'),
                        if (widget.viewModel.outgoingCount > 0) ...[
                          const SizedBox(width: 6),
                          _buildBadge(widget.viewModel.outgoingCount),
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

            // Search Bar
            _buildSearchBar(),

            // Main Tab Content Area
            Expanded(
              child: _buildBodyContent(),
            ),
          ],
        ),
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
              LearningConnectionsViewModel.disconnectedNotice,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
      child: TextField(
        key: const ValueKey('input_connections_search'),
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by partner name or skill...',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: LearningColors.secondaryText,
          ),
          prefixIcon: const Icon(Icons.search, color: LearningColors.primary),
          suffixIcon: widget.viewModel.searchQuery.isNotEmpty
              ? IconButton(
                  key: const ValueKey('btn_clear_connections_search'),
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    widget.viewModel.setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: LearningColors.cardSurface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(
              color: LearningColors.primary,
              width: 1.5,
            ),
          ),
        ),
        onChanged: (val) => widget.viewModel.setSearchQuery(val),
      ),
    );
  }

  Widget _buildBodyContent() {
    final vm = widget.viewModel;

    if (vm.isLoading) {
      return const Center(
        key: ValueKey('loading_connections_indicator'),
        child: CircularProgressIndicator(),
      );
    }

    if (vm.isAccessDenied) {
      return _buildAccessDeniedState();
    }

    if (vm.isServiceUnavailable) {
      return _buildUnavailableState();
    }

    if (vm.status == LearningConnectionsViewStatus.error) {
      return _buildErrorState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildConnectionsList(),
        _buildIncomingRequestsList(),
        _buildSentRequestsList(),
      ],
    );
  }

  Widget _buildConnectionsList() {
    final list = widget.viewModel.filteredConnections;
    if (list.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('empty_connections_view'),
        icon: Icons.people_outline,
        title: 'No Learning Connections Yet',
        subtitle:
            'Discover learning partners who share your goals and skills to connect and grow together.',
        actionLabel: 'Explore Learning Partners',
        onAction: widget.onExplorePartners,
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.viewModel.initialize(force: true),
      child: ListView.builder(
        key: const ValueKey('list_my_connections'),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final conn = list[index];
          return LearningConnectionCard(
            connection: conn,
            onViewProfile: widget.onViewProfile,
            onMessage: widget.onMessage,
            onRemove: (c) => widget.viewModel.removeConnection(c.id),
          );
        },
      ),
    );
  }

  Widget _buildIncomingRequestsList() {
    final list = widget.viewModel.filteredIncomingRequests;
    if (list.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('empty_incoming_requests_view'),
        icon: Icons.inbox_outlined,
        title: 'No Incoming Requests',
        subtitle:
            'When other learners want to connect with you, their requests will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.viewModel.initialize(force: true),
      child: ListView.builder(
        key: const ValueKey('list_incoming_requests'),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final req = list[index];
          return LearningRequestCard(
            request: req,
            isProcessing: widget.viewModel.isOperationInProgress(req.id),
            onAccept: (r) => widget.viewModel.acceptRequest(r.id),
            onDecline: (r) => widget.viewModel.declineRequest(r.id),
          );
        },
      ),
    );
  }

  Widget _buildSentRequestsList() {
    final list = widget.viewModel.filteredOutgoingRequests;
    if (list.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('empty_sent_requests_view'),
        icon: Icons.send_outlined,
        title: 'No Sent Requests',
        subtitle:
            'Requests you send to potential learning partners will be tracked here until accepted.',
        actionLabel: 'Explore Learning Partners',
        onAction: widget.onExplorePartners,
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.viewModel.initialize(force: true),
      child: ListView.builder(
        key: const ValueKey('list_sent_requests'),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final req = list[index];
          return LearningRequestCard(
            request: req,
            isProcessing: widget.viewModel.isOperationInProgress(req.id),
            onCancel: (r) => widget.viewModel.cancelRequest(r.id),
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
                  key: const ValueKey('btn_empty_action_explore'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LearningColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  icon: const Icon(Icons.explore_outlined, size: 18),
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
      key: const ValueKey('access_denied_connections_view'),
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
                  'You must be signed in with an activated Learning profile to view and manage connections.',
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
      key: const ValueKey('service_unavailable_connections_view'),
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
                  LearningConnectionsViewModel.disconnectedNotice,
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
      key: const ValueKey('error_connections_view'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16.0),
            const Text(
              'Unable to Load Connections',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ??
                  'An unexpected error occurred while loading your connections.',
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
                key: const ValueKey('btn_retry_connections'),
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
