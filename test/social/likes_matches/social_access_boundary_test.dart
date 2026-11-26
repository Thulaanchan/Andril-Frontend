import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;

  @override
  SessionPhase get phase => _phase;

  set phase(SessionPhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) => () {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSessionController fakeSession;
  const boundary = SocialAccessBoundary();

  setUp(() {
    fakeSession = FakeSessionController();
  });

  group('SocialAccessBoundary (Task 086)', () {
    test('grants access when session is signed in and evidence is authoritative adult opt-in', () {
      final evidence = SocialAccessEvidence.authorized(userId: 'u-eligible-1');

      final status = boundary.evaluateAccess(
        sessionController: fakeSession,
        evidence: evidence,
      );

      expect(status, SocialAccessStatus.granted);
      expect(boundary.isAccessGranted(sessionController: fakeSession, evidence: evidence), isTrue);
    });

    test('denies access with unauthenticated when sessionController is null', () {
      final evidence = SocialAccessEvidence.authorized(userId: 'u-1');

      final status = boundary.evaluateAccess(
        sessionController: null,
        evidence: evidence,
      );

      expect(status, SocialAccessStatus.unauthenticated);
      expect(boundary.isAccessGranted(sessionController: null, evidence: evidence), isFalse);
    });

    test('denies access with unauthenticated when session phase is signedOut', () {
      fakeSession.phase = SessionPhase.signedOut;
      final evidence = SocialAccessEvidence.authorized(userId: 'u-1');

      final status = boundary.evaluateAccess(
        sessionController: fakeSession,
        evidence: evidence,
      );

      expect(status, SocialAccessStatus.unauthenticated);
    });

    test('denies access with unavailable when evidence is missing or unauthoritative', () {
      final statusNull = boundary.evaluateAccess(
        sessionController: fakeSession,
        evidence: null,
      );
      expect(statusNull, SocialAccessStatus.unavailable);

      final unverified = SocialAccessEvidence.unverified(userId: 'u-hack-1');
      final statusUnverified = boundary.evaluateAccess(
        sessionController: fakeSession,
        evidence: unverified,
      );
      expect(statusUnverified, SocialAccessStatus.unavailable);
    });

    test('denies access with underage when adult verification is false', () {
      final underageEvidence = SocialAccessEvidence(
        userId: 'u-teen-1',
        isAdult: false,
        isOptedIn: true,
        verifiedAt: DateTime.now(),
        isAuthoritative: true,
      );

      final status = boundary.evaluateAccess(
        sessionController: fakeSession,
        evidence: underageEvidence,
      );

      expect(status, SocialAccessStatus.underage);
      expect(boundary.isAccessGranted(sessionController: fakeSession, evidence: underageEvidence), isFalse);
    });

    test('denies access with optInRequired when user has not opted into social', () {
      final noOptInEvidence = SocialAccessEvidence(
        userId: 'u-adult-no-opt',
        isAdult: true,
        isOptedIn: false,
        verifiedAt: DateTime.now(),
        isAuthoritative: true,
      );

      final status = boundary.evaluateAccess(
        sessionController: fakeSession,
        evidence: noOptInEvidence,
      );

      expect(status, SocialAccessStatus.optInRequired);
      expect(boundary.isAccessGranted(sessionController: fakeSession, evidence: noOptInEvidence), isFalse);
    });

    test('denies access with revoked when module participation is suspended', () {
      final revokedEvidence = SocialAccessEvidence(
        userId: 'u-suspended',
        isAdult: true,
        isOptedIn: true,
        isModuleGranted: false,
        verifiedAt: DateTime.now(),
        isAuthoritative: true,
      );

      final status = boundary.evaluateAccess(
        sessionController: fakeSession,
        evidence: revokedEvidence,
      );

      expect(status, SocialAccessStatus.revoked);
      expect(boundary.isAccessGranted(sessionController: fakeSession, evidence: revokedEvidence), isFalse);
    });

    test('JSON serialization roundtrip maintains authoritative integrity', () {
      final original = SocialAccessEvidence.authorized(
        userId: 'u-roundtrip',
        verifiedAt: DateTime.utc(2026, 11, 26, 12, 0, 0),
      );

      final json = original.toJson();
      final restored = SocialAccessEvidence.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.isAdult, isTrue);
      expect(restored.isOptedIn, isTrue);
      expect(restored.isAuthoritative, isTrue);
    });
  });
}
