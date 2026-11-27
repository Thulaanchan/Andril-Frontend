import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:andril_mobile/app/router/hobbies_router.dart';
import 'package:andril_mobile/app/themes/hobbies/hobbies_colors.dart';
import 'package:andril_mobile/app/themes/hobbies/hobbies_theme.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/entities/hobbies_media.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/repositories/hobbies_gallery_repository.dart';
import 'package:andril_mobile/features/hobbies/gallery/domain/usecases/get_hobbies_gallery_media_usecase.dart';
import 'package:andril_mobile/features/hobbies/gallery/presentation/viewmodels/hobbies_gallery_viewmodel.dart';
import 'package:andril_mobile/features/hobbies/gallery/presentation/widgets/hobbies_gallery_binding.dart';
import 'package:andril_mobile/features/hobbies/presentation/screens/hobbies_gallery_screen.dart';

/// Test access policy implementation for verifying static route guards.
class _TestHobbiesAccessPolicy implements HobbiesAccessPolicy {
  @override
  final bool isAuthenticated;

  @override
  final bool isHobbiesActivated;

  const _TestHobbiesAccessPolicy({
    required this.isAuthenticated,
    required this.isHobbiesActivated,
  });
}

/// Reactive test access policy for verifying runtime session/access changes.
class _MutableReactiveHobbiesAccessPolicy extends ChangeNotifier
    implements HobbiesAccessPolicy {
  @override
  bool isAuthenticated;

  @override
  bool isHobbiesActivated;

  _MutableReactiveHobbiesAccessPolicy({
    required this.isAuthenticated,
    required this.isHobbiesActivated,
  });

  void setAuthenticated(bool value) {
    if (isAuthenticated != value) {
      isAuthenticated = value;
      notifyListeners();
    }
  }

  void setHobbiesActivated(bool value) {
    if (isHobbiesActivated != value) {
      isHobbiesActivated = value;
      notifyListeners();
    }
  }
}

/// Fake repository for simulating media retrieval in routing tests.
class _FakeHobbiesGalleryRepository implements HobbiesGalleryRepository {
  List<HobbiesMedia> mediaToReturn;
  Completer<List<HobbiesMedia>>? completer;
  int callCount = 0;

  _FakeHobbiesGalleryRepository({
    List<HobbiesMedia>? media,
    this.completer,
  }) : mediaToReturn = media ?? <HobbiesMedia>[];

  @override
  Future<List<HobbiesMedia>> listMedia() async {
    callCount++;
    if (completer != null) {
      return completer!.future;
    }
    return mediaToReturn;
  }
}

Widget _buildHobbiesRouterApp(GoRouter router) {
  return MaterialApp.router(
    theme: HobbiesTheme.lightTheme,
    routerConfig: router,
  );
}

