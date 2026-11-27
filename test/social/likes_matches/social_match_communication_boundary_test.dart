import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_match_communication_boundary.dart';

void main() {
  const boundary = SocialMatchCommunicationBoundary();

  group('SocialMatchCommunicationBoundary (Tasks 088 & 098)', () {
    test('authorizes communication when match is mutual and M4 authorized', () {
      final evidence = MatchCommunicationEvidence.authorized(
        matchId: 'match-101',
        participantA: 'user-a',
        participantB: 'user-b',
        m4ChannelId: 'm4-ch-999',
      );

      final status = boundary.evaluateMatchCommunication(evidence);

      expect(status, MatchCommunicationStatus.authorized);
      expect(boundary.canInitiateCommunication(evidence), isTrue);
    });

    test('authorizes communication when callerId matches participantA or participantB', () {
      final evidence = MatchCommunicationEvidence.authorized(
        matchId: 'match-101',
        participantA: 'user-a',
        participantB: 'user-b',
        m4ChannelId: 'm4-ch-999',
      );

      expect(
        boundary.evaluateMatchCommunication(evidence, callerId: 'user-a'),
        MatchCommunicationStatus.authorized,
      );
      expect(
        boundary.evaluateMatchCommunication(evidence, callerId: 'user-b'),
        MatchCommunicationStatus.authorized,
      );
      expect(boundary.canInitiateCommunication(evidence, callerId: 'user-a'), isTrue);
    });

    test('denies communication with unauthorized when callerId does not match either participant', () {
      final evidence = MatchCommunicationEvidence.authorized(
        matchId: 'match-101',
        participantA: 'user-a',
        participantB: 'user-b',
        m4ChannelId: 'm4-ch-999',
      );

      final status = boundary.evaluateMatchCommunication(evidence, callerId: 'user-intruder');

      expect(status, MatchCommunicationStatus.unauthorized);
      expect(boundary.canInitiateCommunication(evidence, callerId: 'user-intruder'), isFalse);
    });

    test('denies communication with unauthorized when participants are empty or identical', () {
      final emptyA = MatchCommunicationEvidence.authorized(
        matchId: 'match-101',
        participantA: '',
        participantB: 'user-b',
        m4ChannelId: 'm4-ch-999',
      );
      expect(boundary.evaluateMatchCommunication(emptyA), MatchCommunicationStatus.unauthorized);

      final identical = MatchCommunicationEvidence.authorized(
        matchId: 'match-101',
        participantA: 'user-same',
        participantB: 'user-same',
        m4ChannelId: 'm4-ch-999',
      );
      expect(boundary.evaluateMatchCommunication(identical), MatchCommunicationStatus.unauthorized);
    });

    test('denies communication when evidence is null', () {
      final status = boundary.evaluateMatchCommunication(null);

      expect(status, MatchCommunicationStatus.unauthorized);
      expect(boundary.canInitiateCommunication(null), isFalse);
    });

    test('denies communication with pendingMutualMatch when match is one-sided', () {
      final evidence = MatchCommunicationEvidence.pending(
        matchId: 'match-102',
        participantA: 'user-a',
        participantB: 'user-b',
      );

      final status = boundary.evaluateMatchCommunication(evidence);

      expect(status, MatchCommunicationStatus.pendingMutualMatch);
      expect(boundary.canInitiateCommunication(evidence), isFalse);
    });

    test('denies communication with blocked when connection is blocked', () {
      final evidence = MatchCommunicationEvidence(
        matchId: 'match-103',
        participantA: 'user-a',
        participantB: 'user-b',
        isMutual: true,
        isBlocked: true,
        isUnmatched: false,
        m4ChannelId: 'm4-ch-123',
        verifiedAt: DateTime.now(),
        isM4Authorized: true,
      );

      final status = boundary.evaluateMatchCommunication(evidence);

      expect(status, MatchCommunicationStatus.blocked);
      expect(boundary.canInitiateCommunication(evidence), isFalse);
    });

    test('denies communication with unmatched when connection is dissolved', () {
      final evidence = MatchCommunicationEvidence(
        matchId: 'match-104',
        participantA: 'user-a',
        participantB: 'user-b',
        isMutual: true,
        isBlocked: false,
        isUnmatched: true,
        m4ChannelId: 'm4-ch-123',
        verifiedAt: DateTime.now(),
        isM4Authorized: true,
      );

      final status = boundary.evaluateMatchCommunication(evidence);

      expect(status, MatchCommunicationStatus.unmatched);
      expect(boundary.canInitiateCommunication(evidence), isFalse);
    });

    test('denies communication with expired when evidence is marked expired', () {
      final evidence = MatchCommunicationEvidence(
        matchId: 'match-exp',
        participantA: 'user-a',
        participantB: 'user-b',
        isMutual: true,
        isBlocked: false,
        isUnmatched: false,
        isExpired: true,
        m4ChannelId: 'm4-ch-123',
        verifiedAt: DateTime.now().subtract(const Duration(days: 40)),
        isM4Authorized: true,
      );

      final status = boundary.evaluateMatchCommunication(evidence);

      expect(status, MatchCommunicationStatus.expired);
      expect(boundary.canInitiateCommunication(evidence), isFalse);
    });

    test('denies communication with m4Unavailable when M4 authorization is missing or channel is empty', () {
      final noM4Auth = MatchCommunicationEvidence(
        matchId: 'match-105',
        participantA: 'user-a',
        participantB: 'user-b',
        isMutual: true,
        isBlocked: false,
        isUnmatched: false,
        m4ChannelId: 'm4-ch-123',
        verifiedAt: DateTime.now(),
        isM4Authorized: false,
      );

      expect(boundary.evaluateMatchCommunication(noM4Auth), MatchCommunicationStatus.m4Unavailable);
      expect(boundary.canInitiateCommunication(noM4Auth), isFalse);

      final emptyChannel = MatchCommunicationEvidence(
        matchId: 'match-106',
        participantA: 'user-a',
        participantB: 'user-b',
        isMutual: true,
        isBlocked: false,
        isUnmatched: false,
        m4ChannelId: '',
        verifiedAt: DateTime.now(),
        isM4Authorized: true,
      );

      expect(boundary.evaluateMatchCommunication(emptyChannel), MatchCommunicationStatus.m4Unavailable);
    });

    test('denies communication with unauthorized when verifiedAt timestamp is invalid or zero', () {
      final invalidTimestampEvidence = MatchCommunicationEvidence(
        matchId: 'match-101',
        participantA: 'user-a',
        participantB: 'user-b',
        isMutual: true,
        m4ChannelId: 'm4-ch-999',
        verifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
        isM4Authorized: true,
      );

      final status = boundary.evaluateMatchCommunication(invalidTimestampEvidence);
      expect(status, MatchCommunicationStatus.unauthorized);
      expect(boundary.canInitiateCommunication(invalidTimestampEvidence), isFalse);
    });

    test('redacts private matchId in toString diagnostics', () {
      final evidence = MatchCommunicationEvidence.authorized(
        matchId: 'match-secret-12345',
        participantA: 'u-1',
        participantB: 'u-2',
        m4ChannelId: 'ch-1',
      );
      expect(evidence.toString(), contains('matchId: redacted'));
      expect(evidence.toString(), isNot(contains('match-secret-12345')));
    });

    test('JSON deserialization with invalid timestamp defaults to epoch 0 and fails closed', () {
      final json = {
        'matchId': 'match-json',
        'participantA': 'u-1',
        'participantB': 'u-2',
        'isMutual': true,
        'm4ChannelId': 'm4-channel-abc',
        'verifiedAt': 'invalid-date-string',
        'isM4Authorized': true,
      };

      final restored = MatchCommunicationEvidence.fromJson(json);
      expect(restored.verifiedAt.millisecondsSinceEpoch, 0);
      expect(boundary.canInitiateCommunication(restored), isFalse);
    });

    test('JSON roundtrip preserves communication authorization evidence including expired field', () {
      final original = MatchCommunicationEvidence.authorized(
        matchId: 'match-json',
        participantA: 'u-1',
        participantB: 'u-2',
        m4ChannelId: 'm4-channel-abc',
        verifiedAt: DateTime.utc(2026, 11, 26, 14, 0, 0),
        isExpired: false,
      );

      final json = original.toJson();
      final restored = MatchCommunicationEvidence.fromJson(json);

      expect(restored.matchId, original.matchId);
      expect(restored.participantA, original.participantA);
      expect(restored.participantB, original.participantB);
      expect(restored.isMutual, isTrue);
      expect(restored.isM4Authorized, isTrue);
      expect(restored.m4ChannelId, 'm4-channel-abc');
      expect(restored.isExpired, isFalse);
    });
  });
}
