import 'package:flutter/foundation.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/social_relationship.dart';

import '../../domain/module_config.dart';
import 'chat_navigation_contract.dart';

/// Status codes representing the outcome of a module-scoped chat entry request.
enum ChatEntryStatus {
  /// Navigation to a module's chat conversation list is valid.
  validList,

  /// Navigation to a specific active chat conversation is valid.
  validConversation,

  /// The requested module name is unrecognized or unsupported.
  unsupportedModule,

  /// The request violates module isolation boundaries (e.g., cross-module profile access).
  crossModuleDenied,

  /// The conversation identifier is malformed, contains forbidden credentials, or is empty.
  invalidIdentifier,

  /// The conversation identifier does not exist within the target module scope.
  conversationNotFound,

  /// A module profile ID was supplied but has no active resolved chat conversation.
  unresolvedProfileMapping,

  /// The caller failed authorization or module eligibility gates (e.g. adult age or opt-in).
  authorizationDenied,

  /// Communication is strictly prohibited because the relationship is blocked.
  blockedRelationshipDenied,

  /// Direct communication was requested without authoritative server-confirmed mutual match evidence.
  unconfirmedMatchDenied,
}

/// Strictly typed result of evaluating an incoming chat handoff request.
@immutable
class ChatEntryHandoffResult {
  final ChatEntryStatus status;
  final String? targetRoute;
  final String? denialReason;
  final ChatNavigationParams? params;
  final AndrilModuleProfile? partner;

  const ChatEntryHandoffResult._({
    required this.status,
    this.targetRoute,
    this.denialReason,
    this.params,
    this.partner,
  });

  /// Whether the handoff was permitted and produced a valid navigation destination.
  bool get isSuccess =>
      status == ChatEntryStatus.validList ||
      status == ChatEntryStatus.validConversation;

  /// Whether the handoff was denied or rejected.
  bool get isDenied => !isSuccess;

  /// Creates a successful list navigation result.
  factory ChatEntryHandoffResult.validList({
    required AndrilModuleType moduleType,
    required String targetRoute,
    String? returnLocation,
  }) =>
      ChatEntryHandoffResult._(
        status: ChatEntryStatus.validList,
        targetRoute: targetRoute,
        params: ChatNavigationParams(
          moduleType: moduleType,
          conversationId: '',
          returnLocation: returnLocation,
        ),
      );

  /// Creates a successful conversation navigation result.
  factory ChatEntryHandoffResult.validConversation({
    required ChatNavigationParams params,
    required String targetRoute,
    AndrilModuleProfile? partner,
  }) =>
      ChatEntryHandoffResult._(
        status: ChatEntryStatus.validConversation,
        targetRoute: targetRoute,
        params: params,
        partner: partner ?? params.partner,
      );

  /// Creates a denied navigation result with a diagnostic reason.
  factory ChatEntryHandoffResult.denied({
    required ChatEntryStatus status,
    required String denialReason,
    String? deniedRoute,
  }) =>
      ChatEntryHandoffResult._(
        status: status,
        denialReason: denialReason,
        targetRoute: deniedRoute ??
            '/preview/chat/denied?reason=${Uri.encodeComponent(denialReason)}',
      );
}

/// Request to navigate to a module's chat conversation list screen.
@immutable
class ChatListEntryRequest {
  final String rawModule;
  final String? returnLocation;
  final bool isAuthorized;

  const ChatListEntryRequest({
    required this.rawModule,
    this.returnLocation,
    this.isAuthorized = true,
  });

  factory ChatListEntryRequest.forModule(
    AndrilModuleType moduleType, {
    String? returnLocation,
    bool isAuthorized = true,
  }) =>
      ChatListEntryRequest(
        rawModule: moduleType.name,
        returnLocation: returnLocation,
        isAuthorized: isAuthorized,
      );
}

/// Request to navigate directly to an identified chat conversation.
@immutable
class ConversationEntryRequest {
  final String rawModule;
  final String conversationId;
  final AndrilModuleProfile? partner;
  final String? returnLocation;
  final bool isAuthorized;

  const ConversationEntryRequest({
    required this.rawModule,
    required this.conversationId,
    this.partner,
    this.returnLocation,
    this.isAuthorized = true,
  });

