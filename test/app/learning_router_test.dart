import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:andril_mobile/app/router/learning_router.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/profile/screens/learning_welcome_screen.dart';

class _TestAccessPolicy implements LearningAccessPolicy {
  @override
  final bool isAuthenticated;

  @override
  final bool isLearningActivated;

  const _TestAccessPolicy({
    required this.isAuthenticated,
    required this.isLearningActivated,
  });
}

class _MutableTestAccessPolicy implements LearningAccessPolicy {
  @override
  bool isAuthenticated;

  @override
  bool isLearningActivated;

  _MutableTestAccessPolicy({
    required this.isAuthenticated,
    required this.isLearningActivated,
  });
}

Widget _buildRouterApp(GoRouter router) {
  return MaterialApp.router(
    theme: LearningTheme.theme,
    routerConfig: router,
  );
}

void main() {
  group('LearningRouter - Security & Route Navigation Tests', () {
    // -------------------------------------------------------------------------
    // Baseline Existing Tests (1 - 10)
    // -------------------------------------------------------------------------

    testWidgets('1. Welcome route remains accessible in its intended context',
        (tester) async {
      final router = createLearningRouter(
        initialLocation: '/learning/welcome',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(LearningWelcomeScreen), findsOneWidget);
    });

    testWidgets(
        '2. Each of the five Learning branches resolves correctly in an authorized test fixture',
        (tester) async {
      const authorizedPolicy = _TestAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );

      final testCases = [
        ('/learning/home', 'Learning Home'),
        ('/learning/classrooms', 'Learning Classrooms'),
        ('/learning/explore', 'Learning Explore'),
        ('/learning/chat', 'Learning Chat'),
        ('/learning/profile', 'Learning Profile'),
      ];

      for (final (path, title) in testCases) {
        final router = createLearningRouter(
          accessPolicy: authorizedPolicy,
          initialLocation: path,
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('3. Real runtime does not bypass authentication',
        (tester) async {
      // Default production policy is unauthenticated and unactivated
      final router = createLearningRouter(
        initialLocation: '/learning/home',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      // Protected route /learning/home must fail closed and redirect to Welcome
      expect(find.byType(LearningWelcomeScreen), findsOneWidget);
      expect(find.text('Learning Home'), findsNothing);
    });

    testWidgets('4. Learning activation denial blocks protected destinations',
        (tester) async {
      const authenticatedUnactivatedPolicy = _TestAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: false,
      );

      final router = createLearningRouter(
        accessPolicy: authenticatedUnactivatedPolicy,
        initialLocation: '/learning/home',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      // Authenticated but non-activated identity must redirect to access-denied
      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('Learning Home'), findsNothing);
    });

    testWidgets('5. Missing M2 authorization evidence fails closed',
        (tester) async {
      const defaultPolicy = ProductionLearningAccessPolicy();
      expect(defaultPolicy.isAuthenticated, isFalse);
      expect(defaultPolicy.isLearningActivated, isFalse);

      final router = createLearningRouter(
        accessPolicy: defaultPolicy,
        initialLocation: '/learning/classrooms',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(LearningWelcomeScreen), findsOneWidget);
      expect(find.text('Learning Classrooms'), findsNothing);
    });

    testWidgets('6. Correct route selection and tab identity', (tester) async {
      const authorizedPolicy = _TestAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );

      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/home',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Learning Home'), findsOneWidget);

      // Tap on Classrooms tab
      await tester.tap(find.text('Classrooms'));
      await tester.pumpAndSettle();

      expect(find.text('Learning Classrooms'), findsOneWidget);

      // Tap on Explore tab
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();

      expect(find.text('Learning Explore'), findsOneWidget);
    });

    testWidgets('7. Android back behavior does not crash or loop',
        (tester) async {
      const authorizedPolicy = _TestAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );

      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/home',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Classrooms'));
      await tester.pumpAndSettle();

      // Trigger back navigation
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('8. No unwanted redirect loops on public screens',
        (tester) async {
      for (final path in ['/learning/welcome', '/learning/access-denied']) {
        final router = createLearningRouter(
          initialLocation: path,
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('9. Unimplemented features display unavailable states',
        (tester) async {
      const authorizedPolicy = _TestAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );

      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Learning Chat'), findsOneWidget);
      expect(
        find.text(
          'This feature is currently under active development. No production data or live services are available yet.',
        ),
        findsOneWidget,
      );
      expect(find.text('Feature Pending Implementation'), findsOneWidget);
    });

    testWidgets('10. No route crosses module boundaries', (tester) async {
      const authorizedPolicy = _TestAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );

      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/social/feed',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      // Non-learning route redirected safely to welcome
      expect(find.byType(LearningWelcomeScreen), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST GROUP 1: UNAUTHENTICATED ACCESS DENIAL
    // -------------------------------------------------------------------------
    group('Test Group 1 - Unauthenticated Access Denial', () {
      testWidgets(
          'TEST-03H2B-AUTH-01: Direct initial navigation to /learning/home redirects to Welcome screen',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: false,
          isLearningActivated: false,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/home',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(LearningWelcomeScreen), findsOneWidget);
        expect(find.text('Learning Home'), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-AUTH-02: Direct navigation to all other protected destinations redirects to Welcome screen',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: false,
          isLearningActivated: false,
        );
        final protectedBranches = [
          ('/learning/classrooms', 'Learning Classrooms'),
          ('/learning/explore', 'Learning Explore'),
          ('/learning/chat', 'Learning Chat'),
          ('/learning/profile', 'Learning Profile'),
        ];

        for (final (path, title) in protectedBranches) {
          final router = createLearningRouter(
            accessPolicy: policy,
            initialLocation: path,
          );

          await tester.pumpWidget(_buildRouterApp(router));
          await tester.pumpAndSettle();

          expect(find.byType(LearningWelcomeScreen), findsOneWidget);
          expect(find.text(title), findsNothing);
        }
      });

      testWidgets(
          'TEST-03H2B-AUTH-03: Tapping Continue on Welcome screen while unauthenticated redirects to Access Restricted',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: false,
          isLearningActivated: false,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/welcome',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(LearningWelcomeScreen), findsOneWidget);

        final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
        expect(continueButton, findsOneWidget);

        await tester.ensureVisible(continueButton);
        await tester.pumpAndSettle();

        expect(continueButton.hitTestable(), findsOneWidget);

        await tester.tap(continueButton.hitTestable());
        await tester.pumpAndSettle();

        expect(find.text('Access Restricted'), findsOneWidget);
        expect(find.text('Learning Home'), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-AUTH-04: Programmatic navigation while unauthenticated redirects to Welcome screen',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: false,
          isLearningActivated: false,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/welcome',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        router.go('/learning/home');
        await tester.pumpAndSettle();

        expect(find.byType(LearningWelcomeScreen), findsOneWidget);
        expect(find.text('Learning Home'), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // TEST GROUP 2: AUTHENTICATED BUT UNACTIVATED
    // -------------------------------------------------------------------------
    group('Test Group 2 - Authenticated But Unactivated', () {
      testWidgets(
          'TEST-03H2B-ACT-01: Direct navigation to /learning/home without activation redirects to Access Restricted',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: true,
          isLearningActivated: false,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/home',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.text('Access Restricted'), findsOneWidget);
        expect(find.text('Learning Home'), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-ACT-02: Direct navigation to all other protected destinations without activation redirects to Access Restricted',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: true,
          isLearningActivated: false,
        );
        final protectedBranches = [
          ('/learning/classrooms', 'Learning Classrooms'),
          ('/learning/explore', 'Learning Explore'),
          ('/learning/chat', 'Learning Chat'),
          ('/learning/profile', 'Learning Profile'),
        ];

        for (final (path, title) in protectedBranches) {
          final router = createLearningRouter(
            accessPolicy: policy,
            initialLocation: path,
          );

          await tester.pumpWidget(_buildRouterApp(router));
          await tester.pumpAndSettle();

          expect(find.text('Access Restricted'), findsOneWidget);
          expect(find.text(title), findsNothing);
        }
      });

      testWidgets(
          'TEST-03H2B-ACT-03: Tapping Continue on Welcome screen without activation redirects to Access Restricted',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: true,
          isLearningActivated: false,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/welcome',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(LearningWelcomeScreen), findsOneWidget);

        final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
        expect(continueButton, findsOneWidget);

        await tester.ensureVisible(continueButton);
        await tester.pumpAndSettle();

        expect(continueButton.hitTestable(), findsOneWidget);

        await tester.tap(continueButton.hitTestable());
        await tester.pumpAndSettle();

        expect(find.text('Access Restricted'), findsOneWidget);
        expect(find.text('Learning Home'), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-ACT-04: Programmatic navigation without activation redirects to Access Restricted',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: true,
          isLearningActivated: false,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/welcome',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        router.go('/learning/explore');
        await tester.pumpAndSettle();

        expect(find.text('Access Restricted'), findsOneWidget);
        expect(find.text('Learning Explore'), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // TEST GROUP 3: CONFLICTING AUTHORIZATION EVIDENCE
    // -------------------------------------------------------------------------
    group('Test Group 3 - Conflicting Authorization Evidence', () {
      testWidgets(
          'TEST-03H2B-CONFLICT-01: Activated but unauthenticated initial navigation fails closed to Welcome screen',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: false,
          isLearningActivated: true,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/home',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        // Must fail closed because identity is unauthenticated
        expect(find.byType(LearningWelcomeScreen), findsOneWidget);
        expect(find.text('Learning Home'), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-CONFLICT-02: Activated but unauthenticated branch navigation fails closed to Welcome screen',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: false,
          isLearningActivated: true,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/classrooms',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(LearningWelcomeScreen), findsOneWidget);
        expect(find.text('Learning Classrooms'), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-CONFLICT-03: Tapping Continue on Welcome screen with conflicting authorization fails closed to Access Restricted',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: false,
          isLearningActivated: true,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/welcome',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(LearningWelcomeScreen), findsOneWidget);

        final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
        expect(continueButton, findsOneWidget);

        await tester.ensureVisible(continueButton);
        await tester.pumpAndSettle();

        expect(continueButton.hitTestable(), findsOneWidget);

        await tester.tap(continueButton.hitTestable());
        await tester.pumpAndSettle();

        expect(find.text('Access Restricted'), findsOneWidget);
        expect(find.text('Learning Home'), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // TEST GROUP 4: AUTHORIZED TEST FIXTURES
    // -------------------------------------------------------------------------
    group('Test Group 4 - Authorized Test Fixtures', () {
      testWidgets(
          'TEST-03H2B-NAV-01: Tapping Continue on Welcome screen enters /learning/home when fully authorized',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: true,
          isLearningActivated: true,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/welcome',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(LearningWelcomeScreen), findsOneWidget);

        final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
        expect(continueButton, findsOneWidget);

        await tester.ensureVisible(continueButton);
        await tester.pumpAndSettle();

        expect(continueButton.hitTestable(), findsOneWidget);

        await tester.tap(continueButton.hitTestable());
        await tester.pumpAndSettle();

        expect(find.text('Learning Home'), findsOneWidget);
        expect(find.text('Access Restricted'), findsNothing);
        expect(find.byType(LearningWelcomeScreen), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-NAV-02: Direct navigation to all 5 shell branches resolves without redirection',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: true,
          isLearningActivated: true,
        );
        final branches = [
          ('/learning/home', 'Learning Home'),
          ('/learning/classrooms', 'Learning Classrooms'),
          ('/learning/explore', 'Learning Explore'),
          ('/learning/chat', 'Learning Chat'),
          ('/learning/profile', 'Learning Profile'),
        ];

        for (final (path, title) in branches) {
          final router = createLearningRouter(
            accessPolicy: policy,
            initialLocation: path,
          );

          await tester.pumpWidget(_buildRouterApp(router));
          await tester.pumpAndSettle();

          expect(find.text(title), findsOneWidget);
          expect(find.byType(LearningWelcomeScreen), findsNothing);
          expect(find.text('Access Restricted'), findsNothing);
        }
      });

      testWidgets(
          'TEST-03H2B-NAV-03: Tab switching across all 5 branches maintains shell consistency',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: true,
          isLearningActivated: true,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/home',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.text('Learning Home'), findsOneWidget);

        final tabs = [
          ('Classrooms', 'Learning Classrooms'),
          ('Explore', 'Learning Explore'),
          ('Chat', 'Learning Chat'),
          ('Profile', 'Learning Profile'),
          ('Home', 'Learning Home'),
        ];

        for (final (tabLabel, expectedTitle) in tabs) {
          await tester.tap(find.text(tabLabel));
          await tester.pumpAndSettle();
          expect(find.text(expectedTitle), findsOneWidget);
        }
      });
    });

    // -------------------------------------------------------------------------
    // TEST GROUP 5: DIRECT ROUTE / DEEP-LINK PROTECTION
    // -------------------------------------------------------------------------
    group('Test Group 5 - Direct Route / Deep-Link Protection', () {
      testWidgets(
          'TEST-03H2B-LINK-01: Initial deep-link location to protected route cannot bypass unauthenticated guard',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: false,
          isLearningActivated: false,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/home',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(LearningWelcomeScreen), findsOneWidget);
        expect(find.text('Learning Home'), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-LINK-02: Initial deep-link location to nested branch cannot bypass unactivated guard',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: true,
          isLearningActivated: false,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/profile',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.text('Access Restricted'), findsOneWidget);
        expect(find.text('Learning Profile'), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-LINK-03: Programmatic deep-link attempt while unauthenticated fails closed',
          (tester) async {
        const policy = _TestAccessPolicy(
          isAuthenticated: false,
          isLearningActivated: false,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/access-denied',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        router.go('/learning/chat');
        await tester.pumpAndSettle();

        expect(find.byType(LearningWelcomeScreen), findsOneWidget);
        expect(find.text('Learning Chat'), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // TEST GROUP 6: PRODUCTION FAIL-CLOSED DEFAULTS
    // -------------------------------------------------------------------------
    group('Test Group 6 - Production Fail-Closed Defaults', () {
      test(
          'TEST-03H2B-PROD-01: ProductionLearningAccessPolicy default instance has false for both flags',
          () {
        const policy = ProductionLearningAccessPolicy();
        expect(policy.isAuthenticated, isFalse);
        expect(policy.isLearningActivated, isFalse);
      });

      testWidgets(
          'TEST-03H2B-PROD-02: Default createLearningRouter() fails closed to Welcome on /learning/home',
          (tester) async {
        final router = createLearningRouter(
          initialLocation: '/learning/home',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(LearningWelcomeScreen), findsOneWidget);
        expect(find.text('Learning Home'), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-PROD-03: Default createLearningRouter() fails closed to Welcome on /learning/profile',
          (tester) async {
        final router = createLearningRouter(
          initialLocation: '/learning/profile',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(LearningWelcomeScreen), findsOneWidget);
        expect(find.text('Learning Profile'), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-PROD-04: Default createLearningRouter() redirects Continue on Welcome to Access Restricted',
          (tester) async {
        final router = createLearningRouter(
          initialLocation: '/learning/welcome',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(LearningWelcomeScreen), findsOneWidget);

        final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
        expect(continueButton, findsOneWidget);

        await tester.ensureVisible(continueButton);
        await tester.pumpAndSettle();

        expect(continueButton.hitTestable(), findsOneWidget);

        await tester.tap(continueButton.hitTestable());
        await tester.pumpAndSettle();

        expect(find.text('Access Restricted'), findsOneWidget);
        expect(find.text('Learning Home'), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // TEST GROUP 7: SESSION OR ACTIVATION STATE CHANGES
    // -------------------------------------------------------------------------
    group('Test Group 7 - Session or Activation State Changes', () {
      testWidgets(
          'TEST-03H2B-STATE-01: Subsequent navigation reflects loss of authentication',
          (tester) async {
        final policy = _MutableTestAccessPolicy(
          isAuthenticated: true,
          isLearningActivated: true,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/home',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.text('Learning Home'), findsOneWidget);

        // Identity session revoked
        policy.isAuthenticated = false;

        // Subsequent navigation to protected destination
        router.go('/learning/classrooms');
        await tester.pumpAndSettle();

        // Must fail closed to Welcome screen
        expect(find.byType(LearningWelcomeScreen), findsOneWidget);
        expect(find.text('Learning Classrooms'), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-STATE-02: Subsequent navigation reflects loss of module activation',
          (tester) async {
        final policy = _MutableTestAccessPolicy(
          isAuthenticated: true,
          isLearningActivated: true,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/home',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.text('Learning Home'), findsOneWidget);

        // Module deactivation
        policy.isLearningActivated = false;

        // Subsequent navigation to protected destination
        router.go('/learning/classrooms');
        await tester.pumpAndSettle();

        // Must redirect to Access Restricted
        expect(find.text('Access Restricted'), findsOneWidget);
        expect(find.text('Learning Classrooms'), findsNothing);
      });

      testWidgets(
          'TEST-03H2B-STATE-03: Router re-evaluates access on router.refresh() when policy state changes',
          (tester) async {
        final policy = _MutableTestAccessPolicy(
          isAuthenticated: true,
          isLearningActivated: true,
        );
        final router = createLearningRouter(
          accessPolicy: policy,
          initialLocation: '/learning/home',
        );

        await tester.pumpWidget(_buildRouterApp(router));
        await tester.pumpAndSettle();

        expect(find.text('Learning Home'), findsOneWidget);

        // Revoke authentication while currently mounted on protected route
        policy.isAuthenticated = false;
        router.refresh();
        await tester.pumpAndSettle();

        // Refresh triggers re-evaluation, failing closed to Welcome
        expect(find.byType(LearningWelcomeScreen), findsOneWidget);
        expect(find.text('Learning Home'), findsNothing);
      });
    });
  });
}
