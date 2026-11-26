import 'package:flutter/material.dart';

/// Presentation screen introducing the optional Personality Questionnaire.
///
/// Follows M5 Personality & Privacy Governance:
/// - Independent and strictly optional; skipping does NOT block onboarding or Social access.
/// - Clear privacy explanation: answers remain private; no raw answers disclosed to other members.
/// - Does not make unsupported claims of scientific or clinical psychological diagnosis.
/// - Responsive design supporting 320dp, 400dp, and 800dp viewports and increased text scaling.
class PersonalityIntroScreen extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onSkip;

  const PersonalityIntroScreen({
    super.key,
    required this.onStart,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personality Assessment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: onSkip,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
                      // Illustration / Icon Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha(128),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.psychology_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Discover Your Vibe',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Take an optional 12-question quiz to help us find compatible social connections based on your communication style and shared interests.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Highlights card
                      _buildHighlightCard(
                        theme,
                        icon: Icons.timer_outlined,
                        title: 'Quick & Simple',
                        description: 'Takes only 2-3 minutes to answer all questions.',
                      ),
                      const SizedBox(height: 12),
                      _buildHighlightCard(
                        theme,
                        icon: Icons.lock_outline,
                        title: 'Private & Protected',
                        description: 'Your raw answers are private and never shown to other members.',
                      ),
                      const SizedBox(height: 12),
                      _buildHighlightCard(
                        theme,
                        icon: Icons.check_circle_outline,
                        title: 'Completely Optional',
                        description: 'You can skip anytime and take or retake it later from your profile.',
                      ),
                      const Spacer(),
                      const SizedBox(height: 32),
                      // Actions
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          key: const Key('start_quiz_button'),
                          onPressed: onStart,
                          child: const Text('Start Assessment'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          key: const Key('skip_quiz_button'),
                          onPressed: onSkip,
                          child: const Text('Skip for Now'),
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

  Widget _buildHighlightCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(64),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
