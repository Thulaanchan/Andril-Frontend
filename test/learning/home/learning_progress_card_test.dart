import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/home/widgets/learning_progress_card.dart';

/// Test harness wrapping [LearningProgressCard] with theme and explicit viewport constraints.
Widget _buildTestHarness({
  required Widget child,
  Size size = const Size(360, 640),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Scaffold(
      backgroundColor: LearningColors.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: size.width,
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: textScaler,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('LearningProgressCard - Dedicated Widget Tests (Batch 03D)', () {
    // =========================================================================
    // GROUP A: Goal Display Tests
    // =========================================================================
    testWidgets(
        'TEST-03D-01: Standard active goal renders title and active eyebrow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Learn Flutter Architecture',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE GOAL'), findsOneWidget);
      expect(find.text('Learn Flutter Architecture'), findsOneWidget);
      expect(find.text('No active learning goal'), findsNothing);
    });

    testWidgets('TEST-03D-02: Null goal displays neutral empty state',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LEARNING GOAL'), findsOneWidget);
      expect(find.text('No active learning goal'), findsOneWidget);
      expect(
        find.text(
          'Set a goal to track your progress and resume your learning journey.',
        ),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('TEST-03D-03: Empty string goal displays empty state',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: '',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active learning goal'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('TEST-03D-04: Whitespace-only goal displays empty state',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: '   \t  \n  ',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active learning goal'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets(
        'TEST-03D-05: Long goal title wraps safely without RenderFlex overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(320, 600),
          child: const LearningProgressCard(
            goalTitle:
                'Mastering Advanced Clean Architecture, Reactive State Management, and Domain-Driven Design in Production Flutter Apps',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Mastering Advanced Clean Architecture, Reactive State Management, and Domain-Driven Design in Production Flutter Apps',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'TEST-03D-06: Tamil and multilingual goal renders without exceptions',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'முழுமையான Flutter கட்டமைப்பு பயிற்சி 🌟',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('முழுமையான Flutter கட்டமைப்பு பயிற்சி 🌟'),
        findsOneWidget,
      );
    });

    // =========================================================================
    // GROUP B: Progress Percentage Tests
    // =========================================================================
    testWidgets(
        'TEST-03D-07: Zero progress renders 0% and determinate indicator',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Foundations',
            completionPercent: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
      final indicatorFinder = find.byType(LinearProgressIndicator);
      expect(indicatorFinder, findsOneWidget);

      final LinearProgressIndicator indicator =
          tester.widget<LinearProgressIndicator>(indicatorFinder);
      expect(indicator.value, equals(0.0));
    });

    testWidgets(
        'TEST-03D-08: Partial progress renders correct percentage and indicator value',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Foundations',
            completionPercent: 45,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('45%'), findsOneWidget);
      final indicatorFinder = find.byType(LinearProgressIndicator);
      expect(indicatorFinder, findsOneWidget);

      final LinearProgressIndicator indicator =
          tester.widget<LinearProgressIndicator>(indicatorFinder);
      expect(indicator.value, closeTo(0.45, 0.001));
    });

    testWidgets(
        'TEST-03D-09: Complete progress renders 100% without fabricated awards',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Foundations',
            completionPercent: 100,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);
      final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(indicator.value, equals(1.0));

      // Verify no fictitious certificates or rewards appear
      expect(find.textContaining('Certificate'), findsNothing);
      expect(find.textContaining('Award'), findsNothing);
      expect(find.textContaining('Badge'), findsNothing);
    });

    testWidgets(
        'TEST-03D-10: Null percentage displays Progress unavailable without fake 0%',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Foundations',
            completionPercent: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progress unavailable'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets(
        'TEST-03D-11: Negative percentage renders safe invalid state without crash',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Foundations',
            completionPercent: -1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Invalid progress'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets(
        'TEST-03D-12: Above-100 percentage renders safe invalid state without crash',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Foundations',
            completionPercent: 101,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Invalid progress'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets(
        'TEST-03D-13: Boundary differentiation between 0%, 100%, null, and invalid',
        (tester) async {
      // 0%
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Goal A',
            completionPercent: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0%'), findsOneWidget);

      // 100%
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Goal A',
            completionPercent: 100,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);

      // null
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Goal A',
            completionPercent: null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Progress unavailable'), findsOneWidget);

      // invalid
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Goal A',
            completionPercent: 150,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Invalid progress'), findsOneWidget);
    });

    // =========================================================================
    // GROUP C: Weekly Commitment Tests
    // =========================================================================
    testWidgets(
        'TEST-03D-14: Commitment supplied renders schedule icon and text',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Architecture',
            weeklyCommitmentText: '3 hours per week',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
      expect(find.text('3 hours per week'), findsOneWidget);
    });

    testWidgets('TEST-03D-15: Null commitment omits commitment section safely',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Architecture',
            weeklyCommitmentText: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule_outlined), findsNothing);
    });

    testWidgets('TEST-03D-16: Blank commitment omits commitment section safely',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Architecture',
            weeklyCommitmentText: '   \t  \n  ',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule_outlined), findsNothing);
    });

    testWidgets(
        'TEST-03D-17: Long commitment string is constrained safely without overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(320, 600),
          child: const LearningProgressCard(
            goalTitle: 'Flutter Architecture',
            weeklyCommitmentText:
                '10-15 intensive hours per week including pair programming and code reviews',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(
          '10-15 intensive hours per week including pair programming and code reviews',
        ),
        findsOneWidget,
      );
    });

    // =========================================================================
    // GROUP D: Resume Action Tests
    // =========================================================================
    testWidgets(
        'TEST-03D-18: Callback supplied renders Resume button and fires exactly once on tap',
        (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        _buildTestHarness(
          child: LearningProgressCard(
            goalTitle: 'Flutter Architecture',
            onResume: () => tapCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(FilledButton, 'Resume Learning');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pump();
      expect(tapCount, equals(1));
    });

    testWidgets('TEST-03D-19: Callback omitted omits Resume button cleanly',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Architecture',
            onResume: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resume Learning'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets(
        'TEST-03D-20: Empty goal omits Resume button even if callback is supplied',
        (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        _buildTestHarness(
          child: LearningProgressCard(
            goalTitle: null,
            onResume: () => tapCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resume Learning'), findsNothing);
      expect(tapCount, equals(0));
    });

    testWidgets(
        'TEST-03D-21: Callback ownership: tapping Resume executes callback without navigation',
        (tester) async {
      bool invoked = false;
      await tester.pumpWidget(
        _buildTestHarness(
          child: LearningProgressCard(
            goalTitle: 'Flutter Architecture',
            onResume: () => invoked = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resume Learning'));
      await tester.pumpAndSettle();

      expect(invoked, isTrue);
      expect(tester.takeException(), isNull);
      expect(find.byType(LearningProgressCard), findsOneWidget);
    });

    // =========================================================================
    // GROUP E: Responsive Layout Tests
    // =========================================================================
    testWidgets(
        'TEST-03D-22: 320dp Android width renders safely without overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(320, 600),
          child: LearningProgressCard(
            goalTitle: 'Flutter Architecture',
            completionPercent: 65,
            weeklyCommitmentText: '5 hours/week',
            onResume: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03D-23: 360dp Android width renders safely without overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(360, 640),
          child: LearningProgressCard(
            goalTitle: 'Flutter Architecture',
            completionPercent: 65,
            weeklyCommitmentText: '5 hours/week',
            onResume: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03D-24: 412dp Android width renders safely without overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(412, 892),
          child: LearningProgressCard(
            goalTitle: 'Flutter Architecture',
            completionPercent: 65,
            weeklyCommitmentText: '5 hours/week',
            onResume: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03D-25: 1.5x text scaling renders safely without overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(320, 600),
          textScaler: const TextScaler.linear(1.5),
          child: LearningProgressCard(
            goalTitle: 'Flutter Architecture',
            completionPercent: 65,
            weeklyCommitmentText: '5 hours/week',
            onResume: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03D-26: Combined stress test: Long Unicode goal, long commitment, 100%, resume, 320dp, 1.5x scaling',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(320, 600),
          textScaler: const TextScaler.linear(1.5),
          child: LearningProgressCard(
            goalTitle:
                'முழுமையான Clean Architecture மற்றும் Domain-Driven Design பயிற்சித் திட்டம்',
            completionPercent: 100,
            weeklyCommitmentText:
                'வாரம் 15 மணி நேர தீவிர தொடர் பயிற்சி மற்றும் செய்முறைத் திட்டங்கள்',
            onResume: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LearningProgressCard), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Resume Learning'), findsOneWidget);
    });

    // =========================================================================
    // GROUP F: Accessibility Tests
    // =========================================================================
    testWidgets(
        'TEST-03D-27: Valid progress renders accessible semantic label and value',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Basics',
            completionPercent: 75,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Goal progress: 75%'),
        findsOneWidget,
      );
    });

    testWidgets(
        'TEST-03D-28: Unknown progress announces Goal progress unavailable',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Basics',
            completionPercent: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Goal progress unavailable'),
        findsOneWidget,
      );
    });

    testWidgets(
        'TEST-03D-29: Invalid progress announces Invalid goal progress value',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Flutter Basics',
            completionPercent: -10,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Invalid goal progress value'),
        findsOneWidget,
      );
    });

    testWidgets('TEST-03D-30: Resume action enforces minimum 48dp touch target',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: LearningProgressCard(
            goalTitle: 'Flutter Basics',
            onResume: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final FilledButton button =
          tester.widget<FilledButton>(find.byType(FilledButton));
      final Size? minSize = button.style?.minimumSize?.resolve({});
      expect(minSize?.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets(
        'TEST-03D-31: Empty-state message is understandable without relying on icon or color',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active learning goal'), findsOneWidget);
      expect(
        find.text(
          'Set a goal to track your progress and resume your learning journey.',
        ),
        findsOneWidget,
      );
    });

    // =========================================================================
    // GROUP G: Privacy and Security Boundary Tests
    // =========================================================================
    testWidgets(
        'TEST-03D-32: Presentation only: renders without SessionController or Supabase dependency',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningProgressCard(
              goalTitle: 'Offline Presentation Goal',
              completionPercent: 50,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Presentation Goal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03D-33: Presentation only: does not trigger routing side effects or activation',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: LearningProgressCard(
            goalTitle: 'Passive Goal',
            onResume: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resume Learning'));
      await tester.pumpAndSettle();

      expect(find.byType(LearningProgressCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03D-34: Security boundary: strictly displays supplied Learning values without cross-module leakage',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Learning Module Goal',
            weeklyCommitmentText: '3 hrs/week',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no Social, Hobbies, MoodTone, or Flight Points strings exist
      expect(find.textContaining('MoodTone'), findsNothing);
      expect(find.textContaining('Hobbies'), findsNothing);
      expect(find.textContaining('Social'), findsNothing);
      expect(find.textContaining('Flight Points'), findsNothing);
      expect(find.text('Learning Module Goal'), findsOneWidget);
    });

    testWidgets(
        'TEST-03D-35: Growth integrity: displays progress without unverified XP, streaks, or certificates',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningProgressCard(
            goalTitle: 'Verified Evidence Boundary Goal',
            completionPercent: 80,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no manufactured XP, streaks, or gamification claims
      expect(find.textContaining('XP'), findsNothing);
      expect(find.textContaining('Streak'), findsNothing);
      expect(find.textContaining('Level'), findsNothing);
      expect(find.textContaining('Mentor Eligible'), findsNothing);
      expect(find.text('80%'), findsOneWidget);
    });
  });
}
