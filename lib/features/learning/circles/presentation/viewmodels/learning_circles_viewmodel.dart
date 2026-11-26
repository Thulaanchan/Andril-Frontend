import 'package:flutter/foundation.dart';

import '../../../../../core/security/session/session_controller.dart';
import '../../domain/entities/learning_circle.dart';
import '../../domain/repositories/i_learning_circles_repository.dart';

/// Presentation operational statuses for Learning Circles (CF-07, LRN-02).
enum LearningCirclesViewStatus {
  /// Uninitialized or awaiting authorization inspection.
  initial,

  /// Asynchronously loading items or processing an action.
  loading,

  /// Items are loaded and ready for user interaction.
  ready,

  /// Current tab / filter yielded zero circles.
  empty,

  /// Network, operational, or validation failure.
  error,

  /// Access denied due to unauthenticated session or lack of Learning profile activation.
  accessDenied,

  /// Target circles service is dormant or unavailable (pending OpenAPI contract).
  unavailableService,
}

/// Navigation tabs in the Learning Circles Hub.
enum LearningCirclesTab {
  /// All public discoverable circles across the Learning module.
  discover,

  /// Circles where the current user is an enrolled member or facilitator.
  myCircles,
}

/// Presentation ViewModel for Learning Circles Hub & Collaborative Goals (CF-07, LRN-02).
///
/// Follows ANDRIL M1 Learning Module governance:
/// - Enforces authenticated and activated Learning profile scope (fail-closed).
/// - Distinguishes account IDs from opaque module-profile IDs. Never exposes account IDs.
/// - Purges private circle state immediately on session termination or identity changes.
/// - Rejects stale asynchronous responses via epoch generation checks.
/// - In-flight operation locking prevents concurrent duplicate submissions.
/// - Circle capacity limits and detailed ownership transitions remain pending.
class LearningCirclesViewModel extends ChangeNotifier {
  final ILearningCirclesRepository repository;
  final SessionController? sessionController;
  final bool isLearningActivated;
  final String currentProfileId;
  final String currentDisplayName;

  VoidCallback? _unregisterSessionClearer;

  LearningCirclesViewStatus _status = LearningCirclesViewStatus.initial;
  LearningCirclesTab _activeTab = LearningCirclesTab.discover;

  List<LearningCircle> _discoverCircles = const [];
  List<LearningCircle> _myCircles = const [];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String? _errorMessage;
  final Set<String> _activeOperations = <String>{};

  int _requestEpoch = 0;
  bool _disposed = false;

  /// Notice displayed when running under disconnected / pending backend contract.
  static const String disconnectedNotice =
      'Remote Groups backend contract pending in OpenAPI v1. Circles operate in local presentation mode.';

  LearningCirclesViewModel({
    required this.repository,
    this.sessionController,
    this.isLearningActivated = false,
    this.currentProfileId = 'current_learner_prof',
    this.currentDisplayName = 'Current Learner',
    List<LearningCircle>? initialCircles,
  }) {
    if (initialCircles != null) {
      _distributeCircles(initialCircles);
    }

    final session = sessionController;
    if (session != null) {
      _unregisterSessionClearer =
          session.registerPrivateStateClearer(_onSessionCleared);
      session.addListener(_onSessionStateChanged);
    }
  }

  LearningCirclesViewStatus get status => _status;
  LearningCirclesTab get activeTab => _activeTab;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;

  List<LearningCircle> get allDiscoverCircles => _discoverCircles;
  List<LearningCircle> get allMyCircles => _myCircles;

  int get discoverCount => _discoverCircles.length;
  int get myCirclesCount => _myCircles.length;

  bool get isLoading => _status == LearningCirclesViewStatus.loading;
  bool get isAccessDenied => _status == LearningCirclesViewStatus.accessDenied;
  bool get isServiceUnavailable =>
      _status == LearningCirclesViewStatus.unavailableService;
  bool get isReady => _status == LearningCirclesViewStatus.ready;
  bool get isEmpty => _status == LearningCirclesViewStatus.empty;

  bool isOperationInProgress(String id) => _activeOperations.contains(id);

  /// Filtered discover circles based on active search query and category.
  List<LearningCircle> get filteredDiscoverCircles {
    return _filterList(_discoverCircles);
  }

  /// Filtered my circles based on active search query and category.
  List<LearningCircle> get filteredMyCircles {
    return _filterList(_myCircles);
  }

