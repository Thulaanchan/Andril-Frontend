import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_pact.dart';

/// Presentation card displaying a single Learning Pact in Hub lists (LRN-03).
///
/// Features:
/// - Pact title and partner name.
/// - Status badge: Active, Pending Acceptance, Completed, Cancelled.
/// - Shared goal summary and self-reported progress bar.
/// - Contextual action buttons (View Progress, Review Invitation, View History).
/// - Touch targets >= 44dp.
class LearningPactCard extends StatelessWidget {
  final LearningPact pact;
  final String currentProfileId;
  final VoidCallback? onViewProgress;
  final VoidCallback? onReviewInvitation;
  final VoidCallback? onViewHistory;
  final bool isProcessing;

  const LearningPactCard({
    super.key,
    required this.pact,
    required this.currentProfileId,
    this.onViewProgress,
    this.onReviewInvitation,
    this.onViewHistory,
    this.isProcessing = false,
  });

  Widget _buildStatusBadge() {
    if (pact.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: const Text(
          'Active Pact',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF15803D),
          ),
        ),
      );
    }

    if (pact.isPending) {
      final isProposer = pact.isProposer(currentProfileId);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Text(
          isProposer ? 'Pending Partner' : 'Invitation Received',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB45309),
          ),
        ),
      );
    }

    if (pact.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E7FF),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: const Text(
          'Completed',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4338CA),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: const Text(
        'Cancelled',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFFB91C1C),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partner = pact.getPartner(currentProfileId);
    final partnerName = partner?.participantDisplayName ?? 'Learning Partner';
    final isIncomingPending =
        pact.isPending && !pact.isProposer(currentProfileId);

    return Card(
      key: ValueKey('card_learning_pact_${pact.id}'),
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
            // Top row: Module pill, Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: LearningColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: const Text(
                    'Learning Pact',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: LearningColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 10.0),

            // Title
            Text(
              pact.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6.0),

            // Partner details
            Row(
              children: [
                const Icon(
                  Icons.handshake_outlined,
                  size: 16,
                  color: LearningColors.secondaryText,
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    'Partner: $partnerName',
                    style: const TextStyle(
                      fontSize: 13,
                      color: LearningColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),

            // Goal
            Text(
              pact.sharedGoal,
              style: const TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Progress bar if active or completed
            if (pact.commitments.isNotEmpty &&
                (pact.isActive || pact.isCompleted)) ...[
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${pact.completedCommitmentsCount} of ${pact.commitments.length} Milestones',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: LearningColors.heading,
                    ),
                  ),
                  Text(
                    '${pact.progressPercent}% Complete',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: LearningColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: pact.commitments.isEmpty
                      ? 0
                      : pact.progressPercent / 100.0,
                  minHeight: 6.0,
                  backgroundColor:
                      LearningColors.primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pact.isCompleted
                        ? const Color(0xFF15803D)
                        : LearningColors.primary,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14.0),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 44.0,
              child: isIncomingPending
                  ? ElevatedButton.icon(
                      key: ValueKey('btn_review_invitation_${pact.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LearningColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      icon: const Icon(Icons.mail_outline, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Review Invitation'),
                      ),
                      onPressed: onReviewInvitation,
                    )
                  : OutlinedButton.icon(
                      key: ValueKey('btn_view_pact_${pact.id}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LearningColors.primary,
                        side: const BorderSide(color: LearningColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      icon: Icon(
                        pact.isActive ? Icons.trending_up : Icons.history,
                        size: 18,
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                            pact.isActive ? 'View Progress' : 'View Details'),
                      ),
                      onPressed: pact.isActive ? onViewProgress : onViewHistory,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
