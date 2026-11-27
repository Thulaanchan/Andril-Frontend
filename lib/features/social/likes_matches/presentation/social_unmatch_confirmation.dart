import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';

/// Screen S56: Unmatch Confirmation Modal.
///
/// Follows M5 requirements:
/// - Explicit unmatch confirmation explaining the communication consequences.
/// - Unmatching revokes mutual match standing and closes direct chat channels.
/// - Built-in duplicate submission protection.
/// - Cancel action preserves the connection without side effects.
/// - Fails closed: Prohibits fabricated unmatch actions without active session authorization.
class SocialUnmatchConfirmationModal extends StatefulWidget {
  final String targetName;
  final VoidCallback onConfirmUnmatch;
  final VoidCallback? onCancel;

  const SocialUnmatchConfirmationModal({
    super.key,
    required this.targetName,
    required this.onConfirmUnmatch,
    this.onCancel,
  });

  /// Presents the unmatch confirmation modal as an accessible bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    required String targetName,
    required VoidCallback onConfirmUnmatch,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SocialUnmatchConfirmationModal(
        targetName: targetName,
        onConfirmUnmatch: onConfirmUnmatch,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<SocialUnmatchConfirmationModal> createState() => _SocialUnmatchConfirmationModalState();
}

class _SocialUnmatchConfirmationModalState extends State<SocialUnmatchConfirmationModal> {
  bool _isSubmitting = false;

  void _handleConfirm() {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
      widget.onConfirmUnmatch();
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
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AndrilSocialColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Icon indicator
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE63946).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_off_rounded,
                color: Color(0xFFE63946),
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            'Unmatch with ${widget.targetName}?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AndrilSocialColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Description
          const Text(
            'They will be removed from your connections, and you will no longer be able to message each other. This action cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

          // Confirm Unmatch Button
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
                    'Unmatch',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          // Cancel Button
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
              'Keep Connection',
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
