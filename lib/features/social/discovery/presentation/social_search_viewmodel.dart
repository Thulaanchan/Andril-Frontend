import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../../likes_matches/domain/authorization/social_access_boundary.dart';
import '../domain/social_candidate.dart';

/// Presentation status for Social member search.
enum SocialSearchViewStatus {
  initial,
  loading,
  ready,
  empty,
  accessDenied,
  serviceUnavailable,
  error,
}

/// Presentation ViewModel orchestrating Social member search (S25 Search People).
///
/// Follows Task 111 Fast Feature Delivery Governance:
/// - Strictly searches within the Social module.
/// - Requires current authoritative Social eligibility evidence (SocialAccessBoundary).
/// - Rejects missing, unauthenticated, underage, or revoked access.
/// - Rejects candidates from other sessions / accounts (session isolation).
/// - If no approved authorized candidate source exists, returns serviceUnavailable instead of simulating production search.
/// - Rejects stale asynchronous query results.
/// - Clears private search state on session invalidation or account switch.
/// - Defensively immutable results without exposing private identifiers in diagnostics.
class SocialSearchViewModel extends ChangeNotifier {
  final SessionController _sessionController;
  final ISocialAccessBoundary _accessBoundary;
  final SocialAccessEvidence? _accessEvidence;
  final bool _isSocialOptedIn;

  SocialSearchViewStatus _status = SocialSearchViewStatus.initial;
  String _currentQuery = '';
  List<SocialCandidate> _results = const [];
  String? _errorMessage;
  int _activeQueryId = 0;
  bool _disposed = false;
  String? _boundSubject;

  SocialSearchViewModel({
    required SessionController sessionController,
    ISocialAccessBoundary accessBoundary = const SocialAccessBoundary(),
    SocialAccessEvidence? accessEvidence,
    bool isSocialOptedIn = false,
  })  : _sessionController = sessionController,
        _accessBoundary = accessBoundary,
        _accessEvidence = accessEvidence,
        _isSocialOptedIn = isSocialOptedIn {
    try {
      _boundSubject = _sessionController.subject;
    } catch (_) {
      _boundSubject = null;
    }
    _sessionController.addListener(_onSessionChanged);
    _sessionController.registerPrivateStateClearer(_clearPrivateSearch);
  }

  SocialSearchViewStatus get status => _status;
  String get currentQuery => _currentQuery;
  List<SocialCandidate> get results => _results;
  String? get errorMessage => _errorMessage;
  bool get isSocialOptedIn => _isSocialOptedIn;

  bool get isLoading => _status == SocialSearchViewStatus.loading;
  bool get isReady => _status == SocialSearchViewStatus.ready;
  bool get isEmpty => _status == SocialSearchViewStatus.empty;
  bool get isAccessDenied => _status == SocialSearchViewStatus.accessDenied;
  bool get isServiceUnavailable => _status == SocialSearchViewStatus.serviceUnavailable;
  bool get isError => _status == SocialSearchViewStatus.error;

  /// Evaluates current authoritative access to Social Search.
  bool get isAuthorized {
    if (_sessionController.phase != SessionPhase.signedIn) return false;
    if (_accessEvidence != null) {
      return _accessBoundary.isAccessGranted(
        sessionController: _sessionController,
        evidence: _accessEvidence,
      );
    }
    // Fail-closed if no authoritative evidence provided
    return false;
  }

  /// Executes member search with query sanitization, session validation, and stale response guards.
  Future<void> search(
    String query, {
    List<SocialCandidate>? candidateSource,
    String? sourceSessionSubject,
  }) async {
    if (_disposed) return;

    // Check account-switch guard
    final currentSubject = _resolveSubject();
    if (_boundSubject != null && currentSubject != _boundSubject) {
      _clearPrivateSearch();
      _boundSubject = currentSubject;
      _status = SocialSearchViewStatus.accessDenied;
      _errorMessage = 'Session subject changed.';
      notifyListeners();
      return;
    }

    // Authoritative access check
    if (!isAuthorized) {
      _clearPrivateSearch();
      _status = SocialSearchViewStatus.accessDenied;
      _errorMessage = 'Authoritative Social eligibility evidence and opt-in are required.';
      notifyListeners();
      return;
    }

    final trimmed = query.trim();
    _currentQuery = trimmed;

    if (trimmed.isEmpty) {
      _results = const [];
      _status = SocialSearchViewStatus.initial;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    // If no candidate source is provided, fail closed with serviceUnavailable
    // (no simulated production search endpoint)
    if (candidateSource == null) {
      _status = SocialSearchViewStatus.serviceUnavailable;
      _errorMessage = 'Social search service is currently unavailable.';
      _results = const [];
      notifyListeners();
      return;
    }

    // Verify candidate source ownership / session scope
    if (sourceSessionSubject != null && currentSubject != null && sourceSessionSubject != currentSubject) {
      _clearPrivateSearch();
      _status = SocialSearchViewStatus.accessDenied;
      _errorMessage = 'Cross-session candidate source is rejected.';
      notifyListeners();
      return;
    }

    final queryId = ++_activeQueryId;
    _status = SocialSearchViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future<void>.value();
      if (_disposed || queryId != _activeQueryId) return;

      final normalizedQuery = trimmed.toLowerCase();
      final filtered = candidateSource.where((c) {
        if (c.age < 18 || c.id.trim().isEmpty || c.displayName.trim().isEmpty) return false;
        final nameMatch = c.displayName.toLowerCase().contains(normalizedQuery);
        final bioMatch = c.biography?.toLowerCase().contains(normalizedQuery) ?? false;
        final interestMatch = c.interests.any((i) => i.toLowerCase().contains(normalizedQuery));
        return nameMatch || bioMatch || interestMatch;
      }).toList(growable: false);

      _results = List.unmodifiable(filtered);
      _status = _results.isEmpty ? SocialSearchViewStatus.empty : SocialSearchViewStatus.ready;
      _errorMessage = null;
    } catch (_) {
      if (_disposed || queryId != _activeQueryId) return;
      _status = SocialSearchViewStatus.error;
      _errorMessage = 'An error occurred during search.';
    }

    if (!_disposed && queryId == _activeQueryId) {
      notifyListeners();
    }
  }

  /// Clears the current search query and results.
  void clearSearch() {
    _activeQueryId++;
    _currentQuery = '';
    _results = const [];
    _status = SocialSearchViewStatus.initial;
    _errorMessage = null;
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _clearPrivateSearch() {
    _activeQueryId++;
    _currentQuery = '';
    _results = const [];
    _errorMessage = null;
  }

  String? _resolveSubject() {
    try {
      return _sessionController.subject;
    } catch (_) {
      return null;
    }
  }

  void _onSessionChanged() {
    if (_disposed) return;
    final currentSubject = _resolveSubject();
    if (_sessionController.phase != SessionPhase.signedIn ||
        (_boundSubject != null && currentSubject != _boundSubject)) {
      _clearPrivateSearch();
      _boundSubject = currentSubject;
      _status = SocialSearchViewStatus.accessDenied;
      _errorMessage = 'Session signed out or account switched.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionController.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  String toString() => 'SocialSearchViewModel(status: ${_status.name}, resultsCount: ${_results.length})';
}
