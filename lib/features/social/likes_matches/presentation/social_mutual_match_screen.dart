import 'package:flutter/material.dart';
import '../domain/social_relationship.dart';

/// Presentation screen for Authoritative Server-Confirmed Mutual Matches (S12 It's a Match!).
///
/// Follows M5-FE-S12 presentation governance:
/// - Fails closed: Requires server-confirmed matching evidence (`hasActiveMatch` must be true).
/// - Directional interest alone CANNOT unlock communication or render as a mutual match.
/// - Communication entry requires M4 contract; does not automatically create conversations or transactions.
/// - Supports 320dp, 400dp, and 800dp viewports and increased text scaling.
class SocialMutualMatchScreen extends StatelessWidget {
  final SocialRelationship relationship;
  final ValueChanged<SocialRelationship>? onSendMessage;
  final VoidCallback? onKeepExploring;

  const SocialMutualMatchScreen({
    super.key,
    required this.relationship,
    this.onSendMessage,
    this.onKeepExploring,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Security invariant: Server-confirmed match required
    if (!relationship.hasActiveMatch) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mutual Match')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Unconfirmed Match',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mutual match evidence has not been authoritatively confirmed by the server.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onKeepExploring ?? () => Navigator.of(context).maybePop(),
                  child: const Text('Back to Discovery'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final candidate = relationship.candidate;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Celebration icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha(128),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "It's a Match!",
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You and ${candidate.displayName} liked each other.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Pair Avatars
                      _buildPairAvatars(theme, candidate.primaryPhotoUrl),
                      const SizedBox(height: 24),
                      Text(
                        '${candidate.displayName}, ${candidate.age}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (candidate.approximateDistanceKm != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${candidate.approximateDistanceKm} km away',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (candidate.sharedConnectionGoals.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: candidate.sharedConnectionGoals.map((goal) {
                            return Chip(
                              label: Text(goal),
                              backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                            );
                          }).toList(),
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: 32),
                      // Action buttons
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          key: const Key('send_message_button'),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Send Message'),
                          onPressed: () => onSendMessage?.call(relationship),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          key: const Key('keep_exploring_button'),
                          onPressed: onKeepExploring ?? () => Navigator.of(context).maybePop(),
                          child: const Text('Keep Exploring'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPairAvatars(ThemeData theme, String? candidatePhotoUrl) {
    return SizedBox(
      height: 120,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left Avatar (Caller)
          Positioned(
            left: 10,
            child: CircleAvatar(
              radius: 46,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: const CircleAvatar(
                radius: 42,
                child: Icon(Icons.person, size: 42),
              ),
            ),
          ),
          // Right Avatar (Candidate)
          Positioned(
            right: 10,
            child: CircleAvatar(
              radius: 46,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: CircleAvatar(
                radius: 42,
                backgroundImage: candidatePhotoUrl != null ? NetworkImage(candidatePhotoUrl) : null,
                child: candidatePhotoUrl == null ? const Icon(Icons.person, size: 42) : null,
              ),
            ),
          ),
          // Center Heart Badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.surface, width: 3),
            ),
            child: const Icon(Icons.favorite, size: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
