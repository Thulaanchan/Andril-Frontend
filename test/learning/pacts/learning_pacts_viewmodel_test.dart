import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/pacts/domain/entities/learning_pact.dart';
import 'package:andril_mobile/features/learning/pacts/domain/repositories/i_learning_pacts_repository.dart';
import 'package:andril_mobile/features/learning/pacts/presentation/viewmodels/learning_pacts_viewmodel.dart';

class FakeSessionController extends ChangeNotifier
    implements SessionController {
  SessionPhase _stubPhase;
  final Set<VoidCallback> _clearers = {};

  FakeSessionController({SessionPhase phase = SessionPhase.signedIn})
      : _stubPhase = phase;

  @override
  SessionPhase get phase => _stubPhase;

  @override
  bool get moduleHomeAuthorized => false;

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clear) {
    _clearers.add(clear);
    return () => _clearers.remove(clear);
  }

  void triggerPrivateStateClearers() {
    for (final clearer in List.of(_clearers)) {
      clearer();
    }
  }

  void setPhase(SessionPhase phase) {
    _stubPhase = phase;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLearningPactsRepository implements ILearningPactsRepository {
  bool isBackendActivated;
  List<LearningPact> pacts;
  Completer<void>? delayCompleter;
  bool failNextOperation = false;
  LearningPactsFailureType failureType = LearningPactsFailureType.unknown;
  String? failureErrorMessage;

  _FakeLearningPactsRepository({
    List<LearningPact>? pacts,
  })  : isBackendActivated = true,
        pacts = pacts ?? [];

  @override
  Future<LearningPactsResult<List<LearningPact>>> getPacts() async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPactsViewModel.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    if (failNextOperation) {
      return LearningPactsResult.failure(
        errorMessage: failureErrorMessage ?? 'Failed to load pacts',
        failureType: failureType,
      );
    }
    return LearningPactsResult.success(pacts);
  }

  @override
  Future<LearningPactsResult<LearningPact>> getPactById(String pactId) async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPactsViewModel.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    final pact = pacts.where((p) => p.id == pactId).firstOrNull;
    if (pact == null) {
      return const LearningPactsResult.failure(
        errorMessage: 'Pact not found',
        failureType: LearningPactsFailureType.notFound,
      );
    }
    return LearningPactsResult.success(pact);
  }

  @override
  Future<LearningPactsResult<LearningPact>> proposePact({
    required String title,
    required String sharedGoal,
    required String partnerProfileId,
    required String partnerDisplayName,
    String? partnerAvatarUrl,
    String? duration,
    String? studyPlan,
    Iterable<String>? commitmentTexts,
  }) async {
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPactsViewModel.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    final newPact = LearningPact.propose(
      id: 'pact_${pacts.length + 1}',
      title: title,
      sharedGoal: sharedGoal,
      proposerProfileId: 'current_learner_prof',
      proposerDisplayName: 'Current Learner',
      partnerProfileId: partnerProfileId,
      partnerDisplayName: partnerDisplayName,
      partnerAvatarUrl: partnerAvatarUrl,
      duration: duration,
      studyPlan: studyPlan,
      commitmentTexts: commitmentTexts,
    );
    pacts.add(newPact);
    return LearningPactsResult.success(newPact);
  }

  @override
  Future<LearningPactsResult<LearningPact>> acceptPact(String pactId) async {
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPactsViewModel.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    final idx = pacts.indexWhere((p) => p.id == pactId);
    if (idx == -1) {
      return const LearningPactsResult.failure(
        errorMessage: 'Pact not found',
        failureType: LearningPactsFailureType.notFound,
      );
    }
    final existing = pacts[idx];
    final updatedParticipants = existing.participants.map((p) {
      if (p.participantProfileId == 'current_learner_prof') {
        return p.copyWith(
            decision: PactInvitationDecision.accepted,
            agreedAt: DateTime.now());
      }
      return p;
    }).toList();

    final allAccepted = updatedParticipants
        .every((p) => p.decision == PactInvitationDecision.accepted);
    final updated = existing.copyWith(
      participants: updatedParticipants,
      status:
          allAccepted ? LearningPactStatus.active : LearningPactStatus.pending,
    );
    pacts[idx] = updated;
    return LearningPactsResult.success(updated);
  }

  @override
  Future<LearningPactsResult<LearningPact>> declinePact(String pactId) async {
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPactsViewModel.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    final idx = pacts.indexWhere((p) => p.id == pactId);
    if (idx == -1) {
      return const LearningPactsResult.failure(
        errorMessage: 'Pact not found',
        failureType: LearningPactsFailureType.notFound,
      );
    }
    final existing = pacts[idx];
    final updatedParticipants = existing.participants.map((p) {
      if (p.participantProfileId == 'current_learner_prof') {
        return p.copyWith(decision: PactInvitationDecision.declined);
      }
      return p;
    }).toList();
    final updated = existing.copyWith(participants: updatedParticipants);
    pacts[idx] = updated;
    return LearningPactsResult.success(updated);
  }

  @override
  Future<LearningPactsResult<LearningPact>> cancelPact(String pactId) async {
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPactsViewModel.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    final idx = pacts.indexWhere((p) => p.id == pactId);
    if (idx == -1) {
      return const LearningPactsResult.failure(
        errorMessage: 'Pact not found',
        failureType: LearningPactsFailureType.notFound,
      );
    }
    final existing = pacts[idx];
    final updated = existing.copyWith(status: LearningPactStatus.cancelled);
    pacts[idx] = updated;
    return LearningPactsResult.success(updated);
  }

  @override
  Future<LearningPactsResult<LearningPact>> withdrawPact(String pactId) async {
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPactsViewModel.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    final idx = pacts.indexWhere((p) => p.id == pactId);
    if (idx == -1) {
      return const LearningPactsResult.failure(
        errorMessage: 'Pact not found',
        failureType: LearningPactsFailureType.notFound,
      );
    }
    final existing = pacts[idx];
    final updated = existing.copyWith(status: LearningPactStatus.cancelled);
    pacts[idx] = updated;
    return LearningPactsResult.success(updated);
  }

  @override
  Future<LearningPactsResult<LearningPact>> confirmCompletion(
      String pactId) async {
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPactsViewModel.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    final idx = pacts.indexWhere((p) => p.id == pactId);
    if (idx == -1) {
      return const LearningPactsResult.failure(
        errorMessage: 'Pact not found',
        failureType: LearningPactsFailureType.notFound,
      );
    }
    final existing = pacts[idx];
    final updatedParticipants = existing.participants.map((p) {
      if (p.participantProfileId == 'current_learner_prof') {
        return p.copyWith(completionConfirmed: true);
      }
      return p;
    }).toList();
    final allConfirmed =
        updatedParticipants.every((p) => p.completionConfirmed);
    final updated = existing.copyWith(
      participants: updatedParticipants,
      status: allConfirmed
          ? LearningPactStatus.completed
          : LearningPactStatus.active,
    );
    pacts[idx] = updated;
    return LearningPactsResult.success(updated);
  }

  @override
  Future<LearningPactsResult<LearningPact>> updateCommitmentProgress({
    required String pactId,
    required String commitmentId,
    required bool isCompleted,
  }) async {
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPactsViewModel.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    final idx = pacts.indexWhere((p) => p.id == pactId);
    if (idx == -1) {
      return const LearningPactsResult.failure(
        errorMessage: 'Pact not found',
        failureType: LearningPactsFailureType.notFound,
      );
    }
    final existing = pacts[idx];
    final updatedCommitments = existing.commitments.map((c) {
      if (c.id == commitmentId) {
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
        id: 'hist_${pactId}_${existing.history.length + 1}',
        pactId: pactId,
        title: 'Progress update recorded',
        description: isCompleted
            ? 'Milestone marked completed'
            : 'Milestone marked pending',
        type: PactHistoryEventType.selfReported,
        actorDisplayName: 'Current Learner',
      ),
    ];
    final updated = existing.copyWith(
      commitments: updatedCommitments,
      history: updatedHistory,
    );
    pacts[idx] = updated;
    return LearningPactsResult.success(updated);
  }
}

