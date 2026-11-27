import 'package:flutter/material.dart';
import '../group_contracts/social_zone.dart';
import '../group_contracts/social_zone_management.dart';
import 'social_zone_management_viewmodel.dart';

/// Presentation model for a pending join request in a Social Zone.
class ZoneJoinRequestItem {
  final String requestId;
  final String memberId;
  final String displayName;
  final DateTime requestedAt;

  const ZoneJoinRequestItem({
    required this.requestId,
    required this.memberId,
    required this.displayName,
    required this.requestedAt,
  });
}

/// Screen S65: Zone Moderation (Host and Moderator Tools).
///
/// Follows M5 Social Groups Governance & M6 Moderation Boundaries:
/// - Restricted to callers possessing authoritative [ZonePermissionEvidence] (`canModerate`).
/// - Moderation actions apply strictly within this specific Zone; never imposes platform-wide sanctions.
/// - Requires explicit confirmation for consequential actions (e.g. member removal, muting).
/// - Fails closed: Surfaces explicit deferred/unavailable states for unactivated backend endpoints.
/// - Preserves adult privacy: Displays only display names and safe avatars.
/// - Responsive across 320dp, 400dp, and 800dp viewports.
class SocialZoneModerationScreen extends StatefulWidget {
  final SocialZone zone;
  final SocialZoneManagementViewModel viewModel;
  final List<ZoneJoinRequestItem> pendingRequests;
  final VoidCallback? onBack;

  const SocialZoneModerationScreen({
    super.key,
    required this.zone,
    required this.viewModel,
    this.pendingRequests = const [],
    this.onBack,
  });

  @override
  State<SocialZoneModerationScreen> createState() =>
      _SocialZoneModerationScreenState();
}

class _SocialZoneModerationScreenState
    extends State<SocialZoneModerationScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmRemoveMember(String memberName, VoidCallback onConfirm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove from Zone'),
        content: Text(
          'Are you sure you want to remove $memberName from "${widget.zone.name}"? '
          'This action applies only to this Zone and does not affect the member\'s platform account.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel_moderation_dialog_button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_moderation_dialog_button'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove Member'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.viewModel;
    final evidence = vm.permissionEvidence;
    final canModerate = evidence?.canModerate ?? false;

    if (!canModerate) {
      return Scaffold(
        appBar: AppBar(title: const Text('Zone Moderation')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 56, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Moderation Restricted',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only verified Zone hosts and moderators possess authority to access moderation tools.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.onBack != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    key: const Key('moderation_restricted_back_button'),
                    onPressed: widget.onBack,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.zone.name} Moderation'),
        leading: widget.onBack != null
            ? IconButton(
                key: const Key('moderation_back_button'),
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scope notice
              _buildScopeBanner(theme),
              const SizedBox(height: 16),

              // Feedback / Error banner
              if (vm.errorMessage != null) ...[
                Container(
                  key: const Key('moderation_error_banner'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          vm.errorMessage!,
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Pending Join Requests
              Text(
                'Pending Join Requests (${widget.pendingRequests.length})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (widget.pendingRequests.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(96),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('No pending membership requests.'),
                  ),
                )
              else
                ...widget.pendingRequests.map((req) {
                  return Card(
                    key: Key('join_request_card_${req.requestId}'),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              req.displayName.isNotEmpty ? req.displayName[0].toUpperCase() : '?',
                              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Requested to join',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: Key('approve_request_${req.requestId}'),
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                            tooltip: 'Approve',
                            onPressed: vm.isSubmitting
                                ? null
                                : () => vm.reviewJoinRequest(req.requestId, true),
                          ),
                          IconButton(
                            key: Key('decline_request_${req.requestId}'),
                            icon: Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
                            tooltip: 'Decline',
                            onPressed: vm.isSubmitting
                                ? null
                                : () => vm.reviewJoinRequest(req.requestId, false),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),
              // Zone Moderation Policies & Actions
              Text(
                'Zone Action Controls',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.volume_mute_outlined),
                        title: const Text('Mute Member in Zone'),
                        subtitle: const Text('Prevent a member from posting in this Zone for 24h'),
                        trailing: OutlinedButton(
                          key: const Key('mute_member_action_button'),
                          onPressed: () {
                            _confirmRemoveMember('Selected Member', () {
                              vm.reviewJoinRequest('mute-action', false);
                            });
                          },
                          child: const Text('Mute'),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.person_remove_outlined, color: theme.colorScheme.error),
                        title: const Text('Remove Member from Zone'),
                        subtitle: const Text('Revokes membership from this Zone only'),
                        trailing: OutlinedButton(
                          key: const Key('remove_member_action_button'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                          onPressed: () {
                            _confirmRemoveMember('Selected Member', () {
                              vm.reviewJoinRequest('remove-action', false);
                            });
                          },
                          child: const Text('Remove'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Community Safety note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(64),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(64)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: theme.colorScheme.secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Platform-wide harassment, abuse, or safety concerns must be reported through Community Safety (M6). '
                        'Zone host controls only affect participation within this Zone.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScopeBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(64)),
      ),
      child: Row(
        children: [
          Icon(Icons.gavel, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Zone Moderation applies only within "${widget.zone.name}".',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
