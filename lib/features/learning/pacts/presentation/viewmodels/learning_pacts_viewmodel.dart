import 'package:flutter/foundation.dart';

import '../../../../../core/security/session/session_controller.dart';
import '../../domain/entities/learning_pact.dart';
import '../../../profile/domain/entities/learning_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/repositories/i_learning_pacts_repository.dart';

/// Presentation statuses for Learning Pacts view (LRN-03).
enum LearningPactsViewStatus {
  initial,
  loading,
  ready,
  empty,
  accessDenied,
  unavailableService,
  error,
}

/// Navigation tabs in the Learning Pacts Hub.
enum LearningPactsTab {
  /// Active mutual pacts currently in progress.
  active,

  /// Incoming and outgoing pact invitations awaiting mutual acceptance.
  invitations,

  /// Past pact activity, completed pacts, and ended participation history.
  history,
}

/// Presentation ViewModel for Learning Pacts & Commitments (LRN-03, BRD v2.4-R1).
///
/// Follows ANDRIL M1 Learning Module governance:
/// - Strictly scoped to module 'learning'.
/// - Never activates a Pact before mutual acceptance (DEC-20261120-LRN03-01).
/// - Enforces authenticated and activated Learning profile scope (fail-closed).
/// - Purges private pact state immediately on session revocation.
/// - Rejects stale asynchronous responses via epoch generation checks.
/// - In-flight operation locking prevents duplicate concurrent submissions.
/// - Zero invented durations, study quotas, XP rewards, or communication permissions.
class LearningPactsViewModel extends ChangeNotifier {
  final ILearningPactsRepository repository;
  final SessionController? sessionController;
  final bool isLearningActivated;
  String _currentProfileId;
  String get currentProfileId => _currentProfileId;
  final ProfileRepository? profileRepository;
  final String currentDisplayName;

  VoidCallback? _unregisterSessionClearer;

  LearningPactsViewStatus _status = LearningPactsViewStatus.initial;
  LearningPactsTab _activeTab = LearningPactsTab.active;

  List<LearningPact> _pacts = const [];
  String? _errorMessage;
  final Set<String> _activeOperations = <String>{};

  int _requestEpoch = 0;
  bool _disposed = false;
  bool _sessionRevoked = false;

  /// Notice displayed when running under disconnected / pending backend contract.
  static const String disconnectedNotice =
      'Remote Pacts backend contract pending in OpenAPI v1. Changes cannot be saved until the service is connected.';

  LearningPactsViewModel({
    required this.repository,
    this.sessionController,
    this.isLearningActivated = false,
    String currentProfileId = 'current_learner_prof',
    this.profileRepository,
    this.currentDisplayName = 'Current Learner',
    List<LearningPact>? initialPacts,
  }) : _currentProfileId = currentProfileId {
    if (initialPacts != null) {
      _distributePacts(initialPacts);
    }

    final session = sessionController;
    if (session != null) {
      _unregisterSessionClearer =
          session.registerPrivateStateClearer(_onSessionCleared);
      session.addListener(_onSessionStateChanged);
    }
  }

  LearningPactsViewStatus get status => _status;
  LearningPactsTab get activeTab => _activeTab;
  String? get errorMessage => _errorMessage;

  List<LearningPact> get allPacts => List.unmodifiable(_pacts);

  /// Active pacts where status == active (both participants mutually agreed).
  List<LearningPact> get activePacts =>
      _pacts.where((p) => p.status == LearningPactStatus.active).toList();

  /// Incoming and outgoing invitations where status == pending.
  List<LearningPact> get pendingPacts =>
      _pacts.where((p) => p.status == LearningPactStatus.pending).toList();

  /// Incoming invitations specifically addressed to the current user.
  List<LearningPact> get incomingInvitations {
    return _pacts.where((p) {
      if (p.status != LearningPactStatus.pending) return false;
      final myPart = p.myParticipation(currentProfileId);
      return myPart != null &&
          myPart.decision == PactInvitationDecision.pending &&
          !p.isProposer(currentProfileId);
    }).toList();
  }

  /// Outgoing invitations initiated by the current user awaiting partner acceptance.
  List<LearningPact> get outgoingInvitations {
    return _pacts.where((p) {
      return p.status == LearningPactStatus.pending &&
          p.isProposer(currentProfileId);
    }).toList();
  }

  /// Past pact records: completed or cancelled.
  List<LearningPact> get historyPacts => _pacts
      .where((p) =>
          p.status == LearningPactStatus.completed ||
          p.status == LearningPactStatus.cancelled)
      .toList();

  int get activePactsCount => activePacts.length;
  int get pendingPactsCount => pendingPacts.length;
  int get historyPactsCount => historyPacts.length;

