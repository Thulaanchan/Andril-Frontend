import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/profile/domain/entities/learning_preferences.dart';
import 'package:andril_mobile/features/learning/profile/domain/entities/learning_profile.dart';

void main() {
  group('LearningPreferences Domain Entity Tests', () {
    test('1. Default preferences initialization (Q07_LUC-03 approved)', () {
      const prefs = LearningPreferences();

      expect(prefs.languages, ['English']);
      expect(prefs.learningStyles, isEmpty);
      expect(prefs.availability, isNull);
      expect(prefs.notifications, isEmpty);
    });

    test('2. Defensive immutability of preferences collections', () {
      final inputLangs = ['English', 'Tamil'];
      final inputStyles = ['Video Learning'];
      final inputNotifs = {'Connection requests': true};

      final prefs = const LearningPreferences().copyWith(
        languages: inputLangs,
        learningStyles: inputStyles,
        availability: 'Morning (6 AM – 12 PM)',
        notifications: inputNotifs,
      );

      // Mutating input source does not mutate entity
      inputLangs.add('French');
      expect(prefs.languages, ['English', 'Tamil']);

      // Mutating entity collections directly throws UnsupportedError
      expect(
        () => (prefs.languages as dynamic).add('Sinhala'),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => (prefs.learningStyles as dynamic).add('Audio / Podcasts'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('3. Value equality and hashCode', () {
      const a = LearningPreferences(
        languages: ['English', 'Tamil'],
        learningStyles: ['Video Learning'],
        availability: 'Flexible (Any time)',
        notifications: {'Connection requests': true},
      );
      const b = LearningPreferences(
        languages: ['English', 'Tamil'],
        learningStyles: ['Video Learning'],
        availability: 'Flexible (Any time)',
        notifications: {'Connection requests': true},
      );
      final c = a.copyWith(availability: 'Evening (6 PM – 10 PM)');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('4. copyWith preserves unchanged values', () {
      final original = LearningPreferences.syntheticSample();
      final updated = original.copyWith(
        availability: 'Late Night (10 PM – 2 AM)',
      );

      expect(updated.languages, original.languages);
      expect(updated.learningStyles, original.learningStyles);
      expect(updated.notifications, original.notifications);
      expect(updated.availability, 'Late Night (10 PM – 2 AM)');
    });

    test('5. Confidentiality: toString redacts private preferences', () {
      final prefs = LearningPreferences.syntheticSample();

      expect(
        prefs.toString(),
        'LearningPreferences [private preferences omitted]',
      );
      expect(prefs.toString(), isNot(contains('English')));
      expect(prefs.toString(), isNot(contains('Tamil')));
      expect(prefs.toString(), isNot(contains('Video Learning')));
    });

    test('6. empty and syntheticSample factory methods', () {
      final empty = LearningPreferences.empty();
      expect(empty.languages, isEmpty);
      expect(empty.learningStyles, isEmpty);
      expect(empty.availability, isNull);
      expect(empty.notifications, isEmpty);

      final sample = LearningPreferences.syntheticSample();
      expect(sample.languages, contains('English'));
      expect(sample.learningStyles, isNotEmpty);
      expect(sample.availability, isNotNull);
      expect(sample.notifications, isNotEmpty);
    });
  });

  group('LearningProfile Entity Extensions & Disconnected Notice Tests', () {
    test('1. LearningProfile.empty factory initialization', () {
      final profile = LearningProfile.empty(
        ownerLearningProfileId: 'lp_emp_001',
        accountId: 'acc_001',
        displayName: 'New Learner',
      );

      expect(profile.profileId, 'lp_emp_001');
      expect(profile.accountId, 'acc_001');
      expect(profile.module, 'learning');
      expect(profile.displayName, 'New Learner');
      expect(profile.skillsToLearn, isEmpty);
      expect(profile.skillsToShare, isEmpty);
      expect(profile.learningGoals, isEmpty);
      expect(profile.preferences.languages, isEmpty);
    });

    test('2. LearningProfile.syntheticSample factory initialization', () {
      final profile = LearningProfile.syntheticSample(
        ownerLearningProfileId: 'lp_syn_100',
      );

      expect(profile.profileId, 'lp_syn_100');
      expect(profile.module, 'learning');
      expect(profile.displayName, 'Thusa Learner');
      expect(profile.skillsToLearn, isNotEmpty);
      expect(profile.skillsToShare, isNotEmpty);
      expect(profile.learningGoals, isNotEmpty);
      expect(profile.preferences.languages, contains('English'));
    });

    test('3. Disconnected notice constant verification', () {
      expect(
        LearningProfile.disconnectedNotice,
        'Remote repository persistence contract pending. Profile retained locally.',
      );
    });

    test('4. LearningProfile copyWith with preferences', () {
      final original = LearningProfile.syntheticSample(
        ownerLearningProfileId: 'lp_test_1',
      );
      final newPrefs = original.preferences.copyWith(
        availability: 'Morning (6 AM – 12 PM)',
      );

      final updated = original.copyWith(preferences: newPrefs);
      expect(updated.preferences.availability, 'Morning (6 AM – 12 PM)');
      expect(updated.profileId, original.profileId);
      expect(updated.accountId, original.accountId);
    });
  });
}
