import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/profile/domain/entities/learning_profile.dart';

void main() {
  group('LearningProfile Domain Entity Tests', () {
    test('1. Creation of a valid Learning-scoped profile model', () {
      final profile = LearningProfile(
        profileId: 'lp_1001',
        accountId: 'acc_5001',
        displayName: 'Thusa Learner',
        bio: 'Aspiring Flutter and Mobile UI engineer.',
        skillsToLearn: ['Flutter', 'Clean Architecture'],
        skillsToShare: ['UI Design', 'Figma'],
        learningGoals: ['Complete Phase 10 implementation'],
      );

      expect(profile.profileId, 'lp_1001');
      expect(profile.accountId, 'acc_5001');
      expect(profile.module, 'learning');
      expect(profile.displayName, 'Thusa Learner');
      expect(profile.bio, 'Aspiring Flutter and Mobile UI engineer.');
      expect(profile.skillsToLearn, ['Flutter', 'Clean Architecture']);
      expect(profile.skillsToShare, ['UI Design', 'Figma']);
      expect(profile.learningGoals, ['Complete Phase 10 implementation']);
      expect(profile.isActivated, isFalse);
    });

    test('2. Preservation of assigned module-profile identity', () {
      const assignedProfileId = 'lp_custom_9999_xyz';
      const assignedAccountId = 'acc_m2_authoritative_123';

      final profile = LearningProfile(
        profileId: assignedProfileId,
        accountId: assignedAccountId,
        displayName: 'Learner One',
      );

      expect(profile.profileId, assignedProfileId);
      expect(profile.accountId, assignedAccountId);
    });

    test('3. Rejection of structurally invalid identity references', () {
      // Empty profileId
      expect(
        () => LearningProfile(
          profileId: '',
          accountId: 'acc_1',
          displayName: 'Test',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Whitespace-only profileId
      expect(
        () => LearningProfile(
          profileId: '   ',
          accountId: 'acc_1',
          displayName: 'Test',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Empty accountId
      expect(
        () => LearningProfile(
          profileId: 'lp_1',
          accountId: '',
          displayName: 'Test',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Whitespace-only accountId
      expect(
        () => LearningProfile(
          profileId: 'lp_1',
          accountId: '   ',
          displayName: 'Test',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('4. Rejection of non-Learning module scope', () {
      // Reject social module scope
      expect(
        () => LearningProfile(
          profileId: 'lp_1',
          accountId: 'acc_1',
          module: 'social',
          displayName: 'Social User',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Reject hobbies module scope
      expect(
        () => LearningProfile(
          profileId: 'lp_1',
          accountId: 'acc_1',
          module: 'hobbies',
          displayName: 'Hobbies User',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Reject arbitrary unknown module scope
      expect(
        () => LearningProfile(
          profileId: 'lp_1',
          accountId: 'acc_1',
          module: 'finance',
          displayName: 'Finance User',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('5. Defensive collection immutability', () {
      final inputSkillsToLearn = ['Dart', 'Flutter'];
      final inputSkillsToShare = ['Python'];
      final inputGoals = ['Master testing'];

      final profile = LearningProfile(
        profileId: 'lp_1',
        accountId: 'acc_1',
        displayName: 'Test Learner',
        skillsToLearn: inputSkillsToLearn,
        skillsToShare: inputSkillsToShare,
        learningGoals: inputGoals,
      );

      // Mutating input list after construction must not affect the entity
      inputSkillsToLearn.add('JavaScript');
      expect(profile.skillsToLearn, ['Dart', 'Flutter']);

      // Attempting to mutate entity's collections must throw UnsupportedError
      expect(
        () => (profile.skillsToLearn as dynamic).add('New Skill'),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => (profile.skillsToShare as dynamic).add('New Skill'),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => (profile.learningGoals as dynamic).add('New Goal'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('6. No cross-module data copying', () {
      final profile = LearningProfile(
        profileId: 'lp_100',
        accountId: 'acc_100',
        displayName: 'Isolated Learner',
      );

      expect(profile.module, 'learning');
      expect(profile.module, isNot('social'));
      expect(profile.module, isNot('hobbies'));
    });

    test('7. Stable identity during profile snapshot changes', () {
      final original = LearningProfile(
        profileId: 'lp_stable_1',
        accountId: 'acc_stable_1',
        displayName: 'Original Name',
        bio: 'Original bio',
        skillsToLearn: ['Dart'],
      );

      final updated = original.copyWith(
        displayName: 'Updated Name',
        bio: 'Updated bio',
        skillsToLearn: ['Dart', 'Flutter'],
      );

      // Profile and account identity are preserved
      expect(updated.profileId, original.profileId);
      expect(updated.accountId, original.accountId);
      expect(updated.module, original.module);

      // Presentation fields reflect updates
      expect(updated.displayName, 'Updated Name');
      expect(updated.bio, 'Updated bio');
      expect(updated.skillsToLearn, ['Dart', 'Flutter']);

      // Equality check confirms two distinct states
      expect(updated, isNot(equals(original)));
    });

    test('8. Unicode data preservation', () {
      const unicodeName = 'துசாந்த் (Thusa) 🚀';
      const unicodeBio = 'கற்றல் & வளர்ச்சி — Learning with Freude ü ö ä';
      const unicodeSkills = ['டார்ட்', 'Machine Learning 🤖', 'Español'];

      final profile = LearningProfile(
        profileId: 'lp_unicode_1',
        accountId: 'acc_unicode_1',
        displayName: unicodeName,
        bio: unicodeBio,
        skillsToLearn: unicodeSkills,
      );

      expect(profile.displayName, unicodeName);
      expect(profile.bio, unicodeBio);
      expect(profile.skillsToLearn, unicodeSkills);
    });

    test('9. Clear separation between profile data and activation authority',
        () {
      final profile = LearningProfile(
        profileId: 'lp_1',
        accountId: 'acc_1',
        displayName: 'Learner',
      );

      // Must fail closed (default not activated)
      expect(profile.isActivated, isFalse);

      final activatedProfile = profile.copyWith(isActivated: true);
      expect(activatedProfile.isActivated, isTrue);
    });

    test('10. No invented display-name uniqueness or skill-catalogue decisions',
        () {
      // Any valid string representing user-defined skills is accepted without hardcoded whitelist
      final customSkills = [
        'Quantum Computing 101',
        'Custom Ancient Greek Philosophy',
        'Unconventional Welding',
      ];

      final profile = LearningProfile(
        profileId: 'lp_custom_1',
        accountId: 'acc_custom_1',
        displayName: 'Philosopher',
        skillsToLearn: customSkills,
      );

      expect(profile.skillsToLearn, customSkills);
    });
  });
}
