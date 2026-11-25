import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/features/common/ai_chat/domain/ai_chat_models.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/andril_module_app_bar.dart';

/// Core AI Chat Box Screen for the Learning Module (CF-15 / AI-01).
///
/// Features:
/// 1. First-use privacy presentation & authorization gating (AI-PRIV-02).
/// 2. Empty conversation state with learning prompt suggestions.
/// 3. Active conversation state with distinct user and assistant message bubbles.
/// 4. 500-character input maximum enforced for both Free and Premium tiers.
/// 5. Live character counter and Unicode grapheme cluster counting compatibility.
/// 6. Safe loading state, typing indicator, and duplicate submission prevention.
/// 7. Preserved user input on error with controlled retry capability.
/// 8. Strict owner-scoped access verification failing closed for mismatched profiles/modules.
/// 9. Private conversation state clearing on identity switch or access revocation.
/// 10. Disconnected presentation indicating remote AI backend integration is pending.
/// 11. Fully responsive across 320dp, 360dp, 412dp viewports and 1.5x text scaling.
class LearningAiChatScreen extends StatefulWidget {
  /// Current authenticated user ID used for owner access verification.
  final String currentUserId;

  /// The authorized owner Learning module profile ID.
  final String ownerLearningProfileId;

  /// The active module (must be 'learning').
  final String module;

  /// Optional initial conversation state.
  final AiConversation? initialConversation;

  /// Whether the user has a Premium subscription (limits remain strictly 500).
  final bool isPremiumUser;

  /// Optional message sender callback (e.g. for mock responses or test fixtures).
  final Future<void> Function(String prompt)? onSendMessage;

  /// Optional callback invoked when the user accepts the first-use privacy notice.
  final VoidCallback? onPrivacyAccepted;

  /// Whether access to this AI chat has been explicitly revoked or denied.
  final bool isAccessDenied;

  /// Whether the screen is currently in a loading state.
  final bool isLoading;

  /// Optional initial error message to display.
  final String? initialError;

  /// Optional custom app bar. Defaults to [AndrilModuleAppBar] with Learning branding.
  final PreferredSizeWidget? appBar;

  const LearningAiChatScreen({
    super.key,
    required this.currentUserId,
    required this.ownerLearningProfileId,
    this.module = 'learning',
    this.initialConversation,
    this.isPremiumUser = false,
    this.onSendMessage,
    this.onPrivacyAccepted,
    this.isAccessDenied = false,
    this.isLoading = false,
    this.initialError,
    this.appBar,
  });

  @override
  State<LearningAiChatScreen> createState() => _LearningAiChatScreenState();
}

class _LearningAiChatScreenState extends State<LearningAiChatScreen> {
  late AiConversation _conversation;
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  late bool _hasAcceptedPrivacyNotice;
  bool _isSending = false;
  String? _activeError;
  String? _lastSubmittedPrompt;

