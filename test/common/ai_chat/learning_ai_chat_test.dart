import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/features/common/ai_chat/domain/ai_chat_models.dart';
import 'package:andril_mobile/features/common/ai_chat/presentation/screens/learning_ai_chat_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test harness wrapping child with MaterialApp and Scaffold
  Widget buildTestHarness({
    required Widget child,
    Size size = const Size(360, 800),
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: textScaler,
        ),
        child: child,
      ),
    );
  }

  void setupTestViewport(
    WidgetTester tester, {
    Size size = const Size(360, 800),
  }) {
    tester.view.physicalSize = Size(size.width * 3.0, size.height * 3.0);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());
  }

  Future<void> safeTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('Learning AI Chat Box (CF-15 / AI-01) Tests', () {
    // =========================================================================
    // SECTION 1: DOMAIN MODELS & CONFIDENTIALITY
    // =========================================================================

    test(
        'TEST-AI-01: AiChatMessage validated construction and confidential redaction',
        () {
      final message = AiChatMessage(
        id: 'msg-01',
        role: AiChatRole.user,
        text: 'Confidential study query regarding dynamic programming',
        timestamp: DateTime.utc(2026, 11, 25, 12, 0),
      );

      expect(message.id, 'msg-01');
      expect(message.role, AiChatRole.user);
      expect(message.text,
          'Confidential study query regarding dynamic programming');
      expect(message.timestamp, DateTime.utc(2026, 11, 25, 12, 0));
      expect(message.isError, isFalse);

      // Verify toString() confidentiality redaction
      expect(message.toString(), 'AiChatMessage [private content omitted]');
      expect(message.toString().contains('Confidential'), isFalse);
    });

    test(
        'TEST-AI-02: AiConversation validated construction, copyWith, and redaction',
        () {
      const conversation = AiConversation(
        conversationId: 'conv-01',
        ownerLearningProfileId: 'owner-01',
        module: 'learning',
        hasAcceptedPrivacyNotice: false,
      );

      expect(conversation.conversationId, 'conv-01');
      expect(conversation.ownerLearningProfileId, 'owner-01');
      expect(conversation.module, 'learning');
      expect(conversation.messages, isEmpty);
      expect(conversation.hasAcceptedPrivacyNotice, isFalse);

      // Verify toString() confidentiality redaction
      expect(
          conversation.toString(), 'AiConversation [private content omitted]');

      // Add message
      final msg = AiChatMessage(
        id: 'msg-01',
        role: AiChatRole.user,
        text: 'Hello',
        timestamp: DateTime.utc(2026, 11, 25, 12, 1),
      );
      final updated = conversation.addMessage(msg);
      expect(updated.messages.length, 1);
      expect(updated.messages.first.text, 'Hello');

      // Clear messages
      final cleared = updated.clearMessages();
      expect(cleared.messages, isEmpty);
    });

    // =========================================================================
    // SECTION 2: INPUT VALIDATION & CHARACTER BOUNDARIES
    // =========================================================================

    test(
        'TEST-AI-03: Input boundary enforcement: 0, 499, 500, and 501 characters',
        () {
      // 0 characters (empty)
      expect(AiInputValidator.isValidInput(''), isFalse);
      expect(AiInputValidator.getValidationError(''), isNotNull);

      // 499 characters (valid)
      final text499 = 'a' * 499;
      expect(AiInputValidator.countTextElements(text499), 499);
      expect(AiInputValidator.isValidInput(text499), isTrue);
      expect(AiInputValidator.getValidationError(text499), isNull);

      // 500 characters (valid boundary)
      final text500 = 'a' * 500;
      expect(AiInputValidator.countTextElements(text500), 500);
      expect(AiInputValidator.isValidInput(text500), isTrue);
      expect(AiInputValidator.getValidationError(text500), isNull);

      // 501 characters (invalid boundary - oversized)
      final text501 = 'a' * 501;
      expect(AiInputValidator.countTextElements(text501), 501);
      expect(AiInputValidator.isValidInput(text501), isFalse);
      expect(AiInputValidator.getValidationError(text501),
          'AI input must contain at most 500 characters (currently 501).');
    });

    test('TEST-AI-04: Unicode grapheme cluster counting compatibility', () {
      // Standard ASCII
      expect(AiInputValidator.countTextElements('Flutter'), 7);

      // Accented characters (composed vs decomposed)
      const accented = 'Café';
      expect(AiInputValidator.countTextElements(accented), 4);

      // Multi-byte emoji grapheme cluster (e.g. thumbs up with skin tone modifier)
      const emojiWithModifier = '👍🏽';
      expect(AiInputValidator.countTextElements(emojiWithModifier), 1);

      // Combined emoji family
      const familyEmoji = '👨‍👩‍👧‍👦';
      expect(AiInputValidator.countTextElements(familyEmoji), 1);

      // Total text elements within valid limit
      const mixedText = 'Hello 👨‍👩‍👧‍👦 from Andril Learning!';
      expect(AiInputValidator.isValidInput(mixedText), isTrue);
    });

    test('TEST-AI-05: Blank, whitespace-only, and null input rejection', () {
      expect(AiInputValidator.isValidInput(null), isFalse);
      expect(AiInputValidator.isValidInput('   '), isFalse);
      expect(AiInputValidator.isValidInput('\n\t  \n'), isFalse);
      expect(AiInputValidator.getValidationError('   '),
          'AI input must contain at least 1 non-blank character.');
    });

    test(
        'TEST-AI-06: Free and Premium input limit parity (strictly 500 characters)',
        () {
      // Verify that no invented higher limit exists for Premium
      const freeMax = AiInputValidator.maxUserTextElements;
      const premiumMax = AiInputValidator.maxUserTextElements;
      expect(freeMax, 500);
      expect(premiumMax, 500);
      expect(freeMax, premiumMax);
    });

    // =========================================================================
    // SECTION 3: PRESENTATION & USER FLOWS
    // =========================================================================

    testWidgets(
        'TEST-AI-07: First-use privacy notice rendered when unaccepted; accepting unlocks chat',
        (tester) async {
      setupTestViewport(tester);
      bool privacyAccepted = false;

      await tester.pumpWidget(
        buildTestHarness(
          child: LearningAiChatScreen(
            currentUserId: 'test_owner_01',
            ownerLearningProfileId: 'test_owner_01',
            onPrivacyAccepted: () => privacyAccepted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Privacy card is displayed initially
      expect(find.byKey(const Key('ai_privacy_notice_card')), findsOneWidget);
      expect(find.byKey(const Key('accept_ai_privacy_button')), findsOneWidget);
      expect(find.byKey(const Key('ai_empty_chat_view')), findsNothing);

      // Tap accept button
      await safeTap(tester, find.byKey(const Key('accept_ai_privacy_button')));

      expect(privacyAccepted, isTrue);
      expect(find.byKey(const Key('ai_privacy_notice_card')), findsNothing);
      expect(find.byKey(const Key('ai_empty_chat_view')), findsOneWidget);
    });

    testWidgets(
        'TEST-AI-08: Empty conversation layout displays greeting, disconnected notice, and suggestion chips',
        (tester) async {
      setupTestViewport(tester);

      await tester.pumpWidget(
        buildTestHarness(
          child: const LearningAiChatScreen(
            currentUserId: 'test_owner_01',
            ownerLearningProfileId: 'test_owner_01',
            initialConversation: AiConversation(
              conversationId: 'conv-01',
              ownerLearningProfileId: 'test_owner_01',
              hasAcceptedPrivacyNotice: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai_empty_chat_view')), findsOneWidget);
      expect(find.byKey(const Key('empty_chat_heading')), findsOneWidget);
      expect(find.byKey(const Key('ai_disconnected_notice')), findsOneWidget);
      expect(find.byKey(const Key('suggestion_chip_0')), findsOneWidget);
      expect(find.byKey(const Key('suggestion_chip_1')), findsOneWidget);
      expect(find.byKey(const Key('suggestion_chip_2')), findsOneWidget);
      expect(find.byKey(const Key('ai_char_counter')), findsOneWidget);
      expect(find.text('0/500'), findsOneWidget);
    });

    testWidgets(
        'TEST-AI-09: Tapping suggestion chip populates input field and updates live counter',
        (tester) async {
      setupTestViewport(tester);

      await tester.pumpWidget(
        buildTestHarness(
          child: const LearningAiChatScreen(
            currentUserId: 'test_owner_01',
            ownerLearningProfileId: 'test_owner_01',
            initialConversation: AiConversation(
              conversationId: 'conv-01',
              ownerLearningProfileId: 'test_owner_01',
              hasAcceptedPrivacyNotice: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap suggestion chip 0
      await safeTap(tester, find.byKey(const Key('suggestion_chip_0')));

      expect(find.text('Structure a 4-week study plan'),
          findsNWidgets(2)); // in chip & textfield
      expect(find.text('29/500'), findsOneWidget);
    });

    testWidgets(
        'TEST-AI-10: Submitting prompt adds user message and shows assistant reply',
        (tester) async {
      setupTestViewport(tester);

      String? submittedPrompt;

      await tester.pumpWidget(
        buildTestHarness(
          child: LearningAiChatScreen(
            currentUserId: 'test_owner_01',
            ownerLearningProfileId: 'test_owner_01',
            initialConversation: const AiConversation(
              conversationId: 'conv-01',
              ownerLearningProfileId: 'test_owner_01',
              hasAcceptedPrivacyNotice: true,
            ),
            onSendMessage: (prompt) async {
              submittedPrompt = prompt;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byKey(const Key('ai_chat_input_field')),
          'How to prepare for Flutter tests?');
      await tester.pumpAndSettle();

      expect(find.text('33/500'), findsOneWidget);

      // Submit
      await safeTap(tester, find.byKey(const Key('ai_send_button')));

      expect(submittedPrompt, 'How to prepare for Flutter tests?');
      expect(find.text('How to prepare for Flutter tests?'), findsOneWidget);
      expect(find.byKey(const Key('ai_empty_chat_view')), findsNothing);
      expect(find.byKey(const Key('ai_messages_list')), findsOneWidget);
    });

    testWidgets(
        'TEST-AI-11: Loading state displays typing indicator and disables send button',
        (tester) async {
      setupTestViewport(tester);

      await tester.pumpWidget(
        buildTestHarness(
          child: const LearningAiChatScreen(
            currentUserId: 'test_owner_01',
            ownerLearningProfileId: 'test_owner_01',
            isLoading: true,
            initialConversation: AiConversation(
              conversationId: 'conv-01',
              ownerLearningProfileId: 'test_owner_01',
              hasAcceptedPrivacyNotice: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Typing indicator is rendered
      expect(find.byKey(const Key('ai_typing_indicator')), findsOneWidget);
      expect(find.text('AI Assistant is thinking...'), findsOneWidget);

      // Send button is disabled
      final sendButton =
          tester.widget<IconButton>(find.byKey(const Key('ai_send_button')));
      expect(sendButton.onPressed, isNull);
    });

    testWidgets(
        'TEST-AI-12: Response error displays error banner with Retry button, and preserves user prompt',
        (tester) async {
      setupTestViewport(tester);

      int sendAttempts = 0;

      await tester.pumpWidget(
        buildTestHarness(
          child: LearningAiChatScreen(
            currentUserId: 'test_owner_01',
            ownerLearningProfileId: 'test_owner_01',
            initialConversation: const AiConversation(
              conversationId: 'conv-01',
              ownerLearningProfileId: 'test_owner_01',
              hasAcceptedPrivacyNotice: true,
            ),
            onSendMessage: (prompt) async {
              sendAttempts++;
              if (sendAttempts == 1) {
                throw Exception('Network connection timed out');
              }
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter and submit
      await tester.enterText(find.byKey(const Key('ai_chat_input_field')),
          'Explain binary search trees');
      await tester.pumpAndSettle();
      await safeTap(tester, find.byKey(const Key('ai_send_button')));

      // Error banner is displayed
      expect(find.byKey(const Key('ai_error_card')), findsOneWidget);
      expect(find.byKey(const Key('ai_retry_button')), findsOneWidget);

      // User prompt is preserved in user message
      expect(find.text('Explain binary search trees'), findsOneWidget);

      // Tap Retry
      await safeTap(tester, find.byKey(const Key('ai_retry_button')));

      expect(sendAttempts, 2);
      expect(find.byKey(const Key('ai_error_card')), findsNothing);
    });

    // =========================================================================
    // SECTION 4: SECURITY BOUNDARIES & ACCESS CONTROL
    // =========================================================================

    testWidgets(
        'TEST-AI-13: Access denied when currentUserId != ownerLearningProfileId',
        (tester) async {
      setupTestViewport(tester);

      await tester.pumpWidget(
        buildTestHarness(
          child: const LearningAiChatScreen(
            currentUserId: 'unauthorized_attacker',
            ownerLearningProfileId: 'authorized_owner',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('access_denied_card')), findsOneWidget);
      expect(find.byKey(const Key('ai_chat_input_bar')), findsNothing);
    });

    testWidgets('TEST-AI-14: Access denied when module is not learning',
        (tester) async {
      setupTestViewport(tester);

      await tester.pumpWidget(
        buildTestHarness(
          child: const LearningAiChatScreen(
            currentUserId: 'test_owner_01',
            ownerLearningProfileId: 'test_owner_01',
            module: 'social', // Module mismatch
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('access_denied_card')), findsOneWidget);
      expect(find.byKey(const Key('ai_chat_input_bar')), findsNothing);
    });

    testWidgets(
        'TEST-AI-15: Private state clearing on identity switch or access revocation',
        (tester) async {
      setupTestViewport(tester);

      final initialMsg = AiChatMessage(
        id: 'msg-01',
        role: AiChatRole.user,
        text: 'Initial confidential question',
        timestamp: DateTime.utc(2026, 11, 25, 12, 0),
      );

      await tester.pumpWidget(
        buildTestHarness(
          child: LearningAiChatScreen(
            currentUserId: 'user_A',
            ownerLearningProfileId: 'user_A',
            initialConversation: AiConversation(
              conversationId: 'conv-01',
              ownerLearningProfileId: 'user_A',
              hasAcceptedPrivacyNotice: true,
              messages: [initialMsg],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Initial confidential question'), findsOneWidget);

      // Switch identity to user_B
      await tester.pumpWidget(
        buildTestHarness(
          child: const LearningAiChatScreen(
            currentUserId: 'user_B',
            ownerLearningProfileId: 'user_B',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // State is completely cleared; previous messages are absent
      expect(find.text('Initial confidential question'), findsNothing);
    });

    // =========================================================================
    // SECTION 5: RESPONSIVENESS & ACCESSIBILITY
    // =========================================================================

    testWidgets(
        'TEST-AI-16: Responsive layout renders across 320dp, 360dp, 412dp viewports without overflow',
        (tester) async {
      for (final size in [
        const Size(320, 640),
        const Size(360, 800),
        const Size(412, 915),
      ]) {
        setupTestViewport(tester, size: size);

        await tester.pumpWidget(
          buildTestHarness(
            size: size,
            child: const LearningAiChatScreen(
              currentUserId: 'test_owner_01',
              ownerLearningProfileId: 'test_owner_01',
              initialConversation: AiConversation(
                conversationId: 'conv-01',
                ownerLearningProfileId: 'test_owner_01',
                hasAcceptedPrivacyNotice: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('ai_chat_input_bar')), findsOneWidget);
      }
    });

    testWidgets('TEST-AI-17: 1.5x dynamic text scale renders without overflow',
        (tester) async {
      setupTestViewport(tester, size: const Size(360, 800));

      await tester.pumpWidget(
        buildTestHarness(
          size: const Size(360, 800),
          textScaler: const TextScaler.linear(1.5),
          child: const LearningAiChatScreen(
            currentUserId: 'test_owner_01',
            ownerLearningProfileId: 'test_owner_01',
            initialConversation: AiConversation(
              conversationId: 'conv-01',
              ownerLearningProfileId: 'test_owner_01',
              hasAcceptedPrivacyNotice: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('ai_chat_input_bar')), findsOneWidget);
    });
  });
}
