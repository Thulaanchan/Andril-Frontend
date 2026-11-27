import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:andril_mobile/app/dependencies/registrations/learning/learning_dependencies.dart';
import 'package:andril_mobile/app/router/learning_router.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/circles/presentation/screens/learning_circles_hub_screen.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_editor_screen.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/presentation/screens/my_growth_dashboard_screen.dart';
import 'package:andril_mobile/features/learning/pacts/presentation/screens/learning_pacts_hub_screen.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/presentation/screens/portfolio_editor_screen.dart';
import 'package:andril_mobile/features/learning/profile/screens/learning_onboarding_screen.dart';
import 'package:andril_mobile/features/learning/profile/screens/learning_welcome_screen.dart';

import '../shared_core/authentication/foundation_fakes.dart';

class _FakeSessionSource extends FakeSessionSource
    implements BackendSessionSource {
  _FakeSessionSource({this.initialSubject = 'test-learner'})
      : super(
          restored: SessionEvent(
            SessionEventKind.initial,
            subject: initialSubject,
          ),
        );

  final String? initialSubject;

  @override
  BackendCredential? backendCredential = const BackendCredential(
    'test-learner',
    'fake.jwt.token',
    emailConfirmed: true,
  );

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}
}

Widget _buildTestApp(GoRouter router) {
  return MaterialApp.router(
    theme: LearningTheme.theme,
    routerConfig: router,
  );
}

class _ExplicitAccessPolicy implements LearningAccessPolicy {
  @override
  final bool isAuthenticated;
  @override
  final bool isLearningActivated;

  const _ExplicitAccessPolicy({
    required this.isAuthenticated,
    required this.isLearningActivated,
  });
}

void main() {
  group('Task 05-10: Learning Navigation, Security & E2E QA', () {
    testWidgets(
        '1. Unauthenticated navigation to /learning/home redirects to Welcome screen',
        (tester) async {
      const unauthPolicy = _ExplicitAccessPolicy(
        isAuthenticated: false,
        isLearningActivated: false,
      );

      final router = createLearningRouter(
        accessPolicy: unauthPolicy,
        initialLocation: '/learning/home',
      );

      await tester.pumpWidget(_buildTestApp(router));
      await tester.pumpAndSettle();

      expect(
          router.routeInformationProvider.value.uri.path, '/learning/welcome');
      expect(find.byType(LearningWelcomeScreen), findsOneWidget);
    });

    testWidgets(
        '2. Authenticated but unactivated navigation redirects to Access Denied',
        (tester) async {
      const unactivatedPolicy = _ExplicitAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: false,
      );

      final router = createLearningRouter(
        accessPolicy: unactivatedPolicy,
        initialLocation: '/learning/home',
      );

      await tester.pumpWidget(_buildTestApp(router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          '/learning/access-denied');
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('3. Authenticated user can access /learning/onboarding',
        (tester) async {
      const authUnactivatedPolicy = _ExplicitAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: false,
      );

      final router = createLearningRouter(
        accessPolicy: authUnactivatedPolicy,
        initialLocation: '/learning/onboarding',
      );

      await tester.pumpWidget(_buildTestApp(router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          '/learning/onboarding');
      expect(find.byType(LearningOnboardingScreen), findsOneWidget);
    });

    testWidgets(
        '4. Module isolation: non-learning location redirects to Welcome screen',
        (tester) async {
      const unauthPolicy = _ExplicitAccessPolicy(
        isAuthenticated: false,
        isLearningActivated: false,
      );

      final router = createLearningRouter(
        accessPolicy: unauthPolicy,
        initialLocation: '/social/feed',
      );

      await tester.pumpWidget(_buildTestApp(router));
      await tester.pumpAndSettle();

      expect(
          router.routeInformationProvider.value.uri.path, '/learning/welcome');
      expect(find.byType(LearningWelcomeScreen), findsOneWidget);
    });

    testWidgets(
        '5. Authorized navigation routes render completed Learning screens',
        (tester) async {
      const authorizedPolicy = _ExplicitAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );

      final routesToVerify = [
        ('/learning/circles', LearningCirclesHubScreen),
        ('/learning/pacts', LearningPactsHubScreen),
        ('/learning/growth', MyGrowthDashboardScreen),
        ('/learning/cv-maker', CvEditorScreen),
        ('/learning/portfolio-maker', PortfolioEditorScreen),
      ];

      for (final (path, widgetType) in routesToVerify) {
        final router = createLearningRouter(
          accessPolicy: authorizedPolicy,
          initialLocation: path,
        );

        await tester.pumpWidget(_buildTestApp(router));
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, path);
        expect(find.byType(widgetType), findsOneWidget);
      }
    });

    test('6. SessionLearningAccessPolicy enforces M2 admission rules',
        () async {
      final source = _FakeSessionSource();
      final session = SessionController(source);
      await session.start();

      final policy = SessionLearningAccessPolicy(session);

      // In initial state, user is signed in, but moduleHomeAuthorized is false
      expect(policy.isAuthenticated, isTrue);
      expect(policy.isLearningActivated, isFalse);

      session.dispose();
      await source.signals.close();
    });

    test(
        '7. LearningDependenciesScope cleans up private state upon session clearer callback',
        () async {
      final source = _FakeSessionSource();
      final session = SessionController(source);
      await session.start();

      final scope = LearningDependenciesScope(sessionController: session);

      // Verify lazy getters work before disposal
      expect(scope.isDisposed, isFalse);
      expect(scope.portfolioCvImportService, isNotNull);
      expect(scope.circlesViewModel, isNotNull);

      // Trigger session clearer (e.g. sign-out or session revocation)
      scope.dispose();

      expect(scope.isDisposed, isTrue);
      expect(scope.remoteDataSource, isNull);
      expect(scope.setupRepository, isNull);
      expect(scope.profileRepository, isNull);

      // Subsequent disposal call is idempotent
      expect(() => scope.dispose(), returnsNormally);

      session.dispose();
      await source.signals.close();
    });

    test(
        '8. Unicode and multilingual characters are preserved across portfolio and CV models',
        () {
      const unicodeTitle =
          'මගේ නව ව්‍යාපෘතිය (My New Project) - என் திட்டம் 🚀';
      const unicodeDesc =
          'Flutter アプリケーション開発テスト。Advanced unicode verification with emojis: ✨🔥';

      const project = PortfolioProject(
        id: 'proj-unicode-1',
        title: unicodeTitle,
        description: unicodeDesc,
      );

      final portfolio = LearningPortfolio(
        id: 'port-1',
        ownerLearningProfileId: 'learner-1',
        title: 'Portfolio 🌟',
        projects: const [project],
        updatedAt: DateTime(2026, 11, 27),
      );

      expect(portfolio.projects.first.title, unicodeTitle);
      expect(portfolio.projects.first.description, unicodeDesc);
      expect(portfolio.module, 'learning');
    });
  });
}
