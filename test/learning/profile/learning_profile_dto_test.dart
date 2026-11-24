import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/profile/data/models/learning_profile_dto.dart';
import 'package:andril_mobile/features/learning/profile/domain/entities/learning_profile.dart';

void main() {
  group('LearningProfileDto Serialization & Mapping Tests', () {
    final validJson = <String, dynamic>{
      'profile_id': 'lp_dto_100',
      'account_id': 'acc_dto_200',
      'module': 'learning',
      'display_name': 'DTO Learner',
      'bio': 'Learning Flutter architecture',
      'avatar_url': 'https://example.com/avatar.png',
      'skills_to_learn': ['Flutter', 'Dart'],
      'skills_to_share': ['Graphic Design'],
      'learning_goals': ['Pass Phase 10 verification'],
      'is_activated': true,
    };

    test('1. Valid supported DTO mapping to and from domain entity', () {
      final dto = LearningProfileDto.fromJson(validJson);
      final entity = dto.toDomain();

      expect(entity.profileId, 'lp_dto_100');
      expect(entity.accountId, 'acc_dto_200');
      expect(entity.module, 'learning');
      expect(entity.displayName, 'DTO Learner');
      expect(entity.bio, 'Learning Flutter architecture');
      expect(entity.avatarUrl, 'https://example.com/avatar.png');
      expect(entity.skillsToLearn, ['Flutter', 'Dart']);
      expect(entity.skillsToShare, ['Graphic Design']);
      expect(entity.learningGoals, ['Pass Phase 10 verification']);
      expect(entity.isActivated, isTrue);

      final roundTripDto = LearningProfileDto.fromDomain(entity);
      expect(roundTripDto, equals(dto));
    });

    test('2. Round-trip preservation for all locally supported fields', () {
      final dto = LearningProfileDto.fromJson(validJson);
      final serialized = dto.toJson();
      final rehydrated = LearningProfileDto.fromJson(serialized);

      expect(rehydrated, equals(dto));
      expect(rehydrated.profileId, dto.profileId);
      expect(rehydrated.accountId, dto.accountId);
      expect(rehydrated.module, dto.module);
      expect(rehydrated.displayName, dto.displayName);
      expect(rehydrated.bio, dto.bio);
      expect(rehydrated.avatarUrl, dto.avatarUrl);
      expect(rehydrated.skillsToLearn, dto.skillsToLearn);
      expect(rehydrated.skillsToShare, dto.skillsToShare);
      expect(rehydrated.learningGoals, dto.learningGoals);
      expect(rehydrated.isActivated, dto.isActivated);
    });

    test('3. Missing required identity data throws FormatException', () {
      // Missing profile_id
      final noProfileId = Map<String, dynamic>.from(validJson)
        ..remove('profile_id');
      expect(
        () => LearningProfileDto.fromJson(noProfileId),
        throwsA(isA<FormatException>()),
      );

      // Missing account_id
      final noAccountId = Map<String, dynamic>.from(validJson)
        ..remove('account_id');
      expect(
        () => LearningProfileDto.fromJson(noAccountId),
        throwsA(isA<FormatException>()),
      );

      // Empty profile_id
      final emptyProfileId = Map<String, dynamic>.from(validJson)
        ..['profile_id'] = '   ';
      expect(
        () => LearningProfileDto.fromJson(emptyProfileId),
        throwsA(isA<FormatException>()),
      );
    });

    test('4. Invalid field types throw FormatException', () {
      // Non-string display_name
      final invalidName = Map<String, dynamic>.from(validJson)
        ..['display_name'] = 12345;
      expect(
        () => LearningProfileDto.fromJson(invalidName),
        throwsA(isA<FormatException>()),
      );

      // Non-list skills_to_learn
      final invalidSkills = Map<String, dynamic>.from(validJson)
        ..['skills_to_learn'] = 'Flutter';
      expect(
        () => LearningProfileDto.fromJson(invalidSkills),
        throwsA(isA<FormatException>()),
      );

      // Non-boolean is_activated
      final invalidActivated = Map<String, dynamic>.from(validJson)
        ..['is_activated'] = 'true';
      expect(
        () => LearningProfileDto.fromJson(invalidActivated),
        throwsA(isA<FormatException>()),
      );
    });

    test('5. Invalid module scope throws FormatException', () {
      final socialJson = Map<String, dynamic>.from(validJson)
        ..['module'] = 'social';
      expect(
        () => LearningProfileDto.fromJson(socialJson),
        throwsA(isA<FormatException>()),
      );

      final hobbiesJson = Map<String, dynamic>.from(validJson)
        ..['module'] = 'hobbies';
      expect(
        () => LearningProfileDto.fromJson(hobbiesJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('6. Optional field handling with nulls and omitted collections', () {
      final minimalJson = <String, dynamic>{
        'profile_id': 'lp_min_1',
        'account_id': 'acc_min_1',
        'module': 'learning',
        'display_name': 'Minimalist',
      };

      final dto = LearningProfileDto.fromJson(minimalJson);

      expect(dto.bio, isNull);
      expect(dto.avatarUrl, isNull);
      expect(dto.skillsToLearn, isEmpty);
      expect(dto.skillsToShare, isEmpty);
      expect(dto.learningGoals, isEmpty);
      expect(dto.isActivated, isFalse);

      final entity = dto.toDomain();
      expect(entity.bio, isNull);
      expect(entity.skillsToLearn, isEmpty);
      expect(entity.isActivated, isFalse);
    });

    test('7. Unicode preservation across serialization and deserialization',
        () {
      final unicodeJson = <String, dynamic>{
        'profile_id': 'lp_u_1',
        'account_id': 'acc_u_1',
        'module': 'learning',
        'display_name': 'விழி & திலீபன் ⭐',
        'bio': 'ஆழ்ந்த கற்றல் பாதை — Depth-first path',
        'skills_to_learn': ['இயற்கை மொழி செயலாக்கம் (NLP)'],
        'skills_to_share': ['தமிழ் இலக்கியம்'],
        'learning_goals': ['முழுமைப்படுத்தல் ✨'],
        'is_activated': false,
      };

      final dto = LearningProfileDto.fromJson(unicodeJson);
      final jsonOutput = dto.toJson();
      final roundTrip = LearningProfileDto.fromJson(jsonOutput);

      expect(roundTrip.displayName, 'விழி & திலீபன் ⭐');
      expect(roundTrip.bio, 'ஆழ்ந்த கற்றல் பாதை — Depth-first path');
      expect(roundTrip.skillsToLearn.first, 'இயற்கை மொழி செயலாக்கம் (NLP)');
    });

    test('8. Prevention of accidental cross-module field injection', () {
      final foreignJson = Map<String, dynamic>.from(validJson)
        ..['moodtone_score'] = 'happy'
        ..['hobbies_flight_points'] = 450
        ..['social_matching_zone'] = 'VIP';

      final dto = LearningProfileDto.fromJson(foreignJson);
      final entity = dto.toDomain();

      // Entity remains strictly bounded to Learning
      expect(entity.module, LearningProfile.moduleScope);
      expect(entity.module, 'learning');
    });

    test('9. Deterministic handling of malformed input', () {
      final nonStringSkillElement = Map<String, dynamic>.from(validJson)
        ..['skills_to_learn'] = ['Valid Skill', 999];

      expect(
        () => LearningProfileDto.fromJson(nonStringSkillElement),
        throwsA(isA<FormatException>()),
      );
    });

    test('10. No exposure of private identity data through default diagnostics',
        () {
      try {
        final invalidJson = Map<String, dynamic>.from(validJson)
          ..['module'] = 'wrong_module';
        LearningProfileDto.fromJson(invalidJson);
        fail('Should have thrown FormatException');
      } on FormatException catch (e) {
        // Error message must explain structural reason without dumping private tokens or IDs
        expect(e.message, contains('Invalid module scope'));
        expect(e.message, isNot(contains('lp_dto_100')));
        expect(e.message, isNot(contains('acc_dto_200')));
      }
    });
  });
}
