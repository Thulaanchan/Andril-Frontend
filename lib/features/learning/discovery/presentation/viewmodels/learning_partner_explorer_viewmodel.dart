import 'package:flutter/foundation.dart';

import '../../../../../core/security/session/session_controller.dart';
import '../../domain/entities/learning_partner_candidate.dart';
import '../../domain/entities/learning_partner_filters.dart';
import '../../domain/entities/learning_partner_sort.dart';
import '../../domain/repositories/i_learning_discovery_repository.dart';

/// Presentation status for Learning Partner Explorer (Screen Q13).
enum LearningPartnerExplorerStatus {
  /// Uninitialized or awaiting authorization inspection.
  initial,

  /// Asynchronously retrieving candidates or applying filters.
  loading,

  /// Candidates are loaded and available for user review.
  ready,

  /// Search or filters yielded zero matching candidates.
  empty,

  /// Backend discovery service is dormant or currently unavailable.
  unavailableService,

  /// Caller is unauthenticated or has not activated their Learning profile.
  accessDenied,

  /// Recoverable operational or network failure.
  error,
}

/// Presentation ViewModel for Learning Partner Explorer (CF-04, BRD v2.4-R1, p. 7).
///
/// Follows strict security, architecture, and privacy rules:
/// - Enforces authenticated and activated Learning profile scope (fail-closed).
/// - Distinguishes account IDs from module-profile IDs. Never exposes account IDs.
/// - Excludes hidden, blocked, inactive, and unauthorized profiles.
/// - Prevents cross-module discovery; strictly validates `candidate.module == 'learning'`.
/// - Clears private candidate data on session revocation, logout, and identity switches.
/// - Discards stale asynchronous responses via epoch generation checks.
/// - Never automatically connects users or activates chat permissions.
class LearningPartnerExplorerViewModel extends ChangeNotifier {
  final ILearningDiscoveryRepository repository;
  final SessionController? sessionController;
  final bool isLearningActivated;
  final Set<String> _blockedProfileIds;

  VoidCallback? _unregisterSessionClearer;

  LearningPartnerExplorerStatus _status = LearningPartnerExplorerStatus.initial;
  List<LearningPartnerCandidate> _allCandidates = const [];
  List<LearningPartnerCandidate> _filteredCandidates = const [];
  LearningPartnerFilters _filters = LearningPartnerFilters();
  String? _errorMessage;
  LearningPartnerCandidate? _selectedCandidateForProfile;

  int _requestEpoch = 0;
  bool _disposed = false;

  /// Notice displayed when running under disconnected / pending backend contract.
  static const String disconnectedNotice =
      'Remote discovery backend contract pending in OpenAPI v1. Operating in local presentation mode.';

  LearningPartnerExplorerViewModel({
    required this.repository,
    this.sessionController,
    this.isLearningActivated = false,
    Iterable<String>? blockedProfileIds,
    List<LearningPartnerCandidate>? initialCandidates,
  }) : _blockedProfileIds = blockedProfileIds == null
            ? const <String>{}
            : Set<String>.of(blockedProfileIds) {
    if (initialCandidates != null) {
      _allCandidates = _sanitizeCandidates(initialCandidates);
    }
    final session = sessionController;
    if (session != null) {
      _unregisterSessionClearer =
          session.registerPrivateStateClearer(_onSessionCleared);
      session.addListener(_onSessionStateChanged);
    }
  }

  LearningPartnerExplorerStatus get status => _status;
  List<LearningPartnerCandidate> get candidates => _filteredCandidates;
  LearningPartnerFilters get filters => _filters;
  String? get errorMessage => _errorMessage;
  LearningPartnerCandidate? get selectedCandidateForProfile =>
      _selectedCandidateForProfile;

  bool get isLoading => _status == LearningPartnerExplorerStatus.loading;
  bool get isAccessDenied =>
      _status == LearningPartnerExplorerStatus.accessDenied;
  bool get isServiceUnavailable =>
      _status == LearningPartnerExplorerStatus.unavailableService;
  bool get isReady => _status == LearningPartnerExplorerStatus.ready;
  bool get isEmpty => _status == LearningPartnerExplorerStatus.empty;