void main() {
  group('LearningPactsViewModel Tests', () {
    late FakeSessionController sessionController;
    late _FakeLearningPactsRepository repository;

    LearningPact createActivePact({String id = 'pact_active_1'}) {
      return LearningPact.create(
        id: id,
        title: 'Active Study Pact',
        sharedGoal: 'Complete course',
        proposerProfileId: 'current_learner_prof',
        proposerDisplayName: 'Current Learner',
        status: LearningPactStatus.active,
        participants: [
          PactParticipation(
            participantProfileId: 'current_learner_prof',
            participantDisplayName: 'Current Learner',
            decision: PactInvitationDecision.accepted,
          ),
          PactParticipation(
            participantProfileId: 'partner_prof',
            participantDisplayName: 'Partner Learner',
            decision: PactInvitationDecision.accepted,
          ),
        ],
        commitments: [
          PactCommitment(
              id: 'cmt_1', pactId: id, text: 'Milestone 1', isCompleted: false),
        ],
      );
    }

    LearningPact createIncomingInvitation({String id = 'pact_in_1'}) {
      return LearningPact.propose(
        id: id,
        title: 'Incoming Pact Proposal',
        sharedGoal: 'Learn Flutter',
        proposerProfileId: 'partner_prof',
        proposerDisplayName: 'Partner Learner',
        partnerProfileId: 'current_learner_prof',
        partnerDisplayName: 'Current Learner',
      );
    }

    LearningPact createOutgoingProposal({String id = 'pact_out_1'}) {
      return LearningPact.propose(
        id: id,
        title: 'Outgoing Pact Proposal',
        sharedGoal: 'Learn System Design',
        proposerProfileId: 'current_learner_prof',
        proposerDisplayName: 'Current Learner',
        partnerProfileId: 'partner_prof',
        partnerDisplayName: 'Partner Learner',
      );
    }

    setUp(() {
      sessionController = FakeSessionController(phase: SessionPhase.signedIn);
      repository = _FakeLearningPactsRepository();
    });

    test('initial state is clean and status is initial', () {
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      expect(vm.status, LearningPactsViewStatus.initial);
      expect(vm.activeTab, LearningPactsTab.active);
      expect(vm.activePacts, isEmpty);
      expect(vm.pendingPacts, isEmpty);
      expect(vm.historyPacts, isEmpty);
      vm.dispose();
    });

    test('fails closed with accessDenied when user is not signed in', () async {
      sessionController.setPhase(SessionPhase.signedOut);
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.status, LearningPactsViewStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      vm.dispose();
    });

    test('fails closed with accessDenied when isLearningActivated is false',
        () async {
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: false,
      );

      await vm.initialize();
      expect(vm.status, LearningPactsViewStatus.accessDenied);
      vm.dispose();
    });

    test(
        'initializes and categorizes active, pending incoming, and pending outgoing pacts',
        () async {
      repository.pacts = [
        createActivePact(),
        createIncomingInvitation(),
        createOutgoingProposal(),
      ];

      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.status, LearningPactsViewStatus.ready);
      expect(vm.activePactsCount, 1);
      expect(vm.pendingPactsCount, 2);
      expect(vm.incomingInvitations.length, 1);
      expect(vm.outgoingInvitations.length, 1);
      expect(vm.historyPactsCount, 0);
      vm.dispose();
    });

    test(
        'session revocation triggers private state clearer and purges private state',
        () async {
      repository.pacts = [createActivePact()];
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.activePactsCount, 1);

      // Revoke session
      sessionController.triggerPrivateStateClearers();

      expect(vm.allPacts, isEmpty);
      expect(vm.status, LearningPactsViewStatus.accessDenied);
      vm.dispose();
    });

    test('stale async epoch responses are discarded', () async {
      final completer1 = Completer<void>();
      repository.delayCompleter = completer1;

      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      final future1 = vm.initialize();
      // Start second request
      repository.delayCompleter = null;
      repository.pacts = [createActivePact()];
      final future2 = vm.initialize(force: true);

      await future2;
      expect(vm.activePactsCount, 1);

      // Now complete older delayed request
      completer1.complete();
      await future1;

      // Status should remain ready with the newer data
      expect(vm.activePactsCount, 1);
      vm.dispose();
    });

    test('tab switching notifies listeners and updates activeTab', () {
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.switchTab(LearningPactsTab.invitations);
      expect(vm.activeTab, LearningPactsTab.invitations);
      expect(notifyCount, 1);

      vm.switchTab(LearningPactsTab.history);
      expect(vm.activeTab, LearningPactsTab.history);
      expect(notifyCount, 2);

      // Switching to same tab is no-op
      vm.switchTab(LearningPactsTab.history);
      expect(notifyCount, 2);
      vm.dispose();
    });

    test('proposePact creates and appends pending pact proposal', () async {
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );
      await vm.initialize();

      final success = await vm.proposePact(
        title: 'New Study Pact',
        sharedGoal: 'Score 100 on quiz',
        partnerProfileId: 'partner_1',
        partnerDisplayName: 'Partner 1',
        commitmentTexts: ['Module 1', 'Module 2'],
      );

      expect(success, isTrue);
      expect(vm.pendingPactsCount, 1);
      expect(vm.outgoingInvitations.length, 1);
      vm.dispose();
    });

    test(
        'acceptPact enforces MUTUAL ACCEPTANCE: transitions to active when all accept',
        () async {
      final incoming = createIncomingInvitation(id: 'inv_1');
      repository.pacts = [incoming];

      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );
      await vm.initialize();
      expect(vm.activePactsCount, 0);
      expect(vm.incomingInvitations.length, 1);

      final ok = await vm.acceptPact('inv_1');
      expect(ok, isTrue);

      // Now both proposer and current learner have accepted
      expect(vm.activePactsCount, 1);
      expect(vm.incomingInvitations.length, 0);
      expect(vm.activePacts.first.isActive, isTrue);
      vm.dispose();
    });

    test(
        'declinePact records declined decision and keeps pact in pending/withdrawn state',
        () async {
      final incoming = createIncomingInvitation(id: 'inv_decline');
      repository.pacts = [incoming];

      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );
      await vm.initialize();

      final ok = await vm.declinePact('inv_decline');
      expect(ok, isTrue);
      expect(vm.activePactsCount, 0);

      final myPart = vm.allPacts.first.myParticipation('current_learner_prof');
      expect(myPart?.decision, PactInvitationDecision.declined);
      vm.dispose();
    });

    test('cancelPact succeeds for proposer and transitions status to cancelled',
        () async {
      final outgoing = createOutgoingProposal(id: 'out_cancel');
      repository.pacts = [outgoing];

      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );
      await vm.initialize();

      final ok = await vm.cancelPact('out_cancel');
      expect(ok, isTrue);
      expect(vm.historyPactsCount, 1);
      expect(vm.historyPacts.first.isCancelled, isTrue);
      vm.dispose();
    });

    test('withdrawPact allows active participant to end participation',
        () async {
      final active = createActivePact(id: 'active_withdraw');
      repository.pacts = [active];

      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );
      await vm.initialize();
      expect(vm.activePactsCount, 1);

      final ok = await vm.withdrawPact('active_withdraw');
      expect(ok, isTrue);
      expect(vm.activePactsCount, 0);
      expect(vm.historyPactsCount, 1);
      expect(vm.historyPacts.first.isCancelled, isTrue);
      vm.dispose();
    });

    test(
        'confirmCompletion marks participant confirmation and completes pact when all confirm',
        () async {
      final active = createActivePact(id: 'active_complete');
      // Partner already confirmed
      final partnerConfirmed = active.copyWith(
        participants: [
          active.participants[0],
          active.participants[1].copyWith(completionConfirmed: true),
        ],
      );
      repository.pacts = [partnerConfirmed];

      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );
      await vm.initialize();

      final ok = await vm.confirmCompletion('active_complete');
      expect(ok, isTrue);
      expect(vm.historyPactsCount, 1);
      expect(vm.historyPacts.first.isCompleted, isTrue);
      vm.dispose();
    });

    test('toggleCommitment updates self-reported milestone completion',
        () async {
      final active = createActivePact(id: 'active_cmt');
      repository.pacts = [active];

      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );
      await vm.initialize();

      expect(vm.activePacts.first.commitments.first.isCompleted, isFalse);

      final ok = await vm.toggleCommitment(
        pactId: 'active_cmt',
        commitmentId: 'cmt_1',
        isCompleted: true,
      );

      expect(ok, isTrue);
      expect(vm.activePacts.first.commitments.first.isCompleted, isTrue);
      expect(vm.activePacts.first.history.length, 1);
      expect(vm.activePacts.first.history.first.type,
          PactHistoryEventType.selfReported);
      vm.dispose();
    });
  });
}