  static const List<String> _suggestedPrompts = [
    'Structure a 4-week study plan',
    'Explain Flutter state management',
    'Tips for system design interviews',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    _conversation = widget.initialConversation ??
        AiConversation(
          conversationId: const Uuid().v4(),
          ownerLearningProfileId: widget.ownerLearningProfileId,
          module: widget.module,
        );
    _hasAcceptedPrivacyNotice = _conversation.hasAcceptedPrivacyNotice ||
        (widget.initialConversation?.hasAcceptedPrivacyNotice ?? false);
    _activeError = widget.initialError;

    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(LearningAiChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Identity change or access revocation clears private conversation state
    final identityChanged = oldWidget.currentUserId != widget.currentUserId ||
        oldWidget.ownerLearningProfileId != widget.ownerLearningProfileId;
    final accessRevoked = !oldWidget.isAccessDenied && widget.isAccessDenied;

    if (identityChanged || accessRevoked) {
      _clearPrivateState();
    }

    if (oldWidget.initialError != widget.initialError) {
      _activeError = widget.initialError;
    }
  }

  void _clearPrivateState() {
    setState(() {
      _conversation = _conversation.clearMessages();
      _textController.clear();
      _activeError = null;
      _lastSubmittedPrompt = null;
      _isSending = false;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ACCESS VALIDATION
  // ===========================================================================

  bool get _hasAccess {
    if (widget.isAccessDenied) return false;
    if (widget.currentUserId.trim().isEmpty) return false;
    if (widget.currentUserId != widget.ownerLearningProfileId) return false;
    if (widget.module != 'learning') return false;
    return true;
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  void _handleAcceptPrivacy() {
    setState(() {
      _hasAcceptedPrivacyNotice = true;
      _conversation = _conversation.copyWith(hasAcceptedPrivacyNotice: true);
    });
    widget.onPrivacyAccepted?.call();
  }

  Future<void> _handleSend() async {
    final rawText = _textController.text;
    if (!AiInputValidator.isValidInput(rawText) ||
        _isSending ||
        widget.isLoading) {
      return;
    }

    final prompt = rawText.trim();
    _lastSubmittedPrompt = prompt;
    _textController.clear();

    final userMessage = AiChatMessage(
      id: const Uuid().v4(),
      role: AiChatRole.user,
      text: prompt,
      timestamp: DateTime.now().toUtc(),
    );

    setState(() {
      _conversation = _conversation.addMessage(userMessage);
      _isSending = true;
      _activeError = null;
    });

    _scrollToBottom();

    try {
      if (widget.onSendMessage != null) {
        await widget.onSendMessage!(prompt);
      } else {
        // Disconnected baseline: Record pending service notice without fabricating AI text
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final pendingNotice = AiChatMessage(
          id: const Uuid().v4(),
          role: AiChatRole.assistant,
          text: AiInputValidator.disconnectedNotice,
          timestamp: DateTime.now().toUtc(),
        );
        if (mounted) {
          setState(() {
            _conversation = _conversation.addMessage(pendingNotice);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeError =
              'Failed to receive AI response. Your prompt has been preserved.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _handleRetry() {
    if (_lastSubmittedPrompt != null && _lastSubmittedPrompt!.isNotEmpty) {
      _textController.text = _lastSubmittedPrompt!;
      setState(() {
        _activeError = null;
      });
      _handleSend();
    }
  }

  void _handleSelectSuggestion(String suggestion) {
    _textController.text = suggestion;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: widget.appBar ??
          const AndrilModuleAppBar(
            moduleName: 'AI Assistant',
            badgeColor: LearningColors.primary,
          ),
      body: SafeArea(
        child: !_hasAccess
            ? _buildAccessDeniedState()
            : !_hasAcceptedPrivacyNotice
                ? _buildPrivacyNoticeState()
                : _buildChatInterface(),
      ),
    );
  }

  // ===========================================================================
  // STATE WIDGETS
  // ===========================================================================

  Widget _buildAccessDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          key: const Key('access_denied_card'),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: LearningColors.cardSurface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gpp_bad_outlined,
                  size: 48.0, color: Color(0xFFDC2626)),
              SizedBox(height: 16.0),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'You do not have permission to access this Learning AI Chat Box.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: LearningColors.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyNoticeState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          key: const Key('ai_privacy_notice_card'),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: LearningColors.cardSurface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10.0,
                runSpacing: 4.0,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: LearningColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_outlined,
                      color: LearningColors.primary,
                      size: 24.0,
                    ),
                  ),
                  const Text(
                    'Learning AI Privacy Notice',
                    key: Key('privacy_notice_title'),
                    style: TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                      color: LearningColors.heading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Before using the Learning AI Assistant, please review our privacy and usage principles:',
                style: TextStyle(
                  fontSize: 13.5,
                  color: LearningColors.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14.0),
              _buildPrivacyBullet(
                icon: Icons.lock_outline,
                title: 'Module Isolation',
                description:
                    'Prompts and conversations are strictly isolated to your Learning profile. No cross-module leakage.',
              ),
              const SizedBox(height: 10.0),
              _buildPrivacyBullet(
                icon: Icons.shield_outlined,
                title: 'Data Confidentiality',
                description:
                    'Your private diary, human chats, and profile content are never shared or used to train public AI models.',
              ),
              const SizedBox(height: 10.0),
              _buildPrivacyBullet(
                icon: Icons.lightbulb_outline,
                title: 'Advisory Guidance',
                description:
                    'AI responses provide learning support and guidance. Please independently review important academic facts.',
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('accept_ai_privacy_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LearningColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: _handleAcceptPrivacy,
                  child: const Text(
                    'I Understand & Continue',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyBullet({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.0, color: LearningColors.primary),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: LearningColors.secondaryText,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CHAT INTERFACE
  // ===========================================================================

  Widget _buildChatInterface() {
    final messages = _conversation.messages;

    return Column(
      children: [
        // Disconnected Notice Banner
        Container(
          key: const Key('ai_disconnected_notice'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
          color: const Color(0xFFEFF6FF),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 15.0, color: Color(0xFF1D4ED8)),
              SizedBox(width: 6.0),
              Flexible(
                child: Text(
                  AiInputValidator.disconnectedNotice,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Error Banner with Retry
        if (_activeError != null) _buildErrorBanner(),

        // Chat Body (Empty or Active)
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState()
              : _buildActiveMessagesList(messages),
        ),

        // Typing / Loading Indicator
        if (_isSending || widget.isLoading) _buildTypingIndicator(),

        // Input Bar
        _buildInputBar(),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      key: const Key('ai_error_card'),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF2F2),
        border: Border(bottom: BorderSide(color: Color(0xFFFCA5A5))),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 20.0, color: Color(0xFFDC2626)),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              _activeError!,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_lastSubmittedPrompt != null)
            TextButton(
              key: const Key('ai_retry_button'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: _handleRetry,
              child: const Text('Retry',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          IconButton(
            key: const Key('ai_dismiss_error_button'),
            icon: const Icon(Icons.close, size: 18.0),
            color: const Color(0xFF991B1B),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => setState(() => _activeError = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        key: const Key('ai_empty_chat_view'),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: LearningColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 40.0,
                color: LearningColors.primary,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'How can I help your learning today?',
              key: Key('empty_chat_heading'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Ask questions, clarify concepts, or explore suggestions below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: LearningColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24.0),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.0,
              runSpacing: 8.0,
              children: _suggestedPrompts.asMap().entries.map((entry) {
                final index = entry.key;
                final text = entry.value;
                return ActionChip(
                  key: Key('suggestion_chip_$index'),
                  avatar: const Icon(Icons.chat_bubble_outline, size: 14.0),
                  label: Text(text, style: const TextStyle(fontSize: 12.0)),
                  backgroundColor: LearningColors.cardSurface,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  onPressed: () => _handleSelectSuggestion(text),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMessagesList(List<AiChatMessage> messages) {
    return ListView.builder(
      key: const Key('ai_messages_list'),
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(AiChatMessage message) {
    final isUser = message.role == AiChatRole.user;
    final timeFormatted =
        DateFormat('h:mm a').format(message.timestamp.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8.0, top: 2.0),
              padding: const EdgeInsets.all(6.0),
              decoration: const BoxDecoration(
                color: LearningColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 14.0, color: Colors.white),
            ),
          ],
          Flexible(
            child: Container(
              key: Key(isUser
                  ? 'ai_message_user_${message.id}'
                  : 'ai_message_assistant_${message.id}'),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isUser
                    ? LearningColors.primary
                    : message.isError
                        ? const Color(0xFFFEF2F2)
                        : LearningColors.cardSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14.0),
                  topRight: const Radius.circular(14.0),
                  bottomLeft: Radius.circular(isUser ? 14.0 : 4.0),
                  bottomRight: Radius.circular(isUser ? 4.0 : 14.0),
                ),
                border: Border.all(
                  color: isUser
                      ? LearningColors.primary
                      : message.isError
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isUser ? Colors.white : LearningColors.heading,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    timeFormatted,
                    key: Key('ai_message_timestamp_${message.id}'),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.75)
                          : LearningColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      key: const Key('ai_typing_indicator'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5.0),
            decoration: const BoxDecoration(
              color: LearningColors.primary,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.auto_awesome, size: 12.0, color: Colors.white),
          ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: LearningColors.cardSurface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14.0,
                    height: 14.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: LearningColors.primary,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      'AI Assistant is thinking...',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: LearningColors.secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final text = _textController.text;
    final count = AiInputValidator.countTextElements(text);
    final isOversized = count > AiInputValidator.maxUserTextElements;
    final canSubmit =
        AiInputValidator.isValidInput(text) && !_isSending && !widget.isLoading;

    return Container(
      key: const Key('ai_chat_input_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('ai_chat_input_field'),
                  controller: _textController,
                  enabled: !_isSending && !widget.isLoading,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: AiInputValidator.maxUserTextElements,
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) {
                    return null; // Custom live counter rendered below
                  },
                  decoration: const InputDecoration(
                    hintText: 'Ask Learning AI Assistant...',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF94A3B8),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 10.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      borderSide:
                          BorderSide(color: LearningColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Semantics(
                button: true,
                label: 'Send AI prompt',
                child: IconButton(
                  key: const Key('ai_send_button'),
                  icon: const Icon(Icons.send_rounded),
                  color: LearningColors.primary,
                  disabledColor: const Color(0xFFCBD5E1),
                  constraints:
                      const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                  onPressed: canSubmit ? _handleSend : null,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$count/${AiInputValidator.maxUserTextElements}',
                  key: const Key('ai_char_counter'),
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                    color: isOversized
                        ? const Color(0xFFDC2626)
                        : count > 450
                            ? const Color(0xFFD97706)
                            : LearningColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
