import 'package:flutter/material.dart';
import '../group_contracts/social_zone.dart';
import 'social_zones_viewmodel.dart';

/// Presentation screen for user's joined and managed Social Zones (CF-07 / S48 My Zones).
///
/// Follows M5 Social Groups Governance:
/// - Displays authoritative membership and management entry points.
/// - Does not manufacture fraudulent ownership privileges.
/// - Responsive across 320dp, 400dp, and 800dp viewports.
class SocialMyZonesScreen extends StatelessWidget {
  final SocialZonesViewModel viewModel;
  final ValueChanged<SocialZone>? onZoneSelected;
  final ValueChanged<SocialZone>? onManageZone;
  final VoidCallback? onCreateZone;
  final VoidCallback? onBack;

  const SocialMyZonesScreen({
    super.key,
    required this.viewModel,
    this.onZoneSelected,
    this.onManageZone,
    this.onCreateZone,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = viewModel;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Zones'),
          leading: onBack != null
              ? IconButton(
                  key: const Key('my_zones_back_button'),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                )
              : null,
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('joined_zones_tab'), text: 'Joined'),
              Tab(key: Key('managed_zones_tab'), text: 'Managed by Me'),
            ],
          ),
          actions: [
            if (onCreateZone != null)
              IconButton(
                key: const Key('my_zones_create_button'),
                icon: const Icon(Icons.add),
                tooltip: 'Create Zone',
                onPressed: onCreateZone,
              ),
          ],
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: vm,
            builder: (context, _) {
              if (vm.isLoading && vm.zones.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final joinedZones = vm.zones.where((z) => z.isJoined).toList();
              final managedZones = vm.zones.where((z) => z.isHost).toList();

              return TabBarView(
                children: [
                  _buildJoinedZonesList(context, theme, joinedZones),
                  _buildManagedZonesList(context, theme, managedZones),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildJoinedZonesList(BuildContext context, ThemeData theme, List<SocialZone> zones) {
    if (zones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off_outlined, size: 56, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('No Joined Zones Yet', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Explore interest communities and join discussions that match your passions.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: zones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final zone = zones[index];
        return Card(
          key: Key('my_zone_card_${zone.id}'),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.groups, color: theme.colorScheme.primary),
            ),
            title: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${zone.category} • ${zone.memberCount} members'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              viewModel.selectZone(zone);
              onZoneSelected?.call(zone);
            },
          ),
        );
      },
    );
  }

  Widget _buildManagedZonesList(BuildContext context, ThemeData theme, List<SocialZone> zones) {
    if (zones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 56, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('No Managed Zones', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Zones where you are a verified Host or Moderator will appear here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (onCreateZone != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('create_zone_empty_state_button'),
                  onPressed: onCreateZone,
                  icon: const Icon(Icons.add),
                  label: const Text('Create a Zone'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: zones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final zone = zones[index];
        return Card(
          key: Key('managed_zone_card_${zone.id}'),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(Icons.stars, color: theme.colorScheme.secondary),
            ),
            title: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Host • ${zone.memberCount} members'),
            trailing: FilledButton.tonal(
              key: Key('manage_zone_btn_${zone.id}'),
              child: const Text('Manage'),
              onPressed: () => onManageZone?.call(zone),
            ),
          ),
        );
      },
    );
  }
}
