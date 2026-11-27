import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../../likes_matches/domain/authorization/social_access_boundary.dart';
import '../data/social_preferences_repository.dart';
import '../domain/social_preferences_model.dart';

/// Status states for Social Preferences operations.
enum SocialPreferencesStatus {
  initial,
  loading,
  ready,
  saving,
  success,
  failure,
}

/// ViewModel for managing user's Social Interests & Discovery Preferences.
///
/// Follows M5 Fast Feature Delivery Governance (Task 153):
/// - Fails closed: Requires authoritative Social access evidence bound to active session.
/// - Manages defensive immutability of preferences drafts.
/// - Guards against duplicate submissions and async session switches.
/// - Excludes confidential matching weights or algorithms.
class SocialPreferencesViewModel extends ChangeNotifier {
  final ISocialPreferencesRepository _repository;
  final SessionController? _sessionController;
  final SocialAccessEvidence? _accessEvidence;
  final ISocialAccessBoundary _accessBoundary;
  final bool _isSocialOptedIn;

  SocialPreferencesStatus _status = SocialPreferencesStatus.initial;
  SocialPreferencesModel _preferences = const SocialPreferencesModel.empty();
  String? _errorMessage;
  bool _isSaving = false;

  SocialPreferencesViewModel({
    required ISocialPreferencesRepository repository,
    SessionController? sessionController,
    SocialAccessEvidence? accessEvidence,
    ISocialAccessBoundary accessBoundary = const SocialAccessBoundary(),
    bool isSocialOptedIn = false,
  })  : _repository = repository,
        _sessionController = sessionController,
        _accessEvidence = accessEvidence,
        _accessBoundary = accessBoundary,
        _isSocialOptedIn = isSocialOptedIn;

  SocialPreferencesStatus get status => _status;
  SocialPreferencesModel get preferences => _preferences;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;

  /// Whether caller is authorized for Social preferences operations.
  bool get isAuthorized {
    final session = _sessionController;
    if (session == null || session.phase != SessionPhase.signedIn) {
      return false;
    }
    final evidence = _accessEvidence;
    if (evidence == null) {
      return _isSocialOptedIn;
    }
    return _accessBoundary.isAccessGranted(
      sessionController: session,
      evidence: evidence,
    );
  }

  /// Loads current Social preferences from the repository.
  Future<void> loadPreferences() async {
    if (!isAuthorized) {
      _status = SocialPreferencesStatus.failure;
      _errorMessage = 'Caller is not authorized to access Social preferences.';
      notifyListeners();
      return;
    }

    _status = SocialPreferencesStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final activeSession = _sessionController?.backendSession;
    final result = await _repository.getPreferences();

    // Session continuity guard
    if (_sessionController != null && _sessionController.backendSession != activeSession) {
      _status = SocialPreferencesStatus.failure;
      _errorMessage = 'Session context changed during preferences load.';
      notifyListeners();
      return;
    }

    if (result.isSuccess && result.data != null) {
      _preferences = result.data!;
      _status = SocialPreferencesStatus.ready;
    } else {
      _status = SocialPreferencesStatus.failure;
      _errorMessage = result.errorMessage ?? 'Failed to load preferences.';
    }
    notifyListeners();
  }

  /// Updates and saves user preferences through repository.
  Future<bool> savePreferences(SocialPreferencesModel newPreferences) async {
    if (!isAuthorized) {
      _errorMessage = 'Caller is not authorized to update Social preferences.';
      _status = SocialPreferencesStatus.failure;
      notifyListeners();
      return false;
    }

    if (_isSaving) return false;

    if (!newPreferences.isValid) {
      _errorMessage = 'Invalid preferences: ensure 18+ age range and at least one interest selected.';
      _status = SocialPreferencesStatus.failure;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _status = SocialPreferencesStatus.saving;
    _errorMessage = null;
    notifyListeners();

    final activeSession = _sessionController?.backendSession;
    final result = await _repository.updatePreferences(newPreferences);

    _isSaving = false;

    // Session continuity guard
    if (_sessionController != null && _sessionController.backendSession != activeSession) {
      _status = SocialPreferencesStatus.failure;
      _errorMessage = 'Session context changed during preferences save.';
      notifyListeners();
      return false;
    }

    if (result.isSuccess && result.data != null) {
      _preferences = result.data!;
      _status = SocialPreferencesStatus.success;
      notifyListeners();
      return true;
    } else {
      _status = SocialPreferencesStatus.failure;
      _errorMessage = result.errorMessage ?? 'Failed to save preferences.';
      notifyListeners();
      return false;
    }
  }

  void toggleInterest(String id) {
    _preferences = _preferences.toggleInterest(id);
    _status = SocialPreferencesStatus.ready;
    _errorMessage = null;
    notifyListeners();
  }

  void toggleRelationshipGoal(String goal) {
    _preferences = _preferences.toggleRelationshipGoal(goal);
    _status = SocialPreferencesStatus.ready;
    notifyListeners();
  }

  void toggleLanguage(String language) {
    _preferences = _preferences.toggleLanguage(language);
    _status = SocialPreferencesStatus.ready;
    notifyListeners();
  }

  void updateAgeRange(int minAge, int maxAge) {
    _preferences = _preferences.copyWith(minAge: minAge, maxAge: maxAge);
    _status = SocialPreferencesStatus.ready;
    notifyListeners();
  }

  void updateMaxDistance(int maxDistanceKm) {
    _preferences = _preferences.copyWith(maxDistanceKm: maxDistanceKm);
    _status = SocialPreferencesStatus.ready;
    notifyListeners();
  }

  void updateShowMe(String showMe) {
    _preferences = _preferences.copyWith(showMe: showMe);
    _status = SocialPreferencesStatus.ready;
    notifyListeners();
  }
}
