import 'package:flutter/material.dart';
import '../group_contracts/social_zone.dart';
import 'social_zones_viewmodel.dart';

/// Presentation screen for browsing and discovering Social Zones (S45 Zone Discovery).
///
/// Follows M5 Social Groups Governance:
/// - Allows browsing interest communities across topics.
/// - Does not manufacture unapproved location-based recommendations, ranking algorithms, or fake match criteria.
/// - Responsive layout supporting 320dp, 400dp, and 800dp viewports.
class SocialZoneDiscoveryScreen extends StatelessWidget {
  final SocialZonesViewModel viewModel;
  final ValueChanged<SocialZone>? onZoneSelected;
  final VoidCallback? onBack;

  const SocialZoneDiscoveryScreen({
    super.key,
    required this.viewModel,
    this.onZoneSelected,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = viewModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Zones'),
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: vm,
          builder: (context, _) {
            if (vm.isLoading && vm.zones.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.isAccessDenied) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Access Denied', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        vm.errorMessage ?? 'Social opt-in is required to explore Zones.',
                        textAlign: TextAlign.center,
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
                      Icon(Icons.cloud_off, size: 56, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text('Discovery Unavailable', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        vm.errorMessage ?? 'Zone discovery is temporarily deferred.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (vm.zones.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_off, size: 56, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('No Zones Available', style: theme.textTheme.titleMedium),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                final crossAxisCount = isWide ? 2 : 1;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 160,
                  ),
                  itemCount: vm.zones.length,
                  itemBuilder: (context, index) {
                    final zone = vm.zones[index];
                    return Card(
                      key: Key('discovery_zone_card_${zone.id}'),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          vm.selectZone(zone);
                          onZoneSelected?.call(zone);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: theme.colorScheme.tertiaryContainer,
                                    child: Icon(Icons.hub_outlined, color: theme.colorScheme.tertiary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          zone.name,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${zone.category} • ${zone.memberCount} members',
                                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Text(
                                  zone.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              if (zone.tags.isNotEmpty)
                                Wrap(
                                  spacing: 4,
                                  children: zone.tags.take(3).map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('#$tag', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                                  )).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
