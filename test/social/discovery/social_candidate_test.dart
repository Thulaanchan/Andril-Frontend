import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';

void main() {
  group('SocialCandidate Domain Model Tests (Task 107 & 108)', () {
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

    test('handles optional fields safely when valid', () {
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

    test('defensive collection immutability', () {
      final rawLanguages = ['English', 'Tamil'];
      final rawInterests = {'Music', 'Reading'};
      final rawPhotos = ['https://cdn.andril.app/p1.jpg'];

      final candidate = SocialCandidate(
        id: 'c_immutable',
        displayName: 'Ananthan',
        age: 22,
        sharedLanguages: rawLanguages,
        interests: rawInterests,
        photoUrls: rawPhotos,
      );

      expect(() => (candidate.sharedLanguages as dynamic).add('French'), throwsA(isA<UnsupportedError>()));
      expect(() => (candidate.interests as dynamic).add('Gaming'), throwsA(isA<UnsupportedError>()));
      expect(() => (candidate.photoUrls as dynamic).add('p2.jpg'), throwsA(isA<UnsupportedError>()));
    });

    test('parses valid JSON with approved DTO fields', () {
      final json = {
        'candidateProfileId': 'c_json_01',
        'displayName': 'Dilshan',
        'age': 25,
        'approximateDistanceKm': 8,
        'sharedLanguages': ['English', 'Sinhala'],
        'sharedConnectionGoals': ['Mentorship'],
        'biography': 'Software engineering enthusiast.',
        'interests': ['Tech', 'Hiking'],
        'photoUrls': ['https://cdn.andril.app/dilshan.jpg'],
        'locationName': 'Kandy',
        'isVerified': true,
      };

      final candidate = SocialCandidate.fromJson(json);
      expect(candidate.id, 'c_json_01');
      expect(candidate.displayName, 'Dilshan');
      expect(candidate.age, 25);
      expect(candidate.approximateDistanceKm, 8);
      expect(candidate.sharedLanguages, ['English', 'Sinhala']);
      expect(candidate.sharedConnectionGoals, ['Mentorship']);
      expect(candidate.biography, 'Software engineering enthusiast.');
      expect(candidate.interests, {'Tech', 'Hiking'});
      expect(candidate.primaryPhotoUrl, 'https://cdn.andril.app/dilshan.jpg');
      expect(candidate.locationName, 'Kandy');
      expect(candidate.isVerified, isTrue);
    });

    test('serializes to JSON accurately', () {
      final candidate = SocialCandidate(
        id: 'c_ser_01',
        displayName: 'Anuki',
        age: 21,
        approximateDistanceKm: 5,
        sharedLanguages: const ['English'],
        sharedConnectionGoals: const ['Friendship'],
        biography: 'Bookworm & coffee lover',
        interests: const {'Reading', 'Coffee'},
        photoUrls: const ['https://cdn.andril.app/anuki.jpg'],
        locationName: 'Galle',
        isVerified: true,
      );

      final json = candidate.toJson();
      expect(json['candidateProfileId'], 'c_ser_01');
      expect(json['displayName'], 'Anuki');
      expect(json['age'], 21);
      expect(json['approximateDistanceKm'], 5);
      expect(json['sharedLanguages'], ['English']);
      expect(json['sharedConnectionGoals'], ['Friendship']);
      expect(json['biography'], 'Bookworm & coffee lover');
      expect(json['interests'], ['Reading', 'Coffee']);
      expect(json['photoUrls'], ['https://cdn.andril.app/anuki.jpg']);
      expect(json['locationName'], 'Galle');
      expect(json['isVerified'], isTrue);
    });

    test('rejects missing or empty candidate ID in JSON', () {
      expect(
        () => SocialCandidate.fromJson({'displayName': 'Test', 'age': 20}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => SocialCandidate.fromJson({'candidateProfileId': '   ', 'displayName': 'Test', 'age': 20}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects missing or empty display name in JSON (no manufactured Explorer default)', () {
      expect(
        () => SocialCandidate.fromJson({'candidateProfileId': 'c_1', 'age': 20}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => SocialCandidate.fromJson({'candidateProfileId': 'c_1', 'displayName': '   ', 'age': 20}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects missing age in JSON (no manufactured 18 default)', () {
      expect(
        () => SocialCandidate.fromJson({'candidateProfileId': 'c_1', 'displayName': 'Test'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => SocialCandidate.fromJson({'candidateProfileId': 'c_1', 'displayName': 'Test', 'age': 'twenty'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects underage candidate in JSON (< 18)', () {
      expect(
        () => SocialCandidate.fromJson({'candidateProfileId': 'c_1', 'displayName': 'Minor', 'age': 17}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => SocialCandidate.fromJson({'candidateProfileId': 'c_1', 'displayName': 'Minor', 'age': 0}),
        throwsA(isA<FormatException>()),
      );
    });

    test('redacted diagnostic string protects private user profile details', () {
      final candidate = SocialCandidate(
        id: 'confidential_guid_999',
        displayName: 'Secret Person',
        age: 30,
        biography: 'Private sensitive biography',
        locationName: 'Private Location',
      );

      final diag = candidate.toString();
      expect(diag, 'SocialCandidate(redacted)');
      expect(diag.contains('confidential'), isFalse);
      expect(diag.contains('Secret Person'), isFalse);
      expect(diag.contains('30'), isFalse);
      expect(diag.contains('Private sensitive biography'), isFalse);
    });

    test('equality and hashCode contract', () {
      final c1 = SocialCandidate(
        id: 'c1',
        displayName: 'Kasun',
        age: 25,
        interests: const {'Sports'},
      );
      final c2 = SocialCandidate(
        id: 'c1',
        displayName: 'Kasun',
        age: 25,
        interests: const {'Sports'},
      );
      final c3 = c1.copyWith(displayName: 'Kasun Updated');

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1 == c3, isFalse);
    });
  });
}
