import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_growth_evidence.dart';

/// Card widget presenting a single [LearningGrowthEvidence] record (LRN-04, Q41_LUC-24).
///
/// Features:
/// - Prominent provenance pill (Verified: Emerald, Self-Reported: Blue).
/// - Evidence title and recorded timestamp.
/// - Associated skill chips.
/// - Minimum 44dp touch target on interactive tap.
/// - Semantic accessibility labels.
class GrowthEvidenceCard extends StatelessWidget {
  final LearningGrowthEvidence evidence;
  final VoidCallback? onTap;

  const GrowthEvidenceCard({
    super.key,
    required this.evidence,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = evidence.kind.isVerified;
    final badgeBg =
        isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE);
    final badgeFg =
        isVerified ? const Color(0xFF15803D) : const Color(0xFF1D4ED8);
    final badgeLabel = isVerified ? 'Verified Source' : 'Self-Reported';
    final badgeIcon =
        isVerified ? Icons.verified_outlined : Icons.person_outline;

    final dateStr =
        '${evidence.recordedAt.year}-${evidence.recordedAt.month.toString().padLeft(2, '0')}-${evidence.recordedAt.day.toString().padLeft(2, '0')}';

    return Semantics(
      label:
          'Evidence: ${evidence.title}, $badgeLabel, recorded on $dateStr. Tap to view details.',
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        color: LearningColors.cardSurface,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          key: ValueKey('card_evidence_${evidence.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      Text(
                        evidence.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: LearningColors.heading,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, size: 14, color: badgeFg),
                              const SizedBox(width: 4.0),
                              Text(
                                badgeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: badgeFg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    evidence.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LearningColors.secondaryText,
                      height: 1.3,
                    ),
                  ),
                  if (evidence.skillNames.isNotEmpty) ...[
                    const SizedBox(height: 10.0),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: evidence.skillNames.take(4).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 3.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (evidence.sourceReference != null) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      'Source: ${evidence.sourceReference}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10.0),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Details →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: LearningColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
