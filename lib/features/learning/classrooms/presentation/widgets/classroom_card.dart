import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_classroom.dart';

/// Card widget presenting a single Learning classroom in the discovery or my classrooms lists.
class ClassroomCard extends StatelessWidget {
  final LearningClassroom classroom;
  final VoidCallback? onJoin;
  final VoidCallback? onRequestToJoin;
  final VoidCallback? onCancelRequest;
  final VoidCallback? onViewDetails;

  const ClassroomCard({
    super.key,
    required this.classroom,
    this.onJoin,
    this.onRequestToJoin,
    this.onCancelRequest,
    this.onViewDetails,
  });

  Color _getPrivacyColor(ClassroomPrivacy privacy) {
    switch (privacy) {
      case ClassroomPrivacy.public:
        return const Color(0xFF0D9488); // Teal
      case ClassroomPrivacy.requestToJoin:
        return const Color(0xFFD97706); // Amber
      case ClassroomPrivacy.closed:
        return const Color(0xFF6B7280); // Grey
    }
  }

  String _getPrivacyLabel(ClassroomPrivacy privacy) {
    switch (privacy) {
      case ClassroomPrivacy.public:
        return 'Public (Open)';
      case ClassroomPrivacy.requestToJoin:
        return 'Approval Required';
      case ClassroomPrivacy.closed:
        return 'Private';
    }
  }

  @override
  Widget build(BuildContext context) {
    final privacyColor = _getPrivacyColor(classroom.privacy);
    final privacyLabel = _getPrivacyLabel(classroom.privacy);

    return Material(
      color: Colors.transparent,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Category badge & Privacy badge (wrapped to prevent overflow)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.0,
                runSpacing: 6.0,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: LearningColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      classroom.category,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: LearningColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: privacyColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                          color: privacyColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          classroom.privacy == ClassroomPrivacy.public
                              ? Icons.public
                              : classroom.privacy ==
                                      ClassroomPrivacy.requestToJoin
                                  ? Icons.lock_clock
                                  : Icons.lock,
                          size: 12.0,
                          color: privacyColor,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          privacyLabel,
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                            color: privacyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),

              // Title
              Text(
                classroom.name,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6.0),

              // Description
              Text(
                classroom.description,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12.0),

              // Tags
              if (classroom.tags.isNotEmpty)
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: classroom.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 11.0,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (classroom.tags.isNotEmpty) const SizedBox(height: 12.0),

              const Divider(height: 1.0),
              const SizedBox(height: 10.0),

              // Meta row: Host & Member Count (wrapped with constraints to prevent overflow)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.0,
                runSpacing: 6.0,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16.0,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: Text(
                            classroom.hostDisplayName,
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.group_outlined,
                          size: 16.0,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: Text(
                            classroom.capacity != null
                                ? '${classroom.memberCount}/${classroom.capacity} learners'
                                : '${classroom.memberCount} learners',
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Action buttons & status
              _buildActionRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    if (classroom.membershipStatus == ClassroomMembershipStatus.host) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: LearningColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Text(
          'Educator / Host',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: LearningColors.primary,
            fontSize: 13.0,
          ),
        ),
      );
    }

    if (classroom.membershipStatus == ClassroomMembershipStatus.member) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 16.0, color: Color(0xFF059669)),
            SizedBox(width: 6.0),
            Text(
              'Enrolled in Classroom',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
                fontSize: 13.0,
              ),
            ),
          ],
        ),
      );
    }

    if (classroom.membershipStatus == ClassroomMembershipStatus.pending) {
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 16.0, color: Color(0xFFD97706)),
                SizedBox(width: 6.0),
                Text(
                  'Admission Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (onCancelRequest != null)
            OutlinedButton(
              onPressed: onCancelRequest,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                minimumSize: const Size(48, 36),
              ),
              child: const Text('Cancel Request'),
            ),
        ],
      );
    }

    // ClassroomMembershipStatus.none
    if (classroom.privacy == ClassroomPrivacy.public) {
      return SizedBox(
        width: double.infinity,
        height: 40.0,
        child: ElevatedButton.icon(
          onPressed: onJoin,
          icon: const Icon(Icons.group_add, size: 18.0),
          label: const Text(
            'Join Classroom',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: LearningColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      );
    }

    if (classroom.privacy == ClassroomPrivacy.requestToJoin) {
      return SizedBox(
        width: double.infinity,
        height: 40.0,
        child: OutlinedButton.icon(
          onPressed: onRequestToJoin,
          icon: const Icon(Icons.how_to_reg, size: 18.0),
          label: const Text(
            'Request to Join',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: LearningColors.primary,
            side: const BorderSide(color: LearningColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      );
    }

    // Closed
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Text(
        'Private / Invite Only',
        style: TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
          fontSize: 13.0,
        ),
      ),
    );
  }
}
