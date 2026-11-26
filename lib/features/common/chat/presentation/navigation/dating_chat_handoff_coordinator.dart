import 'package:flutter/foundation.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/social_relationship.dart';

import '../../domain/module_config.dart';
import 'chat_entry_handoff.dart';
import 'chat_navigation_contract.dart';

/// The originating screen or action that requested Dating Chat navigation.
enum DatingHandoffOrigin {
  /// Bottom navigation bar destination tab at index 3 in Social/Dating Home.
  homeTab,

  /// "Send Message" action on the mutual match celebration screen (S12).
  mutualMatch,

  /// Chat action icon on an active connection card in the connections screen (S13).
  connections,

  /// Explicit direct conversation entry or deep link.
  direct,
}

/// The resolution kind of a Dating Chat handoff request.
enum DatingHandoffKind {
  /// Request resolves to the Dating All Chats list screen.
  chatList,

  /// Request resolves to an individual chat conversation detail screen.
  conversationDetail,

  /// Destination index was not the Chat tab (ignored without hijacking).
  ignoredTab,

  /// Request was denied due to missing match, block, age, or policy violation.
  denied,
}

/// Strictly typed navigation intent produced by [DatingChatHandoffCoordinator].
///
/// Encapsulates all validated routing parameters, source origins, and diagnostic
/// denial reasons without leaking unauthenticated credentials or cross-module IDs.
@immutable
class DatingChatHandoffIntent {
  /// The kind of navigation result.
  final DatingHandoffKind kind;

  /// The originating entry point that initiated the handoff.
  final DatingHandoffOrigin origin;

  /// The target module configuration (strictly [AndrilModuleConfig.social]).
  final AndrilModuleConfig moduleConfig;

  /// The resolved chat conversation identifier (e.g. `soc_aira`, `soc_ava`).
  final String? conversationId;

  /// The resolved partner profile for conversation detail navigation.
  final AndrilModuleProfile? partner;

  /// Canonical target route path for preview or router navigation.
  final String? targetRoute;

  /// Target screen to return to upon back navigation.
  final String? returnLocation;

  /// Diagnostic denial reason if [kind] is [DatingHandoffKind.denied].
  final String? denialReason;

  /// Typed status code from [ChatEntryHandoffAdapter] if denied.
  final ChatEntryStatus? denialStatus;

  /// The raw tab index requested when [kind] is [DatingHandoffKind.ignoredTab].
  final int? requestedTabIndex;

  const DatingChatHandoffIntent._({
    required this.kind,
    required this.origin,
    this.moduleConfig = AndrilModuleConfig.social,
    this.conversationId,
    this.partner,
    this.targetRoute,
    this.returnLocation,
    this.denialReason,
    this.denialStatus,
    this.requestedTabIndex,
  });

  /// Whether the handoff was authorized and produced a valid chat destination.
  bool get isSuccess =>
      kind == DatingHandoffKind.chatList ||
      kind == DatingHandoffKind.conversationDetail;

  /// Whether the handoff was denied or rejected fail-closed.
  bool get isDenied => kind == DatingHandoffKind.denied;

  /// Whether the request was for a non-chat tab that should be ignored by Chat.
  bool get isIgnoredTab => kind == DatingHandoffKind.ignoredTab;

  /// Creates a successful Chat List intent from home tab index 3.
  factory DatingChatHandoffIntent.chatList({
    required DatingHandoffOrigin origin,
    String? targetRoute,
    String? returnLocation,
  }) =>
      DatingChatHandoffIntent._(
        kind: DatingHandoffKind.chatList,
        origin: origin,
        moduleConfig: AndrilModuleConfig.social,
        targetRoute: targetRoute ??
            ChatNavigationParams.listPath(AndrilModuleType.social),
        returnLocation: returnLocation ?? 'social_home',
      );

  /// Creates a successful Conversation Detail intent.
  factory DatingChatHandoffIntent.conversation({
    required DatingHandoffOrigin origin,
    required String conversationId,
    required AndrilModuleProfile partner,
    String? targetRoute,
    String? returnLocation,
  }) =>
      DatingChatHandoffIntent._(
        kind: DatingHandoffKind.conversationDetail,
        origin: origin,
        moduleConfig: AndrilModuleConfig.social,
        conversationId: conversationId,
        partner: partner,
        targetRoute: targetRoute ??
            ChatNavigationParams.detailPath(
              AndrilModuleType.social,
              conversationId,
            ),
        returnLocation: returnLocation,
      );

