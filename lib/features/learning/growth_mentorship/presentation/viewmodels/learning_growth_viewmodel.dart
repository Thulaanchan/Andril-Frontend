import 'package:flutter/foundation.dart';

import '../../../../../core/security/session/session_controller.dart';
import '../../domain/entities/learning_growth_evidence.dart';
import '../../domain/repositories/i_learning_growth_repository.dart';

/// Presentation statuses for Learning Growth Dashboard (LRN-04).
enum LearningGrowthViewStatus {
  initial,
  loading,
  ready,
  empty,
  accessDenied,
  unavailableService,
  error,
}

/// Navigation tabs on the Private Learning Growth Dashboard (Q41_LUC-24).
enum LearningGrowthTab {
  /// Summary overview, recent evidence highlights, and privacy notices.
  overview,

  /// Comprehensive evidence records with verified vs self-reported provenance filtering.
  evidence,

  /// Tracked learning skills and evidence sufficiency status.
  skills,

  /// Objective learning insights and reflection history.
  insights,
}

/// Presentation ViewModel governing the Private My Growth Dashboard (LRN-04, GRW-01-05).
///
/// Follows strict ANDRIL M1 governance:
/// - Growth remains private by default (never exposed or shared across accounts).
/// - Never equates evidence to XP, skill mastery, or formal certification.
/// - Clearly distinguishes verified-source, self-reported, and insufficient-evidence states.
/// - Purges private growth state immediately upon session revocation.
/// - Guards against stale asynchronous responses via epoch generation checks.
/// - Prevents concurrent in-flight re-entrancy.
class LearningGrowthViewModel extends ChangeNotifier {
  final ILearningGrowthRepository repository;
  final SessionController? sessionController;
  final bool isLearningActivated;
  final String currentProfileId;
  final String currentDisplayName;

  VoidCallback? _unregisterSessionClearer;

  LearningGrowthViewStatus _status = LearningGrowthViewStatus.initial;
  LearningGrowthTab _activeTab = LearningGrowthTab.overview;
  LearningEvidenceKind? _kindFilter;
  String _searchQuery = '';

  List<LearningGrowthEvidence> _evidence = const [];
  List<LearningTrackedSkill> _skills = const [];
  LearningGrowthSummary _summary = const LearningGrowthSummary();

  String? _errorMessage;
  final Set<String> _activeOperations = <String>{};

  int _requestEpoch = 0;
  bool _disposed = false;

  /// Notice displayed when running in local presentation mode.
  static const String disconnectedNotice =
      LearningGrowthEvidence.disconnectedNotice;

  /// Notice explaining that topic-gap explanations and mentorship belong to Task 05-06.
  static const String mentorshipPendingNotice =
      'Topic-gap explanations and mentorship workflows are scheduled for Task 05-06.';

  LearningGrowthViewModel({
    required this.repository,
    this.sessionController,
    this.isLearningActivated = false,
    this.currentProfileId = 'current_learner_prof',
    this.currentDisplayName = 'Current Learner',
    List<LearningGrowthEvidence>? initialEvidence,
    List<LearningTrackedSkill>? initialSkills,
  }) {
    if (initialEvidence != null) {
      _evidence = List.unmodifiable(initialEvidence);
    }
    if (initialSkills != null) {
      _skills = List.unmodifiable(initialSkills);
    }
    if (initialEvidence != null || initialSkills != null) {
      _summary = LearningGrowthSummary.fromData(
        evidence: _evidence,
        skills: _skills,
      );
    }

    final session = sessionController;
    if (session != null) {
      _unregisterSessionClearer =
          session.registerPrivateStateClearer(_onSessionCleared);
      session.addListener(_onSessionStateChanged);
    }
  }

  LearningGrowthViewStatus get status => _status;
  LearningGrowthTab get activeTab => _activeTab;
  LearningEvidenceKind? get kindFilter => _kindFilter;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  List<LearningGrowthEvidence> get allEvidence => _evidence;
  List<LearningTrackedSkill> get allSkills => _skills;
  LearningGrowthSummary get summary => _summary;

