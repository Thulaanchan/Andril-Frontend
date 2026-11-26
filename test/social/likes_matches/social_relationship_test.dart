import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/social_relationship.dart';

void main() {
  group('SocialRelationshipState Enum & Parsing', () {
    test('parses canonical state strings correctly', () {
      expect(SocialRelationshipState.parse('Matched'), SocialRelationshipState.matched);
      expect(SocialRelationshipState.parse('matched'), SocialRelationshipState.matched);
      expect(SocialRelationshipState.parse('PendingUnilateral'), SocialRelationshipState.pendingUnilateral);
      expect(SocialRelationshipState.parse('pending'), SocialRelationshipState.pendingUnilateral);
      expect(SocialRelationshipState.parse('Passed'), SocialRelationshipState.passed);
      expect(SocialRelationshipState.parse('Revoked'), SocialRelationshipState.revoked);
      expect(SocialRelationshipState.parse('Blocked'), SocialRelationshipState.blocked);
      expect(SocialRelationshipState.parse('None'), SocialRelationshipState.none);
    });

    test('rejects unknown states and returns specified or default fallback', () {
      expect(SocialRelationshipState.parse('unknown'), SocialRelationshipState.none);
      expect(SocialRelationshipState.parse(''), SocialRelationshipState.none);
      expect(SocialRelationshipState.parse(null), SocialRelationshipState.none);
      expect(
        SocialRelationshipState.parse('invalid', defaultValue: SocialRelationshipState.blocked),
        SocialRelationshipState.blocked,
      );
    });

    test('state boolean helpers return expected values', () {
      expect(SocialRelationshipState.matched.isMatched, isTrue);
      expect(SocialRelationshipState.matched.isPending, isFalse);
      expect(SocialRelationshipState.pendingUnilateral.isPending, isTrue);
      expect(SocialRelationshipState.passed.isPassed, isTrue);
      expect(SocialRelationshipState.revoked.isRevoked, isTrue);
      expect(SocialRelationshipState.blocked.isBlocked, isTrue);
    });
  });

  group('DirectionalInterest Enum', () {
    test('parses from boolean and string values', () {
      expect(DirectionalInterest.fromValue(true), DirectionalInterest.positive);
      expect(DirectionalInterest.fromValue(false), DirectionalInterest.negative);
      expect(DirectionalInterest.fromValue('like'), DirectionalInterest.positive);
      expect(DirectionalInterest.fromValue('pass'), DirectionalInterest.negative);
      expect(DirectionalInterest.fromValue('unknown'), DirectionalInterest.none);
      expect(DirectionalInterest.fromValue(null), DirectionalInterest.none);
    });

    test('boolean flags identify polarity correctly', () {
      expect(DirectionalInterest.positive.isPositive, isTrue);
      expect(DirectionalInterest.positive.isNegative, isFalse);
      expect(DirectionalInterest.negative.isNegative, isTrue);
      expect(DirectionalInterest.none.isPositive, isFalse);
    });
  });

  group('SocialMatchEvidence Invariants', () {
    final now = DateTime.utc(2026, 11, 26, 10, 0);

    test('constructs and serializes evidence immutably', () {
      final evidence = SocialMatchEvidence(matchId: 'match-123', matchedAtUtc: now);
      expect(evidence.matchId, 'match-123');
      expect(evidence.matchedAtUtc, now);

      final json = evidence.toJson();
      expect(json['matchId'], 'match-123');
      expect(json['matchedAtUtc'], now.toIso8601String());

      final reconstituted = SocialMatchEvidence.fromJson(json);
      expect(reconstituted, equals(evidence));
      expect(reconstituted.hashCode, equals(evidence.hashCode));
    });

    test('redacts matchId in diagnostic toString', () {
      final evidence = SocialMatchEvidence(matchId: 'secret-match-guid', matchedAtUtc: now);
      expect(evidence.toString(), contains('[redacted]'));
      expect(evidence.toString(), isNot(contains('secret-match-guid')));
    });
  });

  group('SocialRelationship Domain Invariants & Privacy Boundaries', () {
    final candidate = SocialCandidate(
      id: 'candidate-01',
      displayName: 'Maya',
      age: 24,
      approximateDistanceKm: 12,
      isVerified: true,
    );

    final matchEvidence = SocialMatchEvidence(
      matchId: 'match-uuid-001',
      matchedAtUtc: DateTime.utc(2026, 11, 26, 12, 0),
    );

    test('defensively immutabilizes tags collection', () {
      final mutableTags = ['Hiking', 'Art'];
      final relationship = SocialRelationship(
        id: 'rel-01',
        targetProfileId: 'candidate-01',
        candidate: candidate,
        tags: mutableTags,
      );

      expect(relationship.tags, equals(['Hiking', 'Art']));
      // Modifying original source list must not affect internal tags
      mutableTags.add('Music');
      expect(relationship.tags, equals(['Hiking', 'Art']));

      // Attempting to mutate internal tags list directly must throw UnsupportedError
      expect(() => relationship.tags.add('NewTag'), throwsUnsupportedError);
    });

    test('distinguishes directional interest from server-confirmed mutual match', () {
      // 1. One-sided interest (unilateral) - cannot communicate
      final unilateralRel = SocialRelationship(
        id: 'rel-02',
        targetProfileId: 'candidate-01',
        candidate: candidate,
        state: SocialRelationshipState.pendingUnilateral,
        callerInterest: DirectionalInterest.positive,
      );
      expect(unilateralRel.hasActiveMatch, isFalse);
      expect(unilateralRel.canCommunicate, isFalse);

      // 2. Matched state WITHOUT server evidence - cannot communicate
      final missingEvidenceRel = SocialRelationship(
        id: 'rel-03',
        targetProfileId: 'candidate-01',
        candidate: candidate,
        state: SocialRelationshipState.matched,
        callerInterest: DirectionalInterest.positive,
        matchEvidence: null, // No server evidence
      );
      expect(missingEvidenceRel.hasActiveMatch, isFalse);
      expect(missingEvidenceRel.canCommunicate, isFalse);

      // 3. Matched state WITH confirmed server evidence - communication unlocked
      final confirmedMatchRel = SocialRelationship(
        id: 'rel-04',
        targetProfileId: 'candidate-01',
        candidate: candidate,
        state: SocialRelationshipState.matched,
        callerInterest: DirectionalInterest.positive,
        matchEvidence: matchEvidence,
      );
      expect(confirmedMatchRel.hasActiveMatch, isTrue);
      expect(confirmedMatchRel.canCommunicate, isTrue);
      expect(confirmedMatchRel.displayName, 'Maya');
    });

    test('equality and hashcode contracts hold across identical instances', () {
      final rel1 = SocialRelationship(
        id: 'rel-10',
        targetProfileId: 'candidate-01',
        candidate: candidate,
        state: SocialRelationshipState.matched,
        callerInterest: DirectionalInterest.positive,
        matchEvidence: matchEvidence,
        isFavorite: true,
        tags: const ['Coffee', 'Travel'],
      );

      final rel2 = SocialRelationship(
        id: 'rel-10',
        targetProfileId: 'candidate-01',
        candidate: candidate,
        state: SocialRelationshipState.matched,
        callerInterest: DirectionalInterest.positive,
        matchEvidence: matchEvidence,
        isFavorite: true,
        tags: const ['Coffee', 'Travel'],
      );

      expect(rel1, equals(rel2));
      expect(rel1.hashCode, equals(rel2.hashCode));

      final relDifferent = rel1.copyWith(isFavorite: false);
      expect(rel1, isNot(equals(relDifferent)));
    });

    test('serializes and deserializes JSON roundtrip accurately', () {
      final relationship = SocialRelationship(
        id: 'rel-20',
        targetProfileId: 'candidate-01',
        candidate: candidate,
        state: SocialRelationshipState.matched,
        callerInterest: DirectionalInterest.positive,
        matchEvidence: matchEvidence,
        createdAtUtc: DateTime.utc(2026, 11, 26, 8, 30),
        isFavorite: true,
        tags: const ['Music'],
      );

      final json = relationship.toJson();
      final reconstituted = SocialRelationship.fromJson(json);

      expect(reconstituted.id, relationship.id);
      expect(reconstituted.targetProfileId, relationship.targetProfileId);
      expect(reconstituted.state, relationship.state);
      expect(reconstituted.callerInterest, relationship.callerInterest);
      expect(reconstituted.hasActiveMatch, isTrue);
      expect(reconstituted.isFavorite, isTrue);
      expect(reconstituted.tags, equals(['Music']));
    });

    test('diagnostic toString does not expose raw private candidate fields', () {
      final relationship = SocialRelationship(
        id: 'rel-30',
        targetProfileId: 'candidate-01',
        candidate: candidate,
        state: SocialRelationshipState.matched,
        matchEvidence: matchEvidence,
      );

      final diag = relationship.toString();
      expect(diag, contains('SocialRelationship(id: rel-30'));
      expect(diag, contains('hasActiveMatch: true'));
    });
  });

  group('DTO Models Roundtrip', () {
    test('SocialRelationshipOperationResult fromJson and toJson', () {
      final dto = SocialRelationshipOperationResult.fromJson({
        'success': true,
        'matchCreated': true,
        'matchId': 'match-guid-123',
        'visibleState': 'Matched',
      });
      expect(dto.success, isTrue);
      expect(dto.matchCreated, isTrue);
      expect(dto.matchId, 'match-guid-123');
      expect(dto.visibleState, 'Matched');
      expect(dto.toJson()['matchCreated'], isTrue);
    });

    test('SocialRelationshipStatusResult fromJson and toJson', () {
      final dto = SocialRelationshipStatusResult.fromJson({
        'hasActiveMatch': true,
        'matchId': 'match-guid-456',
        'matchedAtUtc': '2026-11-26T12:00:00.000Z',
      });
      expect(dto.hasActiveMatch, isTrue);
      expect(dto.matchId, 'match-guid-456');
      expect(dto.matchedAtUtc, isNotNull);
    });

    test('SocialRevocationResult fromJson and toJson', () {
      final dto = SocialRevocationResult.fromJson({
        'success': true,
        'matchRevoked': true,
      });
      expect(dto.success, isTrue);
      expect(dto.matchRevoked, isTrue);
    });
  });
}
