import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone_repository.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zones_viewmodel.dart';

class MockSocialZoneRepository implements ISocialZoneRepository {
  ZoneResult<List<SocialZone>> zonesResult = const ZoneResult.success([
    SocialZone(
      id: 'z-test-1',
      name: 'Designers Circle',
      description: 'Design talks and reviews.',
      category: 'Design',
      memberCount: 50,
    ),
  ]);

  ZoneResult<SocialZone> detailsResult = const ZoneResult.success(
    SocialZone(
      id: 'z-test-1',
      name: 'Designers Circle',
      description: 'Design talks and reviews.',
      category: 'Design',
      memberCount: 50,
    ),
  );

  ZoneResult<SocialZone> joinResult = const ZoneResult.failure(ZoneFailure(
    type: ZoneFailureType.serviceUnavailable,
    message: 'Deferred',
  ));

  ZoneResult<SocialZone> leaveResult = const ZoneResult.failure(ZoneFailure(
    type: ZoneFailureType.serviceUnavailable,
    message: 'Deferred',
  ));

  int getZonesCallCount = 0;
  String? lastCategoryPassed;
  String? lastQueryPassed;

  @override
  Future<ZoneResult<List<SocialZone>>> getZones({String? category, String? query}) async {
    getZonesCallCount++;
    lastCategoryPassed = category;
    lastQueryPassed = query;
    return zonesResult;
  }

  @override
  Future<ZoneResult<SocialZone>> getZoneDetails(String zoneId) async => detailsResult;

  @override
  Future<ZoneResult<SocialZone>> joinZone(String zoneId) async => joinResult;

  @override
  Future<ZoneResult<SocialZone>> leaveZone(String zoneId) async => leaveResult;
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject = 'user-zones-01';
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

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) {
    _clearers.add(clearer);
    return () => _clearers.remove(clearer);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockSocialZoneRepository mockRepo;
  late FakeSessionController fakeSession;

  setUp(() {
    mockRepo = MockSocialZoneRepository();
    fakeSession = FakeSessionController();
  });

  group('SocialZonesViewModel State & Lifecycle', () {
    test('initial state is correct', () {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.status, SocialZonesStatus.initial);
      expect(vm.zones, isEmpty);
      expect(vm.selectedCategory, 'All');
      expect(vm.searchQuery, '');
      expect(vm.selectedZone, isNull);
      expect(vm.isAuthorized, isTrue);
    });

    test('denies access and sets status when unauthenticated or not opted in', () async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );

      await vm.loadZones();

      expect(vm.status, SocialZonesStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      expect(mockRepo.getZonesCallCount, 0);
    });

    test('loads zones successfully into ready state', () async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadZones();

      expect(vm.status, SocialZonesStatus.ready);
      expect(vm.isReady, isTrue);
      expect(vm.zones.length, 1);
      expect(vm.zones.first.name, 'Designers Circle');
      expect(mockRepo.getZonesCallCount, 1);
    });

    test('transitions to empty state when repository returns zero zones', () async {
      mockRepo.zonesResult = const ZoneResult.success([]);
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadZones();

      expect(vm.status, SocialZonesStatus.empty);
      expect(vm.isEmpty, isTrue);
      expect(vm.zones, isEmpty);
    });

    test('handles serviceUnavailable failure gracefully without crashing', () async {
      mockRepo.zonesResult = const ZoneResult.failure(ZoneFailure(
        type: ZoneFailureType.serviceUnavailable,
        message: 'Backend dormant',
      ));
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadZones();

      expect(vm.status, SocialZonesStatus.serviceUnavailable);
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.errorMessage, 'Backend dormant');
    });

    test('filters by category and passes query correctly', () async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      vm.setCategory('Design');
      expect(mockRepo.lastCategoryPassed, 'Design');

      vm.setSearchQuery('Circle');
      expect(mockRepo.lastQueryPassed, 'Circle');
    });

    test('clears private state upon session sign out', () async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadZones();
      expect(vm.zones.isNotEmpty, isTrue);

      fakeSession.triggerSignOut();

      expect(vm.status, SocialZonesStatus.initial);
      expect(vm.zones, isEmpty);
      expect(vm.selectedZone, isNull);
    });

    test('authorizes via SocialAccessEvidence when provided', () async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-zones-01'),
      );

      expect(vm.isAuthorized, isTrue);
      await vm.loadZones();
      expect(vm.status, SocialZonesStatus.ready);
      expect(vm.zones, isNotEmpty);
    });

    test('denies access and clears private state upon account switch', () async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadZones();
      expect(vm.zones, isNotEmpty);

      fakeSession.subject = 'switched-zones-02';
      expect(vm.zones, isEmpty);
      expect(vm.isAuthorized, isFalse);
      await vm.loadZones();
      expect(vm.status, SocialZonesStatus.accessDenied);
    });
  });
}
