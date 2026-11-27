import 'package:flutter/material.dart';
import '../viewmodels/personality_questionnaire_viewmodel.dart';

/// Screen S37: Personality Answers.
///
/// Follows M5 Personality Governance & BRD §15.4:
/// - Displays the user's own permitted answer draft or completed responses.
/// - Raw answers remain strictly private to the user; never shared publicly.
/// - Does not invent historical answers or retake cooldown periods.
/// - Allows jumping back to edit specific answers or retake the questionnaire.
/// - Distinguishes complete, partial, and empty answer states.
/// - Fails closed on unauthorized access or invalidated session.
/// - Responsive layout supporting 320dp, 400dp, and 800dp viewports.
class PersonalityAnswersScreen extends StatelessWidget {
  final PersonalityQuestionnaireViewModel viewModel;
  final ValueChanged<int>? onEditQuestion;
  final VoidCallback? onRetakeQuiz;
  final VoidCallback? onBack;

  const PersonalityAnswersScreen({
    super.key,
    required this.viewModel,
    this.onEditQuestion,
    this.onRetakeQuiz,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personality Answers'),
        leading: IconButton(
          key: const Key('personality_answers_back_button'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: viewModel,
          builder: (context, _) => _buildBody(context, theme),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    if (viewModel.isAccessDenied) {
      return _buildAccessDeniedState(theme);
    }

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final questionnaire = viewModel.questionnaire;
    final draft = viewModel.answerDraft;

    if (questionnaire == null || draft == null || draft.answers.isEmpty) {
      return _buildEmptyState(theme);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrivacyHeaderCard(theme),
                  const SizedBox(height: 20),
                  Text(
                    'Recorded Answers (${draft.answers.length} of ${questionnaire.totalQuestions})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...questionnaire.questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final q = entry.value;
                    final chosenOptionId = draft.answers[q.id];
                    final chosenOption =
                        q.options.where((opt) => opt.id == chosenOptionId).firstOrNull;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: chosenOption != null
                              ? theme.colorScheme.outlineVariant.withAlpha(128)
                              : theme.colorScheme.error.withAlpha(128),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Q${index + 1}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                if (q.isRequired) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    'Required',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                IconButton(
                                  key: Key('edit_answer_$index'),
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  tooltip: 'Edit Answer',
                                  onPressed: () {
                                    viewModel.goToQuestion(index);
                                    onEditQuestion?.call(index);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              q.prompt,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: chosenOption != null
                                    ? theme.colorScheme.surfaceContainerHighest.withAlpha(128)
                                    : theme.colorScheme.errorContainer.withAlpha(64),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                chosenOption != null
                                    ? chosenOption.label
                                    : (q.isRequired ? 'Answer Required' : 'Skipped (Optional)'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: chosenOption != null
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.error,
                                  fontWeight:
                                      chosenOption != null ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  const SizedBox(height: 20),
                  if (onRetakeQuiz != null)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        key: const Key('retake_quiz_button'),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retake Questionnaire'),
                        onPressed: onRetakeQuiz,
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

  Widget _buildPrivacyHeaderCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(96),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private to You',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your individual questionnaire responses are stored privately and never displayed on public member profiles.',
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Answers Recorded',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Take our optional personality questionnaire to discover your vibe and unlock compatibility highlights.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onRetakeQuiz != null)
              FilledButton.icon(
                key: const Key('take_quiz_button'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Take Personality Quiz'),
                onPressed: onRetakeQuiz,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_person_outlined,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Access Restricted',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.errorMessage ??
                  'Adult eligibility verification and Social opt-in are required.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
