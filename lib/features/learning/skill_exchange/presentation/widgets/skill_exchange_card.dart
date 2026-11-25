import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';
import '../../domain/entities/skill_exchange.dart';

/// Card component presenting a user's Skill Exchange proposal.
///
/// Supports caller perspective (Sender vs Recipient) and all lifecycle states:
/// - Pending (awaiting agreement)
/// - Accepted (mutual agreement active)
/// - Declined (proposal declined)
/// - Cancelled (proposal cancelled by sender)
class SkillExchangeCard extends StatelessWidget {
  final SkillExchange exchange;
  final String currentProfileId;
  final String partnerDisplayName;
  final ValueChanged<SkillExchange>? onAccept;
  final ValueChanged<SkillExchange>? onDecline;
  final ValueChanged<SkillExchange>? onCancel;

  const SkillExchangeCard({
    super.key,
    required this.exchange,
    required this.currentProfileId,
    required this.partnerDisplayName,
    this.onAccept,
    this.onDecline,
    this.onCancel,
  });

  bool get isSender => exchange.sender.learningProfileId == currentProfileId;
  bool get isRecipient =>
      exchange.recipient.learningProfileId == currentProfileId;

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(exchange.status);

    return Card(
      key: ValueKey('card_exchange_${exchange.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: LearningColors.cardSurface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: BorderSide(
          color: statusConfig.borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Partner Name, Role badge (Sender/Recipient), Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partnerDisplayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: LearningColors.heading,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          isSender ? 'You proposed this' : 'Proposed to you',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: LearningColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: statusConfig.backgroundColor,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      statusConfig.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusConfig.textColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12.0),

              // Exchange details container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: LearningColors.background,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          size: 16,
                          color: LearningColors.primary,
                        ),
                        const SizedBox(width: 6.0),
                        const Text(
                          'You teach: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: LearningColors.heading,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            isSender
                                ? exchange.offeredSkill
                                : exchange.wantedSkill,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: LearningColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_downward_rounded,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6.0),
                        const Text(
                          'You learn: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: LearningColors.heading,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            isSender
                                ? exchange.wantedSkill
                                : exchange.offeredSkill,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (exchange.note != null &&
                  exchange.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Text(
                  '"${exchange.note!}"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: LearningColors.secondaryText,
                  ),
                ),
              ],

              const SizedBox(height: 12.0),

              // Mutual agreement active disclosure when accepted
              if (exchange.status == SkillExchangeStatus.accepted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.handshake_rounded,
                        size: 18,
                        color: Color(0xFF15803D),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          'Mutual Agreement Active. (External communication authorization pending)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Action buttons depending on role and status
              if (exchange.status == SkillExchangeStatus.pending) ...[
                const SizedBox(height: 8.0),
                if (isSender && onCancel != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: ValueKey('btn_cancel_exchange_${exchange.id}'),
                      onPressed: () => onCancel!(exchange),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Cancel Request'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                if (isRecipient && (onAccept != null || onDecline != null))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onDecline != null)
                        TextButton(
                          key: ValueKey('btn_decline_exchange_${exchange.id}'),
                          onPressed: () => onDecline!(exchange),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                          ),
                          child: const Text('Decline'),
                        ),
                      const SizedBox(width: 8.0),
                      if (onAccept != null)
                        ElevatedButton.icon(
                          key: ValueKey('btn_accept_exchange_${exchange.id}'),
                          onPressed: () => onAccept!(exchange),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static _StatusConfig _getStatusConfig(SkillExchangeStatus status) {
    switch (status) {
      case SkillExchangeStatus.pending:
        return const _StatusConfig(
          label: 'PENDING',
          textColor: Color(0xFFB45309),
          backgroundColor: Color(0xFFFEF3C7),
          borderColor: Color(0xFFFDE68A),
        );
      case SkillExchangeStatus.accepted:
        return const _StatusConfig(
          label: 'ACCEPTED',
          textColor: Color(0xFF047857),
          backgroundColor: Color(0xFFD1FAE5),
          borderColor: Color(0xFFA7F3D0),
        );
      case SkillExchangeStatus.declined:
        return const _StatusConfig(
          label: 'DECLINED',
          textColor: Color(0xFFBE123C),
          backgroundColor: Color(0xFFFFE4E6),
          borderColor: Color(0xFFFECDD3),
        );
      case SkillExchangeStatus.cancelled:
        return const _StatusConfig(
          label: 'CANCELLED',
          textColor: Color(0xFF475569),
          backgroundColor: Color(0xFFF1F5F9),
          borderColor: Color(0xFFE2E8F0),
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const _StatusConfig({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
