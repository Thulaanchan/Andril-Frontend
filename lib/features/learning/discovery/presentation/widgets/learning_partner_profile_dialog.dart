import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_partner_candidate.dart';

/// Modal dialog for authorized View Profile presentation (CF-04).
///
/// Features:
/// - Strictly displays approved public Learning candidate profile fields.
/// - Never leaks or renders confidential internal account IDs, emails, or phone numbers.
/// - Connect integration boundary for Task 05-02.
/// - Responsive layout supporting 320dp and 1.5x font scaling.
class LearningPartnerProfileDialog extends StatelessWidget {
  final LearningPartnerCandidate candidate;
  final ValueChanged<LearningPartnerCandidate> onConnect;

  const LearningPartnerProfileDialog({
    super.key,
    required this.candidate,
    required this.onConnect,
  });

  /// Presents the profile dialog.
  static Future<void> show(
    BuildContext context, {
    required LearningPartnerCandidate candidate,
    required ValueChanged<LearningPartnerCandidate> onConnect,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => LearningPartnerProfileDialog(
        candidate: candidate,
        onConnect: onConnect,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'LP';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(candidate.displayName);

    return Dialog(
      key: ValueKey('dialog_learning_partner_profile_${candidate.id}'),
      backgroundColor: LearningColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar, Name, Badges, Close Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        LearningColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 18,
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
                        Text(
                          candidate.displayName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: LearningColors.heading,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Wrap(
                          spacing: 6.0,
                          runSpacing: 4.0,
                          children: [
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
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                candidate.proficiencyLevel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('btn_dialog_close'),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ],
              ),

              // Bio
              if (candidate.bio != null &&
                  candidate.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 14.0),
                Text(
                  candidate.bio!,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: LearningColors.secondaryText,
                  ),
                ),
              ],

              const SizedBox(height: 14.0),
              const Divider(height: 1),
              const SizedBox(height: 12.0),

              // Skills to Share
              if (candidate.skillsToShare.isNotEmpty) ...[
                const Text(
                  'Skills Offered (Can Teach)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
                const SizedBox(height: 12.0),
              ],

              // Skills to Learn
              if (candidate.skillsToLearn.isNotEmpty) ...[
                const Text(
                  'Skills Wanted (To Learn)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
                const SizedBox(height: 12.0),
              ],

              // Learning Goals
              if (candidate.learningGoals.isNotEmpty) ...[
                const Text(
                  'Learning Goals',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
                const SizedBox(height: 6.0),
                ...candidate.learningGoals.map((goal) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: LearningColors.primary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            goal,
                            style: const TextStyle(
                              fontSize: 12,
                              color: LearningColors.heading,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12.0),
              ],

              // Availability & Languages
              if (candidate.availability != null ||
                  candidate.languages.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: LearningColors.background,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    children: [
                      if (candidate.availability != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: LearningColors.secondaryText,
                            ),
                            const SizedBox(width: 6.0),
                            Expanded(
                              child: Text(
                                candidate.availability!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: LearningColors.heading,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (candidate.availability != null &&
                          candidate.languages.isNotEmpty)
                        const SizedBox(height: 6.0),
                      if (candidate.languages.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.translate_rounded,
                              size: 14,
                              color: LearningColors.secondaryText,
                            ),
                            const SizedBox(width: 6.0),
                            Expanded(
                              child: Text(
                                candidate.languages.join(', '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: LearningColors.heading,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
              ],

              // Connect Button (Task 05-02 boundary)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  key: const ValueKey('btn_dialog_connect'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConnect(candidate);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LearningColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    minimumSize: const Size(44, 44),
                  ),
                  child: const Text(
                    'Connect with Partner',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
}
