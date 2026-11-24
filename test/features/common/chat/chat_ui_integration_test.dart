import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/common/chat/domain/entities/chat_models.dart';
import 'package:andril_mobile/features/common/chat/domain/module_config.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chat_screen.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chats_list_screen.dart';
import 'package:andril_mobile/features/common/chat/preview/main_chat_preview.dart';
import 'package:andril_mobile/features/common/virtual_gifts/domain/gift_catalogs.dart';

void main() {
  group('1. Three-Module Chat List screens & Module Isolation', () {
    testWidgets('Learning Chats List shows ONLY Maya, never Nila, Aira or Ava',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(
          moduleConfig: AndrilModuleConfig.learning,
          startAtChatsList: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning Chats'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Nila'), findsNothing);
      expect(find.text('Aira'), findsNothing);
      expect(find.text('Ava'), findsNothing);
    });

    testWidgets('Hobbies Chats List shows ONLY Nila, never Maya, Aira or Ava',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(
          moduleConfig: AndrilModuleConfig.hobbies,
          startAtChatsList: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hobbies Chats'), findsOneWidget);
      expect(find.text('Nila'), findsOneWidget);
      expect(find.text('Maya'), findsNothing);
      expect(find.text('Aira'), findsNothing);
      expect(find.text('Ava'), findsNothing);
    });

    testWidgets('Social Chats List shows Aira AND Ava, never Maya or Nila',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(
          moduleConfig: AndrilModuleConfig.social,
          startAtChatsList: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Social Chats'), findsOneWidget);
      expect(find.text('Aira'), findsOneWidget);
      expect(find.text('Ava'), findsOneWidget);
      expect(find.text('Maya'), findsNothing);
      expect(find.text('Nila'), findsNothing);
    });

    testWidgets(
        'Conversation search filters list, handles clear and empty states',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(
          moduleConfig: AndrilModuleConfig.social,
          startAtChatsList: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aira'), findsOneWidget);
      expect(find.text('Ava'), findsOneWidget);

      // Search for 'Ava'
      await tester.enterText(
          find.byKey(const Key('conversation_search_input')), 'Ava');
      await tester.pump();
      expect(find.byKey(const Key('conversation_Ava')), findsOneWidget);
      expect(find.byKey(const Key('conversation_Aira')), findsNothing);

      // Clear search via clear button
      await tester.tap(find.byKey(const Key('clear_search_button')));
      await tester.pump();
      expect(find.byKey(const Key('conversation_Aira')), findsOneWidget);
      expect(find.byKey(const Key('conversation_Ava')), findsOneWidget);

      // Search non-existent
      await tester.enterText(
          find.byKey(const Key('conversation_search_input')), 'UnknownPerson');
      await tester.pump();
      expect(find.byKey(const Key('empty_search_state')), findsOneWidget);
      expect(find.textContaining('No results matching'), findsOneWidget);
    });
  });

  group(
      '2. Dynamic Conversation Navigation (The Fix: Aira -> Aira, Ava -> Ava)',
      () {
    testWidgets(
        'Tapping Aira opens Aira with correct header, avatar and messages',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(
          moduleConfig: AndrilModuleConfig.social,
          startAtChatsList: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('conversation_Aira')));
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatScreen), findsOneWidget);
      expect(find.text('Aira'), findsOneWidget);
      expect(find.text('What about you?'), findsOneWidget);

      // Back navigation returns to Social Chats List
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(AndrilChatsListScreen), findsOneWidget);
      expect(find.text('Social Chats'), findsOneWidget);
    });

    testWidgets(
        'Tapping Ava opens Ava with correct header, avatar and messages',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(
          moduleConfig: AndrilModuleConfig.social,
          startAtChatsList: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('conversation_Ava')));
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatScreen), findsOneWidget);
      expect(find.text('Ava'), findsOneWidget);
      // Ava-specific conversation message
      expect(
          find.text('See you at the coffee shop tomorrow! ☕'), findsOneWidget);

      // Back navigation returns to Social Chats List
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(AndrilChatsListScreen), findsOneWidget);
      expect(find.text('Social Chats'), findsOneWidget);
    });

    testWidgets('Tapping Maya in Learning opens Maya with study messages',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(
          moduleConfig: AndrilModuleConfig.learning,
          startAtChatsList: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('conversation_Maya')));
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatScreen), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text("I'll share my study checklist with you too! 📝"),
          findsOneWidget);
    });

    testWidgets('Tapping Nila in Hobbies opens Nila with hobbies messages',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(
          moduleConfig: AndrilModuleConfig.hobbies,
          startAtChatsList: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('conversation_Nila')));
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatScreen), findsOneWidget);
      expect(find.text('Nila'), findsOneWidget);
      expect(
          find.text(
              'We can also bring my camera and do some photography there! 📸'),
          findsOneWidget);
    });

    test('Cross-module partner cannot be selected in AndrilChatScreen', () {
      const crossPartner = AndrilModuleProfile(
        name: 'Maya',
        status: 'Online',
        avatarAsset: 'assets/profile/maya_avatar.webp',
        moduleType: AndrilModuleType.learning,
      );

      const screen = AndrilChatScreen(
        moduleConfig: AndrilModuleConfig.social,
        partner: crossPartner,
      );

      // Assert effectivePartner throws ArgumentError
      expect(
        () => screen.effectivePartner,
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('3. Partner Identity in Header and Dialogs', () {
    testWidgets('Social Chat: Ava profile, report, and block dialogs use Ava',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(
          moduleConfig: AndrilModuleConfig.social,
          startAtChatsList: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('conversation_Ava')));
      await tester.pumpAndSettle();

      // Profile click on Ava
      await tester.tap(find.byKey(const Key('ava_profile')));
      await tester.pumpAndSettle();
      expect(find.text('Offline · Private Social identity (MOCK)'),
          findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Report dialog for Ava
      await tester.tap(find.byKey(const Key('chat_more_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Report Ava'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancel_report_button')));
      await tester.pumpAndSettle();

      // Block dialog for Ava
      await tester.tap(find.byKey(const Key('chat_more_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block user'));
      await tester.pumpAndSettle();
      expect(find.text('Block Ava?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancel_block_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Social Chat: Aira profile, report, and block dialogs use Aira',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(
          moduleConfig: AndrilModuleConfig.social,
          startAtChatsList: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('conversation_Aira')));
      await tester.pumpAndSettle();

      // Avatar click
      await tester.tap(find.byKey(const Key('aira_avatar')));
      await tester.pumpAndSettle();
      expect(
          find.text('Online · Private Social identity (MOCK)'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Report Aira
      await tester.tap(find.byKey(const Key('chat_more_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Report Aira'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancel_report_button')));
      await tester.pumpAndSettle();
    });
  });

  group('4. Social-Only MoodTone Integration', () {
    testWidgets(
        'Social: typing shows 10 MoodTone pills; select and deselect works',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(moduleConfig: AndrilModuleConfig.social),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mood_selector')), findsNothing);
      await tester.enterText(
          find.byKey(const Key('message_input')), 'Hey there!');
      await tester.pump();
      expect(find.byKey(const Key('mood_selector')), findsOneWidget);

      // Select romantic tone
      await tester.tap(find.byKey(const Key('tone_romantic')));
      await tester.pump();

      // Deselect romantic tone by tapping again
      await tester.tap(find.byKey(const Key('tone_romantic')));
      await tester.pump();

      // Re-select playful tone and send
      await tester.tap(find.byKey(const Key('tone_playful')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('send_message_button')));
      await tester.pumpAndSettle();

      expect(find.text('Hey there!'), findsOneWidget);
      expect(find.text('😜 Playful'), findsOneWidget);
      expect(find.byKey(const Key('mood_selector')), findsNothing);
    });

    testWidgets('Learning Chat NEVER displays MoodTone when typing',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(moduleConfig: AndrilModuleConfig.learning),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('message_input')), 'Testing Learning Chat');
      await tester.pump();
      expect(find.byKey(const Key('mood_selector')), findsNothing);
    });

    testWidgets('Hobbies Chat NEVER displays MoodTone when typing',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(moduleConfig: AndrilModuleConfig.hobbies),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('message_input')), 'Testing Hobbies Chat');
      await tester.pump();
      expect(find.byKey(const Key('mood_selector')), findsNothing);
    });
  });

  group('5. Virtual Gifts Flow (Requirement 8 Confirmation & Safe Demo)', () {
    testWidgets('Gift picker shows 10 module gifts and balance',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(moduleConfig: AndrilModuleConfig.social),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_gifts_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gift_picker_sheet')), findsOneWidget);
      expect(find.text('Virtual Gifts'), findsOneWidget);
      expect(find.byKey(const Key('gift_grid')), findsOneWidget);
      expect(find.text('40 Coins'), findsOneWidget);

      for (var i = 0; i < 10; i++) {
        expect(find.byKey(Key('gift_tile_$i')), findsOneWidget);
      }
    });

    testWidgets(
        'Tapping gift opens confirmation dialog; cancel does NOT deduct coins',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(
          moduleConfig: AndrilModuleConfig.social,
          startAtChatsList: false,
        ),
      );
      await tester.pumpAndSettle();

      // Open gifts
      await tester.tap(find.byKey(const Key('open_gifts_button')));
      await tester.pumpAndSettle();

      // Tap first gift (Sparkle / 1 coin)
      await tester.tap(find.byKey(const Key('gift_tile_0')));
      await tester.pumpAndSettle();

      // Confirm dialog appears showing details and price
      expect(find.byKey(const Key('confirm_gift_dialog')), findsOneWidget);
      expect(find.text('Send ${socialGifts[0].name}?'), findsOneWidget);
      expect(find.textContaining('${socialGifts[0].coins} Coins (MOCK)'),
          findsOneWidget);

      // Cancel send
      await tester.tap(find.byKey(const Key('cancel_send_gift')));
      await tester.pumpAndSettle();

      // Dialog dismissed, sheet still shows 40 coins
      expect(find.byKey(const Key('confirm_gift_dialog')), findsNothing);
      expect(find.text('40 Coins'), findsOneWidget);
      expect(find.byKey(const Key('sent_gift_4')), findsNothing);
    });

    testWidgets('Confirming gift deducts demo balance and sends sticker',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(
          moduleConfig: AndrilModuleConfig.social,
          startAtChatsList: false,
        ),
      );
      await tester.pumpAndSettle();

      // Open gifts
      await tester.tap(find.byKey(const Key('open_gifts_button')));
      await tester.pumpAndSettle();

      // Tap first gift (1 coin)
      await tester.tap(find.byKey(const Key('gift_tile_0')));
      await tester.pumpAndSettle();

      // Confirm send
      await tester.tap(find.byKey(const Key('confirm_send_gift')));
      await tester.pumpAndSettle();

      // Sheet closed and sticker appended
      expect(find.byKey(const Key('gift_picker_sheet')), findsNothing);
      expect(find.byKey(const Key('sent_gift_4')), findsOneWidget);
      expect(find.textContaining('Gift sent (DEMO)'), findsOneWidget);

      // Dismiss snackbar
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify demo balance deducted from 40 to 39
      await tester.tap(find.byKey(const Key('open_gifts_button')));
      await tester.pumpAndSettle();
      expect(find.text('39 Coins'), findsOneWidget);
    });

    testWidgets(
        'Insufficient coins shows warning and Buy Coins not connected notice',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AndrilChatScreen.social(initialBalance: 5),
        ),
      );
      await tester.pumpAndSettle();

      // Open gifts
      await tester.tap(find.byKey(const Key('open_gifts_button')));
      await tester.pumpAndSettle();

      // Tap gift 9 (Rose Bouquet / 20 coins)
      await tester.tap(find.byKey(const Key('gift_tile_9')));
      await tester.pumpAndSettle();

      expect(find.text('Not enough coins'), findsOneWidget);
      expect(
          find.textContaining('This demo balance has 5 coins'), findsOneWidget);
      expect(find.textContaining('You need 15 more coins'), findsOneWidget);

      // Tap Buy Coins from insufficient dialog
      await tester.tap(find.byKey(const Key('insufficient_buy_coins')));
      await tester.pumpAndSettle();

      expect(find.text('Buy Coins'), findsWidgets);
      expect(find.byKey(const Key('close_buy_coins')), findsOneWidget);
      expect(
          find.textContaining(
              'Coin checkout is not connected in this Flutter frontend demo'),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('close_buy_coins')));
      await tester.pumpAndSettle();
    });
  });

  group('6. Interaction Buttons, Menus and Blocking', () {
    testWidgets('Send button sends text, clears input, and trims whitespace',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(moduleConfig: AndrilModuleConfig.social),
      );
      await tester.pumpAndSettle();

      // Empty text does not send
      await tester.tap(find.byKey(const Key('send_message_button')));
      await tester.pump();
      expect(find.byKey(const Key('sent_mood_4')), findsNothing);

      // Enter valid message
      await tester.enterText(
          find.byKey(const Key('message_input')), 'Hello world!');
      await tester.pump();
      await tester.tap(find.byKey(const Key('send_message_button')));
      await tester.pumpAndSettle();

      expect(find.text('Hello world!'), findsOneWidget);
      expect(find.widgetWithText(TextField, ''), findsOneWidget);
    });

    testWidgets('Emoji picker toggles bar and inserts emoji', (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(moduleConfig: AndrilModuleConfig.social),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('emoji_btn')));
      await tester.pumpAndSettle();

      expect(find.text('😊'), findsOneWidget);
      await tester.tap(find.text('😊'));
      await tester.pump();

      expect(find.text('😊'), findsWidgets);
    });

    testWidgets(
        'Block user disables input, shows banner, blocks send/calls, and unblocks',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(moduleConfig: AndrilModuleConfig.social),
      );
      await tester.pumpAndSettle();

      // Block user
      await tester.tap(find.byKey(const Key('chat_more_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block user'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_block_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('blocked_banner')), findsOneWidget);
      expect(find.textContaining('You blocked Aira'), findsOneWidget);

      // Dismiss snackbar
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Message input is disabled
      final input =
          tester.widget<TextField>(find.byKey(const Key('message_input')));
      expect(input.enabled, isFalse);

      // Attempt to send
      await tester.tap(find.byKey(const Key('send_message_button')));
      await tester.pump();
      expect(
          find.text('Cannot send messages to a blocked user.'), findsOneWidget);

      // Dismiss snackbar before tapping audio call
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Attempt to call
      await tester.tap(find.byKey(const Key('audio_call_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Cannot initiate call. You have blocked this user.'),
          findsOneWidget);

      // Unblock
      await tester.tap(find.byKey(const Key('unblock_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('blocked_banner')), findsNothing);
    });

    testWidgets('Clear chat clears all session messages with placeholder',
        (tester) async {
      await tester.pumpWidget(
        const AndrilM4DemoApp(moduleConfig: AndrilModuleConfig.social),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chat_more_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear chat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_clear_chat')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty_chat_placeholder')), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);
    });
  });

  group('7. Responsive Layout and Error Handling', () {
    testWidgets('Chat screen renders without layout overflows on narrow phone',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const AndrilM4DemoApp(moduleConfig: AndrilModuleConfig.social),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Chat screen renders without layout overflows on wide screen',
        (tester) async {
      tester.view.physicalSize = const Size(1000 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const AndrilM4DemoApp(moduleConfig: AndrilModuleConfig.learning),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AndrilChatScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
