import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../../likes_matches/domain/authorization/social_access_boundary.dart';
import 'social_profile_draft.dart';
import 'social_profile_management_repository.dart';
import 'social_profile_repository.dart';

/// Presentation state machine status for Social Profile Management.
enum SocialProfileManagementStatus {
  initial,
  loading,
  ready,
  saving,
  accessDenied,
  error,
}

/// ViewModel orchestrating reading, editing, and saving the authenticated user's private Social profile.
///
/// Follows M5-FE Profile Management Governance:
/// - Reuses validated [SocialProfileDraft] constraints and sanitization.
/// - Guarded against concurrent duplicate saves and stale asynchronous responses.
/// - Tracks unsaved edits and discards changes on cancel.
/// - Clears private profile state on session sign-out or account invalidation.
/// - Does not modify or bypass onboarding flags.
class SocialProfileManagementViewModel extends ChangeNotifier {
  final ISocialProfileManagementRepository _repository;
  final SessionController _sessionController;
  final bool _isSocialOptedIn;
  final bool _isOnboarding;
  final ISocialAccessBoundary _accessBoundary;
  final SocialAccessEvidence? _accessEvidence;
  String? _boundSubject;

  SocialProfileManagementStatus _status = SocialProfileManagementStatus.initial;
  SocialProfileDraft _serverDraft = const SocialProfileDraft();
  SocialProfileDraft _editingDraft = const SocialProfileDraft();
  String? _errorMessage;
  int _activeOperationId = 0;
  bool _isSaving = false;
  bool _disposed = false;

  SocialProfileManagementViewModel({
    required ISocialProfileManagementRepository repository,
    required SessionController sessionController,
    bool isSocialOptedIn = false,
    bool isOnboarding = false,
    ISocialAccessBoundary accessBoundary = const SocialAccessBoundary(),
    SocialAccessEvidence? accessEvidence,
  })  : _repository = repository,
        _sessionController = sessionController,
        _isSocialOptedIn = isSocialOptedIn,
        _isOnboarding = isOnboarding,
        _accessBoundary = accessBoundary,
        _accessEvidence = accessEvidence {
    _boundSubject = _resolveSubject();
    _sessionController.addListener(_onSessionChanged);
    _sessionController.registerPrivateStateClearer(_clearPrivateProfile);
  }

  SocialProfileManagementStatus get status => _status;
  SocialProfileDraft get profile => _serverDraft;
  SocialProfileDraft get draft => _editingDraft;
  String? get errorMessage => _errorMessage;
  bool get isSocialOptedIn => _isSocialOptedIn;
  bool get isOnboarding => _isOnboarding;
  ISocialAccessBoundary get accessBoundary => _accessBoundary;
  SocialAccessEvidence? get accessEvidence => _accessEvidence;

  bool get isLoading => _status == SocialProfileManagementStatus.loading;
  bool get isSaving => _isSaving || _status == SocialProfileManagementStatus.saving;
  bool get isReady => _status == SocialProfileManagementStatus.ready;
  bool get isAccessDenied => _status == SocialProfileManagementStatus.accessDenied;
  bool get isError => _status == SocialProfileManagementStatus.error;

  /// Evaluates authoritative access to private profile management.
  bool get isAuthorized {
    if (_disposed) return false;
    if (_sessionController.phase != SessionPhase.signedIn) return false;

    final currentSubject = _resolveSubject();
    if (_boundSubject != null && currentSubject != null && currentSubject != _boundSubject) {
      return false;
    }

    if (_isOnboarding) return true;

    if (_accessEvidence != null) {
      return _accessBoundary.isAccessGranted(
        sessionController: _sessionController,
        evidence: _accessEvidence,
      );
    }

    return _isSocialOptedIn;
  }

  /// Whether the user has modified the profile draft compared to the server state.
  bool get hasUnsavedChanges =>
      _editingDraft.displayName != _serverDraft.displayName ||
      _editingDraft.bio != _serverDraft.bio ||
      _editingDraft.profilePhotoPath != _serverDraft.profilePhotoPath;

  /// Whether the draft is valid and ready to be saved.
  bool get canSave => _editingDraft.isValid && hasUnsavedChanges && !isSaving;

  /// Loads the authoritative profile from the server.
  Future<void> loadProfile({bool refresh = false}) async {
    if (_disposed) return;

    final currentSubject = _resolveSubject();
    if (_boundSubject != null && currentSubject != null && currentSubject != _boundSubject) {
      _clearPrivateProfile();
      _boundSubject = currentSubject;
      _status = SocialProfileManagementStatus.accessDenied;
      _errorMessage = 'Session subject changed.';
      notifyListeners();
      return;
    }
    if (_boundSubject == null && currentSubject != null) {
      _boundSubject = currentSubject;
    }

    if (!isAuthorized) {
      _clearPrivateProfile();
      _status = SocialProfileManagementStatus.accessDenied;
      _errorMessage = 'Adult eligibility verification and Social opt-in are required.';
      notifyListeners();
      return;
    }

    if (_status == SocialProfileManagementStatus.ready && !refresh) {
      return;
    }

    final opId = ++_activeOperationId;
    final operationSubject = _resolveSubject();
    _status = SocialProfileManagementStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getProfile();
      if (_disposed || opId != _activeOperationId) return;

      final postSubject = _resolveSubject();
      if ((operationSubject != null && postSubject != operationSubject) ||
          (_boundSubject != null && postSubject != _boundSubject) ||
          _sessionController.phase != SessionPhase.signedIn ||
          !isAuthorized) {
        _clearPrivateProfile();
        _status = SocialProfileManagementStatus.accessDenied;
        _errorMessage = 'Session signed out, switched, or authorization revoked.';
        notifyListeners();
        return;
      }

      if (result is SocialProfileSuccess) {
        _serverDraft = result.draft;
        _editingDraft = result.draft;
        _status = SocialProfileManagementStatus.ready;
        _errorMessage = null;
      } else if (result is SocialProfileError) {
        _handleFailure(result.failure);
      }
    } catch (_) {
      if (_disposed || opId != _activeOperationId) return;
      _status = SocialProfileManagementStatus.error;
      _errorMessage = 'An unexpected error occurred while loading profile.';
    }