  bool get isLoading => _status == LearningPactsViewStatus.loading;
  bool get isAccessDenied => _status == LearningPactsViewStatus.accessDenied;
  bool get isServiceUnavailable =>
      _status == LearningPactsViewStatus.unavailableService;
  bool get isReady => _status == LearningPactsViewStatus.ready;
  bool get isEmpty => _status == LearningPactsViewStatus.empty;

  bool isOperationInProgress(String id) => _activeOperations.contains(id);

  void switchTab(LearningPactsTab tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  /// Initializes the ViewModel and loads pacts.
  Future<void> initialize({bool force = false}) async {
    if (_disposed || (_status == LearningPactsViewStatus.loading && !force))
      return;

    if (!_isAuthorized()) {
      _onSessionCleared();
      return;
    }

    _status = LearningPactsViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final currentEpoch = ++_requestEpoch;
    _activeOperations.clear();

    try {
      final profiles = profileRepository;
      if (profiles != null) {
        final profile = await profiles.getProfile();
        if (!_isCurrent(currentEpoch)) return;
        if (profile is! ProfileSuccess<LearningProfile> ||
            !profile.data.isActivated) {
          _pacts = const [];
          _currentProfileId = '';
          _status = profile is ProfileAccessDenied
              ? LearningPactsViewStatus.accessDenied
              : LearningPactsViewStatus.unavailableService;
          _errorMessage = 'Your Learning profile could not be verified.';
          notifyListeners();
          return;
        }
        _currentProfileId = profile.data.profileId;
      }
      if (currentProfileId.trim().isEmpty) {
        _status = LearningPactsViewStatus.unavailableService;
        _errorMessage = 'Your Learning profile could not be verified.';
        notifyListeners();
        return;
      }
      final result = await repository.getPacts();

      if (!_isCurrent(currentEpoch)) return;

      if (result.failureType == LearningPactsFailureType.serviceUnavailable) {
        _status = LearningPactsViewStatus.unavailableService;
        _errorMessage = result.errorMessage ?? disconnectedNotice;
        notifyListeners();
        return;
      }

      if (result.failureType == LearningPactsFailureType.accessDenied) {
        _onSessionCleared();
        return;
      }

      if (result.isFailure) {
        _status = LearningPactsViewStatus.error;
        _errorMessage = result.errorMessage ?? 'Failed to load pacts.';
        notifyListeners();
        return;
      }

      _distributePacts(result.data ?? const <LearningPact>[]);
      _status = _pacts.isEmpty
          ? LearningPactsViewStatus.empty
          : LearningPactsViewStatus.ready;
      notifyListeners();
    } catch (e) {
      if (!_isCurrent(currentEpoch)) return;
      _status = LearningPactsViewStatus.error;
      _errorMessage = 'An unexpected error occurred while loading pacts.';
      notifyListeners();
    }
  }

  /// Saves only a confirmed repository result; unavailable operations stay closed.
  Future<bool> proposePact({
    required String title,
    required String sharedGoal,
    required String partnerProfileId,
    required String partnerDisplayName,
    String? partnerAvatarUrl,
    String? duration,
    String? studyPlan,
    Iterable<String>? commitmentTexts,
  }) async {
    if (title.trim().isEmpty ||
        sharedGoal.trim().isEmpty ||
        partnerProfileId.trim().isEmpty ||
        partnerDisplayName.trim().isEmpty ||
        partnerProfileId.trim() == currentProfileId) return false;
    return _mutate(
      'proposal:${partnerProfileId.trim()}',
      () => repository.proposePact(
        title: title.trim(),
        sharedGoal: sharedGoal.trim(),
        partnerProfileId: partnerProfileId.trim(),
        partnerDisplayName: partnerDisplayName.trim(),
        partnerAvatarUrl: partnerAvatarUrl,
        duration: duration,
        studyPlan: studyPlan,
        commitmentTexts: commitmentTexts,
      ),
      validate: (pact) =>
          pact.isProposer(currentProfileId) &&
          pact.status == LearningPactStatus.pending,
    );
  }

  Future<bool> acceptPact(String pactId) => _change(
        pactId,
        repository.acceptPact,
        permitted: (p) => _canRespond(p),
      );

  Future<bool> declinePact(String pactId) => _change(
        pactId,
        repository.declinePact,
        permitted: (p) => _canRespond(p),
      );

  Future<bool> cancelPact(String pactId) => _change(
        pactId,
        repository.cancelPact,
        permitted: (p) =>
            p.status == LearningPactStatus.pending &&
            p.isProposer(currentProfileId),
      );

  Future<bool> withdrawPact(String pactId) => _change(
        pactId,
        repository.withdrawPact,
        permitted: (p) => p.status == LearningPactStatus.active,
      );

  Future<bool> confirmCompletion(String pactId) => _change(
        pactId,
        repository.confirmCompletion,
        permitted: (p) =>
            p.status == LearningPactStatus.active &&
            p.myParticipation(currentProfileId)?.completionConfirmed == false,
      );

  Future<bool> toggleCommitment({
    required String pactId,
    required String commitmentId,
    required bool isCompleted,
  }) =>
      _change(
        pactId,
        (id) => repository.updateCommitmentProgress(
          pactId: id,
          commitmentId: commitmentId.trim(),
          isCompleted: isCompleted,
        ),
        permitted: (p) =>
            p.status == LearningPactStatus.active &&
            p.commitments.any((c) => c.id == commitmentId.trim()),
      );

  bool _canRespond(LearningPact pact) =>
      pact.status == LearningPactStatus.pending &&
      !pact.isProposer(currentProfileId) &&
      pact.myParticipation(currentProfileId)?.decision ==
          PactInvitationDecision.pending;

  Future<bool> _change(
    String pactId,
    Future<LearningPactsResult<LearningPact>> Function(String) operation, {
    required bool Function(LearningPact) permitted,
  }) async {
    final id = pactId.trim();
    final pact = _pacts.where((p) => p.id == id).firstOrNull;
    if (id.isEmpty ||
        pact == null ||
        pact.myParticipation(currentProfileId) == null ||
        !permitted(pact)) {
      return false;
    }
    return _mutate(id, () => operation(id), validate: (p) => p.id == id);
  }

  Future<bool> _mutate(
    String key,
    Future<LearningPactsResult<LearningPact>> Function() operation, {
    required bool Function(LearningPact) validate,
  }) async {
    if (!_isAuthorized() ||
        currentProfileId.trim().isEmpty ||
        !_activeOperations.add(key)) return false;
    final epoch = _requestEpoch;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await operation();
      if (!_isCurrent(epoch)) return false;
      final pact = result.data;
      if (!result.isSuccess || pact == null) {
        _errorMessage = result.errorMessage ?? 'The change could not be saved.';
        if (result.failureType == LearningPactsFailureType.accessDenied) {
          _onSessionCleared();
        } else if (result.failureType ==
            LearningPactsFailureType.serviceUnavailable) {
          _status = LearningPactsViewStatus.unavailableService;
        }
        return false;
      }
      if (pact.id.trim().isEmpty ||
          pact.module != LearningPact.moduleScope ||
          pact.myParticipation(currentProfileId) == null ||
          !validate(pact)) {
        _errorMessage = 'The returned pact could not be verified.';
        return false;
      }
      final updated = List<LearningPact>.of(_pacts);
      final index = updated.indexWhere((p) => p.id == pact.id);
      if (index < 0) {
        updated.add(pact);
      } else {
        updated[index] = pact;
      }
      _pacts = List.unmodifiable(updated);
      _status = LearningPactsViewStatus.ready;
      return true;
    } catch (_) {
      if (_isCurrent(epoch)) _errorMessage = 'The change could not be saved.';
      return false;
    } finally {
      if (_isCurrent(epoch)) {
        _activeOperations.remove(key);
        notifyListeners();
      }
    }
  }

