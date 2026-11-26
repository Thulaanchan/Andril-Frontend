import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_connection.dart';

/// Card component presenting an established Learning connection (CF-05).
///
/// Features:
/// - Peer display name and initials/avatar.
/// - Shared skills chips styled with [LearningColors].
/// - Formatted connection date.
/// - Decoupled action callbacks: [onMessage], [onViewProfile], and [onRemove].
/// - Confirmation dialog prior to invoking [onRemove].
/// - Minimum 44dp accessible touch targets.
/// - Responsive down to 320dp viewports and with 1.5x dynamic font scaling.
class LearningConnectionCard extends StatelessWidget {
  final LearningConnection connection;
  final ValueChanged<LearningConnection>? onMessage;
  final ValueChanged<LearningConnection>? onViewProfile;
  final ValueChanged<LearningConnection>? onRemove;

  const LearningConnectionCard({
    super.key,
    required this.connection,
    this.onMessage,
    this.onViewProfile,
    this.onRemove,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'LP';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showRemoveConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove Connection?'),
        content: Text(
          'Are you sure you want to remove ${connection.peerDisplayName} from your learning connections? You will need to send a new request to reconnect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop(true);
              onRemove?.call(connection);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(connection.peerDisplayName);
    final formattedDate = _formatDate(connection.connectedAt);

    return Card(
      key: ValueKey('card_learning_connection_${connection.id}'),
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
            // Header Row: Avatar, Name, Connected Date
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
                      Text(
                        connection.peerDisplayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: LearningColors.heading,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Connected on $formattedDate',
                        style: const TextStyle(
                          fontSize: 12,
                          color: LearningColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Remove Connection Icon Button (min 48dp)
                IconButton(
                  key: ValueKey('btn_remove_connection_${connection.id}'),
                  icon: const Icon(Icons.person_remove_outlined),
                  color: Colors.red.shade400,
                  tooltip: 'Remove connection',
                  onPressed: () => _showRemoveConfirmation(context),
                ),
              ],
            ),

            // Shared Skills section
            if (connection.sharedSkills.isNotEmpty) ...[
              const SizedBox(height: 12.0),
              Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: connection.sharedSkills.take(3).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: LearningColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: LearningColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 12,
                        color: LearningColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16.0),

            // Action Buttons Row: View Profile and Message (min 44dp height)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44.0,
                    child: OutlinedButton.icon(
                      key: ValueKey(
                          'btn_view_profile_connection_${connection.id}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        foregroundColor: LearningColors.primary,
                        side: const BorderSide(color: LearningColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      icon: const Icon(Icons.person_outline, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('View Profile'),
                      ),
                      onPressed: onViewProfile != null
                          ? () => onViewProfile!(connection)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: SizedBox(
                    height: 44.0,
                    child: ElevatedButton.icon(
                      key: ValueKey('btn_message_connection_${connection.id}'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        backgroundColor: LearningColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Message'),
                      ),
                      onPressed: onMessage != null
                          ? () => onMessage!(connection)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
