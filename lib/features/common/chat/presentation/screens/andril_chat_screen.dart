import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:andril_mobile/app/themes/common/chat_theme.dart';
import 'package:andril_mobile/features/common/chat/domain/entities/chat_models.dart';
import 'package:andril_mobile/features/common/chat/domain/module_config.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chats_list_screen.dart';
import 'package:andril_mobile/features/common/chat/presentation/widgets/andril_chat_background.dart';
import 'package:andril_mobile/features/common/chat/presentation/widgets/andril_profile_avatar.dart';
import 'package:andril_mobile/features/common/virtual_gifts/presentation/widgets/gift_picker_sheet.dart';
import 'package:andril_mobile/features/social/moodtone/presentation/widgets/mood_tone_selector.dart';

/// Reusable ANDRIL Chat Screen faithfully reproducing the exact HTML prototypes:
/// - Learning: https://andrillearning.netlify.app
/// - Hobbies: https://andrilhobby.netlify.app
/// - Social: https://andrilsocial.netlify.app
///
/// Strictly enforces module isolation:
/// - No cross-module switcher or cards inside Chat.
/// - Injected with the authenticated module context.
/// - MoodTone is enabled ONLY when module == Social.
/// - Dynamically supports conversation partners while enforcing module scope.
class AndrilChatScreen extends StatefulWidget {
  final AndrilModuleConfig moduleConfig;
  final AndrilModuleProfile? partner;
  final String? conversationId;
  final int initialBalance; // Test-only MOCK coin balance
  final bool initialBlocked;
  final VoidCallback? onBackPressed;

  const AndrilChatScreen({
    super.key,
    required this.moduleConfig,
    this.partner,
    this.conversationId,
    this.initialBalance = 40,
    this.initialBlocked = false,
    this.onBackPressed,
  });

  /// Factory constructor for Learning module chat.
  factory AndrilChatScreen.learning({
    AndrilModuleProfile? partner,
    String? conversationId,
    int initialBalance = 40,
    bool initialBlocked = false,
  }) =>
      AndrilChatScreen(
        moduleConfig: AndrilModuleConfig.learning,
        partner: partner,
        conversationId: conversationId,
        initialBalance: initialBalance,
        initialBlocked: initialBlocked,
      );

  /// Factory constructor for Hobbies module chat.
  factory AndrilChatScreen.hobbies({
    AndrilModuleProfile? partner,
    String? conversationId,
    int initialBalance = 40,
    bool initialBlocked = false,
  }) =>
      AndrilChatScreen(
        moduleConfig: AndrilModuleConfig.hobbies,
        partner: partner,
        conversationId: conversationId,
        initialBalance: initialBalance,
        initialBlocked: initialBlocked,
      );

  /// Factory constructor for Social module chat.
  factory AndrilChatScreen.social({
    AndrilModuleProfile? partner,
    String? conversationId,
    int initialBalance = 40,
    bool initialBlocked = false,
  }) =>
      AndrilChatScreen(
        moduleConfig: AndrilModuleConfig.social,
        partner: partner,
        conversationId: conversationId,
        initialBalance: initialBalance,
        initialBlocked: initialBlocked,
      );

  /// Effective conversation partner, validating module isolation strictly.
  AndrilModuleProfile get effectivePartner {
    final p = partner;
    if (p != null) {
      if (p.moduleType != moduleConfig.type) {
        throw ArgumentError(
          'Cross-module partner ${p.name} (${p.moduleType.name}) cannot be selected in ${moduleConfig.name} Chat.',
        );
      }
      return p;
    }
    return moduleConfig.defaultPartner;
  }

  @override
  State<AndrilChatScreen> createState() => _AndrilChatScreenState();
}

