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
/// Follows M5-FE-S02-SEC-02:
/// - Maintains immutable draft state.
/// - Enforces independent in-flight submission guard against concurrent requests.
/// - resetStatus cannot permit duplicate submissions while loading.
/// - Discards stale async responses when session generation changes or on disposal.
/// - Clears sensitive draft state on session invalidation or authorization denial.
/// - Sanitizes user-facing error messages to avoid internal information disclosure.
/// - Does not grant onboarding completion or navigate directly to Social Home.
class SocialProfileViewModel extends ChangeNotifier {
  final SocialProfileRepository repository;

  SocialProfileDraft _draft;
  SocialProfileStatus _status = SocialProfileStatus.initial;
  String? _errorMessage;
  int _sessionGeneration = 0;
  bool _isSubmitting = false;
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
  bool get isLoading => _isSubmitting || _status == SocialProfileStatus.loading;

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
    if (!isLoading &&
        (_status == SocialProfileStatus.conflict ||
            _status == SocialProfileStatus.error)) {
      _status = SocialProfileStatus.initial;
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// Updates the draft bio and resets transient error state.
  void updateBio(String? value) {
    if (_disposed) return;
    _draft = _draft.copyWith(bio: value);
    if (!isLoading && _status == SocialProfileStatus.error) {
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

    // Independent in-flight submission guard
    if (_isSubmitting) {
      return false;
    }

    // Client-side validation check
    if (!_draft.isValid) {
      _status = SocialProfileStatus.error;
      _errorMessage = _draft.displayNameError ?? _draft.bioError ?? 'Invalid input.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _status = SocialProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final currentGen = ++_sessionGeneration;
    final submittedDraft = _draft;

    try {
      final result = await repository.saveProfileDraft(submittedDraft);

      // Check if disposed or superseded by a newer session/action
      if (_disposed || currentGen != _sessionGeneration) {
        return false;
      }

      switch (result) {
        case SocialProfileSuccess(:final draft):
          // Preserve local draft edits if user continued typing
          if (_draft.displayName == submittedDraft.displayName) {
            _draft = draft;
          }
          _status = SocialProfileStatus.success;
          _errorMessage = null;
          notifyListeners();
          return true;

        case SocialProfileError(:final failure):
          switch (failure.type) {
            case SocialProfileFailureType.displayNameUnavailable:
              _status = SocialProfileStatus.conflict;
              _errorMessage = _sanitizeErrorMessage(failure.message, 'The display name is already taken.');
            case SocialProfileFailureType.authorizationDenied:
              _status = SocialProfileStatus.denied;
              _draft = const SocialProfileDraft(); // Invalidate draft on auth denial
              _errorMessage = _sanitizeErrorMessage(failure.message, 'Adult eligibility confirmation is required to access Social.');
            case SocialProfileFailureType.sessionExpired:
              _status = SocialProfileStatus.denied;
              _draft = const SocialProfileDraft(); // Invalidate draft on session expiry
              _errorMessage = 'Session expired. Please log in again.';
            case SocialProfileFailureType.cancelled:
              _status = SocialProfileStatus.initial;
              _errorMessage = null;
            case SocialProfileFailureType.validationFailure:
            case SocialProfileFailureType.dependencyFailure:
            case SocialProfileFailureType.unknown:
              _status = SocialProfileStatus.error;
              _errorMessage = _sanitizeErrorMessage(failure.message, 'Social service temporarily unavailable.');
          }
          notifyListeners();
          return false;
      }
    } catch (_) {
      if (_disposed || currentGen != _sessionGeneration) {
        return false;
      }
      _status = SocialProfileStatus.error;
      _errorMessage = 'An unexpected error occurred while saving profile.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
    }
  }

  static String _sanitizeErrorMessage(String raw, String fallback) {
    if (raw.isEmpty ||
        raw.contains('Exception') ||
        raw.contains('Sql') ||
        raw.contains('Socket') ||
        raw.contains('at ')) {
      return fallback;
    }
    return raw;
  }

  /// Clears sensitive profile draft data when session or auth context is invalidated.
  void invalidateSession() {
    if (_disposed) return;
    _sessionGeneration++;
    _draft = const SocialProfileDraft();
    _status = SocialProfileStatus.initial;
    _errorMessage = null;
    _isSubmitting = false;
    notifyListeners();
  }

  /// Resets status to initial state without altering draft form inputs.
  /// Cannot clear status while an in-flight submission is active.
  void resetStatus() {
    if (_disposed || _isSubmitting) return;
    _status = SocialProfileStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionGeneration++;
    _isSubmitting = false;
    super.dispose();
  }
}
