import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_search_viewmodel.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject = 'user-test-123';
  final List<VoidCallback> _clearers = [];

  FakeSessionController({
    SessionPhase phase = SessionPhase.signedIn,
    String? subject = 'user-test-123',
  })  : _phase = phase,
        _subject = subject;

  @override
  SessionPhase get phase => _phase;

  @override
  String? get subject => _subject;

  set subject(String? newSubject) {
    _subject = newSubject;
    notifyListeners();
  }

  void setPhase(SessionPhase phase) {
    _phase = phase;
    notifyListeners();
  }

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) {
    _clearers.add(clearer);
    return () => _clearers.remove(clearer);
  }

  void invokeClearers() {
    for (final c in List.of(_clearers)) {
      c();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSessionController fakeSession;

  final sampleCandidates = [
    SocialCandidate(
      id: 'cand-01',
      displayName: 'Elena Rostova',
      age: 26,
      biography: 'Exploring coffee shops and film photography.',
      interests: const ['Photography', 'Coffee', 'Hiking'],
      isVerified: true,
    ),
    SocialCandidate(
      id: 'cand-02',
      displayName: 'Marcus Chen',
      age: 29,
      biography: 'Tech enthusiast, runner, and foodie.',
      interests: const ['Running', 'Technology', 'Cooking'],
      isVerified: false,
    ),
  ];

  setUp(() {
    fakeSession = FakeSessionController();
  });

  group('SocialSearchViewModel Security & Session Tests (Tasks 111-112)', () {
    test('initializes with initial status and empty results', () {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      expect(vm.status, SocialSearchViewStatus.initial);
      expect(vm.currentQuery, isEmpty);
      expect(vm.results, isEmpty);
      expect(vm.isLoading, isFalse);
    });

    test('denies access if evidence is unverified or underage', () async {
      final unverifiedEvidence = SocialAccessEvidence.unverified(userId: 'user-test-123');
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        accessEvidence: unverifiedEvidence,
      );

      await vm.search('Elena', candidateSource: sampleCandidates);
      expect(vm.status, SocialSearchViewStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      expect(vm.results, isEmpty);
    });

    test('returns serviceUnavailable when candidateSource is null (no fabricated search endpoint)', () async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      await vm.search('Elena', candidateSource: null);
      expect(vm.status, SocialSearchViewStatus.serviceUnavailable);
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.results, isEmpty);
    });

    test('rejects cross-session candidate source (source session mismatch)', () async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      await vm.search(
        'Elena',
        candidateSource: sampleCandidates,
        sourceSessionSubject: 'other-user-456',
      );

      expect(vm.status, SocialSearchViewStatus.accessDenied);
      expect(vm.results, isEmpty);
    });

    test('filters candidates by name, bio, and interest for authorized search', () async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      // Search by name
      await vm.search('Elena', candidateSource: sampleCandidates);
      expect(vm.status, SocialSearchViewStatus.ready);
      expect(vm.results.length, 1);
      expect(vm.results.first.displayName, 'Elena Rostova');

      // Search by interest
      await vm.search('Running', candidateSource: sampleCandidates);
      expect(vm.status, SocialSearchViewStatus.ready);
      expect(vm.results.length, 1);
      expect(vm.results.first.displayName, 'Marcus Chen');

      // Search by non-existent term
      await vm.search('NonExistentTerm', candidateSource: sampleCandidates);
      expect(vm.status, SocialSearchViewStatus.empty);
      expect(vm.isEmpty, isTrue);
      expect(vm.results, isEmpty);
    });

    test('clears results and sets status to initial on empty query', () async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      await vm.search('Elena', candidateSource: sampleCandidates);
      expect(vm.results.length, 1);

      await vm.search('   ', candidateSource: sampleCandidates);
      expect(vm.status, SocialSearchViewStatus.initial);
      expect(vm.results, isEmpty);
    });

    test('clears private search results on session invalidation', () async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      await vm.search('Elena', candidateSource: sampleCandidates);
      expect(vm.results.length, 1);

      fakeSession.setPhase(SessionPhase.signedOut);
      expect(vm.status, SocialSearchViewStatus.accessDenied);
      expect(vm.results, isEmpty);
    });

    test('clears private search results on account switch', () async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      await vm.search('Elena', candidateSource: sampleCandidates);
      expect(vm.results.length, 1);

      fakeSession.subject = 'user-switched-999';
      expect(vm.status, SocialSearchViewStatus.accessDenied);
      expect(vm.results, isEmpty);
    });

    test('invalidates stale asynchronous queries when newer query supersedes', () async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      final search1 = vm.search('Elena', candidateSource: sampleCandidates);
      final search2 = vm.search('Marcus', candidateSource: sampleCandidates);

      await Future.wait([search1, search2]);

      // Only the last search result should remain
      expect(vm.results.length, 1);
      expect(vm.results.first.displayName, 'Marcus Chen');
    });

    test('safely handles disposal without throwing on late completion', () async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      final searchFuture = vm.search('Elena', candidateSource: sampleCandidates);
      vm.dispose();

      await searchFuture;
      expect(vm.status, SocialSearchViewStatus.loading); // Was loading when disposed
    });
  });
}
