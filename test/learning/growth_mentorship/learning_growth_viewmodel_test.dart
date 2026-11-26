import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/domain/entities/learning_growth_evidence.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/domain/repositories/i_learning_growth_repository.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/presentation/viewmodels/learning_growth_viewmodel.dart';

class _FakeSessionController extends ChangeNotifier
    implements SessionController {
  SessionPhase _stubPhase;
  final Set<VoidCallback> _clearers = {};

  _FakeSessionController({SessionPhase phase = SessionPhase.signedIn})
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
    for (final c in List.of(_clearers)) {
      c();
    }
  }

  void setPhase(SessionPhase phase) {
    _stubPhase = phase;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGrowthRepository implements ILearningGrowthRepository {
  bool isBackendActivated = true;
  LearningGrowthSummary summary = const LearningGrowthSummary();
  List<LearningGrowthEvidence> evidenceList = [];
  List<LearningTrackedSkill> skillsList = [];
  Completer<void>? delayCompleter;
  bool shouldFail = false;
  LearningGrowthFailureType failureType = LearningGrowthFailureType.unknown;
  String? errorMessage;

  @override
  Future<LearningGrowthResult<LearningGrowthSummary>> getGrowthSummary() async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthViewModel.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    if (shouldFail) {
      return LearningGrowthResult.failure(
        errorMessage: errorMessage ?? 'Failed to load summary',
        failureType: failureType,
      );
    }
    return LearningGrowthResult.success(summary);
  }

  @override
  Future<LearningGrowthResult<List<LearningGrowthEvidence>>> getEvidenceList({
    LearningEvidenceKind? kindFilter,
    String? skillId,
  }) async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthViewModel.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    if (shouldFail) {
      return LearningGrowthResult.failure(
        errorMessage: errorMessage ?? 'Failed to load evidence',
        failureType: failureType,
      );
    }
    return LearningGrowthResult.success(evidenceList);
  }

  @override
  Future<LearningGrowthResult<LearningGrowthEvidence>> getEvidenceById(
    String evidenceId,
  ) async {
    final ev = evidenceList.where((e) => e.id == evidenceId).firstOrNull;
    if (ev != null) return LearningGrowthResult.success(ev);
    return const LearningGrowthResult.failure(
      errorMessage: 'Not found',
      failureType: LearningGrowthFailureType.notFound,
    );
  }

  @override
  Future<LearningGrowthResult<List<LearningTrackedSkill>>>
      getTrackedSkills() async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthViewModel.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    if (shouldFail) {
      return LearningGrowthResult.failure(
        errorMessage: errorMessage ?? 'Failed to load skills',
        failureType: failureType,
      );
    }
    return LearningGrowthResult.success(skillsList);
  }

  @override
  Future<LearningGrowthResult<LearningGrowthEvidence>>
      recordSelfReportedEvidence({
    required String title,
    required String description,
    Iterable<String>? skillIds,
    Iterable<String>? skillNames,
    String? sourceReference,
  }) async {
    final ev = LearningGrowthEvidence.recordSelfReport(
      id: 'ev_${evidenceList.length + 1}',
      accountId: 'acc_01',
      learningProfileId: 'prof_01',
      title: title,
      description: description,
      skillIds: skillIds,
      skillNames: skillNames,
      sourceReference: sourceReference,
    );
    evidenceList.insert(0, ev);
    return LearningGrowthResult.success(ev);
  }
}

