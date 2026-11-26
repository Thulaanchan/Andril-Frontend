import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/domain/entities/learning_growth_evidence.dart';

void main() {
  group('LearningEvidenceKind', () {
    test('parses known and fallback values accurately', () {
      expect(
        LearningEvidenceKind.parse('verified'),
        LearningEvidenceKind.verified,
      );
      expect(
        LearningEvidenceKind.parse('verifiedsource'),
        LearningEvidenceKind.verified,
      );
      expect(
        LearningEvidenceKind.parse('verified_source'),
        LearningEvidenceKind.verified,
      );
      expect(
        LearningEvidenceKind.parse('selfreported'),
        LearningEvidenceKind.selfReported,
      );
      expect(
        LearningEvidenceKind.parse('self_reported'),
        LearningEvidenceKind.selfReported,
      );
      expect(
        LearningEvidenceKind.parse('self'),
        LearningEvidenceKind.selfReported,
      );
      expect(
        LearningEvidenceKind.parse(null),
        LearningEvidenceKind.selfReported,
      );
      expect(
        LearningEvidenceKind.parse('unknown_string'),
        LearningEvidenceKind.selfReported,
      );
      expect(
        LearningEvidenceKind.parse('unknown_string',
            defaultValue: LearningEvidenceKind.verified),
        LearningEvidenceKind.verified,
      );
    });

    test('getters return correct boolean values', () {
      expect(LearningEvidenceKind.selfReported.isSelfReported, isTrue);
      expect(LearningEvidenceKind.selfReported.isVerified, isFalse);
      expect(LearningEvidenceKind.verified.isVerified, isTrue);
      expect(LearningEvidenceKind.verified.isSelfReported, isFalse);
    });
  });

  group('EvidenceSufficiencyStatus', () {
    test('parses strings accurately with fallbacks', () {
      expect(
        EvidenceSufficiencyStatus.parse('verifiedsource'),
        EvidenceSufficiencyStatus.verifiedSource,
      );
      expect(
        EvidenceSufficiencyStatus.parse('verified_source'),
        EvidenceSufficiencyStatus.verifiedSource,
      );
      expect(
        EvidenceSufficiencyStatus.parse('selfreportedonly'),
        EvidenceSufficiencyStatus.selfReportedOnly,
      );
      expect(
        EvidenceSufficiencyStatus.parse('self_reported_only'),
        EvidenceSufficiencyStatus.selfReportedOnly,
      );
      expect(
        EvidenceSufficiencyStatus.parse('insufficientevidence'),
        EvidenceSufficiencyStatus.insufficientEvidence,
      );
      expect(
        EvidenceSufficiencyStatus.parse(null),
        EvidenceSufficiencyStatus.insufficientEvidence,
      );
      expect(
        EvidenceSufficiencyStatus.parse('random'),
        EvidenceSufficiencyStatus.insufficientEvidence,
      );
    });

    test('getters return correct flags', () {
      expect(
        EvidenceSufficiencyStatus.verifiedSource.isVerifiedSource,
        isTrue,
      );
      expect(
        EvidenceSufficiencyStatus.selfReportedOnly.isSelfReportedOnly,
        isTrue,
      );
      expect(
        EvidenceSufficiencyStatus.insufficientEvidence.isInsufficientEvidence,
        isTrue,
      );
    });
  });

  group('LearningGrowthEvidence', () {
    final now = DateTime(2026, 11, 26, 12, 0, 0);

    test('enforces module invariant strictly to "learning"', () {
      final ev = LearningGrowthEvidence(
        id: 'ev_01',
        accountId: 'acc_01',
        learningProfileId: 'prof_01',
        module: 'learning',
        title: 'Flutter Architecture',
        description: 'Implemented Clean Architecture',
        recordedAt: now,
      );
      expect(ev.module, 'learning');

      expect(
        () => LearningGrowthEvidence(
          id: 'ev_02',
          accountId: 'acc_01',
          learningProfileId: 'prof_01',
          module: 'classroom',
          title: 'Invalid module',
          description: 'Testing',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('enforces non-empty validation on required fields', () {
      expect(
        () => LearningGrowthEvidence(
          id: '   ',
          accountId: 'acc_01',
          learningProfileId: 'prof_01',
          title: 'Test',
          description: 'Desc',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => LearningGrowthEvidence(
          id: 'ev_01',
          accountId: '   ',
          learningProfileId: 'prof_01',
          title: 'Test',
          description: 'Desc',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => LearningGrowthEvidence(
          id: 'ev_01',
          accountId: 'acc_01',
          learningProfileId: '  ',
          title: 'Test',
          description: 'Desc',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => LearningGrowthEvidence(
          id: 'ev_01',
          accountId: 'acc_01',
          learningProfileId: 'prof_01',
          title: '  ',
          description: 'Desc',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => LearningGrowthEvidence(
          id: 'ev_01',
          accountId: 'acc_01',
          learningProfileId: 'prof_01',
          title: 'Test',
          description: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deduplicates skillIds and sanitizes skillNames', () {
      final ev = LearningGrowthEvidence(
        id: 'ev_01',
        accountId: 'acc_01',
        learningProfileId: 'prof_01',
        title: 'Skills Test',
        description: 'Desc',
        skillIds: ['dart', 'flutter', 'dart', ' flutter '],
        skillNames: [' Dart ', 'Flutter', '  ', 'Dart'],
        recordedAt: now,
      );
      expect(ev.skillIds, ['dart', 'flutter']);
      expect(ev.skillNames, ['Dart', 'Flutter', 'Dart']);
    });

    test('factory recordSelfReport sets correct defaults', () {
      final ev = LearningGrowthEvidence.recordSelfReport(
        id: 'ev_sr_1',
        accountId: 'acc_01',
        learningProfileId: 'prof_01',
        title: 'Refactored State',
        description: 'Used Riverpod and MVVM',
        skillIds: ['flutter'],
        skillNames: ['Flutter'],
        sourceReference: 'Personal Project',
        recordedAt: now,
      );

      expect(ev.kind, LearningEvidenceKind.selfReported);
      expect(ev.isPrivate, isTrue);
      expect(ev.verifiedAt, isNull);
      expect(ev.verifierName, isNull);
      expect(ev.sourceReference, 'Personal Project');
    });

    test('factory recordVerified sets correct attributes', () {
      final verifiedTime = DateTime(2026, 11, 26, 13, 0, 0);
      final ev = LearningGrowthEvidence.recordVerified(
        id: 'ev_v_1',
        accountId: 'acc_01',
        learningProfileId: 'prof_01',
        title: 'System Design Assessment',
        description: 'Passed distributed systems evaluation',
        skillIds: ['sys_design'],
        skillNames: ['System Design'],
        sourceReference: 'Certified Assessment v2',
        verifierName: 'Google Dev Lead',
        recordedAt: now,
        verifiedAt: verifiedTime,
      );

      expect(ev.kind, LearningEvidenceKind.verified);
      expect(ev.isPrivate, isTrue);
      expect(ev.verifierName, 'Google Dev Lead');
      expect(ev.verifiedAt, verifiedTime);
    });

    test('redacted toString prevents PII leakage', () {
      final ev = LearningGrowthEvidence(
        id: 'sensitive_id',
        accountId: 'sensitive_acc',
        learningProfileId: 'sensitive_prof',
        title: 'Sensitive Title',
        description: 'Sensitive personal description',
      );
      expect(
        ev.toString(),
        'LearningGrowthEvidence [identities and associations omitted]',
      );
      expect(ev.toString().contains('sensitive'), isFalse);
    });

    test('JSON serialization round-trip succeeds', () {
      final ev = LearningGrowthEvidence(
        id: 'ev_01',
        accountId: 'acc_01',
        learningProfileId: 'prof_01',
        kind: LearningEvidenceKind.verified,
        isPrivate: true,
        title: 'Clean Architecture Practice',
        description: 'Refactored learning feature',
        skillIds: ['flutter', 'clean_arch'],
        skillNames: ['Flutter', 'Clean Architecture'],
        sourceReference: 'PR #113',
        recordedAt: now,
        verifiedAt: now.add(const Duration(hours: 1)),
        verifierName: 'Team Lead',
      );

      final json = ev.toJson();
      final reconstructed = LearningGrowthEvidence.fromJson(json);

      expect(reconstructed.id, ev.id);
      expect(reconstructed.accountId, ev.accountId);
      expect(reconstructed.learningProfileId, ev.learningProfileId);
      expect(reconstructed.kind, ev.kind);
      expect(reconstructed.isPrivate, isTrue);
      expect(reconstructed.title, ev.title);
      expect(reconstructed.description, ev.description);
      expect(reconstructed.skillIds, ev.skillIds);
      expect(reconstructed.skillNames, ev.skillNames);
      expect(reconstructed.sourceReference, ev.sourceReference);
      expect(reconstructed.verifierName, ev.verifierName);
      expect(reconstructed.recordedAt, ev.recordedAt);
      expect(reconstructed.verifiedAt, ev.verifiedAt);
      expect(reconstructed, equals(ev));
    });

    test('copyWith updates specified fields only', () {
      final ev = LearningGrowthEvidence(
        id: 'ev_01',
        accountId: 'acc_01',
        learningProfileId: 'prof_01',
        title: 'Initial',
        description: 'Initial desc',
        recordedAt: now,
      );

      final updated = ev.copyWith(title: 'Updated Title');
      expect(updated.title, 'Updated Title');
      expect(updated.description, 'Initial desc');
      expect(updated.id, 'ev_01');
    });
  });

  group('LearningTrackedSkill', () {
    test('validates non-empty fields and trims evidence IDs', () {
      final skill = LearningTrackedSkill(
        id: 'skill_01',
        name: ' Flutter Development ',
        category: ' Mobile ',
        associatedEvidenceIds: ['ev_01', ' ev_02 ', ''],
        sufficiencyStatus: EvidenceSufficiencyStatus.verifiedSource,
        notes: 'Personal growth target',
      );

      expect(skill.id, 'skill_01');
      expect(skill.name, 'Flutter Development');
      expect(skill.category, 'Mobile');
      expect(skill.associatedEvidenceIds, ['ev_01', 'ev_02']);
      expect(skill.evidenceCount, 2);
      expect(skill.hasEvidence, isTrue);
      expect(skill.sufficiencyStatus, EvidenceSufficiencyStatus.verifiedSource);
      expect(skill.notes, 'Personal growth target');

      expect(
        () => LearningTrackedSkill(id: '', name: 'Test', category: 'Cat'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('redacted toString prevents leakage', () {
      final skill = LearningTrackedSkill(
        id: 'secret_id',
        name: 'Secret Skill',
        category: 'Secret',
      );
      expect(skill.toString(), 'LearningTrackedSkill [skill identity omitted]');
    });

    test('JSON serialization roundtrip works', () {
      final skill = LearningTrackedSkill(
        id: 'sk_01',
        name: 'Dart',
        category: 'Language',
        associatedEvidenceIds: ['ev_01'],
        sufficiencyStatus: EvidenceSufficiencyStatus.selfReportedOnly,
        notes: 'Study plan',
      );

      final json = skill.toJson();
      final fromJson = LearningTrackedSkill.fromJson(json);

      expect(fromJson, equals(skill));
    });
  });

  group('LearningGrowthSummary', () {
    test('calculates correct summary counts and sorts recent evidence', () {
      final ev1 = LearningGrowthEvidence(
        id: 'ev_1',
        accountId: 'acc',
        learningProfileId: 'prof',
        kind: LearningEvidenceKind.verified,
        title: 'Old Verified',
        description: 'Desc',
        recordedAt: DateTime(2026, 11, 20),
      );
      final ev2 = LearningGrowthEvidence(
        id: 'ev_2',
        accountId: 'acc',
        learningProfileId: 'prof',
        kind: LearningEvidenceKind.selfReported,
        title: 'Mid Self-Report',
        description: 'Desc',
        recordedAt: DateTime(2026, 11, 22),
      );
      final ev3 = LearningGrowthEvidence(
        id: 'ev_3',
        accountId: 'acc',
        learningProfileId: 'prof',
        kind: LearningEvidenceKind.selfReported,
        title: 'Newest Self-Report',
        description: 'Desc',
        recordedAt: DateTime(2026, 11, 25),
      );

      final sk1 = LearningTrackedSkill(
        id: 'sk_1',
        name: 'Skill 1',
        category: 'Cat',
        sufficiencyStatus: EvidenceSufficiencyStatus.verifiedSource,
      );
      final sk2 = LearningTrackedSkill(
        id: 'sk_2',
        name: 'Skill 2',
        category: 'Cat',
        sufficiencyStatus: EvidenceSufficiencyStatus.selfReportedOnly,
      );
      final sk3 = LearningTrackedSkill(
        id: 'sk_3',
        name: 'Skill 3',
        category: 'Cat',
        sufficiencyStatus: EvidenceSufficiencyStatus.insufficientEvidence,
      );

      final summary = LearningGrowthSummary.fromData(
        evidence: [ev1, ev2, ev3],
        skills: [sk1, sk2, sk3],
      );

      expect(summary.totalEvidenceCount, 3);
      expect(summary.verifiedEvidenceCount, 1);
      expect(summary.selfReportedEvidenceCount, 2);
      expect(summary.trackedSkillsCount, 3);
      expect(summary.verifiedSkillsCount, 1);
      expect(summary.selfReportedOnlySkillsCount, 1);
      expect(summary.insufficientEvidenceSkillsCount, 1);

      // Verify sorted recent (ev3, ev2, ev1)
      expect(summary.recentEvidence.length, 3);
      expect(summary.recentEvidence[0].id, 'ev_3');
      expect(summary.recentEvidence[1].id, 'ev_2');
      expect(summary.recentEvidence[2].id, 'ev_1');

      // Redacted toString
      expect(
        summary.toString(),
        'LearningGrowthSummary [private growth summary metrics omitted]',
      );

      // JSON roundtrip
      final json = summary.toJson();
      final roundtrip = LearningGrowthSummary.fromJson(json);
      expect(roundtrip.totalEvidenceCount, summary.totalEvidenceCount);
      expect(roundtrip.verifiedEvidenceCount, summary.verifiedEvidenceCount);
      expect(roundtrip.selfReportedEvidenceCount,
          summary.selfReportedEvidenceCount);
      expect(roundtrip.trackedSkillsCount, summary.trackedSkillsCount);
      expect(roundtrip.recentEvidence.length, 3);
    });
  });
}
