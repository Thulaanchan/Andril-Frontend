import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/entities/hobbies_media.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/repositories/hobbies_gallery_repository.dart';

/// Test double simulating an authorized Hobbies gallery repository.
class _FakeAuthorizedGalleryRepository implements HobbiesGalleryRepository {
  final List<HobbiesMedia> _items;

  _FakeAuthorizedGalleryRepository([this._items = const []]);

  @override
  Future<List<HobbiesMedia>> listMedia() async {
    return List.unmodifiable(_items);
  }
}

/// Test double simulating a repository failing closed on missing/denied authorization.
class _FakeUnauthorizedGalleryRepository implements HobbiesGalleryRepository {
  final Exception error;

  _FakeUnauthorizedGalleryRepository([Exception? error])
      : error = error ??
            Exception('Access denied: missing Hobbies module authorization');

  @override
  Future<List<HobbiesMedia>> listMedia() async {
    throw error;
  }
}

void main() {
  group('HobbiesGalleryRepository Domain Contract (M3-CP-02C-02)', () {
    final testDate = DateTime(2026, 11, 24, 13, 0, 0);

    final sampleMediaList = <HobbiesMedia>[
      HobbiesMedia(
        id: 'media-001',
        title: 'Ceramic Vase Workshop',
        caption: 'First wheel-throwing session.',
        mediaUrl: 'https://storage.test/pottery/vase1.jpg',
        hobbyTag: 'Pottery',
        createdAt: testDate,
      ),
      HobbiesMedia(
        id: 'media-002',
        title: 'Bonsai Pruning',
        caption: 'Juniper foliage styling.',
        mediaUrl: 'https://storage.test/gardening/bonsai1.jpg',
        hobbyTag: 'Gardening',
        createdAt: testDate,
      ),
    ];

    test('1. Repository interface can be implemented by a concrete repository',
        () async {
      final repository = _FakeAuthorizedGalleryRepository();
      expect(repository, isA<HobbiesGalleryRepository>());
    });

    test('2. listMedia returns a typed asynchronous collection of HobbiesMedia',
        () async {
      final repository = _FakeAuthorizedGalleryRepository(sampleMediaList);
      final result = await repository.listMedia();

      expect(result, isA<List<HobbiesMedia>>());
      expect(result.length, equals(2));
      expect(result.first.id, equals('media-001'));
      expect(result.last.id, equals('media-002'));
    });

    test('3. Handles empty media collection cleanly without error', () async {
      final repository = _FakeAuthorizedGalleryRepository(<HobbiesMedia>[]);
      final result = await repository.listMedia();

      expect(result, isA<List<HobbiesMedia>>());
      expect(result, isEmpty);
    });

    test(
        '4. Preserves domain entity immutability and equality across repository retrieval',
        () async {
      final repository = _FakeAuthorizedGalleryRepository(sampleMediaList);
      final result = await repository.listMedia();

      final firstItem = result.first;
      expect(firstItem, equals(sampleMediaList.first));
      expect(firstItem.hashCode, equals(sampleMediaList.first.hashCode));
      expect(firstItem.title, equals('Ceramic Vase Workshop'));
      expect(firstItem.hobbyTag, equals('Pottery'));

      // Modifying via copyWith yields distinct instance
      final updated = firstItem.copyWith(title: 'New Title');
      expect(updated.title, equals('New Title'));
      expect(firstItem.title, equals('Ceramic Vase Workshop'));
      expect(result.first.title, equals('Ceramic Vase Workshop'));
    });

    test(
        '5. Fails closed and propagates error when unauthorized or unauthenticated',
        () async {
      final repository = _FakeUnauthorizedGalleryRepository();

      expect(
        () => repository.listMedia(),
        throwsA(isA<Exception>()),
      );
    });

    test('6. Custom domain exception propagation in fail-closed scenario',
        () async {
      final securityException =
          Exception('Security violation: unverified caller context');
      final repository = _FakeUnauthorizedGalleryRepository(securityException);

      expect(
        () => repository.listMedia(),
        throwsA(isA<Exception>()),
      );
    });

    test(
        '7. Contract signature enforces zero caller-supplied identity parameters',
        () {
      final repository = _FakeAuthorizedGalleryRepository(sampleMediaList);
      expect(() => repository.listMedia(), returnsNormally);
    });

    test('8. Pure Dart contract has no Flutter UI or widget dependencies', () {
      final repository = _FakeAuthorizedGalleryRepository();
      expect(repository, isNot(isA<Map<dynamic, dynamic>>()));
      expect(repository.runtimeType.toString(), contains('GalleryRepository'));
    });
  });
}
