import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_circle.dart';

/// Presentation card displaying a single Learning Circle in Hub discovery or My Circles list (CF-07, LRN-02).
///
/// Features:
/// - Category chip and membership role badge.
/// - Circle name, syllabus/mission description, and facilitator display name.
/// - Enrolled member count with icon.
/// - Shared goals count and visual average progress indicator.
/// - Contextual action buttons: View Circle, Join Circle, or Leave.
/// - Accessible >= 44dp touch targets.
/// - Responsive layout down to 320dp without overflow.
class LearningCircleCard extends StatelessWidget {
  final LearningCircle circle;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onViewDetails;
  final bool isProcessing;

  const LearningCircleCard({
    super.key,
    required this.circle,
    this.onJoin,
    this.onLeave,
    this.onViewDetails,
    this.isProcessing = false,
  });

  Widget _buildRoleBadge() {
    if (circle.membershipRole == CircleMembershipRole.facilitator) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE), // Light purple
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: const Text(
          'Facilitator',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6D28D9),
          ),
        ),
      );
    }
    if (circle.membershipRole == CircleMembershipRole.member) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7), // Light emerald
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: const Text(
          'Member',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF15803D),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final avgProgress = circle.averageGoalProgress;

    return Card(
      key: ValueKey('card_learning_circle_${circle.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: LearningColors.cardSurface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category chip, Spacer, Role Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: LearningColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    circle.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: LearningColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                _buildRoleBadge(),
              ],
            ),
            const SizedBox(height: 10.0),

            // Circle Name
            Text(
              circle.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6.0),

            // Description
            Text(
              circle.description,
              style: const TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12.0),

            // Metadata Row: Facilitator & Member Count
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: LearningColors.secondaryText,
                ),
                const SizedBox(width: 4.0),
                Expanded(
                  child: Text(
                    'Facilitator: ${circle.facilitatorDisplayName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: LearningColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8.0),
                const Icon(
                  Icons.groups_outlined,
                  size: 16,
                  color: LearningColors.secondaryText,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '${circle.memberCount} members',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: LearningColors.secondaryText,
                  ),
                ),
              ],
            ),

            // Shared Goals progress indicator (if goals exist)
            if (circle.goals.isNotEmpty) ...[
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${circle.goals.length} Shared ${circle.goals.length == 1 ? "Goal" : "Goals"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: LearningColors.heading,
                    ),
                  ),
                  Text(
                    '${avgProgress.toStringAsFixed(0)}% avg',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: LearningColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: avgProgress / 100.0,
                  minHeight: 6.0,
                  backgroundColor:
                      LearningColors.primary.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      LearningColors.primary),
                ),
              ),
            ],

            const SizedBox(height: 16.0),

            // Action Buttons Row (min 44dp height)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44.0,
                    child: OutlinedButton(
                      key: ValueKey('btn_view_circle_${circle.id}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        foregroundColor: LearningColors.primary,
                        side: const BorderSide(color: LearningColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: onViewDetails,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('View Circle'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: SizedBox(
                    height: 44.0,
                    child: _buildParticipationButton(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationButton() {
    if (isProcessing) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (circle.canJoin) {
      return ElevatedButton(
        key: ValueKey('btn_join_circle_${circle.id}'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          backgroundColor: LearningColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: onJoin,
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Join Circle'),
        ),
      );
    }

    if (circle.membershipRole == CircleMembershipRole.facilitator) {
      return OutlinedButton(
        key: ValueKey('btn_facilitating_circle_${circle.id}'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          foregroundColor: const Color(0xFF6D28D9),
          side: const BorderSide(color: Color(0xFFC4B5FD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: onViewDetails,
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Manage Circle'),
        ),
      );
    }

    // Regular enrolled member
    return OutlinedButton(
      key: ValueKey('btn_leave_circle_${circle.id}'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        foregroundColor: Colors.red.shade700,
        side: BorderSide(color: Colors.red.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      onPressed: onLeave,
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('Leave Circle'),
      ),
    );
  }
}
