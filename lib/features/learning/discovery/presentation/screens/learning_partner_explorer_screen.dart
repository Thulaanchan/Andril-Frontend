import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_partner_candidate.dart';
import '../viewmodels/learning_partner_explorer_viewmodel.dart';
import '../widgets/applied_filter_chips_bar.dart';
import '../widgets/learning_partner_card.dart';
import '../widgets/learning_partner_filter_sheet.dart';
import '../widgets/learning_partner_profile_dialog.dart';

/// Complete presentation screen for Learning People Discovery — Learning Partner Explorer (CF-04).
///
/// Features:
/// 1. Search by approved skills, goals, and display-name fields.
/// 2. Approved skill, goal, proficiency, language, and availability filters.
/// 3. Apply, reset, and clear-filter controls.
/// 4. Applied filter chips with remove ('X') actions.
/// 5. Eligible Learning partner cards with Learning visual branding.
/// 6. Verified result counts and supported sorting.
/// 7. Authorized View Profile presentation modal.
/// 8. Connect action integration boundary for Task 05-02.
/// 9. Comprehensive states: loading, empty, unavailable, access-denied, error, and ready.
/// 10. Disconnected notice banner for local presentation mode.
/// 11. Fully responsive across 320dp, 360dp, 412dp viewports and with 1.5x font scaling.
class LearningPartnerExplorerScreen extends StatefulWidget {
  final LearningPartnerExplorerViewModel viewModel;
  final ValueChanged<LearningPartnerCandidate>? onConnect;
  final PreferredSizeWidget? appBar;

  const LearningPartnerExplorerScreen({
    super.key,
    required this.viewModel,
    this.onConnect,
    this.appBar,
  });

  @override
  State<LearningPartnerExplorerScreen> createState() =>
      _LearningPartnerExplorerScreenState();
}

