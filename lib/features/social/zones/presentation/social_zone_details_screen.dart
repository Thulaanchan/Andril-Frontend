import 'package:flutter/material.dart';
import '../group_contracts/social_zone.dart';
import 'social_zones_viewmodel.dart';

/// Presentation screen for viewing Social Zone details (S46 Zone Details).
///
/// Follows M5 Social Groups & Privacy Governance:
/// - Displays authorized Zone title, description, category, member count, and guidelines.
/// - Does not expose unauthorized members, private contact details, or other-module profiles.
/// - Incorporates membership action section with fails-closed backend status.
/// - Responsive layout supporting 320dp, 400dp, and 800dp viewports.
class SocialZoneDetailsScreen extends StatelessWidget {
  final SocialZone zone;
  final SocialZonesViewModel viewModel;
  final Widget? membershipSection;
  final VoidCallback? onBack;
  final VoidCallback? onMembersPressed;

  const SocialZoneDetailsScreen({
    super.key,
    required this.zone,
    required this.viewModel,
    this.membershipSection,
    this.onBack,
    this.onMembersPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(zone.name),
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              _buildHeader(theme),
              const SizedBox(height: 20),
              // Membership actions section (custom or default)
              membershipSection ?? _buildDefaultMembershipSection(context, theme),
              const SizedBox(height: 24),
              // About / Description
              Text(
                'About This Zone',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  zone.description,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              // Community Rules
              if (zone.rules.isNotEmpty) ...[
                Text(
                  'Community Guidelines',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...zone.rules.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${entry.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(entry.value, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
              // Member summary entry
              if (onMembersPressed != null)
                ListTile(
                  key: const Key('zone_members_tile'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: theme.colorScheme.surfaceContainerHighest.withAlpha(64),
                  leading: const Icon(Icons.people_outline),
                  title: Text('View Members (${zone.memberCount})'),
                  subtitle: const Text('Only public profiles in this zone are visible'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onMembersPressed,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.groups, size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${zone.category} • ${zone.memberCount} members',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultMembershipSection(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        final currentZone = viewModel.selectedZone?.id == zone.id ? viewModel.selectedZone! : zone;
        final status = currentZone.membershipStatus;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (viewModel.actionFeedbackMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  viewModel.actionFeedbackMessage!,
                  style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (viewModel.isActionInProgress)
              const Center(child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ))
            else ...[
              switch (status) {
                ZoneMembershipStatus.notMember => FilledButton.icon(
                    key: const Key('join_zone_button'),
                    icon: const Icon(Icons.group_add),
                    label: Text(currentZone.requiresApproval ? 'Request to Join' : 'Join Zone'),
                    onPressed: () => viewModel.joinZone(currentZone.id),
                  ),
                ZoneMembershipStatus.pendingApproval => OutlinedButton.icon(
                    key: const Key('pending_approval_button'),
                    icon: const Icon(Icons.hourglass_top),
                    label: const Text('Membership Pending Approval'),
                    onPressed: null,
                  ),
                ZoneMembershipStatus.member => OutlinedButton.icon(
                    key: const Key('leave_zone_button'),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Leave Zone'),
                    style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    onPressed: () => viewModel.leaveZone(currentZone.id),
                  ),
                ZoneMembershipStatus.host => Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(128),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stars, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Zone Host', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              },
            ],
          ],
        );
      },
    );
  }
}
