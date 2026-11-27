import 'package:flutter/material.dart';
import '../group_contracts/social_zone.dart';

/// Supported membership transition actions for Zone confirmation dialogs.
enum ZoneMembershipAction {
  join,
  leave,
}

/// Confirmation modal dialog for joining or leaving a Social Zone (S24 Join / S66 Leave).
///
/// Follows M5 Social Groups Governance:
/// - Distinguishes between direct join and host-approval-required join flows.
/// - Clearly states consequences of leaving (revocation of member interactions).
/// - Fails closed and reports unavailable backend state without fabricating membership.
/// - Prevents duplicate concurrent submissions.
/// - Responsive across 320dp, 400dp, and 800dp viewports.
class SocialZoneMembershipConfirmationDialog extends StatefulWidget {
  final SocialZone zone;
  final ZoneMembershipAction action;
  final Future<void> Function()? onConfirm;
  final VoidCallback? onCancel;

  const SocialZoneMembershipConfirmationDialog({
    super.key,
    required this.zone,
    required this.action,
    this.onConfirm,
    this.onCancel,
  });

  @override
  State<SocialZoneMembershipConfirmationDialog> createState() =>
      _SocialZoneMembershipConfirmationDialogState();
}

class _SocialZoneMembershipConfirmationDialogState
    extends State<SocialZoneMembershipConfirmationDialog> {
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isJoin => widget.action == ZoneMembershipAction.join;

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;

    if (widget.onConfirm != null) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        await widget.onConfirm!();
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'An unexpected error occurred. Please try again.';
          });
        }
      }
    } else {
      Navigator.of(context).maybePop(true);
    }
  }

  void _handleCancel() {
    if (_isSubmitting) return;
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).maybePop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isJoin = _isJoin;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      title: Row(
        children: [
          Icon(
            isJoin ? Icons.group_add_outlined : Icons.exit_to_app_outlined,
            color: isJoin ? theme.colorScheme.primary : theme.colorScheme.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isJoin
                  ? (widget.zone.requiresApproval ? 'Request to Join' : 'Join Zone')
                  : 'Leave Zone',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isJoin
                  ? 'Would you like to join "${widget.zone.name}"?'
                  : 'Are you sure you want to leave "${widget.zone.name}"?',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isJoin
                  ? (widget.zone.requiresApproval
                      ? 'This zone requires host approval. Your request will be submitted to the host for review.'
                      : 'You will be able to participate in discussions, see zone events, and connect with members.')
                  : 'You will no longer receive zone updates or have access to member discussions. You can rejoin at any time.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('membership_confirmation_error'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel_membership_action_button'),
          onPressed: _isSubmitting ? null : _handleCancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: Key(isJoin ? 'confirm_join_zone_button' : 'confirm_leave_zone_button'),
          style: isJoin
              ? null
              : FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
          onPressed: _isSubmitting ? null : _handleConfirm,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isJoin ? (widget.zone.requiresApproval ? 'Submit Request' : 'Join Zone') : 'Leave Zone'),
        ),
      ],
    );
  }
}
