import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';

void main() {
  group('SocialCandidate Domain Model Tests (M5-FE-S09-DOM-QA-01)', () {
    test('constructs valid candidate with all approved fields', () {
      final candidate = SocialCandidate(
        id: 'candidate_001',
        displayName: 'Samadhi P.',
        age: 24,
        approximateDistanceKm: 12,
        sharedLanguages: const ['English', 'Sinhala'],
        sharedConnectionGoals: const ['Friendship', 'Networking'],
        biography: 'Exploring local photography and design.',
        interests: const {'Photography', 'UI Design'},
        photoUrls: const ['https://cdn.andril.app/photos/p1.jpg'],
        locationName: 'Colombo',
        isVerified: true,
      );

      expect(candidate.id, 'candidate_001');
      expect(candidate.displayName, 'Samadhi P.');
      expect(candidate.age, 24);
      expect(candidate.approximateDistanceKm, 12);
      expect(candidate.sharedLanguages, ['English', 'Sinhala']);
      expect(candidate.sharedConnectionGoals, ['Friendship', 'Networking']);
      expect(candidate.biography, 'Exploring local photography and design.');
      expect(candidate.interests, {'Photography', 'UI Design'});
      expect(candidate.photoUrls, ['https://cdn.andril.app/photos/p1.jpg']);
      expect(candidate.primaryPhotoUrl, 'https://cdn.andril.app/photos/p1.jpg');
      expect(candidate.locationName, 'Colombo');
      expect(candidate.isVerified, isTrue);
    });

    test('handles optional fields safely with default fallbacks', () {
      final candidate = SocialCandidate(
        id: 'candidate_minimal',
        displayName: 'Kavindu',
        age: 27,
      );

      expect(candidate.id, 'candidate_minimal');
      expect(candidate.displayName, 'Kavindu');
      expect(candidate.age, 27);
      expect(candidate.approximateDistanceKm, isNull);
      expect(candidate.sharedLanguages, isEmpty);
      expect(candidate.sharedConnectionGoals, isEmpty);
      expect(candidate.biography, isNull);
      expect(candidate.interests, isEmpty);
      expect(candidate.photoUrls, isEmpty);
      expect(candidate.primaryPhotoUrl, isNull);
      expect(candidate.locationName, isNull);
      expect(candidate.isVerified, isFalse);
    });

    test('enforces defensive copying of input collections', () {
      final inputLanguages = ['English', 'Tamil'];
      final inputGoals = ['Networking'];
      final inputInterests = {'Music', 'Coding'};
      final inputPhotos = ['https://cdn.andril.app/p1.jpg'];

      final candidate = SocialCandidate(
        id: 'defensive_test',
        displayName: 'Aarav',
        age: 22,
        sharedLanguages: inputLanguages,
        sharedConnectionGoals: inputGoals,
        interests: inputInterests,
        photoUrls: inputPhotos,
      );

      // Mutate original caller collections
      inputLanguages.add('Sinhala');
      inputGoals.add('Friendship');
      inputInterests.add('Hiking');
      inputPhotos.add('https://cdn.andril.app/p2.jpg');

      // Candidate collections must remain unchanged
      expect(candidate.sharedLanguages, ['English', 'Tamil']);
      expect(candidate.sharedConnectionGoals, ['Networking']);
      expect(candidate.interests, {'Music', 'Coding'});
      expect(candidate.photoUrls, ['https://cdn.andril.app/p1.jpg']);
    });

    test('enforces runtime unmodifiability on exposed collections', () {
      final candidate = SocialCandidate(
        id: 'immutable_test',
        displayName: 'Nethmi',
        age: 25,
        sharedLanguages: const ['English'],
        sharedConnectionGoals: const ['Friendship'],
        interests: const {'Art'},
        photoUrls: const ['https://cdn.andril.app/p1.jpg'],
      );

      expect(() => candidate.sharedLanguages.add('Tamil'), throwsUnsupportedError);
      expect(() => candidate.sharedConnectionGoals.add('Networking'), throwsUnsupportedError);
      expect(() => candidate.interests.add('Design'), throwsUnsupportedError);
      expect(() => candidate.photoUrls.add('https://cdn.andril.app/p2.jpg'), throwsUnsupportedError);
    });

    test('implements order-independent set equality and hashing', () {
      final candidateA = SocialCandidate(
        id: 'equal_test',
        displayName: 'Rohan',
        age: 26,
        interests: {'Reading', 'Coffee', 'Running'},
      );

      final candidateB = SocialCandidate(
        id: 'equal_test',
        displayName: 'Rohan',
        age: 26,
        interests: {'Running', 'Reading', 'Coffee'}, // different insertion order
      );

      expect(candidateA, equals(candidateB));
      expect(candidateA.hashCode, equals(candidateB.hashCode));
    });

    test('serializes to and deserializes from backend JSON accurately', () {
      final jsonPayload = {
        'candidateProfileId': 'guid_555',
        'displayName': 'Thilini M.',
        'age': 28,
        'approximateDistanceKm': 8,
        'sharedLanguages': ['Sinhala', 'English'],
        'sharedConnectionGoals': ['Serious Relationship'],
        'biography': 'Passionate about wildlife conservation.',
        'interests': ['Wildlife', 'Hiking'],
        'photoUrls': ['https://cdn.andril.app/p_thilini.jpg'],
        'locationName': 'Kandy',
        'isVerified': true,
      };

      final candidate = SocialCandidate.fromJson(jsonPayload);
      expect(candidate.id, 'guid_555');
      expect(candidate.displayName, 'Thilini M.');
      expect(candidate.age, 28);
      expect(candidate.approximateDistanceKm, 8);
      expect(candidate.sharedLanguages, ['Sinhala', 'English']);
      expect(candidate.sharedConnectionGoals, ['Serious Relationship']);
      expect(candidate.biography, 'Passionate about wildlife conservation.');
      expect(candidate.interests, {'Wildlife', 'Hiking'});
      expect(candidate.photoUrls, ['https://cdn.andril.app/p_thilini.jpg']);
      expect(candidate.locationName, 'Kandy');
      expect(candidate.isVerified, isTrue);

      final serialized = candidate.toJson();
      expect(serialized['candidateProfileId'], 'guid_555');
      expect(serialized['displayName'], 'Thilini M.');
      expect(serialized['age'], 28);
      expect(serialized['approximateDistanceKm'], 8);
      expect(serialized['isVerified'], isTrue);
    });

    test('copyWith produces an updated immutable clone preserving unchanged fields', () {
      final original = SocialCandidate(
        id: 'copy_test',
        displayName: 'Nuwan',
        age: 30,
        approximateDistanceKm: 15,
        locationName: 'Galle',
      );

      final updated = original.copyWith(
        approximateDistanceKm: 25,
        locationName: 'Matara',
      );

      expect(updated.id, 'copy_test');
      expect(updated.displayName, 'Nuwan');
      expect(updated.age, 30);
      expect(updated.approximateDistanceKm, 25);
      expect(updated.locationName, 'Matara');
      expect(original.approximateDistanceKm, 15);
    });

    test('sanitized toString contains presentation diagnostics without cross-module leakage', () {
      final candidate = SocialCandidate(
        id: 'diag_test',
        displayName: 'Amara',
        age: 23,
        approximateDistanceKm: 5,
        isVerified: true,
      );

      final str = candidate.toString();
      expect(str, contains('SocialCandidate'));
      expect(str, contains('Amara'));
      expect(str, contains('23'));
      expect(str, contains('5km'));
      expect(str, isNot(contains('password')));
      expect(str, isNot(contains('account')));
      expect(str, isNot(contains('scoring')));
      expect(str, isNot(contains('gps')));
    });
  });
}
