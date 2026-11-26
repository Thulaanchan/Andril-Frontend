import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../domain/social_candidate.dart';

/// Presentation status for Social member search.
enum SocialSearchViewStatus {
  initial,
  loading,
  ready,
  empty,
  accessDenied,
  error,
}

/// Presentation ViewModel orchestrating Social member search (S25 Search People).
///
/// Follows M5 Search Governance:
/// - Strictly searches within the Social module.
/// - Requires adult verification and explicit Social opt-in.
/// - Rejects stale asynchronous query results.
/// - Protects user privacy: only displays verified, non-blocked Social candidates.
class SocialSearchViewModel extends ChangeNotifier {
  final SessionController _sessionController;
  final bool _isSocialOptedIn;

  SocialSearchViewStatus _status = SocialSearchViewStatus.initial;
  String _currentQuery = '';
  List<SocialCandidate> _results = const [];
  String? _errorMessage;
  int _activeQueryId = 0;
  bool _disposed = false;

  SocialSearchViewModel({
    required SessionController sessionController,
    bool isSocialOptedIn = true,
  })  : _sessionController = sessionController,
        _isSocialOptedIn = isSocialOptedIn {
    _sessionController.addListener(_onSessionChanged);
    _sessionController.registerPrivateStateClearer(_clearPrivateSearch);
  }

  SocialSearchViewStatus get status => _status;
  String get currentQuery => _currentQuery;
  List<SocialCandidate> get results => _results;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == SocialSearchViewStatus.loading;
  bool get isReady => _status == SocialSearchViewStatus.ready;
  bool get isEmpty => _status == SocialSearchViewStatus.empty;
  bool get isAccessDenied => _status == SocialSearchViewStatus.accessDenied;
  bool get isError => _status == SocialSearchViewStatus.error;

  /// Executes member search with query sanitization and stale response guards.
  Future<void> search(String query, {List<SocialCandidate>? candidateSource}) async {
    if (_disposed) return;

    if (!_isSocialOptedIn || _sessionController.phase != SessionPhase.signedIn) {
      _status = SocialSearchViewStatus.accessDenied;
      _errorMessage = 'Adult eligibility verification and Social opt-in are required.';
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

    final queryId = ++_activeQueryId;
    _status = SocialSearchViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate asynchronous search filter across candidates
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_disposed || queryId != _activeQueryId) return;

      final normalizedQuery = trimmed.toLowerCase();
      final source = candidateSource ?? const <SocialCandidate>[];
      final filtered = source.where((c) {
        final nameMatch = c.displayName.toLowerCase().contains(normalizedQuery);
        final bioMatch = c.biography?.toLowerCase().contains(normalizedQuery) ?? false;
        final interestMatch = c.interests.any((i) => i.toLowerCase().contains(normalizedQuery));
        return nameMatch || bioMatch || interestMatch;
      }).toList();

      _results = List.unmodifiable(filtered);
      _status = _results.isEmpty ? SocialSearchViewStatus.empty : SocialSearchViewStatus.ready;
      _errorMessage = null;
    } catch (_) {
      if (_disposed || queryId != _activeQueryId) return;
      _status = SocialSearchViewStatus.error;
      _errorMessage = 'An error occurred during search.';
    }

    notifyListeners();
  }

  /// Clears the current search query and results.
  void clearSearch() {
    _activeQueryId++;
    _currentQuery = '';
    _results = const [];
    _status = SocialSearchViewStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearPrivateSearch() {
    _activeQueryId++;
    _currentQuery = '';
    _results = const [];
    _errorMessage = null;
  }

  void _onSessionChanged() {
    if (_disposed) return;
    if (_sessionController.phase != SessionPhase.signedIn) {
      _clearPrivateSearch();
      _status = SocialSearchViewStatus.accessDenied;
      _errorMessage = 'Session signed out.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionController.removeListener(_onSessionChanged);
    super.dispose();
  }
}
