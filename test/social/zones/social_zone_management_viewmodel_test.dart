import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone_management.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_management_viewmodel.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  final List<VoidCallback> _clearers = [];

  @override
  SessionPhase get phase => _phase;

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

  group('SocialZoneManagementViewModel Lifecycle & Permissions', () {
    test('initial state is clean and unauthorized without session & opt-in', () {
      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );

      expect(vm.status, ZoneManagementStatus.initial);
      expect(vm.isAuthorized, isFalse);
      expect(vm.isSubmitting, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('denies zone creation when unauthenticated or not opted in', () async {
      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );

      final success = await vm.createZone();

      expect(success, isFalse);
      expect(vm.status, ZoneManagementStatus.accessDenied);
      expect(vm.errorMessage, contains('Adult eligibility and Social opt-in are required'));
    });

    test('validates input and rejects invalid draft', () async {
      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      vm.updateDraft(ZoneManagementDraft(
        name: 'AB', // Too short
        description: 'Short',
        category: 'Tech',
      ));

      final success = await vm.createZone();

      expect(success, isFalse);
      expect(vm.status, ZoneManagementStatus.failure);
      expect(vm.errorMessage, 'Zone name must be at least 3 characters.');
    });

    test('fails closed with serviceUnavailable for valid draft (backend dormant)', () async {
      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      vm.updateDraft(ZoneManagementDraft(
        name: 'Open Source Contributors',
        description: 'Discussing open source libraries, tooling, and best practices.',
        category: 'Technology',
      ));

      final success = await vm.createZone();

      expect(success, isFalse);
      expect(vm.status, ZoneManagementStatus.serviceUnavailable);
      expect(vm.errorMessage, contains('Zone creation is temporarily deferred'));
    });

    test('denies zone update if caller lacks authoritative host permission', () async {
      final memberEvidence = ZonePermissionEvidence.memberDefault(
        zoneId: 'z-tech-1',
        userId: 'u-123',
      );

      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: memberEvidence,
      );

      vm.updateDraft(ZoneManagementDraft(
        name: 'Updated Name',
        description: 'Valid description that has sufficient length.',
        category: 'Technology',
      ));

      final success = await vm.updateZone('z-tech-1');

      expect(success, isFalse);
      expect(vm.status, ZoneManagementStatus.accessDenied);
      expect(vm.errorMessage, contains('Caller lacks authoritative host permission'));
    });

    test('allows zone update validation with host evidence, returns deferred', () async {
      final hostEvidence = ZonePermissionEvidence.host(
        zoneId: 'z-tech-1',
        userId: 'u-host-1',
      );

      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: hostEvidence,
      );

      vm.updateDraft(ZoneManagementDraft(
        name: 'Updated Name',
        description: 'Valid description that has sufficient length.',
        category: 'Technology',
      ));

      final success = await vm.updateZone('z-tech-1');

      expect(success, isFalse);
      expect(vm.status, ZoneManagementStatus.serviceUnavailable);
      expect(vm.errorMessage, contains('Zone modification is temporarily deferred'));
    });

    test('moderation actions enforce permissions', () async {
      final memberEvidence = ZonePermissionEvidence.memberDefault(
        zoneId: 'z-1',
        userId: 'u-1',
      );

      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: memberEvidence,
      );

      final joinResult = await vm.reviewJoinRequest('req-1', true);
      expect(joinResult, isFalse);
      expect(vm.status, ZoneManagementStatus.accessDenied);

      final roleResult = await vm.updateMemberRole('u-2', ZoneRole.moderator);
      expect(roleResult, isFalse);
      expect(vm.status, ZoneManagementStatus.accessDenied);
    });

    test('clears private state upon session sign out', () {
      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      vm.updateDraft(ZoneManagementDraft(
        name: 'Draft Name',
        description: 'Draft Description of sufficient length.',
        category: 'Tech',
      ));
      expect(vm.draft.name, 'Draft Name');

      fakeSession.triggerSignOut();

      expect(vm.draft.name, '');
      expect(vm.status, ZoneManagementStatus.initial);
      expect(vm.permissionEvidence, isNull);
    });
  });
}