  bool get isLoading => _status == LearningGrowthViewStatus.loading;
  bool get isAccessDenied => _status == LearningGrowthViewStatus.accessDenied;
  bool get isServiceUnavailable =>
      _status == LearningGrowthViewStatus.unavailableService;
  bool get isReady => _status == LearningGrowthViewStatus.ready;
  bool get isEmpty => _status == LearningGrowthViewStatus.empty;

  int get totalEvidenceCount => _evidence.length;
  int get verifiedEvidenceCount =>
      _evidence.where((e) => e.kind.isVerified).length;
  int get selfReportedEvidenceCount =>
      _evidence.where((e) => e.kind.isSelfReported).length;
  int get trackedSkillsCount => _skills.length;

  /// Filtered evidence items based on active kind filter and search query.
  List<LearningGrowthEvidence> get filteredEvidence {
    var list = _evidence;
    if (_kindFilter != null) {
      list = list.where((e) => e.kind == _kindFilter).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((e) {
        final matchesTitle = e.title.toLowerCase().contains(q);
        final matchesDesc = e.description.toLowerCase().contains(q);
        final matchesSkills =
            e.skillNames.any((s) => s.toLowerCase().contains(q));
        final matchesSource =
            e.sourceReference?.toLowerCase().contains(q) ?? false;
        return matchesTitle || matchesDesc || matchesSkills || matchesSource;
      }).toList();
    }
    return list;
  }

