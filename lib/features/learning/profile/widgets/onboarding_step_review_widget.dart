import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';
import '../viewmodels/learning_onboarding_viewmodel.dart';

/// Step 5: Proposed Profile Review read-only summary widget.
///
/// Under ANDRIL Phase 10 architecture, this component is a planned orchestration
/// surface allowing the user to review all collected onboarding drafts in one
/// place before submission. It is NOT an existing Q07 visual reproduction.
///
/// Boundaries & Invariants:
/// - Purely read-only presentation of unpersisted ViewModel draft state.
/// - Does NOT manufacture, assign, or expose accountId, JWT tokens, or profileId.
/// - Does NOT grant module activation (Submit button is visibly disabled pending M2 backend contract).
/// - Does NOT automatically navigate to Learning Home.
/// - Does NOT interact with or expose Hobbies or Social module profiles.
class OnboardingStepReviewWidget extends StatelessWidget {
  /// The onboarding viewmodel managing the presentation draft.
  final LearningOnboardingViewModel viewModel;

  /// Optional callback invoked when the user returns to the previous step.
  final VoidCallback? onBack;

  /// Optional callback invoked when user requests editing a specific step index.
  final void Function(int stepIndex)? onEditStep;

  /// Creates an [OnboardingStepReviewWidget].
  const OnboardingStepReviewWidget({
    super.key,
    required this.viewModel,
    this.onBack,
    this.onEditStep,
  });

  @override
  Widget build(BuildContext context) {
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
                  Icons.rate_review_outlined,
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
                      'Review & Confirm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Step 5 of 5: Review your Learning Profile draft',
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

          // Activation disclaimer banner
          Container(
            key: const Key('review_activation_disclaimer'),
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF86EFAC),
                width: 1.0,
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF15803D),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Proposed Review Layout: Profile activation is managed by M2 and requires backend authentication. This is an unpersisted draft review.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF166534),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Profile Basics Section
          _buildReviewCard(
            title: 'Profile Basics',
            icon: Icons.person_outline_rounded,
            onEdit: () => onEditStep?.call(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Display Name',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LearningColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  viewModel.displayName.isNotEmpty
                      ? viewModel.displayName
                      : 'Not provided',
                  key: const Key('review_display_name_text'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: LearningColors.heading,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Learning Bio / Headline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LearningColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  viewModel.bio.isNotEmpty ? viewModel.bio : 'None provided',
                  key: const Key('review_bio_text'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: LearningColors.heading,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Skills to Learn Section
          _buildReviewCard(
            title: 'Skills to Learn',
            icon: Icons.school_outlined,
            onEdit: () => onEditStep?.call(1),
            child: Column(
              key: const Key('review_skills_to_learn_section'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (viewModel.skillsToLearn.isEmpty)
                  const Text(
                    'No skills selected',
                    key: Key('review_empty_skills_learn'),
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: LearningColors.secondaryText,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: viewModel.skillsToLearn.map((skill) {
                      return Chip(
                        label: Text(skill),
                        backgroundColor:
                            LearningColors.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(
                          color: LearningColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: LearningColors.primary,
                            width: 0.8,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Skills to Share Section
          _buildReviewCard(
            title: 'Skills to Share',
            icon: Icons.handshake_outlined,
            onEdit: () => onEditStep?.call(2),
            child: Column(
              key: const Key('review_skills_to_share_section'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (viewModel.skillsToShare.isEmpty)
                  const Text(
                    'No skills specified',
                    key: Key('review_empty_skills_share'),
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: LearningColors.secondaryText,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: viewModel.skillsToShare.map((skill) {
                      return Chip(
                        label: Text(skill),
                        backgroundColor:
                            const Color(0xFF0284C7).withValues(alpha: 0.1),
                        labelStyle: const TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Color(0xFF0284C7),
                            width: 0.8,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Learning Goals Section
          _buildReviewCard(
            title: 'Learning Goals',
            icon: Icons.track_changes_rounded,
            onEdit: () => onEditStep?.call(3),
            child: Column(
              key: const Key('review_learning_goals_section'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (viewModel.learningGoals.isEmpty)
                  const Text(
                    'No goals selected',
                    key: Key('review_empty_goals'),
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: LearningColors.secondaryText,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: viewModel.learningGoals.map((goal) {
                      return Chip(
                        label: Text(goal),
                        backgroundColor:
                            const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        labelStyle: const TextStyle(
                          color: Color(0xFF6D28D9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Color(0xFF7C3AED),
                            width: 0.8,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly Availability Section
          _buildReviewCard(
            title: 'Weekly Availability',
            icon: Icons.schedule_outlined,
            onEdit: () => onEditStep?.call(3),
            child: Text(
              viewModel.availabilityPreference.isNotEmpty
                  ? viewModel.availabilityPreference
                  : 'Not specified',
              key: const Key('review_availability_text'),
              style: TextStyle(
                fontSize: 14,
                color: viewModel.availabilityPreference.isNotEmpty
                    ? LearningColors.heading
                    : LearningColors.secondaryText,
                fontStyle: viewModel.availabilityPreference.isNotEmpty
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons & activation safeguards
          Row(
            children: [
              if (onBack != null)
                Expanded(
                  child: OutlinedButton(
                    key: const Key('onboarding_review_back_button'),
                    onPressed: () {
                      viewModel.previousStep();
                      onBack?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LearningColors.heading,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      minimumSize: const Size(100, 48),
                    ),
                    child: const Text('Back to Goals'),
                  ),
                ),
              if (onBack != null) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  key: const Key('onboarding_review_submit_button'),
                  // Disabled: backend activation gateway is pending M2 integration
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 0,
                    minimumSize: const Size(120, 48),
                  ),
                  child: const Text('Submit & Activate'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Backend module activation gateway pending M2 contract. Submit is currently disabled.',
              key: Key('review_submit_pending_note'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: LearningColors.secondaryText,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: LearningColors.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: LearningColors.heading,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: LearningColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
