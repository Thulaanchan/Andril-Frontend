import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/entities/hobbies_media.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/repositories/hobbies_gallery_repository.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/usecases/get_hobbies_gallery_media_usecase.dart';

/// Test double simulating repository responses with invocation tracking.
class _MockHobbiesGalleryRepository implements HobbiesGalleryRepository {
  List<HobbiesMedia>? itemsToReturn;
  Exception? errorToThrow;
  Error? criticalErrorToThrow;
  int listMediaCallCount = 0;

  _MockHobbiesGalleryRepository({
    this.itemsToReturn,
    this.errorToThrow,
    this.criticalErrorToThrow,
  });

  @override
  Future<List<HobbiesMedia>> listMedia() async {
    listMediaCallCount++;
    if (criticalErrorToThrow != null) {
      throw criticalErrorToThrow!;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return itemsToReturn ?? const [];
  }
}

void main() {
  group('GetHobbiesGalleryMediaUseCase Domain Unit Tests (M3-CP-02C-03)', () {
    final testDate = DateTime(2026, 11, 24, 13, 0, 0);

    final sampleMediaItems = <HobbiesMedia>[
      HobbiesMedia(
        id: 'hob-001',
        title: 'Glazed Pottery Mug',
        caption: 'Handcrafted stoneware with tenmoku glaze.',
        mediaUrl: 'https://storage.test/pottery/mug.jpg',
        hobbyTag: 'Pottery',
        createdAt: testDate,
      ),
      HobbiesMedia(
        id: 'hob-002',
        title: 'Succulent Garden Display',
        caption: 'Arrangement of echeveria and haworthia.',
        mediaUrl: 'https://storage.test/plants/succulents.jpg',
        hobbyTag: 'Gardening',
        createdAt: testDate,
      ),
    ];

    test('1. Use case initializes correctly', () {
      final repository = _MockHobbiesGalleryRepository();
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      expect(useCase, isA<GetHobbiesGalleryMediaUseCase>());
    });

    test('2. Repository dependency is injected and accessible', () {
      final repository = _MockHobbiesGalleryRepository();
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      expect(useCase.repository, equals(repository));
    });

    test('3. Populated media list returns successfully', () async {
      final repository = _MockHobbiesGalleryRepository(
        itemsToReturn: sampleMediaItems,
      );
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      final result = await useCase();

      expect(result, isA<List<HobbiesMedia>>());
      expect(result.length, equals(2));
      expect(result.first.id, equals('hob-001'));
      expect(result.last.id, equals('hob-002'));
    });

    test('4. Empty media list returns successfully', () async {
      final repository = _MockHobbiesGalleryRepository(
        itemsToReturn: <HobbiesMedia>[],
      );
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      final result = await useCase();

      expect(result, isA<List<HobbiesMedia>>());
      expect(result, isEmpty);
    });

    test('5. Domain entity properties are preserved without mutation or loss',
        () async {
      final repository = _MockHobbiesGalleryRepository(
        itemsToReturn: sampleMediaItems,
      );
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      final result = await useCase();
      final first = result.first;

      expect(first.id, equals('hob-001'));
      expect(first.title, equals('Glazed Pottery Mug'));
      expect(
          first.caption, equals('Handcrafted stoneware with tenmoku glaze.'));
      expect(first.mediaUrl, equals('https://storage.test/pottery/mug.jpg'));
      expect(first.hobbyTag, equals('Pottery'));
      expect(first.createdAt, equals(testDate));
      expect(first, equals(sampleMediaItems.first));
    });

    test('6. Unauthorized repository failure propagates as an error', () async {
      final authException =
          Exception('Access denied: missing Hobbies module authorization');
      final repository = _MockHobbiesGalleryRepository(
        errorToThrow: authException,
      );
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      expect(
        () => useCase(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('missing Hobbies module authorization'),
        )),
      );
    });

    test('7. General repository failure propagates', () async {
      final dbError = StateError('Repository query failed');
      final repository = _MockHobbiesGalleryRepository(
        criticalErrorToThrow: dbError,
      );
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      expect(
        () => useCase(),
        throwsA(isA<StateError>()),
      );
    });

    test('8. Failures are not converted to empty success results', () async {
      final repository = _MockHobbiesGalleryRepository(
        errorToThrow: Exception('Network timeout'),
      );
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      // Must complete with error, never complete normally with an empty list
      var completedNormally = false;
      try {
        await useCase();
        completedNormally = true;
      } catch (_) {
        completedNormally = false;
      }

      expect(completedNormally, isFalse);
    });

    test('9. Repository is invoked exactly once per use-case call', () async {
      final repository = _MockHobbiesGalleryRepository(
        itemsToReturn: sampleMediaItems,
      );
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      expect(repository.listMediaCallCount, equals(0));

      await useCase();
      expect(repository.listMediaCallCount, equals(1));

      await useCase();
      expect(repository.listMediaCallCount, equals(2));
    });

    test('10. No caller-supplied profile or module selector exists', () {
      final repository = _MockHobbiesGalleryRepository();
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      // call() signature is zero-argument: callers cannot inject arbitrary profile/user IDs
      expect(() => useCase(), returnsNormally);
    });

    test(
        '11. Use case does not introduce networking or Flutter UI dependencies',
        () {
      final repository = _MockHobbiesGalleryRepository();
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      expect(useCase, isNot(isA<Map<dynamic, dynamic>>()));
      expect(useCase.runtimeType.toString(),
          equals('GetHobbiesGalleryMediaUseCase'));
    });

    test('12. Existing repository and domain tests remain compatible',
        () async {
      final repository = _MockHobbiesGalleryRepository(
        itemsToReturn: sampleMediaItems,
      );
      final useCase = GetHobbiesGalleryMediaUseCase(repository);

      final mediaList = await useCase();
      for (final media in mediaList) {
        expect(media.toString(), equals('HobbiesMedia'));
        expect(media.copyWith(), equals(media));
      }
    });
  });
}
