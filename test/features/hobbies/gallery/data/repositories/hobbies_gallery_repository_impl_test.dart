import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/hobbies/gallery/data/datasources/hobbies_gallery_data_source.dart';
import 'package:andril_mobile/features/hobbies/gallery/data/repositories/hobbies_gallery_repository_impl.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/entities/hobbies_media.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/exceptions/hobbies_gallery_access_denied_exception.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/repositories/hobbies_gallery_repository.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/usecases/get_hobbies_gallery_media_usecase.dart';

/// Private fake implementation of [HobbiesGalleryDataSource] for testing.
///
/// Simulates data source responses with synthetic test-only fixtures.
/// Does not access real networks, databases, or persistent caches.
class _FakeHobbiesGalleryDataSource implements HobbiesGalleryDataSource {
  List<HobbiesMedia> mediaToReturn;
  Exception? exceptionToThrow;
  int callCount = 0;

  _FakeHobbiesGalleryDataSource({
    List<HobbiesMedia>? media,
    this.exceptionToThrow,
  }) : mediaToReturn = media ?? <HobbiesMedia>[];

  @override
  Future<List<HobbiesMedia>> getGalleryMedia() async {
    callCount++;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return mediaToReturn;
  }
}

void main() {
  group('HobbiesGalleryRepositoryImpl (M3-CP-02C-05)', () {
    final DateTime testTimestamp = DateTime(2026, 11, 26, 12, 0);

    final HobbiesMedia testMediaItem1 = HobbiesMedia(
      id: 'mock-media-01',
      title: 'Ceramic Pottery Vase',
      caption: 'Handcrafted stoneware vase glazed in forest green.',
      mediaUrl: 'https://cdn.example.internal/media/pottery_01.jpg',
      hobbyTag: 'Pottery',
      createdAt: testTimestamp,
    );

    final HobbiesMedia testMediaItem2 = HobbiesMedia(
      id: 'mock-media-02',
      title: 'Botanical Herb Garden',
      caption: 'Indoor propagation tray for winter basil.',
      mediaUrl: 'https://cdn.example.internal/media/garden_02.jpg',
      hobbyTag: 'Gardening',
      createdAt: testTimestamp.add(const Duration(hours: 1)),
    );

    test('1. Existing repository interface compatibility', () async {
      final fakeDataSource = _FakeHobbiesGalleryDataSource();
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);

      expect(repository, isA<HobbiesGalleryRepository>());

      // Verify constructor injection through observable delegation
      await repository.listMedia();
      expect(fakeDataSource.callCount, equals(1));
    });

    test('2. Successful retrieval delegates to the injected data source',
        () async {
      final expectedItems = <HobbiesMedia>[testMediaItem1, testMediaItem2];
      final fakeDataSource =
          _FakeHobbiesGalleryDataSource(media: expectedItems);
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);

      final result = await repository.listMedia();

      expect(fakeDataSource.callCount, equals(1));
      expect(result.length, equals(2));
      expect(result[0].id, equals('mock-media-01'));
      expect(result[1].id, equals('mock-media-02'));
    });

    test('3. Empty media results', () async {
      final fakeDataSource =
          _FakeHobbiesGalleryDataSource(media: <HobbiesMedia>[]);
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);

      final result = await repository.listMedia();

      expect(fakeDataSource.callCount, equals(1));
      expect(result, isEmpty);
      expect(result, isA<List<HobbiesMedia>>());
    });

    test('4. Unmodifiable returned collection', () async {
      final fakeDataSource =
          _FakeHobbiesGalleryDataSource(media: <HobbiesMedia>[testMediaItem1]);
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);

      final result = await repository.listMedia();

      expect(() => result.add(testMediaItem2), throwsUnsupportedError);
      expect(() => result.clear(), throwsUnsupportedError);
      expect(() => result.removeAt(0), throwsUnsupportedError);
    });

    test('5. Defensive copying of source collections', () async {
      final mutableSourceList = <HobbiesMedia>[testMediaItem1];
      final fakeDataSource =
          _FakeHobbiesGalleryDataSource(media: mutableSourceList);
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);

      final result = await repository.listMedia();
      expect(result.length, equals(1));

      // Mutate the original source list after retrieval
      mutableSourceList.add(testMediaItem2);

      // The previously returned collection must remain unmodified
      expect(result.length, equals(1));
      expect(result[0].id, equals('mock-media-01'));
    });

    test('6. Preservation of immutable media entity values', () async {
      final fakeDataSource =
          _FakeHobbiesGalleryDataSource(media: <HobbiesMedia>[testMediaItem1]);
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);

      final result = await repository.listMedia();
      final item = result.first;

      expect(item.id, equals('mock-media-01'));
      expect(item.title, equals('Ceramic Pottery Vase'));
      expect(item.caption,
          equals('Handcrafted stoneware vase glazed in forest green.'));
      expect(item.mediaUrl,
          equals('https://cdn.example.internal/media/pottery_01.jpg'));
      expect(item.hobbyTag, equals('Pottery'));
      expect(item.createdAt, equals(testTimestamp));
    });

    test('7. Simulated unauthenticated access denial propagation', () async {
      final fakeDataSource = _FakeHobbiesGalleryDataSource(
        exceptionToThrow: const HobbiesGalleryAccessDeniedException(),
      );
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);

      expect(
        () => repository.listMedia(),
        throwsA(isA<HobbiesGalleryAccessDeniedException>()),
      );
    });

    test('8. Simulated cross-module or cross-profile denial propagation',
        () async {
      // Cross-profile or cross-module access violation emits authoritative denial
      final fakeDataSource = _FakeHobbiesGalleryDataSource(
        exceptionToThrow: const HobbiesGalleryAccessDeniedException(),
      );
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);

      expect(
        () => repository.listMedia(),
        throwsA(isA<HobbiesGalleryAccessDeniedException>()),
      );
    });

    test(
        '9. Successful retrieval followed by denial never returns previous media',
        () async {
      final fakeDataSource =
          _FakeHobbiesGalleryDataSource(media: <HobbiesMedia>[testMediaItem1]);
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);

      // First call succeeds
      final firstResult = await repository.listMedia();
      expect(firstResult.length, equals(1));

      // Transition to denied
      fakeDataSource.exceptionToThrow =
          const HobbiesGalleryAccessDeniedException();

      // Second call must fail closed, not return stale cached data
      expect(
        () => repository.listMedia(),
        throwsA(isA<HobbiesGalleryAccessDeniedException>()),
      );
    });

    test('10. Generic failure diagnostics do not expose private URLs',
        () async {
      const privateUrl =
          'https://private.andril.internal/secret_token_12345/sensitive_photo.jpg';
      final fakeDataSource = _FakeHobbiesGalleryDataSource(
        exceptionToThrow: Exception('Raw transport error at $privateUrl'),
      );
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);

      try {
        await repository.listMedia();
        fail('Expected Exception was not thrown');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), isNot(contains(privateUrl)));
        expect(e.toString(), isNot(contains('secret_token')));
        expect(e.toString(), contains('Gallery media retrieval failed.'));
      }
    });

    test('11. Failed requests never fabricate successful results', () async {
      final fakeDataSource = _FakeHobbiesGalleryDataSource(
        exceptionToThrow: Exception('Database unreachable'),
      );
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);

      expect(
        () => repository.listMedia(),
        throwsA(isA<Exception>()),
      );
    });

    test('12. Integration with GetHobbiesGalleryMediaUseCase', () async {
      final expectedItems = <HobbiesMedia>[testMediaItem1];
      final fakeDataSource =
          _FakeHobbiesGalleryDataSource(media: expectedItems);
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      final result = await useCase();

      expect(result.length, equals(1));
      expect(result.first.id, equals('mock-media-01'));
      expect(result, isA<List<HobbiesMedia>>());
    });

    test('13. Separate requests do not unintentionally reuse cached results',
        () async {
      final fakeDataSource =
          _FakeHobbiesGalleryDataSource(media: <HobbiesMedia>[testMediaItem1]);
      final repository = HobbiesGalleryRepositoryImpl(fakeDataSource);

      final firstResult = await repository.listMedia();
      expect(firstResult.length, equals(1));
      expect(firstResult[0].id, equals('mock-media-01'));

      // Update data source items for a subsequent request
      fakeDataSource.mediaToReturn = <HobbiesMedia>[
        testMediaItem1,
        testMediaItem2
      ];

      final secondResult = await repository.listMedia();
      expect(secondResult.length, equals(2));
      expect(secondResult[1].id, equals('mock-media-02'));
      expect(fakeDataSource.callCount, equals(2));
    });
  });
}
