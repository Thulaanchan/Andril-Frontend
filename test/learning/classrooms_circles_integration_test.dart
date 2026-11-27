import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/dependencies/registrations/learning/learning_dependencies.dart';
import 'package:andril_mobile/app/router/learning_router.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/circles/domain/entities/learning_circle.dart';
import 'package:andril_mobile/features/learning/circles/domain/repositories/i_learning_circles_repository.dart';
import 'package:andril_mobile/features/learning/circles/presentation/screens/learning_circles_hub_screen.dart';
import 'package:andril_mobile/features/learning/circles/presentation/viewmodels/learning_circles_viewmodel.dart';
import 'package:andril_mobile/features/learning/classrooms/domain/entities/classroom_join_request.dart';
import 'package:andril_mobile/features/learning/classrooms/domain/entities/learning_classroom.dart';
import 'package:andril_mobile/features/learning/classrooms/group_contracts/learning_group_contract.dart';
import 'package:andril_mobile/features/learning/classrooms/presentation/screens/learning_classrooms_hub_screen.dart';
import 'package:andril_mobile/features/learning/classrooms/presentation/widgets/create_classroom_dialog.dart';
import 'package:andril_mobile/features/learning/classrooms/presentation/widgets/host_classroom_requests_dialog.dart';

class _MockSessionController extends ChangeNotifier
    implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  bool _isActivated = true;
  final List<VoidCallback> _stateClearers = [];

  @override
  SessionPhase get phase => _phase;

  @override
  bool get moduleHomeAuthorized => _isActivated;

  @override
  bool get supportsBackend => true;

  @override
  String? get subject => 'prof_test_learner_01';

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) {
    _stateClearers.add(clearer);
    return () => _stateClearers.remove(clearer);
  }

  void revokeSession() {
    _phase = SessionPhase.signedOut;
    _isActivated = false;
    for (final clearer in List.of(_stateClearers)) {
      clearer();
    }
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCirclesRepo implements ILearningCirclesRepository {
  List<LearningCircle> circles;

  _FakeCirclesRepo({List<LearningCircle>? initial})
      : circles = initial ??
            [
              LearningCircle.create(
                id: 'circle_flutter_arch',
                name: 'Flutter Architecture Circle',
                description: 'Study group on clean code and design patterns.',
                category: 'Programming',
                facilitatorProfileId: 'prof_mentor_01',
                facilitatorDisplayName: 'Mentor One',
                memberCount: 5,
                membershipRole: CircleMembershipRole.none,
                goals: [
                  CircleSharedGoal(
                    id: 'goal_1',
                    circleId: 'circle_flutter_arch',
                    text: 'Finish Architecture Book',
                    progressPercent: 40,
                  ),
                ],
              ),
              LearningCircle.create(
                id: 'circle_ux_collab',
                name: 'UI/UX Design Systems',
                description: 'Collaborative Figma and Flutter tokens study.',
                category: 'Design',
                facilitatorProfileId: 'prof_test_learner_01',
                facilitatorDisplayName: 'Test Learner',
                memberCount: 3,
                membershipRole: CircleMembershipRole.facilitator,
                goals: [
                  CircleSharedGoal(
                    id: 'goal_2',
                    circleId: 'circle_ux_collab',
                    text: 'Publish Token Spec',
                    progressPercent: 100,
                  ),
                ],
              ),
            ];

  @override
  Future<LearningCirclesResult<List<LearningCircle>>> getCircles({
    String? category,
    String? query,
  }) async {
    var list = circles.where((c) => c.isDiscoverable).toList();
    if (category != null && category.toLowerCase() != 'all') {
      list = list
          .where((c) => c.category.toLowerCase() == category.toLowerCase())
          .toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q))
          .toList();
    }
    return LearningCirclesResult.success(list);
  }

  @override
  Future<LearningCirclesResult<List<LearningCircle>>> getMyCircles() async {
    return LearningCirclesResult.success(
        circles.where((c) => c.isMember).toList());
  }

  @override
  Future<LearningCirclesResult<LearningCircle>> createCircle({
    required String name,
    required String description,
    required String category,
    String? initialGoalText,
  }) async {
    final id = 'circle_${circles.length + 1}';
    final goals = <CircleSharedGoal>[];
    if (initialGoalText != null && initialGoalText.isNotEmpty) {
      goals.add(CircleSharedGoal(
        id: 'goal_${id}_1',
        circleId: id,
        text: initialGoalText,
        progressPercent: 0,
      ));
    }
    final created = LearningCircle.create(
      id: id,
      name: name,
      description: description,
      category: category,
      facilitatorProfileId: 'prof_test_learner_01',
      facilitatorDisplayName: 'Test Learner',
      memberCount: 1,
      membershipRole: CircleMembershipRole.facilitator,
      goals: goals,
    );
    circles.add(created);
    return LearningCirclesResult.success(created);
  }

  @override
  Future<LearningCirclesResult<LearningCircle>> joinCircle(
      String circleId) async {
    final idx = circles.indexWhere((c) => c.id == circleId);
    if (idx == -1) {
      return const LearningCirclesResult.failure(
        failureType: LearningCirclesFailureType.notFound,
        errorMessage: 'Circle not found',
      );
    }
    final current = circles[idx];
    final updated = current.copyWith(
      membershipRole: CircleMembershipRole.member,
      memberCount: current.memberCount + 1,
    );
    circles[idx] = updated;
    return LearningCirclesResult.success(updated);
  }

  @override
  Future<LearningCirclesResult<bool>> leaveCircle(String circleId) async {
    final idx = circles.indexWhere((c) => c.id == circleId);
    if (idx == -1) {
      return const LearningCirclesResult.failure(
        failureType: LearningCirclesFailureType.notFound,
        errorMessage: 'Circle not found',
      );
    }
    final current = circles[idx];
    final updated = current.copyWith(
      membershipRole: CircleMembershipRole.none,
      memberCount: (current.memberCount - 1).clamp(0, 9999),
    );
    circles[idx] = updated;
    return const LearningCirclesResult.success(true);
  }

  @override
  Future<LearningCirclesResult<CircleSharedGoal>> addSharedGoal({
    required String circleId,
    required String goalText,
  }) async {
    final goal = CircleSharedGoal(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
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
    final goal = CircleSharedGoal(
      id: goalId,
      circleId: circleId,
      text: 'Updated goal',
      progressPercent: progressPercent,
    );
    return LearningCirclesResult.success(goal);
  }
}

