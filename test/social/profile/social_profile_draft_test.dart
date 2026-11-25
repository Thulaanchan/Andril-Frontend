import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocialProfileDraft Validation Tests (M5-FE-S02-DOM-02)', () {
    test('default draft has private visibility and empty display name', () {
      const draft = SocialProfileDraft();
      expect(draft.displayName, '');
      expect(draft.bio, isNull);
      expect(draft.profilePhotoPath, isNull);
      expect(draft.visibility, 'private');
      expect(draft.isValid, isFalse);
      expect(draft.displayNameError, isNotNull);
      expect(draft.bioError, isNull);
    });

    test('valid display name passes validation', () {
      const draft = SocialProfileDraft(
        displayName: 'Thulaan',
        bio: 'Hello ANDRIL Social!',
      );
      expect(draft.isValid, isTrue);
      expect(draft.displayNameError, isNull);
      expect(draft.bioError, isNull);
      expect(draft.displayNameGraphemeCount, 7);
      expect(draft.bioGraphemeCount, 20);
    });

    group('Display Name Boundary Validation', () {
      test('rejects empty or whitespace-only display names', () {
        expect(
          SocialProfileDraft.validateDisplayName(''),
          'Display name cannot be empty.',
        );
        expect(
          SocialProfileDraft.validateDisplayName('   '),
          'Display name cannot be empty.',
        );
        expect(
          SocialProfileDraft.validateDisplayName(null),
          'Display name cannot be empty.',
        );
      });

      test('validates minimum length boundary (3 grapheme clusters)', () {
        // 2 characters -> invalid
        expect(
          SocialProfileDraft.validateDisplayName('Ab'),
          'Display name must be at least 3 characters.',
        );
        // 3 characters -> valid
        expect(SocialProfileDraft.validateDisplayName('Abc'), isNull);
      });

      test('validates maximum length boundary (30 grapheme clusters)', () {
        final exactly30 = 'A' * 30;
        final exactly31 = 'A' * 31;
        expect(SocialProfileDraft.validateDisplayName(exactly30), isNull);
        expect(
          SocialProfileDraft.validateDisplayName(exactly31),
          'Display name must not exceed 30 characters.',
        );
      });

      test('disallows C0 and C1 control characters in display name', () {
        expect(
          SocialProfileDraft.validateDisplayName('Test\x00Name'),
          'Display name contains invalid characters.',
        );
        expect(
          SocialProfileDraft.validateDisplayName('Test\x1FName'),
          'Display name contains invalid characters.',
        );
      });

      test('preserves Tamil Unicode grapheme clusters with combining marks', () {
        // "தமிழ்" consists of:
        // த (U+0BA4)
        // ம (U+0BAE) + ி (U+0BC0) -> 1 cluster
        // ழ (U+0BB4) + ் (U+0BCD) -> 1 cluster
        // Total = 3 grapheme clusters, 5 UTF-16 code units.
        const tamilName = 'தமிழ்';
        expect(tamilName.length, 5); // Raw code units
        const draft = SocialProfileDraft(displayName: tamilName);
        expect(draft.displayNameGraphemeCount, 3);
        expect(draft.isValid, isTrue);
        expect(draft.displayNameError, isNull);
      });

      test('preserves Sinhala Unicode grapheme clusters with combining marks', () {
        // "සිංහල":
        // 'සිං' (ස + ි + ං) -> 1 cluster with combining marks
        // 'හ' -> 1 cluster
        // 'ල' -> 1 cluster
        // Total = 3 clusters
        const sinhalaName = 'සිංහල';
        const draft = SocialProfileDraft(displayName: sinhalaName);
        expect(draft.displayNameGraphemeCount, 3);
        expect(draft.isValid, isTrue);
        expect(draft.displayNameError, isNull);
      });

      test('allows approved punctuation and spaces in display name', () {
        expect(SocialProfileDraft.validateDisplayName('Mary-Jane'), isNull);
        expect(SocialProfileDraft.validateDisplayName("O'Connor"), isNull);
        expect(SocialProfileDraft.validateDisplayName('Jean Luc'), isNull);
      });
    });

    group('Bio Boundary Validation', () {
      test('optional bio can be null or empty', () {
        const draft1 = SocialProfileDraft(displayName: 'Thulaan', bio: null);
        const draft2 = SocialProfileDraft(displayName: 'Thulaan', bio: '');
        expect(draft1.isValid, isTrue);
        expect(draft2.isValid, isTrue);
        expect(draft1.bioError, isNull);
        expect(draft2.bioError, isNull);
      });

      test('bio allows multiline newlines but rejects control characters', () {
        const multilineBio = 'First line\nSecond line\r\nThird line';
        expect(SocialProfileDraft.validateBio(multilineBio), isNull);

        const invalidBio = 'Hello\x00World';
        expect(
          SocialProfileDraft.validateBio(invalidBio),
          'Bio contains invalid characters.',
        );
      });

      test('validates maximum bio length (300 grapheme clusters)', () {
        final bio300 = 'B' * 300;
        final bio301 = 'B' * 301;
        expect(SocialProfileDraft.validateBio(bio300), isNull);
        expect(
          SocialProfileDraft.validateBio(bio301),
          'Bio must not exceed 300 characters.',
        );
      });
    });

    group('Immutability and Contract Safety', () {
      test('copyWith creates new instance and retains private visibility', () {
        const original = SocialProfileDraft(
          displayName: 'Initial',
          bio: 'Initial Bio',
          profilePhotoPath: '/tmp/photo.jpg',
        );
        final updated = original.copyWith(displayName: 'Updated Name');

        expect(updated.displayName, 'Updated Name');
        expect(updated.bio, 'Initial Bio');
        expect(updated.profilePhotoPath, '/tmp/photo.jpg');
        expect(updated.visibility, 'private');
        expect(original.displayName, 'Initial');
      });

      test('operator == and hashCode operate correctly', () {
        const draft1 = SocialProfileDraft(displayName: 'Alice', bio: 'Bio');
        const draft2 = SocialProfileDraft(displayName: 'Alice', bio: 'Bio');
        const draft3 = SocialProfileDraft(displayName: 'Bob', bio: 'Bio');

        expect(draft1, equals(draft2));
        expect(draft1.hashCode, equals(draft2.hashCode));
        expect(draft1, isNot(equals(draft3)));
      });

      test('toString excludes raw bio and sensitive text', () {
        const draft = SocialProfileDraft(
          displayName: 'Private Name',
          bio: 'Secret Bio Information',
          profilePhotoPath: '/private/path.jpg',
        );
        final diagnostic = draft.toString();
        expect(diagnostic, contains('displayNameLength: 12'));
        expect(diagnostic, contains('hasBio: true'));
        expect(diagnostic, contains('hasPhoto: true'));
        expect(diagnostic, contains('visibility: private'));
        expect(diagnostic, isNot(contains('Secret Bio Information')));
        expect(diagnostic, isNot(contains('Private Name')));
      });
    });
  });
}
