import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/classroom_join_request.dart';
import '../../domain/entities/learning_classroom.dart';

/// Modal dialog allowing a classroom host/educator to review and decide upon pending admission requests.
///
/// Features:
/// - List of pending admission requests with applicant profile ID, optional note, and timestamp.
/// - Approve and decline actions with immediate callback invocation.
/// - Empty state when all requests have been processed.
/// - Accessible touch targets >= 44dp.
class HostClassroomRequestsDialog extends StatelessWidget {
  final LearningClassroom classroom;
  final List<ClassroomJoinRequest> pendingRequests;
  final void Function(ClassroomJoinRequest request) onApprove;
  final void Function(ClassroomJoinRequest request) onDecline;

  const HostClassroomRequestsDialog({
    super.key,
    required this.classroom,
    required this.pendingRequests,
    required this.onApprove,
    required this.onDecline,
  });

  /// Displays the [HostClassroomRequestsDialog] modal.
  static Future<void> show(
    BuildContext context, {
    required LearningClassroom classroom,
    required List<ClassroomJoinRequest> pendingRequests,
    required void Function(ClassroomJoinRequest request) onApprove,
    required void Function(ClassroomJoinRequest request) onDecline,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => HostClassroomRequestsDialog(
        classroom: classroom,
        pendingRequests: pendingRequests,
        onApprove: onApprove,
        onDecline: onDecline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: LearningColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.people_alt_outlined,
                      color: LearningColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admission Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: LearningColors.heading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          classroom.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: LearningColors.secondaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Request list or empty state
              Expanded(
                child: pendingRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No Pending Requests',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: LearningColors.heading,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All applicant requests for this classroom have been reviewed.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: pendingRequests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final req = pendingRequests[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.account_circle_outlined,
                                      size: 20,
                                      color: LearningColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Applicant: ${req.applicantProfileId}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                          color: LearningColors.heading,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (req.note != null &&
                                    req.note!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '"${req.note!}"',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12.5,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      key: ValueKey(
                                          'btn_decline_${req.requestId}'),
                                      onPressed: () {
                                        onDecline(req);
                                        Navigator.of(context).pop();
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red.shade700,
                                        side: BorderSide(
                                            color: Colors.red.shade300),
                                        minimumSize: const Size(80, 44),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Decline'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      key: ValueKey(
                                          'btn_approve_${req.requestId}'),
                                      onPressed: () {
                                        onApprove(req);
                                        Navigator.of(context).pop();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(90, 44),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Approve'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(80, 44),
                    foregroundColor: LearningColors.secondaryText,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
