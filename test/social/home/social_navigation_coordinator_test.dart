import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/home/viewmodels/social_navigation_coordinator.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_match_communication_boundary.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject = 'u-active-1';
  final List<VoidCallback> _clearers = [];

  @override
  SessionPhase get phase => _phase;

  set phase(SessionPhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }

  @override
  String? get subject => _subject;

  set subject(String? newSubject) {
    _subject = newSubject;
    notifyListeners();
  }

  void triggerSignOut() {
    _phase = SessionPhase.signedOut;
    _subject = null;
    for (final clearer in _clearers) {
      clearer();
    }
    notifyListeners();
  }

  void switchAccount(String newSubject) {
    _subject = newSubject;
    _phase = SessionPhase.signedIn;
    for (final clearer in _clearers) {
      clearer();
    }
    notifyListeners();
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
  late FakeSessionController fakeSession;

  setUp(() {
    fakeSession = FakeSessionController();
  });

  group('SocialNavigationCoordinator (Tasks 092 & 100)', () {
    test('initial destination is home when authorized', () {
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        accessBoundary: const SocialAccessBoundary(),
        communicationBoundary: const SocialMatchCommunicationBoundary(),
        accessEvidence: SocialAccessEvidence.authorized(userId: 'u-active-1'),
      );

      expect(coordinator.currentDestination, SocialDestination.home);
      expect(coordinator.isAuthorized, isTrue);
    });

    test('navigates to approved destinations when authorized with explicit evidence', () {
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'u-active-1'),
      );

      final navigatedToZones = coordinator.navigateTo(SocialDestination.zones);
      expect(navigatedToZones, isTrue);
      expect(coordinator.currentDestination, SocialDestination.zones);

      final navigatedToDiscovery = coordinator.navigateTo(SocialDestination.discovery);
      expect(navigatedToDiscovery, isTrue);
      expect(coordinator.currentDestination, SocialDestination.discovery);
    });

    test('redirects to accessDenied and sets reason when access evidence is revoked or unauthoritative', () {
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.revoked(userId: 'u-active-1'),
      );

      final result = coordinator.navigateTo(SocialDestination.zones);

      expect(result, isFalse);
      expect(coordinator.currentDestination, SocialDestination.accessDenied);
      expect(coordinator.navigationDeniedReason, contains('Access denied: SocialAccessStatus.revoked'));
    });

    test('redirects to accessDenied and returns false when unauthorized without evidence', () {
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        isSocialOptedIn: false, // not opted in
      );

      final result = coordinator.navigateTo(SocialDestination.zones);

      expect(result, isFalse);
      expect(coordinator.currentDestination, SocialDestination.accessDenied);
      expect(coordinator.navigationDeniedReason, contains('Active adult opt-in is required'));
    });

    test('redirects to accessDenied when unauthenticated', () {
      fakeSession.phase = SessionPhase.signedOut;
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      final result = coordinator.navigateTo(SocialDestination.profile);

      expect(result, isFalse);
      expect(coordinator.currentDestination, SocialDestination.accessDenied);
    });

    test('allows direct navigation to accessDenied screen', () {
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      final result = coordinator.navigateTo(SocialDestination.accessDenied);
      expect(result, isTrue);
      expect(coordinator.currentDestination, SocialDestination.accessDenied);
    });

    test('chat handoff succeeds only with verified mutual M4-authorized evidence and matching caller', () {
      String? handedOffChannelId;
      fakeSession.subject = 'u-1';
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'u-1'),
        onChatHandoff: (channelId) => handedOffChannelId = channelId,
      );

      final authorizedEvidence = MatchCommunicationEvidence.authorized(
        matchId: 'm-ok',
        participantA: 'u-1',
        participantB: 'u-2',
        m4ChannelId: 'm4-room-42',
      );

      final success = coordinator.navigateToChat(authorizedEvidence);
      expect(success, isTrue);
      expect(handedOffChannelId, 'm4-room-42');
    });

    test('chat handoff denied when active session subject does not match either participant', () {
      String? handedOffChannelId;
      fakeSession.subject = 'u-intruder';
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'u-intruder'),
        onChatHandoff: (channelId) => handedOffChannelId = channelId,
      );

      final authorizedEvidence = MatchCommunicationEvidence.authorized(
        matchId: 'm-ok',
        participantA: 'u-1',
        participantB: 'u-2',
        m4ChannelId: 'm4-room-42',
      );

      final success = coordinator.navigateToChat(authorizedEvidence);
      expect(success, isFalse);
      expect(handedOffChannelId, isNull);
      expect(coordinator.navigationDeniedReason, contains('Chat handoff denied'));
    });

    test('chat handoff strictly denied for unconfirmed or one-sided matches', () {
      String? handedOffChannelId;
      fakeSession.subject = 'u-1';
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'u-1'),
        onChatHandoff: (channelId) => handedOffChannelId = channelId,
      );

      final unconfirmed = MatchCommunicationEvidence.pending(
        matchId: 'm-pending',
        participantA: 'u-1',
        participantB: 'u-2',
      );

      final success = coordinator.navigateToChat(unconfirmed);
      expect(success, isFalse);
      expect(handedOffChannelId, isNull);
      expect(coordinator.navigationDeniedReason, contains('Chat handoff denied'));
    });

    test('resets navigation, clears evidence and reason upon session sign out', () {
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'u-active-1'),
      );

      coordinator.navigateTo(SocialDestination.zones);
      expect(coordinator.currentDestination, SocialDestination.zones);
      expect(coordinator.accessEvidence, isNotNull);

      fakeSession.triggerSignOut();

      expect(coordinator.currentDestination, SocialDestination.home);
      expect(coordinator.accessEvidence, isNull);
      expect(coordinator.navigationDeniedReason, isNull);
    });

    test('switching accounts triggers state clearer and resets navigation context', () {
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'u-active-1'),
      );

      coordinator.navigateTo(SocialDestination.connections);
      expect(coordinator.currentDestination, SocialDestination.connections);

      fakeSession.switchAccount('u-active-2');

      expect(coordinator.currentDestination, SocialDestination.home);
      expect(coordinator.accessEvidence, isNull);
    });
  });
}