void main() {
  group('HobbiesRouter (M3-CP-02C-07-R01)', () {
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
      title: 'Bonsai Pruning Technique',
      caption: 'Japanese maple shaping.',
      mediaUrl: 'https://cdn.example.internal/media/bonsai.jpg',
      hobbyTag: 'Gardening',
      createdAt: testDate,
    );

    const authorizedPolicy = _TestHobbiesAccessPolicy(
      isAuthenticated: true,
      isHobbiesActivated: true,
    );

    // -------------------------------------------------------------------------
    // 1. Gallery route registration
    // -------------------------------------------------------------------------
    testWidgets('1. Gallery route registration resolves successfully',
        (WidgetTester tester) async {
      final fakeRepo =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);

      final router = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: HobbiesRoutes.gallery,
        galleryViewModelBuilder: () => HobbiesGalleryViewModel(useCase),
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          HobbiesRoutes.gallery);
      expect(find.byType(HobbiesGalleryBinding), findsOneWidget);
      expect(find.byType(HobbiesGalleryScreen), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 2. Authorized Hobbies navigation opens Gallery Binding
    // -------------------------------------------------------------------------
    testWidgets('2. Authorized Hobbies navigation opens Gallery Binding',
        (WidgetTester tester) async {
      final fakeRepo =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);

      final router = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: HobbiesRoutes.home,
        galleryViewModelBuilder: () => HobbiesGalleryViewModel(useCase),
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      expect(
          router.routeInformationProvider.value.uri.path, HobbiesRoutes.home);
      expect(find.text('Hobbies Home'), findsOneWidget);
      final galleryCardFinder =
          find.byKey(const Key('hobbies_home_gallery_card'));
      expect(galleryCardFinder, findsOneWidget);

      // Tap on the Photo Gallery card
      await tester.tap(galleryCardFinder);
      await tester.pumpAndSettle();

      // Verify Gallery Binding is displayed after tapping
      final bindingFinder = find.byType(HobbiesGalleryBinding);
      expect(bindingFinder, findsOneWidget);

      // Verify active Gallery route via GoRouterState obtained from the Gallery widget context
      final BuildContext galleryContext = tester.element(bindingFinder);
      final GoRouterState galleryState = GoRouterState.of(galleryContext);
      expect(galleryState.matchedLocation, equals(HobbiesRoutes.gallery));

      // Verify expected synthetic Gallery media is visible
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);

      // Verify the navigation stack supports returning to Home
      expect(router.canPop(), isTrue);
      expect(Navigator.canPop(galleryContext), isTrue);
    });

    // -------------------------------------------------------------------------
    // 3. Back navigation returns correctly
    // -------------------------------------------------------------------------
    testWidgets('3. Back navigation returns correctly to Hobbies Home',
        (WidgetTester tester) async {
      final fakeRepo =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);

      final router = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: HobbiesRoutes.home,
        galleryViewModelBuilder: () => HobbiesGalleryViewModel(useCase),
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      // Navigate to gallery via push from Hobbies Home
      await tester.tap(find.byKey(const Key('hobbies_home_gallery_card')));
      await tester.pumpAndSettle();

      // Verify Gallery opens successfully
      final bindingFinder = find.byType(HobbiesGalleryBinding);
      expect(bindingFinder, findsOneWidget);

      // Verify active Gallery route via GoRouterState obtained from the Gallery widget context
      final BuildContext galleryContext = tester.element(bindingFinder);
      final GoRouterState galleryState = GoRouterState.of(galleryContext);
      expect(galleryState.matchedLocation, equals(HobbiesRoutes.gallery));
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);

      // Verify BackButton is visible
      final backButtonFinder = find.byType(BackButton);
      expect(backButtonFinder, findsOneWidget);

      // Tap the AppBar leading back button
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      // Verify tapping BackButton returns to Hobbies Home
      expect(
          router.routeInformationProvider.value.uri.path, HobbiesRoutes.home);
      expect(find.text('Hobbies Home'), findsOneWidget);

      // Verify Gallery Binding and previous Gallery media are removed
      expect(find.byType(HobbiesGalleryBinding), findsNothing);
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 4. Inactive or unauthorized Hobbies access does not expose Gallery media
    // -------------------------------------------------------------------------
    testWidgets(
        '4. Inactive or unauthorized Hobbies access does not expose media',
        (WidgetTester tester) async {
      final fakeRepo =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);

      // 4a. Unauthenticated access fails closed to welcome screen
      const unauthPolicy = _TestHobbiesAccessPolicy(
        isAuthenticated: false,
        isHobbiesActivated: false,
      );

      final unauthRouter = createHobbiesRouter(
        accessPolicy: unauthPolicy,
        initialLocation: HobbiesRoutes.gallery,
        galleryViewModelBuilder: () => HobbiesGalleryViewModel(useCase),
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(unauthRouter));
      await tester.pumpAndSettle();

      expect(unauthRouter.routeInformationProvider.value.uri.path,
          HobbiesRoutes.welcome);
      expect(find.byType(HobbiesGalleryBinding), findsNothing);
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      expect(fakeRepo.callCount, equals(0));

      // 4b. Authenticated but unactivated access fails closed to access-denied screen
      const unactivatedPolicy = _TestHobbiesAccessPolicy(
        isAuthenticated: true,
        isHobbiesActivated: false,
      );

      final unactivatedRouter = createHobbiesRouter(
        accessPolicy: unactivatedPolicy,
        initialLocation: HobbiesRoutes.gallery,
        galleryViewModelBuilder: () => HobbiesGalleryViewModel(useCase),
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(unactivatedRouter));
      await tester.pumpAndSettle();

      expect(unactivatedRouter.routeInformationProvider.value.uri.path,
          HobbiesRoutes.accessDenied);
      expect(find.byType(HobbiesGalleryBinding), findsNothing);
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      expect(fakeRepo.callCount, equals(0));
    });

    // -------------------------------------------------------------------------
    // 5. Missing required dependencies fail closed without fabricated data
    // -------------------------------------------------------------------------
    testWidgets(
        '5. Missing required dependencies fail closed without fabricated data',
        (WidgetTester tester) async {
      // No galleryViewModelBuilder provided
      final router = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: HobbiesRoutes.gallery,
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          HobbiesRoutes.gallery);
      // Must render pending screen, not crash or fabricate mock fixtures
      expect(find.text('Gallery Integration Pending'), findsOneWidget);
      expect(find.byType(HobbiesGalleryBinding), findsNothing);
      expect(find.text('Mock Photo'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 6. Initial retrieval occurs once
    // -------------------------------------------------------------------------
    testWidgets('6. Initial retrieval occurs exactly once upon entering route',
        (WidgetTester tester) async {
      final fakeRepo =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);

      final router = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: HobbiesRoutes.gallery,
        galleryViewModelBuilder: () => HobbiesGalleryViewModel(useCase),
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      expect(fakeRepo.callCount, equals(1));
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 7. Parent rebuilds do not trigger duplicate retrieval
    // -------------------------------------------------------------------------
    testWidgets('7. Parent rebuilds do not trigger duplicate retrieval',
        (WidgetTester tester) async {
      final fakeRepo =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);

      final router = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: HobbiesRoutes.gallery,
        galleryViewModelBuilder: () => HobbiesGalleryViewModel(useCase),
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();
      expect(fakeRepo.callCount, equals(1));

      // Trigger parent widget rebuild
      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      expect(fakeRepo.callCount, equals(1));
    });

    // -------------------------------------------------------------------------
    // 8. Route-owned ViewModel disposal is correct where applicable
    // -------------------------------------------------------------------------
    testWidgets('8. Route-owned ViewModel disposal occurs on route unmount',
        (WidgetTester tester) async {
      final fakeRepo =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      HobbiesGalleryViewModel? createdViewModel;

      final router = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: HobbiesRoutes.gallery,
        galleryViewModelBuilder: () {
          createdViewModel = HobbiesGalleryViewModel(useCase);
          return createdViewModel!;
        },
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();
      expect(createdViewModel, isNotNull);
      expect(createdViewModel!.isDisposed, isFalse);

      // Navigate away from the route
      router.go(HobbiesRoutes.home);
      await tester.pumpAndSettle();

      // Route-owned ViewModel must be disposed
      expect(createdViewModel!.isDisposed, isTrue);
    });

    // -------------------------------------------------------------------------
    // 9. Arbitrary state.extra ViewModel is ignored and cannot supply private media
    // -------------------------------------------------------------------------
    testWidgets(
        '9. Arbitrary state.extra ViewModel is ignored and cannot supply private media',
        (WidgetTester tester) async {
      final trustedRepo =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final trustedUseCase = GetHobbiesGalleryMediaUseCase(trustedRepo);

      final untrustedRepo =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem2]);
      final untrustedUseCase = GetHobbiesGalleryMediaUseCase(untrustedRepo);
      final untrustedViewModel = HobbiesGalleryViewModel(untrustedUseCase);

      // 9a. With trusted builder present, state.extra is ignored in favor of builder
      final routerWithBuilder = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: HobbiesRoutes.home,
        galleryViewModelBuilder: () => HobbiesGalleryViewModel(trustedUseCase),
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(routerWithBuilder));
      await tester.pumpAndSettle();

      // Attempt to push gallery supplying arbitrary ViewModel via extra
      routerWithBuilder.push(HobbiesRoutes.gallery, extra: untrustedViewModel);
      await tester.pumpAndSettle();

      // Trusted media from builder appears; untrusted extra media NEVER appears
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);
      expect(find.text('Bonsai Pruning Technique'), findsNothing);
      expect(untrustedRepo.callCount, equals(0));

      // 9b. Without trusted builder, passing state.extra still fails closed to pending screen
      final routerWithoutBuilder = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: HobbiesRoutes.home,
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(routerWithoutBuilder));
      await tester.pumpAndSettle();

      routerWithoutBuilder.push(HobbiesRoutes.gallery,
          extra: untrustedViewModel);
      await tester.pumpAndSettle();

      // Displays safe pending screen; arbitrary ViewModel is ignored
      expect(find.text('Gallery Integration Pending'), findsOneWidget);
      expect(find.byType(HobbiesGalleryBinding), findsNothing);
      expect(find.text('Bonsai Pruning Technique'), findsNothing);
      expect(untrustedRepo.callCount, equals(0));

      untrustedViewModel.dispose();
    });

    // -------------------------------------------------------------------------
    // 10. Reopening the Gallery does not expose stale profile media
    // -------------------------------------------------------------------------
    testWidgets(
        '10. Reopening the Gallery produces fresh instance without stale data',
        (WidgetTester tester) async {
      int instanceCount = 0;
      final fakeRepo1 =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final useCase1 = GetHobbiesGalleryMediaUseCase(fakeRepo1);

      final fakeRepo2 =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem2]);
      final useCase2 = GetHobbiesGalleryMediaUseCase(fakeRepo2);

      final router = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: HobbiesRoutes.home,
        galleryViewModelBuilder: () {
          instanceCount++;
          if (instanceCount == 1) {
            return HobbiesGalleryViewModel(useCase1);
          } else {
            return HobbiesGalleryViewModel(useCase2);
          }
        },
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      // First visit to Gallery
      router.go(HobbiesRoutes.gallery);
      await tester.pumpAndSettle();
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);
      expect(find.text('Bonsai Pruning Technique'), findsNothing);

      // Leave Gallery
      router.go(HobbiesRoutes.home);
      await tester.pumpAndSettle();

      // Second visit to Gallery (simulating profile switch or fresh session)
      router.go(HobbiesRoutes.gallery);
      await tester.pumpAndSettle();
      expect(find.text('Bonsai Pruning Technique'), findsOneWidget);
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 11. Existing Hobbies navigation remains functional
    // -------------------------------------------------------------------------
    testWidgets(
        '11. Existing Hobbies navigation destinations remain functional',
        (WidgetTester tester) async {
      final router = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: HobbiesRoutes.welcome,
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      // Welcome screen renders
      expect(find.text('Welcome to Hobbies'), findsOneWidget);
      expect(find.byKey(const Key('hobbies_welcome_continue_button')),
          findsOneWidget);

      // Tap enter
      await tester
          .tap(find.byKey(const Key('hobbies_welcome_continue_button')));
      await tester.pumpAndSettle();

      // Resolves to Hobbies Home
      expect(
          router.routeInformationProvider.value.uri.path, HobbiesRoutes.home);
      expect(find.text('Hobbies Home'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 12. No cross-module route or profile-data leakage
    // -------------------------------------------------------------------------
    testWidgets('12. Non-hobbies locations fail closed to Hobbies Welcome',
        (WidgetTester tester) async {
      final router = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/home',
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      // Non-hobbies path is isolated and redirected to Hobbies Welcome
      expect(router.routeInformationProvider.value.uri.path,
          HobbiesRoutes.welcome);
      expect(find.text('Learning Home'), findsNothing);
      expect(find.text('Welcome to Hobbies'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 13. Safe behavior when the backend integration is unavailable
    // -------------------------------------------------------------------------
    testWidgets(
        '13. Production policy fails closed pending backend integration',
        (WidgetTester tester) async {
      const prodPolicy = ProductionHobbiesAccessPolicy();
      expect(prodPolicy.isAuthenticated, isFalse);
      expect(prodPolicy.isHobbiesActivated, isFalse);

      final router = createHobbiesRouter(
        accessPolicy: prodPolicy,
        initialLocation: HobbiesRoutes.home,
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      // Protected home route redirects to welcome under production default policy
      expect(router.routeInformationProvider.value.uri.path,
          HobbiesRoutes.welcome);
      expect(find.text('Welcome to Hobbies'), findsOneWidget);
      expect(find.text('Hobbies Home'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 14. Welcome button achieves required WCAG AA normal-text contrast (>= 4.5:1)
    // -------------------------------------------------------------------------
    testWidgets('14. Welcome button achieves required WCAG AA contrast',
        (WidgetTester tester) async {
      final router = createHobbiesRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: HobbiesRoutes.welcome,
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      // Find the welcome continue button
      final buttonFinder =
          find.byKey(const Key('hobbies_welcome_continue_button'));
      expect(buttonFinder, findsOneWidget);
      final FilledButton buttonWidget =
          tester.widget<FilledButton>(buttonFinder);

      // Resolve the actual enabled-state button colors without fallbacks
      final Color? background =
          buttonWidget.style?.backgroundColor?.resolve(<WidgetState>{});
      final Color? foreground =
          buttonWidget.style?.foregroundColor?.resolve(<WidgetState>{});

      // Assert both resolved colors are non-null before evaluating their values
      expect(background, isNotNull);
      expect(foreground, isNotNull);

      // Verify exact theme token adherence
      expect(background, equals(HobbiesColors.primary));
      expect(foreground, equals(HobbiesTheme.textDark));

      // Calculate contrast ratio using Flutter Color.computeLuminance()
      final double l1 = background!.computeLuminance();
      final double l2 = foreground!.computeLuminance();
      final double contrastRatio =
          (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);

      // WCAG AA requirement for normal text is at least 4.5:1
      expect(contrastRatio, greaterThanOrEqualTo(4.5));
    });

    // -------------------------------------------------------------------------
    // 15. Reactive access invalidation: Logout while Gallery is open
    // -------------------------------------------------------------------------
    testWidgets(
        '15. Logout while Gallery is open immediately removes protected content',
        (WidgetTester tester) async {
      final fakeRepo =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      HobbiesGalleryViewModel? createdViewModel;

      final reactivePolicy = _MutableReactiveHobbiesAccessPolicy(
        isAuthenticated: true,
        isHobbiesActivated: true,
      );

      final router = createHobbiesRouter(
        accessPolicy: reactivePolicy,
        initialLocation: HobbiesRoutes.gallery,
        galleryViewModelBuilder: () {
          createdViewModel = HobbiesGalleryViewModel(useCase);
          return createdViewModel!;
        },
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          HobbiesRoutes.gallery);
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);
      expect(createdViewModel!.isDisposed, isFalse);

      // Trigger user logout while Gallery is currently mounted
      reactivePolicy.setAuthenticated(false);
      await tester.pumpAndSettle();

      // Must fail closed to welcome, removing protected content immediately
      expect(router.routeInformationProvider.value.uri.path,
          HobbiesRoutes.welcome);
      expect(find.byType(HobbiesGalleryBinding), findsNothing);
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      expect(find.text('Welcome to Hobbies'), findsOneWidget);
      // Route unmount must dispose the route-owned ViewModel
      expect(createdViewModel!.isDisposed, isTrue);
    });

    // -------------------------------------------------------------------------
    // 16. Reactive access invalidation: Module deactivation while Gallery is open
    // -------------------------------------------------------------------------
    testWidgets(
        '16. Module deactivation while Gallery is open immediately invalidates access',
        (WidgetTester tester) async {
      final fakeRepo =
          _FakeHobbiesGalleryRepository(media: <HobbiesMedia>[testItem1]);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);
      HobbiesGalleryViewModel? createdViewModel;

      final reactivePolicy = _MutableReactiveHobbiesAccessPolicy(
        isAuthenticated: true,
        isHobbiesActivated: true,
      );

      final router = createHobbiesRouter(
        accessPolicy: reactivePolicy,
        initialLocation: HobbiesRoutes.gallery,
        galleryViewModelBuilder: () {
          createdViewModel = HobbiesGalleryViewModel(useCase);
          return createdViewModel!;
        },
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          HobbiesRoutes.gallery);
      expect(find.text('Ceramic Glazing Workshop'), findsOneWidget);

      // Trigger Hobbies module deactivation
      reactivePolicy.setHobbiesActivated(false);
      await tester.pumpAndSettle();

      // Must fail closed to access denied screen
      expect(router.routeInformationProvider.value.uri.path,
          HobbiesRoutes.accessDenied);
      expect(find.byType(HobbiesGalleryBinding), findsNothing);
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      expect(find.text('Hobbies Profile Inactive'), findsOneWidget);
      expect(createdViewModel!.isDisposed, isTrue);
    });

    // -------------------------------------------------------------------------
    // 17. Delayed media responses after access invalidation are safely dropped
    // -------------------------------------------------------------------------
    testWidgets(
        '17. Stale delayed media responses after access invalidation are dropped',
        (WidgetTester tester) async {
      final completer = Completer<List<HobbiesMedia>>();
      final fakeRepo = _FakeHobbiesGalleryRepository(completer: completer);
      final useCase = GetHobbiesGalleryMediaUseCase(fakeRepo);

      final reactivePolicy = _MutableReactiveHobbiesAccessPolicy(
        isAuthenticated: true,
        isHobbiesActivated: true,
      );

      final router = createHobbiesRouter(
        accessPolicy: reactivePolicy,
        initialLocation: HobbiesRoutes.gallery,
        galleryViewModelBuilder: () => HobbiesGalleryViewModel(useCase),
      );

      await tester.pumpWidget(_buildHobbiesRouterApp(router));
      // Single frame pump: request is in-flight
      await tester.pump();
      expect(fakeRepo.callCount, equals(1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Identity session invalidated while request is in-flight
      reactivePolicy.setAuthenticated(false);
      await tester.pumpAndSettle();

      // Redirected to Welcome
      expect(router.routeInformationProvider.value.uri.path,
          HobbiesRoutes.welcome);
      expect(find.byType(HobbiesGalleryBinding), findsNothing);

      // Complete delayed response after unmount
      completer.complete(<HobbiesMedia>[testItem1]);
      await tester.pumpAndSettle();

      // Must complete without exceptions and never leak or render media
      expect(tester.takeException(), isNull);
      expect(find.text('Ceramic Glazing Workshop'), findsNothing);
      expect(find.text('Welcome to Hobbies'), findsOneWidget);
    });
  });
}