  /// Creates an intent indicating a non-chat tab was selected.
  factory DatingChatHandoffIntent.ignoredTab(int tabIndex) =>
      DatingChatHandoffIntent._(
        kind: DatingHandoffKind.ignoredTab,
        origin: DatingHandoffOrigin.homeTab,
        requestedTabIndex: tabIndex,
      );

  /// Creates a denied handoff intent with fail-closed diagnostics.
  factory DatingChatHandoffIntent.denied({
    required DatingHandoffOrigin origin,
    required ChatEntryStatus denialStatus,
    required String denialReason,
    String? returnLocation,
  }) =>
      DatingChatHandoffIntent._(
        kind: DatingHandoffKind.denied,
        origin: origin,
        denialStatus: denialStatus,
        denialReason: denialReason,
        returnLocation: returnLocation,
        targetRoute:
            '/preview/chat/denied?reason=${Uri.encodeComponent(denialReason)}',
      );
}

/// Typed intent resolving back navigation from an active Dating Chat screen.
@immutable
class DatingBackNavigationIntent {
  /// Target identifier for the screen to pop or navigate back to.
  final String targetReturnScreen;

  /// The originating entrypoint that was active before entering chat.
  final DatingHandoffOrigin origin;

  /// Tab index to select if returning to the Social Home navigation shell.
  final int? homeTabIndex;

  const DatingBackNavigationIntent({
    required this.targetReturnScreen,
    required this.origin,
    this.homeTabIndex,
  });
}

/// M4-owned Dating Chat handoff coordinator bridging M5 Dating callbacks to M4 Chat.
///
/// Encapsulates all matching, eligibility, and profile-to-conversation boundary logic:
/// 1. Evaluates Dating Home bottom navigation tab selection (Index 3 = Chat).
/// 2. Evaluates Mutual Match `onSendMessage` handoff from authoritative [SocialRelationship].
/// 3. Evaluates Connections `onOpenChat` handoff requiring an injected relationship lookup.
/// 4. Manages independent conversation routing for Aira (`soc_aira`) and Ava (`soc_ava`).
/// 5. Strictly enforces 18+ adult age, Social opt-in, zero blocks, and zero cross-module leakage.
/// 6. Resolves origin-aware back navigation intents (returning to List, Match, or Connections).
/// 7. Exposes private chat state cleanup conforming to session boundary standards.
class DatingChatHandoffCoordinator {
  /// Approved destination index for Chat in the Social bottom navigation bar.
  static const int socialChatTabIndex = 3;

  /// Canonical preview conversation identifier for Aira.
  static const String airaConversationId = 'soc_aira';

  /// Canonical preview conversation identifier for Ava.
  static const String avaConversationId = 'soc_ava';

  final ChatEntryHandoffAdapter _handoffAdapter;
  final SocialRelationship? Function(String targetProfileId)?
      _relationshipLookup;
  final bool isAdult;
  final bool hasSocialOptIn;
  final bool isAuthorized;

  /// Creates a [DatingChatHandoffCoordinator].
  DatingChatHandoffCoordinator({
    ChatEntryHandoffAdapter? handoffAdapter,
    SocialRelationship? Function(String targetProfileId)? relationshipLookup,
    this.isAdult = true,
    this.hasSocialOptIn = true,
    this.isAuthorized = true,
  })  : _handoffAdapter = handoffAdapter ?? ChatEntryHandoffAdapter(),
        _relationshipLookup = relationshipLookup;

  /// Whether any private handoff or conversation state is currently cached.
  bool get hasActiveState => _handoffAdapter.hasActiveState;

  /// Number of times private chat state was cleared.
  int get clearCount => _handoffAdapter.clearCount;

  /// Purges all cached private chat state, active conversation pointers, and drafts.
  void clearPrivateState() {
    _handoffAdapter.clearPrivateChatState();
  }

  /// Records a temporary draft message tied to a conversation ID.
  void recordDraft(String conversationId, String text) {
    _handoffAdapter.recordDraft(conversationId, text);
  }

  /// Retrieves a recorded draft for a conversation.
  String? getDraft(String conversationId) =>
      _handoffAdapter.getDraft(conversationId);

  // ---------------------------------------------------------------------------
  // A. Dating Home Chat Tab Entry
  // ---------------------------------------------------------------------------

