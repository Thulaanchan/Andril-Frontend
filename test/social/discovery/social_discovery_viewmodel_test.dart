import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/discovery/data/social_discovery_repository.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_discovery_viewmodel.dart';
import 'package:andril_mobile/features/social/interests_preferences/domain/social_preferences_model.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';

class _FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject = 'user-test-uuid';
  final Set<VoidCallback> _clearers = {};

  @override
  SessionPhase get phase => _phase;

  set phase(SessionPhase value) {
    _phase = value;
    notifyListeners();
  }

  @override
  String? get subject => _subject;

  set subject(String? value) {
    _subject = value;
    notifyListeners();
  }

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) {
    _clearers.add(clearer);
    return () => _clearers.remove(clearer);
  }

  void triggerClearers() {
    for (final clearer in List.of(_clearers)) {
      clearer();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDiscoveryRepository implements ISocialDiscoveryRepository {
  List<SocialCandidate> feedToReturn = [];
  DiscoveryFailureType? failureToReturn;
  String? errorMessageToReturn;
  SocialInterestResult? interestResultToReturn;

  int exploreCalls = 0;
  int recordInterestCalls = 0;

  @override
  Future<DiscoveryResult<List<SocialCandidate>>> getExploreFeed({
    int rotationOffset = 0,
    int limit = 20,
    SocialPreferencesModel? filters,
  }) async {
    exploreCalls++;
    if (failureToReturn != null) {
      return DiscoveryResult.failure(
        failureType: failureToReturn!,
        errorMessage: errorMessageToReturn ?? 'Error loading feed',
      );
    }
    return DiscoveryResult.success(feedToReturn);
  }

  @override
  Future<DiscoveryResult<SocialInterestResult>> recordInterest({
    required String targetProfileId,
    required bool isPositive,
  }) async {
    recordInterestCalls++;
    if (failureToReturn != null) {
      return DiscoveryResult.failure(
        failureType: failureToReturn!,
        errorMessage: errorMessageToReturn ?? 'Error recording decision',
      );
    }
    return DiscoveryResult.success(
      interestResultToReturn ??
          const SocialInterestResult(
            success: true,
            matchCreated: false,
            visibleState: 'Recorded',
          ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeSessionController sessionController;
  late _FakeDiscoveryRepository repository;

  final sampleCandidates = [
    SocialCandidate(
      id: 'c1',
      displayName: 'Maya',
      age: 23,
      interests: const {'Art'},
    ),
    SocialCandidate(
      id: 'c2',
      displayName: 'Tariq',
      age: 26,
      interests: const {'Tech'},
    ),
  ];

  setUp(() {
    sessionController = _FakeSessionController();
    repository = _FakeDiscoveryRepository();
    repository.feedToReturn = sampleCandidates;
  });

  group('SocialDiscoveryViewModel Authorization & Security (Task 109 & 110)', () {
    test('missing session fails closed with accessDenied', () async {
      final vm = SocialDiscoveryViewModel(
        repository: repository,
        sessionController: null,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialDiscoveryStatus.accessDenied);
      expect(repository.exploreCalls, 0);
    });

    test('unauthenticated session fails closed with accessDenied', () async {
      sessionController.phase = SessionPhase.signedOut;
      final vm = SocialDiscoveryViewModel(
        repository: repository,
        sessionController: sessionController,
        isSocialOptedIn: true,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialDiscoveryStatus.accessDenied);
      expect(repository.exploreCalls, 0);
    });

    test('authoritative adult opt-in evidence grants access and loads feed', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-uuid',
      );
      final vm = SocialDiscoveryViewModel(
        repository: repository,
        sessionController: sessionController,
        accessEvidence: evidence,
      );

      expect(vm.isAuthorized, isTrue);
      await vm.initialize();
      expect(vm.status, SocialDiscoveryStatus.ready);
      expect(vm.candidates.length, 2);
      expect(vm.currentCandidate?.displayName, 'Maya');
      expect(vm.remainingCount, 2);
    });

    test('underage evidence denies access', () async {
      final evidence = SocialAccessEvidence(
        userId: 'user-test-uuid',
        isAdult: false,
        isOptedIn: true,
        verifiedAt: DateTime.now(),
        isAuthoritative: true,
      );
      final vm = SocialDiscoveryViewModel(
        repository: repository,
        sessionController: sessionController,
        accessEvidence: evidence,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialDiscoveryStatus.accessDenied);
      expect(repository.exploreCalls, 0);
    });

    test('unverified evidence denies access', () async {
      final evidence = SocialAccessEvidence.unverified(
        userId: 'user-test-uuid',
      );
      final vm = SocialDiscoveryViewModel(
        repository: repository,
        sessionController: sessionController,
        accessEvidence: evidence,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialDiscoveryStatus.accessDenied);
      expect(repository.exploreCalls, 0);
    });

    test('revoked evidence denies access', () async {
      final evidence = SocialAccessEvidence.revoked(
        userId: 'user-test-uuid',
      );
      final vm = SocialDiscoveryViewModel(
        repository: repository,
        sessionController: sessionController,
        accessEvidence: evidence,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialDiscoveryStatus.accessDenied);
      expect(repository.exploreCalls, 0);
    });

    test('subject mismatch between session and evidence fails closed', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'foreign-subject-id',
      );
      final vm = SocialDiscoveryViewModel(
        repository: repository,
        sessionController: sessionController,
        accessEvidence: evidence,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialDiscoveryStatus.accessDenied);
      expect(repository.exploreCalls, 0);
    });

    test('session logout clears candidate queue and private state', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-uuid',
      );
      final vm = SocialDiscoveryViewModel(
        repository: repository,
        sessionController: sessionController,
        accessEvidence: evidence,
      );

      await vm.initialize();
      expect(vm.status, SocialDiscoveryStatus.ready);
      expect(vm.candidates.isNotEmpty, isTrue);

      sessionController.phase = SessionPhase.signedOut;
      expect(vm.status, SocialDiscoveryStatus.accessDenied);
      expect(vm.candidates, isEmpty);
      expect(vm.currentCandidate, isNull);
    });

    test('account switching invalidates private candidate state', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-uuid',
      );
      final vm = SocialDiscoveryViewModel(
        repository: repository,
        sessionController: sessionController,
        accessEvidence: evidence,
      );

      await vm.initialize();
      expect(vm.status, SocialDiscoveryStatus.ready);
      expect(vm.candidates.length, 2);

      sessionController.subject = 'switched-subject-999';
      expect(vm.status, SocialDiscoveryStatus.accessDenied);
      expect(vm.candidates, isEmpty);
    });

    test('handles serviceUnavailable backend mapping without fabricating candidates', () async {
      repository.failureToReturn = DiscoveryFailureType.serviceUnavailable;
      repository.errorMessageToReturn = 'Service dormant';

      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-uuid',
      );
      final vm = SocialDiscoveryViewModel(
        repository: repository,
        sessionController: sessionController,
        accessEvidence: evidence,
      );

      await vm.initialize();
      expect(vm.status, SocialDiscoveryStatus.unavailableService);
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.candidates, isEmpty);
    });

    test('evaluates pass and like card decisions sequentially', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-uuid',
      );
      final vm = SocialDiscoveryViewModel(
        repository: repository,
        sessionController: sessionController,
        accessEvidence: evidence,
      );

      await vm.initialize();
      expect(vm.currentIndex, 0);
      expect(vm.currentCandidate?.displayName, 'Maya');

      final passResult = await vm.pass();
      expect(passResult?.success, isTrue);
      expect(vm.currentIndex, 1);
      expect(vm.currentCandidate?.displayName, 'Tariq');

      final likeResult = await vm.like();
      expect(likeResult?.success, isTrue);
      expect(vm.currentIndex, 2);
      expect(vm.hasMoreCandidates, isFalse);
      expect(vm.status, SocialDiscoveryStatus.empty);
    });

    test('disposed viewmodel rejects decisions and unregisters session clearer', () {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-uuid',
      );
      final vm = SocialDiscoveryViewModel(
        repository: repository,
        sessionController: sessionController,
        accessEvidence: evidence,
        initialCandidates: sampleCandidates,
      );

      vm.dispose();
      expect(vm.candidates, isEmpty);
    });
  });
}
