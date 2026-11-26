import 'package:flutter/material.dart';
import '../group_contracts/social_zone.dart';

/// Presentation component for entering Zone communication channels.
///
/// Follows M4/M5 Module Ownership Governance:
/// - M4 retains authoritative ownership of messaging, voice/video calls, live streaming, gifts, and MoodTone.
/// - Does not manufacture fraudulent client-side messaging databases, audio engines, or streaming servers.
/// - Passes navigation intents via approved integration callbacks [onOpenChat].
/// - Visibly disables and annotates unavailable features pending M4 module activation.
class SocialZoneCommunicationSection extends StatelessWidget {
  final SocialZone zone;
  final VoidCallback? onOpenChat;
  final bool isMember;

  const SocialZoneCommunicationSection({
    super.key,
    required this.zone,
    this.onOpenChat,
    this.isMember = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.forum_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Community Channels',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Real-time communication channels are powered by the core messaging engine.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            // Channel options
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    key: const Key('zone_chat_button'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Zone Chat'),
                    onPressed: isMember && onOpenChat != null ? onOpenChat : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Tooltip(
                    message: 'Audio stages are managed by the M4 live audio module.',
                    child: OutlinedButton.icon(
                      key: const Key('zone_audio_stage_button'),
                      icon: const Icon(Icons.mic_none),
                      label: const Text('Live Stage'),
                      onPressed: null, // Disabled pending M4 streaming contract
                    ),
                  ),
                ),
              ],
            ),
            if (!isMember) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    'Join this zone to access community chat channels.',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
