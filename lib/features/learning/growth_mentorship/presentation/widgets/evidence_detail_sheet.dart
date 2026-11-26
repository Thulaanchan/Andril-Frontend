import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_growth_evidence.dart';

/// Modal bottom sheet displaying detailed provenance and metadata for a [LearningGrowthEvidence] record (LRN-04).
///
/// Follows fail-closed privacy governance:
/// - Explicitly denotes record as "Private to you".
/// - Highlights provenance source (Verified vs Self-Reported).
/// - Displays verifying institution if verified.
/// - Minimum 44dp interactive touch targets.
class EvidenceDetailSheet extends StatelessWidget {
  final LearningGrowthEvidence evidence;

  const EvidenceDetailSheet({
    super.key,
    required this.evidence,
  });

  static Future<void> show(
    BuildContext context, {
    required LearningGrowthEvidence evidence,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EvidenceDetailSheet(evidence: evidence),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = evidence.kind.isVerified;
    final badgeBg =
        isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE);
    final badgeFg =
        isVerified ? const Color(0xFF15803D) : const Color(0xFF1D4ED8);
    final badgeLabel =
        isVerified ? 'Verified Source Evidence' : 'Self-Reported Evidence';
    final badgeIcon =
        isVerified ? Icons.verified_outlined : Icons.person_outline;

    final recordedDateStr =
        '${evidence.recordedAt.year}-${evidence.recordedAt.month.toString().padLeft(2, '0')}-${evidence.recordedAt.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      padding: EdgeInsets.only(
        top: 20.0,
        left: 20.0,
        right: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    evidence.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: LearningColors.heading,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('btn_close_evidence_detail'),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close details',
                  constraints:
                      const BoxConstraints(minWidth: 44.0, minHeight: 44.0),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 6.0,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 16, color: badgeFg),
                      const SizedBox(width: 6.0),
                      Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badgeFg,
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
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 14, color: Color(0xFF475569)),
                      SizedBox(width: 4.0),
                      Text(
                        'Private to you',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              evidence.description,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
                height: 1.4,
              ),
            ),
            if (evidence.sourceReference != null) ...[
              const SizedBox(height: 14.0),
              const Text(
                'Source / Artifact Reference',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                evidence.sourceReference!,
                style: const TextStyle(
                  fontSize: 13,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
            if (evidence.verifierName != null) ...[
              const SizedBox(height: 14.0),
              const Text(
                'Verified By',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: Color(0xFF15803D),
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    evidence.verifierName!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ],
            if (evidence.skillNames.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              const Text(
                'Associated Skills',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 6.0,
                children: evidence.skillNames.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3730A3),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16.0),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6.0),
                Text(
                  'Recorded on $recordedDateStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: OutlinedButton(
                key: const ValueKey('btn_dismiss_evidence_sheet'),
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LearningColors.primary,
                  side: const BorderSide(color: LearningColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
