import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/social_relationship.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_connections_screen.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_match_history_screen.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_relationship_viewmodel.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_unmatch_confirmation.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_unmatched_screen.dart';

class _FakeRelationshipViewModel extends ChangeNotifier implements SocialRelationshipViewModel {
  @override
  SocialRelationshipViewStatus get status => SocialRelationshipViewStatus.ready;

  @override
  bool get isLoading => false;

  @override
  bool get isAccessDenied => false;

  @override
  bool get isServiceUnavailable => false;

  @override
  String? get errorMessage => null;

  @override
  SocialConnectionCategory get selectedCategory => SocialConnectionCategory.all;

  @override
  bool isOperationInProgress(String targetProfileId) => false;

  @override
  List<SocialRelationship> get connections => [
        SocialRelationship(
          id: 'rel-1',
          targetProfileId: 'u-target-1',
          candidate: SocialCandidate(
            id: 'u-target-1',
            displayName: 'Diya',
            age: 24,
          ),
          state: SocialRelationshipState.matched,
          createdAtUtc: DateTime.now(),
        ),
      ];

  @override
  List<SocialRelationship> get sentLikes => [];

  @override
  List<SocialRelationship> get receivedLikes => [];

  @override
  Future<void> loadConnections({
    SocialConnectionCategory category = SocialConnectionCategory.all,
    bool refresh = false,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SocialUnmatchConfirmationModal (Task 131 / S56)', () {
    testWidgets('renders target name, warning message, and action controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialUnmatchConfirmationModal(
              targetName: 'Kavya',
              onConfirmUnmatch: () {},
            ),
          ),
        ),
      );

      expect(find.text('Unmatch with Kavya?'), findsOneWidget);
      expect(find.textContaining('They will be removed from your connections'), findsOneWidget);
      expect(find.text('Unmatch'), findsOneWidget);
      expect(find.text('Keep Connection'), findsOneWidget);
    });

    testWidgets('confirm button invokes callback', (tester) async {
      var confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialUnmatchConfirmationModal(
              targetName: 'Kavya',
              onConfirmUnmatch: () => confirmed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Unmatch'));
      await tester.pump();
      expect(confirmed, isTrue);
    });

    testWidgets('cancel button invokes onCancel callback', (tester) async {
      var cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialUnmatchConfirmationModal(
              targetName: 'Kavya',
              onConfirmUnmatch: () {},
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Keep Connection'));
      await tester.pump();
      expect(cancelled, isTrue);
    });

    testWidgets('renders cleanly across viewports without overflow', (tester) async {
      for (final width in [320.0, 400.0, 800.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialUnmatchConfirmationModal(
                targetName: 'Kavya',
                onConfirmUnmatch: () {},
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

  group('SocialUnmatchedScreen (Task 132 / S57)', () {
    testWidgets('renders connection removed state with explanation', (tester) async {
      var returnCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialUnmatchedScreen(
            targetName: 'Kavya',
            onReturnToConnections: () => returnCalled = true,
          ),
        ),
      );

      expect(find.text('Connection Removed'), findsOneWidget);
      expect(find.textContaining('You and Kavya are no longer connected.'), findsOneWidget);
      expect(find.text('Return to Connections'), findsOneWidget);

      await tester.tap(find.text('Return to Connections'));
      await tester.pump();
      expect(returnCalled, isTrue);
    });

    testWidgets('renders cleanly across viewports without overflow', (tester) async {
      for (final width in [320.0, 400.0, 800.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: SocialUnmatchedScreen(
              targetName: 'Kavya',
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

  group('SocialMatchHistoryScreen (Task 133 / S86, S88)', () {
    final sampleHistory = [
      SocialMatchHistoryRecord(
        id: 'h-1',
        displayName: 'Aarav',
        matchedAt: DateTime(2026, 11, 1),
        status: SocialRelationshipState.matched,
      ),
      SocialMatchHistoryRecord(
        id: 'h-2',
        displayName: 'Meera',
        matchedAt: DateTime(2026, 10, 15),
        endedAt: DateTime(2026, 10, 20),
        status: SocialRelationshipState.revoked,
      ),
    ];

    testWidgets('renders chronological history records with status chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SocialMatchHistoryScreen(
            historyRecords: sampleHistory,
          ),
        ),
      );

      expect(find.text('Match History'), findsOneWidget);
      expect(find.text('Aarav'), findsOneWidget);
      expect(find.text('Meera'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Unmatched'), findsOneWidget);
    });

    testWidgets('renders S88 empty state with explore action when records are empty', (tester) async {
      var exploreCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialMatchHistoryScreen(
            historyRecords: const [],
            onExplore: () => exploreCalled = true,
          ),
        ),
      );

      expect(find.text('No Connections Yet'), findsOneWidget);
      expect(find.textContaining('you\'ll see your connection history here.'), findsOneWidget);
      expect(find.text('Discover People'), findsOneWidget);

      await tester.tap(find.text('Discover People'));
      await tester.pump();
      expect(exploreCalled, isTrue);
    });

    testWidgets('renders access denied state when isAuthorized is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SocialMatchHistoryScreen(
            historyRecords: [],
            isAuthorized: false,
          ),
        ),
      );

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });
  });

  group('SocialConnectionsScreen History Integration (Task 133)', () {
    testWidgets('match history icon button invokes onOpenMatchHistory', (tester) async {
      var historyOpened = false;
      final fakeVm = _FakeRelationshipViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialConnectionsScreen(
            viewModel: fakeVm,
            onOpenMatchHistory: () => historyOpened = true,
          ),
        ),
      );

      final historyBtn = find.byTooltip('Match History');
      expect(historyBtn, findsOneWidget);

      await tester.tap(historyBtn);
      await tester.pump();
      expect(historyOpened, isTrue);
    });
  });
}
