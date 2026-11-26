import 'package:flutter/material.dart';

/// Presentation state for authoritative smart matching results.
enum SmartMatchingState {
  loading,
  unavailable,
  empty,
  ready,
}

/// Domain summary representation of verified server-authorized matching criteria (S28 Why We Matched).
///
/// Follows M5 Smart Matching Governance:
/// - Strictly relies on server-provided data; does not invent compatibility percentages or algorithms.
/// - Does not fabricate personality classifications or confidential AI explanations.
class ServerMatchExplanation {
  final String matchedCandidateName;
  final List<String> commonInterests;
  final List<String> sharedGoals;
  final String? approximateDistance;

  const ServerMatchExplanation({
    required this.matchedCandidateName,
    this.commonInterests = const [],
    this.sharedGoals = const [],
    this.approximateDistance,
  });
}

/// Presentation screen explaining match compatibility (S28 Why We Matched / Smart Matching).
///
/// Follows M5 Smart Matching Governance:
/// - Fails closed: If matching service is unavailable or dormant, presents explicit unavailable state.
/// - Incomplete or skipped questionnaires do NOT fabricate synthetic results.
/// - Responsive layout supporting 320dp, 400dp, and 800dp viewports and increased text scaling.
class SocialSmartMatchingScreen extends StatelessWidget {
  final SmartMatchingState state;
  final ServerMatchExplanation? matchExplanation;
  final String? errorMessage;
  final VoidCallback? onRetakeQuiz;
  final VoidCallback? onExplore;
  final VoidCallback? onRetry;

  const SocialSmartMatchingScreen({
    super.key,
    this.state = SmartMatchingState.unavailable,
    this.matchExplanation,
    this.errorMessage,
    this.onRetakeQuiz,
    this.onExplore,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Why We Matched'),
      ),
      body: SafeArea(
        child: _buildContent(context, theme),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    switch (state) {
      case SmartMatchingState.loading:
        return const Center(child: CircularProgressIndicator());

      case SmartMatchingState.unavailable:
        return _buildUnavailableState(theme);

      case SmartMatchingState.empty:
        return _buildEmptyState(theme);

      case SmartMatchingState.ready:
        if (matchExplanation == null) {
          return _buildEmptyState(theme);
        }
        return _buildReadyState(context, matchExplanation!, theme);
    }
  }

  Widget _buildReadyState(
    BuildContext context,
    ServerMatchExplanation explanation,
    ThemeData theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(128),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Compatibility Highlights',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Shared preferences between you and ${explanation.matchedCandidateName}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (explanation.sharedGoals.isNotEmpty) ...[
                    Text(
                      'Shared Connection Goals',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: explanation.sharedGoals.map((goal) {
                        return Chip(
                          label: Text(goal),
                          avatar: const Icon(Icons.check, size: 16),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (explanation.commonInterests.isNotEmpty) ...[
                    Text(
                      'Common Interests',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: explanation.commonInterests.map((interest) {
                        return Chip(
                          label: Text(interest),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (explanation.approximateDistance != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            explanation.approximateDistance!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  const SizedBox(height: 32),
                  if (onExplore != null)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        key: const Key('explore_button'),
                        onPressed: onExplore,
                        child: const Text('Back to Discovery'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnavailableState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              'Smart Matching Preparing',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ??
                  'The automated smart matching analysis service is currently preparing and unavailable.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              OutlinedButton(
                key: const Key('retry_button'),
                onPressed: onRetry,
                child: const Text('Check Again'),
              ),
            if (onExplore != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('explore_people_button'),
                onPressed: onExplore,
                child: const Text('Discover People'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No Criteria Available',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Take the personality questionnaire or update your interests to unlock compatibility highlights.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (onRetakeQuiz != null)
              FilledButton(
                key: const Key('take_quiz_button'),
                onPressed: onRetakeQuiz,
                child: const Text('Take Personality Quiz'),
              ),
          ],
        ),
      ),
    );
  }
}