class _LearningPartnerExplorerScreenState
    extends State<LearningPartnerExplorerScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.viewModel.filters.searchQuery,
    );
    widget.viewModel.addListener(_onViewModelChanged);

    // Auto-initialize if initial status
    if (widget.viewModel.status == LearningPartnerExplorerStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.viewModel.initialize();
      });
    }
  }

  void _onViewModelChanged() {
    if (mounted) {
      if (_searchController.text != widget.viewModel.filters.searchQuery) {
        _searchController.text = widget.viewModel.filters.searchQuery;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    LearningPartnerFilterSheet.show(
      context,
      initialFilters: widget.viewModel.filters,
      onApply: (newFilters) {
        widget.viewModel.applyFilters(newFilters);
      },
      onReset: () {
        widget.viewModel.resetFilters();
      },
    );
  }

  void _handleConnect(LearningPartnerCandidate candidate) {
    if (widget.onConnect != null) {
      widget.onConnect!(candidate);
    } else {
      // Standard integration boundary notice for Task 05-02
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connection request to ${candidate.displayName} registered (Task 05-02 boundary).',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleViewProfile(LearningPartnerCandidate candidate) {
    widget.viewModel.selectCandidateForProfile(candidate);
    LearningPartnerProfileDialog.show(
      context,
      candidate: candidate,
      onConnect: _handleConnect,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: widget.appBar ??
          AppBar(
            backgroundColor: LearningColors.cardSurface,
            elevation: 0,
            title: const Text(
              'Learning Partner Explorer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            actions: [
              IconButton(
                key: const ValueKey('btn_refresh_explorer'),
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: LearningColors.primary,
                ),
                tooltip: 'Refresh',
                onPressed: () => widget.viewModel.initialize(),
              ),
            ],
          ),
      body: SafeArea(
        child: Column(
          children: [
            // Disconnected mode notice banner
            _buildDisconnectedNoticeBanner(),

            // Search Bar & Filter trigger button
            _buildSearchAndFilterHeader(),

            // Applied Filter Chips and Sort Bar
            if (widget.viewModel.isReady || widget.viewModel.isEmpty)
              AppliedFilterChipsBar(
                filters: widget.viewModel.filters,
                resultCount: widget.viewModel.filteredCount,
                onSortChanged: (sort) => widget.viewModel.setSortOption(sort),
                onRemoveFilter: (category, value) => widget.viewModel
                    .removeFilter(category: category, value: value),
                onClearAll: () => widget.viewModel.resetFilters(),
              ),

            // Main State Switcher
            Expanded(
              child: _buildStateContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// Prominent banner explaining disconnected / pending OpenAPI contract.
  Widget _buildDisconnectedNoticeBanner() {
    return Container(
      key: const ValueKey('banner_disconnected_notice'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.amber.shade50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Colors.amber.shade900,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              LearningPartnerExplorerViewModel.disconnectedNotice,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Search input with Filter button trigger.
  Widget _buildSearchAndFilterHeader() {
    final activeCount = widget.viewModel.filters.activeFilterCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 4.0),
      child: Row(
        children: [
          // Search TextField
          Expanded(
            child: TextField(
              key: const ValueKey('input_partner_search'),
              controller: _searchController,
              onChanged: (text) => widget.viewModel.setSearchQuery(text),
              decoration: InputDecoration(
                hintText: 'Search skills, goals, or partners...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: LearningColors.secondaryText,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: LearningColors.secondaryText,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        key: const ValueKey('btn_clear_search_text'),
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          widget.viewModel.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: LearningColors.cardSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
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
            ),
          ),
          const SizedBox(width: 8.0),

          // Filter Button
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                key: const ValueKey('btn_open_filters'),
                icon: const Icon(
                  Icons.tune_rounded,
                  color: LearningColors.primary,
                ),
                tooltip: 'Filters',
                style: IconButton.styleFrom(
                  backgroundColor: LearningColors.cardSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(
                      color: activeCount > 0
                          ? LearningColors.primary
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  minimumSize: const Size(44, 44),
                ),
                onPressed: _openFilterSheet,
              ),
              if (activeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: LearningColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the current operational presentation state.
  Widget _buildStateContent() {
    switch (widget.viewModel.status) {
      case LearningPartnerExplorerStatus.initial:
      case LearningPartnerExplorerStatus.loading:
        return const Center(
          key: ValueKey('state_loading'),
          child: CircularProgressIndicator(
            color: LearningColors.primary,
          ),
        );

      case LearningPartnerExplorerStatus.accessDenied:
        return _buildAccessDeniedState();

      case LearningPartnerExplorerStatus.unavailableService:
        return _buildUnavailableState();

      case LearningPartnerExplorerStatus.error:
        return _buildErrorState();

      case LearningPartnerExplorerStatus.empty:
        return _buildEmptyState();

      case LearningPartnerExplorerStatus.ready:
        return _buildReadyList();
    }
  }

  /// Access Denied State (unauthenticated or unactivated Learning profile).
  Widget _buildAccessDeniedState() {
    return Center(
      key: const ValueKey('state_access_denied'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: Color(0xFFDC2626),
              ),
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
                  'Authentication and activated Learning profile are required to explore learning partners.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Service Unavailable State.
  Widget _buildUnavailableState() {
    return Center(
      key: const ValueKey('state_unavailable'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Service Preparing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ??
                  'Learning discovery service is currently preparing and unavailable.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              key: const ValueKey('btn_retry_unavailable'),
              onPressed: () => widget.viewModel.initialize(),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(44, 40),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Error State.
  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('state_error'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Unable to Load Partners',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ??
                  'An unexpected error occurred while loading learning partners.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              key: const ValueKey('btn_retry_error'),
              onPressed: () => widget.viewModel.initialize(),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(44, 40),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State (no partners found for current filters/query).
  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('state_empty'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: LearningColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: LearningColors.primary,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'No Learning Partners Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'No partners match your current search or filter criteria. Try broadening your filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
              ),
            ),
            if (widget.viewModel.filters.hasActiveFilters) ...[
              const SizedBox(height: 16.0),
              OutlinedButton.icon(
                key: const ValueKey('btn_reset_empty_filters'),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset Filters'),
                onPressed: () {
                  _searchController.clear();
                  widget.viewModel.resetFilters();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: LearningColors.primary,
                  side: const BorderSide(color: LearningColors.primary),
                  minimumSize: const Size(44, 40),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Ready State with ListView of candidate cards.
  Widget _buildReadyList() {
    final list = widget.viewModel.candidates;

    return RefreshIndicator(
      key: const ValueKey('refresh_indicator_candidates'),
      color: LearningColors.primary,
      onRefresh: () => widget.viewModel.initialize(),
      child: ListView.builder(
        key: const ValueKey('list_learning_partners'),
        padding: const EdgeInsets.only(top: 4.0, bottom: 24.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final candidate = list[index];
          return LearningPartnerCard(
            candidate: candidate,
            onViewProfile: _handleViewProfile,
            onConnect: _handleConnect,
          );
        },
      ),
    );
  }
}
