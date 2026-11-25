import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/home/viewmodels/social_home_viewmodel.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _stubPhase;

  FakeSessionController({SessionPhase phase = SessionPhase.signedIn})
      : _stubPhase = phase;

  @override
  SessionPhase get phase => _stubPhase;

  void setPhase(SessionPhase phase) {
    _stubPhase = phase;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SocialHomeViewModel Unit Tests (M5-FE-S21-VM-01)', () {
    test('initial state has correct default values', () {
      final vm = SocialHomeViewModel();
      expect(vm.status, SocialHomeStatus.initial);
      expect(vm.displayName, 'Explorer');
      expect(vm.avatarUrl, isNull);
      expect(vm.unreadNotificationsCount, 0);
      expect(vm.recommendedPeople, isEmpty);
      expect(vm.errorMessage, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.isAccessDenied, isFalse);
      expect(vm.isAuthorized, isTrue);
      expect(vm.quickActions.length, 4);
    });

    test('isAuthorized fails closed when not opted in to social module', () {
      final vm = SocialHomeViewModel(isSocialOptedIn: false);
      expect(vm.isAuthorized, isFalse);

      vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
    });

    test('isAuthorized fails closed when session controller is signed out', () {
      final fakeSession = FakeSessionController(phase: SessionPhase.signedOut);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.isAuthorized, isFalse);
      vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
    });

    test('isAuthorized fails closed when session controller is unavailable', () {
      final fakeSession = FakeSessionController(phase: SessionPhase.unavailable);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.isAuthorized, isFalse);
      vm.initialize();
      expect(vm.status, SocialHomeStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
    });

    test('initialize loads default recommendations when authorized and none provided', () async {
      final fakeSession = FakeSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.isAuthorized, isTrue);
      await vm.initialize();

      expect(vm.status, SocialHomeStatus.ready);
      expect(vm.recommendedPeople.length, 4);
      expect(vm.recommendedPeople.first.displayName, 'Nivetha R.');
      expect(vm.recommendedPeople.first.location, 'Kandy');
      expect(vm.errorMessage, isNull);
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

      final vm = SocialHomeViewModel(
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

    test('refresh calls initialize and preserves ready state', () async {
      final vm = SocialHomeViewModel();
      await vm.refresh();
      expect(vm.status, SocialHomeStatus.ready);
      expect(vm.recommendedPeople, isNotEmpty);
    });

    test('updateProfileHeader updates displayName and avatarUrl and notifies listeners', () {
      final vm = SocialHomeViewModel();
      var notificationCount = 0;
      vm.addListener(() => notificationCount++);

      vm.updateProfileHeader(
        displayName: 'Aarav',
        avatarUrl: 'https://example.com/aarav.png',
      );

      expect(vm.displayName, 'Aarav');
      expect(vm.avatarUrl, 'https://example.com/aarav.png');
      expect(notificationCount, 1);
    });

    test('setUnreadNotificationsCount updates count and clamps negative to 0', () {
      final vm = SocialHomeViewModel();
      var notificationCount = 0;
      vm.addListener(() => notificationCount++);

      vm.setUnreadNotificationsCount(5);
      expect(vm.unreadNotificationsCount, 5);
      expect(notificationCount, 1);

      vm.setUnreadNotificationsCount(-2);
      expect(vm.unreadNotificationsCount, 0);
      expect(notificationCount, 2);
    });

    test('triggerExplorePeople invokes onExplorePeople callback', () {
      final vm = SocialHomeViewModel();
      var called = false;
      vm.onExplorePeople = () => called = true;

      vm.triggerExplorePeople();
      expect(called, isTrue);
    });

    test('triggerSeeAllRecommendations invokes onSeeAllRecommendations callback', () {
      final vm = SocialHomeViewModel();
      var called = false;
      vm.onSeeAllRecommendations = () => called = true;

      vm.triggerSeeAllRecommendations();
      expect(called, isTrue);
    });

    test('triggerViewProfile invokes onViewProfile with target userId', () {
      final vm = SocialHomeViewModel();
      String? viewedUserId;
      vm.onViewProfile = (id) => viewedUserId = id;

      vm.triggerViewProfile('user_xyz_123');
      expect(viewedUserId, 'user_xyz_123');
    });

    test('triggerQuickAction invokes onQuickAction with actionId', () {
      final vm = SocialHomeViewModel();
      SocialHomeActionId? selectedAction;
      vm.onQuickAction = (action) => selectedAction = action;

      for (final actionId in SocialHomeActionId.values) {
        vm.triggerQuickAction(actionId);
        expect(selectedAction, actionId);
      }
    });

    test('triggerNotificationTap invokes onNotificationTap callback', () {
      final vm = SocialHomeViewModel();
      var called = false;
      vm.onNotificationTap = () => called = true;

      vm.triggerNotificationTap();
      expect(called, isTrue);
    });

    test('triggerSearchTap invokes onSearchTap callback', () {
      final vm = SocialHomeViewModel();
      var called = false;
      vm.onSearchTap = () => called = true;

      vm.triggerSearchTap();
      expect(called, isTrue);
    });

    test('SocialRecommendedPerson and SocialHomeQuickAction equality and string representation', () {
      const person1 = SocialRecommendedPerson(
        id: '1',
        displayName: 'Test',
        location: 'City',
        photoUrl: 'url',
      );
      const person2 = SocialRecommendedPerson(
        id: '1',
        displayName: 'Test',
        location: 'City',
        photoUrl: 'url',
      );
      const person3 = SocialRecommendedPerson(
        id: '2',
        displayName: 'Test2',
        location: 'City2',
      );

      expect(person1, equals(person2));
      expect(person1 == person3, isFalse);
      expect(person1.hashCode, person2.hashCode);
      expect(person1.toString(), contains('SocialRecommendedPerson'));

      const action1 = SocialHomeQuickAction(
        id: SocialHomeActionId.myConnections,
        title: 'Title',
        subtitle: 'Sub',
      );
      const action2 = SocialHomeQuickAction(
        id: SocialHomeActionId.myConnections,
        title: 'Title',
        subtitle: 'Sub',
      );
      const action3 = SocialHomeQuickAction(
        id: SocialHomeActionId.andrilDiary,
        title: 'Title',
        subtitle: 'Sub',
      );

      expect(action1, equals(action2));
      expect(action1 == action3, isFalse);
      expect(action1.hashCode, action2.hashCode);
      expect(action1.toString(), contains('myConnections'));
    });

    test('disposed viewModel ignores updates and does not notify listeners', () {
      final vm = SocialHomeViewModel();
      var notifyCalled = false;
      vm.addListener(() => notifyCalled = true);

      vm.dispose();

      vm.updateProfileHeader(displayName: 'New Name');
      vm.setUnreadNotificationsCount(10);
      expect(notifyCalled, isFalse);
    });
  });
}