  int get totalCount => _allCandidates.length;
  int get filteredCount => _filteredCandidates.length;

  /// Evaluates authoritative session and module activation status.
  bool get isAuthorized {
    if (_disposed) return false;
    final session = sessionController;
    if (session == null) return false;
    if (session.phase != SessionPhase.signedIn) return false;
    return isLearningActivated;
  }

  /// Initializes discovery with authoritative security and session verification.
  Future<void> initialize({bool force = false}) async {
    if (_disposed) return;
    if (!force && _status == LearningPartnerExplorerStatus.loading) return;

    if (!isAuthorized) {
      _status = LearningPartnerExplorerStatus.accessDenied;
      _errorMessage =
          'Authentication and activated Learning profile required to explore learning partners.';
      _allCandidates = const [];
      _filteredCandidates = const [];
      notifyListeners();
      return;
    }

    final epoch = ++_requestEpoch;
    _status = LearningPartnerExplorerStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // If pre-supplied initial candidates are already provided (e.g. In tests or seeded state),
    // apply filtering directly without remote repository call.
    if (_allCandidates.isNotEmpty) {
      _applyFiltersAndNotify();
      return;
    }

    final result = await repository.getCandidates(filters: _filters);

    if (_disposed || epoch != _requestEpoch || !isAuthorized) return;

    if (result.isSuccess) {
      final incoming = result.data ?? const <LearningPartnerCandidate>[];
      _allCandidates = _sanitizeCandidates(incoming);
      _applyFiltersAndNotify();
    } else {
      _errorMessage = result.errorMessage;
      if (result.failureType == LearningDiscoveryFailureType.unauthorized) {
        _status = LearningPartnerExplorerStatus.accessDenied;
      } else if (result.failureType ==
          LearningDiscoveryFailureType.serviceUnavailable) {
        _status = LearningPartnerExplorerStatus.unavailableService;
      } else {
        _status = LearningPartnerExplorerStatus.error;
      }
      _filteredCandidates = const [];
      notifyListeners();
    }
  }

  /// Sets candidate pool explicitly (e.g. for testing or disconnected seed).
  void setCandidates(List<LearningPartnerCandidate> candidates) {
    if (_disposed) return;
    _allCandidates = _sanitizeCandidates(candidates);
    if (!isAuthorized) {
      _status = LearningPartnerExplorerStatus.accessDenied;
      _filteredCandidates = const [];
    } else {
      _applyFiltersAndNotify();
    }
    notifyListeners();
  }

  /// Updates search text query.
  void setSearchQuery(String query) {
    if (_disposed) return;
    _filters = _filters.copyWith(searchQuery: query);
    _applyFiltersAndNotify();
  }

  /// Applies complete new filter set.
  void applyFilters(LearningPartnerFilters newFilters) {
    if (_disposed) return;
    _filters = newFilters;
    _applyFiltersAndNotify();
  }

  /// Removes an individual categorical filter item.
  void removeFilter({required String category, required String value}) {
    if (_disposed) return;
    _filters = _filters.removeFilter(category: category, value: value);
    _applyFiltersAndNotify();
  }

  /// Resets all categorical filters and search text.
  void resetFilters() {
    if (_disposed) return;
    _filters = _filters.clear();
    _applyFiltersAndNotify();
  }

  /// Changes the sorting option.
  void setSortOption(LearningPartnerSort sort) {
    if (_disposed) return;
    _filters = _filters.copyWith(sortOption: sort);
    _applyFiltersAndNotify();
  }

  /// Selects a candidate to show in the View Profile modal.
  void selectCandidateForProfile(LearningPartnerCandidate? candidate) {
    if (_disposed) return;
    _selectedCandidateForProfile = candidate;
    notifyListeners();
  }

