import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_pact.dart';
import '../viewmodels/learning_pacts_viewmodel.dart';
import '../widgets/learning_pact_card.dart';
import '../widgets/pact_invitation_bottom_sheet.dart';
import 'learning_pact_progress_screen.dart';
import 'propose_pact_flow_screen.dart';

/// Presentation screen for Learning Pacts & Commitments Hub (LRN-03, BRD v2.4-R1).
///
/// Features:
/// 1. Tabbed navigation: Active Pacts, Invitations (incoming/outgoing), and Pact History.
/// 2. Numerical count badges on each tab.
/// 3. Clear disconnected contract notice banner for pending OpenAPI integration.
/// 4. Dynamic search filter across pact titles, goals, and partner names.
/// 5. Proposal workflow invocation via [ProposePactFlowScreen].
/// 6. Comprehensive states: loading, empty, access-denied, unavailable, error, and ready.
/// 7. Responsive across 320dp, 360dp, 412dp viewports and with 1.5x dynamic font scaling.
class LearningPactsHubScreen extends StatefulWidget {
  final LearningPactsViewModel viewModel;
  final PreferredSizeWidget? appBar;

  const LearningPactsHubScreen({
    super.key,
    required this.viewModel,
    this.appBar,
  });

  @override
  State<LearningPactsHubScreen> createState() => _LearningPactsHubScreenState();
}