class _AndrilChatScreenState extends State<AndrilChatScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  late int _balance;
  late bool _isBlocked;
  bool _attachmentsOpen = false;
  bool _emojiMenuOpen = false;
  bool _giftActionPending = false;
  MoodTone? _selectedTone;

  late List<ChatEntry> _entries;

  AndrilModuleProfile get effectivePartner => widget.effectivePartner;

  Key _avatarKey(String name) {
    if (name.toLowerCase().contains('ava')) return const Key('ava_avatar');
    if (name.toLowerCase().contains('aira')) return const Key('aira_avatar');
    return Key('${name.toLowerCase()}_avatar');
  }

  Key _profileKey(String name) {
    if (name.toLowerCase().contains('ava')) return const Key('ava_profile');
    if (name.toLowerCase().contains('aira')) return const Key('aira_profile');
    return Key('${name.toLowerCase()}_profile');
  }

  @override
  void initState() {
    super.initState();
    _balance = widget.initialBalance;
    _isBlocked = widget.initialBlocked;
    _entries = _seedInitialMessages(
      widget.moduleConfig.type,
      widget.conversationId,
      effectivePartner.name,
    );
    _composer.addListener(_onComposerUpdated);
  }

  @override
  void dispose() {
    _composer.removeListener(_onComposerUpdated);
    _composer.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  /// Initial sample messages matching each conversation and HTML prototype.
  List<ChatEntry> _seedInitialMessages(
    AndrilModuleType moduleType,
    String? conversationId,
    String partnerName,
  ) {
    if (conversationId == 'soc_ava' ||
        partnerName.toLowerCase().contains('ava')) {
      return [
        const ChatEntry(
          sent: false,
          text: 'Hey! Are we still meeting up this week? ☕',
          time: 'Yesterday',
        ),
        const ChatEntry(
          sent: true,
          text: 'Yes definitely! How about tomorrow afternoon?',
          time: 'Yesterday ✓✓',
        ),
        const ChatEntry(
          sent: false,
          text: 'See you at the coffee shop tomorrow! ☕',
          time: 'Yesterday',
        ),
      ];
    }
    switch (moduleType) {
      case AndrilModuleType.learning:
        return [
          const ChatEntry(
            sent: false,
            text: 'Hey! How is your Flutter learning going? 😊',
            time: '05:20 PM',
          ),
          const ChatEntry(
            sent: true,
            text:
                "It's going well! 📘 I'm practicing widgets and layouts today.",
            time: '05:22 PM ✓✓',
          ),
          const ChatEntry(
            sent: false,
            text: "That's great! Let's review our notes together this weekend.",
            time: '05:24 PM',
          ),
          const ChatEntry(
            sent: false,
            text: "I'll share my study checklist with you too! 📝",
            time: '05:24 PM',
          ),
        ];

      case AndrilModuleType.hobbies:
        return [
          const ChatEntry(
            sent: false,
            text: 'Hey! What hobbies have you been into lately? 😊',
            time: '05:20 PM',
          ),
          const ChatEntry(
            sent: true,
            text:
                "I've been cycling a lot! 🚴 It's such a refreshing way to unwind.",
            time: '05:22 PM ✓✓',
          ),
          const ChatEntry(
            sent: false,
            text: "That's awesome! I'm planning a camping trip this weekend. ⛺",
            time: '05:24 PM',
          ),
          const ChatEntry(
            sent: false,
            text:
                'We can also bring my camera and do some photography there! 📸',
            time: '05:24 PM',
          ),
        ];

      case AndrilModuleType.social:
        return [
          const ChatEntry(
            sent: false,
            text: 'Hey! Great to hear from you 😊',
            time: '05:20 PM',
          ),
          const ChatEntry(
            sent: true,
            text: 'How’s your day going?',
            time: '05:22 PM ✓✓',
          ),
          const ChatEntry(
            sent: false,
            text: 'Pretty good! Just finished my class and now relaxing ✨',
            time: '05:24 PM',
          ),
          const ChatEntry(
            sent: false,
            text: 'What about you?',
            time: '05:24 PM',
          ),
        ];
    }
  }

  void _onComposerUpdated() {
    if (!mounted) return;
    if (_composer.text.trim().isEmpty) {
      _selectedTone = null;
    }
    setState(() {});
  }

  void _scrollEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _mockTime() => '05:25 PM';

  void _sendMessage() {
    if (_isBlocked) {
      _showSnackbar('Cannot send messages to a blocked user.');
      return;
    }
    final text = _composer.text.trim();
    if (text.isEmpty) {
      _inputFocus.requestFocus();
      return;
    }
    setState(() {
      _entries.add(
        ChatEntry(
          sent: true,
          text: text,
          time: '${_mockTime()} ✓✓',
          mood: widget.moduleConfig.supportsMoodTone ? _selectedTone : null,
        ),
      );
      _selectedTone = null;
      _attachmentsOpen = false;
      _emojiMenuOpen = false;
      _composer.clear();
    });
    _inputFocus.unfocus();
    _scrollEnd();
  }

  void _addGiftSticker(AndrilGift gift) {
    setState(() {
      _balance -= gift.coins; // MOCK deduction; no financial authority
      _entries.add(
        ChatEntry(
          type: ChatContentType.giftSticker,
          sent: true,
          text: gift.name,
          time: '${_mockTime()} ✓✓',
          imagePath: gift.stickerAsset,
        ),
      );
    });
    _scrollEnd();
  }

  Future<void> _pickAttachment({required bool image}) async {
    setState(() {
      _attachmentsOpen = false;
      _emojiMenuOpen = false;
    });
    try {
      final file = await FilePicker.pickFile(
        type: image ? FileType.image : FileType.any,
      );
      if (!mounted || file == null) return;
      if (file.path == null) {
        _showSnackbar('This file has no readable local preview.');
        return;
      }
      setState(() {
        _entries.add(
          ChatEntry(
            type: image
                ? ChatContentType.imagePreview
                : ChatContentType.filePreview,
            sent: true,
            text: file.name,
            time: '${_mockTime()} ✓✓',
            imagePath: file.path,
            isLocalFile: true,
          ),
        );
      });
      _scrollEnd();
      _showSnackbar('Local preview only — MOCK, not uploaded');
    } catch (_) {
      if (mounted) _showSnackbar('Could not open file picker.');
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showInfoDialog(String title, String description) async {
    final theme = widget.moduleConfig.theme;
    final partner = effectivePartner;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            AndrilProfileAvatar(
              avatarAsset: partner.avatarAsset,
              moduleType: widget.moduleConfig.type,
              size: 70,
              borderWidth: 3,
              fallbackInitial: partner.name.isNotEmpty ? partner.name[0] : '?',
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.primary,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(description, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBuyCoinsDialog() async {
    final theme = widget.moduleConfig.theme;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Buy Coins',
          style: TextStyle(
            color: theme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Coin checkout is not connected in this Flutter frontend demo. No purchase or credit occurs.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            key: const Key('close_buy_coins'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showInsufficientCoinsDialog(AndrilGift gift) async {
    final theme = widget.moduleConfig.theme;
    final need = gift.coins - _balance;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Not enough coins',
          style: TextStyle(
            color: theme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 80,
              child: Image.asset(gift.assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            Text(
              'This demo balance has $_balance coins. This gift needs ${gift.coins} coins.\nYou need $need more coins to send this gift.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('insufficient_buy_coins'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showBuyCoinsDialog();
            },
            child: const Text('Buy Coins'),
          ),
        ],
      ),
    );
  }

  /// Safe prototype flow: Select gift -> show details and MOCK price -> confirm/cancel -> update DEMO state.
  Future<void> _showGiftConfirmDialog(
    BuildContext sheetContext,
    AndrilGift gift,
  ) async {
    final theme = widget.moduleConfig.theme;
    final partner = effectivePartner;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('confirm_gift_dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            SizedBox(
              height: 72,
              width: 72,
              child: Image.asset(gift.assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            Text(
              'Send ${gift.name}?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.primary,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CoinDot(diameter: 12),
                const SizedBox(width: 6),
                Text(
                  '${gift.coins} Coins (MOCK)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8B4D08),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Send this virtual gift sticker to ${partner.name}?\n(Deducts from prototype demo balance only; no real payment occurs)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('cancel_send_gift'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_send_gift'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
              _addGiftSticker(gift);
              _showSnackbar('Gift sent (DEMO) — Local prototype state only');
            },
            child: const Text('Send Gift'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearChatConfirmDialog() async {
    final theme = widget.moduleConfig.theme;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('clear_chat_dialog'),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Clear chat?',
          style: TextStyle(
            color: theme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Remove the messages and gift stickers visible in this demo? This cannot be undone in the current session.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            key: const Key('cancel_clear_chat'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_clear_chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() {
                _entries.clear();
                _composer.clear();
                _selectedTone = null;
              });
              _showSnackbar('Chat cleared for current session.');
            },
            child: const Text('Clear chat'),
          ),
        ],
      ),
    );
  }

  Future<void> _showReportDialog() async {
    final theme = widget.moduleConfig.theme;
    final partner = effectivePartner;
    String? selectedReason;
    String? validationError;
    final descriptionController = TextEditingController();

    const reasons = [
      'Spam or scam',
      'Inappropriate content',
      'Harassment or hate speech',
      'Impersonation',
      'Other',
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          key: const Key('report_user_dialog'),
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Column(
            children: [
              AndrilProfileAvatar(
                avatarAsset: partner.avatarAsset,
                moduleType: widget.moduleConfig.type,
                size: 56,
                borderWidth: 2.5,
                fallbackInitial:
                    partner.name.isNotEmpty ? partner.name[0] : '?',
              ),
              const SizedBox(height: 10),
              Text(
                'Report ${partner.name}',
                style: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Help us keep ANDRIL safe. (MOCK)',
                style: TextStyle(fontSize: 12, color: Color(0xFF67798A)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reason for report *',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: validationError != null
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: const Key('report_reason_dropdown'),
                      value: selectedReason,
                      hint: const Text('Select a reason',
                          style: TextStyle(fontSize: 14)),
                      isExpanded: true,
                      items: reasons.map((reason) {
                        return DropdownMenuItem<String>(
                          key: Key('report_reason_$reason'),
                          value: reason,
                          child: Text(reason,
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedReason = val;
                          validationError = null;
                        });
                      },
                    ),
                  ),
                ),
                if (validationError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    validationError!,
                    key: const Key('report_validation_error'),
                    style:
                        const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Description (optional)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('report_description_input'),
                  controller: descriptionController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Provide additional details...',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Note: Frontend demo only. Reports are not delivered to a real backend.',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('cancel_report_button'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('submit_report_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                if (selectedReason == null || selectedReason!.isEmpty) {
                  setDialogState(() {
                    validationError = 'Please select a reason for reporting.';
                  });
                  return;
                }
                Navigator.of(dialogContext).pop();
                _showSnackbar(
                    'Report submitted (MOCK) — Not delivered to real server');
              },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBlockConfirmDialog() async {
    final theme = widget.moduleConfig.theme;
    final partner = effectivePartner;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('block_user_dialog'),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Block ${partner.name}?',
          style: TextStyle(
            color: theme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          'You will no longer be able to send or receive messages or calls from ${partner.name} in this ${widget.moduleConfig.name} demo.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            key: const Key('cancel_block_button'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_block_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() {
                _isBlocked = true;
                _attachmentsOpen = false;
                _emojiMenuOpen = false;
              });
              _showSnackbar('Blocked ${partner.name}. (MOCK)');
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _unblockUser() {
    setState(() {
      _isBlocked = false;
    });
    _showSnackbar('Unblocked ${effectivePartner.name}. (MOCK)');
  }

  void _openGifts() {
    if (_isBlocked) {
      _showSnackbar('Cannot send gifts to a blocked user.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66172E2D),
      builder: (sheetContext) => GiftPickerSheet(
        balance: _balance,
        giftCatalog: widget.moduleConfig.giftCatalog,
        theme: widget.moduleConfig.theme,
        onBuyCoins: _showBuyCoinsDialog,
        onGiftTap: (gift) async {
          if (_giftActionPending) return;
          _giftActionPending = true;
          try {
            if (_balance < gift.coins) {
              await _showInsufficientCoinsDialog(gift);
            } else {
              await _showGiftConfirmDialog(sheetContext, gift);
            }
          } finally {
            _giftActionPending = false;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.moduleConfig.theme;
    final partner = effectivePartner;

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AndrilChatsListScreen(
              moduleConfig: widget.moduleConfig,
            ),
          ),
        );
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75),
          child: _buildHeader(theme, partner),
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AndrilChatBackground(
                      moduleType: widget.moduleConfig.type,
                    ),
                  ),
                  if (_entries.isEmpty)
                    Center(
                      child: Column(
                        key: const Key('empty_chat_placeholder'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: theme.primary,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: theme.ink,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Say hello to start the conversation! (MOCK)',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.ink.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      key: const Key('chat_message_list'),
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: _buildEntry(_entries[index], index, theme),
                      ),
                    ),
                  if (_attachmentsOpen) _buildAttachmentMenu(theme),
                  if (_emojiMenuOpen) _buildEmojiMenu(),
                ],
              ),
            ),
            if (_isBlocked) _buildBlockedBanner(theme, partner),
            _buildComposer(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedBanner(
      AndrilChatTheme theme, AndrilModuleProfile partner) {
    return Container(
      key: const Key('blocked_banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFEE2E2),
        border: Border(top: BorderSide(color: Color(0xFFFCA5A5), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.block, color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'You blocked ${partner.name}. Unblock to send messages or calls. (MOCK)',
                style: const TextStyle(
                  color: Color(0xFF991B1B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              key: const Key('unblock_button'),
              style: TextButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _unblockUser,
              child: const Text('Unblock',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AndrilChatTheme theme, AndrilModuleProfile partner) {
    // Header gradient matching HTML: linear-gradient(110deg,#f3fffb,#e6fbf5), etc.
    final headerGradient = widget.moduleConfig.type == AndrilModuleType.learning
        ? const LinearGradient(
            colors: [Color(0xFFF6F8FF), Color(0xFFE8EEFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : widget.moduleConfig.type == AndrilModuleType.hobbies
            ? const LinearGradient(
                colors: [Color(0xFFF3FFFB), Color(0xFFE6FBF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFFBFC), Color(0xFFF8E8F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );

    return Container(
      decoration: BoxDecoration(
        gradient: headerGradient,
        border: Border(bottom: BorderSide(color: theme.border, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: 75),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Back button matching HTML: <button class="iconbtn back" id="backBtn">
                SizedBox(
                  width: 36,
                  height: 40,
                  child: IconButton(
                    key: const Key('back_button'),
                    tooltip: 'Back to chats',
                    onPressed: () {
                      if (widget.onBackPressed != null) {
                        widget.onBackPressed!();
                        return;
                      }
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => AndrilChatsListScreen(
                              moduleConfig: widget.moduleConfig,
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.chevron_left, size: 28, color: theme.dark),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(width: 2),

                // Partner avatar matching HTML
                InkWell(
                  key: _avatarKey(partner.name),
                  onTap: () => _showInfoDialog(
                    partner.name,
                    '${partner.status} · Private ${widget.moduleConfig.name} identity (MOCK)',
                  ),
                  borderRadius: BorderRadius.circular(25),
                  child: AndrilProfileAvatar(
                    avatarAsset: partner.avatarAsset,
                    moduleType: widget.moduleConfig.type,
                    size: 44,
                    borderWidth: 2,
                    fallbackInitial:
                        partner.name.isNotEmpty ? partner.name[0] : '?',
                  ),
                ),
                const SizedBox(width: 8),

                // Name & Online status matching HTML
                Expanded(
                  child: InkWell(
                    key: _profileKey(partner.name),
                    onTap: () => _showInfoDialog(
                      partner.name,
                      '${partner.status} · Private ${widget.moduleConfig.name} identity (MOCK)',
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          partner.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.ink,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00C95B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                partner.status,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.ink.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons matching HTML
                SizedBox(
                  width: 32,
                  height: 40,
                  child: IconButton(
                    key: const Key('audio_call_button'),
                    icon: Icon(
                      Icons.call_outlined,
                      color: _isBlocked
                          ? theme.dark.withValues(alpha: 0.35)
                          : theme.dark,
                      size: 22,
                    ),
                    tooltip: 'Audio call',
                    onPressed: () {
                      if (_isBlocked) {
                        _showSnackbar(
                            'Cannot initiate call. You have blocked this user.');
                        return;
                      }
                      _showInfoDialog(
                        'Audio call',
                        'Audio calling demo — Proposed LiveKit RTC integration.',
                      );
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: 32,
                  height: 40,
                  child: IconButton(
                    key: const Key('video_call_button'),
                    icon: Icon(
                      Icons.videocam_outlined,
                      color: _isBlocked
                          ? theme.dark.withValues(alpha: 0.35)
                          : theme.dark,
                      size: 23,
                    ),
                    tooltip: 'Video call',
                    onPressed: () {
                      if (_isBlocked) {
                        _showSnackbar(
                            'Cannot initiate call. You have blocked this user.');
                        return;
                      }
                      _showInfoDialog(
                        'Video call',
                        'Video calling demo — Proposed LiveKit RTC integration.',
                      );
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: 36,
                  height: 40,
                  child: PopupMenuButton<String>(
                    key: const Key('chat_more_button'),
                    icon: Icon(Icons.more_vert, color: theme.dark, size: 22),
                    tooltip: 'Chat options',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      if (value == 'clear') {
                        _showClearChatConfirmDialog();
                      } else if (value == 'report') {
                        _showReportDialog();
                      } else if (value == 'block') {
                        if (_isBlocked) {
                          _unblockUser();
                        } else {
                          _showBlockConfirmDialog();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'clear',
                        child: Text('Clear chat'),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('Report Profile'),
                      ),
                      PopupMenuItem(
                        value: 'block',
                        child: Text(_isBlocked ? 'Unblock user' : 'Block user'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(ChatEntry entry, int index, AndrilChatTheme theme) {
    final alignment = entry.sent ? Alignment.centerRight : Alignment.centerLeft;

    // Gift sticker message matching HTML: <div class="sticker-msg">
    if (entry.type == ChatContentType.giftSticker) {
      return Align(
        alignment: alignment,
        child: Semantics(
          label: '${entry.text} virtual gift sticker sent',
          child: Column(
            key: Key('sent_gift_$index'),
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                height: 128,
                width: 128,
                child: Image.asset(
                  entry.imagePath!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                entry.time,
                style: const TextStyle(
                  color: Color(0xFF67798A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isImage = entry.type == ChatContentType.imagePreview;
    final isFile = entry.type == ChatContentType.filePreview;
    final screenWidth = MediaQuery.maybeOf(context)?.size.width ?? 360.0;
    final maxWidth = screenWidth > 80.0 ? screenWidth * 0.80 : 280.0;

    // Standard bubble matching HTML: .message.received vs .message.outgoing
    final outgoingGradient =
        widget.moduleConfig.type == AndrilModuleType.learning
            ? const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : widget.moduleConfig.type == AndrilModuleType.hobbies
                ? const LinearGradient(
                    colors: [Color(0xFF009C8F), Color(0xFF007A70)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF5B1CDA), Color(0xFF330099)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: entry.sent ? null : Colors.white,
            gradient: entry.sent ? outgoingGradient : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(entry.sent ? 18 : 6),
              bottomRight: Radius.circular(entry.sent ? 6 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF005344).withValues(alpha: 0.09),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Social-only MoodTone Tag matching HTML: <div class="tone-tag">
                  if (entry.mood != null &&
                      widget.moduleConfig.supportsMoodTone) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        key: Key('sent_mood_$index'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${entry.mood!.emoji} ${entry.mood!.label}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (isImage && entry.imagePath != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 220,
                        maxHeight: 180,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(entry.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              const Text('Image preview unavailable'),
                        ),
                      ),
                    )
                  else if (isFile)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 7),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            entry.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      entry.text,
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.34,
                        color: entry.sent ? Colors.white : theme.ink,
                      ),
                    ),

                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      entry.time,
                      style: TextStyle(
                        fontSize: 11.2,
                        color: entry.sent
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xFF67798A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Exact reproduction of the HTML composer:
  /// [Gift Button] -> [Input Shell: (Input + Emoji + Paperclip)] -> [Send Button]
  Widget _buildComposer(AndrilChatTheme theme) {
    final showMood = widget.moduleConfig.supportsMoodTone &&
        _composer.text.trim().isNotEmpty;

    // Gift button background and icon color per module
    final giftBg = widget.moduleConfig.type == AndrilModuleType.learning
        ? const Color(0xFFE2EAFF)
        : widget.moduleConfig.type == AndrilModuleType.hobbies
            ? const Color(0xFFDFF9F1)
            : const Color(0xFFF2E3FB);

    final giftIconColor = widget.moduleConfig.type == AndrilModuleType.learning
        ? const Color(0xFF2563EB)
        : widget.moduleConfig.type == AndrilModuleType.hobbies
            ? const Color(0xFF006653)
            : const Color(0xFF400DA3);

    // Send button gradient per module
    final sendGradient = widget.moduleConfig.type == AndrilModuleType.learning
        ? const LinearGradient(
            colors: [Color(0xFF428BFA), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : widget.moduleConfig.type == AndrilModuleType.hobbies
            ? const LinearGradient(
                colors: [Color(0xFF02AAA0), Color(0xFF006A63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF5B1CDA), Color(0xFF330099)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: theme.border, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Social-only MoodTone Panel (2 rows × 5 columns)
            if (showMood)
              MoodToneSelector(
                selected: _selectedTone,
                onSelected: (tone) {
                  setState(() => _selectedTone = tone);
                  _inputFocus.requestFocus();
                },
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
              child: Row(
                children: [
                  // 1. [Gift Button] on the LEFT matching HTML: <button id="giftBtn" class="giftbtn">
                  Material(
                    color: giftBg,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: const Key('open_gifts_button'),
                      onTap: _openGifts,
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.card_giftcard_rounded,
                          color: giftIconColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. [Input Shell] in the CENTER containing (Input + Emoji + Paperclip)
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(
                          color: widget.moduleConfig.type ==
                                  AndrilModuleType.learning
                              ? const Color(0xFFCCD8F3)
                              : widget.moduleConfig.type ==
                                      AndrilModuleType.hobbies
                                  ? const Color(0xFFCBD9D9)
                                  : const Color(0xFFEAD5EE),
                          width: 1.3,
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 14, right: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('message_input'),
                              controller: _composer,
                              focusNode: _inputFocus,
                              enabled: !_isBlocked,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              style: TextStyle(
                                fontSize: 15,
                                color: _isBlocked
                                    ? theme.ink.withValues(alpha: 0.4)
                                    : theme.ink,
                              ),
                              decoration: InputDecoration(
                                hintText: _isBlocked
                                    ? 'You have blocked this user'
                                    : 'Type a message...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF8E9BA0),
                                  fontSize: 14.5,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),

                          // [Emoji Button] inside shell matching HTML: <button class="emojibtn" id="emojiBtn">
                          IconButton(
                            key: const Key('emoji_btn'),
                            icon: const Icon(
                              Icons.sentiment_satisfied_alt_outlined,
                              color: Color(0xFF4B6360),
                              size: 23,
                            ),
                            tooltip: 'Choose emoji',
                            onPressed: () {
                              setState(() {
                                _emojiMenuOpen = !_emojiMenuOpen;
                                _attachmentsOpen = false;
                              });
                            },
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 38,
                            ),
                            padding: EdgeInsets.zero,
                          ),

                          // [Paperclip Button] inside shell matching HTML: <button id="clipBtn" class="clipbtn">
                          IconButton(
                            key: const Key('attach_plus_button'),
                            icon: const Icon(
                              Icons.attach_file_rounded,
                              color: Color(0xFF4B6360),
                              size: 23,
                            ),
                            tooltip: 'Attach image or file',
                            onPressed: () {
                              setState(() {
                                _attachmentsOpen = !_attachmentsOpen;
                                _emojiMenuOpen = false;
                              });
                            },
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 38,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. [Send Button] on the RIGHT matching HTML: <button class="sendbtn" id="sendBtn">
                  Material(
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: const Key('send_message_button'),
                      onTap: _sendMessage,
                      child: Ink(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: sendGradient,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentMenu(AndrilChatTheme theme) {
    return Positioned(
      bottom: 8,
      right: 48,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Container(
          width: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCEFEA)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('pick_image_button'),
                dense: true,
                leading: Icon(
                  Icons.image_outlined,
                  color: theme.primary,
                  size: 20,
                ),
                title: const Text(
                  'Image',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => _pickAttachment(image: true),
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('pick_file_button'),
                dense: true,
                leading: Icon(
                  Icons.description_outlined,
                  color: theme.primary,
                  size: 20,
                ),
                title: const Text(
                  'File',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => _pickAttachment(image: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiMenu() {
    return Positioned(
      bottom: 8,
      right: 30,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCEFEA)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final emoji in ['😊', '❤️', '😂', '🥰', '💗', '🌹'])
                InkWell(
                  onTap: () {
                    _composer.text += emoji;
                    setState(() => _emojiMenuOpen = false);
                    _inputFocus.requestFocus();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