void main() {
  group('Task 06-04 — Classrooms & Circles Integration Suite', () {
    test('1. Learning Group contract verifies module and group kind isolation',
        () {
      expect(LearningGroupContract.module, 'learning');
      expect(LearningGroupContract.groupKind, GroupKind.classroom);
      expect(
          LearningGroupContract.isCompatible('learning', GroupKind.classroom),
          isTrue);
      expect(LearningGroupContract.isCompatible('hobbies', GroupKind.club),
          isFalse);
      expect(LearningGroupContract.isCompatible('social', GroupKind.zone),
          isFalse);
    });

    testWidgets(
        '2. Classroom creation dialog validates inputs and creates host classroom',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      LearningClassroom? createdClassroom;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  CreateClassroomDialog.show(
                    ctx,
                    onCreate: ({
                      required String name,
                      required String description,
                      required String category,
                      required ClassroomPrivacy privacy,
                      int? capacity,
                      List<String> tags = const [],
                    }) async {
                      createdClassroom = LearningClassroom.create(
                        id: 'cls_new_01',
                        name: name,
                        description: description,
                        category: category,
                        privacy: privacy,
                        capacity: capacity,
                        hostProfileId: 'prof_test_learner_01',
                        hostDisplayName: 'Test Learner',
                        membershipStatus: ClassroomMembershipStatus.host,
                        tags: tags,
                      );
                      return true;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Create Classroom'), findsOneWidget);

      // Verify form validation on empty submit
      await tester
          .ensureVisible(find.byKey(const ValueKey('btn_submit_classroom')));
      await tester.tap(find.byKey(const ValueKey('btn_submit_classroom')));
      await tester.pumpAndSettle();
      expect(find.text('Classroom name is required'), findsOneWidget);

      // Fill in valid classroom details
      await tester.enterText(
        find.byKey(const ValueKey('input_classroom_name')),
        'Advanced Dart Concurrency',
      );
      await tester.enterText(
        find.byKey(const ValueKey('input_classroom_desc')),
        'Deep dive into Dart isolates, streams, and async patterns.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('input_classroom_capacity')),
        '30',
      );
      await tester.enterText(
        find.byKey(const ValueKey('input_classroom_tags')),
        'Dart, Isolates, Concurrency',
      );

      await tester
          .ensureVisible(find.byKey(const ValueKey('btn_submit_classroom')));
      await tester.tap(find.byKey(const ValueKey('btn_submit_classroom')));
      await tester.pumpAndSettle();

      expect(createdClassroom, isNotNull);
      expect(createdClassroom!.name, 'Advanced Dart Concurrency');
      expect(createdClassroom!.capacity, 30);
      expect(createdClassroom!.tags, ['Dart', 'Isolates', 'Concurrency']);
      expect(
          createdClassroom!.membershipStatus, ClassroomMembershipStatus.host);
      expect(createdClassroom!.hostProfileId, 'prof_test_learner_01');
    });

    testWidgets(
        '3. Host classroom admission requests dialog allows host to approve and decline applicants',
        (tester) async {
      final sampleClassroom = LearningClassroom.create(
        id: 'cls_hosted_01',
        name: 'Mobile Architecture Labs',
        description: 'Hosted workshop series.',
        category: 'Programming',
        privacy: ClassroomPrivacy.requestToJoin,
        memberCount: 10,
        hostProfileId: 'prof_test_learner_01',
        hostDisplayName: 'Test Learner',
        membershipStatus: ClassroomMembershipStatus.host,
      );

      final requests = [
        ClassroomJoinRequest.create(
          requestId: 'req_01',
          classroomId: 'cls_hosted_01',
          applicantProfileId: 'prof_applicant_alice',
          note: 'Excited to learn architecture patterns!',
        ),
        ClassroomJoinRequest.create(
          requestId: 'req_02',
          classroomId: 'cls_hosted_01',
          applicantProfileId: 'prof_applicant_bob',
        ),
      ];

      ClassroomJoinRequest? approvedRequest;
      ClassroomJoinRequest? declinedRequest;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  HostClassroomRequestsDialog.show(
                    ctx,
                    classroom: sampleClassroom,
                    pendingRequests: requests,
                    onApprove: (req) => approvedRequest = req,
                    onDecline: (req) => declinedRequest = req,
                  );
                },
                child: const Text('Review Requests'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Review Requests'));
      await tester.pumpAndSettle();

      expect(find.text('Admission Requests'), findsOneWidget);
      expect(find.text('Applicant: prof_applicant_alice'), findsOneWidget);
      expect(find.text('"Excited to learn architecture patterns!"'),
          findsOneWidget);
      expect(find.text('Applicant: prof_applicant_bob'), findsOneWidget);

      // Approve Alice
      await tester.tap(find.byKey(const ValueKey('btn_approve_req_01')));
      await tester.pumpAndSettle();
      expect(approvedRequest, isNotNull);
      expect(approvedRequest!.requestId, 'req_01');

      // Reopen dialog and decline Bob
      await tester.tap(find.text('Review Requests'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('btn_decline_req_02')));
      await tester.pumpAndSettle();
      expect(declinedRequest, isNotNull);
      expect(declinedRequest!.requestId, 'req_02');
    });

    testWidgets(
        '4. ClassroomsHubScreen displays create action and integrates host workflow',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: LearningClassroomsHubScreen(
            currentUserId: 'current_user_profile_id',
            currentDisplayName: 'Thusa Learner (Host)',
            isLearningActivated: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // App bar create button exists
      expect(find.byKey(const ValueKey('btn_appbar_create_classroom')),
          findsOneWidget);

      // Switch to My Classrooms tab where hosted classroom is listed
      await tester.tap(find.text('My Classrooms'));
      await tester.pumpAndSettle();

      // Verify hosted classroom card shows Educator / Host and review button
      expect(find.text('Educator / Host'), findsOneWidget);
      final reviewButton = find.byKey(
          const ValueKey('btn_manage_requests_cls_my_mentorship_classroom_06'));
      expect(reviewButton, findsOneWidget);
      await tester.ensureVisible(reviewButton);

      // Tap review button
      await tester.tap(reviewButton);
      await tester.pumpAndSettle();

      expect(find.text('Admission Requests'), findsOneWidget);
      expect(find.text('Applicant: prof_applicant_charlie'), findsOneWidget);

      // Approve Charlie
      await tester
          .tap(find.byKey(const ValueKey('btn_approve_req_seed_host_01')));
      await tester.pumpAndSettle();

      expect(
          find.text('Approved applicant for "Mobile App Architecture Labs".'),
          findsOneWidget);
    });

    testWidgets(
        '5. Circles ViewModel handles lifecycle, creation, enrollment and goal tracking',
        (tester) async {
      final fakeRepo = _FakeCirclesRepo();
      final session = _MockSessionController();
      final vm = LearningCirclesViewModel(
        repository: fakeRepo,
        sessionController: session,
        isLearningActivated: true,
        currentProfileId: 'prof_test_learner_01',
        currentDisplayName: 'Test Learner',
      );

      await vm.initialize();
      expect(vm.status, LearningCirclesViewStatus.ready);
      expect(vm.discoverCount, 2);
      expect(vm.myCirclesCount, 1);

      // Filter by category
      vm.setCategory('Design');
      expect(vm.filteredDiscoverCircles.length, 1);
      expect(vm.filteredDiscoverCircles.first.name, 'UI/UX Design Systems');

      vm.setCategory('All');
      expect(vm.filteredDiscoverCircles.length, 2);

      // Join circle
      final joinSuccess = await vm.joinCircle('circle_flutter_arch');
      expect(joinSuccess, isTrue);
      expect(vm.myCirclesCount, 2);

      // Add shared goal
      final addGoalSuccess = await vm.addSharedGoal(
        circleId: 'circle_flutter_arch',
        goalText: 'Complete Isolates Practice',
      );
      expect(addGoalSuccess, isTrue);

      // Update goal progress
      final updateSuccess = await vm.updateGoalProgress(
        circleId: 'circle_flutter_arch',
        goalId: 'goal_1',
        progressPercent: 100,
      );
      expect(updateSuccess, isTrue);

      // Leave circle
      final leaveSuccess = await vm.leaveCircle('circle_flutter_arch');
      expect(leaveSuccess, isTrue);
      expect(vm.myCirclesCount, 1);

      // Session revocation purges private state immediately
      session.revokeSession();
      expect(vm.status, LearningCirclesViewStatus.accessDenied);
      expect(vm.allDiscoverCircles, isEmpty);
      expect(vm.allMyCircles, isEmpty);
    });

    testWidgets(
        '6. Shared goal enforces 0 to 100 progress range constraints and completion flag',
        (tester) async {
      final goal = CircleSharedGoal(
        id: 'goal_test',
        circleId: 'circle_test',
        text: 'Self-reported progress',
        progressPercent: 50,
      );

      expect(goal.isCompleted, isFalse);
      expect(goal.copyWith(progressPercent: 100).isCompleted, isTrue);

      expect(
        () => CircleSharedGoal(
          id: 'goal_bad',
          circleId: 'circle_test',
          text: 'Invalid progress',
          progressPercent: 150,
        ),
        throwsA(isA<ArgumentOutOfRangeException>()),
      );

      expect(
        () => CircleSharedGoal(
          id: 'goal_bad',
          circleId: 'circle_test',
          text: 'Negative progress',
          progressPercent: -10,
        ),
        throwsA(isA<ArgumentOutOfRangeException>()),
      );
    });

    testWidgets(
        '7. Learning Router wires /learning/circles and /learning/classrooms/hub with session context',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const authorizedPolicy = _ExplicitAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );
      final session = _MockSessionController();
      final dependencies =
          LearningDependenciesScope(sessionController: session);
      final router = createLearningRouter(
        dependencies: dependencies,
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/circles',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(LearningCirclesHubScreen), findsOneWidget);

      // Navigate to classrooms hub
      router.go('/learning/classrooms/hub');
      await tester.pumpAndSettle();

      expect(find.byType(LearningClassroomsHubScreen), findsOneWidget);

      // Navigate to shell classrooms tab
      router.go('/learning/classrooms');
      await tester.pumpAndSettle();

      expect(find.text('Learning Classrooms'), findsOneWidget);
      final hubButton = find.byKey(const ValueKey('btn_open_classrooms_hub'));
      expect(hubButton, findsOneWidget);

      // Tap open hub button
      await tester.tap(hubButton);
      await tester.pumpAndSettle();

      expect(find.byType(LearningClassroomsHubScreen), findsOneWidget);
    });

    testWidgets(
        '8. ClassroomsHubScreen purges state on session revocation via didUpdateWidget',
        (tester) async {
      const testWidget = MaterialApp(
        home: StatefulBuilder(
          builder: _buildClassroomsScreen,
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Spanish');
      await tester.pumpAndSettle();
      expect(find.text('Conversational Spanish for Tech'), findsOneWidget);
      expect(find.text('Flutter & Dart Mastery'), findsNothing);

      // Simulate session revocation by updating widget with new caller ID
      await tester.pumpWidget(
        const MaterialApp(
          home: LearningClassroomsHubScreen(
            currentUserId: 'user_switched_02',
            isLearningActivated: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dirty search query is purged, full catalog restored
      expect(find.text('Flutter & Dart Mastery'), findsOneWidget);
    });
  });
}

Widget _buildClassroomsScreen(BuildContext ctx, StateSetter setState) {
  return const LearningClassroomsHubScreen(
    currentUserId: 'user_active_01',
    isLearningActivated: true,
  );
}

class _ExplicitAccessPolicy implements LearningAccessPolicy {
  @override
  final bool isAuthenticated;
  @override
  final bool isLearningActivated;

  const _ExplicitAccessPolicy({
    required this.isAuthenticated,
    required this.isLearningActivated,
  });
}
