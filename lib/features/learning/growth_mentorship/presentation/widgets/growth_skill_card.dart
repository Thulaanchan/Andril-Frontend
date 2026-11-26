import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_growth_evidence.dart';

/// Card widget presenting a tracked skill and its qualitative evidence sufficiency (LRN-04, Q41_LUC-24).
///
/// Features:
/// - Skill title and domain category.
/// - Qualitative sufficiency status indicator (Verified Source, Self-Reported Only, Insufficient Evidence).
/// - Governance notice: Missing evidence is NOT proof of a missing skill.
/// - Minimum 44dp touch target.
class GrowthSkillCard extends StatelessWidget {
  final LearningTrackedSkill skill;
  final VoidCallback? onTap;

  const GrowthSkillCard({
    super.key,
    required this.skill,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeFg, badgeText, badgeIcon) =
        switch (skill.sufficiencyStatus) {
      EvidenceSufficiencyStatus.verifiedSource => (
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          'Verified Source',
          Icons.verified_outlined,
        ),
      EvidenceSufficiencyStatus.selfReportedOnly => (
          const Color(0xFFDBEAFE),
          const Color(0xFF1D4ED8),
          'Self-Reported Only',
          Icons.person_outline,
        ),
      EvidenceSufficiencyStatus.insufficientEvidence => (
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
          'Insufficient Evidence',
          Icons.info_outline,
        ),
    };

    return Semantics(
      label:
          'Skill: ${skill.name}, Category: ${skill.category}, Status: $badgeText, Evidence count: ${skill.evidenceCount}.',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        color: LearningColors.cardSurface,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          key: ValueKey('card_skill_${skill.id}'),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skill.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: LearningColors.heading,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            skill.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: LearningColors.secondaryText,
                            ),
                          ),
                        ],
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
                                badgeText,
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
                  const SizedBox(height: 12.0),
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
                              Icons.description_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              '${skill.evidenceCount} ${skill.evidenceCount == 1 ? 'record' : 'records'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (skill.sufficiencyStatus ==
                          EvidenceSufficiencyStatus.insufficientEvidence)
                        Text(
                          'Needs more evidence',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.amber.shade900,
                          ),
                        ),
                    ],
                  ),
                  if (skill.notes != null && skill.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      skill.notes!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: LearningColors.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
