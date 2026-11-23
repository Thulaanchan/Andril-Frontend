import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/home/widgets/learning_home_action_grid.dart';

/// Test harness wrapping [LearningHomeActionGrid] with theme and explicit viewport constraints.
Widget _buildActionGridHarness({
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
  group('LearningHomeActionGrid - Dedicated Widget Tests (Batch 03F)', () {
    // =========================================================================
    // GROUP A: Rendering and Empty States
    // =========================================================================
    testWidgets('TEST-03F-01: Empty actions list renders neutral empty state',
        (tester) async {
      await tester.pumpWidget(
        _buildActionGridHarness(
          child: const LearningHomeActionGrid(actions: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Learning Hub'), findsOneWidget);
      expect(find.text('No learning actions available'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('TEST-03F-02: Single action renders title and icon',
        (tester) async {
      final action = LearningHomeActionItem(
        id: 'classrooms',
        title: 'Classrooms',
        icon: Icons.school_outlined,
        onTap: () {},
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Classrooms'), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      expect(find.text('No learning actions available'), findsNothing);
    });

    testWidgets(
        'TEST-03F-03: Multiple actions render without duplication or omission',
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
          title: 'Study Circles',
          icon: Icons.groups_outlined,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'pacts',
          title: 'Learning Pacts',
          icon: Icons.handshake_outlined,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'cv_maker',
          title: 'CV Maker',
          icon: Icons.description_outlined,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Classrooms'), findsOneWidget);
      expect(find.text('Study Circles'), findsOneWidget);
      expect(find.text('Learning Pacts'), findsOneWidget);
      expect(find.text('CV Maker'), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(4));
    });

    testWidgets('TEST-03F-04: Custom section title replaces default',
        (tester) async {
      await tester.pumpWidget(
        _buildActionGridHarness(
          child: const LearningHomeActionGrid(
            actions: [],
            title: 'Featured Learning Tools',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Featured Learning Tools'), findsOneWidget);
      expect(find.text('My Learning Hub'), findsNothing);
    });

    testWidgets('TEST-03F-05: Default section title renders when unspecified',
        (tester) async {
      await tester.pumpWidget(
        _buildActionGridHarness(
          child: const LearningHomeActionGrid(actions: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Learning Hub'), findsOneWidget);
    });

    testWidgets('TEST-03F-06: Caller-provided ordering is strictly preserved',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: 'z_item',
          title: 'Zebra Tool',
          icon: Icons.bookmark_border,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'a_item',
          title: 'Alpha Tool',
          icon: Icons.star_border,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      final firstText = tester.getTopLeft(find.text('Zebra Tool'));
      final secondText = tester.getTopLeft(find.text('Alpha Tool'));
      expect(firstText.dx, lessThan(secondText.dx));
    });

    // =========================================================================
    // GROUP B: Enabled Actions and Callbacks
    // =========================================================================
    testWidgets(
        'TEST-03F-07: Valid action with callback and no restriction is available',
        (tester) async {
      final item = LearningHomeActionItem(
        id: '1',
        title: 'Action 1',
        icon: Icons.star,
        onTap: () {},
      );

      expect(item.isAvailable, isTrue);
    });

    testWidgets(
        'TEST-03F-08: Tapping an enabled action invokes callback exactly once',
        (tester) async {
      int tapCount = 0;
      final action = LearningHomeActionItem(
        id: 'tap_test',
        title: 'Tap Me',
        icon: Icons.touch_app,
        onTap: () => tapCount++,
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap Me'));
      await tester.pump();
      expect(tapCount, equals(1));
    });

    testWidgets(
        'TEST-03F-09: Independent callbacks: tapping item A only executes callback A',
        (tester) async {
      int countA = 0;
      int countB = 0;

      final actions = [
        LearningHomeActionItem(
          id: 'a',
          title: 'Item A',
          icon: Icons.looks_one,
          onTap: () => countA++,
        ),
        LearningHomeActionItem(
          id: 'b',
          title: 'Item B',
          icon: Icons.looks_two,
          onTap: () => countB++,
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Item A'));
      await tester.pump();

      expect(countA, equals(1));
      expect(countB, equals(0));
    });

    testWidgets(
        'TEST-03F-10: Repeated legitimate taps execute callback per tap',
        (tester) async {
      int tapCount = 0;
      final action = LearningHomeActionItem(
        id: 'multi_tap',
        title: 'Multi Tap',
        icon: Icons.touch_app,
        onTap: () => tapCount++,
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Multi Tap'));
      await tester.pump();
      await tester.tap(find.text('Multi Tap'));
      await tester.pump();

      expect(tapCount, equals(2));
    });

    testWidgets('TEST-03F-11: Action with null callback is non-interactive',
        (tester) async {
      final action = const LearningHomeActionItem(
        id: 'no_cb',
        title: 'No Callback',
        icon: Icons.lock_outline,
        onTap: null,
      );

      expect(action.isAvailable, isFalse);

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });

    testWidgets(
        'TEST-03F-12: Action with unavailableReason is non-interactive despite callback',
        (tester) async {
      int tapCount = 0;
      final action = LearningHomeActionItem(
        id: 'unavail',
        title: 'Future Feature',
        icon: Icons.schedule,
        onTap: () => tapCount++,
        unavailableReason: 'Coming soon',
      );

      expect(action.isAvailable, isFalse);

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coming soon'), findsOneWidget);
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);

      await tester.tap(find.text('Future Feature'));
      await tester.pump();
      expect(tapCount, equals(0));
    });

    testWidgets('TEST-03F-13: Empty unavailableReason leaves action available',
        (tester) async {
      int tapCount = 0;
      final action = LearningHomeActionItem(
        id: 'empty_reason',
        title: 'Available Tool',
        icon: Icons.check,
        onTap: () => tapCount++,
        unavailableReason: '',
      );

      expect(action.isAvailable, isTrue);

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Available Tool'));
      await tester.pump();
      expect(tapCount, equals(1));
    });

    testWidgets(
        'TEST-03F-14: Whitespace-only unavailableReason leaves action available',
        (tester) async {
      int tapCount = 0;
      final action = LearningHomeActionItem(
        id: 'ws_reason',
        title: 'Available Tool WS',
        icon: Icons.check,
        onTap: () => tapCount++,
        unavailableReason: '   \t  \n  ',
      );

      expect(action.isAvailable, isTrue);

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Available Tool WS'));
      await tester.pump();
      expect(tapCount, equals(1));
    });

    testWidgets(
        'TEST-03F-15: Meaningful caller-supplied reason is displayed on card',
        (tester) async {
      final action = const LearningHomeActionItem(
        id: 'under_maint',
        title: 'Peer Chat',
        icon: Icons.chat_bubble_outline,
        unavailableReason: 'Under maintenance',
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Under maintenance'), findsOneWidget);
    });

    // =========================================================================
    // GROUP C: Input and State Safety
    // =========================================================================
    testWidgets('TEST-03F-16: Action list is not mutated by rendering or tap',
        (tester) async {
      final actions = List<LearningHomeActionItem>.from([
        LearningHomeActionItem(
          id: '1',
          title: 'Action 1',
          icon: Icons.star,
          onTap: () {},
        ),
      ]);

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Action 1'));
      await tester.pump();

      expect(actions.length, equals(1));
      expect(actions.first.id, equals('1'));
    });

    testWidgets(
        'TEST-03F-17: Stable item identity and callback mapping across reordering and rebuilds',
        (tester) async {
      int countA = 0;
      int countB = 0;
      int countC = 0;

      // 1. Initial order: A, B (unavailable), C
      final actionsInitial = [
        LearningHomeActionItem(
          id: 'action_a',
          title: 'Action Alpha',
          icon: Icons.looks_one,
          onTap: () => countA++,
        ),
        LearningHomeActionItem(
          id: 'action_b',
          title: 'Action Beta',
          icon: Icons.looks_two,
          onTap: () => countB++,
          unavailableReason: 'Locked initially',
        ),
        LearningHomeActionItem(
          id: 'action_c',
          title: 'Action Gamma',
          icon: Icons.looks_3,
          onTap: () => countC++,
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actionsInitial),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial layout order and keys
      expect(find.byKey(const Key('action_a')), findsOneWidget);
      expect(find.byKey(const Key('action_b')), findsOneWidget);
      expect(find.byKey(const Key('action_c')), findsOneWidget);

      final posA1 = tester.getTopLeft(find.text('Action Alpha'));
      final posB1 = tester.getTopLeft(find.text('Action Beta'));
      expect(posA1.dx, lessThan(posB1.dx));

      // Initial tap on Alpha (enabled) works
      await tester.tap(find.text('Action Alpha'));
      await tester.pump();
      expect(countA, equals(1));

      // Initial tap on Beta (unavailable) does nothing
      await tester.tap(find.text('Action Beta'));
      await tester.pump();
      expect(countB, equals(0));

      // 2. Rebuild with reordered actions and changed availability: C, B (now enabled), A (now locked)
      final actionsReordered = [
        LearningHomeActionItem(
          id: 'action_c',
          title: 'Action Gamma',
          icon: Icons.looks_3,
          onTap: () => countC++,
        ),
        LearningHomeActionItem(
          id: 'action_b',
          title: 'Action Beta',
          icon: Icons.looks_two,
          onTap: () => countB++,
        ),
        LearningHomeActionItem(
          id: 'action_a',
          title: 'Action Alpha',
          icon: Icons.looks_one,
          onTap: () => countA++,
          unavailableReason: 'Now locked',
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actionsReordered),
        ),
      );
      await tester.pumpAndSettle();

      // Verify keys preserved
      expect(find.byKey(const Key('action_a')), findsOneWidget);
      expect(find.byKey(const Key('action_b')), findsOneWidget);
      expect(find.byKey(const Key('action_c')), findsOneWidget);

      // Verify new visual order (Gamma is now first, Beta is second)
      final posC2 = tester.getTopLeft(find.text('Action Gamma'));
      final posB2 = tester.getTopLeft(find.text('Action Beta'));
      expect(posC2.dx, lessThan(posB2.dx));

      // Tap Gamma (C): countC increments
      await tester.tap(find.text('Action Gamma'));
      await tester.pump();
      expect(countC, equals(1));
      expect(countA, equals(1)); // unchanged

      // Tap Beta (B, now enabled): countB increments
      await tester.tap(find.text('Action Beta'));
      await tester.pump();
      expect(countB, equals(1));

      // Tap Alpha (A, now locked): countA does not increment
      await tester.tap(find.text('Action Alpha'));
      await tester.pump();
      expect(countA, equals(1));

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03F-18: Ordinary rendering is safe with distinct IDs without uncaught exceptions',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: 'action_ordinary_1',
          title: 'Primary Action',
          icon: Icons.explore_outlined,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'action_ordinary_2',
          title: 'Secondary Action',
          icon: Icons.bookmark_border_outlined,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Primary Action'), findsOneWidget);
      expect(find.text('Secondary Action'), findsOneWidget);
    });

    testWidgets(
        'TEST-03F-19: Empty action title renders safely without unhandled errors',
        (tester) async {
      final action = LearningHomeActionItem(
        id: 'empty_title',
        title: '',
        icon: Icons.help_outline,
        onTap: () {},
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets(
        'TEST-03F-20: Long action title wraps up to 2 lines without RenderFlex overflow',
        (tester) async {
      final action = LearningHomeActionItem(
        id: 'long_title',
        title:
            'Advanced Full Stack Flutter Microservices & Reactive Cloud Architecture',
        icon: Icons.architecture,
        onTap: () {},
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          size: const Size(320, 600),
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(
            'Advanced Full Stack Flutter Microservices & Reactive Cloud Architecture'),
        findsOneWidget,
      );
    });

    testWidgets('TEST-03F-21: Tamil and mixed Unicode labels render safely',
        (tester) async {
      final action = LearningHomeActionItem(
        id: 'tamil_title',
        title: 'கற்றல் வட்டங்கள் 📘',
        icon: Icons.groups,
        onTap: () {},
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('கற்றல் வட்டங்கள் 📘'), findsOneWidget);
    });

    // =========================================================================
    // GROUP D: Responsive Layout
    // =========================================================================
    testWidgets(
        'TEST-03F-22: Narrow viewport below 260dp adapts to 1 column without overflow',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: '1',
          title: 'Action 1',
          icon: Icons.star,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: '2',
          title: 'Action 2',
          icon: Icons.star,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          size: const Size(240, 600),
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final firstTop = tester.getTopLeft(find.text('Action 1'));
      final secondTop = tester.getTopLeft(find.text('Action 2'));
      // In single column, item 2 sits below item 1
      expect(secondTop.dy, greaterThan(firstTop.dy));
    });

    testWidgets(
        'TEST-03F-23: 320dp Android width renders 2 columns without overflow',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: '1',
          title: 'Classrooms',
          icon: Icons.school,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: '2',
          title: 'Mentorship',
          icon: Icons.person,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          size: const Size(320, 600),
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final firstTop = tester.getTopLeft(find.text('Classrooms'));
      final secondTop = tester.getTopLeft(find.text('Mentorship'));
      expect(firstTop.dx, lessThan(secondTop.dx));
    });

    testWidgets('TEST-03F-24: 360dp Android width renders without overflow',
        (tester) async {
      final actions = List.generate(
        4,
        (i) => LearningHomeActionItem(
          id: '$i',
          title: 'Shortcut $i',
          icon: Icons.star,
          onTap: () {},
        ),
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          size: const Size(360, 640),
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('TEST-03F-25: 412dp Android width renders without overflow',
        (tester) async {
      final actions = List.generate(
        4,
        (i) => LearningHomeActionItem(
          id: '$i',
          title: 'Shortcut $i',
          icon: Icons.star,
          onTap: () {},
        ),
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          size: const Size(412, 892),
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('TEST-03F-26: Wide layout at 600dp adapts to 3 columns safely',
        (tester) async {
      final actions = List.generate(
        3,
        (i) => LearningHomeActionItem(
          id: '$i',
          title: 'Tool $i',
          icon: Icons.star,
          onTap: () {},
        ),
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          size: const Size(600, 800),
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final pos0 = tester.getTopLeft(find.text('Tool 0'));
      final pos1 = tester.getTopLeft(find.text('Tool 1'));
      final pos2 = tester.getTopLeft(find.text('Tool 2'));

      // In 3 columns, all 3 items fit on the same horizontal row
      expect(pos0.dx, lessThan(pos1.dx));
      expect(pos1.dx, lessThan(pos2.dx));
    });

    testWidgets(
        'TEST-03F-27: 1.5x dynamic text scaling renders without overflow',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: '1',
          title: 'Study Groups',
          icon: Icons.group,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: '2',
          title: 'Mentorship',
          icon: Icons.person,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          size: const Size(320, 600),
          textScaler: const TextScaler.linear(1.5),
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03F-28: Combined narrow-screen stress test: 320dp, 1.5x scale, long Unicode & unavailable',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: '1',
          title: 'முழுமையான கற்றல் வட்டங்கள் மற்றும் கலந்துரையாடல்கள்',
          icon: Icons.groups,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: '2',
          title: 'செயற்கை நுண்ணறிவு வழிகாட்டி',
          icon: Icons.psychology,
          onTap: () {},
          unavailableReason: 'விரைவில் எதிர்பார்க்கப்படுகிறது',
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          size: const Size(320, 600),
          textScaler: const TextScaler.linear(1.5),
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LearningHomeActionGrid), findsOneWidget);
      expect(find.text('விரைவில் எதிர்பார்க்கப்படுகிறது'), findsOneWidget);
    });

    testWidgets(
        'TEST-03F-29: Embedded in constrained parent width respects bounds',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: '1',
          title: 'Item 1',
          icon: Icons.star,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: LearningTheme.theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                child: LearningHomeActionGrid(actions: actions),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // GROUP E: Accessibility and Semantics
    // =========================================================================
    testWidgets(
        'TEST-03F-30: Available action exposes button semantics with label',
        (tester) async {
      final action = LearningHomeActionItem(
        id: 'acc_btn',
        title: 'Interactive Card',
        icon: Icons.touch_app,
        onTap: () {},
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.enabled == true &&
            w.properties.label == 'Interactive Card'),
        findsOneWidget,
      );
    });

    testWidgets(
        'TEST-03F-31: Unavailable action is not exposed as enabled button',
        (tester) async {
      final action = const LearningHomeActionItem(
        id: 'dis_btn',
        title: 'Disabled Card',
        icon: Icons.lock,
        unavailableReason: 'Locked',
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.button == false &&
            w.properties.enabled == false &&
            w.properties.label == 'Disabled Card'),
        findsOneWidget,
      );
    });

    testWidgets(
        'TEST-03F-32: Unavailability explanation is exposed in accessibility hint',
        (tester) async {
      final action = const LearningHomeActionItem(
        id: 'hint_test',
        title: 'Feature X',
        icon: Icons.lock,
        unavailableReason: 'Requires Level 2',
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.hint == 'Requires Level 2'),
        findsOneWidget,
      );
    });

    testWidgets('TEST-03F-33: Touch target exceeds 48x48dp minimum standard',
        (tester) async {
      final action = LearningHomeActionItem(
        id: 'touch_target',
        title: 'Touch Card',
        icon: Icons.touch_app,
        onTap: () {},
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      final Size cardSize = tester.getSize(find.byType(InkWell));
      expect(cardSize.width, greaterThanOrEqualTo(48.0));
      expect(cardSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('TEST-03F-34: No duplicate semantic action announcements',
        (tester) async {
      final action = LearningHomeActionItem(
        id: 'clean_sem',
        title: 'Unique Item',
        icon: Icons.star,
        onTap: () {},
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      final semanticsFinder = find.byWidgetPredicate((w) =>
          w is Semantics &&
          w.properties.button == true &&
          w.properties.label == 'Unique Item');
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets(
        'TEST-03F-35: Keyboard/focus behavior: available action acquires focus and activates via keyboard',
        (tester) async {
      int tapCount = 0;
      final action = LearningHomeActionItem(
        id: 'focus_test',
        title: 'Focusable Card',
        icon: Icons.keyboard,
        onTap: () => tapCount++,
      );
      final disabledAction = const LearningHomeActionItem(
        id: 'disabled_focus',
        title: 'Disabled Focus Card',
        icon: Icons.lock,
        unavailableReason: 'Locked for focus test',
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action, disabledAction]),
        ),
      );
      await tester.pumpAndSettle();

      // Obtain the FocusNode managed by the interactive InkWell
      final focusNode = Focus.of(tester.element(find.text('Focusable Card')));
      focusNode.requestFocus();
      await tester.pump();

      // Verify focus is held
      expect(focusNode.hasFocus, isTrue);

      // Activate via Enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(tapCount, equals(1));

      // Activate via Space key
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(tapCount, equals(2));

      // Verify disabled card cannot receive focus
      final disabledFinder = find.text('Disabled Focus Card');
      final disabledFocusNode = Focus.of(tester.element(disabledFinder));
      // Disabled card should not be the same focus node and cannot hold primary focus
      expect(disabledFocusNode.hasPrimaryFocus, isFalse);
      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // GROUP F: Security and Navigation Boundaries
    // =========================================================================
    testWidgets(
        'TEST-03F-36: Renders offline without SessionController or Supabase dependency',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningHomeActionGrid(actions: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Learning Hub'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03F-37: Tapping action dispatches callback without auto-navigation',
        (tester) async {
      bool tapped = false;
      final action = LearningHomeActionItem(
        id: 'nav_boundary',
        title: 'Passive Shortcut',
        icon: Icons.link,
        onTap: () => tapped = true,
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Passive Shortcut'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      // Confirms grid remains on screen and no route was pushed independently
      expect(find.byType(LearningHomeActionGrid), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03F-38: Disabled action never executes navigation callback',
        (tester) async {
      bool tapped = false;
      final action = LearningHomeActionItem(
        id: 'disabled_nav',
        title: 'Locked Shortcut',
        icon: Icons.lock,
        onTap: () => tapped = true,
        unavailableReason: 'Locked by system',
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Locked Shortcut'));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });

    testWidgets(
        'TEST-03F-39: Displays strictly caller-provided actions without unapproved defaults',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: 'custom_only',
          title: 'Custom Action',
          icon: Icons.check,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Action'), findsOneWidget);
      // Confirms unapproved shortcuts are never automatically synthesized
      expect(find.text('Classrooms'), findsNothing);
      expect(find.text('Mentorship'), findsNothing);
      expect(find.text('XP & Achievements'), findsNothing);
      expect(find.text('AI Chat'), findsNothing);
    });

    testWidgets(
        'TEST-03F-40: Module privacy: strictly no cross-module data leaked',
        (tester) async {
      await tester.pumpWidget(
        _buildActionGridHarness(
          child: const LearningHomeActionGrid(actions: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('MoodTone'), findsNothing);
      expect(find.textContaining('Hobbies'), findsNothing);
      expect(find.textContaining('Social'), findsNothing);
      expect(find.textContaining('Flight Points'), findsNothing);
    });

    testWidgets(
        'TEST-03F-41: Rendering does not mutate authorization or module activation',
        (tester) async {
      bool localSentinel = false;
      final action = LearningHomeActionItem(
        id: 'sentinel',
        title: 'Sentinel Test',
        icon: Icons.shield,
        onTap: () => localSentinel = true,
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      expect(localSentinel, isFalse);
    });

    testWidgets('TEST-03F-42: No fabricated rewards, streaks, or XP displays',
        (tester) async {
      final action = LearningHomeActionItem(
        id: '1',
        title: 'Action Item',
        icon: Icons.star,
        onTap: () {},
      );

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: [action]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('XP'), findsNothing);
      expect(find.textContaining('Streak'), findsNothing);
      expect(find.textContaining('Level'), findsNothing);
      expect(find.textContaining('Coins'), findsNothing);
    });

    // =========================================================================
    // GROUP G: Direct Fail-Closed Duplicate-ID Regression (Batch 03G-2)
    // Rule ID: AND-LRN-HOME-03G-01
    // =========================================================================
    testWidgets(
        'TEST-03G-2-01: Adjacent duplicate IDs exclude conflicting items and render unique item',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: 'action_a',
          title: 'Action A1',
          icon: Icons.looks_one,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'action_a',
          title: 'Action A2',
          icon: Icons.looks_two,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'action_b',
          title: 'Action B',
          icon: Icons.star,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Action A1'), findsNothing);
      expect(find.text('Action A2'), findsNothing);
      expect(find.text('Action B'), findsOneWidget);
      expect(find.byKey(const Key('action_a')), findsNothing);
      expect(find.byKey(const Key('action_b')), findsOneWidget);
    });

    testWidgets(
        'TEST-03G-2-02: Separated duplicate IDs exclude conflicting items and preserve ordering',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: 'action_a',
          title: 'Action A1',
          icon: Icons.looks_one,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'action_b',
          title: 'Action B',
          icon: Icons.star,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'action_a',
          title: 'Action A2',
          icon: Icons.looks_two,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'action_c',
          title: 'Action C',
          icon: Icons.check,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Action A1'), findsNothing);
      expect(find.text('Action A2'), findsNothing);
      expect(find.text('Action B'), findsOneWidget);
      expect(find.text('Action C'), findsOneWidget);

      final posB = tester.getTopLeft(find.text('Action B'));
      final posC = tester.getTopLeft(find.text('Action C'));
      expect(posB.dx, lessThan(posC.dx));
    });

    testWidgets(
        'TEST-03G-2-03: All IDs conflicting renders empty state without exceptions',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: 'action_a',
          title: 'Action A1',
          icon: Icons.looks_one,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'action_a',
          title: 'Action A2',
          icon: Icons.looks_one,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'action_b',
          title: 'Action B1',
          icon: Icons.looks_two,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'action_b',
          title: 'Action B2',
          icon: Icons.looks_two,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('No learning actions available'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets(
        'TEST-03G-2-04: Multiple conflicting IDs with one safe item renders only safe item',
        (tester) async {
      int countC = 0;
      final actions = [
        LearningHomeActionItem(
          id: 'dup_1',
          title: 'Dup 1 First',
          icon: Icons.looks_one,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'dup_2',
          title: 'Dup 2 First',
          icon: Icons.looks_two,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'dup_1',
          title: 'Dup 1 Second',
          icon: Icons.looks_one,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'dup_2',
          title: 'Dup 2 Second',
          icon: Icons.looks_two,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'safe_c',
          title: 'Safe Action C',
          icon: Icons.verified,
          onTap: () => countC++,
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Safe Action C'), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.text('Safe Action C'));
      await tester.pump();
      expect(countC, equals(1));
    });

    testWidgets(
        'TEST-03G-2-05: Same ID with different callbacks excludes both and invokes neither callback',
        (tester) async {
      int countA1 = 0;
      int countA2 = 0;
      int countSafe = 0;

      final actions = [
        LearningHomeActionItem(
          id: 'conflict_id',
          title: 'Conflicting Item 1',
          icon: Icons.warning,
          onTap: () => countA1++,
        ),
        LearningHomeActionItem(
          id: 'conflict_id',
          title: 'Conflicting Item 2',
          icon: Icons.warning,
          onTap: () => countA2++,
        ),
        LearningHomeActionItem(
          id: 'safe_unique',
          title: 'Safe Unique Item',
          icon: Icons.check,
          onTap: () => countSafe++,
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Conflicting Item 1'), findsNothing);
      expect(find.text('Conflicting Item 2'), findsNothing);
      expect(find.text('Safe Unique Item'), findsOneWidget);

      await tester.tap(find.text('Safe Unique Item'));
      await tester.pump();

      expect(countSafe, equals(1));
      expect(countA1, equals(0));
      expect(countA2, equals(0));
    });

    testWidgets(
        'TEST-03G-2-06: Enabled and unavailable conflict excludes both and renders unique item',
        (tester) async {
      int enabledTap = 0;
      int safeTap = 0;

      final actions = [
        LearningHomeActionItem(
          id: 'circle',
          title: 'Enabled Circle',
          icon: Icons.circle,
          onTap: () => enabledTap++,
        ),
        LearningHomeActionItem(
          id: 'circle',
          title: 'Unavailable Circle',
          icon: Icons.circle_outlined,
          onTap: () {},
          unavailableReason: 'Locked by system',
        ),
        LearningHomeActionItem(
          id: 'unique_safe',
          title: 'Safe Action',
          icon: Icons.star,
          onTap: () => safeTap++,
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Enabled Circle'), findsNothing);
      expect(find.text('Unavailable Circle'), findsNothing);
      expect(find.text('Safe Action'), findsOneWidget);

      await tester.tap(find.text('Safe Action'));
      await tester.pump();

      expect(safeTap, equals(1));
      expect(enabledTap, equals(0));
    });

    testWidgets(
        'TEST-03G-2-07: Exact string equality treats case variants as distinct actions',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: 'circle',
          title: 'Lower Circle',
          icon: Icons.circle,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'Circle',
          title: 'Title Circle',
          icon: Icons.circle_outlined,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'CIRCLE',
          title: 'Upper Circle',
          icon: Icons.lens,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Lower Circle'), findsOneWidget);
      expect(find.text('Title Circle'), findsOneWidget);
      expect(find.text('Upper Circle'), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(3));
    });

    testWidgets('TEST-03G-2-08: Duplicate Unicode IDs are safely excluded',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: 'வட்டம்',
          title: 'Tamil Circle 1',
          icon: Icons.circle,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'வட்டம்',
          title: 'Tamil Circle 2',
          icon: Icons.circle_outlined,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'சதுரம்',
          title: 'Tamil Square',
          icon: Icons.crop_square,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Tamil Circle 1'), findsNothing);
      expect(find.text('Tamil Circle 2'), findsNothing);
      expect(find.text('Tamil Square'), findsOneWidget);
      expect(find.byKey(const Key('வட்டம்')), findsNothing);
      expect(find.byKey(const Key('சதுரம்')), findsOneWidget);
    });

    testWidgets(
        'TEST-03G-2-09: Duplicate empty-string IDs are excluded while unique action renders',
        (tester) async {
      final actions = [
        LearningHomeActionItem(
          id: '',
          title: 'Empty ID 1',
          icon: Icons.help_outline,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: '',
          title: 'Empty ID 2',
          icon: Icons.help_outline,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'valid_id',
          title: 'Valid Action',
          icon: Icons.check,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Empty ID 1'), findsNothing);
      expect(find.text('Empty ID 2'), findsNothing);
      expect(find.text('Valid Action'), findsOneWidget);
    });

    testWidgets('TEST-03G-2-10: Original caller action list remains unmutated',
        (tester) async {
      final item1 = LearningHomeActionItem(
        id: 'dup_item',
        title: 'Item 1',
        icon: Icons.looks_one,
        onTap: () {},
      );
      final item2 = LearningHomeActionItem(
        id: 'dup_item',
        title: 'Item 2',
        icon: Icons.looks_two,
        onTap: () {},
      );
      final item3 = LearningHomeActionItem(
        id: 'unique_item',
        title: 'Item 3',
        icon: Icons.looks_3,
        onTap: () {},
      );

      final actions = <LearningHomeActionItem>[item1, item2, item3];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      // Original caller list must remain completely unmodified
      expect(actions.length, equals(3));
      expect(identical(actions[0], item1), isTrue);
      expect(identical(actions[1], item2), isTrue);
      expect(identical(actions[2], item3), isTrue);
    });

    testWidgets(
        'TEST-03G-2-11: No duplicates means no filtering and all items interactive',
        (tester) async {
      int count1 = 0;
      int count2 = 0;

      final actions = [
        LearningHomeActionItem(
          id: 'clean_1',
          title: 'Clean Action 1',
          icon: Icons.star,
          onTap: () => count1++,
        ),
        LearningHomeActionItem(
          id: 'clean_2',
          title: 'Clean Action 2',
          icon: Icons.favorite,
          onTap: () => count2++,
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actions),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Clean Action 1'), findsOneWidget);
      expect(find.text('Clean Action 2'), findsOneWidget);

      await tester.tap(find.text('Clean Action 1'));
      await tester.pump();
      await tester.tap(find.text('Clean Action 2'));
      await tester.pump();

      expect(count1, equals(1));
      expect(count2, equals(1));
    });

    testWidgets(
        'TEST-03G-2-12: Rebuild changes conflict set and updates rendered actions dynamically',
        (tester) async {
      // Initial list has duplicate A, so only B renders
      final actionsInitial = [
        LearningHomeActionItem(
          id: 'id_a',
          title: 'Action A1',
          icon: Icons.looks_one,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'id_a',
          title: 'Action A2',
          icon: Icons.looks_two,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'id_b',
          title: 'Action B',
          icon: Icons.star,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actionsInitial),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Action A1'), findsNothing);
      expect(find.text('Action A2'), findsNothing);
      expect(find.text('Action B'), findsOneWidget);

      // Rebuild with unique A, B, C
      final actionsUpdated = [
        LearningHomeActionItem(
          id: 'id_a',
          title: 'Action A Unified',
          icon: Icons.looks_one,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'id_b',
          title: 'Action B',
          icon: Icons.star,
          onTap: () {},
        ),
        LearningHomeActionItem(
          id: 'id_c',
          title: 'Action C',
          icon: Icons.looks_3,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        _buildActionGridHarness(
          child: LearningHomeActionGrid(actions: actionsUpdated),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Action A Unified'), findsOneWidget);
      expect(find.text('Action B'), findsOneWidget);
      expect(find.text('Action C'), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(3));
    });
  });
}
