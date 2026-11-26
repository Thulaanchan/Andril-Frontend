import 'package:flutter/material.dart';
import 'package:andril_mobile/app/themes/social/social_theme.dart';
import 'package:andril_mobile/features/common/chat/domain/module_config.dart';
import 'package:andril_mobile/features/common/chat/presentation/navigation/chat_navigation_contract.dart';
import 'package:andril_mobile/features/common/chat/presentation/navigation/dating_chat_handoff_coordinator.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chat_screen.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chats_list_screen.dart';
import 'package:andril_mobile/features/common/chat/preview/main_app_chat_route_preview.dart';

/// Lightweight preview host demonstrating M4 Dating Chat integration.
///
/// Bridges [DatingChatHandoffCoordinator] navigation intents to actual M4 Chat
/// presentation screens ([AndrilChatsListScreen] and [AndrilChatScreen])
/// without modifying production routers or M5 source files.
class DatingChatPreviewHost extends StatefulWidget {
  /// The handoff coordinator driving navigation transitions.
  final DatingChatHandoffCoordinator coordinator;

  /// Initial handoff intent to display upon mounting.
  final DatingChatHandoffIntent? initialIntent;

  /// Callback invoked when a navigation transition occurs.
  final ValueChanged<DatingChatHandoffIntent>? onIntentChanged;

  /// Callback invoked when back navigation resolves to an external surface.
  final ValueChanged<DatingBackNavigationIntent>? onBackResolved;

  const DatingChatPreviewHost({
    super.key,
    required this.coordinator,
    this.initialIntent,
    this.onIntentChanged,
    this.onBackResolved,
  });

  @override
  State<DatingChatPreviewHost> createState() => _DatingChatPreviewHostState();
}

class _DatingChatPreviewHostState extends State<DatingChatPreviewHost> {
  late DatingChatHandoffIntent _currentIntent;

  @override
  void initState() {
    super.initState();
    _currentIntent = widget.initialIntent ??
        widget.coordinator.handleHomeDestinationSelected(
          DatingChatHandoffCoordinator.socialChatTabIndex,
        );
  }

  @override
  void didUpdateWidget(covariant DatingChatPreviewHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIntent != null &&
        widget.initialIntent != oldWidget.initialIntent) {
      _currentIntent = widget.initialIntent!;
    }
  }

  void _updateIntent(DatingChatHandoffIntent newIntent) {
    setState(() {
      _currentIntent = newIntent;
    });
    widget.onIntentChanged?.call(newIntent);
  }

  void _handleBack() {
    final backIntent = widget.coordinator.resolveBackNavigation(_currentIntent);
    widget.onBackResolved?.call(backIntent);

    if (backIntent.targetReturnScreen == 'chat_list') {
      _updateIntent(
        widget.coordinator.handleHomeDestinationSelected(
          DatingChatHandoffCoordinator.socialChatTabIndex,
          returnLocation: 'social_home',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF330099),
        ),
        useMaterial3: true,
      ),
      child: Scaffold(
        backgroundColor: AndrilSocialColors.cream,
        body: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final intent = _currentIntent;

    if (intent.isDenied) {
      return ChatRouteDeniedScreen(
        key: const Key('dating_preview_denied_screen'),
        reason: intent.denialReason ?? 'Dating Chat access restricted.',
        onReturn: _handleBack,
      );
    }

    if (intent.kind == DatingHandoffKind.conversationDetail) {
      final conversationId = intent.conversationId ?? 'soc_aira';
      final partner = intent.partner ??
          MockConversationCatalog.defaultPartnerFor(
            AndrilModuleType.social,
            conversationId,
          )!;

      return AndrilChatScreen(
        key: ValueKey('dating_chat_detail_$conversationId'),
        moduleConfig: AndrilModuleConfig.social,
        partner: partner,
        conversationId: conversationId,
        onBackPressed: _handleBack,
      );
    }

    // Default to Chat List
    return AndrilChatsListScreen(
      key: const ValueKey('dating_chats_list_screen'),
      moduleConfig: AndrilModuleConfig.social,
      onOpenConversation: (item) {
        final detailIntent = widget.coordinator.handleConversationEntry(
          rawModule: 'social',
          conversationId: item.id,
          partner: item.partner,
          returnLocation: 'chat_list',
        );
        _updateIntent(detailIntent);
      },
    );
  }
}
