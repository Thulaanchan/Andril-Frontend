import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/circles/domain/entities/learning_circle.dart';
import 'package:andril_mobile/features/learning/circles/domain/repositories/i_learning_circles_repository.dart';
import 'package:andril_mobile/features/learning/circles/presentation/viewmodels/learning_circles_viewmodel.dart';

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

class _FakeLearningCirclesRepository implements ILearningCirclesRepository {
  bool isBackendActivated;
  List<LearningCircle> circles;
  List<LearningCircle> myCircles;
  Completer<void>? delayCompleter;
  bool failNextOperation = false;
  String? failureErrorMessage;

  _FakeLearningCirclesRepository({
    this.isBackendActivated = true,
    List<LearningCircle>? circles,
    List<LearningCircle>? myCircles,
  })  : circles = circles ?? [],
        myCircles = myCircles ?? [];

  @override
  Future<LearningCirclesResult<List<LearningCircle>>> getCircles({
    String? category,
    String? query,
  }) async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: LearningCirclesViewModel.disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }
    if (failNextOperation) {
      return LearningCirclesResult.failure(
        errorMessage: failureErrorMessage ?? 'Failed to load discover circles',
        failureType: LearningCirclesFailureType.unknown,
      );
    }
    return LearningCirclesResult.success(circles);
  }

  @override
  Future<LearningCirclesResult<List<LearningCircle>>> getMyCircles() async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: LearningCirclesViewModel.disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }
    if (failNextOperation) {
      return LearningCirclesResult.failure(
        errorMessage: failureErrorMessage ?? 'Failed to load my circles',
        failureType: LearningCirclesFailureType.unknown,
      );
    }
    return LearningCirclesResult.success(myCircles);
  }

  @override
  Future<LearningCirclesResult<LearningCircle>> joinCircle(
      String circleId) async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: LearningCirclesViewModel.disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }
    final idx = circles.indexWhere((c) => c.id == circleId);
    if (idx == -1) {
      return const LearningCirclesResult.failure(
        errorMessage: 'Circle not found',
        failureType: LearningCirclesFailureType.notFound,
      );
    }
    final existing = circles[idx];
    final joined = existing.copyWith(
      membershipRole: CircleMembershipRole.member,
      memberCount: existing.memberCount + 1,
    );
    circles[idx] = joined;
    myCircles.add(joined);
    return LearningCirclesResult.success(joined);
  }

  @override
  Future<LearningCirclesResult<void>> leaveCircle(String circleId) async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: LearningCirclesViewModel.disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }
    final myIdx = myCircles.indexWhere((c) => c.id == circleId);
    if (myIdx != -1) {
      myCircles.removeAt(myIdx);
    }
    final cIdx = circles.indexWhere((c) => c.id == circleId);
    if (cIdx != -1) {
      final existing = circles[cIdx];
      circles[cIdx] = existing.copyWith(
        membershipRole: CircleMembershipRole.none,
        memberCount: (existing.memberCount - 1).clamp(0, 9999),
      );
    }
    return const LearningCirclesResult.success(null);
  }

  @override
  Future<LearningCirclesResult<LearningCircle>> createCircle({
    required String name,
    required String description,
    required String category,
    String? initialGoalText,
  }) async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: LearningCirclesViewModel.disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }
    final newCircle = LearningCircle.create(
      id: 'circle_${circles.length + 1}',
      name: name,
      description: description,
      category: category,
      facilitatorProfileId: 'current_prof',
      facilitatorDisplayName: 'Current User',
      memberCount: 1,
      membershipRole: CircleMembershipRole.facilitator,
      goals: initialGoalText != null && initialGoalText.trim().isNotEmpty
          ? [
              CircleSharedGoal(
                id: 'goal_1',
                circleId: 'circle_${circles.length + 1}',
                text: initialGoalText.trim(),
                progressPercent: 0,
              )
            ]
          : const [],
    );
    circles.add(newCircle);
    myCircles.add(newCircle);
    return LearningCirclesResult.success(newCircle);
  }

  @override
  Future<LearningCirclesResult<CircleSharedGoal>> addSharedGoal({
    required String circleId,
    required String goalText,
  }) async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: LearningCirclesViewModel.disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }
    final goal = CircleSharedGoal(
      id: 'goal_${DateTime.now().microsecondsSinceEpoch}',
      circleId: circleId,
      text: goalText,
      progressPercent: 0,
    );
    return LearningCirclesResult.success(goal);
  }

  @override
  Future<LearningCirclesResult<CircleSharedGoal>> updateGoalProgress({
    required String circleId,
    required String goalId,
    required int progressPercent,
  }) async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: LearningCirclesViewModel.disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }
    final updated = CircleSharedGoal(
      id: goalId,
      circleId: circleId,
      text: 'Updated goal',
      progressPercent: progressPercent,
    );
    return LearningCirclesResult.success(updated);
  }
}

