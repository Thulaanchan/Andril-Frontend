import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:andril_mobile/app/themes/common/chat_theme.dart';
import 'package:andril_mobile/features/common/chat/domain/module_config.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chat_screen.dart';
import 'package:andril_mobile/features/common/chat/presentation/widgets/andril_profile_avatar.dart';

/// Represents a conversation item inside the module-scoped Chats List.
class ConversationItem {
  final String id;
  final AndrilModuleProfile partner;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final bool isBlocked;

  const ConversationItem({
    required this.id,
    required this.partner,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isBlocked = false,
  });

  ConversationItem copyWith({
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
    bool? isBlocked,
  }) {
    return ConversationItem(
      id: id,
      partner: partner,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}

/// Presentation inputs for the isolated preview, never backend permission states.
enum ChatListPreviewStatus {
  loading,
  empty,
  content,
  unavailable,
  retryableError
}

/// Optional input around the existing M4 preview harness. Absence preserves its
/// seeded demo. No I/O, authenticated identity selection or server authorization.
/// Non-content states retain no supplied rows; content is a single-module snapshot.
class ChatListPreviewScope extends InheritedWidget {
  final AndrilModuleType moduleType;
  final ChatListPreviewStatus status;
  final List<ConversationItem> conversations;
  final VoidCallback? onRetry;

  ChatListPreviewScope({
    super.key,
    required this.moduleType,
    required this.status,
    List<ConversationItem> conversations = const [],
    this.onRetry,
    required super.child,
  }) : conversations = status == ChatListPreviewStatus.content
            ? List.unmodifiable(conversations)
            : const [] {
    if (this
        .conversations
        .any((item) => item.partner.moduleType != moduleType)) {
      throw ArgumentError('Preview conversations must match their module.');
    }
  }

  static ChatListPreviewScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatListPreviewScope>();

  @override
  bool updateShouldNotify(ChatListPreviewScope oldWidget) =>
      moduleType != oldWidget.moduleType ||
      status != oldWidget.status ||
      !listEquals(conversations, oldWidget.conversations) ||
      onRetry != oldWidget.onRetry;
}

/// Reusable, module-scoped All Chats screen.
///
/// Strictly enforces module isolation:
/// - Never shows Learning, Hobbies, and Social conversations together.
/// - Never includes a cross-module switcher.
/// - Displays module-specific header, gradient, theme, and profile assets.
class AndrilChatsListScreen extends StatefulWidget {
  final AndrilModuleConfig moduleConfig;

  const AndrilChatsListScreen({
    super.key,
    required this.moduleConfig,
  });

  @override
  State<AndrilChatsListScreen> createState() => _AndrilChatsListScreenState();
}

class _AndrilChatsListScreenState extends State<AndrilChatsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  ChatListPreviewScope? _preview;

  ChatListPreviewStatus get _status {
    final preview = _preview;
    if (preview == null) return ChatListPreviewStatus.content;
    // Never substitute seeds when a retained input belongs to another module.
    if (preview.moduleType != widget.moduleConfig.type) {
      return ChatListPreviewStatus.unavailable;
    }
    return preview.status;
  }

  List<ConversationItem> get _conversations =>
      _status == ChatListPreviewStatus.content
          ? _preview?.conversations ??
              _seedModuleConversations(widget.moduleConfig.type)
          : const [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ChatListPreviewScope.maybeOf(context);
    if (_preview?.moduleType != next?.moduleType ||
        _preview?.status != next?.status) {
      _resetSearch();
    }
    _preview = next;
  }

  @override
  void didUpdateWidget(covariant AndrilChatsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moduleConfig.type != widget.moduleConfig.type) _resetSearch();
  }

