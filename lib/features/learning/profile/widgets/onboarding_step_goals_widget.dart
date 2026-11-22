import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';
import '../viewmodels/learning_onboarding_viewmodel.dart';

/// Step 4: Learning Goals selection and custom input widget.
///
/// Follows approved visual specifications (Q06_LUC-03_Learning Goals Setup) allowing
/// the learner to specify their learning goals and optional availability preferences.
/// Mutates strictly the temporary Learning Goals presentation draft without
/// creating database records, classroom memberships, or backend activation requests.
class OnboardingStepGoalsWidget extends StatefulWidget {
  /// The onboarding viewmodel managing the presentation draft.
  final LearningOnboardingViewModel viewModel;

  /// Optional suggested goals catalogue. When null, a default starter set is shown.
  final List<String>? availableGoals;

  /// Optional callback invoked when advancing to the next step.
  final VoidCallback? onContinue;

  /// Optional callback invoked when returning to the previous step.
  final VoidCallback? onBack;

  /// Creates an [OnboardingStepGoalsWidget].
  const OnboardingStepGoalsWidget({
    super.key,
    required this.viewModel,
    this.availableGoals,
    this.onContinue,
    this.onBack,
  });

  /// Default suggested starter goals for presentation when no external catalogue is provided.
  static const List<String> defaultGoals = [
    'Build practical portfolio projects',
    'Collaborate with study partners',
    'Master Flutter mobile architecture',
    'Prepare for technical interviews',
    'Learn a new programming language',
    'Contribute to open source software',
  ];

  /// Standard optional availability preferences sourced from Q07 design references.
  static const List<String> standardAvailabilityOptions = [
    '1-3 hrs/week',
    '3-5 hrs/week',
    '5-10 hrs/week',
    'Flexible',
  ];

  @override
  State<OnboardingStepGoalsWidget> createState() =>
      _OnboardingStepGoalsWidgetState();
}

class _OnboardingStepGoalsWidgetState extends State<OnboardingStepGoalsWidget> {
  final TextEditingController _customGoalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _customGoalController.dispose();
    super.dispose();
  }

  void _addCustomGoal() {
    final text = _customGoalController.text.trim();
    if (text.isNotEmpty) {
      widget.viewModel.addLearningGoal(text);
      _customGoalController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCatalogue =
        widget.availableGoals ?? OnboardingStepGoalsWidget.defaultGoals;
    final selectedGoals = widget.viewModel.learningGoals;
    final currentAvailability = widget.viewModel.availabilityPreference;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: LearningColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: LearningColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Goals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Step 4 of 5: What would you like to achieve?',
                      style: TextStyle(
                        fontSize: 13,
                        color: LearningColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom goal input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('custom_goal_field'),
                  controller: _customGoalController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Add a specific goal (e.g. Master Flutter)',
                    prefixIcon: Icon(
                      Icons.flag_outlined,
                      color: LearningColors.secondaryText,
                      size: 20,
                    ),
                  ),
                  onSubmitted: (_) => _addCustomGoal(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  key: const Key('add_custom_goal_button'),
                  onPressed: _addCustomGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LearningColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Suggested goals header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Suggested Goals',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: LearningColors.heading,
                ),
              ),
              if (selectedGoals.isNotEmpty)
                Text(
                  '${selectedGoals.length} selected',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LearningColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.viewModel.isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (effectiveCatalogue.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: LearningColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'No suggested goals available. Use the text field above to add your custom learning goals.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: LearningColors.secondaryText,
                ),
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: effectiveCatalogue.map((goal) {
                final isSelected = selectedGoals.contains(goal);
                return FilterChip(
                  key: Key('goal_chip_$goal'),
                  label: Text(goal),
                  selected: isSelected,
                  onSelected: (_) => widget.viewModel.toggleLearningGoal(goal),
                  selectedColor: LearningColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: LearningColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? LearningColors.primary
                        : LearningColors.heading,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  backgroundColor: LearningColors.cardSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? LearningColors.primary
                          : const Color(0xFFCBD5E1),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                );
              }).toList(),
            ),
          ],

          // Currently Selected Goals Summary (for custom goals not in catalogue)
          if (selectedGoals.any((g) => !effectiveCatalogue.contains(g))) ...[
            const SizedBox(height: 20),
            const Text(
              'Custom Goals Added',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: selectedGoals
                  .where((g) => !effectiveCatalogue.contains(g))
                  .map((customGoal) {
                return Chip(
                  key: Key('custom_chip_goal_$customGoal'),
                  label: Text(customGoal),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () =>
                      widget.viewModel.removeLearningGoal(customGoal),
                  backgroundColor:
                      LearningColors.primary.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(
                    color: LearningColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(
                      color: LearningColors.primary,
                      width: 1.0,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 28),

          // Optional Weekly Availability Section (Q07 design reference)
          const Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 18,
                color: LearningColors.primary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Weekly Availability (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: LearningColors.heading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a preliminary draft availability preference for study matching.',
            style: TextStyle(
              fontSize: 12,
              color: LearningColors.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: OnboardingStepGoalsWidget.standardAvailabilityOptions
                .map((option) {
              final isSelected = currentAvailability == option;
              return ChoiceChip(
                key: Key('availability_chip_$option'),
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  widget.viewModel
                      .setAvailabilityPreference(selected ? option : '');
                },
                selectedColor: LearningColors.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected
                      ? LearningColors.primary
                      : LearningColors.heading,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                backgroundColor: LearningColors.cardSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? LearningColors.primary
                        : const Color(0xFFCBD5E1),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              if (widget.onBack != null)
                Expanded(
                  child: OutlinedButton(
                    key: const Key('onboarding_goals_back_button'),
                    onPressed: () {
                      widget.viewModel.previousStep();
                      widget.onBack?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LearningColors.heading,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      minimumSize: const Size(100, 48),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (widget.onBack != null && widget.onContinue != null)
                const SizedBox(width: 12),
              if (widget.onContinue != null)
                Expanded(
                  child: ElevatedButton(
                    key: const Key('onboarding_goals_continue_button'),
                    onPressed: () {
                      if (widget.viewModel.nextStep()) {
                        widget.onContinue?.call();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LearningColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 0,
                      minimumSize: const Size(100, 48),
                    ),
                    child: const Text(
                      'Continue to Review',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
