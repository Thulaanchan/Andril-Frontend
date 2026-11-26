import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/discovery/data/social_discovery_repository.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/likes_matches/data/social_relationship_repository.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/social_relationship.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_connections_screen.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_mutual_match_screen.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_received_likes_screen.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_relationship_viewmodel.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_sent_likes_screen.dart';

class MockRelationshipRepository implements ISocialRelationshipRepository {
  DiscoveryResult<List<SocialRelationship>> receivedLikesResult =
      const DiscoveryResult.success([]);
  DiscoveryResult<List<SocialRelationship>> sentLikesResult =
      const DiscoveryResult.success([]);
  DiscoveryResult<List<SocialRelationship>> connectionsResult =
      const DiscoveryResult.success([]);
  DiscoveryResult<SocialRelationshipOperationResult> recordInterestResult =
      const DiscoveryResult.success(SocialRelationshipOperationResult(
    success: true,
    matchCreated: false,
    visibleState: 'Pending',
  ));
  DiscoveryResult<SocialRevocationResult> revokeMatchResult =
      const DiscoveryResult.success(SocialRevocationResult(
    success: true,
    matchRevoked: true,
  ));

  @override
  Future<DiscoveryResult<List<SocialRelationship>>> getReceivedLikes({
    int page = 0,
    int pageSize = 20,
  }) async => receivedLikesResult;

  @override
  Future<DiscoveryResult<List<SocialRelationship>>> getSentLikes({
    int page = 0,
    int pageSize = 20,
  }) async => sentLikesResult;

  @override
  Future<DiscoveryResult<List<SocialRelationship>>> getConnections({
    SocialConnectionCategory category = SocialConnectionCategory.all,
    int page = 0,
    int pageSize = 20,
  }) async => connectionsResult;

  @override
  Future<DiscoveryResult<SocialRelationshipStatusResult>> getRelationshipStatus({
    required String targetProfileId,
  }) async => const DiscoveryResult.success(SocialRelationshipStatusResult(hasActiveMatch: false));

  @override
  Future<DiscoveryResult<SocialRelationshipOperationResult>> recordInterest({
    required String targetProfileId,
    required bool isPositive,
  }) async => recordInterestResult;