    if (!_disposed && opId == _activeOperationId) {
      notifyListeners();
    }
  }

  /// Updates the editing draft display name.
  void updateDisplayName(String value) {
    if (_disposed) return;
    _editingDraft = _editingDraft.copyWith(displayName: value);
    _clearTransientErrors();
    notifyListeners();
  }

  /// Updates the editing draft bio.
  void updateBio(String? value) {
    if (_disposed) return;
    _editingDraft = _editingDraft.copyWith(bio: value);
    _clearTransientErrors();
    notifyListeners();
  }

  /// Updates the editing draft local profile photo.
  void updateProfilePhoto(String? path) {
    if (_disposed) return;
    _editingDraft = _editingDraft.copyWith(profilePhotoPath: path);
    _clearTransientErrors();
    notifyListeners();
  }

  /// Resets editing draft to the last known server state, discarding unsaved edits.
  void discardEdits() {
    _editingDraft = _serverDraft;
    _clearTransientErrors();
    notifyListeners();
  }

  /// Saves the current editing draft to the server.
  Future<bool> saveProfile() async {
    if (_disposed || _isSaving || !canSave) return false;

    final currentSubject = _resolveSubject();
    if (_boundSubject != null && currentSubject != null && currentSubject != _boundSubject) {
      _clearPrivateProfile();
      _boundSubject = currentSubject;
      _status = SocialProfileManagementStatus.accessDenied;
      _errorMessage = 'Session subject changed.';
      notifyListeners();
      return false;
    }
    if (_boundSubject == null && currentSubject != null) {
      _boundSubject = currentSubject;
    }

    if (!isAuthorized) {
      _status = SocialProfileManagementStatus.accessDenied;
      _errorMessage = 'Adult eligibility verification and Social opt-in are required.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    final opId = ++_activeOperationId;
    final operationSubject = _resolveSubject();
    _status = SocialProfileManagementStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.updateProfile(_editingDraft);
      if (_disposed || opId != _activeOperationId) return false;

      final postSubject = _resolveSubject();
      if ((operationSubject != null && postSubject != operationSubject) ||
          (_boundSubject != null && postSubject != _boundSubject) ||
          _sessionController.phase != SessionPhase.signedIn ||
          !isAuthorized) {
        _isSaving = false;
        _clearPrivateProfile();
        _status = SocialProfileManagementStatus.accessDenied;
        _errorMessage = 'Session signed out, switched, or authorization revoked.';
        notifyListeners();
        return false;
      }

      _isSaving = false;
      if (result is SocialProfileSuccess) {
        _serverDraft = result.draft;
        _editingDraft = result.draft;
        _status = SocialProfileManagementStatus.ready;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else if (result is SocialProfileError) {
        _handleFailure(result.failure);
        notifyListeners();
        return false;
      }
    } catch (_) {
      if (_disposed || opId != _activeOperationId) return false;
      _isSaving = false;
      _status = SocialProfileManagementStatus.error;
      _errorMessage = 'Failed to save profile.';
      notifyListeners();
      return false;
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  void _clearTransientErrors() {
    if (_status == SocialProfileManagementStatus.error) {
      _status = SocialProfileManagementStatus.ready;
      _errorMessage = null;
    }
  }

  void _clearPrivateProfile() {
    _serverDraft = const SocialProfileDraft();
    _editingDraft = const SocialProfileDraft();
    _errorMessage = null;
    _isSaving = false;
  }

  void _onSessionChanged() {
    if (_disposed) return;
    final currentSubject = _resolveSubject();

    if (_boundSubject != null && currentSubject != null && currentSubject != _boundSubject) {
      _boundSubject = currentSubject;
      _clearPrivateProfile();
      _status = SocialProfileManagementStatus.accessDenied;
      _errorMessage = 'Session signed out or account switched.';
      notifyListeners();
      return;
    }
    if (_boundSubject == null && currentSubject != null) {
      _boundSubject = currentSubject;
    }

    if (_sessionController.phase != SessionPhase.signedIn) {
      _clearPrivateProfile();
      _status = SocialProfileManagementStatus.accessDenied;
      _errorMessage = 'Session signed out or account switched.';
      notifyListeners();
    }
  }

  String? _resolveSubject() {
    try {
      return _sessionController.subject;
    } catch (_) {
      return null;
    }
  }

  void _handleFailure(SocialProfileFailure failure) {
    switch (failure.type) {
      case SocialProfileFailureType.authorizationDenied:
      case SocialProfileFailureType.sessionExpired:
        _status = SocialProfileManagementStatus.accessDenied;
        _errorMessage = failure.message;
        break;
      case SocialProfileFailureType.displayNameUnavailable:
      case SocialProfileFailureType.validationFailure:
      case SocialProfileFailureType.dependencyFailure:
      case SocialProfileFailureType.cancelled:
      case SocialProfileFailureType.unknown:
        _status = SocialProfileManagementStatus.error;
        _errorMessage = failure.message;
        break;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionController.removeListener(_onSessionChanged);
    super.dispose();
  }
}
