import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_pact.dart';
import '../viewmodels/learning_pacts_viewmodel.dart';
import '../widgets/end_pact_dialog.dart';

/// Presentation screen for Learning Pact Progress and Milestone Tracking (LRN-03, Q33_LUC-19).
///
/// Features:
/// 1. Comprehensive pact summary: title, status badge, shared goal, and optional duration/study plan.
/// 2. Participants overview ("You" + Learning Partner) with mutual agreement statuses.
/// 3. Self-reported milestone checklist with interactive progress toggling.
/// 4. Read-only Activity History modal (ANDRIL_LP_H01) tracking all audit events.
/// 5. Mutual completion reporting and voluntary withdrawal modal (ANDRIL_LP_E01).
/// 6. Fully responsive layout across 320dp, 360dp, 412dp viewports with 1.5x font scale support.
class LearningPactProgressScreen extends StatefulWidget {
  final LearningPactsViewModel viewModel;
  final String pactId;

  const LearningPactProgressScreen({
    super.key,
    required this.viewModel,
    required this.pactId,
  });

  @override
  State<LearningPactProgressScreen> createState() =>
      _LearningPactProgressScreenState();
}

class _LearningPactProgressScreenState
    extends State<LearningPactProgressScreen> {
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

  LearningPact? _getPact() {
    try {
      return widget.viewModel.allPacts.firstWhere(
        (p) => p.id == widget.pactId,
      );
    } catch (_) {
      return null;
    }
  }

  void _showActivityHistorySheet(BuildContext context, LearningPact pact) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          key: const ValueKey('sheet_pact_activity_history'),
          decoration: const BoxDecoration(
            color: LearningColors.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                children: [
                  const Icon(
                    Icons.history,
                    color: LearningColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8.0),
                  const Expanded(
                    child: Text(
                      'Pact Activity History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              const Text(
                'Read-only audit timeline of agreed terms, milestones, and status changes.',
                style: TextStyle(
                  fontSize: 13,
                  color: LearningColors.secondaryText,
                ),
              ),
              const Divider(height: 24.0),
              Expanded(
                child: pact.history.isEmpty
                    ? const Center(
                        child: Text(
                          'No activity recorded yet.',
                          style: TextStyle(
                            fontSize: 14,
                            color: LearningColors.secondaryText,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: pact.history.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 16.0),
                        itemBuilder: (context, index) {
                          final event = pact.history[index];
                          IconData eventIcon;
                          Color iconColor;
                          switch (event.type) {
                            case PactHistoryEventType.proposal:
                              eventIcon = Icons.lightbulb_outline;
                              iconColor = Colors.amber.shade700;
                              break;
                            case PactHistoryEventType.agreed:
                              eventIcon = Icons.handshake_outlined;
                              iconColor = const Color(0xFF15803D);
                              break;
                            case PactHistoryEventType.selfReported:
                              eventIcon = Icons.task_alt;
                              iconColor = LearningColors.primary;
                              break;
                            case PactHistoryEventType.partnerUpdate:
                              eventIcon = Icons.sync_alt;
                              iconColor = LearningColors.primary;
                              break;
                            case PactHistoryEventType.completed:
                              eventIcon = Icons.emoji_events_outlined;
                              iconColor = const Color(0xFF4338CA);
                              break;
                            case PactHistoryEventType.withdrawn:
                              eventIcon = Icons.cancel_outlined;
                              iconColor = const Color(0xFFB91C1C);
                              break;
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  eventIcon,
                                  size: 18,
                                  color: iconColor,
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: LearningColors.heading,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      event.description,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: LearningColors.secondaryText,
                                      ),
                                    ),
                                    if (event.actorDisplayName != null) ...[
                                      const SizedBox(height: 2.0),
                                      Text(
                                        'By ${event.actorDisplayName}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: LearningColors.secondaryText,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(LearningPact pact) {
    if (pact.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: const Text(
          'Active Pact',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF15803D),
          ),
        ),
      );
    }
    if (pact.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: const Text(
          'Pending Acceptance',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB45309),
          ),
        ),
      );
    }
    if (pact.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E7FF),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: const Text(
          'Completed',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4338CA),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: const Text(
        'Cancelled',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFFB91C1C),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(LearningPact pact) {
    return Container(
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  pact.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              _buildStatusBadge(pact),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.flag_outlined,
                size: 18,
                color: LearningColors.primary,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  pact.sharedGoal,
                  style: const TextStyle(
                    fontSize: 14,
                    color: LearningColors.secondaryText,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          if (pact.duration != null && pact.duration!.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 18,
                  color: LearningColors.secondaryText,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Duration: ${pact.duration}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: LearningColors.secondaryText,
                  ),
                ),
              ],
            ),
          ],
          if (pact.studyPlan != null && pact.studyPlan!.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  size: 18,
                  color: LearningColors.secondaryText,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Plan: ${pact.studyPlan}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: LearningColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantsCard(LearningPact pact) {
    final proposer = pact.participants.firstWhere(
      (p) => p.participantProfileId == pact.proposerProfileId,
      orElse: () => pact.participants.first,
    );
    final partner = pact.participants.firstWhere(
      (p) => p.participantProfileId != pact.proposerProfileId,
      orElse: () => pact.participants.last,
    );

    return Container(
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Participants',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 12.0),
          _buildParticipantRow(
            name: proposer.participantDisplayName,
            role: 'Proposer',
            isCurrent: proposer.participantProfileId ==
                widget.viewModel.currentProfileId,
            decision: proposer.decision,
          ),
          const Divider(height: 20.0),
          _buildParticipantRow(
            name: partner.participantDisplayName,
            role: 'Partner',
            isCurrent: partner.participantProfileId ==
                widget.viewModel.currentProfileId,
            decision: partner.decision,
          ),
          if (pact.isPending) ...[
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.amber.shade900,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Pact will activate automatically once both partners have accepted.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantRow({
    required String name,
    required String role,
    required bool isCurrent,
    required PactInvitationDecision decision,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: LearningColors.primary.withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: LearningColors.primary,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCurrent ? '$name (You)' : name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: LearningColors.heading,
                ),
              ),
              Text(
                role,
                style: const TextStyle(
                  fontSize: 12,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
          decoration: BoxDecoration(
            color: decision.isAccepted
                ? const Color(0xFFDCFCE7)
                : decision.isDeclined
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Text(
            decision.isAccepted
                ? 'Accepted'
                : decision.isDeclined
                    ? 'Declined'
                    : 'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: decision.isAccepted
                  ? const Color(0xFF15803D)
                  : decision.isDeclined
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFFB45309),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneChecklist(LearningPact pact) {
    final completedCount = pact.completedCommitmentsCount;
    final totalCount = pact.commitments.length;
    final pct = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final isEditable = pact.isActive;

    return Container(
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Agreed Milestones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              Text(
                '$completedCount of $totalCount completed',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: LearningColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8.0,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                LearningColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          if (pact.commitments.isEmpty)
            const Text(
              'No specific milestones recorded for this pact.',
              style: TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...pact.commitments.map((cmt) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: InkWell(
                  key: ValueKey('milestone_row_${cmt.id}'),
                  onTap: isEditable
                      ? () {
                          widget.viewModel.toggleCommitment(
                            pactId: pact.id,
                            commitmentId: cmt.id,
                            isCompleted: !cmt.isCompleted,
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: cmt.isCompleted
                          ? Colors.grey.shade50
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          key: ValueKey('checkbox_commitment_${cmt.id}'),
                          value: cmt.isCompleted,
                          activeColor: LearningColors.primary,
                          onChanged: isEditable
                              ? (val) {
                                  widget.viewModel.toggleCommitment(
                                    pactId: pact.id,
                                    commitmentId: cmt.id,
                                    isCompleted: val ?? false,
                                  );
                                }
                              : null,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              cmt.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: cmt.isCompleted
                                    ? LearningColors.secondaryText
                                    : LearningColors.heading,
                                decoration: cmt.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActions(LearningPact pact) {
    final isProcessing = widget.viewModel.isOperationInProgress(pact.id);
    final myPart = pact.myParticipation(widget.viewModel.currentProfileId);
    final myCompletionConfirmed = myPart?.completionConfirmed ?? false;

    return Column(
      children: [
        if (pact.isActive) ...[
          // Confirm Completion Action
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              key: const ValueKey('button_confirm_completion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: myCompletionConfirmed
                    ? const Color(0xFF15803D)
                    : LearningColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: (isProcessing || myCompletionConfirmed)
                  ? null
                  : () async {
                      await widget.viewModel.confirmCompletion(pact.id);
                    },
              icon: Icon(
                myCompletionConfirmed ? Icons.check_circle : Icons.check,
                size: 20,
              ),
              label: Text(
                myCompletionConfirmed
                    ? 'Completion Confirmed'
                    : 'Mark Pact as Completed',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12.0),

          // End Participation Action (Voluntary exit)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              key: const ValueKey('button_end_participation'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: isProcessing
                  ? null
                  : () async {
                      await EndPactDialog.show(
                        context,
                        onConfirmEnd: () async {
                          final ok =
                              await widget.viewModel.withdrawPact(pact.id);
                          if (ok && mounted) {
                            Navigator.of(context).pop();
                          }
                          return ok;
                        },
                      );
                    },
              icon: const Icon(Icons.exit_to_app, size: 20),
              label: const Text(
                'End My Participation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12.0),
        ],

        // View Activity History Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton.icon(
            key: const ValueKey('button_view_activity_history'),
            style: TextButton.styleFrom(
              foregroundColor: LearningColors.heading,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onPressed: () => _showActivityHistorySheet(context, pact),
            icon: const Icon(Icons.history, size: 20),
            label: const Text(
              'View Activity History',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pact = _getPact();

    return Scaffold(
      key: const ValueKey('screen_learning_pact_progress'),
      backgroundColor: LearningColors.background,
      appBar: AppBar(
        title: const Text(
          'Pact Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: LearningColors.heading,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          key: const ValueKey('button_pact_progress_back'),
          icon: const Icon(Icons.arrow_back, color: LearningColors.heading),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (pact != null)
            IconButton(
              key: const ValueKey('button_app_bar_history'),
              icon: const Icon(Icons.history, color: LearningColors.heading),
              tooltip: 'Activity History',
              onPressed: () => _showActivityHistorySheet(context, pact),
            ),
        ],
      ),
      body: pact == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: LearningColors.secondaryText,
                  ),
                  const SizedBox(height: 12.0),
                  const Text(
                    'Pact record not found.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: LearningColors.heading,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Hub'),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(pact),
                    const SizedBox(height: 16.0),
                    _buildParticipantsCard(pact),
                    const SizedBox(height: 16.0),
                    _buildMilestoneChecklist(pact),
                    const SizedBox(height: 24.0),
                    _buildActions(pact),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ),
    );
  }
}