  void _resetSearch() {
    // Lifecycle callbacks already schedule a build; avoid listener-driven setState.
    _searchQuery = '';
    _searchController.removeListener(_onSearchChanged);
    _searchController.clear();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  /// Initial mock conversations scoped to the selected presentation module only.
  List<ConversationItem> _seedModuleConversations(AndrilModuleType type) {
    switch (type) {
      case AndrilModuleType.learning:
        return [
          const ConversationItem(
            id: 'lrn_maya',
            partner: AndrilModuleProfile(
              name: 'Maya',
              status: 'Online',
              avatarAsset: 'assets/profile/maya_avatar.webp',
              moduleType: AndrilModuleType.learning,
            ),
            lastMessage: "I'll share my study checklist with you too! 📝",
            lastMessageTime: '05:24 PM',
            unreadCount: 0,
          ),
        ];

      case AndrilModuleType.hobbies:
        return [
          const ConversationItem(
            id: 'hob_nila',
            partner: AndrilModuleProfile(
              name: 'Nila',
              status: 'Online',
              avatarAsset: 'assets/profile/nila_avatar.png',
              moduleType: AndrilModuleType.hobbies,
            ),
            lastMessage:
                'We can also bring my camera and do some photography there! 📸',
            lastMessageTime: '05:24 PM',
            unreadCount: 0,
          ),
        ];

      case AndrilModuleType.social:
        return [
          const ConversationItem(
            id: 'soc_aira',
            partner: AndrilModuleProfile(
              name: 'Aira',
              status: 'Online',
              avatarAsset: 'assets/profile/aira_avatar.png',
              moduleType: AndrilModuleType.social,
            ),
            lastMessage: 'What about you?',
            lastMessageTime: '05:24 PM',
            unreadCount: 0,
          ),
          const ConversationItem(
            id: 'soc_ava',
            partner: AndrilModuleProfile(
              name: 'Ava',
              status: 'Offline',
              avatarAsset: 'assets/profile/ava_avatar.webp',
              moduleType: AndrilModuleType.social,
            ),
            lastMessage: 'See you at the coffee shop tomorrow! ☕',
            lastMessageTime: 'Yesterday',
            unreadCount: 1,
          ),
        ];
    }
  }

  List<ConversationItem> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((item) {
      final nameMatches =
          item.partner.name.toLowerCase().contains(_searchQuery);
      final msgMatches = item.lastMessage.toLowerCase().contains(_searchQuery);
      return nameMatches || msgMatches;
    }).toList();
  }