  factory ConversationEntryRequest.forModule({
    required AndrilModuleType moduleType,
    required String conversationId,
    AndrilModuleProfile? partner,
    String? returnLocation,
    bool isAuthorized = true,
  }) =>
      ConversationEntryRequest(
        rawModule: moduleType.name,
        conversationId: conversationId,
        partner: partner,
        returnLocation: returnLocation,
        isAuthorized: isAuthorized,
      );
}

/// Request to enter chat from a Dating/Social candidate profile or relationship.
///
/// Follows M5 Social and Section 10 invariants:
/// - Unilateral interest cannot unlock communication.
/// - Requires server-confirmed mutual matching evidence.
/// - Requires adult eligibility (18+) and social profile opt-in.
/// - Differentiates a profile ID from a conversation ID.
@immutable
class SocialProfileHandoffRequest {
  final String targetProfileId;
  final SocialRelationshipState relationshipState;
  final bool hasActiveMatchEvidence;
  final bool isAdult;
  final bool hasSocialOptIn;
  final bool isAuthorized;
  final String? returnLocation;

  const SocialProfileHandoffRequest({
    required this.targetProfileId,
    this.relationshipState = SocialRelationshipState.none,
    this.hasActiveMatchEvidence = false,
    this.isAdult = true,
    this.hasSocialOptIn = true,
    this.isAuthorized = true,
    this.returnLocation,
  });

  /// Constructs a request directly from an authoritative M5 [SocialRelationship].
  factory SocialProfileHandoffRequest.fromRelationship(
    SocialRelationship relationship, {
    bool isAdult = true,
    bool hasSocialOptIn = true,
    bool isAuthorized = true,
    String? returnLocation,
  }) {
    return SocialProfileHandoffRequest(
      targetProfileId: relationship.targetProfileId,
      relationshipState: relationship.state,
      hasActiveMatchEvidence: relationship.hasActiveMatch,
      isAdult: isAdult,
      hasSocialOptIn: hasSocialOptIn,
      isAuthorized: isAuthorized,
      returnLocation: returnLocation,
    );
  }
}

/// Reusable adapter bridging external module entrypoints to M4 Chat navigation.
///
/// Acts as the typed barrier enforcing:
/// 1. Module boundary verification (Learning, Hobbies, Dating/Social).
/// 2. Profile ID vs. Conversation ID resolution.
/// 3. Dating eligibility and mutual-match validation.
/// 4. Identity isolation between module personas.
/// 5. Session-bound private state cleanup via [clearPrivateChatState].
class ChatEntryHandoffAdapter {
  final Map<String, List<String>> _allowedConversations;
  final Map<String, String> _profileToConversationMap;

  // Transient state tracking for session boundary verification
  ChatNavigationParams? _lastResolvedParams;
  AndrilModuleProfile? _lastResolvedPartner;
  final Map<String, String> _transientDrafts = {};
  int _clearCount = 0;

  ChatEntryHandoffAdapter({
    Map<String, List<String>>? allowedConversations,
    Map<String, String>? profileToConversationMap,
  })  : _allowedConversations = allowedConversations ??
            MockConversationCatalog.previewAllowedConversations,
        _profileToConversationMap = profileToConversationMap ??
            const {
              // Social mock mappings: Aira and Ava have independent identities
              'soc_aira': 'soc_aira',
              'aira': 'soc_aira',
              'candidate_aira': 'soc_aira',
              'profile_aira': 'soc_aira',
              'soc_ava': 'soc_ava',
              'ava': 'soc_ava',
              'candidate_ava': 'soc_ava',
              'profile_ava': 'soc_ava',
              // Learning mock mappings
              'lrn_maya': 'lrn_maya',
              'maya': 'lrn_maya',
              'candidate_maya': 'lrn_maya',
              'profile_maya': 'lrn_maya',
              // Hobbies mock mappings
              'hob_nila': 'hob_nila',
              'nila': 'hob_nila',
              'candidate_nila': 'hob_nila',
              'profile_nila': 'hob_nila',
            };

  /// Whether any private handoff or conversation state is currently cached.
  bool get hasActiveState =>
      _lastResolvedParams != null ||
      _lastResolvedPartner != null ||
      _transientDrafts.isNotEmpty;