  /// Evaluates a navigation tab selection from [SocialHomeScreen.onDestinationSelected].
  ///
  /// Index `3` opens the Social Chat list. Any other index is ignored without
  /// hijacking or altering the host application's bottom navigation logic.
  DatingChatHandoffIntent handleHomeDestinationSelected(
    int destinationIndex, {
    String returnLocation = 'social_home',
  }) {
    if (destinationIndex != socialChatTabIndex) {
      return DatingChatHandoffIntent.ignoredTab(destinationIndex);
    }

    final request = ChatListEntryRequest.forModule(
      AndrilModuleType.social,
      returnLocation: returnLocation,
      isAuthorized: isAuthorized,
    );

    final result = _handoffAdapter.handleListEntry(request);

    if (result.isSuccess) {
      return DatingChatHandoffIntent.chatList(
        origin: DatingHandoffOrigin.homeTab,
        targetRoute: result.targetRoute,
        returnLocation: returnLocation,
      );
    }

    return DatingChatHandoffIntent.denied(
      origin: DatingHandoffOrigin.homeTab,
      denialStatus: result.status,
      denialReason: result.denialReason ?? 'Unauthorized chat list access.',
      returnLocation: returnLocation,
    );
  }

  // ---------------------------------------------------------------------------
  // B. Mutual Match "Send Message" Handoff (Screen S12)
  // ---------------------------------------------------------------------------

  /// Evaluates an `onSendMessage` callback emitted by [SocialMutualMatchScreen].
  ///
  /// Strictly requires server-confirmed mutual match evidence, 18+ adult age,
  /// explicit Social opt-in, zero blocks, and an active candidate conversation mapping.
  DatingChatHandoffIntent handleMutualMatchSendMessage(
    SocialRelationship relationship, {
    bool? isAdult,
    bool? hasSocialOptIn,
    bool? isAuthorized,
    String returnLocation = 'mutual_match',
  }) {
    return _evaluateRelationshipHandoff(
      relationship,
      origin: DatingHandoffOrigin.mutualMatch,
      isAdult: isAdult,
      hasSocialOptIn: hasSocialOptIn,
      isAuthorized: isAuthorized,
      returnLocation: returnLocation,
    );
  }

  // ---------------------------------------------------------------------------
  // C. Connections Screen `onOpenChat` Handoff (Screen S13)
  // ---------------------------------------------------------------------------

  /// Evaluates an `onOpenChat` callback emitted by [SocialConnectionsScreen].
  ///
  /// Because M5's callback emits only `targetProfileId`, this method requires an
  /// explicitly injected relationship lookup. Never infers a match from profile ID alone.
  DatingChatHandoffIntent handleConnectionsOpenChat(
    String targetProfileId, {
    SocialRelationship? Function(String targetProfileId)? lookup,
    bool? isAdult,
    bool? hasSocialOptIn,
    bool? isAuthorized,
    String returnLocation = 'connections',
  }) {
    final effectiveLookup = lookup ?? _relationshipLookup;

    if (effectiveLookup == null) {
      return DatingChatHandoffIntent.denied(
        origin: DatingHandoffOrigin.connections,
        denialStatus: ChatEntryStatus.unconfirmedMatchDenied,
        denialReason:
            'Missing relationship lookup. A candidate profile ID alone cannot authorize chat.',
        returnLocation: returnLocation,
      );
    }

    final relationship = effectiveLookup(targetProfileId);

    if (relationship == null) {
      return DatingChatHandoffIntent.denied(
        origin: DatingHandoffOrigin.connections,
        denialStatus: ChatEntryStatus.unconfirmedMatchDenied,
        denialReason:
            'No active relationship found for profile "$targetProfileId".',
        returnLocation: returnLocation,
      );
    }

    if (relationship.targetProfileId != targetProfileId) {
      return DatingChatHandoffIntent.denied(
        origin: DatingHandoffOrigin.connections,
        denialStatus: ChatEntryStatus.unconfirmedMatchDenied,
        denialReason:
            'Relationship profile mismatch: record target "${relationship.targetProfileId}" does not match requested profile "$targetProfileId".',
        returnLocation: returnLocation,
      );
    }

    return _evaluateRelationshipHandoff(
      relationship,
      origin: DatingHandoffOrigin.connections,
      isAdult: isAdult,
      hasSocialOptIn: hasSocialOptIn,
      isAuthorized: isAuthorized,
      returnLocation: returnLocation,
    );
  }

  // ---------------------------------------------------------------------------
  // D. Direct Conversation Entry & Cross-Module Isolation
  // ---------------------------------------------------------------------------

