import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_connection_request.dart';

/// Card component presenting a Learning connection request (incoming or outgoing) (CF-05).
///
/// Features:
/// - Partner display name, initials, and optional intro note.
/// - Incoming requests: [onAccept] and [onDecline] action controls.
/// - Outgoing requests: [onCancel] action control with confirmation.
/// - In-flight operation indicator disables buttons while processing.
/// - Minimum 44dp accessible touch targets.
/// - Responsive down to 320dp viewports and with 1.5x dynamic font scaling.
class LearningRequestCard extends StatelessWidget {
  final LearningConnectionRequest request;
  final ValueChanged<LearningConnectionRequest>? onAccept;
  final ValueChanged<LearningConnectionRequest>? onDecline;
  final ValueChanged<LearningConnectionRequest>? onCancel;
  final bool isProcessing;

  const LearningRequestCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onDecline,
    this.onCancel,
    this.isProcessing = false,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'LR';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showDeclineConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Decline Request?'),
        content: Text(
          'Are you sure you want to decline the connection request from ${request.senderDisplayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop(true);
              onDecline?.call(request);
            },
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: Text(
          'Are you sure you want to cancel your connection request to ${request.receiverDisplayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Keep Request'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop(true);
              onCancel?.call(request);
            },
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnerName = request.isIncoming
        ? request.senderDisplayName
        : request.receiverDisplayName;
    final initials = _getInitials(partnerName);
    final formattedDate = _formatDate(request.createdAt);

    return Card(
      key: ValueKey('card_learning_request_${request.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: LearningColors.cardSurface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Avatar, Partner Name, Status Badge, Timestamp
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      LearningColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: LearningColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              partnerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: LearningColors.heading,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        request.isIncoming
                            ? 'Received on $formattedDate'
                            : 'Sent on $formattedDate',
                        style: const TextStyle(
                          fontSize: 12,
                          color: LearningColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Optional Note / Introduction message
            if (request.note != null && request.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 12.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Text(
                  '"${request.note!.trim()}"',
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: LearningColors.heading,
                  ),
                ),
              ),
            ],

            // Skills chips (if incoming sender has skills)
            if (request.senderSkills.isNotEmpty) ...[
              const SizedBox(height: 10.0),
              Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: request.senderSkills.take(3).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: LearningColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 11,
                        color: LearningColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 14.0),

            // Action Buttons
            if (isProcessing)
              const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (request.isIncoming)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44.0,
                      child: OutlinedButton(
                        key: ValueKey('btn_decline_request_${request.id}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onPressed: onDecline != null
                            ? () => _showDeclineConfirmation(context)
                            : null,
                        child: const Text('Decline'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: SizedBox(
                      height: 44.0,
                      child: ElevatedButton(
                        key: ValueKey('btn_accept_request_${request.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LearningColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onPressed:
                            onAccept != null ? () => onAccept!(request) : null,
                        child: const Text('Accept'),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 44.0,
                child: OutlinedButton(
                  key: ValueKey('btn_cancel_request_${request.id}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: onCancel != null
                      ? () => _showCancelConfirmation(context)
                      : null,
                  child: const Text('Cancel Request'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
