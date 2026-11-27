import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/home/viewmodels/social_home_viewmodel.dart';
import 'package:andril_mobile/features/social/home/viewmodels/social_navigation_coordinator.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_match_communication_boundary.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone_management.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone_repository.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_management_viewmodel.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zones_viewmodel.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject = 'u-minor-1';
  final List<VoidCallback> _clearers = [];

  @override
  SessionPhase get phase => _phase;

  @override
  String? get subject => _subject;

  set subject(String? s) {
    _subject = s;
    notifyListeners();
  }

  set phase(SessionPhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }

  void triggerSignOut() {
    _phase = SessionPhase.signedOut;
    for (final clearer in _clearers) {
      clearer();
    }
    notifyListeners();
  }

  void simulateAccountSwitch() {
    // When account changes, session triggers private state clearing
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

  group('Social Frontend Security Integration (Task 094)', () {
    test('enforces adult eligibility across all features (fails closed)', () async {
      const accessBoundary = SocialAccessBoundary();

      // Underage user
      final underageEvidence = SocialAccessEvidence(
        userId: 'u-minor-1',
        isAdult: false,
        isOptedIn: true,
        verifiedAt: DateTime.now(),
        isAuthoritative: true,
      );

      final status = accessBoundary.evaluateAccess(
        sessionController: fakeSession,
        evidence: underageEvidence,
      );
      expect(status, SocialAccessStatus.underage);
      expect(accessBoundary.isAccessGranted(sessionController: fakeSession, evidence: underageEvidence), isFalse);

      // Home VM
      final homeVm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );
      expect(homeVm.isAuthorized, isFalse);

      // Zones VM
      final zoneRepo = SocialZoneRepository(sessionController: fakeSession);
      final zonesVm = SocialZonesViewModel(
        repository: zoneRepo,
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );
      await zonesVm.loadZones();
      expect(zonesVm.status, SocialZonesStatus.accessDenied);

      // Zone Mgmt VM
      final mgmtVm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );
      final createSuccess = await mgmtVm.createZone();
      expect(createSuccess, isFalse);
      expect(mgmtVm.status, ZoneManagementStatus.accessDenied);
    });

    test('clears in-memory private state across all viewmodels upon session sign out', () async {
      final zoneRepo = SocialZoneRepository(sessionController: fakeSession);

      final zonesVm = SocialZonesViewModel(
        repository: zoneRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      await zonesVm.loadZones();
      expect(zonesVm.zones, isNotEmpty);

      final mgmtVm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      mgmtVm.updateDraft(ZoneManagementDraft(
        name: 'Private Draft',
        description: 'Private in-memory description of sufficient length.',
        category: 'Tech',
      ));
      expect(mgmtVm.draft.name, 'Private Draft');

      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: fakeSession.subject ?? 'u-minor-1'),
        isSocialOptedIn: true,
      );
      coordinator.navigateTo(SocialDestination.zones);
      expect(coordinator.currentDestination, SocialDestination.zones);

      // Trigger session sign out
      fakeSession.triggerSignOut();

      // Verify all private states were cleared
      expect(zonesVm.zones, isEmpty);
      expect(zonesVm.status, SocialZonesStatus.initial);

      expect(mgmtVm.draft.name, '');
      expect(mgmtVm.status, ZoneManagementStatus.initial);

      expect(coordinator.currentDestination, SocialDestination.home);
    });

    test('clears in-memory state upon simulated account switch to prevent data leakage', () async {
      final zoneRepo = SocialZoneRepository(sessionController: fakeSession);

      final zonesVm = SocialZonesViewModel(
        repository: zoneRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      await zonesVm.loadZones();
      expect(zonesVm.zones, isNotEmpty);

      final mgmtVm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      mgmtVm.updateDraft(ZoneManagementDraft(
        name: 'Account A Draft',
        description: 'Sensitive private description of sufficient length.',
        category: 'Tech',
      ));

      // Simulate account switch
      fakeSession.simulateAccountSwitch();

      expect(zonesVm.zones, isEmpty);
      expect(mgmtVm.draft.name, '');
    });

    test('communication boundary strictly prevents unauthorized peer chat initiation', () {
      const commBoundary = SocialMatchCommunicationBoundary();

      // 1. One-sided interest
      final pending = MatchCommunicationEvidence.pending(
        matchId: 'm-1',
        participantA: 'u-1',
        participantB: 'u-2',
      );
      expect(commBoundary.canInitiateCommunication(pending), isFalse);

      // 2. Blocked connection
      final blocked = MatchCommunicationEvidence(
        matchId: 'm-2',
        participantA: 'u-1',
        participantB: 'u-2',
        isMutual: true,
        isBlocked: true,
        verifiedAt: DateTime.now(),
        isM4Authorized: true,
        m4ChannelId: 'ch-2',
      );
      expect(commBoundary.canInitiateCommunication(blocked), isFalse);

      // 3. Unmatched connection
      final unmatched = MatchCommunicationEvidence(
        matchId: 'm-3',
        participantA: 'u-1',
        participantB: 'u-2',
        isMutual: true,
        isUnmatched: true,
        verifiedAt: DateTime.now(),
        isM4Authorized: true,
        m4ChannelId: 'ch-3',
      );
      expect(commBoundary.canInitiateCommunication(unmatched), isFalse);

      // 4. Missing M4 authorization
      final noM4 = MatchCommunicationEvidence(
        matchId: 'm-4',
        participantA: 'u-1',
        participantB: 'u-2',
        isMutual: true,
        isM4Authorized: false,
        verifiedAt: DateTime.now(),
        m4ChannelId: 'ch-4',
      );
      expect(commBoundary.canInitiateCommunication(noM4), isFalse);
    });
  });
}
