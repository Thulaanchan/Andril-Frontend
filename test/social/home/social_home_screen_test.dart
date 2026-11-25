import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/andril_module_app_bar.dart';
import 'package:andril_mobile/features/social/home/screens/social_home_screen.dart';
import 'package:andril_mobile/features/social/home/viewmodels/social_home_viewmodel.dart';

void main() {
  group('SocialHomeScreen Widget & Responsive Tests (M5-FE-S21-UI-01)', () {
    testWidgets('renders all initial S21 components without overflow at 400x800', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final vm = SocialHomeViewModel(
        initialDisplayName: 'Amara K.',
        initialUnreadNotifications: 2,
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

      // Verify Recommendations Section
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

    testWidgets('renders responsive layout at 320x640 (small screen) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final vm = SocialHomeViewModel(initialDisplayName: 'TestUser');
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(0.55),
            ),
            child: SocialHomeScreen(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AndrilModuleAppBar), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('renders responsive layout at 800x1200 (tablet/desktop) without overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final vm = SocialHomeViewModel(initialDisplayName: 'TabletUser');
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 1200),
            ),
            child: SocialHomeScreen(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AndrilModuleAppBar), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('tapping 2x2 action card dispatches onQuickAction', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SocialHomeActionId? tappedAction;
      final vm = SocialHomeViewModel();
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

    testWidgets('tapping Explore People button triggers onExplorePeople', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var exploreTapped = false;
      final vm = SocialHomeViewModel();
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

    testWidgets('tapping View profile on recommendation card dispatches onViewProfile with userId', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? viewedId;
      final vm = SocialHomeViewModel();
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialHomeScreen(
            viewModel: vm,
            onViewProfile: (id) => viewedId = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstViewButton = find.text('View').first;
      await tester.tap(firstViewButton);
      await tester.pumpAndSettle();

      expect(viewedId, 'rec_01');
    });

    testWidgets('renders Access Restricted view when unauthorized', (tester) async {
      final vm = SocialHomeViewModel(isSocialOptedIn: false);
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialHomeScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Quick Actions'), findsNothing);
    });
  });
}