  /// Sanitizes candidates: enforces module 'learning', active status, and excludes blocked IDs.
  List<LearningPartnerCandidate> _sanitizeCandidates(
      Iterable<LearningPartnerCandidate> candidates) {
    return List.unmodifiable(
      candidates.where((c) {
        // Enforce module boundary
        if (c.module != LearningPartnerCandidate.moduleScope) return false;
        // Enforce active / server-side eligibility
        if (!c.isActive) return false;
        // Exclude blocked profiles
        if (_blockedProfileIds.contains(c.id)) return false;
        return true;
      }),
    );
  }

  /// Filters and sorts candidates against active filters.
  void _applyFiltersAndNotify() {
    if (!isAuthorized) {
      _status = LearningPartnerExplorerStatus.accessDenied;
      _filteredCandidates = const [];
      notifyListeners();
      return;
    }

    final query = _filters.searchQuery.trim().toLowerCase();
    final hasQuery = query.isNotEmpty;

    final result = _allCandidates.where((candidate) {
      // 1. Text Search matching across displayName, skills, and goals
      if (hasQuery) {
        final nameMatch = candidate.displayName.toLowerCase().contains(query);
        final shareMatch =
            candidate.skillsToShare.any((s) => s.toLowerCase().contains(query));
        final learnMatch =
            candidate.skillsToLearn.any((s) => s.toLowerCase().contains(query));
        final goalMatch =
            candidate.learningGoals.any((g) => g.toLowerCase().contains(query));

        if (!nameMatch && !shareMatch && !learnMatch && !goalMatch) {
          return false;
        }
      }

      // 2. Skill Filter (matches skillsToShare or skillsToLearn)
      if (_filters.selectedSkills.isNotEmpty) {
        final hasSkill = _filters.selectedSkills.any((s) =>
            candidate.skillsToShare.contains(s) ||
            candidate.skillsToLearn.contains(s));
        if (!hasSkill) return false;
      }

      // 3. Goal Filter
      if (_filters.selectedGoals.isNotEmpty) {
        final hasGoal = _filters.selectedGoals
            .any((g) => candidate.learningGoals.contains(g));
        if (!hasGoal) return false;
      }

      // 4. Proficiency Filter
      if (_filters.selectedProficiencies.isNotEmpty) {
        if (!_filters.selectedProficiencies
            .contains(candidate.proficiencyLevel)) {
          return false;
        }
      }

      // 5. Language Filter
      if (_filters.selectedLanguages.isNotEmpty) {
        final hasLang = _filters.selectedLanguages
            .any((lang) => candidate.languages.contains(lang));
        if (!hasLang) return false;
      }

      // 6. Availability Filter
      if (_filters.selectedAvailabilities.isNotEmpty) {
        if (candidate.availability == null ||
            !_filters.selectedAvailabilities.contains(candidate.availability)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply Sorting
    switch (_filters.sortOption) {
      case LearningPartnerSort.recommended:
        // Preserves candidate source order
        break;
      case LearningPartnerSort.nameAsc:
        result.sort((a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
        break;
      case LearningPartnerSort.nameDesc:
        result.sort((a, b) =>
            b.displayName.toLowerCase().compareTo(a.displayName.toLowerCase()));
        break;
      case LearningPartnerSort.skillsCount:
        result.sort(
            (a, b) => b.skillsToShare.length.compareTo(a.skillsToShare.length));
        break;
    }

    _filteredCandidates = List.unmodifiable(result);
    _status = _filteredCandidates.isEmpty
        ? LearningPartnerExplorerStatus.empty
        : LearningPartnerExplorerStatus.ready;
    notifyListeners();
  }

  void _onSessionCleared() {
    _requestEpoch++;
    _allCandidates = const [];
    _filteredCandidates = const [];
    _filters = LearningPartnerFilters();
    _selectedCandidateForProfile = null;
    _status = LearningPartnerExplorerStatus.accessDenied;
    _errorMessage = 'Session signed out or revoked.';
    notifyListeners();
  }

  void _onSessionStateChanged() {
    if (!isAuthorized) {
      _onSessionCleared();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _unregisterSessionClearer?.call();
    sessionController?.removeListener(_onSessionStateChanged);
    super.dispose();
  }
}
