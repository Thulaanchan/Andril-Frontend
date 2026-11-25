import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';
import '../../domain/entities/skill_partner.dart';

/// Card component presenting an eligible partner in the Skill Exchange Hub.
///
/// Complies with BRD LRN-01 and privacy constraints:
/// - Only public display name, category, offered skills, and wanted skills are shown.
/// - Internal account IDs are never exposed or rendered.
/// - Minimum 44dp touch targets for accessibility.
/// - Responsive down to 320dp viewports and with 1.5x dynamic text scaling.
class SkillPartnerCard extends StatelessWidget {
  final SkillPartner partner;
  final ValueChanged<SkillPartner> onRequestExchange;
  final bool hasPendingExchangeWithUser;

  const SkillPartnerCard({
    super.key,
    required this.partner,
    required this.onRequestExchange,
    this.hasPendingExchangeWithUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(partner.displayName);

    return Card(
      key: ValueKey('card_partner_${partner.profileId}'),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: LearningColors.cardSurface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: hasPendingExchangeWithUser
              ? Colors.amber.shade300
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar, Name, Category badge, Module badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        LearningColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 16,
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
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              partner.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: LearningColors.heading,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: LearningColors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: const Text(
                                'Learning',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: LearningColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          partner.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: LearningColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (partner.bio != null && partner.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 10.0),
                Text(
                  partner.bio!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: LearningColors.secondaryText,
                  ),
                ),
              ],

              const SizedBox(height: 12.0),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10.0),

              // Skills Offered (Can Teach)
              const Text(
                'Offered Skills (Can Teach)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 6.0),
              if (partner.skillsOffered.isNotEmpty)
                Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: partner.skillsOffered.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: LearningColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school_rounded,
                            size: 12,
                            color: LearningColors.primary,
                          ),
                          const SizedBox(width: 4.0),
                          Flexible(
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: LearningColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                const Text(
                  'No skills listed to offer',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: LearningColors.secondaryText,
                  ),
                ),

              const SizedBox(height: 10.0),

              // Skills Wanted (Wants to Learn)
              const Text(
                'Wanted Skills (To Learn)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 6.0),
              if (partner.skillsWanted.isNotEmpty)
                Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: partner.skillsWanted.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: Colors.amber.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 12,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 4.0),
                          Flexible(
                            child: Text(
                              skill,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                const Text(
                  'No skills requested',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: LearningColors.secondaryText,
                  ),
                ),

              if (partner.availability != null &&
                  partner.availability!.isNotEmpty) ...[
                const SizedBox(height: 10.0),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4.0,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: LearningColors.secondaryText,
                    ),
                    Text(
                      'Availability: ${partner.availability}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: LearningColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14.0),

              // Action button
              SizedBox(
                width: double.infinity,
                child: hasPendingExchangeWithUser
                    ? OutlinedButton.icon(
                        key: ValueKey(
                          'btn_request_exchange_${partner.profileId}',
                        ),
                        onPressed: null,
                        icon: const Icon(Icons.hourglass_top_rounded, size: 16),
                        label: const Text('Pending Proposal Active'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      )
                    : ElevatedButton.icon(
                        key: ValueKey(
                          'btn_request_exchange_${partner.profileId}',
                        ),
                        onPressed: () => onRequestExchange(partner),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const Text('Request Exchange'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LearningColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'L';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