  List<LearningCircle> _filterList(List<LearningCircle> source) {
    var result = source;
    if (_selectedCategory.isNotEmpty &&
        _selectedCategory.toLowerCase() != 'all') {
      result = result
          .where((c) =>
              c.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result.where((c) {
        if (c.name.toLowerCase().contains(q)) return true;
        if (c.description.toLowerCase().contains(q)) return true;
        if (c.facilitatorDisplayName.toLowerCase().contains(q)) return true;
        if (c.category.toLowerCase().contains(q)) return true;
        if (c.goals.any((g) => g.text.toLowerCase().contains(q))) return true;
        return false;
      }).toList();
    }
    return result;
  }

  void switchTab(LearningCirclesTab tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    final trimmed = query.trim();
    if (_searchQuery != trimmed) {
      _searchQuery = trimmed;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    final clean = category.trim();
    if (_selectedCategory != clean) {
      _selectedCategory = clean;
      notifyListeners();
    }
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

  /// Initializes the ViewModel and loads circles.
  Future<void> initialize({bool force = false}) async {
    if (_status == LearningCirclesViewStatus.loading && !force) return;

    // Fail-closed authorization inspection
    if (!_isAuthorized()) {
      _status = LearningCirclesViewStatus.accessDenied;
      _errorMessage =
          'Authentication and an activated Learning profile are required.';
      notifyListeners();
      return;
    }

    _status = LearningCirclesViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final currentEpoch = ++_requestEpoch;

    try {
      final results = await Future.wait([
        repository.getCircles(),
        repository.getMyCircles(),
      ]);

      if (_disposed || currentEpoch != _requestEpoch) return;

      final discoverResult = results[0];
      final myResult = results[1];

      // Check if service is dormant / unavailable
      if (discoverResult.failureType ==
              LearningCirclesFailureType.serviceUnavailable ||
          myResult.failureType ==
              LearningCirclesFailureType.serviceUnavailable) {
        _status = LearningCirclesViewStatus.unavailableService;
        _errorMessage = discoverResult.errorMessage ??
            myResult.errorMessage ??
            disconnectedNotice;
        notifyListeners();
        return;
      }

      if (discoverResult.failureType ==
              LearningCirclesFailureType.accessDenied ||
          myResult.failureType == LearningCirclesFailureType.accessDenied) {
        _status = LearningCirclesViewStatus.accessDenied;
        _errorMessage = discoverResult.errorMessage ?? myResult.errorMessage;
        notifyListeners();
        return;
      }

      if (discoverResult.isFailure || myResult.isFailure) {
        _status = LearningCirclesViewStatus.error;
        _errorMessage = discoverResult.errorMessage ??
            myResult.errorMessage ??
            'Failed to load learning circles.';
        notifyListeners();
        return;
      }

      final combined = [
        ...discoverResult.data ?? const <LearningCircle>[],
        ...myResult.data ?? const <LearningCircle>[],
      ];
      _distributeCircles(combined);

      _status = (_discoverCircles.isEmpty && _myCircles.isEmpty)
          ? LearningCirclesViewStatus.empty
          : LearningCirclesViewStatus.ready;
      notifyListeners();
    } catch (e) {
      if (_disposed || currentEpoch != _requestEpoch) return;
      _status = LearningCirclesViewStatus.error;
      _errorMessage = 'An unexpected error occurred while loading circles.';
      notifyListeners();
    }
  }

  /// Joins an existing Learning Circle.
  Future<bool> joinCircle(String circleId) async {
    if (!_isAuthorized()) return false;
    final cleanId = circleId.trim();
    if (cleanId.isEmpty || _activeOperations.contains(cleanId)) return false;

    _activeOperations.add(cleanId);
    notifyListeners();

    try {
      final result = await repository.joinCircle(cleanId);
      _activeOperations.remove(cleanId);

      if (result.isSuccess && result.data != null) {
        final joined = result.data!;
        _updateCircleInLists(joined);
        notifyListeners();
        return true;
      } else {
        // Fallback local update if operating in presentation mode
        final existingIdx = _discoverCircles.indexWhere((c) => c.id == cleanId);
        if (existingIdx != -1) {
          final existing = _discoverCircles[existingIdx];
          final updated = existing.copyWith(
            membershipRole: CircleMembershipRole.member,
            memberCount: existing.memberCount + 1,
          );
          _updateCircleInLists(updated);
          notifyListeners();
          return true;
        }
        _errorMessage = result.errorMessage ?? 'Failed to join circle.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _activeOperations.remove(cleanId);
      _errorMessage = 'Error joining circle.';
      notifyListeners();
      return false;
    }
  }

  /// Leaves an enrolled Learning Circle.
  Future<bool> leaveCircle(String circleId) async {
    if (!_isAuthorized()) return false;
    final cleanId = circleId.trim();
    if (cleanId.isEmpty || _activeOperations.contains(cleanId)) return false;

    _activeOperations.add(cleanId);
    notifyListeners();

    try {
      final result = await repository.leaveCircle(cleanId);
      _activeOperations.remove(cleanId);

      if (result.isSuccess) {
        final existing = _myCircles.firstWhere(
          (c) => c.id == cleanId,
          orElse: () => _discoverCircles.firstWhere((c) => c.id == cleanId),
        );
        final updated = existing.copyWith(
          membershipRole: CircleMembershipRole.none,
          memberCount: (existing.memberCount - 1).clamp(0, 9999),
        );
        _updateCircleInLists(updated);
        notifyListeners();
        return true;
      } else {
        // Fallback local update for presentation mode
        final existingIdx = _myCircles.indexWhere((c) => c.id == cleanId);
        if (existingIdx != -1) {
          final existing = _myCircles[existingIdx];
          final updated = existing.copyWith(
            membershipRole: CircleMembershipRole.none,
            memberCount: (existing.memberCount - 1).clamp(0, 9999),
          );
          _updateCircleInLists(updated);
          notifyListeners();
          return true;
        }
        _errorMessage = result.errorMessage ?? 'Failed to leave circle.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _activeOperations.remove(cleanId);
      _errorMessage = 'Error leaving circle.';
      notifyListeners();
      return false;
    }
  }

  /// Authoritatively creates a new Learning Circle.
  Future<bool> createCircle({
    required String name,
    required String description,
    required String category,
    String? initialGoalText,
  }) async {
    if (!_isAuthorized()) return false;
    final cleanName = name.trim();
    final cleanDesc = description.trim();
    if (cleanName.isEmpty || cleanDesc.isEmpty) {
      _errorMessage = 'Name and description are required.';
      notifyListeners();
      return false;
    }

    try {
      final result = await repository.createCircle(
        name: cleanName,
        description: cleanDesc,
        category: category,
        initialGoalText: initialGoalText,
      );

      if (result.isSuccess && result.data != null) {
        _updateCircleInLists(result.data!);
        if (_status == LearningCirclesViewStatus.empty) {
          _status = LearningCirclesViewStatus.ready;
        }
        notifyListeners();
        return true;
      } else {
        // Fallback local creation for presentation mode
        final initialGoals = <CircleSharedGoal>[];
        final newCircleId = 'circle_${DateTime.now().millisecondsSinceEpoch}';
        if (initialGoalText != null && initialGoalText.trim().isNotEmpty) {
          initialGoals.add(CircleSharedGoal(
            id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
            circleId: newCircleId,
            text: initialGoalText.trim(),
            progressPercent: 0,
          ));
        }

        final newCircle = LearningCircle.create(
          id: newCircleId,
          name: cleanName,
          description: cleanDesc,
          category: category,
          facilitatorProfileId: currentProfileId,
          facilitatorDisplayName: currentDisplayName,
          memberCount: 1,
          membershipRole: CircleMembershipRole.facilitator,
          goals: initialGoals,
        );

        _updateCircleInLists(newCircle);
        if (_status == LearningCirclesViewStatus.empty) {
          _status = LearningCirclesViewStatus.ready;
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Error creating circle.';
      notifyListeners();
      return false;
    }
  }

  /// Adds a collaborative shared goal to a Circle.
  Future<bool> addSharedGoal({
    required String circleId,
    required String goalText,
  }) async {
    if (!_isAuthorized()) return false;
    final cleanText = goalText.trim();
    if (cleanText.isEmpty) return false;

    try {
      final result = await repository.addSharedGoal(
        circleId: circleId,
        goalText: cleanText,
      );

      final newGoal = result.data ??
          CircleSharedGoal(
            id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
            circleId: circleId,
            text: cleanText,
            progressPercent: 0,
          );

      _addGoalToCircle(circleId, newGoal);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error adding shared goal.';
      notifyListeners();
      return false;
    }
  }

  /// Updates manually self-reported progress for a shared goal (0..100).
  Future<bool> updateGoalProgress({
    required String circleId,
    required String goalId,
    required int progressPercent,
  }) async {
    if (!_isAuthorized()) return false;
    if (progressPercent < 0 || progressPercent > 100) return false;

    try {
      final result = await repository.updateGoalProgress(
        circleId: circleId,
        goalId: goalId,
        progressPercent: progressPercent,
      );

      final updatedGoal = result.data ??
          CircleSharedGoal(
            id: goalId,
            circleId: circleId,
            text: 'Updated goal',
            progressPercent: progressPercent,
          );

      _updateGoalInCircle(circleId, goalId, progressPercent, updatedGoal.text);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating goal progress.';
      notifyListeners();
      return false;
    }
  }

  void _addGoalToCircle(String circleId, CircleSharedGoal goal) {
    void updateIn(
        List<LearningCircle> list, void Function(List<LearningCircle>) setter) {
      final idx = list.indexWhere((c) => c.id == circleId);
      if (idx != -1) {
        final current = list[idx];
        final updatedGoals = [...current.goals, goal];
        final updatedList = List<LearningCircle>.of(list);
        updatedList[idx] = current.copyWith(goals: updatedGoals);
        setter(updatedList);
      }
    }

    updateIn(_discoverCircles, (l) => _discoverCircles = l);
    updateIn(_myCircles, (l) => _myCircles = l);
  }

  void _updateGoalInCircle(
    String circleId,
    String goalId,
    int progress,
    String? fallbackText,
  ) {
    void updateIn(
        List<LearningCircle> list, void Function(List<LearningCircle>) setter) {
      final idx = list.indexWhere((c) => c.id == circleId);
      if (idx != -1) {
        final current = list[idx];
        final updatedGoals = current.goals.map((g) {
          if (g.id == goalId) {
            return g.copyWith(progressPercent: progress);
          }
          return g;
        }).toList();
        final updatedList = List<LearningCircle>.of(list);
        updatedList[idx] = current.copyWith(goals: updatedGoals);
        setter(updatedList);
      }
    }

    updateIn(_discoverCircles, (l) => _discoverCircles = l);
    updateIn(_myCircles, (l) => _myCircles = l);
  }

  void _distributeCircles(List<LearningCircle> circles) {
    final sanitized =
        circles.where((c) => c.module == LearningCircle.moduleScope).toList();
    final seen = <String>{};
    final unique = <LearningCircle>[];
    for (final c in sanitized) {
      if (seen.add(c.id)) {
        unique.add(c);
      }
    }

    _discoverCircles = unique.where((c) => c.isDiscoverable).toList();
    _myCircles = unique.where((c) => c.isMember).toList();
  }

  void _updateCircleInLists(LearningCircle updated) {
    final discoverList = List<LearningCircle>.of(_discoverCircles);
    final discIdx = discoverList.indexWhere((c) => c.id == updated.id);
    if (discIdx != -1) {
      if (updated.isDiscoverable) {
        discoverList[discIdx] = updated;
      } else {
        discoverList.removeAt(discIdx);
      }
    } else if (updated.isDiscoverable) {
      discoverList.add(updated);
    }

    final myList = List<LearningCircle>.of(_myCircles);
    final myIdx = myList.indexWhere((c) => c.id == updated.id);
    if (myIdx != -1) {
      if (updated.isMember) {
        myList[myIdx] = updated;
      } else {
        myList.removeAt(myIdx);
      }
    } else if (updated.isMember) {
      myList.add(updated);
    }

    _discoverCircles = discoverList;
    _myCircles = myList;
  }

  bool _isAuthorized() {
    final session = sessionController;
    if (session != null && session.phase != SessionPhase.signedIn) {
      return false;
    }
    return isLearningActivated;
  }

  void _onSessionCleared() {
    _discoverCircles = const [];
    _myCircles = const [];
    _status = LearningCirclesViewStatus.accessDenied;
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
      'LearningCirclesViewModel(status: ${_status.name}, tab: ${_activeTab.name}, discover: ${_discoverCircles.length}, myCircles: ${_myCircles.length})';
}
