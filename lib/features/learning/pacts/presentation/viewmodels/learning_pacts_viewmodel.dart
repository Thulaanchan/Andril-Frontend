import 'package:flutter/foundation.dart';

import '../../../../../core/security/session/session_controller.dart';
import '../../domain/entities/learning_pact.dart';
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
  final String currentProfileId;
  final String currentDisplayName;

  VoidCallback? _unregisterSessionClearer;

  LearningPactsViewStatus _status = LearningPactsViewStatus.initial;
  LearningPactsTab _activeTab = LearningPactsTab.active;

  List<LearningPact> _pacts = const [];
  String? _errorMessage;
  final Set<String> _activeOperations = <String>{};

  int _requestEpoch = 0;
  bool _disposed = false;

  /// Notice displayed when running under disconnected / pending backend contract.
  static const String disconnectedNotice =
      'Remote Pacts backend contract pending in OpenAPI v1. Pacts operate in local presentation mode.';

  LearningPactsViewModel({
    required this.repository,
    this.sessionController,
    this.isLearningActivated = false,
    this.currentProfileId = 'current_learner_prof',
    this.currentDisplayName = 'Current Learner',
    List<LearningPact>? initialPacts,
  }) {
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

  List<LearningPact> get allPacts => _pacts;

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
    if (_status == LearningPactsViewStatus.loading && !force) return;

    if (!_isAuthorized()) {
      _status = LearningPactsViewStatus.accessDenied;
      _errorMessage =
          'Authentication and an activated Learning profile are required.';
      notifyListeners();
      return;
    }

    _status = LearningPactsViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final currentEpoch = ++_requestEpoch;

    try {
      final result = await repository.getPacts();

      if (_disposed || currentEpoch != _requestEpoch) return;

      if (result.failureType == LearningPactsFailureType.serviceUnavailable) {
        _status = LearningPactsViewStatus.unavailableService;
        _errorMessage = result.errorMessage ?? disconnectedNotice;
        notifyListeners();
        return;
      }

      if (result.failureType == LearningPactsFailureType.accessDenied) {
        _status = LearningPactsViewStatus.accessDenied;
        _errorMessage = result.errorMessage;
        notifyListeners();
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
      if (_disposed || currentEpoch != _requestEpoch) return;
      _status = LearningPactsViewStatus.error;
      _errorMessage = 'An unexpected error occurred while loading pacts.';
      notifyListeners();
    }
  }

  /// Proposes a new Learning Pact between the current user and a selected partner.
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
    if (!_isAuthorized()) return false;
    final cleanTitle = title.trim();
    final cleanGoal = sharedGoal.trim();
    final cleanPartnerId = partnerProfileId.trim();
    final cleanPartnerName = partnerDisplayName.trim();

    if (cleanTitle.isEmpty ||
        cleanGoal.isEmpty ||
        cleanPartnerId.isEmpty ||
        cleanPartnerName.isEmpty) {
      _errorMessage = 'Title, goal, and partner selection are required.';
      notifyListeners();
      return false;
    }

    try {
      final result = await repository.proposePact(
        title: cleanTitle,
        sharedGoal: cleanGoal,
        partnerProfileId: cleanPartnerId,
        partnerDisplayName: cleanPartnerName,
        partnerAvatarUrl: partnerAvatarUrl,
        duration: duration,
        studyPlan: studyPlan,
        commitmentTexts: commitmentTexts,
      );

      final newPact = result.data ??
          LearningPact.propose(
            id: 'pact_${DateTime.now().millisecondsSinceEpoch}',
            title: cleanTitle,
            sharedGoal: cleanGoal,
            proposerProfileId: currentProfileId,
            proposerDisplayName: currentDisplayName,
            partnerProfileId: cleanPartnerId,
            partnerDisplayName: cleanPartnerName,
            partnerAvatarUrl: partnerAvatarUrl,
            duration: duration,
            studyPlan: studyPlan,
            commitmentTexts: commitmentTexts,
          );

      _updatePactInList(newPact);
      if (_status == LearningPactsViewStatus.empty) {
        _status = LearningPactsViewStatus.ready;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error proposing pact.';
      notifyListeners();
      return false;
    }
  }

  /// Records acceptance of an incoming pact invitation.
  ///
  /// CRITICAL GOVERNANCE INVARIANT:
  /// The pact activates IF AND ONLY IF all participants have voluntarily accepted.
  Future<bool> acceptPact(String pactId) async {
    if (!_isAuthorized()) return false;
    final cleanId = pactId.trim();
    if (cleanId.isEmpty || _activeOperations.contains(cleanId)) return false;

    _activeOperations.add(cleanId);
    notifyListeners();

    try {
      final result = await repository.acceptPact(cleanId);
      _activeOperations.remove(cleanId);

      if (result.isSuccess && result.data != null) {
        _updatePactInList(result.data!);
        notifyListeners();
        return true;
      }

      // Local fallback presentation update
      final idx = _pacts.indexWhere((p) => p.id == cleanId);
      if (idx != -1) {
        final existing = _pacts[idx];
        final updatedParticipants = existing.participants.map((p) {
          if (p.participantProfileId == currentProfileId) {
            return p.copyWith(
              decision: PactInvitationDecision.accepted,
              agreedAt: DateTime.now(),
            );
          }
          return p;
        }).toList();

        final allAccepted = updatedParticipants
            .every((p) => p.decision == PactInvitationDecision.accepted);

        final updatedHistory = [
          ...existing.history,
          PactHistoryEvent(
            id: 'hist_${cleanId}_${existing.history.length + 1}',
            pactId: cleanId,
            title: 'Pact accepted',
            description: 'Both participants accepted the commitment.',
            type: PactHistoryEventType.agreed,
            actorDisplayName: currentDisplayName,
          ),
        ];

        final updatedPact = existing.copyWith(
          participants: updatedParticipants,
          status: allAccepted
              ? LearningPactStatus.active
              : LearningPactStatus.pending,
          history: updatedHistory,
        );

        _updatePactInList(updatedPact);
        notifyListeners();
        return true;
      }

      _errorMessage = result.errorMessage ?? 'Failed to accept pact.';
      notifyListeners();
      return false;
    } catch (e) {
      _activeOperations.remove(cleanId);
      _errorMessage = 'Error accepting pact.';
      notifyListeners();
      return false;
    }
  }

  /// Records decline of an incoming pact invitation.
  Future<bool> declinePact(String pactId) async {
    if (!_isAuthorized()) return false;
    final cleanId = pactId.trim();
    if (cleanId.isEmpty || _activeOperations.contains(cleanId)) return false;

    _activeOperations.add(cleanId);
    notifyListeners();

    try {
      final result = await repository.declinePact(cleanId);
      _activeOperations.remove(cleanId);

      if (result.isSuccess && result.data != null) {
        _updatePactInList(result.data!);
        notifyListeners();
        return true;
      }

      final idx = _pacts.indexWhere((p) => p.id == cleanId);
      if (idx != -1) {
        final existing = _pacts[idx];
        final updatedParticipants = existing.participants.map((p) {
          if (p.participantProfileId == currentProfileId) {
            return p.copyWith(decision: PactInvitationDecision.declined);
          }
          return p;
        }).toList();

        final updatedHistory = [
          ...existing.history,
          PactHistoryEvent(
            id: 'hist_${cleanId}_${existing.history.length + 1}',
            pactId: cleanId,
            title: 'Pact invitation declined',
            description: '$currentDisplayName declined the invitation.',
            type: PactHistoryEventType.withdrawn,
            actorDisplayName: currentDisplayName,
          ),
        ];

        final updatedPact = existing.copyWith(
          participants: updatedParticipants,
          history: updatedHistory,
        );

        _updatePactInList(updatedPact);
        notifyListeners();
        return true;
      }

      _errorMessage = result.errorMessage ?? 'Failed to decline pact.';
      notifyListeners();
      return false;
    } catch (e) {
      _activeOperations.remove(cleanId);
      _errorMessage = 'Error declining pact.';
      notifyListeners();
      return false;
    }
  }

  /// Cancels a pending pact proposal initiated by the current user.
  Future<bool> cancelPact(String pactId) async {
    if (!_isAuthorized()) return false;
    final cleanId = pactId.trim();
    if (cleanId.isEmpty || _activeOperations.contains(cleanId)) return false;

    _activeOperations.add(cleanId);
    notifyListeners();

    try {
      final result = await repository.cancelPact(cleanId);
      _activeOperations.remove(cleanId);

      if (result.isSuccess && result.data != null) {
        _updatePactInList(result.data!);
        notifyListeners();
        return true;
      }

      final idx = _pacts.indexWhere((p) => p.id == cleanId);
      if (idx != -1) {
        final existing = _pacts[idx];
        if (!existing.isProposer(currentProfileId)) {
          _errorMessage = 'Only the designated proposer may cancel.';
          notifyListeners();
          return false;
        }

        final updatedHistory = [
          ...existing.history,
          PactHistoryEvent(
            id: 'hist_${cleanId}_${existing.history.length + 1}',
            pactId: cleanId,
            title: 'Pact cancelled',
            description: 'The proposal was cancelled by the proposer.',
            type: PactHistoryEventType.withdrawn,
            actorDisplayName: currentDisplayName,
          ),
        ];

        final updatedPact = existing.copyWith(
          status: LearningPactStatus.cancelled,
          history: updatedHistory,
        );

        _updatePactInList(updatedPact);
        notifyListeners();
        return true;
      }

      _errorMessage = result.errorMessage ?? 'Failed to cancel pact.';
      notifyListeners();
      return false;
    } catch (e) {
      _activeOperations.remove(cleanId);
      _errorMessage = 'Error cancelling pact.';
      notifyListeners();
      return false;
    }
  }

  /// Withdraws the current user from an active pact, ending participation.
  Future<bool> withdrawPact(String pactId) async {
    if (!_isAuthorized()) return false;
    final cleanId = pactId.trim();
    if (cleanId.isEmpty || _activeOperations.contains(cleanId)) return false;

    _activeOperations.add(cleanId);
    notifyListeners();

    try {
      final result = await repository.withdrawPact(cleanId);
      _activeOperations.remove(cleanId);

      if (result.isSuccess && result.data != null) {
        _updatePactInList(result.data!);
        notifyListeners();
        return true;
      }

      final idx = _pacts.indexWhere((p) => p.id == cleanId);
      if (idx != -1) {
        final existing = _pacts[idx];
        final updatedHistory = [
          ...existing.history,
          PactHistoryEvent(
            id: 'hist_${cleanId}_${existing.history.length + 1}',
            pactId: cleanId,
            title: 'Participation ended',
            description: '$currentDisplayName ended their participation.',
            type: PactHistoryEventType.withdrawn,
            actorDisplayName: currentDisplayName,
          ),
        ];

        final updatedPact = existing.copyWith(
          status: LearningPactStatus.cancelled,
          history: updatedHistory,
        );

        _updatePactInList(updatedPact);
        notifyListeners();
        return true;
      }

      _errorMessage = result.errorMessage ?? 'Failed to withdraw from pact.';
      notifyListeners();
      return false;
    } catch (e) {
      _activeOperations.remove(cleanId);
      _errorMessage = 'Error withdrawing from pact.';
      notifyListeners();
      return false;
    }
  }

  /// Records this participant's report of pact completion.
  Future<bool> confirmCompletion(String pactId) async {
    if (!_isAuthorized()) return false;
    final cleanId = pactId.trim();
    if (cleanId.isEmpty || _activeOperations.contains(cleanId)) return false;

    _activeOperations.add(cleanId);
    notifyListeners();

    try {
      final result = await repository.confirmCompletion(cleanId);
      _activeOperations.remove(cleanId);

      if (result.isSuccess && result.data != null) {
        _updatePactInList(result.data!);
        notifyListeners();
        return true;
      }

      final idx = _pacts.indexWhere((p) => p.id == cleanId);
      if (idx != -1) {
        final existing = _pacts[idx];
        final updatedParticipants = existing.participants.map((p) {
          if (p.participantProfileId == currentProfileId) {
            return p.copyWith(completionConfirmed: true);
          }
          return p;
        }).toList();

        final allConfirmed =
            updatedParticipants.every((p) => p.completionConfirmed);

        final updatedHistory = [
          ...existing.history,
          PactHistoryEvent(
            id: 'hist_${cleanId}_${existing.history.length + 1}',
            pactId: cleanId,
            title: 'Pact completed',
            description: '$currentDisplayName confirmed completion.',
            type: PactHistoryEventType.completed,
            actorDisplayName: currentDisplayName,
          ),
        ];

        final updatedPact = existing.copyWith(
          participants: updatedParticipants,
          status: allConfirmed
              ? LearningPactStatus.completed
              : LearningPactStatus.active,
          history: updatedHistory,
        );

        _updatePactInList(updatedPact);
        notifyListeners();
        return true;
      }

      _errorMessage = result.errorMessage ?? 'Failed to confirm completion.';
      notifyListeners();
      return false;
    } catch (e) {
      _activeOperations.remove(cleanId);
      _errorMessage = 'Error confirming completion.';
      notifyListeners();
      return false;
    }
  }

  /// Toggles self-reported completion of an agreed commitment milestone.
  Future<bool> toggleCommitment({
    required String pactId,
    required String commitmentId,
    required bool isCompleted,
  }) async {
    if (!_isAuthorized()) return false;
    final cleanPactId = pactId.trim();
    final cleanCmtId = commitmentId.trim();
    if (cleanPactId.isEmpty || cleanCmtId.isEmpty) return false;

    try {
      final result = await repository.updateCommitmentProgress(
        pactId: cleanPactId,
        commitmentId: cleanCmtId,
        isCompleted: isCompleted,
      );

      if (result.isSuccess && result.data != null) {
        _updatePactInList(result.data!);
        notifyListeners();
        return true;
      }

      final idx = _pacts.indexWhere((p) => p.id == cleanPactId);
      if (idx != -1) {
        final existing = _pacts[idx];
        String commitmentText = 'Milestone';
        final updatedCommitments = existing.commitments.map((c) {
          if (c.id == cleanCmtId) {
            commitmentText = c.text;
            return c.copyWith(
              isCompleted: isCompleted,
              completedAt: isCompleted ? DateTime.now() : null,
            );
          }
          return c;
        }).toList();

        final updatedHistory = [
          ...existing.history,
          PactHistoryEvent(
            id: 'hist_${cleanPactId}_${existing.history.length + 1}',
            pactId: cleanPactId,
            title: 'Progress update recorded',
            description: isCompleted
                ? '$currentDisplayName completed milestone: $commitmentText'
                : '$currentDisplayName updated progress on: $commitmentText',
            type: PactHistoryEventType.selfReported,
            actorDisplayName: currentDisplayName,
          ),
        ];

        final updatedPact = existing.copyWith(
          commitments: updatedCommitments,
          history: updatedHistory,
        );

        _updatePactInList(updatedPact);
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = 'Error updating commitment.';
      notifyListeners();
      return false;
    }
  }

  void _distributePacts(List<LearningPact> pacts) {
    final sanitized =
        pacts.where((p) => p.module == LearningPact.moduleScope).toList();
    final seen = <String>{};
    final unique = <LearningPact>[];
    for (final p in sanitized) {
      if (seen.add(p.id)) {
        unique.add(p);
      }
    }
    _pacts = unique;
  }

  void _updatePactInList(LearningPact updated) {
    final list = List<LearningPact>.of(_pacts);
    final idx = list.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
    } else {
      list.add(updated);
    }
    _pacts = list;
  }

  bool _isAuthorized() {
    final session = sessionController;
    if (session != null && session.phase != SessionPhase.signedIn) {
      return false;
    }
    return isLearningActivated;
  }

  void _onSessionCleared() {
    _pacts = const [];
    _status = LearningPactsViewStatus.accessDenied;
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
      'LearningPactsViewModel(status: ${_status.name}, tab: ${_activeTab.name}, pacts: ${_pacts.length})';
}
