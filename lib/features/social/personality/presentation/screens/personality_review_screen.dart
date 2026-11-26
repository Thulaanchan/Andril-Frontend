import 'package:flutter/material.dart';
import '../viewmodels/personality_questionnaire_viewmodel.dart';

/// Presentation screen for reviewing answers before final completion (S82 Questionnaire Review).
///
/// Follows M5 Personality & Contract Readiness Governance:
/// - Distinguishes between local answer draft completion and server-confirmed submission.
/// - Does NOT claim successful server submission while the backend response endpoint is dormant.
/// - Allows reviewing each question's selected answer and jumping back to edit answers.
/// - Informs user that responses are stored locally and submission is pending backend activation.
class PersonalityReviewScreen extends StatelessWidget {
  final PersonalityQuestionnaireViewModel viewModel;
  final ValueChanged<int>? onEditQuestion;
  final VoidCallback? onDone;

  const PersonalityReviewScreen({
    super.key,
    required this.viewModel,
    this.onEditQuestion,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questionnaire = viewModel.questionnaire;
    final draft = viewModel.answerDraft;

    if (questionnaire == null || draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Answers')),
        body: const Center(child: Text('No active questionnaire draft to review.')),
      );
    }

    final isDraftComplete = viewModel.isComplete;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Answers'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Completion header badge
                      _buildHeaderCard(theme, isDraftComplete),
                      const SizedBox(height: 20),
                      Text(
                        'Your Responses',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // List of question summaries
                      ...questionnaire.questions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final q = entry.value;
                        final chosenOptionId = draft.answers[q.id];
                        final chosenOption = q.options.where((opt) => opt.id == chosenOptionId).firstOrNull;

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
                                    const Spacer(),
                                    IconButton(
                                      key: Key('edit_question_$index'),
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
                                      fontWeight: chosenOption != null ? FontWeight.normal : FontWeight.bold,
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
                      // Dormant notice & confirmation
                      _buildDormantSubmissionNotice(theme),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          key: const Key('save_review_button'),
                          onPressed: isDraftComplete ? onDone : null,
                          child: const Text('Save & Return to Profile'),
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

  Widget _buildHeaderCard(ThemeData theme, bool isComplete) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete
            ? theme.colorScheme.primaryContainer.withAlpha(96)
            : theme.colorScheme.errorContainer.withAlpha(96),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.task_alt : Icons.warning_amber_rounded,
            size: 36,
            color: isComplete ? theme.colorScheme.primary : theme.colorScheme.error,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete ? 'All Required Questions Answered' : 'Incomplete Responses',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isComplete
                      ? 'You can review and adjust any answer before saving.'
                      : 'Please answer all required questions before saving.',
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

  Widget _buildDormantSubmissionNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(64),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your responses are saved locally. Cloud synchronization will activate once server response processing is enabled.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