  /// Filtered skills based on search query.
  List<LearningTrackedSkill> get filteredSkills {
    if (_searchQuery.trim().isEmpty) return _skills;
    final q = _searchQuery.trim().toLowerCase();
    return _skills.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q);
    }).toList();
  }

  bool isOperationInProgress(String opId) => _activeOperations.contains(opId);

  void switchTab(LearningGrowthTab tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  void setKindFilter(LearningEvidenceKind? filter) {
    if (_kindFilter != filter) {
      _kindFilter = filter;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

  /// Initializes the ViewModel and loads private growth data.
  Future<void> initialize({bool force = false}) async {
    if (_status == LearningGrowthViewStatus.loading && !force) return;

    if (!_isAuthorized()) {
      _status = LearningGrowthViewStatus.accessDenied;
      _errorMessage =
          'Authentication and an activated Learning profile are required to view private growth.';
      notifyListeners();
      return;
    }

    _status = LearningGrowthViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final currentEpoch = ++_requestEpoch;

    try {
      final summaryResult = await repository.getGrowthSummary();

      if (_disposed || currentEpoch != _requestEpoch) return;

      if (summaryResult.failureType ==
          LearningGrowthFailureType.serviceUnavailable) {
        _status = LearningGrowthViewStatus.unavailableService;
        _errorMessage = summaryResult.errorMessage ?? disconnectedNotice;
        notifyListeners();
        return;
      }

      if (summaryResult.failureType == LearningGrowthFailureType.accessDenied) {
        _status = LearningGrowthViewStatus.accessDenied;
        _errorMessage = summaryResult.errorMessage;
        notifyListeners();
        return;
      }

      if (summaryResult.isFailure) {
        _status = LearningGrowthViewStatus.error;
        _errorMessage =
            summaryResult.errorMessage ?? 'Failed to load growth data.';
        notifyListeners();
        return;
      }

      // If backend returned empty in presentation mode, load evidence and skills lists
      final evidenceResult = await repository.getEvidenceList();
      final skillsResult = await repository.getTrackedSkills();

      if (_disposed || currentEpoch != _requestEpoch) return;

      _evidence = List.unmodifiable(evidenceResult.data ?? const []);
      _skills = List.unmodifiable(skillsResult.data ?? const []);

      _summary = LearningGrowthSummary.fromData(
        evidence: _evidence,
        skills: _skills,
      );

      _status = (_evidence.isEmpty && _skills.isEmpty)
          ? LearningGrowthViewStatus.empty
          : LearningGrowthViewStatus.ready;
      notifyListeners();
    } catch (e) {
      if (_disposed || currentEpoch != _requestEpoch) return;
      _status = LearningGrowthViewStatus.error;
      _errorMessage =
          'An unexpected error occurred while loading growth records.';
      notifyListeners();
    }
  }

  /// Records self-reported evidence voluntarily declared by the learner.
  Future<bool> recordSelfReportedEvidence({
    required String title,
    required String description,
    Iterable<String>? skillIds,
    Iterable<String>? skillNames,
    String? sourceReference,
  }) async {
    if (!_isAuthorized()) return false;
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();
    if (cleanTitle.isEmpty || cleanDesc.isEmpty) {
      _errorMessage = 'Title and description are required.';
      notifyListeners();
      return false;
    }

    const opKey = 'record_self_reported';
    _activeOperations.add(opKey);
    notifyListeners();

    try {
      final result = await repository.recordSelfReportedEvidence(
        title: cleanTitle,
        description: cleanDesc,
        skillIds: skillIds,
        skillNames: skillNames,
        sourceReference: sourceReference,
      );

      _activeOperations.remove(opKey);

      final newEvidence = result.data ??
          LearningGrowthEvidence.recordSelfReport(
            id: 'ev_${DateTime.now().millisecondsSinceEpoch}',
            accountId: 'acc_$currentProfileId',
            learningProfileId: currentProfileId,
            title: cleanTitle,
            description: cleanDesc,
            skillIds: skillIds,
            skillNames: skillNames,
            sourceReference: sourceReference,
          );

      _addEvidence(newEvidence);
      if (_status == LearningGrowthViewStatus.empty) {
        _status = LearningGrowthViewStatus.ready;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _activeOperations.remove(opKey);
      _errorMessage = 'Error recording self-reported evidence.';
      notifyListeners();
      return false;
    }
  }

  void _addEvidence(LearningGrowthEvidence ev) {
    final list = List<LearningGrowthEvidence>.of(_evidence);
    list.insert(0, ev);
    _evidence = List.unmodifiable(list);

    // Update skills associated evidence
    final updatedSkills = _skills.map((s) {
      if (ev.skillIds.contains(s.id)) {
        final newEvIds = {...s.associatedEvidenceIds, ev.id}.toList();
        final status = _calculateSufficiency(newEvIds, _evidence);
        return s.copyWith(
          associatedEvidenceIds: newEvIds,
          sufficiencyStatus: status,
        );
      }
      return s;
    }).toList();
    _skills = List.unmodifiable(updatedSkills);

    _summary = LearningGrowthSummary.fromData(
      evidence: _evidence,
      skills: _skills,
    );
  }

  EvidenceSufficiencyStatus _calculateSufficiency(
    List<String> evidenceIds,
    List<LearningGrowthEvidence> allEv,
  ) {
    if (evidenceIds.isEmpty) {
      return EvidenceSufficiencyStatus.insufficientEvidence;
    }
    final related = allEv.where((e) => evidenceIds.contains(e.id)).toList();
    if (related.any((e) => e.kind.isVerified)) {
      return EvidenceSufficiencyStatus.verifiedSource;
    }
    return EvidenceSufficiencyStatus.selfReportedOnly;
  }

  bool _isAuthorized() {
    final session = sessionController;
    if (session != null && session.phase != SessionPhase.signedIn) {
      return false;
    }
    return isLearningActivated;
  }

  void _onSessionCleared() {
    _evidence = const [];
    _skills = const [];
    _summary = const LearningGrowthSummary();
    _status = LearningGrowthViewStatus.accessDenied;
    _errorMessage = null;
    _activeOperations.clear();
    _requestEpoch++;
    notifyListeners();
  }

  void _onSessionStateChanged() {
    if (!_isAuthorized()) {
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

  @override
  String toString() =>
      'LearningGrowthViewModel(status: ${_status.name}, tab: ${_activeTab.name}, evidence: ${_evidence.length}, skills: ${_skills.length})';
}
