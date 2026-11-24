import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';
import '../viewmodels/learning_onboarding_viewmodel.dart';

/// Step 1: Learning Profile Basics input widget.
///
/// Follows approved visual specifications allowing the learner to draft their
/// module-specific display name and optional bio/headline without premature
/// M2 account modification or activation claims.
class OnboardingStepBasicsWidget extends StatefulWidget {
  /// The onboarding viewmodel managing the presentation draft.
  final LearningOnboardingViewModel viewModel;

  /// Optional callback invoked when the user requests advancement.
  final VoidCallback? onContinue;

  /// Creates an [OnboardingStepBasicsWidget].
  const OnboardingStepBasicsWidget({
    super.key,
    required this.viewModel,
    this.onContinue,
  });

  @override
  State<OnboardingStepBasicsWidget> createState() =>
      _OnboardingStepBasicsWidgetState();
}

class _OnboardingStepBasicsWidgetState
    extends State<OnboardingStepBasicsWidget> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.viewModel.displayName);
    _bioController = TextEditingController(text: widget.viewModel.bio);

    widget.viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    if (_nameController.text != widget.viewModel.displayName) {
      _nameController.text = widget.viewModel.displayName;
    }
    if (_bioController.text != widget.viewModel.bio) {
      _bioController.text = widget.viewModel.bio;
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

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
                  Icons.person_outline_rounded,
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
                      'Profile Basics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Step 1 of 3: Set up your Learning identity',
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
          const SizedBox(height: 24),

          // Display Name Field
          const Text(
            'Display Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('onboarding_display_name_field'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Alex Rivera or CodeLearner',
              errorText: widget.viewModel.displayNameError,
              prefixIcon: const Icon(
                Icons.badge_outlined,
                color: LearningColors.secondaryText,
                size: 20,
              ),
            ),
            onChanged: (value) => widget.viewModel.setDisplayName(value),
          ),
          const SizedBox(height: 6),
          const Text(
            'This name will be visible to study partners and circle members. Official uniqueness is validated upon activation.',
            style: TextStyle(
              fontSize: 12,
              color: LearningColors.secondaryText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),

          // Bio / Learning Headline Field
          const Text(
            'Learning Headline or Bio (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('onboarding_bio_field'),
            controller: _bioController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText:
                  'Share what you are studying, your interests, or your goals...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: LearningColors.secondaryText,
                  size: 20,
                ),
              ),
            ),
            onChanged: (value) => widget.viewModel.setBio(value),
          ),
          const SizedBox(height: 6),
          const Text(
            'You can update or expand this information at any time from your Profile settings.',
            style: TextStyle(
              fontSize: 12,
              color: LearningColors.secondaryText,
              height: 1.3,
            ),
          ),
          if (widget.onContinue != null) ...[
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('onboarding_basics_continue_button'),
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
                  minimumSize: const Size(120, 48),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Continue to Skills to Learn',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
