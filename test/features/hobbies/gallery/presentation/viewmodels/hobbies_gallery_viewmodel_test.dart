import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/entities/hobbies_media.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/repositories/hobbies_gallery_repository.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/usecases/get_hobbies_gallery_media_usecase.dart';
import 'package:andril_mobile/features/hobbies/gallery/presentation/viewmodels/hobbies_gallery_viewmodel.dart';
import 'package:andril_mobile/features/hobbies/presentation/screens/hobbies_gallery_screen.dart';

/// Test double simulating use case behavior with controllable responses.
class _MockGetHobbiesGalleryMediaUseCase
    implements GetHobbiesGalleryMediaUseCase {
  @override
  final HobbiesGalleryRepository repository;

  Future<List<HobbiesMedia>> Function()? handler;
  int callCount = 0;

  _MockGetHobbiesGalleryMediaUseCase([HobbiesGalleryRepository? repo])
      : repository = repo ?? _FakeHobbiesGalleryRepository();

  @override
  Future<List<HobbiesMedia>> call() {
    callCount++;
    if (handler != null) {
      return handler!();
    }
    return Future.value(<HobbiesMedia>[]);
  }
}

class _FakeHobbiesGalleryRepository implements HobbiesGalleryRepository {
  @override
  Future<List<HobbiesMedia>> listMedia() async => const [];
}

