import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';
import '../viewmodels/learning_onboarding_viewmodel.dart';

/// Step 3: Learning Skills to Share selection and input widget.
///
/// Enables learners to specify skills or subjects they are able and willing to share
/// with study partners or peers. Stores selections strictly in the Skills-to-Share
/// draft collection without contaminating Skills to Learn or creating backend records.
class OnboardingStepShareWidget extends StatefulWidget {
  /// The onboarding viewmodel managing the presentation draft.
  final LearningOnboardingViewModel viewModel;

  /// Optional suggested skills catalogue. When null, a default starter set is shown.
  final List<String>? availableSkills;

  /// Optional callback invoked when completing or proceeding from this step.
  final VoidCallback? onContinue;

  /// Optional callback invoked when returning to the previous step.
  final VoidCallback? onBack;

  /// Creates an [OnboardingStepShareWidget].
  const OnboardingStepShareWidget({
    super.key,
    required this.viewModel,
    this.availableSkills,
    this.onContinue,
    this.onBack,
  });

  /// Default suggested starter skills for sharing when no external catalogue is provided.
  static const List<String> defaultSkills = [
    'Python',
    'UI/UX Design',
    'Mathematics',
    'English',
    'JavaScript',
    'Graphic Design',
    'Project Management',
    'Public Speaking',
  ];

  @override
  State<OnboardingStepShareWidget> createState() =>
      _OnboardingStepShareWidgetState();
}

class _OnboardingStepShareWidgetState extends State<OnboardingStepShareWidget> {
  final TextEditingController _customSkillController = TextEditingController();

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
    _customSkillController.dispose();
    super.dispose();
  }

  void _addCustomSkill() {
    final text = _customSkillController.text.trim();
    if (text.isNotEmpty) {
      widget.viewModel.addSkillToShare(text);
      _customSkillController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCatalogue =
        widget.availableSkills ?? OnboardingStepShareWidget.defaultSkills;
    final selectedSkills = widget.viewModel.skillsToShare;

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
                  Icons.handshake_outlined,
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
                      'Skills to Share',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Step 3 of 3: What can you help others with?',
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

          // Custom skill input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('custom_skill_share_field'),
                  controller: _customSkillController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Add skill to share (e.g. Git)',
                    prefixIcon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: LearningColors.secondaryText,
                      size: 20,
                    ),
                  ),
                  onSubmitted: (_) => _addCustomSkill(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  key: const Key('add_custom_skill_share_button'),
                  onPressed: _addCustomSkill,
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

          // Suggested skills header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Suggested Topics',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: LearningColors.heading,
                ),
              ),
              if (selectedSkills.isNotEmpty)
                Text(
                  '${selectedSkills.length} selected',
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
                'No suggested topics available. Use the text field above to add skills you can share.',
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
              children: effectiveCatalogue.map((skill) {
                final isSelected = selectedSkills.contains(skill);
                return FilterChip(
                  key: Key('skill_chip_share_$skill'),
                  label: Text(skill),
                  selected: isSelected,
                  onSelected: (_) => widget.viewModel.toggleSkillToShare(skill),
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

          // Currently Selected Skills Summary (if any custom ones not in catalogue)
          if (selectedSkills.any((s) => !effectiveCatalogue.contains(s))) ...[
            const SizedBox(height: 20),
            const Text(
              'Custom Skills Added',
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
              children: selectedSkills
                  .where((s) => !effectiveCatalogue.contains(s))
                  .map((customSkill) {
                return Chip(
                  key: Key('custom_chip_share_$customSkill'),
                  label: Text(customSkill),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () =>
                      widget.viewModel.removeSkillToShare(customSkill),
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

          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              if (widget.onBack != null)
                Expanded(
                  child: OutlinedButton(
                    key: const Key('onboarding_share_back_button'),
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
                    key: const Key('onboarding_share_continue_button'),
                    onPressed: () {
                      widget.onContinue?.call();
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
                    child: const Text('Continue'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
