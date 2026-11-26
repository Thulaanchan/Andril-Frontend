import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_growth_evidence.dart';
import '../viewmodels/learning_growth_viewmodel.dart';
import '../viewmodels/learning_mentorship_viewmodel.dart';
import '../viewmodels/learning_topic_gap_viewmodel.dart';
import '../widgets/evidence_detail_sheet.dart';
import '../widgets/growth_evidence_card.dart';
import '../widgets/growth_skill_card.dart';
import 'learning_mentorship_hub_screen.dart';
import 'topic_gap_explanation_screen.dart';

/// Screen displaying the Private My Learning Growth Dashboard (LRN-04, GRW-01-05, Q41_LUC-24).
///
/// Features:
/// 1. Tabbed navigation: Overview, Evidence, Skills, and Insights.
/// 2. Clear distinction between verified-source, self-reported, and insufficient-evidence states.
/// 3. Growth remains private by default (with prominent privacy callouts).
/// 4. Disconnected notice banner when running in local presentation mode.
/// 5. Self-reported evidence recording dialog.
/// 6. Responsive across 320dp, 360dp, 412dp viewports and with 1.5x dynamic font scaling.
/// 7. Strict compliance with no-invention rule (no XP rewards, no fake credentials, no assessment scores).
class MyGrowthDashboardScreen extends StatefulWidget {
  final LearningGrowthViewModel viewModel;
  final PreferredSizeWidget? appBar;

  const MyGrowthDashboardScreen({
    super.key,
    required this.viewModel,
    this.appBar,
  });

  @override
  State<MyGrowthDashboardScreen> createState() =>
      _MyGrowthDashboardScreenState();
}

