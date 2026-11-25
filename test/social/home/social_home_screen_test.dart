import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/andril_module_app_bar.dart';
import 'package:andril_mobile/features/social/home/screens/social_home_screen.dart';
import 'package:andril_mobile/features/social/home/viewmodels/social_home_viewmodel.dart';

class FakeScreenSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _stubPhase;

  FakeScreenSessionController({SessionPhase phase = SessionPhase.signedIn})
      : _stubPhase = phase;

  @override
  SessionPhase get phase => _stubPhase;

  @override
  bool get moduleHomeAuthorized => false;

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clear) => () {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SocialHomeScreen Widget & Security Tests (M5-FE-S21-SEC-01)', () {
    testWidgets('renders Access Restricted view when unauthorized (fails closed)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Default ViewModel fails closed
      final vm = SocialHomeViewModel();
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialHomeScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('You must be signed in and opted in to the Social module to access Social Home.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      // NavigationBar is hidden when access is restricted
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('renders all authorized S21 components when authorized via test fixture', (tester) async {
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
        isSocialOptedIn: true,
        isTestAuthorized: true,
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
              textScaler: TextScaler.linear(0.8),
            ),
            child: SocialHomeScreen(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

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

      // Verify Navigation Bar
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Connections'), findsOneWidget);
      expect(find.text('Chats'), findsOneWidget);
    });

    testWidgets('empty recommendations feed renders cleanly without errors', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeSession = FakeScreenSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        isTestAuthorized: true,
        initialDisplayName: 'Amara K.',
        initialRecommendations: const [],
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              textScaler: TextScaler.linear(0.8),
            ),
            child: SocialHomeScreen(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Recommended for you'), findsNothing);
      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('tapping 2x2 action card dispatches onQuickAction when authorized', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SocialHomeActionId? tappedAction;
      final fakeSession = FakeScreenSessionController(phase: SessionPhase.signedIn);
      final vm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        isTestAuthorized: true,
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
        isSocialOptedIn: true,
        isTestAuthorized: true,
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
