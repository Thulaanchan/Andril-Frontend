import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';

/// Screen S53: Pass on Profile Confirmation.
///
/// Follows M5 requirements:
/// - Explicit pass confirmation to prevent accidental dismissal.
/// - Clear messaging: Passed candidate will not be notified and will not appear in immediate recommendations.
/// - Cancel action returns cleanly without altering candidate standing.
/// - Prevents duplicate submission via internal submission guarding.
/// - Fails closed: No fabricated persistence or rediscovery policies.
class SocialPassConfirmationModal extends StatefulWidget {
  final String candidateName;
  final VoidCallback onConfirmPass;
  final VoidCallback? onCancel;

  const SocialPassConfirmationModal({
    super.key,
    required this.candidateName,
    required this.onConfirmPass,
    this.onCancel,
  });

  /// Displays the pass confirmation modal as an accessible bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    required String candidateName,
    required VoidCallback onConfirmPass,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SocialPassConfirmationModal(
        candidateName: candidateName,
        onConfirmPass: onConfirmPass,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<SocialPassConfirmationModal> createState() => _SocialPassConfirmationModalState();
}

class _SocialPassConfirmationModalState extends State<SocialPassConfirmationModal> {
  bool _isSubmitting = false;

  void _handleConfirm() {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
      widget.onConfirmPass();
    } finally {
      if (mounted) {
        Navigator.of(context).maybePop(true);
      }
    }
  }

  void _handleCancel() {
    if (_isSubmitting) return;
    widget.onCancel?.call();
    Navigator.of(context).maybePop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AndrilSocialColors.canvasCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AndrilSocialColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Icon indicator
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE63946).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFFE63946),
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Pass on ${widget.candidateName}?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AndrilSocialColors.ink,
            ),
          ),
          const SizedBox(height: 10),

          // Body explanation
          Text(
            'You won\'t see ${widget.candidateName}\'s profile in your discovery recommendations. They will not be notified that you passed.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Confirm Pass Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Pass on Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          // Cancel / Keep Exploring Button
          TextButton(
            onPressed: _isSubmitting ? null : _handleCancel,
            style: TextButton.styleFrom(
              foregroundColor: AndrilSocialColors.ink,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Keep Exploring',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