  void _openChat(ConversationItem item) {
    // Reject callbacks captured before context/data replacement. Not authorization.
    if (_status != ChatListPreviewStatus.content ||
        item.partner.moduleType != widget.moduleConfig.type ||
        !_filteredConversations.contains(item)) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AndrilChatScreen(
          moduleConfig: widget.moduleConfig,
          partner: item.partner,
          conversationId: item.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.moduleConfig.theme;
    return Scaffold(
      backgroundColor: theme.background,
      body: Column(
        children: [
          // Let scaled header text determine its height; keep the list bounded.
          _buildHeader(theme),
          _buildSearchBar(theme),
          Expanded(
            child: _buildPresentation(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AndrilChatTheme theme) {
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
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              if (Navigator.of(context).canPop())
                IconButton(
                  key: const Key('chats_list_back_button'),
                  icon: Icon(Icons.arrow_back, color: theme.dark),
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.moduleConfig.name} Chats',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: theme.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'MOCK PREVIEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: theme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Private ${widget.moduleConfig.name} identity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.ink.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AndrilChatTheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: theme.border, width: 0.8)),
      ),
      child: Container(
        height: 42 +
            (MediaQuery.textScalerOf(context).scale(14) - 14)
                .clamp(0.0, double.infinity)
                .toDouble(),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: theme.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(Icons.search,
                size: 20, color: theme.ink.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const Key('conversation_search_input'),
                controller: _searchController,
                enabled: _status == ChatListPreviewStatus.content &&
                    _conversations.isNotEmpty,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                style: TextStyle(fontSize: 14, color: theme.ink),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.moduleConfig.name} chats...',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: theme.ink.withValues(alpha: 0.45),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                key: const Key('clear_search_button'),
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, size: 18),
                color: theme.ink.withValues(alpha: 0.5),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  _searchController.clear();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresentation(AndrilChatTheme theme) {
    switch (_status) {
      case ChatListPreviewStatus.loading:
        return Center(
            child: Semantics(
                liveRegion: true,
                child: CircularProgressIndicator(
                    key: const Key('chats_list_loading'),
                    semanticsLabel: 'Loading mock conversations',
                    color: theme.primary)));
      case ChatListPreviewStatus.empty:
      case ChatListPreviewStatus.content:
        return _buildListContent(theme);
      case ChatListPreviewStatus.unavailable:
        return _buildNotice(theme,
            key: const Key('chats_list_unavailable'),
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat preview unavailable',
            description: 'Conversations are unavailable in this preview.');
      case ChatListPreviewStatus.retryableError:
        final captured = _preview;
        return _buildNotice(theme,
            key: const Key('chats_list_error'),
            icon: Icons.refresh_rounded,
            title: 'Unable to load chat preview',
            description: 'Try the preview again when you are ready.',
            onRetry: captured?.onRetry == null
                ? null
                : () {
                    if (mounted &&
                        identical(captured, _preview) &&
                        _status == ChatListPreviewStatus.retryableError) {
                      captured!.onRetry!();
                    }
                  });
    }
  }

  Widget _buildNotice(
    AndrilChatTheme theme, {
    required Key key,
    required IconData icon,
    required String title,
    required String description,
    VoidCallback? onRetry,
  }) =>
      LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Semantics(
                          key: const Key('chat_list_notice_semantics'),
                          container: true,
                          liveRegion: true,
                          child: Column(
                              key: key,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon,
                                    size: 54,
                                    color:
                                        theme.primary.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                Text(title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: theme.ink)),
                                const SizedBox(height: 4),
                                Text(description,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            theme.ink.withValues(alpha: 0.6))),
                                if (onRetry != null) ...[
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                      key: const Key(
                                          'retry_chat_preview_button'),
                                      onPressed: onRetry,
                                      child: const Text('Retry preview')),
                                ],
                              ]),
                        ),
                      )),
                ),
              ));

  Widget _buildListContent(AndrilChatTheme theme) {
    final filtered = _filteredConversations;

    if (_conversations.isEmpty) {
      return _buildNotice(theme,
          key: const Key('empty_conversations_state'),
          icon: Icons.chat_bubble_outline_rounded,
          title: 'No ${widget.moduleConfig.name} chats yet',
          description:
              'Conversations with your ${widget.moduleConfig.name} connections will appear here.');
    }
    if (filtered.isEmpty) {
      return _buildNotice(theme,
          key: const Key('empty_search_state'),
          icon: Icons.search_off_rounded,
          title: 'No conversations found',
          description: 'No results matching "$_searchQuery".');
    }

    return ListView.separated(
      key: const Key('chats_list_view'),
      itemCount: filtered.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 76,
        endIndent: 16,
        color: theme.border.withValues(alpha: 0.7),
      ),
      itemBuilder: (context, index) {
        final item = filtered[index];
        final partner = item.partner;

        return InkWell(
          key: Key('conversation_${partner.name}'),
          onTap: () => _openChat(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar with online status
                Stack(
                  children: [
                    AndrilProfileAvatar(
                      avatarAsset: partner.avatarAsset,
                      moduleType: widget.moduleConfig.type,
                      size: 54,
                      borderWidth: 2,
                      fallbackInitial:
                          partner.name.isNotEmpty ? partner.name[0] : '?',
                    ),
                    if (partner.status.toLowerCase() == 'online')
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C95B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name and message preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              partner.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: theme.ink,
                              ),
                            ),
                          ),
                          Text(
                            item.lastMessageTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: item.unreadCount > 0
                                  ? theme.primary
                                  : const Color(0xFF8E9BA0),
                              fontWeight: item.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: item.unreadCount > 0
                                    ? theme.ink
                                    : theme.ink.withValues(alpha: 0.65),
                                fontWeight: item.unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (item.unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${item.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
