import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_pact.dart';

/// Modal bottom sheet presenting a received Learning Pact invitation (LRN-03).
///
/// Follows design specification Q32_LUC-18:
/// - Informs the learner that the pact does NOT activate until voluntary mutual acceptance.
/// - Allows reviewing terms before choosing to Accept or Decline.
/// - Minimum 44dp touch targets.
class PactInvitationBottomSheet extends StatelessWidget {
  final LearningPact pact;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isProcessing;

  const PactInvitationBottomSheet({
    super.key,
    required this.pact,
    required this.onAccept,
    required this.onDecline,
    this.isProcessing = false,
  });

  /// Displays the [PactInvitationBottomSheet] modal.
  static Future<void> show(
    BuildContext context, {
    required LearningPact pact,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    bool isProcessing = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PactInvitationBottomSheet(
        pact: pact,
        onAccept: () {
          Navigator.of(ctx).pop();
          onAccept();
        },
        onDecline: () {
          Navigator.of(ctx).pop();
          onDecline();
        },
        isProcessing: isProcessing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('sheet_pact_invitation'),
      decoration: const BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),

              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: LearningColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mail_outline,
                      color: LearningColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Text(
                      'Learning Pact Invitation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Proposer Card
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: LearningColors.background,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          LearningColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        pact.proposerDisplayName.isNotEmpty
                            ? pact.proposerDisplayName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: LearningColors.primary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pact.proposerDisplayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: LearningColors.heading,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          const Text(
                            'Invited you to a Learning Pact',
                            style: TextStyle(
                              fontSize: 12,
                              color: LearningColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Pact Details Section
              const Text(
                'Pact Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 10.0),

              // Title & Goal
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: LearningColors.background,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pact.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      pact.sharedGoal,
                      style: const TextStyle(
                        fontSize: 13,
                        color: LearningColors.secondaryText,
                        height: 1.3,
                      ),
                    ),
                    if (pact.duration != null || pact.studyPlan != null) ...[
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          if (pact.duration != null) ...[
                            const Icon(Icons.schedule,
                                size: 14, color: LearningColors.secondaryText),
                            const SizedBox(width: 4.0),
                            Text(
                              pact.duration!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: LearningColors.secondaryText),
                            ),
                            const SizedBox(width: 16.0),
                          ],
                          if (pact.studyPlan != null) ...[
                            const Icon(Icons.calendar_today_outlined,
                                size: 14, color: LearningColors.secondaryText),
                            const SizedBox(width: 4.0),
                            Text(
                              pact.studyPlan!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: LearningColors.secondaryText),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Mutual Acceptance Callout Notice
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.handshake_outlined,
                      size: 20,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 10.0),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This Learning Pact starts only after you accept.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            'Both of you must voluntarily agree before the pact activates. You may decline without penalty.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF166534),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              // Action Buttons Row (min 44dp height)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44.0,
                      child: OutlinedButton(
                        key: const ValueKey('btn_decline_pact'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onPressed: isProcessing ? null : onDecline,
                        child: const Text('Decline'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: SizedBox(
                      height: 44.0,
                      child: ElevatedButton(
                        key: const ValueKey('btn_accept_pact'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LearningColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onPressed: isProcessing ? null : onAccept,
                        child: const Text('Accept Pact'),
                      ),
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
