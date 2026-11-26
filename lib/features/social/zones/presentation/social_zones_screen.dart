import 'package:flutter/material.dart';
import '../group_contracts/social_zone.dart';
import 'social_zones_viewmodel.dart';

/// Presentation screen for Social Zones home / landing (S44/CF-07).
///
/// Follows M5 Social Groups Governance:
/// - Displays available community interest zones categorized by topic.
/// - Supports searching and category filtering.
/// - Shows explicit states: loading, empty, denied, error, and dormant unavailable.
/// - Fully responsive across 320dp, 400dp, and 800dp viewports.
class SocialZonesScreen extends StatefulWidget {
  final SocialZonesViewModel viewModel;
  final ValueChanged<SocialZone>? onZoneSelected;
  final VoidCallback? onCreateZone;
  final VoidCallback? onMyZones;

  const SocialZonesScreen({
    super.key,
    required this.viewModel,
    this.onZoneSelected,
    this.onCreateZone,
    this.onMyZones,
  });

  @override
  State<SocialZonesScreen> createState() => _SocialZonesScreenState();
}

class _SocialZonesScreenState extends State<SocialZonesScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'All',
    'Technology',
    'Outdoors',
    'Creative Arts',
    'Lifestyle',
  ];

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    if (widget.viewModel.status == SocialZonesStatus.initial) {
      widget.viewModel.loadZones();
    }
  }

  @override
  void didUpdateWidget(covariant SocialZonesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      widget.viewModel.addListener(_onViewModelChanged);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Zones'),
        actions: [
          if (widget.onMyZones != null)
            IconButton(
              key: const Key('my_zones_button'),
              icon: const Icon(Icons.bookmark_outline),
              tooltip: 'My Zones',
              onPressed: widget.onMyZones,
            ),
          IconButton(
            key: const Key('refresh_zones_button'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: vm.isLoading ? null : () => vm.loadZones(refresh: true),
          ),
        ],
      ),
      floatingActionButton: widget.onCreateZone != null
          ? FloatingActionButton.extended(
              key: const Key('create_zone_fab'),
              onPressed: widget.onCreateZone,
              icon: const Icon(Icons.add),
              label: const Text('Create Zone'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilters(theme, vm),
            Expanded(child: _buildBody(context, theme, vm)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme, SocialZonesViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            key: const Key('zone_search_field'),
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search interest zones...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        vm.setSearchQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: (val) => vm.setSearchQuery(val),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = vm.selectedCategory.toLowerCase() == cat.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    key: Key('category_chip_${cat.toLowerCase().replaceAll(' ', '_')}'),
                    selected: isSelected,
                    label: Text(cat),
                    onSelected: (_) => vm.setCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, SocialZonesViewModel vm) {
    if (vm.isAccessDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Access Restricted', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                vm.errorMessage ?? 'Active Social opt-in and adult eligibility are required.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => vm.loadZones(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.isServiceUnavailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 56, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('Zones Temporarily Deferred', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                vm.errorMessage ?? 'Social Zone groups backend service is temporarily dormant.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (vm.isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to Load Zones', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(vm.errorMessage ?? 'An unexpected error occurred.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => vm.loadZones(refresh: true),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.isLoading && vm.zones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.isEmpty || vm.zones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.groups_outlined, size: 56, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('No Zones Found', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                vm.searchQuery.isNotEmpty
                    ? 'No zones matching "${vm.searchQuery}". Try a different keyword.'
                    : 'No zones in this category yet. Explore other topics or create one!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadZones(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vm.zones.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final zone = vm.zones[index];
          return Card(
            key: Key('zone_card_${zone.id}'),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                vm.selectZone(zone);
                widget.onZoneSelected?.call(zone);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.groups, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                zone.name,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${zone.category} • ${zone.memberCount} members',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        if (zone.isJoined)
                          Chip(
                            label: const Text('Joined', style: TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: theme.colorScheme.secondaryContainer,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      zone.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
