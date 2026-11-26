import 'package:flutter/material.dart';
import '../../domain/entities/personality_questionnaire.dart';
import '../viewmodels/personality_questionnaire_viewmodel.dart';

/// Presentation screen for the interactive Personality Questionnaire.
///
/// Follows M5 Personality & Privacy Governance:
/// - Renders canonical questions dynamically from the authoritative definition.
/// - Single-choice selection per question with distinct active/unselected visual styling.
/// - Required questions enforce selection before advancing or completing.
/// - Provides full support for loading, empty, access denied, and service unavailable states.
class PersonalityQuestionnaireScreen extends StatefulWidget {
  final PersonalityQuestionnaireViewModel viewModel;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const PersonalityQuestionnaireScreen({
    super.key,
    required this.viewModel,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<PersonalityQuestionnaireScreen> createState() => _PersonalityQuestionnaireScreenState();
}

class _PersonalityQuestionnaireScreenState extends State<PersonalityQuestionnaireScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    if (widget.viewModel.status == PersonalityQuestionnaireStatus.initial) {
      widget.viewModel.loadQuestionnaire();
    }
  }

  @override
  void didUpdateWidget(covariant PersonalityQuestionnaireScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      widget.viewModel.addListener(_onViewModelChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personality Quiz'),
        actions: [
          TextButton(
            key: const Key('cancel_quiz_button'),
            onPressed: () {
              vm.cancelDraft();
              widget.onCancel?.call();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(context, vm, theme),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PersonalityQuestionnaireViewModel vm,
    ThemeData theme,
  ) {
    if (vm.isAccessDenied) {
      return _buildAccessDeniedState(theme, vm);
    }

    if (vm.isServiceUnavailable) {
      return _buildServiceUnavailableState(theme, vm);
    }

    if (vm.status == PersonalityQuestionnaireStatus.error) {
      return _buildErrorState(theme, vm);
    }

    if (vm.isLoading || vm.questionnaire == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final question = vm.currentQuestion;
    if (question == null) {
      return _buildEmptyState(theme, vm);
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
                  _buildProgressBar(vm, theme),
                  const SizedBox(height: 24),
                  _buildQuestionHeader(question, vm, theme),
                  const SizedBox(height: 20),
                  ..._buildOptionCards(question, vm, theme),
                  const Spacer(),
                  const SizedBox(height: 24),
                  _buildNavigationControls(vm, theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(PersonalityQuestionnaireViewModel vm, ThemeData theme) {
    final current = vm.currentQuestionIndex + 1;
    final total = vm.totalQuestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question $current of $total',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(vm.progress * 100).toInt()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: vm.progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionHeader(
    PersonalityQuestion question,
    PersonalityQuestionnaireViewModel vm,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.isRequired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Required',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          question.prompt,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptionCards(
    PersonalityQuestion question,
    PersonalityQuestionnaireViewModel vm,
    ThemeData theme,
  ) {
    final selectedOptionId = vm.selectedOptionForCurrentQuestion();

    return question.options.map((option) {
      final isSelected = option.id == selectedOptionId;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          key: Key('option_${option.id}'),
          borderRadius: BorderRadius.circular(14),
          onTap: () => vm.selectOption(option.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withAlpha(128)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildNavigationControls(PersonalityQuestionnaireViewModel vm, ThemeData theme) {
    final hasPrev = vm.hasPreviousQuestion;
    final isLast = vm.isLastQuestion;
    final currentQ = vm.currentQuestion;
    final currentAnswer = vm.selectedOptionForCurrentQuestion();
    final canAdvance = currentQ == null || !currentQ.isRequired || (currentAnswer != null && currentAnswer.isNotEmpty);

    return Row(
      children: [
        if (hasPrev) ...[
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                key: const Key('prev_question_button'),
                onPressed: vm.previousQuestion,
                child: const Text('Previous'),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 48,
            child: FilledButton(
              key: Key(isLast ? 'finish_quiz_button' : 'next_question_button'),
              onPressed: canAdvance
                  ? () {
                      if (isLast) {
                        widget.onComplete?.call();
                      } else {
                        vm.nextQuestion();
                      }
                    }
                  : null,
              child: Text(isLast ? 'Review Answers' : 'Next Question'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessDeniedState(ThemeData theme, PersonalityQuestionnaireViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Access Restricted', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? 'Adult eligibility verification and Social opt-in are required.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => vm.loadQuestionnaire(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceUnavailableState(ThemeData theme, PersonalityQuestionnaireViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text('Quiz Unavailable', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? 'The personality questionnaire is currently preparing and unavailable.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => vm.loadQuestionnaire(refresh: true),
              child: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, PersonalityQuestionnaireViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Something Went Wrong', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(vm.errorMessage ?? 'Failed to load questionnaire.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => vm.loadQuestionnaire(refresh: true),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, PersonalityQuestionnaireViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No Questions Available', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'No questionnaire questions were returned by the server.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => vm.loadQuestionnaire(refresh: true),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
