import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';
import '../../../shared/presentation/widgets/andril_module_app_bar.dart';
import '../viewmodels/learning_onboarding_viewmodel.dart';
import '../widgets/onboarding_step_basics_widget.dart';
import '../widgets/onboarding_step_goals_widget.dart';
import '../widgets/onboarding_step_learn_widget.dart';
import '../widgets/onboarding_step_review_widget.dart';
import '../widgets/onboarding_step_share_widget.dart';

/// Complete multi-step presentation container for the Learning module onboarding flow.
///
/// Follows the approved five-step architecture:
/// 1. Profile Basics (display name, bio)
/// 2. Skills to Learn
/// 3. Skills to Share
/// 4. Learning Goals & Optional Availability
/// 5. Proposed Profile Review (read-only draft summary)
///
/// Boundaries & Lifecycle:
/// - Supports caller-injected or internally created [LearningOnboardingViewModel].
/// - Disposes the ViewModel exclusively if internally created and owned.
/// - Preserves draft state safely across forward and backward navigation.
/// - Prompts for confirmation when the user attempts to exit with unsaved changes.
/// - Does NOT grant module activation (Submit remains disabled pending M2 contract).
/// - Does NOT expose private account identity, tokens, or other module profiles.
class LearningOnboardingScreen extends StatefulWidget {
  /// Optional pre-configured ViewModel. If null, an internal instance is created and owned.
  final LearningOnboardingViewModel? viewModel;

  /// Optional injected suggested skills catalogue for Steps 2 and 3.
  final List<String>? availableSkills;

  /// Optional injected suggested goals catalogue for Step 4.
  final List<String>? availableGoals;

  /// Optional callback invoked when the user confirms discarding changes and exiting.
  final VoidCallback? onExit;

  /// Optional callback invoked if completion is triggered.
  final VoidCallback? onComplete;

  /// Creates a [LearningOnboardingScreen].
  const LearningOnboardingScreen({
    super.key,
    this.viewModel,
    this.availableSkills,
    this.availableGoals,
    this.onExit,
    this.onComplete,
  });

  @override
  State<LearningOnboardingScreen> createState() =>
      _LearningOnboardingScreenState();
}

class _LearningOnboardingScreenState extends State<LearningOnboardingScreen> {
  late final LearningOnboardingViewModel _viewModel;
  bool _ownsViewModel = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _ownsViewModel = false;
    } else {
      _viewModel = LearningOnboardingViewModel();
      _ownsViewModel = true;
    }
    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  /// Prompts the user to confirm discarding unsaved draft inputs before exiting.
  Future<bool> _confirmDiscardChanges(BuildContext context) async {
    if (!_viewModel.hasUnsavedChanges) return true;

    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Discard Changes?',
            key: Key('discard_dialog_title'),
          ),
          content: const Text(
            'You have unsaved changes in your Learning profile draft. If you exit now, your draft will be discarded.',
            key: Key('discard_dialog_content'),
          ),
          actions: [
            TextButton(
              key: const Key('discard_dialog_cancel_button'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Editing'),
            ),
            ElevatedButton(
              key: const Key('discard_dialog_confirm_button'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    return discard ?? false;
  }

  Future<void> _handleExit(BuildContext context) async {
    if (_isExiting) return;
    _isExiting = true;
    try {
      final shouldExit = await _confirmDiscardChanges(context);
      if (!mounted) return;
      if (shouldExit) {
        if (widget.onExit != null) {
          widget.onExit!.call();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } else {
        _isExiting = false;
      }
    } catch (_) {
      if (mounted) {
        _isExiting = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExit(context);
      },
      child: Scaffold(
        backgroundColor: LearningColors.background,
        appBar: AndrilModuleAppBar(
          moduleName: 'Learning',
          leading: IconButton(
            key: const Key('onboarding_exit_button'),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Exit Onboarding',
            onPressed: () => _handleExit(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProgressHeader(),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: _buildCurrentStepWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the persistent 5-step progress indicator and title header.
  Widget _buildProgressHeader() {
    final int currentStep = _viewModel.currentStep;
    final int stepNumber = currentStep + 1;
    final String stepTitle = _viewModel.step.title;

    return Semantics(
      label: 'Step $stepNumber of 5: $stepTitle',
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        color: LearningColors.cardSurface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step $stepNumber of 5',
                  key: const Key('onboarding_step_counter'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    stepTitle,
                    key: const Key('onboarding_step_title'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: LearningColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 5-segment discrete progress indicator
            Row(
              key: const Key('onboarding_progress_indicator'),
              children: List.generate(LearningOnboardingViewModel.totalSteps,
                  (index) {
                final bool isCompletedOrCurrent = index <= currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(
                      right: index < LearningOnboardingViewModel.totalSteps - 1
                          ? 6.0
                          : 0.0,
                    ),
                    decoration: BoxDecoration(
                      color: isCompletedOrCurrent
                          ? LearningColors.primary
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Instantiates the active step widget according to the current ViewModel state.
  Widget _buildCurrentStepWidget() {
    switch (_viewModel.step) {
      case OnboardingStep.basics:
        return OnboardingStepBasicsWidget(
          key: const ValueKey('step_basics_widget'),
          viewModel: _viewModel,
          onContinue: () {
            // Step 0 validates display name and advances via ViewModel.nextStep()
          },
        );
      case OnboardingStep.skillsToLearn:
        return OnboardingStepLearnWidget(
          key: const ValueKey('step_learn_widget'),
          viewModel: _viewModel,
          availableSkills: widget.availableSkills,
          onContinue: () {
            // Step 1 advances via ViewModel.nextStep()
          },
          onBack: () {
            // Step 1 retreats via ViewModel.previousStep()
          },
        );
      case OnboardingStep.skillsToShare:
        return OnboardingStepShareWidget(
          key: const ValueKey('step_share_widget'),
          viewModel: _viewModel,
          availableSkills: widget.availableSkills,
          onContinue: () {
            _viewModel.nextStep();
          },
          onBack: () {
            // Step 2 retreats via ViewModel.previousStep()
          },
        );
      case OnboardingStep.goals:
        return OnboardingStepGoalsWidget(
          key: const ValueKey('step_goals_widget'),
          viewModel: _viewModel,
          availableGoals: widget.availableGoals,
          onContinue: () {
            // Step 3 advances via ViewModel.nextStep()
          },
          onBack: () {
            // Step 3 retreats via ViewModel.previousStep()
          },
        );
      case OnboardingStep.review:
        return OnboardingStepReviewWidget(
          key: const ValueKey('step_review_widget'),
          viewModel: _viewModel,
          onBack: () {
            // Step 4 retreats via ViewModel.previousStep()
          },
          onEditStep: (stepIndex) {
            _viewModel.setStep(stepIndex);
          },
        );
    }
  }
}
