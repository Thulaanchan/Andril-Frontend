import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/home/viewmodels/social_home_viewmodel.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _stubPhase;
  String? _subject;
  final Set<VoidCallback> _clearers = {};

  FakeSessionController({
    SessionPhase phase = SessionPhase.signedIn,
    String? subject = 'user-test-123',
  })  : _stubPhase = phase,
        _subject = subject;

  @override
  SessionPhase get phase => _stubPhase;

  @override
  String? get subject => _subject;

  set subject(String? newSubject) {
    _subject = newSubject;
    notifyListeners();
  }

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

void main() {
  late FakeSessionController fakeSession;

  setUp(() {
    fakeSession = FakeSessionController(
      phase: SessionPhase.signedIn,
      subject: 'user-test-123',
    );
  });

  group('SocialHomeViewModel Security & Authorization Tests (Task 105 & 106)', () {
    test('default construction fails closed (missing session, opt-in false)', () {
      final vm = SocialHomeViewModel();
      expect(vm.status, SocialHomeStatus.initial);
      expect(vm.displayName, '');
      expect(vm.avatarUrl, isNull);
      expect(vm.unreadNotificationsCount, 0);
      expect(vm.recommendedPeople, isEmpty);
      expect(vm.errorMessage, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.isAccessDenied, isFalse);
      expect(vm.isAuthorized, isFalse);
    });

    test('missing session is denied on initialize', () async {
      final vm = SocialHomeViewModel(isSocialOptedIn: true);
      expect(vm.isAuthorized, isFalse);

      await vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
    });

    test('signed-out session is denied', () async {
      fakeSession.setPhase(SessionPhase.signedOut);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
    });

    test('unavailable session is denied', () async {
      fakeSession.setPhase(SessionPhase.unavailable);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
    });

    test('signed-in status alone without authoritative evidence is denied (local boolean bypass attempt)', () async {
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
    });

    test('authoritative adult opt-in evidence grants access and reaches ready state', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-123',
      );
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
      );

      expect(vm.isAuthorized, isTrue);
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.ready);
      expect(vm.isReady, isTrue);
    });

    test('underage evidence is denied', () async {
      final evidence = SocialAccessEvidence(
        userId: 'user-test-123',
        isAdult: false,
        isOptedIn: true,
        verifiedAt: DateTime.now(),
        isAuthoritative: true,
      );
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
    });

    test('revoked evidence is denied', () async {
      final evidence = SocialAccessEvidence.revoked(
        userId: 'user-test-123',
      );
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
    });

    test('subject mismatch between session and evidence fails closed', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'different-user-456',
      );
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
    });

    test('injected custom recommendations are preserved upon initialization', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-123',
      );
      const customRec = [
        SocialRecommendedPerson(
          id: 'rec-01',
          displayName: 'Kasun P.',
          location: 'Galle',
        ),
      ];

      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
        initialRecommendations: customRec,
      );

      await vm.initialize();
      expect(vm.status, SocialHomeStatus.ready);
      expect(vm.recommendedPeople.length, 1);
      expect(vm.recommendedPeople.first.displayName, 'Kasun P.');
    });

    test('session logout clears private state and transitions to accessDenied', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-123',
      );
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
        initialDisplayName: 'Test User',
        initialUnreadNotifications: 5,
      );

      await vm.initialize();
      expect(vm.status, SocialHomeStatus.ready);

      fakeSession.setPhase(SessionPhase.signedOut);
      expect(vm.status, SocialHomeStatus.accessDenied);
      expect(vm.displayName, '');
      expect(vm.unreadNotificationsCount, 0);
      expect(vm.recommendedPeople, isEmpty);
    });

    test('account switching invalidates private state', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-123',
      );
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
        initialDisplayName: 'Initial Account User',
      );

      await vm.initialize();
      expect(vm.status, SocialHomeStatus.ready);

      fakeSession.subject = 'new-user-789';
      expect(vm.status, SocialHomeStatus.accessDenied);
      expect(vm.displayName, '');
      expect(vm.isAuthorized, isFalse);
    });

    test('navigation callbacks do not fire when access is denied', () {
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );

      var exploreCalled = false;
      var seeAllCalled = false;
      var viewProfileCalled = false;
      var quickActionCalled = false;
      var notifCalled = false;
      var searchCalled = false;

      vm.onExplorePeople = () => exploreCalled = true;
      vm.onSeeAllRecommendations = () => seeAllCalled = true;
      vm.onViewProfile = (_) => viewProfileCalled = true;
      vm.onQuickAction = (_) => quickActionCalled = true;
      vm.onNotificationTap = () => notifCalled = true;
      vm.onSearchTap = () => searchCalled = true;

      vm.triggerExplorePeople();
      vm.triggerSeeAllRecommendations();
      vm.triggerViewProfile('p1');
      vm.triggerQuickAction(SocialHomeActionId.myConnections);
      vm.triggerNotificationTap();
      vm.triggerSearchTap();

      expect(exploreCalled, isFalse);
      expect(seeAllCalled, isFalse);
      expect(viewProfileCalled, isFalse);
      expect(quickActionCalled, isFalse);
      expect(notifCalled, isFalse);
      expect(searchCalled, isFalse);
    });

    test('navigation callbacks fire when authorized', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-123',
      );
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
      );
      await vm.initialize();

      var exploreCalled = false;
      var seeAllCalled = false;
      var viewProfileTarget = '';
      SocialHomeActionId? quickActionTarget;
      var notifCalled = false;
      var searchCalled = false;

      vm.onExplorePeople = () => exploreCalled = true;
      vm.onSeeAllRecommendations = () => seeAllCalled = true;
      vm.onViewProfile = (id) => viewProfileTarget = id;
      vm.onQuickAction = (action) => quickActionTarget = action;
      vm.onNotificationTap = () => notifCalled = true;
      vm.onSearchTap = () => searchCalled = true;

      vm.triggerExplorePeople();
      vm.triggerSeeAllRecommendations();
      vm.triggerViewProfile('p1');
      vm.triggerQuickAction(SocialHomeActionId.myConnections);
      vm.triggerNotificationTap();
      vm.triggerSearchTap();

      expect(exploreCalled, isTrue);
      expect(seeAllCalled, isTrue);
      expect(viewProfileTarget, 'p1');
      expect(quickActionTarget, SocialHomeActionId.myConnections);
      expect(notifCalled, isTrue);
      expect(searchCalled, isTrue);
    });

    test('disposed viewmodel rejects operations and unregisters listeners', () {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-123',
      );
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
      );

      vm.dispose();

      var exploreCalled = false;
      vm.onExplorePeople = () => exploreCalled = true;
      vm.triggerExplorePeople();
      expect(exploreCalled, isFalse);
    });
  });
}
