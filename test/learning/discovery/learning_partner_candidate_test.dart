import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/discovery/domain/entities/learning_partner_candidate.dart';

void main() {
  group('LearningPartnerCandidate Domain Invariants & Serialization', () {
    test('constructs valid immutable LearningPartnerCandidate', () {
      final candidate = LearningPartnerCandidate(
        id: 'lp_cand_01',
        displayName: 'Amara Fernando',
        skillsToShare: const ['Flutter', 'Dart'],
        skillsToLearn: const ['Figma', 'UI/UX'],
        learningGoals: const ['Master state management'],
        proficiencyLevel: 'Advanced',
        languages: const ['English', 'Tamil'],
        availability: 'Flexible (Any time)',
        bio: 'Passionate mobile developer.',
        isActive: true,
      );

      expect(candidate.id, equals('lp_cand_01'));
      expect(candidate.displayName, equals('Amara Fernando'));
      expect(candidate.module, equals('learning'));
      expect(candidate.skillsToShare, equals(['Flutter', 'Dart']));
      expect(candidate.skillsToLearn, equals(['Figma', 'UI/UX']));
      expect(candidate.learningGoals, equals(['Master state management']));
      expect(candidate.proficiencyLevel, equals('Advanced'));
      expect(candidate.languages, equals(['English', 'Tamil']));
      expect(candidate.availability, equals('Flexible (Any time)'));
      expect(candidate.bio, equals('Passionate mobile developer.'));
      expect(candidate.isActive, isTrue);
    });

    test('enforces defensive immutability on collection fields', () {
      final mutableSkills = ['Flutter', 'Dart'];
      final candidate = LearningPartnerCandidate(
        id: 'lp_cand_02',
        displayName: 'Kavinda Perera',
        skillsToShare: mutableSkills,
      );

      // Mutating source list after construction does not mutate candidate
      mutableSkills.add('Java');
      expect(candidate.skillsToShare, equals(['Flutter', 'Dart']));

      // Attempting to modify candidate's collection throws UnsupportedError
      expect(() => candidate.skillsToShare.add('Rust'), throwsUnsupportedError);
      expect(() => candidate.skillsToLearn.add('Go'), throwsUnsupportedError);
      expect(() => candidate.learningGoals.add('Goal'), throwsUnsupportedError);
      expect(() => candidate.languages.add('French'), throwsUnsupportedError);
    });

    test('rejects empty or whitespace-only candidate ID', () {
      expect(
        () => LearningPartnerCandidate(id: '', displayName: 'Test'),
        throwsArgumentError,
      );
      expect(
        () => LearningPartnerCandidate(id: '   ', displayName: 'Test'),
        throwsArgumentError,
      );
    });

    test('rejects non-learning module identifier', () {
      expect(
        () => LearningPartnerCandidate(
          id: 'lp_cand_03',
          displayName: 'Test',
          module: 'social',
        ),
        throwsArgumentError,
      );
    });

    test('supports JSON serialization and deserialization roundtrip', () {
      final original = LearningPartnerCandidate(
        id: 'lp_cand_04',
        displayName: 'Nimali Silva',
        skillsToShare: const ['Python', 'FastAPI'],
        skillsToLearn: const ['Machine Learning'],
        learningGoals: const ['Build AI models'],
        proficiencyLevel: 'Intermediate',
        languages: const ['English', 'Tamil', 'Tanglish'],
        availability: 'Morning (6 AM – 12 PM)',
        bio: 'Data enthusiast.',
        avatarUrl: 'https://example.com/avatar.png',
        isActive: true,
      );

      final json = original.toJson();
      final reconstructed = LearningPartnerCandidate.fromJson(json);

      expect(reconstructed, equals(original));
      expect(reconstructed.id, equals('lp_cand_04'));
      expect(reconstructed.displayName, equals('Nimali Silva'));
      expect(reconstructed.skillsToShare, equals(['Python', 'FastAPI']));
      expect(reconstructed.skillsToLearn, equals(['Machine Learning']));
      expect(reconstructed.learningGoals, equals(['Build AI models']));
      expect(reconstructed.proficiencyLevel, equals('Intermediate'));
      expect(reconstructed.languages, equals(['English', 'Tamil', 'Tanglish']));
      expect(reconstructed.availability, equals('Morning (6 AM – 12 PM)'));
      expect(reconstructed.bio, equals('Data enthusiast.'));
      expect(reconstructed.avatarUrl, equals('https://example.com/avatar.png'));
      expect(reconstructed.isActive, isTrue);
    });

    test('copyWith updates specified properties while preserving immutability',
        () {
      final candidate = LearningPartnerCandidate(
        id: 'lp_cand_05',
        displayName: 'Original Name',
        skillsToShare: const ['Dart'],
      );

      final updated = candidate.copyWith(
        displayName: 'Updated Name',
        proficiencyLevel: 'Advanced',
      );

      expect(updated.id, equals('lp_cand_05'));
      expect(updated.displayName, equals('Updated Name'));
      expect(updated.proficiencyLevel, equals('Advanced'));
      expect(updated.skillsToShare, equals(['Dart']));
      expect(updated.module, equals('learning'));
    });

    test('evaluates equality and hashCode consistently', () {
      final a = LearningPartnerCandidate(
        id: 'lp_cand_06',
        displayName: 'Candidate A',
        skillsToShare: const ['Flutter'],
      );
      final b = LearningPartnerCandidate(
        id: 'lp_cand_06',
        displayName: 'Candidate A',
        skillsToShare: const ['Flutter'],
      );
      final c = LearningPartnerCandidate(
        id: 'lp_cand_07',
        displayName: 'Candidate C',
        skillsToShare: const ['Dart'],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('redacts toString to prevent confidential learner data leakage', () {
      final candidate = LearningPartnerCandidate(
        id: 'lp_cand_secret',
        displayName: 'Confidential Learner',
        bio: 'Highly private bio information',
        learningGoals: const ['Confidential goal'],
      );

      final str = candidate.toString();
      expect(str, contains('LearningPartnerCandidate'));
      expect(str, contains('id: lp_cand_secret'));
      expect(str, isNot(contains('Highly private bio information')));
      expect(str, isNot(contains('Confidential goal')));
    });
  });
}
