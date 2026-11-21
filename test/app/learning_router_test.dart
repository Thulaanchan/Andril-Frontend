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

Widget _buildRouterApp(GoRouter router) {
  return MaterialApp.router(
    theme: LearningTheme.theme,
    routerConfig: router,
  );
}

void main() {
  group('LearningRouter - Security & Route Navigation Tests', () {
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
  });
}
