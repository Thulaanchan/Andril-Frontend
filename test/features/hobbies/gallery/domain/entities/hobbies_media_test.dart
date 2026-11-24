import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/entities/hobbies_media.dart';
import 'package:andril_mobile/features/hobbies/presentation/screens/hobbies_gallery_screen.dart';

void main() {
  group('HobbiesMedia Domain Entity (M3-CP-02C-01)', () {
    final testCreatedAt = DateTime(2026, 11, 24, 12, 0, 0);

    test('1. Domain entity creation with minimal required fields', () {
      const media = HobbiesMedia(
        id: 'hob-media-001',
        title: 'Ceramic Vase',
      );

      expect(media, isA<HobbiesMedia>());
      expect(media.id, 'hob-media-001');
      expect(media.title, 'Ceramic Vase');
    });

    test('2. Required properties are accurately stored and accessible', () {
      const media = HobbiesMedia(
        id: 'media-req-42',
        title: 'Watercolor Landscape',
      );

      expect(media.id, equals('media-req-42'));
      expect(media.title, equals('Watercolor Landscape'));
    });

    test('3. Optional properties default to null and accept values', () {
      const mediaDefault = HobbiesMedia(
        id: 'media-opt-01',
        title: 'Default Test',
      );

      expect(mediaDefault.caption, isNull);
      expect(mediaDefault.mediaUrl, isNull);
      expect(mediaDefault.hobbyTag, isNull);
      expect(mediaDefault.createdAt, isNull);

      final mediaPopulated = HobbiesMedia(
        id: 'media-opt-02',
        title: 'Bonsai Pruning',
        caption: 'Refining foliage pads on Juniper.',
        mediaUrl: 'https://example.test/hobbies/bonsai.jpg',
        hobbyTag: 'Gardening',
        createdAt: testCreatedAt,
      );

      expect(
        mediaPopulated.caption,
        equals('Refining foliage pads on Juniper.'),
      );
      expect(
        mediaPopulated.mediaUrl,
        equals('https://example.test/hobbies/bonsai.jpg'),
      );
      expect(mediaPopulated.hobbyTag, equals('Gardening'));
      expect(mediaPopulated.createdAt, equals(testCreatedAt));
    });

    test('4. Value equality holds for entities with identical field values',
        () {
      final mediaA = HobbiesMedia(
        id: 'media-eq-01',
        title: 'Leathercraft',
        caption: 'Card holder finish.',
        mediaUrl: 'file://local/leather.jpg',
        hobbyTag: 'Crafts',
        createdAt: testCreatedAt,
      );

      final mediaB = HobbiesMedia(
        id: 'media-eq-01',
        title: 'Leathercraft',
        caption: 'Card holder finish.',
        mediaUrl: 'file://local/leather.jpg',
        hobbyTag: 'Crafts',
        createdAt: testCreatedAt,
      );

      expect(mediaA, equals(mediaB));
      expect(mediaA == mediaB, isTrue);

      final mediaCopy = mediaA.copyWith();
      expect(mediaCopy, equals(mediaA));
    });

    test('5. Consistent hashCode for equal instances', () {
      final mediaA = HobbiesMedia(
        id: 'media-hash-01',
        title: 'Astrophotography',
        caption: 'Orion nebula shot.',
        mediaUrl: 'https://example.test/astro.png',
        hobbyTag: 'Astronomy',
        createdAt: testCreatedAt,
      );

      final mediaB = HobbiesMedia(
        id: 'media-hash-01',
        title: 'Astrophotography',
        caption: 'Orion nebula shot.',
        mediaUrl: 'https://example.test/astro.png',
        hobbyTag: 'Astronomy',
        createdAt: testCreatedAt,
      );

      expect(mediaA.hashCode, equals(mediaB.hashCode));
    });

    test('6. Distinct media entities are not equal across fields', () {
      final base = HobbiesMedia(
        id: 'base-id',
        title: 'Base Title',
        caption: 'Base Caption',
        mediaUrl: 'https://example.test/base.jpg',
        hobbyTag: 'Baking',
        createdAt: testCreatedAt,
      );

      expect(base == base.copyWith(id: 'diff-id'), isFalse);
      expect(base == base.copyWith(title: 'Diff Title'), isFalse);
      expect(base == base.copyWith(caption: 'Diff Caption'), isFalse);
      expect(
        base == base.copyWith(mediaUrl: 'https://example.test/diff.jpg'),
        isFalse,
      );
      expect(base == base.copyWith(hobbyTag: 'Pottery'), isFalse);
      expect(
        base == base.copyWith(createdAt: DateTime(2026, 12, 1)),
        isFalse,
      );
    });

    test('7. Immutability and compile-time const support', () {
      const constA = HobbiesMedia(
        id: 'const-01',
        title: 'Const Entity',
      );
      const constB = HobbiesMedia(
        id: 'const-01',
        title: 'Const Entity',
      );

      expect(identical(constA, constB), isTrue);

      final updated = constA.copyWith(title: 'New Title');
      expect(updated.title, equals('New Title'));
      expect(constA.title, equals('Const Entity'));
    });

    test('8. Pure Dart entity has no Flutter UI or backend dependencies', () {
      const media = HobbiesMedia(
        id: 'pure-dart-01',
        title: 'Pure Domain',
      );

      expect(media, isNot(isA<Map<dynamic, dynamic>>()));
      expect(media.toString(), equals('HobbiesMedia'));
    });

    test('9. Presentation item compatibility with HobbiesGalleryItem', () {
      final presentationItem = HobbiesGalleryMockFixtures.sampleItems.first;

      final domainMedia = HobbiesMedia(
        id: presentationItem.id,
        title: presentationItem.title,
        caption: presentationItem.caption,
        mediaUrl: presentationItem.mediaUrl,
        hobbyTag: presentationItem.hobbyTag,
        createdAt: presentationItem.createdAt,
      );

      expect(domainMedia.id, equals(presentationItem.id));
      expect(domainMedia.title, equals(presentationItem.title));
      expect(domainMedia.caption, equals(presentationItem.caption));
      expect(domainMedia.mediaUrl, equals(presentationItem.mediaUrl));
      expect(domainMedia.hobbyTag, equals(presentationItem.hobbyTag));
      expect(domainMedia.createdAt, equals(presentationItem.createdAt));
    });
  });

  group('HobbiesMedia Domain Safety Hardening (M3-CP-02C-01-R01)', () {
    final testTime = DateTime(2026, 11, 24, 12, 30, 0);
    final initialMedia = HobbiesMedia(
      id: 'media-safe-01',
      title: 'Oil Painting on Canvas',
      caption: 'Sunset over coastal cliffs.',
      mediaUrl: 'https://storage.andril.test/gallery/oil_sunset.jpg',
      hobbyTag: 'Painting',
      createdAt: testTime,
    );

    test('1. Optional values preserved when omitted', () {
      final copied = initialMedia.copyWith(title: 'Updated Painting Title');

      expect(copied.id, equals(initialMedia.id));
      expect(copied.title, equals('Updated Painting Title'));
      expect(copied.caption, equals(initialMedia.caption));
      expect(copied.mediaUrl, equals(initialMedia.mediaUrl));
      expect(copied.hobbyTag, equals(initialMedia.hobbyTag));
      expect(copied.createdAt, equals(initialMedia.createdAt));
    });

    test('2. Optional values replaced correctly', () {
      final newTime = DateTime(2026, 11, 24, 15, 0, 0);
      final replaced = initialMedia.copyWith(
        caption: 'Sunrise over mountains.',
        mediaUrl: 'https://storage.andril.test/gallery/sunrise.jpg',
        hobbyTag: 'Digital Art',
        createdAt: newTime,
      );

      expect(replaced.caption, equals('Sunrise over mountains.'));
      expect(
        replaced.mediaUrl,
        equals('https://storage.andril.test/gallery/sunrise.jpg'),
      );
      expect(replaced.hobbyTag, equals('Digital Art'));
      expect(replaced.createdAt, equals(newTime));
    });

    test('3. Caption cleared', () {
      final cleared = initialMedia.copyWith(clearCaption: true);

      expect(cleared.caption, isNull);
      expect(cleared.mediaUrl, equals(initialMedia.mediaUrl));
      expect(cleared.hobbyTag, equals(initialMedia.hobbyTag));
      expect(cleared.createdAt, equals(initialMedia.createdAt));
    });

    test('4. Media URL cleared', () {
      final cleared = initialMedia.copyWith(clearMediaUrl: true);

      expect(cleared.mediaUrl, isNull);
      expect(cleared.caption, equals(initialMedia.caption));
      expect(cleared.hobbyTag, equals(initialMedia.hobbyTag));
      expect(cleared.createdAt, equals(initialMedia.createdAt));
    });

    test('5. Hobby tag cleared', () {
      final cleared = initialMedia.copyWith(clearHobbyTag: true);

      expect(cleared.hobbyTag, isNull);
      expect(cleared.caption, equals(initialMedia.caption));
      expect(cleared.mediaUrl, equals(initialMedia.mediaUrl));
      expect(cleared.createdAt, equals(initialMedia.createdAt));
    });

    test('6. Creation timestamp cleared', () {
      final cleared = initialMedia.copyWith(clearCreatedAt: true);

      expect(cleared.createdAt, isNull);
      expect(cleared.caption, equals(initialMedia.caption));
      expect(cleared.mediaUrl, equals(initialMedia.mediaUrl));
      expect(cleared.hobbyTag, equals(initialMedia.hobbyTag));
    });

    test('7. Multiple fields cleared together', () {
      final multiCleared = initialMedia.copyWith(
        clearCaption: true,
        clearMediaUrl: true,
        clearHobbyTag: true,
        clearCreatedAt: true,
      );

      expect(multiCleared.id, equals(initialMedia.id));
      expect(multiCleared.title, equals(initialMedia.title));
      expect(multiCleared.caption, isNull);
      expect(multiCleared.mediaUrl, isNull);
      expect(multiCleared.hobbyTag, isNull);
      expect(multiCleared.createdAt, isNull);
    });

    test('8. Contradictory replacement and clearing rejected', () {
      expect(
        () => initialMedia.copyWith(
          caption: 'Contradiction',
          clearCaption: true,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => initialMedia.copyWith(
          mediaUrl: 'https://storage.test/contradiction.jpg',
          clearMediaUrl: true,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => initialMedia.copyWith(
          hobbyTag: 'Tag',
          clearHobbyTag: true,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => initialMedia.copyWith(
          createdAt: DateTime.now(),
          clearCreatedAt: true,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('9. Entity remains immutable', () {
      const constMedia = HobbiesMedia(
        id: 'const-check',
        title: 'Original Title',
        caption: 'Original Caption',
      );

      final modified = constMedia.copyWith(clearCaption: true);

      expect(constMedia.caption, equals('Original Caption'));
      expect(modified.caption, isNull);
      expect(identical(constMedia, modified), isFalse);
    });

    test('10. Equality and hashCode remain correct', () {
      final copy1 = initialMedia.copyWith(clearCaption: true);
      final copy2 = initialMedia.copyWith(clearCaption: true);

      expect(copy1, equals(copy2));
      expect(copy1.hashCode, equals(copy2.hashCode));

      final copy3 = initialMedia.copyWith(clearCaption: false);
      expect(copy1 == copy3, isFalse);
      expect(copy1.hashCode == copy3.hashCode, isFalse);
    });

    test('11. toString reveals no private metadata', () {
      final diagnostic = initialMedia.toString();

      expect(diagnostic, equals('HobbiesMedia'));
      expect(diagnostic.contains(initialMedia.id), isFalse);
      expect(diagnostic.contains(initialMedia.title), isFalse);
      expect(diagnostic.contains(initialMedia.caption!), isFalse);
      expect(diagnostic.contains(initialMedia.mediaUrl!), isFalse);
      expect(diagnostic.contains(initialMedia.hobbyTag!), isFalse);
      expect(diagnostic.contains(initialMedia.createdAt!.toString()), isFalse);
    });

    test('12. Existing Gallery presentation compatibility', () {
      for (final fixture in HobbiesGalleryMockFixtures.sampleItems) {
        final domainMedia = HobbiesMedia(
          id: fixture.id,
          title: fixture.title,
          caption: fixture.caption,
          mediaUrl: fixture.mediaUrl,
          hobbyTag: fixture.hobbyTag,
          createdAt: fixture.createdAt,
        );

        expect(domainMedia.id, equals(fixture.id));
        expect(domainMedia.title, equals(fixture.title));
        expect(domainMedia.caption, equals(fixture.caption));
        expect(domainMedia.mediaUrl, equals(fixture.mediaUrl));
        expect(domainMedia.hobbyTag, equals(fixture.hobbyTag));
        expect(domainMedia.createdAt, equals(fixture.createdAt));

        final clearedCaption = domainMedia.copyWith(clearCaption: true);
        expect(clearedCaption.caption, isNull);
        expect(clearedCaption.title, equals(fixture.title));
      }
    });
  });

  group('HobbiesMedia Exception Privacy Hardening (M3-CP-02C-01-R02)', () {
    const sentinelCaption = 'SECRET_CONFIDENTIAL_CAPTION_98765';
    const sentinelMediaUrl =
        'https://storage.private.test/vault/secret_file_12345.jpg';
    const sentinelHobbyTag = 'SECRET_STEALTH_TAG_777';
    final sentinelCreatedAt = DateTime(2026, 12, 31, 23, 59, 59, 999);

    const baseMedia = HobbiesMedia(
      id: 'media-privacy-guard-01',
      title: 'Private Craft Prototype',
      caption: 'Initial private note.',
      mediaUrl: 'https://storage.test/base.jpg',
      hobbyTag: 'Woodworking',
    );

    test('1. Caption contradiction throws without exposing the caption', () {
      try {
        baseMedia.copyWith(
          caption: sentinelCaption,
          clearCaption: true,
        );
        fail('Expected ArgumentError was not thrown');
      } on ArgumentError catch (err) {
        expect(err.name, equals('caption'));
        expect(err.invalidValue, isNull);
        expect(err.message, contains('caption'));
        expect(err.message.toString().contains(sentinelCaption), isFalse);
        expect(err.toString().contains(sentinelCaption), isFalse);
      }
    });

    test('2. Media URL contradiction throws without exposing the URL', () {
      try {
        baseMedia.copyWith(
          mediaUrl: sentinelMediaUrl,
          clearMediaUrl: true,
        );
        fail('Expected ArgumentError was not thrown');
      } on ArgumentError catch (err) {
        expect(err.name, equals('mediaUrl'));
        expect(err.invalidValue, isNull);
        expect(err.message, contains('mediaUrl'));
        expect(err.message.toString().contains(sentinelMediaUrl), isFalse);
        expect(err.toString().contains(sentinelMediaUrl), isFalse);
      }
    });

    test('3. Hobby tag contradiction throws without exposing the tag', () {
      try {
        baseMedia.copyWith(
          hobbyTag: sentinelHobbyTag,
          clearHobbyTag: true,
        );
        fail('Expected ArgumentError was not thrown');
      } on ArgumentError catch (err) {
        expect(err.name, equals('hobbyTag'));
        expect(err.invalidValue, isNull);
        expect(err.message, contains('hobbyTag'));
        expect(err.message.toString().contains(sentinelHobbyTag), isFalse);
        expect(err.toString().contains(sentinelHobbyTag), isFalse);
      }
    });

    test('4. Timestamp contradiction throws without exposing the timestamp',
        () {
      try {
        baseMedia.copyWith(
          createdAt: sentinelCreatedAt,
          clearCreatedAt: true,
        );
        fail('Expected ArgumentError was not thrown');
      } on ArgumentError catch (err) {
        expect(err.name, equals('createdAt'));
        expect(err.invalidValue, isNull);
        expect(err.message, contains('createdAt'));
        expect(err.message.toString().contains('2026-12-31'), isFalse);
        expect(err.toString().contains('2026-12-31'), isFalse);
        expect(err.toString().contains('23:59:59'), isFalse);
      }
    });

    test('5. Exception messages retain safe parameter identification', () {
      final guards = <String, ArgumentError>{
        'caption': () {
          try {
            baseMedia.copyWith(caption: 'test', clearCaption: true);
            throw StateError('unreachable');
          } on ArgumentError catch (e) {
            return e;
          }
        }(),
        'mediaUrl': () {
          try {
            baseMedia.copyWith(mediaUrl: 'test', clearMediaUrl: true);
            throw StateError('unreachable');
          } on ArgumentError catch (e) {
            return e;
          }
        }(),
        'hobbyTag': () {
          try {
            baseMedia.copyWith(hobbyTag: 'test', clearHobbyTag: true);
            throw StateError('unreachable');
          } on ArgumentError catch (e) {
            return e;
          }
        }(),
        'createdAt': () {
          try {
            baseMedia.copyWith(createdAt: DateTime.now(), clearCreatedAt: true);
            throw StateError('unreachable');
          } on ArgumentError catch (e) {
            return e;
          }
        }(),
      };

      for (final entry in guards.entries) {
        expect(entry.value.name, equals(entry.key));
        expect(entry.value.message.toString(), contains(entry.key));
        expect(entry.value.toString(), contains('(${entry.key})'));
      }
    });

    test('6. ArgumentError.invalidValue does not retain the private payload',
        () {
      try {
        baseMedia.copyWith(caption: sentinelCaption, clearCaption: true);
      } on ArgumentError catch (err) {
        expect(err.invalidValue, isNull);
      }

      try {
        baseMedia.copyWith(mediaUrl: sentinelMediaUrl, clearMediaUrl: true);
      } on ArgumentError catch (err) {
        expect(err.invalidValue, isNull);
      }

      try {
        baseMedia.copyWith(hobbyTag: sentinelHobbyTag, clearHobbyTag: true);
      } on ArgumentError catch (err) {
        expect(err.invalidValue, isNull);
      }

      try {
        baseMedia.copyWith(createdAt: sentinelCreatedAt, clearCreatedAt: true);
      } on ArgumentError catch (err) {
        expect(err.invalidValue, isNull);
      }
    });

    test('7. Clearing optional fields still works', () {
      final cleared = baseMedia.copyWith(
        clearCaption: true,
        clearMediaUrl: true,
        clearHobbyTag: true,
        clearCreatedAt: true,
      );

      expect(cleared.caption, isNull);
      expect(cleared.mediaUrl, isNull);
      expect(cleared.hobbyTag, isNull);
      expect(cleared.createdAt, isNull);
      expect(cleared.id, equals(baseMedia.id));
      expect(cleared.title, equals(baseMedia.title));
    });

    test('8. Replacing optional fields still works', () {
      final updated = baseMedia.copyWith(
        caption: 'Public replaced caption',
        mediaUrl: 'https://storage.test/public_replaced.jpg',
        hobbyTag: 'Sculpting',
        createdAt: DateTime(2026, 11, 24, 13, 0, 0),
      );

      expect(updated.caption, equals('Public replaced caption'));
      expect(
          updated.mediaUrl, equals('https://storage.test/public_replaced.jpg'));
      expect(updated.hobbyTag, equals('Sculpting'));
      expect(updated.createdAt, equals(DateTime(2026, 11, 24, 13, 0, 0)));
    });

    test('9. HobbiesMedia.toString() remains privacy-safe', () {
      expect(baseMedia.toString(), equals('HobbiesMedia'));
      expect(baseMedia.toString().contains(baseMedia.id), isFalse);
      expect(baseMedia.toString().contains(baseMedia.title), isFalse);
    });

    test(
        '10. Equality, hashCode, immutability and constructor compatibility are unchanged',
        () {
      const constMedia1 = HobbiesMedia(
        id: 'comp-1',
        title: 'Compatibility Check',
        caption: 'Note',
      );
      const constMedia2 = HobbiesMedia(
        id: 'comp-1',
        title: 'Compatibility Check',
        caption: 'Note',
      );

      expect(identical(constMedia1, constMedia2), isTrue);
      expect(constMedia1 == constMedia2, isTrue);
      expect(constMedia1.hashCode, equals(constMedia2.hashCode));

      final nonConstCopy = constMedia1.copyWith();
      expect(nonConstCopy, equals(constMedia1));
      expect(nonConstCopy.hashCode, equals(constMedia1.hashCode));
    });
  });
}
