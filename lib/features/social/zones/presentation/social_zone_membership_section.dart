import 'package:flutter/material.dart';
import '../group_contracts/social_zone.dart';
import 'social_zones_viewmodel.dart';

/// Reusable presentation component for Social Zone membership status and actions.
///
/// Follows M5 Social Groups Governance:
/// - Renders Join, Leave, Pending, or Host standing based on authoritative membership evidence.
/// - Does not invent client-side automatic approval or arbitrary host privileges.
/// - Gracefully surfaces backend service availability and feedback diagnostics.
class SocialZoneMembershipSection extends StatelessWidget {
  final SocialZone zone;
  final SocialZonesViewModel viewModel;

  const SocialZoneMembershipSection({
    super.key,
    required this.zone,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = viewModel;

    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        final currentZone = vm.selectedZone?.id == zone.id ? vm.selectedZone! : zone;
        final status = currentZone.membershipStatus;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vm.actionFeedbackMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  vm.actionFeedbackMessage!,
                  style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (vm.isActionInProgress)
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
                    onPressed: () => vm.joinZone(currentZone.id),
                  ),
                ZoneMembershipStatus.pendingApproval => OutlinedButton.icon(
                    key: const Key('pending_approval_button'),
                    icon: const Icon(Icons.hourglass_top),
                    label: const Text('Membership Pending Approval'),
                    onPressed: null, // Disabled pending host action
                  ),
                ZoneMembershipStatus.member => OutlinedButton.icon(
                    key: const Key('leave_zone_button'),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Leave Zone'),
                    style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    onPressed: () => vm.leaveZone(currentZone.id),
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
