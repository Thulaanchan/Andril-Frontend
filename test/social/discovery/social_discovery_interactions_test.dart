import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_pass_confirmation.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_interest_feedback.dart';

void main() {
  group('SocialPassConfirmationModal (Task 128 / S53)', () {
    testWidgets('renders candidate name, explanation, and action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialPassConfirmationModal(
              candidateName: 'Rohan',
              onConfirmPass: () {},
            ),
          ),
        ),
      );

      expect(find.text('Pass on Rohan?'), findsOneWidget);
      expect(
        find.textContaining('You won\'t see Rohan\'s profile in your discovery recommendations.'),
        findsOneWidget,
      );
      expect(find.text('Pass on Profile'), findsOneWidget);
      expect(find.text('Keep Exploring'), findsOneWidget);
    });

    testWidgets('confirm button invokes callback and handles submission state', (tester) async {
      var confirmCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialPassConfirmationModal(
              candidateName: 'Rohan',
              onConfirmPass: () => confirmCallCount++,
            ),
          ),
        ),
      );

      final passButton = find.byType(ElevatedButton);
      expect(passButton, findsOneWidget);
      await tester.tap(passButton);
      await tester.pump();

      expect(confirmCallCount, 1);
    });

    testWidgets('cancel button invokes onCancel callback', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialPassConfirmationModal(
              candidateName: 'Rohan',
              onConfirmPass: () {},
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Keep Exploring'));
      await tester.pump();
      expect(cancelCalled, isTrue);
    });

    testWidgets('renders cleanly across viewports without overflow', (tester) async {
      for (final width in [320.0, 400.0, 800.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialPassConfirmationModal(
                candidateName: 'Rohan',
                onConfirmPass: () {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      }
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });

  group('SocialInterestFeedbackSheet (Task 129 / S11, S54, S55)', () {
    testWidgets('renders S11 Interest Sent variant correctly', (tester) async {
      var primaryCalled = false;
      var secondaryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialInterestFeedbackSheet(
              type: SocialInterestFeedbackType.sent,
              candidateName: 'Ananya',
              onPrimaryAction: () => primaryCalled = true,
              onSecondaryAction: () => secondaryCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Interest Sent!'), findsOneWidget);
      expect(find.textContaining('We\'ve notified Ananya that you like them.'), findsOneWidget);
      expect(find.text('Keep Exploring'), findsOneWidget);
      expect(find.text('View Sent Likes'), findsOneWidget);

      await tester.tap(find.text('View Sent Likes'));
      await tester.pump();
      expect(secondaryCalled, isTrue);
      expect(primaryCalled, isFalse);
    });

    testWidgets('renders S54 Pending Interest variant correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SocialInterestFeedbackSheet(
              type: SocialInterestFeedbackType.pending,
              candidateName: 'Ananya',
            ),
          ),
        ),
      );

      expect(find.text('Interest Pending'), findsOneWidget);
      expect(find.textContaining('You already expressed interest in Ananya.'), findsOneWidget);
      expect(find.text('Got It'), findsOneWidget);
    });

    testWidgets('renders S55 Interest Unavailable variant correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SocialInterestFeedbackSheet(
              type: SocialInterestFeedbackType.unavailable,
              candidateName: 'Ananya',
            ),
          ),
        ),
      );

      expect(find.text('Profile Unavailable'), findsOneWidget);
      expect(find.textContaining('This profile is no longer available'), findsOneWidget);
      expect(find.text('Continue Exploring'), findsOneWidget);
    });

    testWidgets('does not manufacture mutual match or provide chat triggers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SocialInterestFeedbackSheet(
              type: SocialInterestFeedbackType.sent,
              candidateName: 'Ananya',
            ),
          ),
        ),
      );

      // Ensures chat initiation is never authorized from one-sided feedback
      expect(find.text('Chat'), findsNothing);
      expect(find.text('Start Chat'), findsNothing);
      expect(find.text('Send Message'), findsNothing);
    });

    testWidgets('renders cleanly across viewports without overflow', (tester) async {
      for (final width in [320.0, 400.0, 800.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SocialInterestFeedbackSheet(
                type: SocialInterestFeedbackType.sent,
                candidateName: 'Ananya',
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      }
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
