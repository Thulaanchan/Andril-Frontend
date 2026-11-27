import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/entities/hobbies_media.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/repositories/hobbies_gallery_repository.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/usecases/get_hobbies_gallery_media_usecase.dart';
import 'package:andril_mobile/features/hobbies/gallery/presentation/viewmodels/hobbies_gallery_viewmodel.dart';
import 'package:andril_mobile/features/hobbies/gallery/presentation/widgets/hobbies_gallery_binding.dart';
import 'package:andril_mobile/features/hobbies/presentation/screens/hobbies_gallery_screen.dart';

/// Test-only fake repository simulating media retrieval, errors, and asynchronous delays.
class _FakeGalleryRepository implements HobbiesGalleryRepository {
  List<HobbiesMedia> mediaToReturn;
  Exception? errorToThrow;
  Completer<List<HobbiesMedia>>? completer;
  int callCount = 0;

  _FakeGalleryRepository({
    List<HobbiesMedia>? media,
    this.errorToThrow,
    this.completer,
  }) : mediaToReturn = media ?? <HobbiesMedia>[];

  @override
  Future<List<HobbiesMedia>> listMedia() async {
    callCount++;
    if (completer != null) {
      return completer!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mediaToReturn;
  }
}

void main() {
  group('HobbiesGalleryBinding (M3-CP-02C-06)', () {
    final DateTime testDate = DateTime(2026, 11, 27, 10, 0);

    final HobbiesMedia testItem1 = HobbiesMedia(
      id: 'hob-media-01',
      title: 'Ceramic Glazing Workshop',
      caption: 'Handmade pottery with teal glaze finish.',
      mediaUrl: 'https://cdn.example.internal/media/pottery.jpg',
      hobbyTag: 'Pottery',
      createdAt: testDate,
    );

    final HobbiesMedia testItem2 = HobbiesMedia(
      id: 'hob-media-02',
      title: 'Indoor Herb Garden',
      caption: 'Winter rosemary propagation.',
      mediaUrl: 'https://cdn.example.internal/media/garden.jpg',
      hobbyTag: 'Gardening',
      createdAt: testDate.add(const Duration(hours: 2)),
    );

    Widget createTestApp(Widget child) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: child,
      );
    }

    testWidgets('1. Gallery binding accepts an injected ViewModel',
        (WidgetTester tester) async {
      final fakeRepo = _FakeGalleryRepository();
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: false,
          ),
        ),
      );

