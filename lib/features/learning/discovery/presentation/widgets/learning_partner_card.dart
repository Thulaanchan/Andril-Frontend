import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_partner_candidate.dart';

/// Card component presenting an eligible candidate in Learning Partner Explorer (CF-04).
///
/// Complies with Learning visual identity and security rules:
/// - Only public display name, skills, goals, proficiency, language, and availability are shown.
/// - Internal account IDs are never exposed or rendered.
/// - Connect action forms an integration boundary for Task 05-02; never connects automatically.
/// - Minimum 44dp touch targets for accessibility.
/// - Responsive down to 320dp viewports and with 1.5x dynamic text scaling without overflow.
class LearningPartnerCard extends StatelessWidget {
  final LearningPartnerCandidate candidate;
  final ValueChanged<LearningPartnerCandidate> onViewProfile;
  final ValueChanged<LearningPartnerCandidate> onConnect;

  const LearningPartnerCard({
    super.key,
    required this.candidate,
    required this.onViewProfile,
    required this.onConnect,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'LP';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getProficiencyColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF10B981); // Emerald
      case 'intermediate':
        return const Color(0xFF3B82F6); // Blue
      case 'advanced':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return LearningColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(candidate.displayName);
    final profColor = _getProficiencyColor(candidate.proficiencyLevel);

    return Card(
      key: ValueKey('card_learning_partner_${candidate.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: LearningColors.cardSurface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar, Name, Module Badge, Proficiency Badge
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
                          spacing: 6.0,
                          runSpacing: 4.0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              candidate.displayName,
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: profColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                candidate.proficiencyLevel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: profColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (candidate.availability != null &&
                            candidate.availability!.isNotEmpty) ...[
                          const SizedBox(height: 4.0),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: LearningColors.secondaryText,
                              ),
                              const SizedBox(width: 4.0),
                              Expanded(
                                child: Text(
                                  candidate.availability!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: LearningColors.secondaryText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Bio (optional)
              if (candidate.bio != null &&
                  candidate.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 10.0),
                Text(
                  candidate.bio!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: LearningColors.secondaryText,
                  ),
                ),
              ],

              const SizedBox(height: 12.0),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10.0),

              // Skills to Teach / Share
              if (candidate.skillsToShare.isNotEmpty) ...[
                const Text(
                  'Can Teach / Share',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: LearningColors.heading,
                  ),
                ),
                const SizedBox(height: 6.0),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: candidate.skillsToShare.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: LearningColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: LearningColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10.0),
              ],

              // Skills to Learn
              if (candidate.skillsToLearn.isNotEmpty) ...[
                const Text(
                  'Wants to Learn',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: LearningColors.heading,
                  ),
                ),
                const SizedBox(height: 6.0),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: candidate.skillsToLearn.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: LearningColors.heading,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10.0),
              ],

              // Languages
              if (candidate.languages.isNotEmpty) ...[
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      size: 13,
                      color: LearningColors.secondaryText,
                    ),
                    ...candidate.languages.map((lang) {
                      return Text(
                        lang,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: LearningColors.secondaryText,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12.0),
              ],

              // Action Buttons Row: View Profile & Connect
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: ValueKey('btn_view_profile_${candidate.id}'),
                      onPressed: () => onViewProfile(candidate),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LearningColors.primary,
                        side: const BorderSide(
                          color: LearningColors.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        minimumSize: const Size(44, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                      child: const Text(
                        'View Profile',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: ElevatedButton(
                      key: ValueKey('btn_connect_${candidate.id}'),
                      onPressed: () => onConnect(candidate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LearningColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        minimumSize: const Size(44, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                      child: const Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
