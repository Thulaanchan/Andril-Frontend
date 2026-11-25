import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/home/viewmodels/social_home_viewmodel.dart';

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

void main() {
  group('SocialHomeViewModel Security & Authorization Tests (M5-FE-S21-SEC-01)', () {
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
      expect(vm.isSocialOptedIn, isFalse);
    });

    test('missing session is denied on initialize', () async {
      final vm = SocialHomeViewModel(isSocialOptedIn: true);
      expect(vm.isAuthorized, isFalse);

      await vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
    });

    test('signed-out session is denied', () async {
      final fakeSession = FakeSessionController(phase: SessionPhase.signedOut);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
    });

    test('unavailable session is denied', () async {
      final fakeSession = FakeSessionController(phase: SessionPhase.unavailable);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
    });

    test('signed-in status alone without module authorization is denied', () async {
      final fakeSession = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        isTestAuthorized: false,
      );

      expect(vm.isAuthorized, isFalse);
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
    });

    test('isolated test fixture with signed-in session and opt-in is authorized', () async {
      final fakeSession = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        isTestAuthorized: true,
      );

      expect(vm.isAuthorized, isTrue);
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.ready);
      // No automatic mock profile generation in production
      expect(vm.recommendedPeople, isEmpty);
    });

    test('custom recommendations in constructor are preserved upon initialization', () async {
      const customRecs = [
        SocialRecommendedPerson(
          id: 'custom_01',
          displayName: 'Priya S.',
          location: 'Batticaloa',
          photoUrl: 'https://example.com/priya.jpg',
        ),
      ];
      final fakeSession = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        isTestAuthorized: true,
        initialRecommendations: customRecs,
        initialDisplayName: 'Thulaan',
        initialUnreadNotifications: 3,
      );

      expect(vm.displayName, 'Thulaan');
      expect(vm.unreadNotificationsCount, 3);
      expect(vm.recommendedPeople.length, 1);
      expect(vm.recommendedPeople.first.id, 'custom_01');

      await vm.initialize();
      expect(vm.status, SocialHomeStatus.ready);
      expect(vm.recommendedPeople.length, 1);
      expect(vm.recommendedPeople.first.displayName, 'Priya S.');
    });

    test('session logout clears private state and transitions to accessDenied', () async {
      final fakeSession = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        isTestAuthorized: true,
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

    test('session phase transition to signedOut invalidates state', () async {
      final fakeSession = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        isTestAuthorized: true,
        initialDisplayName: 'Sensitive Name',
      );
      await vm.initialize();
      expect(vm.status, SocialHomeStatus.ready);

      fakeSession.setPhase(SessionPhase.signedOut);

      expect(vm.isAuthorized, isFalse);
      expect(vm.status, SocialHomeStatus.accessDenied);
      expect(vm.displayName, '');
    });

    test('navigation callbacks do not fire when access is denied', () {
      final fakeSession = FakeSessionController(phase: SessionPhase.signedOut);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: false,
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
      final fakeSession = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        isTestAuthorized: true,
      );

      var exploreFired = false;
      var seeAllFired = false;
      String? viewedId;
      SocialHomeActionId? actionFired;
      var notificationFired = false;
      var searchFired = false;

      vm.onExplorePeople = () => exploreFired = true;
      vm.onSeeAllRecommendations = () => seeAllFired = true;
      vm.onViewProfile = (id) => viewedId = id;
      vm.onQuickAction = (act) => actionFired = act;
      vm.onNotificationTap = () => notificationFired = true;
      vm.onSearchTap = () => searchFired = true;

      vm.triggerExplorePeople();
      vm.triggerSeeAllRecommendations();
      vm.triggerViewProfile('user_42');
      vm.triggerQuickAction(SocialHomeActionId.myConnections);
      vm.triggerNotificationTap();
      vm.triggerSearchTap();

      expect(exploreFired, isTrue);
      expect(seeAllFired, isTrue);
      expect(viewedId, 'user_42');
      expect(actionFired, SocialHomeActionId.myConnections);
      expect(notificationFired, isTrue);
      expect(searchFired, isTrue);
    });

    test('disposed viewModel ignores updates and does not dispatch callbacks', () {
      final fakeSession = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        isTestAuthorized: true,
      );
      var exploreFired = false;
      vm.onExplorePeople = () => exploreFired = true;

      vm.dispose();

      vm.updateProfileHeader(displayName: 'New Name');
      vm.setUnreadNotificationsCount(10);
      vm.triggerExplorePeople();

      expect(exploreFired, isFalse);
      expect(vm.displayName, '');
    });

    test('diagnostic toString does not expose PII', () {
      const person = SocialRecommendedPerson(
        id: 'rec_private_id',
        displayName: 'Secret Identity',
        location: 'Secret City',
      );
      expect(person.toString(), equals('SocialRecommendedPerson(id: rec_private_id)'));
      expect(person.toString(), isNot(contains('Secret Identity')));
      expect(person.toString(), isNot(contains('Secret City')));
    });
  });
}
