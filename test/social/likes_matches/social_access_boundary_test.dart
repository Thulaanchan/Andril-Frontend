import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject;
  int _epoch = 1;

  @override
  SessionPhase get phase => _phase;

  set phase(SessionPhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }

  @override
  String? get subject => _subject;

  set subject(String? s) {
    _subject = s;
    notifyListeners();
  }

  @override
  BackendSession? get backendSession =>
      _subject != null && _phase == SessionPhase.signedIn ? (subject: _subject!, epoch: _epoch) : null;

  void setSession({required String subject, int epoch = 1}) {
    _subject = subject;
    _epoch = epoch;
    _phase = SessionPhase.signedIn;
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

  group('SocialAccessBoundary (Tasks 086 & 096)', () {
    test('grants access when session is signed in and evidence is authoritative adult opt-in', () {
      final evidence = SocialAccessEvidence.authorized(userId: 'u-eligible-1');

      final status = boundary.evaluateAccess(
        sessionController: fakeSession,
        evidence: evidence,
      );

      expect(status, SocialAccessStatus.granted);
      expect(boundary.isAccessGranted(sessionController: fakeSession, evidence: evidence), isTrue);
    });

    test('grants access when session subject matches evidence and epoch matches', () {
      fakeSession.setSession(subject: 'u-eligible-1', epoch: 2);
      final evidence = SocialAccessEvidence.authorized(
        userId: 'u-eligible-1',
        sessionEpoch: 2,
      );

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

    test('denies access with unauthenticated when session phase is signedOut or restoring', () {
      fakeSession.phase = SessionPhase.signedOut;
      final evidence = SocialAccessEvidence.authorized(userId: 'u-1');

      expect(
        boundary.evaluateAccess(sessionController: fakeSession, evidence: evidence),
        SocialAccessStatus.unauthenticated,
      );

      fakeSession.phase = SessionPhase.restoring;
      expect(
        boundary.evaluateAccess(sessionController: fakeSession, evidence: evidence),
        SocialAccessStatus.unauthenticated,
      );
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

    test('denies access with mismatched when evidence userId does not match session subject', () {
      fakeSession.setSession(subject: 'u-active-user');
      final mismatchedEvidence = SocialAccessEvidence.authorized(userId: 'u-other-account');

      final status = boundary.evaluateAccess(
        sessionController: fakeSession,
        evidence: mismatchedEvidence,
      );

      expect(status, SocialAccessStatus.mismatched);
      expect(boundary.isAccessGranted(sessionController: fakeSession, evidence: mismatchedEvidence), isFalse);
    });

    test('denies access with stale when evidence sessionEpoch differs from backendSession epoch', () {
      fakeSession.setSession(subject: 'u-active-user', epoch: 3);
      final staleEvidence = SocialAccessEvidence.authorized(
        userId: 'u-active-user',
        sessionEpoch: 2, // Outdated epoch
      );

      final status = boundary.evaluateAccess(
        sessionController: fakeSession,
        evidence: staleEvidence,
      );

      expect(status, SocialAccessStatus.stale);
      expect(boundary.isAccessGranted(sessionController: fakeSession, evidence: staleEvidence), isFalse);
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

    test('denies access with revoked when module participation is suspended or revoked', () {
      final suspendedEvidence = SocialAccessEvidence(
        userId: 'u-suspended',
        isAdult: true,
        isOptedIn: true,
        isModuleGranted: false,
        verifiedAt: DateTime.now(),
        isAuthoritative: true,
      );

      expect(
        boundary.evaluateAccess(sessionController: fakeSession, evidence: suspendedEvidence),
        SocialAccessStatus.revoked,
      );

      final revokedEvidence = SocialAccessEvidence.revoked(userId: 'u-revoked');
      expect(
        boundary.evaluateAccess(sessionController: fakeSession, evidence: revokedEvidence),
        SocialAccessStatus.revoked,
      );
      expect(boundary.isAccessGranted(sessionController: fakeSession, evidence: revokedEvidence), isFalse);
    });

    test('JSON serialization roundtrip maintains authoritative integrity and epoch', () {
      final original = SocialAccessEvidence.authorized(
        userId: 'u-roundtrip',
        verifiedAt: DateTime.utc(2026, 11, 26, 12, 0, 0),
        sessionEpoch: 5,
      );

      final json = original.toJson();
      final restored = SocialAccessEvidence.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.isAdult, isTrue);
      expect(restored.isOptedIn, isTrue);
      expect(restored.isAuthoritative, isTrue);
      expect(restored.sessionEpoch, 5);
      expect(restored.isRevoked, isFalse);
    });
  });
}