      expect(find.byType(HobbiesGalleryBinding), findsOneWidget);
      expect(find.byType(HobbiesGalleryScreen), findsOneWidget);
      // Strengthened: autoLoad: false must not trigger repository retrieval
      expect(fakeRepo.callCount, equals(0));
    });

    testWidgets('2. Initial retrieval occurs once',
        (WidgetTester tester) async {
      final fakeRepo = _FakeGalleryRepository();
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeRepo.callCount, equals(1));
    });

    testWidgets('3. Rebuilds do not trigger duplicate requests',
        (WidgetTester tester) async {
      final fakeRepo = _FakeGalleryRepository();
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(fakeRepo.callCount, equals(1));

      // Trigger multiple rebuilds of the widget tree
      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
            title: 'Updated Title',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
            title: 'Updated Title Again',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Call count must strictly remain 1
      expect(fakeRepo.callCount, equals(1));
    });

    testWidgets('4. Loading state renders correctly',
        (WidgetTester tester) async {
      final completer = Completer<List<HobbiesMedia>>();
      final fakeRepo = _FakeGalleryRepository(completer: completer);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading media gallery...'), findsOneWidget);

      completer.complete(<HobbiesMedia>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('5. Empty state renders correctly',
        (WidgetTester tester) async {
      final fakeRepo = _FakeGalleryRepository(media: <HobbiesMedia>[]);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Hobby Moments Yet'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('6. Populated state reflects ViewModel media',
        (WidgetTester tester) async {
      final fakeRepo = _FakeGalleryRepository(
        media: <HobbiesMedia>[testItem1, testItem2],
      );
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);
      expect(find.text('Indoor Herb Garden'), findsOneWidget);
      expect(find.text('Total Media'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('7. Generic error state renders safely',
        (WidgetTester tester) async {
      final fakeRepo = _FakeGalleryRepository(
        errorToThrow: Exception('Database connection failed'),
      );
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Media'), findsOneWidget);
      expect(
        find.text('Unable to load gallery media. Please try again.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('gallery_retry_button')), findsOneWidget);
    });

    testWidgets('8. Retry invokes the existing ViewModel behavior',
        (WidgetTester tester) async {
      final fakeRepo = _FakeGalleryRepository(
        errorToThrow: Exception('Initial network error'),
      );
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(fakeRepo.callCount, equals(1));
      expect(find.text('Unable to Load Media'), findsOneWidget);

      // Resolve the error on the fake repository
      fakeRepo.errorToThrow = null;
      fakeRepo.mediaToReturn = <HobbiesMedia>[testItem1];

      // Tap the retry button
      await tester.tap(find.byKey(const Key('gallery_retry_button')));
      await tester.pumpAndSettle();

      expect(fakeRepo.callCount, equals(2));
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);
    });

    testWidgets(
        '9. Authoritative access denial removes previously visible private media widgets',
        (WidgetTester tester) async {
      final fakeRepo = _FakeGalleryRepository(
        media: <HobbiesMedia>[testItem1],
      );
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);

      // Transition repository to authoritative access denial
      fakeRepo.errorToThrow = const HobbiesGalleryAccessDeniedException();
      viewModel.load();
      await tester.pumpAndSettle();

      // Private media widgets must be immediately wiped from the screen
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('10. Access-denied UI is distinct from empty-state UI',
        (WidgetTester tester) async {
      final fakeRepo = _FakeGalleryRepository(
        errorToThrow: const HobbiesGalleryAccessDeniedException(),
      );
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.text('No Hobby Moments Yet'), findsNothing);
      expect(find.byKey(const Key('gallery_retry_button')), findsNothing);
    });

    testWidgets(
        '11. A stale successful response cannot restore private media after denial',
        (WidgetTester tester) async {
      final completer1 = Completer<List<HobbiesMedia>>();
      final fakeRepo = _FakeGalleryRepository(completer: completer1);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pump();

      // Trigger a denial request while first request is in-flight
      fakeRepo.completer = null;
      fakeRepo.errorToThrow = const HobbiesGalleryAccessDeniedException();
      viewModel.load();
      await tester.pumpAndSettle();

      expect(find.text('Access Denied'), findsOneWidget);

      // Now complete the older stale request with data
      completer1.complete(<HobbiesMedia>[testItem1]);
      await tester.pumpAndSettle();

      // Media must NOT be restored
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      expect(find.text('Access Denied'), findsOneWidget);
      expect(viewModel.isRevoked, isTrue);
    });

    testWidgets('12. Repeated state changes remain reactive',
        (WidgetTester tester) async {
      final fakeRepo = _FakeGalleryRepository(media: <HobbiesMedia>[]);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No Hobby Moments Yet'), findsOneWidget);

      // Transition to populated
      fakeRepo.mediaToReturn = <HobbiesMedia>[testItem1];
      viewModel.load();
      await tester.pumpAndSettle();
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);

      // Transition to error
      fakeRepo.errorToThrow = Exception('Transient error');
      viewModel.load();
      await tester.pumpAndSettle();
      expect(find.text('Unable to Load Media'), findsOneWidget);

      // Transition back to populated
      fakeRepo.errorToThrow = null;
      viewModel.load();
      await tester.pumpAndSettle();
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);
    });

    testWidgets('13. Widget disposal prevents listener or lifecycle errors',
        (WidgetTester tester) async {
      final completer = Completer<List<HobbiesMedia>>();
      final fakeRepo = _FakeGalleryRepository(completer: completer);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      // Mount the binding with an in-flight asynchronous request
      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Unmount the binding while request is in-flight
      await tester.pumpWidget(createTestApp(const SizedBox()));
      await tester.pump();

      // Complete in-flight request after unmount
      completer.complete(<HobbiesMedia>[testItem1]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Subsequent load on the external ViewModel completes safely
      fakeRepo.completer = null;
      fakeRepo.mediaToReturn = <HobbiesMedia>[testItem1, testItem2];
      await viewModel.load();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(viewModel.isDisposed, isFalse);
      expect(viewModel.items.length, equals(2));
    });

    testWidgets('14. Externally owned ViewModel is not incorrectly disposed',
        (WidgetTester tester) async {
      final fakeRepo = _FakeGalleryRepository();
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unmount the widget
      await tester.pumpWidget(createTestApp(const SizedBox()));
      await tester.pumpAndSettle();

      // Externally owned viewModel must remain active
      expect(viewModel.isDisposed, isFalse);
    });

    testWidgets(
        '15. No raw private URLs or exception details appear in visible error text',
        (WidgetTester tester) async {
      const String sensitiveUrl =
          'https://private.andril.internal/secret_token_98765/confidential.jpg';
      final fakeRepo = _FakeGalleryRepository(
        errorToThrow: Exception('Crash on $sensitiveUrl'),
      );
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      final viewModel = HobbiesGalleryViewModel(useCase);

      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            viewModel: viewModel,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('private.andril.internal'), findsNothing);
      expect(find.textContaining('secret_token'), findsNothing);
      expect(find.textContaining('confidential.jpg'), findsNothing);
      expect(
        find.text('Unable to load gallery media. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('16. ViewModel replacement isolates stale responses',
        (WidgetTester tester) async {
      final completerA = Completer<List<HobbiesMedia>>();
      final fakeRepoA = _FakeGalleryRepository(completer: completerA);
      final useCaseA = GetHobbiesGalleryMediaUseCase(fakeRepoA);
      final viewModelA = HobbiesGalleryViewModel(useCaseA);

      final fakeRepoB =
          _FakeGalleryRepository(media: <HobbiesMedia>[testItem2]);
      final useCaseB = GetHobbiesGalleryMediaUseCase(fakeRepoB);
      final viewModelB = HobbiesGalleryViewModel(useCaseB);

      const bindingKey = Key('hobbies_gallery_binding_key');

      // 1. Mount using ViewModel A with a pending request
      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            key: bindingKey,
            viewModel: viewModelA,
            autoLoad: true,
          ),
        ),
      );
      await tester.pump();
      expect(fakeRepoA.callCount, equals(1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 2. Replace ViewModel A with ViewModel B (preserving the same binding identity)
      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            key: bindingKey,
            viewModel: viewModelB,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ViewModel B must load exactly once when autoLoad is true
      expect(fakeRepoB.callCount, equals(1));
      // Display ViewModel B's distinct synthetic media
      expect(find.text('Indoor Herb Garden'), findsOneWidget);
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);

      // 3. Complete ViewModel A's older pending request with its media
      completerA.complete(<HobbiesMedia>[testItem1]);
      await tester.pumpAndSettle();

      // Verify ViewModel A's media never appears in the current screen
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      // Verify ViewModel B's media remains visible
      expect(find.text('Indoor Herb Garden'), findsOneWidget);

      // Verify neither externally owned ViewModel was incorrectly disposed
      expect(viewModelA.isDisposed, isFalse);
      expect(viewModelB.isDisposed, isFalse);
      // Verify no lifecycle exceptions occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('17. Replacement with revoked ViewModel remains fail-closed',
        (WidgetTester tester) async {
      final fakeRepoA =
          _FakeGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final useCaseA = GetHobbiesGalleryMediaUseCase(fakeRepoA);
      final viewModelA = HobbiesGalleryViewModel(useCaseA);

      // Prepare ViewModel B in an authoritative access-denied state
      final fakeRepoB = _FakeGalleryRepository(
        errorToThrow: const HobbiesGalleryAccessDeniedException(),
      );
      final useCaseB = GetHobbiesGalleryMediaUseCase(fakeRepoB);
      final viewModelB = HobbiesGalleryViewModel(useCaseB);
      await viewModelB.load();
      expect(viewModelB.status, equals(HobbiesGalleryStatus.denied));
      expect(viewModelB.isRevoked, isTrue);
      final int callCountBBefore = fakeRepoB.callCount;

      const bindingKey = Key('hobbies_gallery_binding_key');

      // 1. Display synthetic private media using ViewModel A
      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            key: bindingKey,
            viewModel: viewModelA,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);

      // 2. Replace ViewModel A with revoked ViewModel B
      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            key: bindingKey,
            viewModel: viewModelB,
            autoLoad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify previous media widgets are removed
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      // Verify Access Denied is displayed
      expect(find.text('Access Denied'), findsOneWidget);
      // Verify the retry button is absent
      expect(find.byKey(const Key('gallery_retry_button')), findsNothing);
      // Verify replacement does not trigger another retrieval on the revoked ViewModel
      expect(fakeRepoB.callCount, equals(callCountBBefore));

      // 3. Verify later notifications from ViewModel A cannot restore its media
      fakeRepoA.mediaToReturn = <HobbiesMedia>[testItem1, testItem2];
      await viewModelA.load();
      await tester.pumpAndSettle();

      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      expect(find.text('Indoor Herb Garden'), findsNothing);
      expect(find.text('Access Denied'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('18. ViewModel replacement respects autoLoad false',
        (WidgetTester tester) async {
      final fakeRepoA =
          _FakeGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final useCaseA = GetHobbiesGalleryMediaUseCase(fakeRepoA);
      final viewModelA = HobbiesGalleryViewModel(useCaseA);

      final fakeRepoB =
          _FakeGalleryRepository(media: <HobbiesMedia>[testItem2]);
      final useCaseB = GetHobbiesGalleryMediaUseCase(fakeRepoB);
      final viewModelB = HobbiesGalleryViewModel(useCaseB);

      const bindingKey = Key('hobbies_gallery_binding_key');

      // 1. Mount with autoLoad: false
      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            key: bindingKey,
            viewModel: viewModelA,
            autoLoad: false,
          ),
        ),
      );
      // Bounded single frame pump avoids timing out on indeterminate progress animation
      await tester.pump();
      expect(fakeRepoA.callCount, equals(0));

      // 2. Replace with ViewModel B, keeping autoLoad: false
      await tester.pumpWidget(
        createTestApp(
          HobbiesGalleryBinding(
            key: bindingKey,
            viewModel: viewModelB,
            autoLoad: false,
          ),
        ),
      );
      // Bounded single frame pump avoids timing out on indeterminate progress animation
      await tester.pump();

      // Verify no automatic retrieval occurs for either instance
      expect(fakeRepoA.callCount, equals(0));
      expect(fakeRepoB.callCount, equals(0));

      // 3. Verify binding observes ViewModel B when explicitly loaded
      await viewModelB.load();
      await tester.pumpAndSettle();

      expect(fakeRepoB.callCount, equals(1));
      expect(find.text('Indoor Herb Garden'), findsOneWidget);
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);

      // 4. Verify previous ViewModel A cannot update the replacement screen
      await viewModelA.load();
      await tester.pumpAndSettle();

      expect(fakeRepoA.callCount, equals(1));
      expect(find.text('Indoor Herb Garden'), findsOneWidget);
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);

      // 5. Verify both externally owned ViewModels remain active and usable
      expect(viewModelA.isDisposed, isFalse);
      expect(viewModelB.isDisposed, isFalse);

      // Unmount safely to detach listeners before disposing test-owned ViewModels
      await tester.pumpWidget(createTestApp(const SizedBox()));
      await tester.pumpAndSettle();

      viewModelA.dispose();
      viewModelB.dispose();

      expect(tester.takeException(), isNull);
    });
  });
}