  void _distributePacts(List<LearningPact> pacts) {
    final seen = <String>{};
    _pacts = List.unmodifiable(pacts.where((p) =>
        p.module == LearningPact.moduleScope &&
        p.myParticipation(currentProfileId) != null &&
        seen.add(p.id)));
  }

  bool _isAuthorized() =>
      !_disposed &&
      !_sessionRevoked &&
      isLearningActivated &&
      (sessionController == null ||
          sessionController!.phase == SessionPhase.signedIn);

  bool _isCurrent(int epoch) => _isAuthorized() && epoch == _requestEpoch;

  void _onSessionCleared() {
    if (_disposed) return;
    _sessionRevoked = true;
    _pacts = const [];
    _status = LearningPactsViewStatus.accessDenied;
    _errorMessage = null;
    _activeOperations.clear();
    _requestEpoch++;
    if (profileRepository != null) _currentProfileId = '';
    notifyListeners();
  }

  void _onSessionStateChanged() {
    if (!_isAuthorized()) _onSessionCleared();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _requestEpoch++;
    _pacts = const [];
    _activeOperations.clear();
    _unregisterSessionClearer?.call();
    sessionController?.removeListener(_onSessionStateChanged);
    super.dispose();
  }

  @override
  String toString() => 'LearningPactsViewModel(status: ${_status.name})';
}