  @override
  Future<DiscoveryResult<SocialRevocationResult>> revokeMatch({
    required String targetProfileId,
  }) async => revokeMatchResult;
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  @override
  SessionPhase get phase => SessionPhase.signedIn;

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) => () {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockRelationshipRepository mockRepo;
  late FakeSessionController fakeSession;

  final sampleCandidate = SocialCandidate(
    id: 'candidate-01',
    displayName: 'Elena',
    age: 25,
    approximateDistanceKm: 8,
    biography: 'Exploring coffee shops and photography.',
    isVerified: true,
    sharedConnectionGoals: const ['Long-term dating'],
  );

  final sampleReceivedLike = SocialRelationship(
    id: 'rel-rec-01',
    targetProfileId: 'candidate-01',
    candidate: sampleCandidate,
    state: SocialRelationshipState.pendingUnilateral,
    callerInterest: DirectionalInterest.none,
  );

  final sampleSentLike = SocialRelationship(
    id: 'rel-sent-01',
    targetProfileId: 'candidate-01',
    candidate: sampleCandidate,
    state: SocialRelationshipState.pendingUnilateral,
    callerInterest: DirectionalInterest.positive,
  );

  final sampleConnection = SocialRelationship(
    id: 'rel-conn-01',
    targetProfileId: 'candidate-01',
    candidate: sampleCandidate,
    state: SocialRelationshipState.matched,
    callerInterest: DirectionalInterest.positive,
    matchEvidence: SocialMatchEvidence(
      matchId: 'match-01',
      matchedAtUtc: DateTime.utc(2026, 11, 26, 10, 0),
    ),
  );

  setUp(() {
    mockRepo = MockRelationshipRepository();
    fakeSession = FakeSessionController();
  });

  Widget buildTestHost(Widget child, {Size size = const Size(400, 800), double textScale = 1.0}) {
    return MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('SocialReceivedLikesScreen (S43)', () {
    testWidgets('renders empty state when received likes is empty', (tester) async {
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await tester.pumpWidget(buildTestHost(SocialReceivedLikesScreen(viewModel: vm)));
      await tester.pumpAndSettle();

      expect(find.text('No Likes Yet'), findsOneWidget);
      expect(find.text('Received Likes'), findsOneWidget);
    });

    testWidgets('renders candidate cards with pass and like back action controls', (tester) async {
      mockRepo.receivedLikesResult = DiscoveryResult.success([sampleReceivedLike]);
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await tester.pumpWidget(buildTestHost(SocialReceivedLikesScreen(viewModel: vm)));
      await tester.pumpAndSettle();

      expect(find.text('Elena, 25'), findsOneWidget);
      expect(find.text('8 km away'), findsOneWidget);
      expect(find.byKey(const Key('pass_button_candidate-01')), findsOneWidget);
      expect(find.byKey(const Key('like_back_button_candidate-01')), findsOneWidget);

      // Tap Pass button
      await tester.tap(find.byKey(const Key('pass_button_candidate-01')));
      await tester.pumpAndSettle();

      // Card removed upon decision
      expect(find.text('No Likes Yet'), findsOneWidget);
    });

    testWidgets('renders access denied state when not opted in', (tester) async {
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );

      await tester.pumpWidget(buildTestHost(SocialReceivedLikesScreen(viewModel: vm)));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
    });
  });

  group('SocialSentLikesScreen (S11)', () {
    testWidgets('renders sent likes list and status chip', (tester) async {
      mockRepo.sentLikesResult = DiscoveryResult.success([sampleSentLike]);
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await tester.pumpWidget(buildTestHost(SocialSentLikesScreen(viewModel: vm)));
      await tester.pumpAndSettle();

      expect(find.text('Elena, 25'), findsOneWidget);
      expect(find.text('Interest Sent'), findsOneWidget);
    });

    testWidgets('renders empty state when sent likes is empty', (tester) async {
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await tester.pumpWidget(buildTestHost(SocialSentLikesScreen(viewModel: vm)));
      await tester.pumpAndSettle();

      expect(find.text('No Sent Likes'), findsOneWidget);
    });
  });

  group('SocialConnectionsScreen (S13)', () {
    testWidgets('renders connections with search, chat button, and unmatch menu', (tester) async {
      mockRepo.connectionsResult = DiscoveryResult.success([sampleConnection]);
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      String? openedChatProfileId;
      await tester.pumpWidget(buildTestHost(SocialConnectionsScreen(
        viewModel: vm,
        onOpenChat: (id) => openedChatProfileId = id,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Elena, 25'), findsOneWidget);
      expect(find.text('All Connections'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);

      // Verify chat button invokes callback
      final chatBtn = find.byKey(const Key('chat_button_candidate-01'));
      expect(chatBtn, findsOneWidget);
      await tester.tap(chatBtn);
      expect(openedChatProfileId, 'candidate-01');

      // Verify unmatch dialog
      final menuBtn = find.byKey(const Key('menu_button_candidate-01'));
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      expect(find.text('Unmatch'), findsOneWidget);
      await tester.tap(find.text('Unmatch'));
      await tester.pumpAndSettle();

      expect(find.text('Unmatch Confirmation'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Unmatch'));
      await tester.pumpAndSettle();

      expect(find.text('No Connections Yet'), findsOneWidget);
    });
  });

  group('SocialMutualMatchScreen (S12)', () {
    testWidgets('requires server-confirmed matching evidence; fails closed on unconfirmed state', (tester) async {
      // Unconfirmed match
      final unconfirmedRel = SocialRelationship(
        id: 'rel-unconf',
        targetProfileId: 'candidate-01',
        candidate: sampleCandidate,
        state: SocialRelationshipState.pendingUnilateral,
      );

      await tester.pumpWidget(buildTestHost(SocialMutualMatchScreen(relationship: unconfirmedRel)));
      await tester.pumpAndSettle();

      expect(find.text('Unconfirmed Match'), findsOneWidget);
      expect(find.text("It's a Match!"), findsNothing);
    });

    testWidgets('renders server-confirmed match celebration and action buttons', (tester) async {
      SocialRelationship? messageTarget;
      bool explored = false;

      await tester.pumpWidget(buildTestHost(SocialMutualMatchScreen(
        relationship: sampleConnection,
        onSendMessage: (rel) => messageTarget = rel,
        onKeepExploring: () => explored = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text("It's a Match!"), findsOneWidget);
      expect(find.text('Elena, 25'), findsOneWidget);
      expect(find.text('Long-term dating'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('send_message_button')));
      await tester.tap(find.byKey(const Key('send_message_button')));
      expect(messageTarget, equals(sampleConnection));

      await tester.ensureVisible(find.byKey(const Key('keep_exploring_button')));
      await tester.tap(find.byKey(const Key('keep_exploring_button')));
      expect(explored, isTrue);
    });
  });

  group('Responsive Layout Viewport Tests', () {
    testWidgets('S12, S13, S43 render without overflow across 320dp, 400dp, 800dp viewports', (tester) async {
      mockRepo.receivedLikesResult = DiscoveryResult.success([sampleReceivedLike]);
      mockRepo.connectionsResult = DiscoveryResult.success([sampleConnection]);
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      for (final size in [
        const Size(320, 640),
        const Size(400, 800),
        const Size(800, 1200),
      ]) {
        // S43 Received Likes
        await tester.pumpWidget(buildTestHost(SocialReceivedLikesScreen(viewModel: vm), size: size, textScale: 1.0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // S13 Connections
        await tester.pumpWidget(buildTestHost(SocialConnectionsScreen(viewModel: vm), size: size, textScale: 1.0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // S12 Mutual Match
        await tester.pumpWidget(buildTestHost(SocialMutualMatchScreen(relationship: sampleConnection), size: size, textScale: 1.0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