class _MyGrowthDashboardScreenState extends State<MyGrowthDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _searchController = TextEditingController();
    _searchController.addListener(() {
      widget.viewModel.setSearchQuery(_searchController.text);
    });

    widget.viewModel.addListener(_onViewModelChanged);

    if (widget.viewModel.status == LearningGrowthViewStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.viewModel.initialize();
      });
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        widget.viewModel.switchTab(LearningGrowthTab.overview);
        break;
      case 1:
        widget.viewModel.switchTab(LearningGrowthTab.evidence);
        break;
      case 2:
        widget.viewModel.switchTab(LearningGrowthTab.skills);
        break;
      case 3:
        widget.viewModel.switchTab(LearningGrowthTab.insights);
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

  void _showRecordEvidenceDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final skillsCtrl = TextEditingController();
    final sourceCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Record Self-Reported Evidence'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Record an activity, reflection, or project. Self-reported evidence is private to you and clearly marked.',
                  style: TextStyle(
                      fontSize: 13, color: LearningColors.secondaryText),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  key: const ValueKey('input_evidence_title'),
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Evidence Title *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Clean Architecture Refactor',
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  key: const ValueKey('input_evidence_desc'),
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description / Reflection *',
                    border: OutlineInputBorder(),
                    hintText: 'Describe what you practiced or learned...',
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  key: const ValueKey('input_evidence_skills'),
                  controller: skillsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Associated Skills (comma-separated)',
                    border: OutlineInputBorder(),
                    hintText: 'Flutter, Architecture, State Management',
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  key: const ValueKey('input_evidence_source'),
                  controller: sourceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Source Reference (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Self-Study, Personal Project',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const ValueKey('btn_submit_evidence'),
              onPressed: () {
                final title = titleCtrl.text.trim();
                final desc = descCtrl.text.trim();
                if (title.isEmpty || desc.isEmpty) return;

                final rawSkills = skillsCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                widget.viewModel.recordSelfReportedEvidence(
                  title: title,
                  description: desc,
                  skillIds: rawSkills
                      .map((s) => s.toLowerCase().replaceAll(' ', '_'))
                      .toList(),
                  skillNames: rawSkills,
                  sourceReference: sourceCtrl.text.trim().isEmpty
                      ? null
                      : sourceCtrl.text.trim(),
                );
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Record'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: widget.appBar ?? _buildDefaultAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildDisconnectedBanner(),
            _buildTabBar(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              key: const ValueKey('btn_record_evidence'),
              onPressed: _showRecordEvidenceDialog,
              backgroundColor: LearningColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Record Evidence'),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildDefaultAppBar() {
    return AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'My Growth Dashboard',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
              ),
              SizedBox(width: 6.0),
              Icon(Icons.lock_outline,
                  size: 16, color: LearningColors.secondaryText),
            ],
          ),
          Text(
            'Private to you • Self-reflection & verified evidence',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: LearningColors.secondaryText,
            ),
          ),
        ],
      ),
      backgroundColor: LearningColors.cardSurface,
      elevation: 0,
      iconTheme: const IconThemeData(color: LearningColors.heading),
    );
  }

  Widget _buildDisconnectedBanner() {
    return Container(
      key: const ValueKey('banner_growth_disconnected'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: const Color(0xFFFEF3C7),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              LearningGrowthViewModel.disconnectedNotice,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
          const Tab(
            key: ValueKey('tab_overview'),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Overview'),
            ),
          ),
          Tab(
            key: const ValueKey('tab_evidence'),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Evidence'),
                  if (widget.viewModel.totalEvidenceCount > 0) ...[
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${widget.viewModel.totalEvidenceCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Tab(
            key: const ValueKey('tab_skills'),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Skills'),
                  if (widget.viewModel.trackedSkillsCount > 0) ...[
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${widget.viewModel.trackedSkillsCount}',
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
          const Tab(
            key: ValueKey('tab_insights'),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Insights'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (widget.viewModel.status) {
      case LearningGrowthViewStatus.initial:
      case LearningGrowthViewStatus.loading:
        return const Center(
          child: CircularProgressIndicator(
            key: ValueKey('loading_indicator'),
          ),
        );

      case LearningGrowthViewStatus.accessDenied:
        return _buildAccessDeniedState();

      case LearningGrowthViewStatus.unavailableService:
        return _buildUnavailableState();

      case LearningGrowthViewStatus.error:
        return _buildErrorState();

      case LearningGrowthViewStatus.empty:
        return _buildEmptyState();

      case LearningGrowthViewStatus.ready:
        return TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildEvidenceTab(),
            _buildSkillsTab(),
            _buildInsightsTab(),
          ],
        );
    }
  }

  Widget _buildAccessDeniedState() {
    return Center(
      key: const ValueKey('state_access_denied'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline,
                  size: 48, color: Colors.red.shade700),
            ),
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
                  'Authentication and an activated Learning profile are required to view private growth records.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableState() {
    return Center(
      key: const ValueKey('state_unavailable'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_outlined,
                  size: 48, color: Colors.amber.shade700),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Growth Service Unavailable',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ??
                  'The growth backend contract is currently pending or dormant.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              key: const ValueKey('btn_retry_unavailable'),
              onPressed: () => widget.viewModel.initialize(force: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 44),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('state_error'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 48, color: Colors.red.shade700),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Unable to Load Growth Records',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              key: const ValueKey('btn_retry_error'),
              onPressed: () => widget.viewModel.initialize(force: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 44),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('view_growth_empty'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.insights_outlined,
                  size: 48, color: LearningColors.primary),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'No Growth Records Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Start tracking your learning journey by recording self-reported evidence or completing verified partner activities.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              key: const ValueKey('btn_empty_record'),
              onPressed: _showRecordEvidenceDialog,
              icon: const Icon(Icons.add),
              label: const Text('Record First Evidence'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final summary = widget.viewModel.summary;
    final recent = summary.recentEvidence;

    return SingleChildScrollView(
      key: const ValueKey('view_tab_overview'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Privacy Callout
          Container(
            key: const ValueKey('banner_privacy_callout'),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 20, color: Color(0xFF1D4ED8)),
                SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    'Your growth dashboard is strictly private. Only you can view your learning progress, reflections, and evidence.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E40AF),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  key: 'metric_total_evidence',
                  label: 'Total Evidence',
                  count: summary.totalEvidenceCount,
                  icon: Icons.folder_open_outlined,
                  color: LearningColors.primary,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildMetricTile(
                  key: 'metric_verified_evidence',
                  label: 'Verified',
                  count: summary.verifiedEvidenceCount,
                  icon: Icons.verified_outlined,
                  color: const Color(0xFF15803D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  key: 'metric_self_reported',
                  label: 'Self-Reported',
                  count: summary.selfReportedEvidenceCount,
                  icon: Icons.person_outline,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildMetricTile(
                  key: 'metric_tracked_skills',
                  label: 'Tracked Skills',
                  count: summary.trackedSkillsCount,
                  icon: Icons.lightbulb_outline,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),

          // Recent Evidence Header
          const Text(
            'Recent Learning Evidence',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 8.0),

          if (recent.isEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Center(
                child: Text(
                  'No recent evidence recorded.',
                  style: TextStyle(
                      fontSize: 13, color: LearningColors.secondaryText),
                ),
              ),
            )
          else
            ...recent.map(
              (ev) => GrowthEvidenceCard(
                evidence: ev,
                onTap: () => EvidenceDetailSheet.show(context, evidence: ev),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String key,
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      key: ValueKey(key),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: LearningColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceTab() {
    final filtered = widget.viewModel.filteredEvidence;

    return Column(
      key: const ValueKey('view_tab_evidence'),
      children: [
        // Filter Chips and Search Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              TextField(
                key: const ValueKey('input_growth_search'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search evidence by title, skill, or source...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: widget.viewModel.searchQuery.isNotEmpty
                      ? IconButton(
                          key: const ValueKey('btn_clear_search'),
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            widget.viewModel.clearSearch();
                          },
                          constraints:
                              const BoxConstraints(minWidth: 44, minHeight: 44),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      key: 'filter_all',
                      label: 'All Evidence',
                      isSelected: widget.viewModel.kindFilter == null,
                      onSelected: () => widget.viewModel.setKindFilter(null),
                    ),
                    const SizedBox(width: 8.0),
                    _buildFilterChip(
                      key: 'filter_verified',
                      label: 'Verified Source',
                      isSelected: widget.viewModel.kindFilter ==
                          LearningEvidenceKind.verified,
                      onSelected: () => widget.viewModel
                          .setKindFilter(LearningEvidenceKind.verified),
                    ),
                    const SizedBox(width: 8.0),
                    _buildFilterChip(
                      key: 'filter_self_reported',
                      label: 'Self-Reported',
                      isSelected: widget.viewModel.kindFilter ==
                          LearningEvidenceKind.selfReported,
                      onSelected: () => widget.viewModel
                          .setKindFilter(LearningEvidenceKind.selfReported),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Evidence List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_outlined,
                            size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8.0),
                        const Text(
                          'No evidence matches your filter.',
                          style: TextStyle(
                            fontSize: 14,
                            color: LearningColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ev = filtered[index];
                    return GrowthEvidenceCard(
                      evidence: ev,
                      onTap: () =>
                          EvidenceDetailSheet.show(context, evidence: ev),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String key,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      key: ValueKey(key),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: const Color(0xFFDBEAFE),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color:
            isSelected ? const Color(0xFF1D4ED8) : LearningColors.secondaryText,
      ),
    );
  }

  Widget _buildSkillsTab() {
    final skills = widget.viewModel.filteredSkills;

    return SingleChildScrollView(
      key: const ValueKey('view_tab_skills'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sufficiency Notice Banner
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFFB45309)),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Missing evidence does not imply absence of skill. Track your qualitative growth as you complete learning circles and pacts.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          if (skills.isEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Center(
                child: Text(
                  'No skills tracked yet.',
                  style: TextStyle(
                      fontSize: 13, color: LearningColors.secondaryText),
                ),
              ),
            )
          else
            ...skills.map(
              (skill) => GrowthSkillCard(
                skill: skill,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      key: const ValueKey('view_tab_insights'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mentorship Scheduled Notice Banner
          Container(
            key: const ValueKey('banner_mentorship_pending'),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school_outlined, size: 18, color: Color(0xFF1D4ED8)),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    LearningGrowthViewModel.mentorshipPendingNotice,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Topic Gap Action Card
          _buildTopicGapActionCard(context),
          const SizedBox(height: 12.0),

          // Mentorship Action Card
          _buildMentorshipActionCard(context),
          const SizedBox(height: 16.0),

          // Qualitative Learning Reflections
          const Text(
            'Learning Journey Reflections',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 8.0),
          _buildReflectionCard(
            title: 'Continuous Commitment',
            narrative:
                'Focus on steady practice through collaborative learning pacts and circle sessions. Progress is personal and self-paced.',
            icon: Icons.trending_up,
          ),
          const SizedBox(height: 12.0),
          _buildReflectionCard(
            title: 'Evidence Provenance',
            narrative:
                'Verified records reflect peer confirmations and mentor sign-offs, while self-reports capture personal reflections.',
            icon: Icons.verified_user_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTopicGapActionCard(BuildContext context) {
    return Container(
      key: const ValueKey('card_topic_gap_action'),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.analytics_outlined,
                    size: 20, color: Color(0xFFB45309)),
              ),
              const SizedBox(width: 12.0),
              const Expanded(
                child: Text(
                  'Topic Gap Analysis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Explore evidence-grounded analysis of your learning focus areas and recommended next steps.',
            style: TextStyle(
              fontSize: 12,
              color: LearningColors.secondaryText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12.0),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('btn_view_topic_gaps'),
              onPressed: () {
                final topicGapViewModel = LearningTopicGapViewModel(
                  repository: widget.viewModel.repository,
                  sessionController: widget.viewModel.sessionController,
                  isLearningActivated: widget.viewModel.isLearningActivated,
                  currentProfileId: widget.viewModel.currentProfileId,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TopicGapExplanationScreen(
                      viewModel: topicGapViewModel,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View Topic Gaps'),
              style: OutlinedButton.styleFrom(
                foregroundColor: LearningColors.primary,
                side: const BorderSide(color: LearningColors.primary),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorshipActionCard(BuildContext context) {
    return Container(
      key: const ValueKey('card_mentorship_hub_action'),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.people_outline,
                    size: 20, color: Color(0xFF1D4ED8)),
              ),
              const SizedBox(width: 12.0),
              const Expanded(
                child: Text(
                  'Voluntary Peer Mentorship',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Connect with peer mentors for qualitative guidance, structured pacts, and mutual learning goals.',
            style: TextStyle(
              fontSize: 12,
              color: LearningColors.secondaryText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const ValueKey('btn_open_mentorship_hub'),
              onPressed: () {
                final mentorshipViewModel = LearningMentorshipViewModel(
                  repository: widget.viewModel.repository,
                  sessionController: widget.viewModel.sessionController,
                  isLearningActivated: widget.viewModel.isLearningActivated,
                  currentProfileId: widget.viewModel.currentProfileId,
                  currentDisplayName: widget.viewModel.currentDisplayName,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LearningMentorshipHubScreen(
                      viewModel: mentorshipViewModel,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.school, size: 16),
              label: const Text('Explore Peer Mentorship'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionCard({
    required String title,
    required String narrative,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, size: 20, color: LearningColors.primary),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  narrative,
                  style: const TextStyle(
                    fontSize: 12,
                    color: LearningColors.secondaryText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
