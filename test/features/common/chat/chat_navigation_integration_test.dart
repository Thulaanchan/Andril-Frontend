import 'package:andril_mobile/features/common/chat/domain/module_config.dart';
import 'package:andril_mobile/features/common/chat/presentation/navigation/chat_navigation_contract.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chat_screen.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chats_list_screen.dart';
import 'package:andril_mobile/features/common/chat/preview/main_app_chat_route_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M4 Chat GoRouter Navigation Integration', () {
    test(
        '0. Contract validation maps dating to social and rejects invalid identifiers',
        () {
      expect(ChatNavigationParams.parseModuleType('dating'),
          AndrilModuleType.social);
      expect(ChatNavigationParams.parseModuleType('social'),
          AndrilModuleType.social);
      expect(ChatNavigationParams.parseModuleType('learning'),
          AndrilModuleType.learning);
      expect(ChatNavigationParams.parseModuleType('hobbies'),
          AndrilModuleType.hobbies);
      expect(ChatNavigationParams.parseModuleType('unknown'), isNull);

      final tokenValidation = ChatNavigationParams.validate(
        rawModule: 'learning',
        conversationId: 'bearer secret_token',
      );
      expect(tokenValidation.isValid, isFalse);
      expect(
          tokenValidation.status, ChatNavigationStatus.missingConversationId);

      final emailValidation = ChatNavigationParams.validate(
        rawModule: 'learning',
        conversationId: 'user@andril.com',
      );
      expect(emailValidation.isValid, isFalse);

      final crossValidation = ChatNavigationParams.validate(
        rawModule: 'learning',
        conversationId: 'maya',
        partner: AndrilModuleConfig.hobbies.defaultPartner,
      );
      expect(crossValidation.isValid, isFalse);
      expect(crossValidation.status,
          ChatNavigationStatus.crossModulePartnerMismatch);
    });

    testWidgets('1. Learning Chat List navigates and displays Maya only',
        (tester) async {
      await tester.pumpWidget(
        const MainAppChatRoutePreviewApp(
          initialLocation: '/preview/chat/learning',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatsListScreen), findsOneWidget);
      expect(find.text('Learning Chats'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Nila'), findsNothing);
      expect(find.text('Aira'), findsNothing);
      expect(find.text('Ava'), findsNothing);
    });

    testWidgets('2. Hobbies Chat List navigates and displays Nila only',
        (tester) async {
      await tester.pumpWidget(
        const MainAppChatRoutePreviewApp(
          initialLocation: '/preview/chat/hobbies',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatsListScreen), findsOneWidget);
      expect(find.text('Hobbies Chats'), findsOneWidget);
      expect(find.text('Nila'), findsOneWidget);
      expect(find.text('Maya'), findsNothing);
      expect(find.text('Aira'), findsNothing);
      expect(find.text('Ava'), findsNothing);
    });

    testWidgets('3. Dating/Social Chat List navigates and displays Aira & Ava',
        (tester) async {
      await tester.pumpWidget(
        const MainAppChatRoutePreviewApp(
          initialLocation: '/preview/chat/social',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatsListScreen), findsOneWidget);
      expect(find.text('Social Chats'), findsOneWidget);
      expect(find.text('Aira'), findsOneWidget);
      expect(find.text('Ava'), findsOneWidget);
      expect(find.text('Maya'), findsNothing);
      expect(find.text('Nila'), findsNothing);
    });

    testWidgets(
        '4. Tapping Maya in Learning opens Maya chat detail with study message',
        (tester) async {
      final router = createChatPreviewRouter(
        initialLocation: '/preview/chat/learning',
      );
      await tester.pumpWidget(MainAppChatRoutePreviewApp(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Maya'), findsOneWidget);
      await tester.tap(find.text('Maya'));
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatScreen), findsOneWidget);
      final chatScreen =
          tester.widget<AndrilChatScreen>(find.byType(AndrilChatScreen));
      expect(chatScreen.effectivePartner.name, 'Maya');
      expect(chatScreen.moduleConfig.type, AndrilModuleType.learning);
      expect(router.state.uri.path, '/preview/chat/learning/lrn_maya');
      expect(find.text('Hey! How is your Flutter learning going? 😊'),
          findsOneWidget);
    });

    testWidgets('5. Aira and Ava have independent conversations in Social',
        (tester) async {
      final router = createChatPreviewRouter(
        initialLocation: '/preview/chat/social',
      );
      await tester.pumpWidget(MainAppChatRoutePreviewApp(router: router));
      await tester.pumpAndSettle();

      // Tap Aira
      await tester.tap(find.text('Aira'));
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatScreen), findsOneWidget);
      expect(
        tester
            .widget<AndrilChatScreen>(find.byType(AndrilChatScreen))
            .effectivePartner
            .name,
        'Aira',
      );
      expect(router.state.uri.path, '/preview/chat/social/soc_aira');

      // Go back to social list
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatsListScreen), findsOneWidget);
      expect(router.state.uri.path, '/preview/chat/social');

      // Tap Ava
      await tester.tap(find.text('Ava'));
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatScreen), findsOneWidget);
      expect(
        tester
            .widget<AndrilChatScreen>(find.byType(AndrilChatScreen))
            .effectivePartner
            .name,
        'Ava',
      );
      expect(router.state.uri.path, '/preview/chat/social/soc_ava');
    });

    testWidgets('6. Cross-module partner mismatch is denied by contract',
        (tester) async {
      final router = createChatPreviewRouter(
        initialLocation: '/preview/chat/learning/soc_aira',
      );
      await tester.pumpWidget(MainAppChatRoutePreviewApp(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(ChatRouteDeniedScreen), findsOneWidget);
      expect(find.text('Chat Navigation Restricted'), findsOneWidget);
      expect(find.byType(AndrilChatScreen), findsNothing);
    });

    testWidgets('7. Invalid conversation ID or email in route is denied',
        (tester) async {
      final router = createChatPreviewRouter(
        initialLocation: '/preview/chat/learning/user@example.com',
      );
      await tester.pumpWidget(MainAppChatRoutePreviewApp(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(ChatRouteDeniedScreen), findsOneWidget);
      expect(
          find.text('Invalid conversation identifier format.'), findsOneWidget);
      expect(find.byType(AndrilChatScreen), findsNothing);
    });

    testWidgets('8. Back button navigates from detail back to module chat list',
        (tester) async {
      final router = createChatPreviewRouter(
        initialLocation: '/preview/chat/hobbies/hob_nila',
      );
      await tester.pumpWidget(MainAppChatRoutePreviewApp(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatScreen), findsOneWidget);
      expect(router.state.uri.path, '/preview/chat/hobbies/hob_nila');

      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatsListScreen), findsOneWidget);
      expect(router.state.uri.path, '/preview/chat/hobbies');
      expect(find.text('Hobbies Chats'), findsOneWidget);
    });

    testWidgets(
        '9. Presentation states (loading, empty, error) work with preview scope',
        (tester) async {
      final router = createChatPreviewRouter(
        initialLocation: '/preview/chat/social',
      );

      // Loading
      await tester.pumpWidget(
        MainAppChatRoutePreviewApp(
          router: router,
          builder: (context, child) => ChatListPreviewScope(
            moduleType: AndrilModuleType.social,
            status: ChatListPreviewStatus.loading,
            child: child!,
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('chats_list_loading')), findsOneWidget);

      // Empty
      await tester.pumpWidget(
        MainAppChatRoutePreviewApp(
          router: router,
          builder: (context, child) => ChatListPreviewScope(
            moduleType: AndrilModuleType.social,
            status: ChatListPreviewStatus.empty,
            child: child!,
          ),
        ),
      );
      await tester.pump();
      expect(
          find.byKey(const Key('empty_conversations_state')), findsOneWidget);

      // Error
      await tester.pumpWidget(
        MainAppChatRoutePreviewApp(
          router: router,
          builder: (context, child) => ChatListPreviewScope(
            moduleType: AndrilModuleType.social,
            status: ChatListPreviewStatus.retryableError,
            onRetry: () {},
            child: child!,
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('chats_list_error')), findsOneWidget);
    });

    testWidgets(
        '10. MoodTone pills appear in Social chat only, never in Learning or Hobbies',
        (tester) async {
      // 1. Social
      final socialRouter = createChatPreviewRouter(
        initialLocation: '/preview/chat/social/soc_aira',
      );
      await tester.pumpWidget(MainAppChatRoutePreviewApp(router: socialRouter));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('message_input')), 'Hello');
      await tester.pump();
      expect(find.byKey(const Key('mood_selector')), findsOneWidget);

      // 2. Learning
      final learningRouter = createChatPreviewRouter(
        initialLocation: '/preview/chat/learning/lrn_maya',
      );
      await tester
          .pumpWidget(MainAppChatRoutePreviewApp(router: learningRouter));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('message_input')), 'Hello');
      await tester.pump();
      expect(find.byKey(const Key('mood_selector')), findsNothing);

      // 3. Hobbies
      final hobbiesRouter = createChatPreviewRouter(
        initialLocation: '/preview/chat/hobbies/hob_nila',
      );
      await tester
          .pumpWidget(MainAppChatRoutePreviewApp(router: hobbiesRouter));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('message_input')), 'Hello');
      await tester.pump();
      expect(find.byKey(const Key('mood_selector')), findsNothing);
    });

    testWidgets(
        '11. Gift confirmation dialog remains MOCK with safe simulated balance',
        (tester) async {
      final router = createChatPreviewRouter(
        initialLocation: '/preview/chat/social/soc_aira',
      );
      await tester.pumpWidget(MainAppChatRoutePreviewApp(router: router));
      await tester.pumpAndSettle();

      // 1. Open gift picker sheet
      await tester.tap(find.byKey(const Key('open_gifts_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gift_picker_sheet')), findsOneWidget);
      expect(find.byKey(const Key('gift_tile_0')), findsOneWidget);
      expect(find.text('40 Coins'), findsOneWidget);

      // 2. Tap first gift tile to open confirmation
      await tester.tap(find.byKey(const Key('gift_tile_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirm_gift_dialog')), findsOneWidget);

      // 3. Cancel should dismiss dialog without deducting coins
      await tester.tap(find.byKey(const Key('cancel_send_gift')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirm_gift_dialog')), findsNothing);
      expect(find.text('40 Coins'), findsOneWidget);

      // 4. GiftPickerSheet remains open; tap visible gift tile again
      expect(find.byKey(const Key('gift_picker_sheet')), findsOneWidget);
      expect(find.byKey(const Key('gift_tile_0')), findsOneWidget);

      await tester.tap(find.byKey(const Key('gift_tile_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirm_gift_dialog')), findsOneWidget);

      // 5. Confirm send gift: dismisses dialog and sheet, deducts simulated balance
      await tester.tap(find.byKey(const Key('confirm_send_gift')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirm_gift_dialog')), findsNothing);
      expect(find.byKey(const Key('gift_picker_sheet')), findsNothing);

      // 6. Simulated gift sticker message was sent locally (appended at index 4)
      expect(find.byKey(const Key('sent_gift_4')), findsOneWidget);
      expect(find.textContaining('Gift sent (DEMO)'), findsOneWidget);
    });

    testWidgets(
        '12. Responsive layout at 320x600 with 2x text scaling renders without overflow',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final module in ['learning', 'hobbies', 'social']) {
        final router = createChatPreviewRouter(
          initialLocation: '/preview/chat/$module',
        );
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 600),
              textScaler: TextScaler.linear(2.0),
            ),
            child: MainAppChatRoutePreviewApp(router: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason:
                'RenderFlex overflow detected on $module list at 320x600 @ 2x');
      }
    });

    testWidgets(
        '13. Denied screen returns to preview safely without bypassing authentication',
        (tester) async {
      final router = createChatPreviewRouter(
        initialLocation: '/preview/chat/denied?reason=Policy+enforcement',
      );
      await tester.pumpWidget(MainAppChatRoutePreviewApp(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(ChatRouteDeniedScreen), findsOneWidget);
      expect(find.text('Policy enforcement'), findsOneWidget);

      await tester.tap(find.byKey(const Key('return_to_preview_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatsListScreen), findsOneWidget);
      expect(router.state.uri.path, '/preview/chat/learning');
    });
  });
}
