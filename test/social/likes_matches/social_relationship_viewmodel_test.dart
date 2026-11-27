import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/discovery/data/social_discovery_repository.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/likes_matches/data/social_relationship_repository.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/social_relationship.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_relationship_viewmodel.dart';

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

  Completer<void>? delayCompleter;
  int recordInterestCallCount = 0;

  @override
  Future<DiscoveryResult<List<SocialRelationship>>> getReceivedLikes({
    int page = 0,
    int pageSize = 20,
  }) async {
    if (delayCompleter != null) await delayCompleter!.future;
    return receivedLikesResult;
  }

  @override
  Future<DiscoveryResult<List<SocialRelationship>>> getSentLikes({
    int page = 0,
    int pageSize = 20,
  }) async {
    if (delayCompleter != null) await delayCompleter!.future;
    return sentLikesResult;
  }

  @override
  Future<DiscoveryResult<List<SocialRelationship>>> getConnections({
    SocialConnectionCategory category = SocialConnectionCategory.all,
    int page = 0,
    int pageSize = 20,
  }) async {
    if (delayCompleter != null) await delayCompleter!.future;
    return connectionsResult;
  }

  @override
  Future<DiscoveryResult<SocialRelationshipStatusResult>> getRelationshipStatus({
    required String targetProfileId,
  }) async {
    return const DiscoveryResult.success(SocialRelationshipStatusResult(
      hasActiveMatch: false,
    ));
  }

  @override
  Future<DiscoveryResult<SocialRelationshipOperationResult>> recordInterest({
    required String targetProfileId,
    required bool isPositive,
  }) async {
    recordInterestCallCount++;
    if (delayCompleter != null) await delayCompleter!.future;
    return recordInterestResult;
  }

  @override
  Future<DiscoveryResult<SocialRevocationResult>> revokeMatch({
    required String targetProfileId,
  }) async {
    if (delayCompleter != null) await delayCompleter!.future;
    return revokeMatchResult;
  }
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject = 'user-rel-01';
  final List<VoidCallback> _clearers = [];

  @override
  SessionPhase get phase => _phase;

  @override
  String? get subject => _subject;

  set subject(String? s) {
    _subject = s;
    notifyListeners();
  }

  void setPhase(SessionPhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }

  void triggerSessionClear() {
    for (final clearer in _clearers) {
      clearer();
    }
  }

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) {
    _clearers.add(clearer);
    return () => _clearers.remove(clearer);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockRelationshipRepository mockRepo;
  late FakeSessionController fakeSession;

  final sampleCandidate = SocialCandidate(
    id: 'candidate-01',
    displayName: 'Aria',
    age: 23,
    isVerified: true,
  );

  final sampleRelationship = SocialRelationship(
    id: 'rel-01',
    targetProfileId: 'candidate-01',
    candidate: sampleCandidate,
    state: SocialRelationshipState.pendingUnilateral,
    callerInterest: DirectionalInterest.positive,
  );

  setUp(() {
    mockRepo = MockRelationshipRepository();
    fakeSession = FakeSessionController();
  });

  group('Authorization and Privacy Boundaries', () {
    test('denies access when session is missing', () async {
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: null,
        isSocialOptedIn: true,
      );

      await vm.loadReceivedLikes();
      expect(vm.status, SocialRelationshipViewStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      expect(vm.isAuthorized, isFalse);
    });

    test('denies access when user has not opted into Social', () async {
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );

      await vm.loadConnections();
      expect(vm.status, SocialRelationshipViewStatus.accessDenied);
    });

    test('denies access when session is not signedIn', () async {
      fakeSession.setPhase(SessionPhase.signedOut);
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadSentLikes();
      expect(vm.status, SocialRelationshipViewStatus.accessDenied);
    });
  });

  group('Asynchronous State Transitions', () {
    test('loads received likes and transitions from loading to ready', () async {
      mockRepo.receivedLikesResult = DiscoveryResult.success([sampleRelationship]);
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      final future = vm.loadReceivedLikes();
      expect(vm.isLoading, isTrue);

      await future;
      expect(vm.status, SocialRelationshipViewStatus.ready);
      expect(vm.receivedLikes.length, 1);
      expect(vm.receivedLikes.first.displayName, 'Aria');
    });

    test('transitions to empty when loaded list contains zero items', () async {
      mockRepo.receivedLikesResult = const DiscoveryResult.success([]);
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadReceivedLikes();
      expect(vm.status, SocialRelationshipViewStatus.empty);
      expect(vm.receivedLikes, isEmpty);
    });

    test('maps serviceUnavailable failure correctly', () async {
      mockRepo.connectionsResult = const DiscoveryResult.failure(
        errorMessage: 'Service dormant',
        failureType: DiscoveryFailureType.serviceUnavailable,
      );
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadConnections();
      expect(vm.status, SocialRelationshipViewStatus.unavailableService);
      expect(vm.isServiceUnavailable, isTrue);
    });
  });

  group('Duplicate Operations and Race Protection', () {
    test('prevents concurrent duplicate decisions on identical targetProfileId', () async {
      mockRepo.delayCompleter = Completer<void>();
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialReceivedLikes: [sampleRelationship],
      );

      final op1 = vm.respondToLike(targetProfileId: 'candidate-01', isPositive: true);
      expect(vm.isOperationInProgress('candidate-01'), isTrue);

      // Concurrent second call for same profile must be rejected
      final op2 = await vm.respondToLike(targetProfileId: 'candidate-01', isPositive: true);
      expect(op2, isFalse);
      expect(mockRepo.recordInterestCallCount, 1);

      mockRepo.delayCompleter!.complete();
      final res1 = await op1;
      expect(res1, isTrue);
      expect(vm.isOperationInProgress('candidate-01'), isFalse);
    });

    test('discards stale asynchronous responses when newer load operation arrives', () async {
      final slowCompleter = Completer<void>();
      mockRepo.delayCompleter = slowCompleter;
      mockRepo.sentLikesResult = DiscoveryResult.success([sampleRelationship]);

      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      // 1. Dispatch slow operation
      final slowFuture = vm.loadSentLikes();

      // 2. Clear completer and dispatch faster subsequent operation
      mockRepo.delayCompleter = null;
      mockRepo.sentLikesResult = const DiscoveryResult.success([]);
      await vm.loadSentLikes();
      expect(vm.status, SocialRelationshipViewStatus.empty);
      expect(vm.sentLikes, isEmpty);

      // 3. Resolve the older slow request
      slowCompleter.complete();
      await slowFuture;

      // Newer result (empty) must not be overwritten by stale slow response
      expect(vm.sentLikes, isEmpty);
      expect(vm.status, SocialRelationshipViewStatus.empty);
    });
  });

  group('Mutual Match and Communication Boundaries', () {
    test('confirms mutual match only on authoritative server confirmation and unlocks communication', () async {
      mockRepo.recordInterestResult = const DiscoveryResult.success(
        SocialRelationshipOperationResult(
          success: true,
          matchCreated: true,
          matchId: 'match-server-001',
          visibleState: 'Matched',
        ),
      );

      SocialRelationship? matchedCallbackItem;
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialReceivedLikes: [sampleRelationship],
      );
      vm.onMatchConfirmed = (rel) => matchedCallbackItem = rel;

      final success = await vm.respondToLike(
        targetProfileId: 'candidate-01',
        isPositive: true,
      );

      expect(success, isTrue);
      expect(matchedCallbackItem, isNotNull);
      expect(matchedCallbackItem!.hasActiveMatch, isTrue);
      expect(matchedCallbackItem!.canCommunicate, isTrue);
      expect(vm.connections.length, 1);
      expect(vm.connections.first.hasActiveMatch, isTrue);
    });

    test('one-sided interest does not grant communication access', () async {
      mockRepo.recordInterestResult = const DiscoveryResult.success(
        SocialRelationshipOperationResult(
          success: true,
          matchCreated: false, // Unilateral only
          visibleState: 'PendingUnilateral',
        ),
      );

      SocialRelationship? matchedCallbackItem;
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialReceivedLikes: [sampleRelationship],
      );
      vm.onMatchConfirmed = (rel) => matchedCallbackItem = rel;

      final success = await vm.respondToLike(
        targetProfileId: 'candidate-01',
        isPositive: true,
      );

      expect(success, isTrue);
      expect(matchedCallbackItem, isNull);
      expect(vm.connections, isEmpty);
    });
  });

  group('Session Invalidation and Private State Clearing', () {
    test('clears all private relationship state on session logout or account switch', () {
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialReceivedLikes: [sampleRelationship],
        initialSentLikes: [sampleRelationship],
        initialConnections: [sampleRelationship],
      );

      expect(vm.receivedLikes.length, 1);
      expect(vm.sentLikes.length, 1);
      expect(vm.connections.length, 1);

      // Trigger session clearance
      fakeSession.triggerSessionClear();

      expect(vm.receivedLikes, isEmpty);
      expect(vm.sentLikes, isEmpty);
      expect(vm.connections, isEmpty);
    });

    test('disposal unregisters listeners cleanly', () {
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(() => vm.dispose(), returnsNormally);
    });

    test('authorizes relationship operations when valid SocialAccessEvidence is provided', () async {
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-rel-01'),
      );

      expect(vm.isAuthorized, isTrue);
      await vm.loadReceivedLikes();
      expect(vm.status, isNot(SocialRelationshipViewStatus.accessDenied));
    });

    test('clears private state and denies access upon account switch', () async {
      final vm = SocialRelationshipViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialConnections: [sampleRelationship],
      );

      expect(vm.connections, isNotEmpty);
      fakeSession.subject = 'switched-rel-02';
      expect(vm.connections, isEmpty);
      expect(vm.status, SocialRelationshipViewStatus.accessDenied);
    });
  });
}
