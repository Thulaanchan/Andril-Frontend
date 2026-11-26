import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone_repository.dart';

class _FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject;

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
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) => () {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeSessionController sessionController;

  const sampleFixtureZones = [
    SocialZone(
      id: 'fixture-zone-1',
      name: 'Flutter Architects',
      description: 'Discussing state management and clean architecture patterns.',
      category: 'Technology',
      memberCount: 42,
      membershipStatus: ZoneMembershipStatus.notMember,
      rules: ['Be respectful', 'No spam'],
      tags: ['flutter', 'dart', 'architecture'],
    ),
    SocialZone(
      id: 'fixture-zone-2',
      name: 'Mountain Hikers',
      description: 'Weekend hikes and trail explorations.',
      category: 'Outdoors',
      memberCount: 19,
      membershipStatus: ZoneMembershipStatus.member,
      rules: ['Leave no trace'],
      tags: ['hiking', 'outdoors', 'nature'],
    ),
  ];

  setUp(() {
    sessionController = _FakeSessionController();
    sessionController.phase = SessionPhase.signedIn;
    sessionController.subject = 'user-test-123';
  });

  group('SocialZoneRepository Authentication Boundaries', () {
    test('denies getZones when unauthenticated', () async {
      sessionController.phase = SessionPhase.signedOut;
      final repo = SocialZoneRepository(
        sessionController: sessionController,
        isDormant: false,
        fixtureZones: sampleFixtureZones,
      );

      final result = await repo.getZones();
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.type, equals(ZoneFailureType.authorizationDenied));
      expect(result.dataOrNull, isNull);
    });

    test('denies getZoneDetails when unauthenticated', () async {
      sessionController.phase = SessionPhase.signedOut;
      final repo = SocialZoneRepository(
        sessionController: sessionController,
        isDormant: false,
        fixtureZones: sampleFixtureZones,
      );

      final result = await repo.getZoneDetails('fixture-zone-1');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.type, equals(ZoneFailureType.authorizationDenied));
      expect(result.dataOrNull, isNull);
    });

    test('denies joinZone when unauthenticated', () async {
      sessionController.phase = SessionPhase.signedOut;
      final repo = SocialZoneRepository(
        sessionController: sessionController,
        isDormant: false,
      );

      final result = await repo.joinZone('fixture-zone-1');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.type, equals(ZoneFailureType.authorizationDenied));
    });

    test('denies leaveZone when unauthenticated', () async {
      sessionController.phase = SessionPhase.signedOut;
      final repo = SocialZoneRepository(
        sessionController: sessionController,
        isDormant: false,
      );

      final result = await repo.leaveZone('fixture-zone-1');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.type, equals(ZoneFailureType.authorizationDenied));
    });
  });

  group('SocialZoneRepository Dormant Production Boundaries', () {
    test('returns explicit serviceUnavailable for getZones in dormant mode without synthetic data', () async {
      final repo = SocialZoneRepository(
        sessionController: sessionController,
        isDormant: true,
      );

      final result = await repo.getZones();
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.type, equals(ZoneFailureType.serviceUnavailable));
      expect(result.failureOrNull?.message, contains('dormant'));
      expect(result.dataOrNull, isNull);
    });

    test('returns explicit serviceUnavailable for getZoneDetails in dormant mode', () async {
      final repo = SocialZoneRepository(
        sessionController: sessionController,
        isDormant: true,
      );

      final result = await repo.getZoneDetails('zone-tech-innovators');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.type, equals(ZoneFailureType.serviceUnavailable));
      expect(result.failureOrNull?.message, contains('dormant'));
      expect(result.dataOrNull, isNull);
    });

    test('joinZone returns explicit serviceUnavailable deferred message', () async {
      final repo = SocialZoneRepository(
        sessionController: sessionController,
        isDormant: true,
      );

      final result = await repo.joinZone('zone-tech-innovators');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.type, equals(ZoneFailureType.serviceUnavailable));
      expect(result.failureOrNull?.message, contains('deferred'));
      expect(result.dataOrNull, isNull);
    });

    test('leaveZone returns explicit serviceUnavailable deferred message', () async {
      final repo = SocialZoneRepository(
        sessionController: sessionController,
        isDormant: true,
      );

      final result = await repo.leaveZone('zone-tech-innovators');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.type, equals(ZoneFailureType.serviceUnavailable));
      expect(result.failureOrNull?.message, contains('deferred'));
      expect(result.dataOrNull, isNull);
    });
  });

  group('SocialZoneRepository Fixture Filtering (Non-Dormant / Testing)', () {
    test('retrieves fixture zones filtered by category', () async {
      final repo = SocialZoneRepository(
        sessionController: sessionController,
        isDormant: false,
        fixtureZones: sampleFixtureZones,
      );

      final result = await repo.getZones(category: 'Technology');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.length, equals(1));
      expect(result.dataOrNull?.first.name, equals('Flutter Architects'));
    });

    test('retrieves fixture zones filtered by query', () async {
      final repo = SocialZoneRepository(
        sessionController: sessionController,
        isDormant: false,
        fixtureZones: sampleFixtureZones,
      );

      final result = await repo.getZones(query: 'hike');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.length, equals(1));
      expect(result.dataOrNull?.first.id, equals('fixture-zone-2'));
    });

    test('returns notFound when zoneId does not exist in fixtures', () async {
      final repo = SocialZoneRepository(
        sessionController: sessionController,
        isDormant: false,
        fixtureZones: sampleFixtureZones,
      );

      final result = await repo.getZoneDetails('nonexistent-id');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.type, equals(ZoneFailureType.notFound));
    });
  });

  group('SocialZoneRepository Privacy & Diagnostic Safety', () {
    test('diagnostic string does not expose private subject or identity details', () async {
      sessionController.subject = 'private_user_uuid_999';
      final repo = SocialZoneRepository(
        sessionController: sessionController,
        isDormant: true,
      );

      final result = await repo.getZones();
      final diag = result.failureOrNull?.toString() ?? '';
      expect(diag, isNot(contains('private_user_uuid_999')));
    });
  });
}