  /// Evaluates direct entry to an identified conversation.
  ///
  /// Strictly requires `rawModule` to be `social` or `dating`. Learning (`lrn_maya`)
  /// and Hobbies (`hob_nila`) conversation identifiers are denied fail-closed.
  DatingChatHandoffIntent handleConversationEntry({
    required String rawModule,
    required String conversationId,
    AndrilModuleProfile? partner,
    String? returnLocation,
    bool? isAuthorized,
  }) {
    final effectiveAuthorized = isAuthorized ?? this.isAuthorized;

    final parsedModule = ChatNavigationParams.parseModuleType(rawModule);
    if (parsedModule != AndrilModuleType.social) {
      return DatingChatHandoffIntent.denied(
        origin: DatingHandoffOrigin.direct,
        denialStatus: ChatEntryStatus.crossModuleDenied,
        denialReason:
            'Module "$rawModule" is not permitted in Dating Chat. Expected "social" or "dating".',
        returnLocation: returnLocation,
      );
    }

    final request = ConversationEntryRequest.forModule(
      moduleType: AndrilModuleType.social,
      conversationId: conversationId,
      partner: partner,
      returnLocation: returnLocation,
      isAuthorized: effectiveAuthorized,
    );

    final result = _handoffAdapter.handleConversationEntry(request);

    if (result.isSuccess) {
      return DatingChatHandoffIntent.conversation(
        origin: DatingHandoffOrigin.direct,
        conversationId: result.params!.conversationId,
        partner: result.partner!,
        targetRoute: result.targetRoute,
        returnLocation: returnLocation,
      );
    }

    return DatingChatHandoffIntent.denied(
      origin: DatingHandoffOrigin.direct,
      denialStatus: result.status,
      denialReason: result.denialReason ?? 'Invalid conversation entry request.',
      returnLocation: returnLocation,
    );
  }

  // ---------------------------------------------------------------------------
  // E. Origin-Aware Back Navigation
  // ---------------------------------------------------------------------------

  /// Resolves the typed back navigation intent for an active chat screen.
  ///
  /// Avoids hard-coding all return actions to Social Home: returns to Mutual Match,
  /// Connections, or Chat List depending on the handoff origin and return location.
  DatingBackNavigationIntent resolveBackNavigation(
    DatingChatHandoffIntent activeIntent,
  ) {
    if (activeIntent.returnLocation == 'mutual_match' ||
        activeIntent.origin == DatingHandoffOrigin.mutualMatch) {
      return const DatingBackNavigationIntent(
        targetReturnScreen: 'mutual_match',
        origin: DatingHandoffOrigin.mutualMatch,
      );
    }

    if (activeIntent.returnLocation == 'connections' ||
        activeIntent.origin == DatingHandoffOrigin.connections) {
      return const DatingBackNavigationIntent(
        targetReturnScreen: 'connections',
        origin: DatingHandoffOrigin.connections,
      );
    }

    if (activeIntent.returnLocation == 'chat_list' ||
        activeIntent.kind == DatingHandoffKind.conversationDetail &&
            activeIntent.origin == DatingHandoffOrigin.homeTab) {
      return const DatingBackNavigationIntent(
        targetReturnScreen: 'chat_list',
        origin: DatingHandoffOrigin.homeTab,
      );
    }

    return const DatingBackNavigationIntent(
      targetReturnScreen: 'social_home',
      origin: DatingHandoffOrigin.homeTab,
      homeTabIndex: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Private Helper: Relationship Handoff Evaluation
  // ---------------------------------------------------------------------------

  DatingChatHandoffIntent _evaluateRelationshipHandoff(
    SocialRelationship relationship, {
    required DatingHandoffOrigin origin,
    bool? isAdult,
    bool? hasSocialOptIn,
    bool? isAuthorized,
    String? returnLocation,
  }) {
    final request = SocialProfileHandoffRequest.fromRelationship(
      relationship,
      isAdult: isAdult ?? this.isAdult,
      hasSocialOptIn: hasSocialOptIn ?? this.hasSocialOptIn,
      isAuthorized: isAuthorized ?? this.isAuthorized,
      returnLocation: returnLocation,
    );

    final result = _handoffAdapter.handleProfileHandoff(request);

    if (result.isSuccess) {
      return DatingChatHandoffIntent.conversation(
        origin: origin,
        conversationId: result.params!.conversationId,
        partner: result.partner!,
        targetRoute: result.targetRoute,
        returnLocation: returnLocation,
      );
    }

    return DatingChatHandoffIntent.denied(
      origin: origin,
      denialStatus: result.status,
      denialReason:
          result.denialReason ?? 'Relationship chat handoff denied.',
      returnLocation: returnLocation,
    );
  }
}
