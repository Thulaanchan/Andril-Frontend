import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/home/screens/learning_home_screen.dart';
import 'package:andril_mobile/features/learning/home/widgets/learning_home_action_grid.dart';
import 'package:andril_mobile/features/learning/home/widgets/learning_home_header.dart';
import 'package:andril_mobile/features/learning/home/widgets/learning_progress_card.dart';

/// Test harness wrapping [LearningHomeScreen] with theme, layout, and explicit viewport constraints.
Widget _buildHomeScreenHarness({
  required Widget child,
  Size size = const Size(360, 800),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: textScaler,
          ),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('LearningHomeScreen - Dedicated Widget Tests (Batch 03H-1)', () {
    // =========================================================================
    // GROUP 1: Ready State
    // =========================================================================
    testWidgets(
        'TEST-03H-1-01: Minimal props render header, progress card empty state, and action grid',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LearningHomeHeader), findsOneWidget);
      expect(find.byType(LearningProgressCard), findsOneWidget);
      expect(find.byType(LearningHomeActionGrid), findsOneWidget);
      expect(find.text('Thusha'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('No active learning goal'), findsOneWidget);
      expect(find.text('No learning actions available'), findsOneWidget);
      expect(find.text('My Learning Hub'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03H-1-02: Renders custom greeting, display name, and status text',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Aarav',
            greeting: 'Good morning',
            statusText: 'Active Learner',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aarav'), findsOneWidget);
      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Active Learner'), findsOneWidget);
    });

    testWidgets(
        'TEST-03H-1-03: Active goal, completion percent, and weekly commitment render properly',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Flutter Architecture Mastery',
            completionPercent: 65,
            weeklyCommitmentText: '4 hrs/week',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE GOAL'), findsOneWidget);
      expect(find.text('Flutter Architecture Mastery'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('4 hrs/week'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('TEST-03H-1-04: Action grid items render titles and icons',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: 'classrooms',
          title: 'Classrooms',
          icon: Icons.school_outlined,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'circles',
          title: 'Learning Circles',
          icon: Icons.group_work_outlined,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'Thusha',
            actions: actions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Classrooms'), findsOneWidget);
      expect(find.text('Learning Circles'), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      expect(find.byIcon(Icons.group_work_outlined), findsOneWidget);
    });

    testWidgets(
        'TEST-03H-1-05: Screen scrolls vertically to reveal content below viewport',
        (tester) async {
      tester.view.physicalSize = const Size(360, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final actions = List.generate(
        6,
        (index) => LearningHomeActionItem(
          id: 'action_$index',
          title: 'Action Item $index',
          icon: Icons.bookmark_border_rounded,
          onTap: () {},
        ),
      );

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          size: const Size(360, 400),
          child: LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Extensive Goal to Fill Vertical Space',
            completionPercent: 50,
            weeklyCommitmentText: '5 hrs/week',
            actions: actions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Action Item 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // GROUP 2: Loading State
    // =========================================================================
    testWidgets(
        'TEST-03H-1-06: Loading state displays progress indicator and loading label',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Learning Home...'), findsOneWidget);
    });

    testWidgets(
        'TEST-03H-1-07: Loading state suppresses private header, progress card, and action grid',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Secret Learning Goal',
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LearningHomeHeader), findsNothing);
      expect(find.byType(LearningProgressCard), findsNothing);
      expect(find.byType(LearningHomeActionGrid), findsNothing);
      expect(find.text('Thusha'), findsNothing);
      expect(find.text('Secret Learning Goal'), findsNothing);
    });

    testWidgets(
        'TEST-03H-1-08: Loading state does not expose interactive actions',
        (tester) async {
      bool tapped = false;
      final actions = [
        LearningHomeActionItem(
          id: 'secret_action',
          title: 'Secret Action',
          icon: Icons.lock,
          onTap: () => tapped = true,
        ),
      ];

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'Thusha',
            actions: actions,
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Secret Action'), findsNothing);
      expect(tapped, isFalse);
    });

    testWidgets(
        'TEST-03H-1-09: Loading state takes precedence over error and access denied flags',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            isLoading: true,
            isAccessDenied: true,
            errorMessage: 'Something went wrong',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading Learning Home...'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Access Restricted'), findsNothing);
    });

    // =========================================================================
    // GROUP 3: Access Denied / Privacy
    // =========================================================================
    testWidgets(
        'TEST-03H-1-10: Access-denied state displays restricted heading, explanation, and lock icon',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            isAccessDenied: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('Learning Home requires active module activation.'),
          findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets(
        'TEST-03H-1-11: Access-denied state conceals private profile and progress data',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Confidential Learner',
            statusText: 'Advanced Researcher',
            goalTitle: 'Confidential Milestone',
            completionPercent: 88,
            weeklyCommitmentText: '10 hrs/week',
            isAccessDenied: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confidential Learner'), findsNothing);
      expect(find.text('Advanced Researcher'), findsNothing);
      expect(find.text('Confidential Milestone'), findsNothing);
      expect(find.text('88%'), findsNothing);
      expect(find.text('10 hrs/week'), findsNothing);
      expect(find.byType(LearningHomeHeader), findsNothing);
      expect(find.byType(LearningProgressCard), findsNothing);
      expect(find.byType(LearningHomeActionGrid), findsNothing);
    });

    testWidgets(
        'TEST-03H-1-12: Protected callbacks are not exposed or invocable in denied state',
        (tester) async {
      bool notificationTapped = false;
      bool resumeTapped = false;
      bool actionTapped = false;

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Some Goal',
            onNotificationTap: () => notificationTapped = true,
            onResume: () => resumeTapped = true,
            actions: [
              LearningHomeActionItem(
                id: 'item1',
                title: 'Protected Action',
                icon: Icons.star,
                onTap: () => actionTapped = true,
              ),
            ],
            isAccessDenied: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
      expect(find.text('Resume Learning'), findsNothing);
      expect(find.text('Protected Action'), findsNothing);
      expect(notificationTapped, isFalse);
      expect(resumeTapped, isFalse);
      expect(actionTapped, isFalse);
    });

    testWidgets(
        'TEST-03H-1-13: Error state takes precedence over access denied when both are set',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            errorMessage: 'Network connection dropped',
            isAccessDenied: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Network connection dropped'), findsOneWidget);
      expect(find.text('Access Restricted'), findsNothing);
    });

    testWidgets(
        'TEST-03H-1-14: Blank or whitespace-only error message falls through to access-denied state',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            errorMessage: '   ',
            isAccessDenied: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
    });

    // =========================================================================
    // GROUP 4: Error and Retry
    // =========================================================================
    testWidgets(
        'TEST-03H-1-15: Error state displays error message and error icon',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            errorMessage: 'Unable to reach learning services',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to reach learning services'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets(
        'TEST-03H-1-16: Error state displays Retry button when onRetry is provided',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'Thusha',
            errorMessage: 'Failed to synchronize',
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets(
        'TEST-03H-1-17: Tapping Retry button invokes onRetry callback exactly once',
        (tester) async {
      int retryCount = 0;

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'Thusha',
            errorMessage: 'Failed to synchronize',
            onRetry: () => retryCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(retryCount, equals(0));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retryCount, equals(1));
    });

    testWidgets(
        'TEST-03H-1-18: Error state without onRetry safely omits Retry button',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            errorMessage: 'Permanent configuration error',
            onRetry: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsNothing);
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    });

    testWidgets(
        'TEST-03H-1-19: Error state suppresses private ready-state components',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Private Learner',
            goalTitle: 'Private Goal',
            errorMessage: 'Sync error',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LearningHomeHeader), findsNothing);
      expect(find.byType(LearningProgressCard), findsNothing);
      expect(find.byType(LearningHomeActionGrid), findsNothing);
      expect(find.text('Private Learner'), findsNothing);
      expect(find.text('Private Goal'), findsNothing);
    });

    // =========================================================================
    // GROUP 5: Empty and Optional Data
    // =========================================================================
    testWidgets(
        'TEST-03H-1-20: Empty actions list renders neutral action empty state',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            actions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No learning actions available'), findsOneWidget);
    });

    testWidgets(
        'TEST-03H-1-21: Null avatar renders neutral fallback person icon',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            avatarImage: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('TEST-03H-1-22: Null statusText omits status badge from header',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            statusText: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thusha'), findsOneWidget);
      expect(find.text('Active Learner'), findsNothing);
    });

    testWidgets(
        'TEST-03H-1-23: Null goalTitle renders progress card empty state',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active learning goal'), findsOneWidget);
      expect(
          find.text(
              'Set a goal to track your progress and resume your learning journey.'),
          findsOneWidget);
    });

    testWidgets(
        'TEST-03H-1-24: Null completionPercent with goal renders unavailable progress safely',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Goal with uncalculated progress',
            completionPercent: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Goal with uncalculated progress'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets(
        'TEST-03H-1-25: Null weeklyCommitmentText omits commitment row from card',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Goal without commitment',
            weeklyCommitmentText: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule_outlined), findsNothing);
    });

    testWidgets(
        'TEST-03H-1-26: Null onNotificationTap omits notification action from header',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            onNotificationTap: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });

    testWidgets(
        'TEST-03H-1-27: Null onResume omits resume button from progress card',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Goal without resume callback',
            onResume: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resume Learning'), findsNothing);
    });

    // =========================================================================
    // GROUP 6: Callback Interactions
    // =========================================================================
    testWidgets(
        'TEST-03H-1-28: Tapping notification action in header invokes onNotificationTap exactly once',
        (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'Thusha',
            onNotificationTap: () => tapCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tapCount, equals(0));
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(tapCount, equals(1));
    });

    testWidgets(
        'TEST-03H-1-29: Tapping Resume Learning button in progress card invokes onResume exactly once',
        (tester) async {
      int resumeCount = 0;

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Active Flutter Goal',
            onResume: () => resumeCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(resumeCount, equals(0));
      await tester.tap(find.text('Resume Learning'));
      await tester.pumpAndSettle();

      expect(resumeCount, equals(1));
    });

    testWidgets(
        'TEST-03H-1-30: Tapping available action card in action grid invokes item onTap exactly once',
        (tester) async {
      int actionCount = 0;
      final actions = [
        LearningHomeActionItem(
          id: 'mentorship',
          title: 'Mentorship',
          icon: Icons.person_pin_outlined,
          onTap: () => actionCount++,
        ),
      ];

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'Thusha',
            actions: actions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(actionCount, equals(0));
      await tester.tap(find.text('Mentorship'));
      await tester.pumpAndSettle();

      expect(actionCount, equals(1));
    });

    testWidgets(
        'TEST-03H-1-31: Callbacks are not triggered during initial widget construction',
        (tester) async {
      bool notifCalled = false;
      bool resumeCalled = false;
      bool actionCalled = false;
      bool retryCalled = false;

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Goal',
            onNotificationTap: () => notifCalled = true,
            onResume: () => resumeCalled = true,
            onRetry: () => retryCalled = true,
            actions: [
              LearningHomeActionItem(
                id: 'act',
                title: 'Action',
                icon: Icons.star,
                onTap: () => actionCalled = true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(notifCalled, isFalse);
      expect(resumeCalled, isFalse);
      expect(actionCalled, isFalse);
      expect(retryCalled, isFalse);
    });

    testWidgets(
        'TEST-03H-1-32: Unavailable action card with unavailableReason is non-interactive',
        (tester) async {
      int tapCount = 0;
      final actions = [
        LearningHomeActionItem(
          id: 'locked_feature',
          title: 'Advanced Lab',
          icon: Icons.biotech_outlined,
          unavailableReason: 'Available at Level 3',
          onTap: () => tapCount++,
        ),
      ];

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'Thusha',
            actions: actions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Advanced Lab'), findsOneWidget);
      expect(find.text('Available at Level 3'), findsOneWidget);

      await tester.tap(find.text('Advanced Lab'));
      await tester.pumpAndSettle();

      expect(tapCount, equals(0));
    });

    // =========================================================================
    // GROUP 7: Responsiveness
    // =========================================================================
    testWidgets(
        'TEST-03H-1-33: 320dp compact phone viewport renders without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          size: const Size(320, 800),
          child: LearningHomeScreen(
            displayName: 'Thusha',
            statusText: 'Active Learner',
            goalTitle: 'Compact Viewport Test Goal',
            completionPercent: 40,
            weeklyCommitmentText: '3 hrs/week',
            onResume: () {},
            actions: [
              LearningHomeActionItem(
                id: 'a1',
                title: 'Classrooms',
                icon: Icons.school_outlined,
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Thusha'), findsOneWidget);
      expect(find.text('Compact Viewport Test Goal'), findsOneWidget);
    });

    testWidgets(
        'TEST-03H-1-34: 360dp standard phone viewport renders without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          size: const Size(360, 800),
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Standard Phone Test Goal',
            completionPercent: 55,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03H-1-35: 412dp modern phone viewport renders without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(412, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          size: const Size(412, 800),
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Wide Modern Phone Test Goal',
            completionPercent: 80,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03H-1-36: Long strings in display name and goal title do not cause layout overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          size: const Size(360, 800),
          child: const LearningHomeScreen(
            displayName:
                'VeryLongLearnerDisplayNameThatShouldBeEllipsizedGracefullyWithoutAnyHorizontalOverflowIssue',
            greeting:
                'Extremely Long Greeting String That Exceeds Normal Screen Width Boundaries',
            statusText:
                'Exceptionally Detailed Status Description That Exceeds Container Limits',
            goalTitle:
                'An Exceptionally Long Goal Title That Spans Multiple Lines Describing The Intended Learning Path In Full Depth Without Overflowing Out Of The Card Surface',
            completionPercent: 50,
            weeklyCommitmentText:
                'Extremely Detailed Weekly Commitment Text With Lots Of Description',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // GROUP 8: Accessibility & Unicode
    // =========================================================================
    testWidgets(
        'TEST-03H-1-37: 1.5x dynamic text scaling renders without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          size: const Size(360, 800),
          textScaler: const TextScaler.linear(1.5),
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Accessibility Test Goal',
            completionPercent: 50,
            weeklyCommitmentText: '3 hrs/wk',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03H-1-38: Tamil and Unicode characters render correctly across all components',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'கற்றல் அன்பர்',
            greeting: 'வணக்கம்',
            statusText: 'செயலில் உள்ள மாணவர்',
            goalTitle: 'தமிழ் மொழி கற்றல் இலக்கு',
            weeklyCommitmentText: 'வாரம் 3 மணிநேரம்',
            actionsTitle: 'கற்றல் மையம்',
            actions: [
              LearningHomeActionItem(
                id: 'tamil_circle',
                title: 'கற்றல் வட்டம்',
                icon: Icons.forum_outlined,
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('கற்றல் அன்பர்'), findsOneWidget);
      expect(find.text('வணக்கம்'), findsOneWidget);
      expect(find.text('செயலில் உள்ள மாணவர்'), findsOneWidget);
      expect(find.text('தமிழ் மொழி கற்றல் இலக்கு'), findsOneWidget);
      expect(find.text('வாரம் 3 மணிநேரம்'), findsOneWidget);
      expect(find.text('கற்றல் மையம்'), findsOneWidget);
      expect(find.text('கற்றல் வட்டம்'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03H-1-39: Semantic node labels for avatar and notification action exist',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'Thusha',
            onNotificationTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Profile avatar for Thusha'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Learning notifications'),
        findsOneWidget,
      );
    });

    testWidgets(
        'TEST-03H-1-40: Semantics for progress indicator reflect completion percent value',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            goalTitle: 'Active Semantic Goal',
            completionPercent: 42,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Goal progress: 42%'),
        findsOneWidget,
      );
    });

    // =========================================================================
    // GROUP 9: Screen Composition & Regression
    // =========================================================================
    testWidgets(
        'TEST-03H-1-41: Screen composes Scaffold, SafeArea, SingleChildScrollView, and child bricks',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(LearningHomeScreen),
          matching: find.byType(Scaffold),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(LearningHomeScreen),
          matching: find.byType(SafeArea),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(LearningHomeScreen),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(LearningHomeScreen),
          matching: find.byType(LearningHomeHeader),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(LearningHomeScreen),
          matching: find.byType(LearningProgressCard),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(LearningHomeScreen),
          matching: find.byType(LearningHomeActionGrid),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'TEST-03H-1-42: Custom actionsTitle overrides default grid heading',
        (tester) async {
      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: const LearningHomeScreen(
            displayName: 'Thusha',
            actionsTitle: 'Personalized Shortcuts',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personalized Shortcuts'), findsOneWidget);
      expect(find.text('My Learning Hub'), findsNothing);
    });

    testWidgets(
        'TEST-03H-1-43: Action Grid fail-closed duplicate-ID safety is preserved at screen level',
        (tester) async {
      final actionsWithDuplicates = [
        LearningHomeActionItem(
          id: 'duplicate_id',
          title: 'First Conflicting Action',
          icon: Icons.warning,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'duplicate_id',
          title: 'Second Conflicting Action',
          icon: Icons.error,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'unique_id',
          title: 'Safe Unique Action',
          icon: Icons.check_circle_outline,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildHomeScreenHarness(
          child: LearningHomeScreen(
            displayName: 'Thusha',
            actions: actionsWithDuplicates,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('First Conflicting Action'), findsNothing);
      expect(find.text('Second Conflicting Action'), findsNothing);
      expect(find.text('Safe Unique Action'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
