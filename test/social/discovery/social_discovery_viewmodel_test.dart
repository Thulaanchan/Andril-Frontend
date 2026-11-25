import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/discovery/data/social_discovery_repository.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_discovery_viewmodel.dart';
import 'package:andril_mobile/features/social/interests_preferences/domain/social_preferences_model.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _stubPhase;
  final Set<VoidCallback> _clearers = {};

  FakeSessionController({SessionPhase phase = SessionPhase.signedIn})
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

class FakeDiscoveryRepository implements ISocialDiscoveryRepository {
  DiscoveryResult<List<SocialCandidate>> exploreResult;
  DiscoveryResult<SocialInterestResult> interestResult;
  final List<Map<String, dynamic>> exploreCalls = [];
  final List<Map<String, dynamic>> interestCalls = [];
  Completer<void>? delayCompleter;

  FakeDiscoveryRepository({
    DiscoveryResult<List<SocialCandidate>>? exploreResult,
    DiscoveryResult<SocialInterestResult>? interestResult,
  })  : exploreResult = exploreResult ??
            const DiscoveryResult.success(<SocialCandidate>[]),
        interestResult = interestResult ??
            const DiscoveryResult.success(
              SocialInterestResult(
                success: true,
                matchCreated: false,
                visibleState: 'Recorded',
              ),
            );

  @override
  Future<DiscoveryResult<List<SocialCandidate>>> getExploreFeed({
    int rotationOffset = 0,
    int limit = 20,
  }) async {
    exploreCalls.add({'offset': rotationOffset, 'limit': limit});
    if (delayCompleter != null) {
      await delayCompleter!.future;
    }
    return exploreResult;
  }

  @override
  Future<DiscoveryResult<SocialInterestResult>> recordInterest({
    required String targetProfileId,
    required bool isPositive,
  }) async {
    interestCalls.add({'targetProfileId': targetProfileId, 'isPositive': isPositive});
    if (delayCompleter != null) {
      await delayCompleter!.future;
    }
    return interestResult;
  }
}

SocialCandidate _fixtureCandidate(String id, String name, int age) {
  return SocialCandidate(
    id: id,
    displayName: name,
    age: age,
    approximateDistanceKm: 10,
    sharedLanguages: const ['English'],
    sharedConnectionGoals: const ['Friendship'],
    interests: const {'Music'},
    photoUrls: const ['https://cdn.andril.app/p1.jpg'],
    locationName: 'Colombo',
    isVerified: true,
  );
}

