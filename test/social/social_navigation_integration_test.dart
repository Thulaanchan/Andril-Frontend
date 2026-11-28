import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/dependencies/registrations/social/social_dependencies.dart';
import 'package:andril_mobile/app/router/routes/social/social_router.dart';
import 'package:andril_mobile/app/router/routes/social/social_routes.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/home/screens/social_shell_screen.dart';
import 'package:andril_mobile/features/social/home/widgets/social_prototype_navigation.dart';
import 'package:andril_mobile/features/social/home/widgets/social_shared_feature_entry.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';

class _MockSessionController extends ChangeNotifier
    implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject = 'user-test-subject';
  final List<VoidCallback> _clearers = [];

  @override
  SessionPhase get phase => _phase;

  set phase(SessionPhase value) {
    _phase = value;
    notifyListeners();
  }

  @override
  String? get subject => _subject;

  set subject(String? value) {
    _subject = value;
    notifyListeners();
  }

  void signOut() {
    _phase = SessionPhase.signedOut;
    _subject = null;
    for (final c in _clearers) {
      c();
    }
    notifyListeners();
  }

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) {
    _clearers.add(clearer);
    return () => _clearers.remove(clearer);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSessionController session;
  late SocialDependenciesScope scope;
  final evidence = SocialAccessEvidence.authorized(userId: 'user-test-subject');

  setUp(() {
    session = _MockSessionController();
    scope = SocialDependenciesScope(
      sessionController: session,
      accessEvidence: evidence,
      isSocialOptedIn: true,
    );
  });

  tearDown(() {
    scope.dispose();
    session.dispose();
  });

  group('SocialRouteRegistry Tests (Task 147)', () {
    test('contains all approved M5 screen routes without missing descriptors',
        () {
      expect(SocialRouteRegistry.approvedRoutes.isNotEmpty, isTrue);

      final expectedPaths = [
        SocialRoutes.home,
        SocialRoutes.accessDenied,
        SocialRoutes.discovery,
        SocialRoutes.memberProfile,
        SocialRoutes.memberPhotos,
        SocialRoutes.photoViewer,
        SocialRoutes.savedProfiles,
        SocialRoutes.discoveryFilters,
        SocialRoutes.search,
        SocialRoutes.connections,
        SocialRoutes.likes,
        SocialRoutes.sentLikes,
        SocialRoutes.receivedLikes,
        SocialRoutes.mutualMatch,
        SocialRoutes.matchHistory,
        SocialRoutes.unmatched,
        SocialRoutes.preferences,
        SocialRoutes.discoveryLanguages,
        SocialRoutes.zones,
        SocialRoutes.zoneDiscovery,
        SocialRoutes.zoneDetails,
        SocialRoutes.zoneMembers,
        SocialRoutes.zoneManagement,
        SocialRoutes.zoneModeration,
        SocialRoutes.createZone,
        SocialRoutes.myZones,
        SocialRoutes.personalityIntro,
        SocialRoutes.personalityQuestionnaire,
        SocialRoutes.personalityReview,
        SocialRoutes.personalityAnswers,
        SocialRoutes.smartMatching,
        SocialRoutes.myProfile,
        SocialRoutes.editProfile,
        SocialRoutes.createProfile,
      ];

      for (final p in expectedPaths) {
        final d = SocialRouteRegistry.findByPath(p);
        expect(d, isNotNull,
            reason: 'Route $p must have an approved descriptor');
        expect(SocialRouteRegistry.isApproved(p), isTrue);
        expect(SocialRouteRegistry.isSocialPath(p), isTrue);
      }
    });

    test('correctly rejects unapproved, non-social and pending routes', () {
      expect(SocialRouteRegistry.isApproved('/social/s39-live-room'), isFalse);
      expect(SocialRouteRegistry.isApproved('/social/ai-copilot'), isFalse);
      expect(SocialRouteRegistry.isApproved('/learning/home'), isFalse);
      expect(SocialRouteRegistry.isApproved('/hobbies/home'), isFalse);
      expect(SocialRouteRegistry.isSocialPath('/learning/home'), isFalse);
    });

    test('isGuarded correctly classifies protected vs public routes', () {
      expect(SocialRouteRegistry.isGuarded(SocialRoutes.home), isTrue);
      expect(SocialRouteRegistry.isGuarded(SocialRoutes.discovery), isTrue);
      expect(SocialRouteRegistry.isGuarded(SocialRoutes.zones), isTrue);
      expect(SocialRouteRegistry.isGuarded(SocialRoutes.accessDenied), isFalse);
      expect(SocialRouteRegistry.isGuarded('/social/unknown'), isTrue);
    });
  });

  group('SocialRouter Tests (Task 148)', () {
    testWidgets(
        'unauthorized caller is strictly redirected to AccessDeniedScreen',
        (tester) async {
      final unauthScope = SocialDependenciesScope(
        sessionController: session,
        accessEvidence: null, // No authoritative evidence
        isSocialOptedIn: false,
      );

      final router = SocialRouter(scope: unauthScope);
      final route =
          router.onGenerateRoute(const RouteSettings(name: SocialRoutes.home));

      await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () => Navigator.of(context).push(route),
          child: const Text('Go'),
        );
      })));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(SocialAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);

      unauthScope.dispose();
    });

    testWidgets('unapproved deep links fail closed to AccessDeniedScreen',
        (tester) async {
      final router = SocialRouter(scope: scope);
      final route = router.onGenerateRoute(
          const RouteSettings(name: '/social/unapproved-path'));

      await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () => Navigator.of(context).push(route),
          child: const Text('Go'),
        );
      })));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(SocialAccessDeniedScreen), findsOneWidget);
    });

    testWidgets('authorized caller generates shell route successfully for home',
        (tester) async {
      final router = SocialRouter(scope: scope);
      final route =
          router.onGenerateRoute(const RouteSettings(name: SocialRoutes.home));

      await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () => Navigator.of(context).push(route),
          child: const Text('Go'),
        );
      })));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(SocialShellScreen), findsOneWidget);
    });
  });

  group('SocialShellScreen Navigation Tests (Task 148)', () {
    testWidgets('renders 5 navigation destinations and switches tabs',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) =>
              SocialRouter(scope: scope).onGenerateRoute(settings),
          home: SocialShellScreen(scope: scope),
        ),
      );
      await tester.pumpAndSettle();

      // Check destinations
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Zones'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Switch to Zones
      await tester.tap(find.text('Zones'));
      await tester.pumpAndSettle();

      // Switch to Explore
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();

      // Switch to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Switch back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
    });

    testWidgets('tapping Chat tab opens M4 messaging bottom sheet',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) =>
              SocialRouter(scope: scope).onGenerateRoute(settings),
          home: SocialShellScreen(scope: scope),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(find.text('Social Messaging (M4)'), findsOneWidget);
      expect(find.text('View Connections'), findsOneWidget);
    });

    testWidgets('quick action diary triggers handoff or unavailable dialog',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool diaryHandoffCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) =>
              SocialRouter(scope: scope).onGenerateRoute(settings),
          home: SocialShellScreen(
            scope: scope,
            onDiaryHandoff: () => diaryHandoffCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Andril Diary'));
      await tester.pumpAndSettle();

      expect(diaryHandoffCalled, isTrue);
    });

    testWidgets(
        'fails closed and renders access restricted view when unauthorized',
        (tester) async {
      final unauthScope = SocialDependenciesScope(
        sessionController: session,
        accessEvidence: null,
        isSocialOptedIn: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SocialShellScreen(scope: unauthScope),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.byType(SocialPrototypeNavigation), findsNothing);

      unauthScope.dispose();
    });

    testWidgets('renders cleanly on small viewport (320x640) without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) =>
              SocialRouter(scope: scope).onGenerateRoute(settings),
          home: SocialShellScreen(scope: scope),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SocialSharedFeatureHandoff Tests (Task 149)', () {
    testWidgets(
        'presents unavailable dialog when handoff callback is unconfigured',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SocialSharedFeatureHandoff.invokeHandoff(
                  context: ctx,
                  type: SocialSharedFeatureType.safetyReporting,
                ),
                child: const Text('Report'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();

      expect(find.text('Community Safety & Reporting'), findsOneWidget);
      expect(find.text('M6 Community Safety'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Community Safety & Reporting'), findsNothing);
    });

    testWidgets('invokes delegate callback directly when supplied',
        (tester) async {
      bool handoffInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SocialSharedFeatureHandoff.invokeHandoff(
                  context: ctx,
                  type: SocialSharedFeatureType.accountSettings,
                  onHandoff: () => handoffInvoked = true,
                ),
                child: const Text('Settings'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(handoffInvoked, isTrue);
    });
  });
}