  /// Number of times private state was cleared.
  int get clearCount => _clearCount;

  /// The most recently resolved navigation parameters (cleared on logout).
  ChatNavigationParams? get lastResolvedParams => _lastResolvedParams;

  /// The most recently resolved partner profile (cleared on logout).
  AndrilModuleProfile? get lastResolvedPartner => _lastResolvedPartner;

  /// Records a temporary draft message tied to a conversation ID.
  void recordDraft(String conversationId, String text) {
    _transientDrafts[conversationId] = text;
  }

  /// Retrieves a recorded draft for a conversation.
  String? getDraft(String conversationId) => _transientDrafts[conversationId];

  /// Purges all cached private chat state, active conversation pointers, and drafts.
  ///
  /// Conforms to `SessionController.registerPrivateStateClearer` requirements:
  /// must be invoked on logout or account switch to prevent data leakage.
  void clearPrivateChatState() {
    _lastResolvedParams = null;
    _lastResolvedPartner = null;
    _transientDrafts.clear();
    _clearCount++;
  }

  /// Handles entry to a module's conversation list screen.
  ChatEntryHandoffResult handleListEntry(ChatListEntryRequest request) {
    if (!request.isAuthorized) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.authorizationDenied,
        denialReason: 'User is not authorized for module chat list.',
      );
    }

    final moduleType = ChatNavigationParams.parseModuleType(request.rawModule);
    if (moduleType == null) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.unsupportedModule,
        denialReason:
            'Unsupported module: "${request.rawModule}". Approved modules are learning, hobbies, dating/social.',
      );
    }

    final path = ChatNavigationParams.listPath(moduleType);
    return ChatEntryHandoffResult.validList(
      moduleType: moduleType,
      targetRoute: path,
      returnLocation: request.returnLocation,
    );
  }

  /// Handles direct entry to an identified conversation.
  ChatEntryHandoffResult handleConversationEntry(
      ConversationEntryRequest request) {
    if (!request.isAuthorized) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.authorizationDenied,
        denialReason: 'User is not authorized for chat conversation.',
      );
    }

    final moduleType = ChatNavigationParams.parseModuleType(request.rawModule);
    if (moduleType == null) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.unsupportedModule,
        denialReason:
            'Unsupported module: "${request.rawModule}". Approved modules are learning, hobbies, dating/social.',
      );
    }

    // Enforce identifier format and credential rejection rules
    final validation = ChatNavigationParams.validate(
      rawModule: request.rawModule,
      conversationId: request.conversationId,
      partner: request.partner,
      returnLocation: request.returnLocation,
    );

    if (!validation.isValid) {
      if (validation.status == ChatNavigationStatus.missingConversationId) {
        return ChatEntryHandoffResult.denied(
          status: ChatEntryStatus.invalidIdentifier,
          denialReason: validation.denialReason ?? 'Invalid conversation identifier.',
        );
      }
      if (validation.status ==
          ChatNavigationStatus.crossModulePartnerMismatch) {
        return ChatEntryHandoffResult.denied(
          status: ChatEntryStatus.crossModuleDenied,
          denialReason: validation.denialReason ??
              'Partner does not belong to route module.',
        );
      }
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.invalidIdentifier,
        denialReason: validation.denialReason ?? 'Validation failed.',
      );
    }

    // Verify conversation belongs to the requested module scope
    final allowedInTarget =
        _allowedConversations[moduleType.name] ?? const [];
    if (!allowedInTarget.contains(request.conversationId)) {
      // Check if this conversation exists in another module (cross-module denial)
      for (final entry in _allowedConversations.entries) {
        if (entry.key != moduleType.name &&
            entry.value.contains(request.conversationId)) {
          return ChatEntryHandoffResult.denied(
            status: ChatEntryStatus.crossModuleDenied,
            denialReason:
                'Conversation "${request.conversationId}" belongs to module "${entry.key}", not "${moduleType.name}".',
          );
        }
      }
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.conversationNotFound,
        denialReason:
            'Conversation "${request.conversationId}" is not available in module "${moduleType.name}".',
      );
    }

    final partner = request.partner ??
        MockConversationCatalog.defaultPartnerFor(
          moduleType,
          request.conversationId,
        );

    if (partner == null) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.conversationNotFound,
        denialReason:
            'No partner profile found for conversation "${request.conversationId}".',
      );
    }

    _lastResolvedParams = validation.params;
    _lastResolvedPartner = partner;

    final targetRoute = ChatNavigationParams.detailPath(
      moduleType,
      request.conversationId,
    );

    return ChatEntryHandoffResult.validConversation(
      params: validation.params!,
      targetRoute: targetRoute,
      partner: partner,
    );
  }

  /// Handles handoff from a Dating/Social candidate profile (e.g. Mutual Match or Connections).
  ChatEntryHandoffResult handleProfileHandoff(
      SocialProfileHandoffRequest request) {
    // 1. Authorization check
    if (!request.isAuthorized) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.authorizationDenied,
        denialReason: 'User is not authorized for Dating/Social chat access.',
      );
    }

    // 2. Adult eligibility check (age 18+)
    if (!request.isAdult) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.authorizationDenied,
        denialReason: 'Dating/Social module requires adult eligibility (age 18+).',
      );
    }

    // 3. Social profile opt-in check
    if (!request.hasSocialOptIn) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.authorizationDenied,
        denialReason:
            'Dating/Social module requires an explicit user profile opt-in.',
      );
    }

    // 4. Blocked relationship check (strictly prohibited)
    if (request.relationshipState.isBlocked) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.blockedRelationshipDenied,
        denialReason:
            'Communication with blocked profile "${request.targetProfileId}" is strictly prohibited.',
      );
    }

    // 5. Confirmed mutual match check
    if (!request.relationshipState.isMatched) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.unconfirmedMatchDenied,
        denialReason:
            'Direct communication requires an authoritative, server-confirmed mutual match. Current state: ${request.relationshipState.name}.',
      );
    }

    if (!request.hasActiveMatchEvidence) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.unconfirmedMatchDenied,
        denialReason:
            'Active mutual-match evidence is missing or unverified for profile "${request.targetProfileId}".',
      );
    }

    // 6. Cross-module persona leak check
    final lowerTarget = request.targetProfileId.toLowerCase();
    if (lowerTarget.contains('maya') || lowerTarget.contains('learning')) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.crossModuleDenied,
        denialReason:
            'Profile "${request.targetProfileId}" belongs to Learning module and cannot be accessed in Dating/Social.',
      );
    }
    if (lowerTarget.contains('nila') || lowerTarget.contains('hobbies')) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.crossModuleDenied,
        denialReason:
            'Profile "${request.targetProfileId}" belongs to Hobbies module and cannot be accessed in Dating/Social.',
      );
    }

    // 7. Profile-to-conversation resolution
    final resolvedConversationId =
        _profileToConversationMap[request.targetProfileId];

    if (resolvedConversationId == null) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.unresolvedProfileMapping,
        denialReason:
            'Target profile "${request.targetProfileId}" does not have an active chat conversation. Server conversation resolution required.',
      );
    }

    // Verify conversation is allowed in Social
    final allowedSocial =
        _allowedConversations[AndrilModuleType.social.name] ?? const [];
    if (!allowedSocial.contains(resolvedConversationId)) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.conversationNotFound,
        denialReason:
            'Resolved conversation "$resolvedConversationId" is not available in Social module.',
      );
    }

    final partner = MockConversationCatalog.defaultPartnerFor(
      AndrilModuleType.social,
      resolvedConversationId,
    );

    if (partner == null) {
      return ChatEntryHandoffResult.denied(
        status: ChatEntryStatus.unresolvedProfileMapping,
        denialReason:
            'No partner profile found for resolved conversation "$resolvedConversationId".',
      );
    }

    final params = ChatNavigationParams(
      moduleType: AndrilModuleType.social,
      conversationId: resolvedConversationId,
      partner: partner,
      returnLocation: request.returnLocation,
    );

    _lastResolvedParams = params;
    _lastResolvedPartner = partner;

    final targetRoute = ChatNavigationParams.detailPath(
      AndrilModuleType.social,
      resolvedConversationId,
    );

    return ChatEntryHandoffResult.validConversation(
      params: params,
      targetRoute: targetRoute,
      partner: partner,
    );
  }
}
