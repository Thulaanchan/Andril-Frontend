import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/home/widgets/learning_home_header.dart';

/// Test helper providing a deterministic simulated failing [ImageProvider].
class _TestFailingImageProvider
    extends ImageProvider<_TestFailingImageProvider> {
  const _TestFailingImageProvider();

  @override
  Future<_TestFailingImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<_TestFailingImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      _TestFailingImageProvider key, ImageDecoderCallback decode) {
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    completer.completeError(Exception('Simulated avatar load failure'));
    return OneFrameImageStreamCompleter(completer.future);
  }
}

/// Standard test harness wrapping the header with theme and explicit viewport constraints.
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
  group('LearningHomeHeader - Dedicated Widget Tests (Batch 03B)', () {
    // =========================================================================
    // GROUP A: Greeting and Display Name
    // =========================================================================
    testWidgets('TEST-03B-01: Standard greeting and display name rendered',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(displayName: 'Thusha'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Thusha'), findsOneWidget);
    });

    testWidgets('TEST-03B-02: Custom greeting replaces default greeting',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(
            displayName: 'Thusha',
            greeting: 'Good morning',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
      expect(find.text('Thusha'), findsOneWidget);
    });

    testWidgets('TEST-03B-03: Empty name falls back to Learner label',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(displayName: ''),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Learner'), findsOneWidget);
    });

    testWidgets('TEST-03B-04: Whitespace-only name falls back to Learner label',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(displayName: '   \t  \n '),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learner'), findsOneWidget);
    });

    testWidgets(
        'TEST-03B-05: Long name constrained safely without RenderFlex overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(320, 600),
          child: const LearningHomeHeader(
            displayName:
                'Dr. Alexandrina Constantina Montgomery-Wellington III',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Dr. Alexandrina Constantina Montgomery-Wellington III'),
        findsOneWidget,
      );
    });

    testWidgets(
        'TEST-03B-06: Tamil and mixed Unicode display names render safely',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(
            displayName: 'துஷாந்தன் (Thusha) 🌟',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('துஷாந்தன் (Thusha) 🌟'), findsOneWidget);
    });

    // =========================================================================
    // GROUP B: Avatar Rendering and Error Fallback
    // =========================================================================
    testWidgets(
        'TEST-03B-07: Null avatar renders neutral icon placeholder with semantics',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(displayName: 'Thusha'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(
        find.bySemanticsLabel('Profile avatar for Thusha'),
        findsOneWidget,
      );

      final CircleAvatar avatar =
          tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.foregroundImage, isNull);
    });

    testWidgets(
        'TEST-03B-08: Caller-provided avatar image is bound to CircleAvatar',
        (tester) async {
      const testImage = AssetImage('assets/branding/andril_black_logo.png');
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(
            displayName: 'Thusha',
            avatarImage: testImage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final CircleAvatar avatar =
          tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.foregroundImage, equals(testImage));
    });

    testWidgets(
        'TEST-03B-09: Failed avatar image suppresses error and falls back safely',
        (tester) async {
      const failingImage = _TestFailingImageProvider();
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(
            displayName: 'Thusha',
            avatarImage: failingImage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no unhandled framework exception escaped
      expect(tester.takeException(), isNull);

      // Verify the fallback child icon remains present in the tree
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    // =========================================================================
    // GROUP C: Optional Status Label
    // =========================================================================
    testWidgets('TEST-03B-10: Status supplied renders status badge',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(
            displayName: 'Thusha',
            statusText: 'In Progress: Clean Architecture',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('In Progress: Clean Architecture'), findsOneWidget);
    });

    testWidgets(
        'TEST-03B-11: Null and whitespace status are omitted completely',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(
            displayName: 'Thusha',
            statusText: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only 2 Text widgets: greeting ('Welcome back') and displayName ('Thusha')
      expect(find.byType(Text), findsNWidgets(2));

      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(
            displayName: 'Thusha',
            statusText: '   \t  \n ',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets(
        'TEST-03B-12: Long status text does not overflow narrow layouts',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(320, 600),
          child: const LearningHomeHeader(
            displayName: 'Thusha',
            statusText:
                'Completing Phase 10 Advanced Architecture Module with Honors & Distinctions',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Completing Phase 10 Advanced Architecture Module with Honors & Distinctions',
        ),
        findsOneWidget,
      );
    });

    // =========================================================================
    // GROUP D: Notification Callback
    // =========================================================================
    testWidgets(
        'TEST-03B-13: Notification callback renders button and fires on tap',
        (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        _buildTestHarness(
          child: LearningHomeHeader(
            displayName: 'Thusha',
            onNotificationTap: () => tapCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final notifButton = find.byIcon(Icons.notifications_outlined);
      expect(notifButton, findsOneWidget);

      await tester.tap(notifButton);
      await tester.pump();
      expect(tapCount, equals(1));
    });

    testWidgets('TEST-03B-14: Callback absent renders no notification button',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(
            displayName: 'Thusha',
            onNotificationTap: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });

    testWidgets(
        'TEST-03B-15: Notification action has accessible semantics and touch target',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: LearningHomeHeader(
            displayName: 'Thusha',
            onNotificationTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Learning notifications'),
        findsOneWidget,
      );

      final IconButton button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.notifications_outlined),
      );
      expect(button.constraints?.minWidth, greaterThanOrEqualTo(48.0));
      expect(button.constraints?.minHeight, greaterThanOrEqualTo(48.0));
    });

    // =========================================================================
    // GROUP E: Responsive Viewport Behavior
    // =========================================================================
    testWidgets(
        'TEST-03B-16: 320dp Android width renders safely without overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(320, 600),
          child: LearningHomeHeader(
            displayName: 'Thusha',
            statusText: 'Learning Flutter',
            onNotificationTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03B-17: 360dp Android width renders safely without overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(360, 640),
          child: LearningHomeHeader(
            displayName: 'Thusha',
            statusText: 'Learning Flutter',
            onNotificationTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03B-18: 412dp Android width renders safely without overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(412, 892),
          child: LearningHomeHeader(
            displayName: 'Thusha',
            statusText: 'Learning Flutter',
            onNotificationTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('TEST-03B-19: 1.5x text scaling renders without overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(320, 600),
          textScaler: const TextScaler.linear(1.5),
          child: LearningHomeHeader(
            displayName: 'Thusha',
            statusText: 'Learning Flutter',
            onNotificationTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03B-20: Long text at 320dp narrow width with notification action renders safely',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(320, 600),
          child: LearningHomeHeader(
            displayName:
                'Dr. Alexandrina Constantina Montgomery-Wellington III',
            statusText:
                'Mastering Advanced Reactive State Management & Deep Neural Systems',
            onNotificationTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LearningHomeHeader), findsOneWidget);
    });

    // =========================================================================
    // GROUP F: Security and Presentation Boundaries
    // =========================================================================
    testWidgets(
        'TEST-03B-21: Presentation only: renders without SessionController or Supabase dependency',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningHomeHeader(
              displayName: 'Offline Presentation Learner',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Presentation Learner'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03B-22: Presentation only: does not trigger routing or activation',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: LearningHomeHeader(
            displayName: 'Passive Learner',
            onNotificationTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(LearningHomeHeader), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-03B-23: Security boundary: strictly displays supplied Learning values without cross-module leakage',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: const LearningHomeHeader(
            displayName: 'Learning Only User',
            statusText: 'Module Scope: Learning',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Confirm no Social or Hobbies terms or attributes are rendered or leaked
      expect(find.textContaining('MoodTone'), findsNothing);
      expect(find.textContaining('Hobbies'), findsNothing);
      expect(find.textContaining('Social'), findsNothing);
      expect(find.textContaining('Flight Points'), findsNothing);
      expect(find.text('Learning Only User'), findsOneWidget);
    });
  });
}
