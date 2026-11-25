import 'package:flutter/foundation.dart';
import 'social_profile_draft.dart';
import 'social_profile_repository.dart';

/// Distinct states for Social profile creation and draft persistence.
enum SocialProfileStatus {
  /// Initial idle state before submission.
  initial,

  /// Asynchronous draft save or profile operation in progress.
  loading,

  /// Draft saved successfully (does NOT indicate onboarding completion).
  success,

  /// The requested display name is taken or reserved by another account.
  conflict,

  /// Caller lacks adult eligibility or is denied Social access.
  denied,

  /// General failure (validation error, dependency failure, or network drop).
  error,
}

/// Manages client-side form state and asynchronous persistence for Social profile creation.
///
/// Follows M5-FE-S02-STATE-01:
/// - Maintains immutable draft state.
/// - Prevents concurrent duplicate submissions.
/// - Distinguishes server validation and display-name conflicts.
/// - Discards stale async responses when session generation changes or on disposal.
/// - Clears sensitive draft state on session invalidation.
/// - Does not grant onboarding completion or navigate directly to Social Home.
class SocialProfileViewModel extends ChangeNotifier {
  final SocialProfileRepository repository;

  SocialProfileDraft _draft;
  SocialProfileStatus _status = SocialProfileStatus.initial;
  String? _errorMessage;
  int _sessionGeneration = 0;
  bool _disposed = false;

  SocialProfileViewModel({
    required this.repository,
    SocialProfileDraft initialDraft = const SocialProfileDraft(),
  }) : _draft = initialDraft;

  /// The current immutable draft state.
  SocialProfileDraft get draft => _draft;

  /// The current operation status.
  SocialProfileStatus get status => _status;

  /// Diagnostic error message or null if no error.
  String? get errorMessage => _errorMessage;

  /// Whether an asynchronous operation is in progress.
  bool get isLoading => _status == SocialProfileStatus.loading;

  /// Whether the draft has been successfully saved.
  bool get isSuccess => _status == SocialProfileStatus.success;

  /// Whether the display name was rejected due to a conflict or reservation.
  bool get isConflict => _status == SocialProfileStatus.conflict;

  /// Whether authorization was denied.
  bool get isDenied => _status == SocialProfileStatus.denied;

  /// Whether a generic error occurred.
  bool get isError => _status == SocialProfileStatus.error;

  /// Whether the draft is valid and ready for submission.
  bool get canSubmit => _draft.isValid && !isLoading;

  /// Updates the draft display name and resets transient error state.
  void updateDisplayName(String value) {
    if (_disposed) return;
    _draft = _draft.copyWith(displayName: value);
    if (_status == SocialProfileStatus.conflict ||
        _status == SocialProfileStatus.error) {
      _status = SocialProfileStatus.initial;
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// Updates the draft bio and resets transient error state.
  void updateBio(String? value) {
    if (_disposed) return;
    _draft = _draft.copyWith(bio: value);
    if (_status == SocialProfileStatus.error) {
      _status = SocialProfileStatus.initial;
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// Updates the optional local profile photo path.
  void updateProfilePhoto(String? path) {
    if (_disposed) return;
    _draft = _draft.copyWith(profilePhotoPath: path);
    notifyListeners();
  }

  /// Asynchronously saves the Social profile draft.
  ///
  /// Prevents duplicate concurrent submissions and discards stale responses.
  /// Returns `true` on successful draft save, `false` otherwise.
  Future<bool> saveDraft() async {
    if (_disposed) return false;

    // Prevent duplicate concurrent submission
    if (isLoading) {
      return false;
    }

    // Client-side validation check
    if (!_draft.isValid) {
      _status = SocialProfileStatus.error;
      _errorMessage = _draft.displayNameError ?? _draft.bioError ?? 'Invalid input.';
      notifyListeners();
      return false;
    }

    _status = SocialProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final currentGen = ++_sessionGeneration;

    try {
      final result = await repository.saveProfileDraft(_draft);

      // Check if disposed or superseded by a newer session/action
      if (_disposed || currentGen != _sessionGeneration) {
        return false;
      }

      switch (result) {
        case SocialProfileSuccess(:final draft):
          _draft = draft;
          _status = SocialProfileStatus.success;
          _errorMessage = null;
          notifyListeners();
          return true;

        case SocialProfileError(:final failure):
          switch (failure.type) {
            case SocialProfileFailureType.displayNameUnavailable:
              _status = SocialProfileStatus.conflict;
            case SocialProfileFailureType.authorizationDenied:
              _status = SocialProfileStatus.denied;
            case SocialProfileFailureType.sessionExpired:
              _status = SocialProfileStatus.denied;
              _draft = const SocialProfileDraft(); // Invalidate draft on session expiry
            case SocialProfileFailureType.cancelled:
              _status = SocialProfileStatus.initial;
            case SocialProfileFailureType.validationFailure:
            case SocialProfileFailureType.dependencyFailure:
            case SocialProfileFailureType.unknown:
              _status = SocialProfileStatus.error;
          }
          _errorMessage = failure.message;
          notifyListeners();
          return false;
      }
    } catch (e) {
      if (_disposed || currentGen != _sessionGeneration) {
        return false;
      }
      _status = SocialProfileStatus.error;
      _errorMessage = 'An unexpected error occurred while saving profile.';
      notifyListeners();
      return false;
    }
  }

  /// Clears sensitive profile draft data when session or auth context is invalidated.
  void invalidateSession() {
    if (_disposed) return;
    _sessionGeneration++;
    _draft = const SocialProfileDraft();
    _status = SocialProfileStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  /// Resets status to initial state without altering draft form inputs.
  void resetStatus() {
    if (_disposed) return;
    _status = SocialProfileStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionGeneration++;
    super.dispose();
  }
}