void main() {
  late _FakeGrowthRepository repository;
  late _FakeSessionController sessionController;

  setUp(() {
    repository = _FakeGrowthRepository();
    sessionController = _FakeSessionController();
  });

  group('LearningGrowthViewModel - Auth and Activation Gates', () {
    test('denies access when session is signed out', () async {
      sessionController.setPhase(SessionPhase.signedOut);

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.status, LearningGrowthViewStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      expect(vm.errorMessage, contains('Authentication'));
    });

    test('denies access when learning profile is not activated', () async {
      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: false,
      );

      await vm.initialize();
      expect(vm.status, LearningGrowthViewStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
    });

    test('session state change to signed out revokes private state', () async {
      final ev = LearningGrowthEvidence(
        id: 'ev_1',
        accountId: 'acc',
        learningProfileId: 'prof',
        title: 'Test Evidence',
        description: 'Desc',
      );
      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        initialEvidence: [ev],
      );

      expect(vm.allEvidence.length, 1);
      sessionController.setPhase(SessionPhase.signedOut);

      expect(vm.status, LearningGrowthViewStatus.accessDenied);
      expect(vm.allEvidence, isEmpty);
      expect(vm.allSkills, isEmpty);
      expect(vm.summary.totalEvidenceCount, 0);
    });

    test('direct trigger of private state clearer clears all private data', () {
      final ev = LearningGrowthEvidence(
        id: 'ev_1',
        accountId: 'acc',
        learningProfileId: 'prof',
        title: 'Test Evidence',
        description: 'Desc',
      );
      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        initialEvidence: [ev],
      );

      expect(vm.allEvidence.isNotEmpty, isTrue);
      sessionController.triggerPrivateStateClearers();

      expect(vm.status, LearningGrowthViewStatus.accessDenied);
      expect(vm.allEvidence, isEmpty);
      expect(vm.allSkills, isEmpty);
    });
  });

  group('LearningGrowthViewModel - Repository Interaction & States', () {
    test('transitions to unavailableService when backend is disconnected',
        () async {
      repository.isBackendActivated = false;

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.status, LearningGrowthViewStatus.unavailableService);
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.errorMessage, LearningGrowthEvidence.disconnectedNotice);
    });

    test('transitions to error when repository fails with unknown error',
        () async {
      repository.shouldFail = true;
      repository.errorMessage = 'Network timeout';
      repository.failureType = LearningGrowthFailureType.unknown;

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.status, LearningGrowthViewStatus.error);
      expect(vm.errorMessage, 'Network timeout');
    });

    test('transitions to empty when no evidence and no skills exist', () async {
      repository.evidenceList = [];
      repository.skillsList = [];

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.status, LearningGrowthViewStatus.empty);
      expect(vm.isEmpty, isTrue);
      expect(vm.totalEvidenceCount, 0);
      expect(vm.trackedSkillsCount, 0);
    });

    test('transitions to ready when evidence exists', () async {
      final ev = LearningGrowthEvidence(
        id: 'ev_1',
        accountId: 'acc',
        learningProfileId: 'prof',
        kind: LearningEvidenceKind.verified,
        title: 'Clean Architecture Test',
        description: 'Verified unit test',
      );
      final skill = LearningTrackedSkill(
        id: 'sk_1',
        name: 'Architecture',
        category: 'Engineering',
        associatedEvidenceIds: ['ev_1'],
        sufficiencyStatus: EvidenceSufficiencyStatus.verifiedSource,
      );
      repository.evidenceList = [ev];
      repository.skillsList = [skill];

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.status, LearningGrowthViewStatus.ready);
      expect(vm.isReady, isTrue);
      expect(vm.totalEvidenceCount, 1);
      expect(vm.verifiedEvidenceCount, 1);
      expect(vm.selfReportedEvidenceCount, 0);
      expect(vm.trackedSkillsCount, 1);
    });

    test('epoch generation discards stale async responses', () async {
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      repository.delayCompleter = completer1;
      final future1 = vm.initialize();

      repository.delayCompleter = completer2;
      final future2 = vm.initialize(force: true);

      // Complete second first
      repository.evidenceList = [
        LearningGrowthEvidence(
          id: 'ev_fresh',
          accountId: 'acc',
          learningProfileId: 'prof',
          title: 'Fresh Evidence',
          description: 'Desc',
        ),
      ];
      completer2.complete();
      await future2;

      expect(vm.allEvidence.first.id, 'ev_fresh');

      // Now complete first request (stale epoch)
      repository.evidenceList = [];
      completer1.complete();
      await future1;

      // Stale response must be ignored
      expect(vm.allEvidence.first.id, 'ev_fresh');
    });
  });

  group('LearningGrowthViewModel - Tabs, Filters, and Actions', () {
    test('switches tabs and notifies listeners', () {
      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      expect(vm.activeTab, LearningGrowthTab.overview);
      var notified = false;
      vm.addListener(() => notified = true);

      vm.switchTab(LearningGrowthTab.evidence);
      expect(vm.activeTab, LearningGrowthTab.evidence);
      expect(notified, isTrue);

      vm.switchTab(LearningGrowthTab.skills);
      expect(vm.activeTab, LearningGrowthTab.skills);

      vm.switchTab(LearningGrowthTab.insights);
      expect(vm.activeTab, LearningGrowthTab.insights);
    });

    test('filters evidence by kind and search query', () {
      final evVerified = LearningGrowthEvidence(
        id: 'ev_1',
        accountId: 'acc',
        learningProfileId: 'prof',
        kind: LearningEvidenceKind.verified,
        title: 'Flutter Verification',
        description: 'Verified assessment',
        skillNames: ['Flutter'],
      );
      final evSelf = LearningGrowthEvidence(
        id: 'ev_2',
        accountId: 'acc',
        learningProfileId: 'prof',
        kind: LearningEvidenceKind.selfReported,
        title: 'Dart Practice',
        description: 'Self-guided study',
        skillNames: ['Dart'],
      );

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        initialEvidence: [evVerified, evSelf],
      );

      expect(vm.filteredEvidence.length, 2);

      // Filter by Verified
      vm.setKindFilter(LearningEvidenceKind.verified);
      expect(vm.filteredEvidence.length, 1);
      expect(vm.filteredEvidence.first.id, 'ev_1');

      // Filter by SelfReported
      vm.setKindFilter(LearningEvidenceKind.selfReported);
      expect(vm.filteredEvidence.length, 1);
      expect(vm.filteredEvidence.first.id, 'ev_2');

      // Clear filter
      vm.setKindFilter(null);
      expect(vm.filteredEvidence.length, 2);

      // Search query filter
      vm.setSearchQuery('Dart');
      expect(vm.filteredEvidence.length, 1);
      expect(vm.filteredEvidence.first.id, 'ev_2');

      vm.clearSearch();
      expect(vm.filteredEvidence.length, 2);
    });

    test('filters skills by search query', () {
      final sk1 = LearningTrackedSkill(
        id: 'sk_1',
        name: 'Flutter Architecture',
        category: 'Mobile',
      );
      final sk2 = LearningTrackedSkill(
        id: 'sk_2',
        name: 'Kubernetes',
        category: 'DevOps',
      );

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        initialSkills: [sk1, sk2],
      );

      expect(vm.filteredSkills.length, 2);

      vm.setSearchQuery('mobile');
      expect(vm.filteredSkills.length, 1);
      expect(vm.filteredSkills.first.name, 'Flutter Architecture');

      vm.setSearchQuery('DevOps');
      expect(vm.filteredSkills.length, 1);
      expect(vm.filteredSkills.first.name, 'Kubernetes');
    });

    test('records self-reported evidence and updates skills and summary',
        () async {
      final skill = LearningTrackedSkill(
        id: 'flutter',
        name: 'Flutter',
        category: 'Mobile',
        associatedEvidenceIds: [],
        sufficiencyStatus: EvidenceSufficiencyStatus.insufficientEvidence,
      );

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        initialSkills: [skill],
      );

      expect(vm.totalEvidenceCount, 0);
      expect(vm.allSkills.first.sufficiencyStatus,
          EvidenceSufficiencyStatus.insufficientEvidence);

      final success = await vm.recordSelfReportedEvidence(
        title: 'New Widget Tree',
        description: 'Optimized build passes',
        skillIds: ['flutter'],
        skillNames: ['Flutter'],
        sourceReference: 'Code Review',
      );

      expect(success, isTrue);
      expect(vm.totalEvidenceCount, 1);
      expect(vm.selfReportedEvidenceCount, 1);
      expect(vm.summary.totalEvidenceCount, 1);

      // Associated skill sufficiency updated to selfReportedOnly
      expect(vm.allSkills.first.associatedEvidenceIds.length, 1);
      expect(vm.allSkills.first.sufficiencyStatus,
          EvidenceSufficiencyStatus.selfReportedOnly);
    });

    test('rejects recordSelfReportedEvidence when title or desc is empty',
        () async {
      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      final success = await vm.recordSelfReportedEvidence(
        title: '   ',
        description: 'Valid',
      );
      expect(success, isFalse);
      expect(vm.errorMessage, contains('required'));
    });
  });
}