void main() {
  late FakeSessionController fakeSession;
  late _FakeLearningCirclesRepository fakeRepo;
  late LearningCircle sampleCircle1;
  late LearningCircle sampleCircle2;
  late LearningCircle sampleMyCircle;

  setUp(() {
    fakeSession = FakeSessionController(phase: SessionPhase.signedIn);

    sampleCircle1 = LearningCircle.create(
      id: 'circle_flutter',
      name: 'Flutter Enthusiasts',
      description: 'Building modern cross-platform apps with Dart.',
      category: 'Development',
      facilitatorProfileId: 'fac_1',
      facilitatorDisplayName: 'Ada Lovelace',
      memberCount: 12,
      membershipRole: CircleMembershipRole.none,
      goals: [
        CircleSharedGoal(
          id: 'goal_f1',
          circleId: 'circle_flutter',
          text: 'Master state management',
          progressPercent: 60,
        ),
      ],
    );

    sampleCircle2 = LearningCircle.create(
      id: 'circle_design',
      name: 'UI/UX Design Circle',
      description: 'Figma prototypes and accessible design systems.',
      category: 'Design',
      facilitatorProfileId: 'fac_2',
      facilitatorDisplayName: 'Grace Hopper',
      memberCount: 8,
      membershipRole: CircleMembershipRole.none,
    );

    sampleMyCircle = LearningCircle.create(
      id: 'circle_ai',
      name: 'AI Study Group',
      description: 'Exploring machine learning concepts.',
      category: 'Data Science',
      facilitatorProfileId: 'current_prof',
      facilitatorDisplayName: 'Current User',
      memberCount: 5,
      membershipRole: CircleMembershipRole.facilitator,
      goals: [
        CircleSharedGoal(
          id: 'goal_ai1',
          circleId: 'circle_ai',
          text: 'Read attention paper',
          progressPercent: 100,
        ),
      ],
    );

    fakeRepo = _FakeLearningCirclesRepository(
      isBackendActivated: true,
      circles: [sampleCircle1, sampleCircle2],
      myCircles: [sampleMyCircle],
    );
  });

  group('LearningCirclesViewModel - Security & Fail-Closed Authorization', () {
    test('denies access when session is unauthenticated (signedOut)', () async {
      fakeSession.setPhase(SessionPhase.signedOut);
      final vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      await vm.initialize();

      expect(vm.status, LearningCirclesViewStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      expect(
          vm.errorMessage,
          contains(
              'Authentication and an activated Learning profile are required'));
      expect(vm.allDiscoverCircles, isEmpty);
      expect(vm.allMyCircles, isEmpty);
    });

    test('denies access when learning profile is not activated', () async {
      final vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: fakeSession,
        isLearningActivated: false,
      );

      await vm.initialize();

      expect(vm.status, LearningCirclesViewStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
    });

    test(
        'session revocation triggers private state clearer and purges circle state',
        () async {
      final vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCircles: [sampleCircle1, sampleMyCircle],
      );

      expect(vm.discoverCount, 2);
      expect(vm.myCirclesCount, 1);

      fakeSession.triggerPrivateStateClearers();

      expect(vm.discoverCount, 0);
      expect(vm.myCirclesCount, 0);
      expect(vm.status, LearningCirclesViewStatus.accessDenied);
    });

    test('session state change to signedOut purges circles', () async {
      final vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCircles: [sampleCircle1, sampleMyCircle],
      );

      fakeSession.setPhase(SessionPhase.signedOut);

      expect(vm.discoverCount, 0);
      expect(vm.myCirclesCount, 0);
      expect(vm.status, LearningCirclesViewStatus.accessDenied);
    });

    test('filters out any item with non-learning module scope', () {
      final invalidCircle = LearningCircle.create(
        id: 'c_foreign',
        name: 'Foreign Circle',
        description: 'From another module',
        category: 'Development',
        facilitatorProfileId: 'fac_9',
        facilitatorDisplayName: 'Foreign Facilitator',
        memberCount: 3,
        membershipRole: CircleMembershipRole.none,
        module: 'dating',
      );

      final vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCircles: [sampleCircle1, invalidCircle],
      );

      expect(vm.allDiscoverCircles.length, 1);
      expect(vm.allDiscoverCircles.first.id, sampleCircle1.id);
    });
  });

  group('LearningCirclesViewModel - Lifecycle & Initialization', () {
    test('initializes successfully into ready status when circles exist',
        () async {
      final vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      expect(vm.status, LearningCirclesViewStatus.initial);

      await vm.initialize();

      expect(vm.status, LearningCirclesViewStatus.ready);
      expect(vm.isReady, isTrue);
      expect(vm.discoverCount, 3);
      expect(vm.myCirclesCount, 1);
      expect(vm.errorMessage, isNull);
    });

    test(
        'initializes into empty status when both discover and myCircles are empty',
        () async {
      fakeRepo.circles.clear();
      fakeRepo.myCircles.clear();

      final vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      await vm.initialize();

      expect(vm.status, LearningCirclesViewStatus.empty);
      expect(vm.isEmpty, isTrue);
      expect(vm.discoverCount, 0);
      expect(vm.myCirclesCount, 0);
    });

    test('transitions to unavailableService when backend is deactivated',
        () async {
      fakeRepo.isBackendActivated = false;

      final vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      await vm.initialize();

      expect(vm.status, LearningCirclesViewStatus.unavailableService);
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.errorMessage,
          contains(LearningCirclesViewModel.disconnectedNotice));
    });

    test('transitions to error status on unexpected repository failure',
        () async {
      fakeRepo.failNextOperation = true;
      fakeRepo.failureErrorMessage = 'Database connection failed';

      final vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      await vm.initialize();

      expect(vm.status, LearningCirclesViewStatus.error);
      expect(vm.errorMessage, 'Database connection failed');
    });

    test('stale async responses are discarded via epoch counter', () async {
      final completer = Completer<void>();
      fakeRepo.delayCompleter = completer;

      final vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      final initFuture = vm.initialize();
      expect(vm.isLoading, isTrue);

      // Trigger session clearer to increment epoch
      fakeSession.triggerPrivateStateClearers();

      // Complete async operation
      completer.complete();
      await initFuture;

      // Status must remain accessDenied from clearer, NOT overridden by late response
      expect(vm.status, LearningCirclesViewStatus.accessDenied);
      expect(vm.discoverCount, 0);
    });
  });

  group('LearningCirclesViewModel - Navigation, Search & Category Filters', () {
    late LearningCirclesViewModel vm;

    setUp(() async {
      vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCircles: [sampleCircle1, sampleCircle2, sampleMyCircle],
      );
    });

    test('switches active tabs correctly', () {
      expect(vm.activeTab, LearningCirclesTab.discover);

      vm.switchTab(LearningCirclesTab.myCircles);
      expect(vm.activeTab, LearningCirclesTab.myCircles);

      vm.switchTab(LearningCirclesTab.discover);
      expect(vm.activeTab, LearningCirclesTab.discover);
    });

    test(
        'filters discover circles by keyword in name, description, facilitator or goals',
        () {
      vm.setSearchQuery('Dart');
      expect(vm.filteredDiscoverCircles.length, 1);
      expect(vm.filteredDiscoverCircles.first.id, 'circle_flutter');

      vm.setSearchQuery('Lovelace');
      expect(vm.filteredDiscoverCircles.length, 1);
      expect(vm.filteredDiscoverCircles.first.id, 'circle_flutter');

      vm.setSearchQuery('state management');
      expect(vm.filteredDiscoverCircles.length, 1);
      expect(vm.filteredDiscoverCircles.first.id, 'circle_flutter');

      vm.setSearchQuery('Figma');
      expect(vm.filteredDiscoverCircles.length, 1);
      expect(vm.filteredDiscoverCircles.first.id, 'circle_design');

      vm.clearSearch();
      expect(vm.filteredDiscoverCircles.length, 3);
    });

    test('filters circles by category', () {
      vm.setCategory('Design');
      expect(vm.filteredDiscoverCircles.length, 1);
      expect(vm.filteredDiscoverCircles.first.id, 'circle_design');

      vm.setCategory('All');
      expect(vm.filteredDiscoverCircles.length, 3);
    });

    test('filters my circles correctly by search query', () {
      vm.switchTab(LearningCirclesTab.myCircles);
      expect(vm.filteredMyCircles.length, 1);

      vm.setSearchQuery('attention');
      expect(vm.filteredMyCircles.length, 1);
      expect(vm.filteredMyCircles.first.id, 'circle_ai');

      vm.setSearchQuery('flutter');
      expect(vm.filteredMyCircles.length, 0);
    });
  });

  group('LearningCirclesViewModel - Actions & State Mutations', () {
    late LearningCirclesViewModel vm;

    setUp(() {
      vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCircles: [sampleCircle1, sampleCircle2, sampleMyCircle],
      );
    });

    test('joinCircle successfully updates role and membership list', () async {
      expect(vm.allMyCircles.any((c) => c.id == 'circle_flutter'), isFalse);
      expect(sampleCircle1.memberCount, 12);

      final success = await vm.joinCircle('circle_flutter');

      expect(success, isTrue);
      expect(vm.allMyCircles.any((c) => c.id == 'circle_flutter'), isTrue);
      final updated =
          vm.allMyCircles.firstWhere((c) => c.id == 'circle_flutter');
      expect(updated.membershipRole, CircleMembershipRole.member);
      expect(updated.memberCount, 13);
    });

    test('leaveCircle successfully updates role and membership list', () async {
      expect(vm.allMyCircles.any((c) => c.id == 'circle_ai'), isTrue);

      final success = await vm.leaveCircle('circle_ai');

      expect(success, isTrue);
      expect(vm.allMyCircles.any((c) => c.id == 'circle_ai'), isFalse);
    });

    test('in-flight operation lock prevents concurrent calls for same circleId',
        () async {
      final completer = Completer<void>();
      fakeRepo.delayCompleter = completer;

      final f1 = vm.joinCircle('circle_flutter');
      expect(vm.isOperationInProgress('circle_flutter'), isTrue);

      final f2 = vm.joinCircle('circle_flutter');
      final res2 = await f2;
      expect(res2, isFalse); // rejected due to active lock

      completer.complete();
      final res1 = await f1;
      expect(res1, isTrue);
      expect(vm.isOperationInProgress('circle_flutter'), isFalse);
    });

    test(
        'createCircle creates circle and distributes to discover and myCircles',
        () async {
      final success = await vm.createCircle(
        name: 'Kotlin Multiplatform',
        description: 'Cross platform mobile logic sharing.',
        category: 'Development',
        initialGoalText: 'Complete shared networking layer',
      );

      expect(success, isTrue);
      final createdInMy =
          vm.allMyCircles.firstWhere((c) => c.name == 'Kotlin Multiplatform');
      expect(createdInMy.membershipRole, CircleMembershipRole.facilitator);
      expect(createdInMy.goals.length, 1);
      expect(createdInMy.goals.first.text, 'Complete shared networking layer');
      expect(createdInMy.goals.first.progressPercent, 0);
    });

    test('createCircle validates required name and description', () async {
      final res1 = await vm.createCircle(
        name: '   ',
        description: 'valid desc',
        category: 'Development',
      );
      expect(res1, isFalse);
      expect(vm.errorMessage, contains('Name and description are required'));

      final res2 = await vm.createCircle(
        name: 'valid name',
        description: '',
        category: 'Development',
      );
      expect(res2, isFalse);
      expect(vm.errorMessage, contains('Name and description are required'));
    });

    test('addSharedGoal adds a collaborative target to the circle', () async {
      final success = await vm.addSharedGoal(
        circleId: 'circle_flutter',
        goalText: 'Ship responsive UI to Google Play',
      );

      expect(success, isTrue);
      final circle =
          vm.allDiscoverCircles.firstWhere((c) => c.id == 'circle_flutter');
      expect(circle.goals.length, 2);
      expect(
          circle.goals
              .any((g) => g.text == 'Ship responsive UI to Google Play'),
          isTrue);
    });

    test('updateGoalProgress updates progressPercent within 0..100 range',
        () async {
      final success = await vm.updateGoalProgress(
        circleId: 'circle_flutter',
        goalId: 'goal_f1',
        progressPercent: 85,
      );

      expect(success, isTrue);
      final circle =
          vm.allDiscoverCircles.firstWhere((c) => c.id == 'circle_flutter');
      final goal = circle.goals.firstWhere((g) => g.id == 'goal_f1');
      expect(goal.progressPercent, 85);
    });

    test('updateGoalProgress rejects invalid progress values (< 0 or > 100)',
        () async {
      final res1 = await vm.updateGoalProgress(
        circleId: 'circle_flutter',
        goalId: 'goal_f1',
        progressPercent: -5,
      );
      expect(res1, isFalse);

      final res2 = await vm.updateGoalProgress(
        circleId: 'circle_flutter',
        goalId: 'goal_f1',
        progressPercent: 105,
      );
      expect(res2, isFalse);
    });

    test('actions are denied when user is not authorized', () async {
      fakeSession.setPhase(SessionPhase.signedOut);

      final joinRes = await vm.joinCircle('circle_flutter');
      expect(joinRes, isFalse);

      final leaveRes = await vm.leaveCircle('circle_ai');
      expect(leaveRes, isFalse);

      final createRes = await vm.createCircle(
        name: 'Denied Circle',
        description: 'Should fail',
        category: 'Development',
      );
      expect(createRes, isFalse);

      final addGoalRes = await vm.addSharedGoal(
        circleId: 'circle_flutter',
        goalText: 'Should fail',
      );
      expect(addGoalRes, isFalse);

      final updateGoalRes = await vm.updateGoalProgress(
        circleId: 'circle_flutter',
        goalId: 'goal_f1',
        progressPercent: 50,
      );
      expect(updateGoalRes, isFalse);
    });
  });
}
