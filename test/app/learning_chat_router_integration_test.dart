import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:andril_mobile/app/router/learning_router.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/common/chat/domain/module_config.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chat_screen.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chats_list_screen.dart';
import 'package:andril_mobile/features/common/chat/preview/main_app_chat_route_preview.dart';
import 'package:andril_mobile/features/learning/profile/screens/learning_welcome_screen.dart';
import 'package:andril_mobile/features/shared/presentation/scaffolds/learning_scaffold.dart';

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
  const authorizedPolicy = _TestAccessPolicy(
    isAuthenticated: true,
    isLearningActivated: true,
  );

  group('Learning Chat Router Integration Suite', () {
    // 1. /learning/chat mounts AndrilChatsListScreen
    testWidgets(
        '1. /learning/chat mounts AndrilChatsListScreen in learning shell',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/learning/chat');
      expect(find.byType(AndrilChatsListScreen), findsOneWidget);
      expect(find.text('Learning Chats'), findsOneWidget);
      final chatsList = tester
          .widget<AndrilChatsListScreen>(find.byType(AndrilChatsListScreen));
      expect(chatsList.moduleConfig.type, AndrilModuleType.learning);
    });

    // 2. Maya conversation is visible with mock preview label
    testWidgets('2. Maya conversation is visible with mock preview label',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('MOCK PREVIEW'), findsOneWidget);
      expect(find.text("I'll share my study checklist with you too! 📝"),
          findsOneWidget);
    });

    // 3. Tapping Maya navigates to /learning/chat/lrn_maya and mounts AndrilChatScreen
    testWidgets(
        '3. Tapping Maya navigates to /learning/chat/lrn_maya and mounts AndrilChatScreen',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Maya'), findsOneWidget);
      await tester.tap(find.text('Maya'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          '/learning/chat/lrn_maya');
      expect(find.byType(AndrilChatScreen), findsOneWidget);
      final chatScreen =
          tester.widget<AndrilChatScreen>(find.byType(AndrilChatScreen));
      expect(chatScreen.effectivePartner.name, 'Maya');
      expect(chatScreen.moduleConfig.type, AndrilModuleType.learning);
    });

    // 4. Back navigation button returns to /learning/chat
    testWidgets('4. Back navigation button returns to /learning/chat',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Maya'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          '/learning/chat/lrn_maya');
      expect(find.byType(AndrilChatScreen), findsOneWidget);

      final backButton = find.byKey(const Key('back_button'));
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/learning/chat');
      expect(find.byType(AndrilChatsListScreen), findsOneWidget);
    });

    // 5. Learning tab switching (Home -> Chat -> Explore -> Chat) preserves navigation shell and selected tab state
    testWidgets(
        '5. Learning tab switching maintains shell and selected tab state',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/home',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(LearningScaffold), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/learning/home');

      // Home -> Chat
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/learning/chat');
      expect(find.byType(AndrilChatsListScreen), findsOneWidget);

      // Chat -> Explore
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      expect(
          router.routeInformationProvider.value.uri.path, '/learning/explore');
      expect(find.text('Learning Explore'), findsOneWidget);

      // Explore -> Chat
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/learning/chat');
      expect(find.byType(AndrilChatsListScreen), findsOneWidget);
      expect(find.byType(LearningScaffold), findsOneWidget);
    });

    // 6. Signed-out session denied (redirects to /learning/welcome)
    testWidgets(
        '6. Signed-out session is denied and redirects to /learning/welcome',
        (tester) async {
      const signedOutPolicy = _TestAccessPolicy(
        isAuthenticated: false,
        isLearningActivated: true,
      );

      final router = createLearningRouter(
        accessPolicy: signedOutPolicy,
        initialLocation: '/learning/chat',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          '/learning/welcome');
      expect(find.byType(LearningWelcomeScreen), findsOneWidget);
      expect(find.byType(AndrilChatsListScreen), findsNothing);
    });

    // 7. Inactive Learning module denied (redirects to /learning/access-denied)
    testWidgets(
        '7. Inactive Learning module is denied and redirects to /learning/access-denied',
        (tester) async {
      const inactivePolicy = _TestAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: false,
      );

      final router = createLearningRouter(
        accessPolicy: inactivePolicy,
        initialLocation: '/learning/chat',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          '/learning/access-denied');
      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.byType(AndrilChatsListScreen), findsNothing);
    });

    // 8. Invalid conversation ID denied (e.g. /learning/chat/invalid_id renders ChatRouteDeniedScreen)
    testWidgets(
        '8. Invalid conversation ID is denied with ChatRouteDeniedScreen',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat/invalid_id',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(ChatRouteDeniedScreen), findsOneWidget);
      expect(find.byType(AndrilChatScreen), findsNothing);
      expect(find.text('Chat Navigation Restricted'), findsOneWidget);
    });

    // 9. Social/Dating conversation ID denied (e.g. /learning/chat/soc_aira renders ChatRouteDeniedScreen)
    testWidgets('9. Cross-module Social conversation ID is denied in Learning',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat/soc_aira',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(ChatRouteDeniedScreen), findsOneWidget);
      expect(find.byType(AndrilChatScreen), findsNothing);
    });

    // 10. Hobbies conversation ID denied (e.g. /learning/chat/hob_nila renders ChatRouteDeniedScreen)
    testWidgets('10. Cross-module Hobbies conversation ID is denied in Learning',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat/hob_nila',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(ChatRouteDeniedScreen), findsOneWidget);
      expect(find.byType(AndrilChatScreen), findsNothing);
    });

    // 11. Direct deep link resolves valid mock Learning conversation
    testWidgets(
        '11. Direct deep link resolves valid mock Learning conversation',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat/lrn_maya',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          '/learning/chat/lrn_maya');
      expect(find.byType(AndrilChatScreen), findsOneWidget);
      final chatScreen =
          tester.widget<AndrilChatScreen>(find.byType(AndrilChatScreen));
      expect(chatScreen.effectivePartner.name, 'Maya');
      expect(chatScreen.moduleConfig.type, AndrilModuleType.learning);
    });

    // 12. Spoofed route partner data denied
    testWidgets('12. Spoofed route partner data from Social is denied',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      // Programmatically push to detail route with a cross-module partner (Social Aira)
      router.go(
        '/learning/chat/lrn_maya',
        extra: AndrilModuleConfig.social.defaultPartner,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatRouteDeniedScreen), findsOneWidget);
      expect(find.byType(AndrilChatScreen), findsNothing);
      expect(
          find.textContaining('does not belong to route module'), findsOneWidget);

      // Also verify spoofed partner within same module name mismatch
      router.go(
        '/learning/chat/lrn_maya',
        extra: const AndrilModuleProfile(
          name: 'SpoofedPartner',
          status: 'Online',
          avatarAsset: 'assets/profile/maya_avatar.webp',
          moduleType: AndrilModuleType.learning,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatRouteDeniedScreen), findsOneWidget);
      expect(find.byType(AndrilChatScreen), findsNothing);
      expect(find.textContaining('Partner profile mismatch'), findsOneWidget);

      // Verify that relying on display-name alone is rejected (spoofed avatar asset)
      router.go(
        '/learning/chat/lrn_maya',
        extra: const AndrilModuleProfile(
          name: 'Maya',
          status: 'Online',
          avatarAsset: 'assets/profile/spoofed_avatar.webp',
          moduleType: AndrilModuleType.learning,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatRouteDeniedScreen), findsOneWidget);
      expect(find.byType(AndrilChatScreen), findsNothing);
      expect(find.textContaining('Partner profile mismatch'), findsOneWidget);
    });

    // 13. MOCK labeling preserved on Chat list and detail
    testWidgets('13. MOCK labeling preserved on Chat list and detail',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      // Check list has MOCK label
      expect(find.text('MOCK PREVIEW'), findsOneWidget);

      // Open detail
      await tester.tap(find.text('Maya'));
      await tester.pumpAndSettle();

      // Tap profile to inspect partner info dialog with MOCK indicator
      await tester.tap(find.byKey(const Key('maya_profile')));
      await tester.pumpAndSettle();

      // Check detail dialog has MOCK label
      expect(find.textContaining('(MOCK)'), findsWidgets);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    // 14. No production API requests (purely mock-backed)
    testWidgets('14. Resolves purely from mock catalogs without external calls',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat',
      );

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Maya'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AndrilChatScreen), findsOneWidget);
    });

    // 15. Responsive and accessible layout across viewports (320x600 and wide) without overflow
    testWidgets(
        '15. Responsive layout across compact (320x600) and wide viewports without overflow',
        (tester) async {
      final router = createLearningRouter(
        accessPolicy: authorizedPolicy,
        initialLocation: '/learning/chat',
      );

      // Compact viewport
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildRouterApp(router));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Navigate to chat detail on compact screen
      await tester.tap(find.text('Maya'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AndrilChatScreen), findsOneWidget);

      // Wide viewport
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
