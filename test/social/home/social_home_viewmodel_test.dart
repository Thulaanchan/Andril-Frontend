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

    test('signed-in status alone without authoritative evidence is denied', () async {
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
    });

    test('isTestAuthorized flag alone cannot bypass authorization', () async {
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        isTestAuthorized: true, // Bypass neutralized
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
      // No synthetic hardcoded mock recommendations in production
      expect(vm.recommendedPeople, isEmpty);
    });

    test('underage evidence is denied', () async {
      final evidence = SocialAccessEvidence.unverified(
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
      const customRecs = [
        SocialRecommendedPerson(
          id: 'custom_01',
          displayName: 'Priya S.',
          location: 'Batticaloa',
          photoUrl: 'https://example.com/priya.jpg',
        ),
      ];
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-123',
      );
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
        initialRecommendations: customRecs,
        initialDisplayName: 'Thulaan',
        initialUnreadNotifications: 3,
      );

      expect(vm.displayName, 'Thulaan');
      expect(vm.unreadNotificationsCount, 3);
      expect(vm.recommendedPeople.length, 1);

      await vm.initialize();
      expect(vm.status, SocialHomeStatus.ready);
      expect(vm.recommendedPeople.length, 1);
      expect(vm.recommendedPeople.first.displayName, 'Priya S.');
    });

    test('session logout clears private state and transitions to accessDenied', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-123',
      );
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
        initialDisplayName: 'Sensitive Name',
        initialUnreadNotifications: 5,
        initialRecommendations: const [
          SocialRecommendedPerson(id: 'r1', displayName: 'P1', location: 'L1'),
        ],
      );
      await vm.initialize();
      expect(vm.displayName, 'Sensitive Name');
      expect(vm.recommendedPeople.length, 1);

      // Trigger session clearance / logout
      fakeSession.triggerPrivateStateClearers();

      expect(vm.displayName, '');
      expect(vm.unreadNotificationsCount, 0);
      expect(vm.recommendedPeople, isEmpty);
      expect(vm.status, SocialHomeStatus.accessDenied);
    });

    test('account switching invalidates private state', () async {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-123',
      );
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
        initialDisplayName: 'Account A User',
      );
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.ready);

      // Switch account
      fakeSession.subject = 'user-switched-999';

      expect(vm.isAuthorized, isFalse);
      expect(vm.status, SocialHomeStatus.accessDenied);
      expect(vm.displayName, '');
    });

    test('navigation callbacks do not fire when access is denied', () {
      fakeSession.setPhase(SessionPhase.signedOut);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
      );

      var exploreFired = false;
      var seeAllFired = false;
      var viewProfileFired = false;
      var quickActionFired = false;
      var notificationFired = false;
      var searchFired = false;

      vm.onExplorePeople = () => exploreFired = true;
      vm.onSeeAllRecommendations = () => seeAllFired = true;
      vm.onViewProfile = (_) => viewProfileFired = true;
      vm.onQuickAction = (_) => quickActionFired = true;
      vm.onNotificationTap = () => notificationFired = true;
      vm.onSearchTap = () => searchFired = true;

      vm.triggerExplorePeople();
      vm.triggerSeeAllRecommendations();
      vm.triggerViewProfile('target');
      vm.triggerQuickAction(SocialHomeActionId.myConnections);
      vm.triggerNotificationTap();
      vm.triggerSearchTap();

      expect(exploreFired, isFalse);
      expect(seeAllFired, isFalse);
      expect(viewProfileFired, isFalse);
      expect(quickActionFired, isFalse);
      expect(notificationFired, isFalse);
      expect(searchFired, isFalse);
    });

    test('navigation callbacks fire when authorized', () {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-123',
      );
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: evidence,
      );

      var exploreFired = false;
      var seeAllFired = false;
      String? viewedProfileId;
      SocialHomeActionId? executedAction;
      var notificationFired = false;
      var searchFired = false;

      vm.onExplorePeople = () => exploreFired = true;
      vm.onSeeAllRecommendations = () => seeAllFired = true;
      vm.onViewProfile = (id) => viewedProfileId = id;
      vm.onQuickAction = (action) => executedAction = action;
      vm.onNotificationTap = () => notificationFired = true;
      vm.onSearchTap = () => searchFired = true;

      vm.triggerExplorePeople();
      vm.triggerSeeAllRecommendations();
      vm.triggerViewProfile('target-profile-uuid');
      vm.triggerQuickAction(SocialHomeActionId.personality);
      vm.triggerNotificationTap();
      vm.triggerSearchTap();

      expect(exploreFired, isTrue);
      expect(seeAllFired, isTrue);
      expect(viewedProfileId, 'target-profile-uuid');
      expect(executedAction, SocialHomeActionId.personality);
      expect(notificationFired, isTrue);
      expect(searchFired, isTrue);
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

      expect(vm.isAuthorized, isFalse);
      var callbackFired = false;
      vm.onExplorePeople = () => callbackFired = true;
      vm.triggerExplorePeople();
      expect(callbackFired, isFalse);
    });
  });
}
