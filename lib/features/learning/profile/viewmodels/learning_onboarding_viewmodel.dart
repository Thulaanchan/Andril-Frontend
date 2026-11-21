import 'package:flutter/foundation.dart';

/// Supported onboarding steps in the Learning module onboarding flow.
///
/// Under ANDRIL Phase 10 architecture, the draft progression spans:
/// 0 - Profile Basics (display name, bio)
/// 1 - Skills to Learn
/// 2 - Skills to Share
/// 3 - Learning Goals
/// 4 - Review & Confirm
enum OnboardingStep {
  basics('Profile Basics'),
  skillsToLearn('Skills to Learn'),
  skillsToShare('Skills to Share'),
  goals('Learning Goals'),
  review('Review & Confirm');

  final String title;
  const OnboardingStep(this.title);
}

/// ViewModel managing draft user input for Learning onboarding steps.
///
/// Under ANDRIL architecture (§04.1-04.3, CF-01, CF-02, AND-M2-ONB-DEC-20261121-01),
/// M2 owns global account identity, module activation, and display-name uniqueness.
/// This ViewModel manages strictly temporary, unpersisted presentation drafts for
/// steps 1 through 5. It never manufactures account IDs, profile IDs, or local
/// activation grants.
class LearningOnboardingViewModel extends ChangeNotifier {
  /// Total number of onboarding steps managed in this flow.
  static const int totalSteps = 5;

  int _currentStep = 0;
  String _displayName = '';
  String _bio = '';
  final List<String> _skillsToLearn = [];
  final List<String> _skillsToShare = [];
  final List<String> _learningGoals = [];
  String _availabilityPreference = '';

  String? _displayNameError;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  /// Current active step index (0 = Basics, 1 = Skills to Learn, 2 = Skills to Share,
  /// 3 = Goals, 4 = Review).
  int get currentStep => _currentStep;

  /// Semantic enum representation of the current active step.
  OnboardingStep get step => OnboardingStep.values[_currentStep];

  /// Current draft display name for the Learning profile.
  String get displayName => _displayName;

  /// Optional biographical summary or tagline draft.
  String get bio => _bio;

  /// Validation error message for the display name field, if any.
  String? get displayNameError => _displayNameError;

  /// Whether an asynchronous background operation is in progress.
  bool get isLoading => _isLoading;

  /// User-facing error message for recoverable failures.
  String? get errorMessage => _errorMessage;

  /// Whether this ViewModel has been disposed.
  bool get isDisposed => _isDisposed;

  /// Defensive unmodifiable view of selected skills the learner wants to acquire.
  List<String> get skillsToLearn => List.unmodifiable(_skillsToLearn);

  /// Defensive unmodifiable view of selected skills the learner can teach or share.
  List<String> get skillsToShare => List.unmodifiable(_skillsToShare);

  /// Defensive unmodifiable view of selected learning goals.
  List<String> get learningGoals => List.unmodifiable(_learningGoals);

  /// Optional availability preference draft (e.g., '1-3 hrs/week', 'Flexible').
  String get availabilityPreference => _availabilityPreference;

  /// Whether any draft inputs have been modified by the user.
  bool get hasUnsavedChanges {
    return _displayName.trim().isNotEmpty ||
        _bio.trim().isNotEmpty ||
        _skillsToLearn.isNotEmpty ||
        _skillsToShare.isNotEmpty ||
        _learningGoals.isNotEmpty ||
        _availabilityPreference.trim().isNotEmpty;
  }

  /// Sets the draft display name and clears existing validation errors.
  void setDisplayName(String value) {
    if (_displayName != value) {
      _displayName = value;
      if (_displayNameError != null && value.trim().isNotEmpty) {
        _displayNameError = null;
      }
      notifyListeners();
    }
  }

  /// Sets the draft biographical summary.
  void setBio(String value) {
    if (_bio != value) {
      _bio = value;
      notifyListeners();
    }
  }

  /// Sets the optional availability preference draft.
  void setAvailabilityPreference(String value) {
    if (_availabilityPreference != value) {
      _availabilityPreference = value;
      notifyListeners();
    }
  }

  /// Sets the current step directly, clamping to valid indices [0, totalSteps - 1].
  void setStep(int stepIndex) {
    final int clamped = stepIndex.clamp(0, totalSteps - 1);
    if (_currentStep != clamped) {
      _currentStep = clamped;
      notifyListeners();
    }
  }

