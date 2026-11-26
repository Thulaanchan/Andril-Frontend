import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';
import '../../../discovery/domain/entities/learning_partner_candidate.dart';

/// Modal dialog for sending a connection request to an eligible learning partner candidate (CF-05).
///
/// Features:
/// - Candidate name and skill highlights.
/// - Contextual note input (optional, max 200 characters).
/// - Character counter.
/// - Send Request and Cancel action controls.
/// - Touch target accessibility >= 44dp.
class SendConnectionRequestDialog extends StatefulWidget {
  final LearningPartnerCandidate candidate;
  final Future<bool> Function(String? note) onSend;

  const SendConnectionRequestDialog({
    super.key,
    required this.candidate,
    required this.onSend,
  });

  /// Displays the [SendConnectionRequestDialog] modal.
  static Future<bool?> show(
    BuildContext context, {
    required LearningPartnerCandidate candidate,
    required Future<bool> Function(String? note) onSend,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SendConnectionRequestDialog(
        candidate: candidate,
        onSend: onSend,
      ),
    );
  }

  @override
  State<SendConnectionRequestDialog> createState() =>
      _SendConnectionRequestDialogState();
}

class _SendConnectionRequestDialogState
    extends State<SendConnectionRequestDialog> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final note = _noteController.text.trim();
      final success = await widget.onSend(note.isEmpty ? null : note);
      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _isSending = false;
            _errorMessage = 'Could not send request. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = 'An error occurred while sending request.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey('dialog_send_connection_request'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: LearningColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1,
                      color: LearningColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      'Connect with ${widget.candidate.displayName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Candidate skills summary
              if (widget.candidate.skillsToShare.isNotEmpty) ...[
                Text(
                  'Skills: ${widget.candidate.skillsToShare.take(3).join(', ')}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: LearningColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 12.0),
              ],

              // Note input
              const Text(
                'Add an introduction note (optional):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 8.0),
              TextField(
                key: const ValueKey('input_connection_note'),
                controller: _noteController,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'e.g., Hi! I saw your Flutter skills and would love to exchange knowledge on Dart.',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: LearningColors.secondaryText.withValues(alpha: 0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: LearningColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8.0),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ],

              const SizedBox(height: 20.0),

              // Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 44.0,
                    child: TextButton(
                      key: const ValueKey('btn_cancel_send_request'),
                      onPressed: _isSending
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  SizedBox(
                    height: 44.0,
                    child: ElevatedButton(
                      key: const ValueKey('btn_confirm_send_request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LearningColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: _isSending ? null : _handleSend,
                      child: _isSending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send Request'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
