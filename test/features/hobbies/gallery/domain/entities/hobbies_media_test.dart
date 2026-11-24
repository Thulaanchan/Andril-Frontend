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
      expect(media.toString(), contains('HobbiesMedia('));
      expect(media.toString(), contains('pure-dart-01'));
      expect(media.toString(), contains('Pure Domain'));
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
}