  /// Validates the current step and advances to the next step if valid.
  ///
  /// Returns `true` if transition was successful, `false` if validation failed
  /// or already at the final step.
  bool nextStep() {
    if (_currentStep == 0) {
      if (_displayName.trim().isEmpty) {
        _displayNameError = 'Display name is required';
        notifyListeners();
        return false;
      }
    }

    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      _displayNameError = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Navigates to the previous step without losing existing draft state.
  ///
  /// Returns `true` if transition occurred, `false` if already at the first step.
  bool previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Adds a skill to the Skills-to-Learn draft, preventing duplicate entries.
  void addSkillToLearn(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isNotEmpty && !_skillsToLearn.contains(trimmed)) {
      _skillsToLearn.add(trimmed);
      notifyListeners();
    }
  }

  /// Removes a skill from the Skills-to-Learn draft.
  void removeSkillToLearn(String skill) {
    if (_skillsToLearn.remove(skill.trim())) {
      notifyListeners();
    }
  }

  /// Toggles selection of a skill in the Skills-to-Learn draft.
  void toggleSkillToLearn(String skill) {
    final trimmed = skill.trim();
    if (_skillsToLearn.contains(trimmed)) {
      _skillsToLearn.remove(trimmed);
    } else if (trimmed.isNotEmpty) {
      _skillsToLearn.add(trimmed);
    }
    notifyListeners();
  }

  /// Clears all selected skills in the Skills-to-Learn draft.
  void clearSkillsToLearn() {
    if (_skillsToLearn.isNotEmpty) {
      _skillsToLearn.clear();
      notifyListeners();
    }
  }

  /// Adds a skill to the Skills-to-Share draft, preventing duplicate entries.
  void addSkillToShare(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isNotEmpty && !_skillsToShare.contains(trimmed)) {
      _skillsToShare.add(trimmed);
      notifyListeners();
    }
  }

  /// Removes a skill from the Skills-to-Share draft.
  void removeSkillToShare(String skill) {
    if (_skillsToShare.remove(skill.trim())) {
      notifyListeners();
    }
  }

  /// Toggles selection of a skill in the Skills-to-Share draft.
  void toggleSkillToShare(String skill) {
    final trimmed = skill.trim();
    if (_skillsToShare.contains(trimmed)) {
      _skillsToShare.remove(trimmed);
    } else if (trimmed.isNotEmpty) {
      _skillsToShare.add(trimmed);
    }
    notifyListeners();
  }

  /// Clears all selected skills in the Skills-to-Share draft.
  void clearSkillsToShare() {
    if (_skillsToShare.isNotEmpty) {
      _skillsToShare.clear();
      notifyListeners();
    }
  }

  /// Adds a learning goal to the draft, preventing duplicate entries.
  void addLearningGoal(String goal) {
    final trimmed = goal.trim();
    if (trimmed.isNotEmpty && !_learningGoals.contains(trimmed)) {
      _learningGoals.add(trimmed);
      notifyListeners();
    }
  }

  /// Removes a learning goal from the draft.
  void removeLearningGoal(String goal) {
    if (_learningGoals.remove(goal.trim())) {
      notifyListeners();
    }
  }

  /// Toggles selection of a learning goal in the draft.
  void toggleLearningGoal(String goal) {
    final trimmed = goal.trim();
    if (_learningGoals.contains(trimmed)) {
      _learningGoals.remove(trimmed);
    } else if (trimmed.isNotEmpty) {
      _learningGoals.add(trimmed);
    }
    notifyListeners();
  }

  /// Clears all selected learning goals in the draft.
  void clearLearningGoals() {
    if (_learningGoals.isNotEmpty) {
      _learningGoals.clear();
      notifyListeners();
    }
  }

  /// Sets the loading state.
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Sets the error message.
  void setErrorMessage(String? message) {
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  /// Resets all temporary draft state to initial defaults.
  void reset() {
    _currentStep = 0;
    _displayName = '';
    _bio = '';
    _skillsToLearn.clear();
    _skillsToShare.clear();
    _learningGoals.clear();
    _availabilityPreference = '';
    _displayNameError = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    super.dispose();
  }
}
