import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/andril_module_app_bar.dart';
import 'package:andril_mobile/features/social/home/screens/social_home_screen.dart';
import 'package:andril_mobile/features/social/home/viewmodels/social_home_viewmodel.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';

class FakeScreenSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _stubPhase;
  final String? _subject;

  FakeScreenSessionController({
    SessionPhase phase = SessionPhase.signedIn,
    String? subject = 'user_fixture_01',
  })  : _stubPhase = phase,
        _subject = subject;

  @override
  SessionPhase get phase => _stubPhase;

  @override
  String? get subject => _subject;

  @override
  bool get moduleHomeAuthorized => false;

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clear) => () {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SocialHomeScreen Widget & Accessibility Tests (M5-FE-S21-UI-04)', () {
    testWidgets('renders all authorized S21 components at standard 400x800 without overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeSession = FakeScreenSessionController(phase: SessionPhase.signedIn);
      const fixtureRecommendations = [
        SocialRecommendedPerson(
          id: 'rec_fixture_01',
          displayName: 'Nivetha R.',
          location: 'Kandy',
        ),
      ];

      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user_fixture_01'),
        initialDisplayName: 'Amara K.',
        initialUnreadNotifications: 2,
        initialRecommendations: fixtureRecommendations,
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              textScaler: TextScaler.noScaling,
            ),
            child: SocialHomeScreen(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Verify Header & Module Bar
      expect(find.byType(AndrilModuleAppBar), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Welcome back,'), findsOneWidget);
      expect(find.text('Amara K.'), findsOneWidget);

      // Verify Hero Banner
      expect(find.text('Discover Meaningful\nConnections'), findsOneWidget);
      expect(find.text('Explore People'), findsOneWidget);

      // Verify 2x2 Quick Action Grid
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('My Connections'), findsOneWidget);
      expect(find.text('Andril Diary'), findsOneWidget);
      expect(find.text('Personality'), findsOneWidget);
      expect(find.text('Saved Profiles'), findsOneWidget);

      // Verify Recommendations Section with fixture profile
      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.text('Nivetha R.'), findsOneWidget);
      expect(find.text('View'), findsWidgets);

      // Verify 5-Destination Navigation Bar
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Zones'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('renders cleanly on small screen 320x640 at TextScaler 1.0 without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeSession = FakeScreenSessionController(phase: SessionPhase.signedIn);
      const fixtureRecommendations = [
        SocialRecommendedPerson(
          id: 'rec_fixture_01',
          displayName: 'Nivetha R.',
          location: 'Kandy',
        ),
      ];

      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user_fixture_01'),
        initialDisplayName: 'Amara K.',
        initialRecommendations: fixtureRecommendations,
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.noScaling,
            ),
            child: SocialHomeScreen(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Explore People'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('renders cleanly on small screen 320x640 with accessibility scaling (1.3) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeSession = FakeScreenSessionController(phase: SessionPhase.signedIn);
      const fixtureRecommendations = [
        SocialRecommendedPerson(
          id: 'rec_fixture_01',
          displayName: 'Nivetha R.',
          location: 'Kandy',
        ),
      ];

      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user_fixture_01'),
        initialDisplayName: 'Amara K.',
        initialRecommendations: fixtureRecommendations,
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: SocialHomeScreen(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Explore People'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('renders cleanly on tablet 800x1200 at TextScaler 1.0 without overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeSession = FakeScreenSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user_fixture_01'),
        initialDisplayName: 'TabletUser',
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 1200),
              textScaler: TextScaler.noScaling,
            ),
            child: SocialHomeScreen(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('tapping 2x2 action card dispatches onQuickAction when authorized', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SocialHomeActionId? tappedAction;
      final fakeSession = FakeScreenSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user_fixture_01'),
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialHomeScreen(
            viewModel: vm,
            onQuickAction: (action) => tappedAction = action,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Connections'));
      await tester.pumpAndSettle();
      expect(tappedAction, SocialHomeActionId.myConnections);

      await tester.tap(find.text('Andril Diary'));
      await tester.pumpAndSettle();
      expect(tappedAction, SocialHomeActionId.andrilDiary);
    });

    testWidgets('tapping Explore People button triggers onExplorePeople when authorized', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var exploreTapped = false;
      final fakeSession = FakeScreenSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user_fixture_01'),
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialHomeScreen(
            viewModel: vm,
            onExplorePeople: () => exploreTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explore People'));
      await tester.pumpAndSettle();
      expect(exploreTapped, isTrue);
    });
  });
}