void main() {
  group('HobbiesGalleryViewModel Unit Tests (M3-CP-02C-04-R01)', () {
    final testDate = DateTime(2026, 11, 24, 13, 0, 0);

    final sampleMediaItems = <HobbiesMedia>[
      HobbiesMedia(
        id: 'hob-media-1',
        title: 'Pottery Vase Glazing',
        caption: 'Cobalt oxide layer.',
        mediaUrl: 'https://storage.test/pottery/vase.jpg',
        hobbyTag: 'Pottery',
        createdAt: testDate,
      ),
      HobbiesMedia(
        id: 'hob-media-2',
        title: 'Macro Bonsai Shoot',
        caption: 'Shohin juniper needle pruning.',
        mediaUrl: 'https://storage.test/plants/bonsai.jpg',
        hobbyTag: 'Gardening',
        createdAt: testDate,
      ),
    ];

    test('1. ViewModel initialization', () {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase();
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      expect(viewModel.status, equals(HobbiesGalleryStatus.loading));
      expect(viewModel.items, isEmpty);
      expect(viewModel.isRevoked, isFalse);
      expect(viewModel.isDisposed, isFalse);
    });

    test('2. Constructor injection', () {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase();
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      expect(viewModel.getGalleryMediaUseCase, equals(mockUseCase));
    });

    test('3. Loading state starts correctly', () async {
      final completer = Completer<List<HobbiesMedia>>();
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => completer.future;
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      final loadFuture = viewModel.load();
      expect(viewModel.status, equals(HobbiesGalleryStatus.loading));
      expect(viewModel.isLoading, isTrue);

      completer.complete(sampleMediaItems);
      await loadFuture;
      expect(viewModel.isLoading, isFalse);
    });

    test('4. Populated result maps correctly', () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.value(sampleMediaItems);
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      await viewModel.load();

      expect(viewModel.status, equals(HobbiesGalleryStatus.populated));
      expect(viewModel.items.length, equals(2));
      expect(viewModel.items.first.id, equals('hob-media-1'));
      expect(viewModel.items.last.id, equals('hob-media-2'));
    });

    test('5. Empty result maps correctly', () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.value(<HobbiesMedia>[]);
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      await viewModel.load();

      expect(viewModel.status, equals(HobbiesGalleryStatus.empty));
      expect(viewModel.items, isEmpty);
    });

    test('6. Domain-to-presentation field integrity', () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.value(sampleMediaItems);
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      await viewModel.load();

      final firstPresentation = viewModel.items.first;
      final firstDomain = sampleMediaItems.first;

      expect(firstPresentation.id, equals(firstDomain.id));
      expect(firstPresentation.title, equals(firstDomain.title));
      expect(firstPresentation.caption, equals(firstDomain.caption));
      expect(firstPresentation.mediaUrl, equals(firstDomain.mediaUrl));
      expect(firstPresentation.hobbyTag, equals(firstDomain.hobbyTag));
      expect(firstPresentation.createdAt, equals(firstDomain.createdAt));
    });

    test('7. Repository invoked exactly once per load', () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.value(sampleMediaItems);
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      expect(mockUseCase.callCount, equals(0));

      await viewModel.load();
      expect(mockUseCase.callCount, equals(1));

      await viewModel.load();
      expect(mockUseCase.callCount, equals(2));
    });

    test('8. Generic error handling', () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.error(Exception('Network timeout'));
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      await viewModel.load();

      expect(viewModel.status, equals(HobbiesGalleryStatus.error));
      expect(viewModel.items, isEmpty);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.errorMessage, contains('Unable to load gallery media'));
    });

    test('9. Private media cleared after failure', () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.value(sampleMediaItems);
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      await viewModel.load();
      expect(viewModel.items.isNotEmpty, isTrue);

      // Subsequent failure must clear retained media
      mockUseCase.handler = () => Future.error(Exception('Server crash'));
      await viewModel.load();

      expect(viewModel.status, equals(HobbiesGalleryStatus.error));
      expect(viewModel.items, isEmpty);
    });

    test('10. Retry recovers from a previous error', () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.error(Exception('Temporary outage'));
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      await viewModel.load();
      expect(viewModel.status, equals(HobbiesGalleryStatus.error));

      // Retry recovers
      mockUseCase.handler = () => Future.value(sampleMediaItems);
      await viewModel.load();

      expect(viewModel.status, equals(HobbiesGalleryStatus.populated));
      expect(viewModel.items.length, equals(2));
    });

    test('11. Explicit denial clears retained media', () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.value(sampleMediaItems);
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      await viewModel.load();
      expect(viewModel.items.isNotEmpty, isTrue);

      viewModel.handleAccessDenied();

      expect(viewModel.status, equals(HobbiesGalleryStatus.denied));
      expect(viewModel.items, isEmpty);
      expect(viewModel.isRevoked, isTrue);
    });

    test('12. Denied state blocks further loads', () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.value(sampleMediaItems);
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      viewModel.handleAccessDenied();
      expect(viewModel.status, equals(HobbiesGalleryStatus.denied));

      final initialCallCount = mockUseCase.callCount;
      await viewModel.load();

      // No new invocation permitted after revocation
      expect(mockUseCase.callCount, equals(initialCallCount));
      expect(viewModel.status, equals(HobbiesGalleryStatus.denied));
      expect(viewModel.items, isEmpty);
    });

    test('13. Late responses cannot restore revoked media', () async {
      final completer = Completer<List<HobbiesMedia>>();
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => completer.future;
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      final loadFuture = viewModel.load();

      // Explicit revocation arrives while load is in-flight
      viewModel.handleAccessDenied();
      expect(viewModel.status, equals(HobbiesGalleryStatus.denied));

      // In-flight response finally completes late with media
      completer.complete(sampleMediaItems);
      await loadFuture;

      expect(viewModel.status, equals(HobbiesGalleryStatus.denied));
      expect(viewModel.items, isEmpty);
    });

    test('14. Older responses cannot overwrite newer results', () async {
      final completer1 = Completer<List<HobbiesMedia>>();
      final completer2 = Completer<List<HobbiesMedia>>();

      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase();
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      // Start Request 1
      mockUseCase.handler = () => completer1.future;
      final future1 = viewModel.load();

      // Start Request 2 (newer)
      mockUseCase.handler = () => completer2.future;
      final future2 = viewModel.load();

      // Complete Request 2 first with new items
      final newerItems = <HobbiesMedia>[
        HobbiesMedia(
          id: 'newer-item',
          title: 'Newer Pottery Item',
          createdAt: testDate,
        ),
      ];
      completer2.complete(newerItems);
      await future2;

      expect(viewModel.status, equals(HobbiesGalleryStatus.populated));
      expect(viewModel.items.length, equals(1));
      expect(viewModel.items.first.id, equals('newer-item'));

      // Now complete older Request 1 late with stale items
      completer1.complete(sampleMediaItems);
      await future1;

      // Stale items must NOT overwrite newer items
      expect(viewModel.status, equals(HobbiesGalleryStatus.populated));
      expect(viewModel.items.length, equals(1));
      expect(viewModel.items.first.id, equals('newer-item'));
    });

    test('15. Exposed collections cannot be modified externally', () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.value(sampleMediaItems);
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      await viewModel.load();

      final items = viewModel.items;
      expect(
        () => items.add(const HobbiesGalleryItem(id: 'hack', title: 'Hacked')),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('16. Listener notifications are correct', () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.value(sampleMediaItems);
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      var notificationCount = 0;
      viewModel.addListener(() {
        notificationCount++;
      });

      await viewModel.load();

      // Notified on loading transition and populated transition
      expect(notificationCount, greaterThanOrEqualTo(1));
    });

    test('17. Disposal is safe during active requests', () async {
      final completer = Completer<List<HobbiesMedia>>();
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => completer.future;
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      final loadFuture = viewModel.load();

      // Disposed while request in-flight
      viewModel.dispose();
      expect(viewModel.isDisposed, isTrue);

      // Complete request after disposal; must not throw Flutter framework error
      completer.complete(sampleMediaItems);
      await loadFuture;

      expect(viewModel.items, isEmpty);
    });

    test('18. No arbitrary identity or module arguments (reliably awaited)',
        () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase();
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      // Verify zero-argument load() signature and reliably await its execution
      await expectLater(viewModel.load(), completes);
      expect(viewModel.status, equals(HobbiesGalleryStatus.empty));
    });

    test('19. No sensitive metadata included in errors', () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.error(
            Exception('Private SQL Error: id=456 secret_url=http://vault'));
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      await viewModel.load();

      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.errorMessage!.contains('Private SQL Error'), isFalse);
      expect(viewModel.errorMessage!.contains('secret_url'), isFalse);
      expect(viewModel.errorMessage!.contains('http://vault'), isFalse);
    });

    test('20. Existing Gallery presentation contract remains compatible',
        () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () => Future.value(sampleMediaItems);
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      await viewModel.load();

      // Directly feeds HobbiesGalleryScreen properties
      final screen = HobbiesGalleryScreen(
        status: viewModel.status,
        items: viewModel.items,
      );

      expect(screen.status, equals(HobbiesGalleryStatus.populated));
      expect(screen.items.length, equals(2));
    });

    test(
        '21. Single request returning typed denial transitions to denied and revokes access',
        () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler =
            () => Future.error(const HobbiesGalleryAccessDeniedException());
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      await viewModel.load();

      expect(viewModel.status, equals(HobbiesGalleryStatus.denied));
      expect(viewModel.items, isEmpty);
      expect(viewModel.isRevoked, isTrue);
    });

    test(
        '22. An older request\'s denial revokes access even while a newer request is pending',
        () async {
      final completer1 = Completer<List<HobbiesMedia>>();
      final completer2 = Completer<List<HobbiesMedia>>();

      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase();
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      // Start Request 1 (older)
      mockUseCase.handler = () => completer1.future;
      final future1 = viewModel.load();

      // Start Request 2 (newer)
      mockUseCase.handler = () => completer2.future;
      final future2 = viewModel.load();

      // Complete Request 1 with explicit denial while Request 2 is still pending
      completer1.completeError(const HobbiesGalleryAccessDeniedException());
      await future1;

      expect(viewModel.status, equals(HobbiesGalleryStatus.denied));
      expect(viewModel.isRevoked, isTrue);
      expect(viewModel.items, isEmpty);

      // Now complete Request 2 with media
      completer2.complete(sampleMediaItems);
      await future2;

      // Newer response MUST NOT restore media or overwrite denial
      expect(viewModel.status, equals(HobbiesGalleryStatus.denied));
      expect(viewModel.isRevoked, isTrue);
      expect(viewModel.items, isEmpty);
    });

    test('23. An older denial clears data already returned by a newer request',
        () async {
      final completer1 = Completer<List<HobbiesMedia>>();
      final completer2 = Completer<List<HobbiesMedia>>();

      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase();
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      // Start Request 1 (older)
      mockUseCase.handler = () => completer1.future;
      final future1 = viewModel.load();

      // Start Request 2 (newer)
      mockUseCase.handler = () => completer2.future;
      final future2 = viewModel.load();

      // Request 2 completes first with media
      completer2.complete(sampleMediaItems);
      await future2;

      expect(viewModel.status, equals(HobbiesGalleryStatus.populated));
      expect(viewModel.items.length, equals(2));

      // Now older Request 1 returns late with authoritative denial
      completer1.completeError(const HobbiesGalleryAccessDeniedException());
      await future1;

      // Older denial MUST clear already-displayed data and transition to denied!
      expect(viewModel.status, equals(HobbiesGalleryStatus.denied));
      expect(viewModel.isRevoked, isTrue);
      expect(viewModel.items, isEmpty);
    });

    test(
        '24. Outdated generic errors do not overwrite newer successful results',
        () async {
      final completer1 = Completer<List<HobbiesMedia>>();
      final completer2 = Completer<List<HobbiesMedia>>();

      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase();
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      // Start Request 1
      mockUseCase.handler = () => completer1.future;
      final future1 = viewModel.load();

      // Start Request 2
      mockUseCase.handler = () => completer2.future;
      final future2 = viewModel.load();

      // Request 2 completes successfully with media
      completer2.complete(sampleMediaItems);
      await future2;

      expect(viewModel.status, equals(HobbiesGalleryStatus.populated));
      expect(viewModel.items.length, equals(2));

      // Now Request 1 completes late with a generic error
      completer1.completeError(Exception('Timeout on older request'));
      await future1;

      // Generic error from older request MUST NOT overwrite newer success
      expect(viewModel.status, equals(HobbiesGalleryStatus.populated));
      expect(viewModel.items.length, equals(2));
    });

    test('25. Denial diagnostics do not reveal private metadata', () {
      const exception = HobbiesGalleryAccessDeniedException();
      final diagnostic = exception.toString();

      expect(diagnostic, equals('HobbiesGalleryAccessDeniedException'));
      expect(diagnostic.contains('http'), isFalse);
      expect(diagnostic.contains('id'), isFalse);
      expect(diagnostic.contains('key'), isFalse);
    });

    test(
        '26. No arbitrary error message is interpreted as authorization denial',
        () async {
      final mockUseCase = _MockGetHobbiesGalleryMediaUseCase()
        ..handler = () =>
            Future.error(Exception('403 Forbidden: access denied by firewall'));
      final viewModel = HobbiesGalleryViewModel(mockUseCase);

      await viewModel.load();

      // Must be generic error, NEVER inferred as denied without typed signal!
      expect(viewModel.status, equals(HobbiesGalleryStatus.error));
      expect(viewModel.isRevoked, isFalse);
    });
  });
}
