import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/circles/domain/entities/learning_circle.dart';
import 'package:andril_mobile/features/learning/circles/domain/repositories/i_learning_circles_repository.dart';
import 'package:andril_mobile/features/learning/circles/presentation/screens/learning_circles_hub_screen.dart';
import 'package:andril_mobile/features/learning/circles/presentation/viewmodels/learning_circles_viewmodel.dart';
import 'package:andril_mobile/features/learning/circles/presentation/widgets/circle_details_sheet.dart';
import 'package:andril_mobile/features/learning/circles/presentation/widgets/create_circle_dialog.dart';
import 'package:andril_mobile/features/learning/circles/presentation/widgets/learning_circle_card.dart';

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

class _FakeCirclesScreenRepository implements ILearningCirclesRepository {
  bool isBackendActivated;
  List<LearningCircle> circles;
  List<LearningCircle> myCircles;
  Completer<void>? delayCompleter;
  bool shouldFail = false;
  String? errorMessage;

  _FakeCirclesScreenRepository({
    List<LearningCircle>? circles,
    List<LearningCircle>? myCircles,
  })  : isBackendActivated = true,
        circles = circles ?? [],
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
    if (shouldFail) {
      return LearningCirclesResult.failure(
        errorMessage: errorMessage ?? 'Failed to load circles',
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
    if (shouldFail) {
      return LearningCirclesResult.failure(
        errorMessage: errorMessage ?? 'Failed to load my circles',
        failureType: LearningCirclesFailureType.unknown,
      );
    }
    return LearningCirclesResult.success(myCircles);
  }

  @override
  Future<LearningCirclesResult<LearningCircle>> joinCircle(
      String circleId) async {
    if (delayCompleter != null) await delayCompleter!.future;
    final idx = circles.indexWhere((c) => c.id == circleId);
    if (idx != -1) {
      final updated = circles[idx].copyWith(
        membershipRole: CircleMembershipRole.member,
        memberCount: circles[idx].memberCount + 1,
      );
      circles[idx] = updated;
      myCircles.add(updated);
      return LearningCirclesResult.success(updated);
    }
    return const LearningCirclesResult.failure(
      errorMessage: 'Circle not found',
      failureType: LearningCirclesFailureType.notFound,
    );
  }

  @override
  Future<LearningCirclesResult<void>> leaveCircle(String circleId) async {
    if (delayCompleter != null) await delayCompleter!.future;
    myCircles.removeWhere((c) => c.id == circleId);
    final idx = circles.indexWhere((c) => c.id == circleId);
    if (idx != -1) {
      circles[idx] = circles[idx].copyWith(
        membershipRole: CircleMembershipRole.none,
        memberCount: (circles[idx].memberCount - 1).clamp(0, 9999),
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
    final newCircle = LearningCircle.create(
      id: 'circle_${circles.length + 1}',
      name: name,
      description: description,
      category: category,
      facilitatorProfileId: 'fac_me',
      facilitatorDisplayName: 'Current Learner',
      memberCount: 1,
      membershipRole: CircleMembershipRole.facilitator,
      goals: initialGoalText != null && initialGoalText.trim().isNotEmpty
          ? [
              CircleSharedGoal(
                id: 'goal_new',
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
    if (delayCompleter != null) await delayCompleter!.future;
    final updated = CircleSharedGoal(
      id: goalId,
      circleId: circleId,
      text: 'Updated goal',
      progressPercent: progressPercent,
    );
    return LearningCirclesResult.success(updated);
  }
}

Widget _buildTestApp({
  required LearningCirclesViewModel viewModel,
  Size size = const Size(360, 640),
  double textScaleFactor = 1.0,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(textScaleFactor),
    ),
    child: MaterialApp(
      home: LearningCirclesHubScreen(
        viewModel: viewModel,
      ),
    ),
  );
}

void main() {
  late _FakeSessionController sessionController;
  late _FakeCirclesScreenRepository repository;
  late LearningCircle circle1;
  late LearningCircle circle2;
  late LearningCircle myCircle1;

  setUp(() {
    sessionController = _FakeSessionController(phase: SessionPhase.signedIn);

    circle1 = LearningCircle.create(
      id: 'c1',
      name: 'Flutter Architecture',
      description:
          'Clean Architecture and state management patterns in Flutter.',
      category: 'Mobile Dev',
      facilitatorProfileId: 'fac_1',
      facilitatorDisplayName: 'Grace Hopper',
      memberCount: 14,
      membershipRole: CircleMembershipRole.none,
      goals: [
        CircleSharedGoal(
          id: 'g1',
          circleId: 'c1',
          text: 'Implement Bloc & Repository layer',
          progressPercent: 50,
        ),
      ],
    );

    circle2 = LearningCircle.create(
      id: 'c2',
      name: 'Systems Programming',
      description: 'Rust and low level concurrent systems.',
      category: 'Programming',
      facilitatorProfileId: 'fac_2',
      facilitatorDisplayName: 'Alan Turing',
      memberCount: 7,
      membershipRole: CircleMembershipRole.none,
    );

    myCircle1 = LearningCircle.create(
      id: 'c3',
      name: 'Algorithms & Data Structures',
      description: 'Competitive programming and interview prep.',
      category: 'Algorithms',
      facilitatorProfileId: 'fac_me',
      facilitatorDisplayName: 'Current Learner',
      memberCount: 5,
      membershipRole: CircleMembershipRole.facilitator,
      goals: [
        CircleSharedGoal(
          id: 'g2',
          circleId: 'c3',
          text: 'Solve 50 LeetCode graph problems',
          progressPercent: 80,
        ),
      ],
    );

    repository = _FakeCirclesScreenRepository(
      circles: [circle1, circle2],
      myCircles: [myCircle1],
    );
  });

  group('LearningCirclesHubScreen - Hub Layout & Tab Navigation', () {
    testWidgets('renders app bar, title, tab badges, notice banner, and FAB',
        (tester) async {
      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.text('Learning Circles Hub'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('tab_discover_circles')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_my_circles')), findsOneWidget);
      expect(find.text('Discover Circles'), findsOneWidget);
      expect(find.text('My Circles'), findsOneWidget);
      expect(find.byKey(const ValueKey('banner_disconnected_notice')),
          findsOneWidget);
      expect(find.text(LearningCirclesViewModel.disconnectedNotice),
          findsOneWidget);
      expect(find.byKey(const ValueKey('fab_create_circle')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_appbar_create_circle')),
          findsOneWidget);
    });

    testWidgets('switches between Discover Circles and My Circles tabs',
        (tester) async {
      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Initially on Discover tab
      expect(find.text('Flutter Architecture'), findsOneWidget);
      expect(find.text('Systems Programming'), findsOneWidget);

      // Tap My Circles tab
      await tester.tap(find.byKey(const ValueKey('tab_my_circles')));
      await tester.pumpAndSettle();

      expect(vm.activeTab, LearningCirclesTab.myCircles);
      expect(find.text('Algorithms & Data Structures'), findsOneWidget);

      // Tap back to Discover tab
      await tester.tap(find.byKey(const ValueKey('tab_discover_circles')));
      await tester.pumpAndSettle();

      expect(vm.activeTab, LearningCirclesTab.discover);
      expect(find.text('Flutter Architecture'), findsOneWidget);
    });
  });

  group('LearningCirclesHubScreen - Presentation States', () {
    testWidgets('renders loading spinner while circles are loading',
        (tester) async {
      final completer = Completer<void>();
      repository.delayCompleter = completer;

      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pump();

      expect(find.byKey(const ValueKey('loading_circles_indicator')),
          findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('loading_circles_indicator')),
          findsNothing);
      expect(find.text('Flutter Architecture'), findsOneWidget);
    });

    testWidgets('renders Access Denied state when session is signed out',
        (tester) async {
      sessionController.setPhase(SessionPhase.signedOut);

      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('access_denied_circles_view')),
          findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets(
        'renders Service Unavailable state when backend contract is disconnected',
        (tester) async {
      repository.isBackendActivated = false;

      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('service_unavailable_circles_view')),
          findsOneWidget);
      expect(find.text('Service Notice'), findsOneWidget);
    });

    testWidgets('renders Error state and retry button works', (tester) async {
      repository.shouldFail = true;
      repository.errorMessage = 'Network timeout';

      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('error_circles_view')), findsOneWidget);
      expect(find.text('Network timeout'), findsOneWidget);

      // Now clear failure and tap retry
      repository.shouldFail = false;
      await tester.tap(find.byKey(const ValueKey('btn_retry_circles')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('error_circles_view')), findsNothing);
      expect(find.text('Flutter Architecture'), findsOneWidget);
    });

    testWidgets('renders Empty state for Discover when no circles exist',
        (tester) async {
      repository.circles.clear();
      repository.myCircles.clear();

      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('empty_discover_circles_view')),
          findsOneWidget);
      expect(find.text('No Circles Found'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_empty_action_circle')),
          findsOneWidget);
    });

    testWidgets('renders Empty state for My Circles when not enrolled',
        (tester) async {
      repository.myCircles.clear();

      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Switch to My Circles tab
      await tester.tap(find.byKey(const ValueKey('tab_my_circles')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('empty_my_circles_view')), findsOneWidget);
      expect(find.text('No Enrolled Circles'), findsOneWidget);
    });
  });

  group(
      'LearningCirclesHubScreen - Card Details, Collaborative Goals & Actions',
      () {
    testWidgets('LearningCircleCard renders details, badges, and progress',
        (tester) async {
      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byType(LearningCircleCard), findsNWidgets(2));
      expect(find.text('Flutter Architecture'), findsOneWidget);
      expect(find.text('Facilitator: Grace Hopper'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(LearningCircleCard),
          matching: find.text('Mobile Dev'),
        ),
        findsOneWidget,
      );
      expect(find.text('14 members'), findsOneWidget);
      expect(find.text('50% avg'), findsOneWidget);
      expect(find.text('1 Shared Goal'), findsOneWidget);
    });

    testWidgets('tapping View Details opens CircleDetailsSheet with goal info',
        (tester) async {
      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Tap View Details on Flutter Architecture card
      final viewDetailsButton =
          find.byKey(const ValueKey('btn_view_circle_c1'));
      expect(viewDetailsButton, findsOneWidget);
      await tester.tap(viewDetailsButton);
      await tester.pumpAndSettle();

      expect(find.byType(CircleDetailsSheet), findsOneWidget);
      expect(find.text('Implement Bloc & Repository layer'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('joining a circle from card updates UI and switches membership',
        (tester) async {
      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      final joinButton = find.byKey(const ValueKey('btn_join_circle_c1'));
      expect(joinButton, findsOneWidget);

      await tester.ensureVisible(joinButton);
      await tester.tap(joinButton);
      await tester.pumpAndSettle();

      // Card now has Member badge
      expect(find.text('Member'), findsOneWidget);
      expect(find.text('15 members'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_leave_circle_c1')), findsOneWidget);
    });

    testWidgets(
        'creating a circle via FAB opens CreateCircleDialog and creates circle',
        (tester) async {
      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('fab_create_circle')));
      await tester.pumpAndSettle();

      expect(find.byType(CreateCircleDialog), findsOneWidget);
      expect(find.text('Create Learning Circle'), findsOneWidget);

      // Fill in details
      await tester.enterText(
        find.byKey(const ValueKey('input_circle_name')),
        'Cybersecurity Ops',
      );
      await tester.enterText(
        find.byKey(const ValueKey('input_circle_description')),
        'Penetration testing and secure code review practices.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('input_circle_initial_goal')),
        'Complete OWASP Top 10 hands-on labs',
      );

      // Submit
      final submitBtn = find.byKey(const ValueKey('btn_submit_create_circle'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.byType(CreateCircleDialog), findsNothing);
      expect(vm.allDiscoverCircles.any((c) => c.name == 'Cybersecurity Ops'),
          isTrue);
      expect(vm.allMyCircles.any((c) => c.name == 'Cybersecurity Ops'), isTrue);
    });

    testWidgets(
        'adding a goal and updating goal progress via dialogs in CircleDetailsSheet',
        (tester) async {
      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Switch to My Circles tab where user is facilitator of c3
      await tester.tap(find.byKey(const ValueKey('tab_my_circles')));
      await tester.pumpAndSettle();

      // Open details of circle 3
      await tester.tap(find.byKey(const ValueKey('btn_view_circle_c3')));
      await tester.pumpAndSettle();

      // Tap Add Goal button
      final addGoalBtn = find.byKey(const ValueKey('btn_add_shared_goal'));
      expect(addGoalBtn, findsOneWidget);
      await tester.tap(addGoalBtn);
      await tester.pumpAndSettle();

      // Enter goal text and submit
      await tester.enterText(
        find.byKey(const ValueKey('input_new_shared_goal')),
        'Write unit tests for viewmodels',
      );
      await tester
          .tap(find.byKey(const ValueKey('btn_confirm_add_shared_goal')));
      await tester.pumpAndSettle();

      // Now tap update progress on first goal
      final updateProgressBtn =
          find.byKey(const ValueKey('btn_update_progress_g2'));
      expect(updateProgressBtn, findsOneWidget);
      await tester.tap(updateProgressBtn);
      await tester.pumpAndSettle();

      expect(find.text('Update Reported Progress'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('slider_goal_progress')), findsOneWidget);

      // Confirm update
      await tester.tap(find.byKey(const ValueKey('btn_save_goal_progress')));
      await tester.pumpAndSettle();

      expect(find.text('Update Reported Progress'), findsNothing);
    });
  });

  group('LearningCirclesHubScreen - Responsive Layouts & Accessibility', () {
    testWidgets('renders cleanly on 320dp viewport without overflow',
        (tester) async {
      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Learning Circles Hub'), findsOneWidget);
      expect(find.text('Flutter Architecture'), findsOneWidget);
    });

    testWidgets('renders cleanly on 360dp viewport without overflow',
        (tester) async {
      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        size: const Size(360, 640),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Flutter Architecture'), findsOneWidget);
    });

    testWidgets('renders cleanly on 412dp viewport without overflow',
        (tester) async {
      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        size: const Size(412, 915),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Flutter Architecture'), findsOneWidget);
    });

    testWidgets(
        'renders cleanly under 1.5x dynamic text scale without overflow',
        (tester) async {
      final vm = LearningCirclesViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        size: const Size(360, 640),
        textScaleFactor: 1.5,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Learning Circles Hub'), findsOneWidget);
      expect(find.text('Flutter Architecture'), findsOneWidget);
    });
  });
}