void main() {
  group('SocialDiscoveryViewModel Tests (M5-FE-S09-VM-QA-01)', () {
    test('default construction fails closed and denies unverified access', () {
      final repo = FakeDiscoveryRepository();
      final vm = SocialDiscoveryViewModel(repository: repo);

      expect(vm.status, SocialDiscoveryStatus.initial);
      expect(vm.candidates, isEmpty);
      expect(vm.currentIndex, 0);
      expect(vm.currentCandidate, isNull);
      expect(vm.remainingCount, 0);
      expect(vm.hasMoreCandidates, isFalse);
      expect(vm.isAuthorized, isFalse);
      expect(vm.isAccessDenied, isFalse);
    });

    test('initialize denies access when session is missing or unauthenticated', () async {
      final repo = FakeDiscoveryRepository();
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        isSocialOptedIn: true,
      );

      await vm.initialize();

      expect(vm.status, SocialDiscoveryStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      expect(vm.errorMessage, contains('requires signed-in module authorization'));
      expect(repo.exploreCalls, isEmpty);
    });

    test('initialize denies access when user has not opted in to Social', () async {
      final repo = FakeDiscoveryRepository();
      final session = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        isSocialOptedIn: false,
      );

      await vm.initialize();

      expect(vm.status, SocialDiscoveryStatus.accessDenied);
      expect(repo.exploreCalls, isEmpty);
    });

    test('production repository defaults to dormant unavailable boundary', () async {
      const prodRepo = SocialDiscoveryRepository(isBackendActivated: false);
      final result = await prodRepo.getExploreFeed();

      expect(result.isSuccess, isFalse);
      expect(result.failureType, DiscoveryFailureType.serviceUnavailable);
      expect(result.errorMessage, contains('currently preparing and unavailable'));
    });

    test('authorized initialize loads candidates and transitions to ready', () async {
      final candidates = [
        _fixtureCandidate('c1', 'Amara', 24),
        _fixtureCandidate('c2', 'Kamal', 27),
      ];
      final repo = FakeDiscoveryRepository(
        exploreResult: DiscoveryResult.success(candidates),
      );
      final session = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        isSocialOptedIn: true,
      );

      await vm.initialize();

      expect(vm.status, SocialDiscoveryStatus.ready);
      expect(vm.candidates.length, 2);
      expect(vm.currentIndex, 0);
      expect(vm.currentCandidate?.displayName, 'Amara');
      expect(vm.remainingCount, 2);
      expect(vm.hasMoreCandidates, isTrue);
      expect(repo.exploreCalls.length, 1);
    });

    test('empty candidate response transitions to empty state', () async {
      final repo = FakeDiscoveryRepository(
        exploreResult: const DiscoveryResult.success(<SocialCandidate>[]),
      );
      final session = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        isSocialOptedIn: true,
      );

      await vm.initialize();

      expect(vm.status, SocialDiscoveryStatus.empty);
      expect(vm.candidates, isEmpty);
      expect(vm.currentCandidate, isNull);
    });

    test('service unavailable response transitions to unavailableService state', () async {
      final repo = FakeDiscoveryRepository(
        exploreResult: const DiscoveryResult.failure(
          errorMessage: 'Social discovery service is currently preparing and unavailable.',
          failureType: DiscoveryFailureType.serviceUnavailable,
        ),
      );
      final session = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        isSocialOptedIn: true,
      );

      await vm.initialize();

      expect(vm.status, SocialDiscoveryStatus.unavailableService);
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.errorMessage, contains('preparing and unavailable'));
    });

    test('directional pass records negative interest and advances stack', () async {
      final candidates = [
        _fixtureCandidate('c1', 'Amara', 24),
        _fixtureCandidate('c2', 'Kamal', 27),
      ];
      final repo = FakeDiscoveryRepository(
        exploreResult: DiscoveryResult.success(candidates),
      );
      final session = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        isSocialOptedIn: true,
      );

      await vm.initialize();
      expect(vm.currentIndex, 0);

      final passResult = await vm.pass();
      expect(passResult?.success, isTrue);
      expect(repo.interestCalls.length, 1);
      expect(repo.interestCalls.first['targetProfileId'], 'c1');
      expect(repo.interestCalls.first['isPositive'], isFalse);

      expect(vm.currentIndex, 1);
      expect(vm.currentCandidate?.displayName, 'Kamal');
      expect(vm.remainingCount, 1);
    });

    test('directional like records positive interest and triggers match callback when matched', () async {
      final candidates = [_fixtureCandidate('c1', 'Amara', 24)];
      final repo = FakeDiscoveryRepository(
        exploreResult: DiscoveryResult.success(candidates),
        interestResult: const DiscoveryResult.success(
          SocialInterestResult(
            success: true,
            matchCreated: true,
            matchId: 'match_999',
            visibleState: 'Matched',
          ),
        ),
      );
      final session = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        isSocialOptedIn: true,
      );

      SocialInterestResult? reportedMatch;
      vm.onMatchCreated = (result) {
        reportedMatch = result;
      };

      await vm.initialize();
      final likeResult = await vm.like();

      expect(likeResult?.success, isTrue);
      expect(likeResult?.matchCreated, isTrue);
      expect(reportedMatch?.matchId, 'match_999');
      expect(repo.interestCalls.first['isPositive'], isTrue);
      expect(vm.status, SocialDiscoveryStatus.empty);
    });

    test('in-flight guard rejects duplicate concurrent operations', () async {
      final candidates = [_fixtureCandidate('c1', 'Amara', 24)];
      final completer = Completer<void>();
      final repo = FakeDiscoveryRepository(
        exploreResult: DiscoveryResult.success(candidates),
      )..delayCompleter = completer;

      final session = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        isSocialOptedIn: true,
        initialCandidates: candidates,
      );

      // Trigger first like (async delay)
      final future1 = vm.like();
      expect(vm.isActionInProgress, isTrue);

      // Concurrent second like must be rejected
      final future2 = await vm.like();
      expect(future2, isNull);

      completer.complete();
      await future1;
      expect(vm.isActionInProgress, isFalse);
    });

    test('session invalidation clears private candidate state and denies access', () async {
      final candidates = [_fixtureCandidate('c1', 'Amara', 24)];
      final repo = FakeDiscoveryRepository(
        exploreResult: DiscoveryResult.success(candidates),
      );
      final session = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        isSocialOptedIn: true,
      );

      await vm.initialize();
      expect(vm.candidates.isNotEmpty, isTrue);

      // Trigger session clearance (logout / epoch invalidation)
      session.triggerPrivateStateClearers();

      expect(vm.candidates, isEmpty);
      expect(vm.currentCandidate, isNull);
      expect(vm.status, SocialDiscoveryStatus.accessDenied);
    });

    test('applying filters stores preferences model and triggers refresh', () async {
      final repo = FakeDiscoveryRepository();
      final session = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        isSocialOptedIn: true,
      );

      await vm.initialize();
      expect(repo.exploreCalls.length, 1);

      final filterDraft = SocialPreferencesModel(
        minAge: 21,
        maxAge: 35,
        maxDistanceKm: 25,
      );
      vm.applyFilters(filterDraft);

      expect(vm.activeFilters?.minAge, 21);
      expect(vm.activeFilters?.maxDistanceKm, 25);
      expect(repo.exploreCalls.length, 2);
    });

    test('disposal unregisters session listeners and prevents post-disposal dispatches', () async {
      final repo = FakeDiscoveryRepository();
      final session = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        isSocialOptedIn: true,
      );

      vm.dispose();
      await vm.initialize();

      expect(repo.exploreCalls, isEmpty);
      expect(vm.isAuthorized, isFalse);
    });
  });
}