class _LearningPactsHubScreenState extends State<LearningPactsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    widget.viewModel.addListener(_onViewModelChanged);

    if (widget.viewModel.status == LearningPactsViewStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.viewModel.initialize();
      });
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        widget.viewModel.switchTab(LearningPactsTab.active);
        break;
      case 1:
        widget.viewModel.switchTab(LearningPactsTab.invitations);
        break;
      case 2:
        widget.viewModel.switchTab(LearningPactsTab.history);
        break;
    }
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<LearningPact> _applySearchFilter(List<LearningPact> pacts) {
    if (_searchQuery.isEmpty) return pacts;
    return pacts.where((p) {
      final matchesTitle = p.title.toLowerCase().contains(_searchQuery);
      final matchesGoal = p.sharedGoal.toLowerCase().contains(_searchQuery);
      final matchesPartner = p.participants.any(
        (part) =>
            part.participantDisplayName.toLowerCase().contains(_searchQuery),
      );
      return matchesTitle || matchesGoal || matchesPartner;
    }).toList();
  }

  void _openProposeFlow() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProposePactFlowScreen(viewModel: widget.viewModel),
      ),
    );
  }

  void _openPactProgress(String pactId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningPactProgressScreen(
          viewModel: widget.viewModel,
          pactId: pactId,
        ),
      ),
    );
  }

  void _reviewInvitation(LearningPact pact) {
    PactInvitationBottomSheet.show(
      context,
      pact: pact,
      onAccept: () => widget.viewModel.acceptPact(pact.id),
      onDecline: () => widget.viewModel.declinePact(pact.id),
      isProcessing: widget.viewModel.isOperationInProgress(pact.id),
    );
  }

  Widget _buildDisconnectedBanner() {
    return Container(
      key: const ValueKey('banner_disconnected_notice'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      color: Colors.blue.shade50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Colors.blue.shade800,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              LearningPactsViewModel.disconnectedNotice,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      child: TextField(
        key: const ValueKey('input_pacts_search'),
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search pacts by title, goal, or partner...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: LearningColors.secondaryText,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: LearningColors.secondaryText,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  key: const ValueKey('button_clear_search'),
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14.0,
            vertical: 10.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: LearningColors.primary,
        unselectedLabelColor: LearningColors.secondaryText,
        indicatorColor: LearningColors.primary,
        indicatorWeight: 3.0,
        tabs: [
          Tab(
            key: const ValueKey('tab_active_pacts'),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Active'),
                  if (widget.viewModel.activePactsCount > 0) ...[
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${widget.viewModel.activePactsCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Tab(
            key: const ValueKey('tab_invitations'),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Invitations'),
                  if (widget.viewModel.pendingPactsCount > 0) ...[
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${widget.viewModel.pendingPactsCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Tab(
            key: const ValueKey('tab_history'),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('History'),
                  if (widget.viewModel.historyPactsCount > 0) ...[
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${widget.viewModel.historyPactsCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: LearningColors.heading,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      key: const ValueKey('view_pacts_empty'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20.0),
              ElevatedButton.icon(
                key: const ValueKey('button_empty_action'),
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab(List<LearningPact> pacts) {
    if (pacts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.handshake_outlined,
        title: 'No Active Learning Pacts',
        message:
            'Propose a learning pact with a study partner to commit to mutual goals and track progress together.',
        actionLabel: 'Propose a Pact',
        onAction: _openProposeFlow,
      );
    }

    return ListView.separated(
      key: const ValueKey('list_active_pacts'),
      padding: const EdgeInsets.all(16.0),
      itemCount: pacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        final pact = pacts[index];
        return LearningPactCard(
          pact: pact,
          currentProfileId: widget.viewModel.currentProfileId,
          onViewProgress: () => _openPactProgress(pact.id),
          isProcessing: widget.viewModel.isOperationInProgress(pact.id),
        );
      },
    );
  }

  Widget _buildInvitationsTab() {
    final incoming = _applySearchFilter(widget.viewModel.incomingInvitations);
    final outgoing = _applySearchFilter(widget.viewModel.outgoingInvitations);

    if (incoming.isEmpty && outgoing.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mail_outline,
        title: 'No Pending Invitations',
        message:
            'Any received pact invitations or pending proposals awaiting partner acceptance will appear here.',
        actionLabel: 'Propose a Pact',
        onAction: _openProposeFlow,
      );
    }

    return ListView(
      key: const ValueKey('list_invitations_pacts'),
      padding: const EdgeInsets.all(16.0),
      children: [
        if (incoming.isNotEmpty) ...[
          Text(
            'Received Invitations (${incoming.length})',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 8.0),
          ...incoming.map((pact) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: LearningPactCard(
                pact: pact,
                currentProfileId: widget.viewModel.currentProfileId,
                onReviewInvitation: () => _reviewInvitation(pact),
                isProcessing: widget.viewModel.isOperationInProgress(pact.id),
              ),
            );
          }),
          const SizedBox(height: 12.0),
        ],
        if (outgoing.isNotEmpty) ...[
          Text(
            'Outgoing Proposals (${outgoing.length})',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 8.0),
          ...outgoing.map((pact) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: LearningPactCard(
                pact: pact,
                currentProfileId: widget.viewModel.currentProfileId,
                onViewProgress: () => _openPactProgress(pact.id),
                isProcessing: widget.viewModel.isOperationInProgress(pact.id),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildHistoryTab(List<LearningPact> pacts) {
    if (pacts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Pact History',
        message:
            'Completed pacts and ended participations will be recorded here in your permanent learning history.',
      );
    }

    return ListView.separated(
      key: const ValueKey('list_history_pacts'),
      padding: const EdgeInsets.all(16.0),
      itemCount: pacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        final pact = pacts[index];
        return LearningPactCard(
          pact: pact,
          currentProfileId: widget.viewModel.currentProfileId,
          onViewHistory: () => _openPactProgress(pact.id),
          isProcessing: widget.viewModel.isOperationInProgress(pact.id),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (widget.viewModel.status) {
      case LearningPactsViewStatus.loading:
        return const Center(
          child: CircularProgressIndicator(
            key: ValueKey('loading_indicator'),
          ),
        );

      case LearningPactsViewStatus.accessDenied:
        return Center(
          key: const ValueKey('state_access_denied'),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Color(0xFFB91C1C),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.viewModel.errorMessage ??
                      'Authentication and an activated Learning profile are required to access Learning Pacts.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: LearningColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      case LearningPactsViewStatus.unavailableService:
        return Center(
          key: const ValueKey('state_unavailable'),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Service Unavailable',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.viewModel.errorMessage ??
                      'Learning Pacts service is currently unavailable.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: LearningColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  key: const ValueKey('button_retry'),
                  onPressed: () => widget.viewModel.initialize(force: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );

      case LearningPactsViewStatus.error:
        return Center(
          key: const ValueKey('state_error'),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Color(0xFFB91C1C),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Error Loading Pacts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.viewModel.errorMessage ??
                      'An unexpected error occurred.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: LearningColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  key: const ValueKey('button_retry'),
                  onPressed: () => widget.viewModel.initialize(force: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );

      case LearningPactsViewStatus.initial:
      case LearningPactsViewStatus.empty:
      case LearningPactsViewStatus.ready:
        return TabBarView(
          controller: _tabController,
          children: [
            _buildActiveTab(
              _applySearchFilter(widget.viewModel.activePacts),
            ),
            _buildInvitationsTab(),
            _buildHistoryTab(
              _applySearchFilter(widget.viewModel.historyPacts),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('screen_learning_pacts_hub'),
      backgroundColor: LearningColors.background,
      appBar: widget.appBar ??
          AppBar(
            title: const Text(
              'Learning Pacts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
          ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('button_propose_pact'),
        onPressed: _openProposeFlow,
        backgroundColor: LearningColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Propose Pact',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDisconnectedBanner(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
