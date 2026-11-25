import 'package:flutter/foundation.dart';
import '../../domain/module_config.dart';

/// Validation status for typed module chat navigation.
enum ChatNavigationStatus {
  valid,
  missingConversationId,
  unsupportedModule,
  crossModulePartnerMismatch,
  missingConversationScope,
}

/// Result of evaluating a proposed chat navigation request.
@immutable
class ChatNavigationValidation {
  final ChatNavigationStatus status;
  final String? denialReason;
  final ChatNavigationParams? params;

  const ChatNavigationValidation._({
    required this.status,
    this.denialReason,
    this.params,
  });

  bool get isValid => status == ChatNavigationStatus.valid;

  factory ChatNavigationValidation.valid(ChatNavigationParams params) =>
      ChatNavigationValidation._(
        status: ChatNavigationStatus.valid,
        params: params,
      );

  factory ChatNavigationValidation.denied(
    ChatNavigationStatus status,
    String reason,
  ) =>
      ChatNavigationValidation._(
        status: status,
        denialReason: reason,
      );
}

/// Strictly typed navigation parameters for opening an M4 Chat destination.
///
/// Disallows using emails, tokens, or cross-module profiles as route parameters.
@immutable
class ChatNavigationParams {
  final AndrilModuleType moduleType;
  final String conversationId;
  final AndrilModuleProfile? partner;
  final String? returnLocation;

  const ChatNavigationParams({
    required this.moduleType,
    required this.conversationId,
    this.partner,
    this.returnLocation,
  });

  /// The associated module configuration.
  AndrilModuleConfig get moduleConfig {
    switch (moduleType) {
      case AndrilModuleType.learning:
        return AndrilModuleConfig.learning;
      case AndrilModuleType.hobbies:
        return AndrilModuleConfig.hobbies;
      case AndrilModuleType.social:
        return AndrilModuleConfig.social;
    }
  }

  /// Validates the navigation request against module boundaries and privacy rules.
  static ChatNavigationValidation validate({
    required String? rawModule,
    required String? conversationId,
    AndrilModuleProfile? partner,
    String? returnLocation,
    Map<String, List<String>>? allowedConversationsByModule,
  }) {
    if (rawModule == null || rawModule.trim().isEmpty) {
      return ChatNavigationValidation.denied(
        ChatNavigationStatus.unsupportedModule,
        'Module identifier is required.',
      );
    }

    final moduleType = parseModuleType(rawModule);
    if (moduleType == null) {
      return ChatNavigationValidation.denied(
        ChatNavigationStatus.unsupportedModule,
        'Unsupported module: "$rawModule". Approved modules are learning, hobbies, dating/social.',
      );
    }

    if (conversationId == null || conversationId.trim().isEmpty) {
      return ChatNavigationValidation.denied(
        ChatNavigationStatus.missingConversationId,
        'Conversation identifier is required.',
      );
    }

    // Disallow email, tokens, or bearer headers in route identifiers.
    final lowerId = conversationId.toLowerCase();
    if (lowerId.contains('@') ||
        lowerId.contains('bearer ') ||
        lowerId.contains('token') ||
        conversationId.length > 128) {
      return ChatNavigationValidation.denied(
        ChatNavigationStatus.missingConversationId,
        'Invalid conversation identifier format.',
      );
    }

    // Enforce module partner boundary.
    if (partner != null && partner.moduleType != moduleType) {
      return ChatNavigationValidation.denied(
        ChatNavigationStatus.crossModulePartnerMismatch,
        'Partner "${partner.name}" (${partner.moduleType.name}) does not belong to route module "${moduleType.name}".',
      );
    }

    // If a scoped conversation catalog is provided, enforce conversation membership.
    if (allowedConversationsByModule != null) {
      final allowed = allowedConversationsByModule[moduleType.name] ?? const [];
      if (!allowed.contains(conversationId)) {
        return ChatNavigationValidation.denied(
          ChatNavigationStatus.missingConversationScope,
          'Conversation "$conversationId" is not available in module "${moduleType.name}".',
        );
      }
    }

    return ChatNavigationValidation.valid(
      ChatNavigationParams(
        moduleType: moduleType,
        conversationId: conversationId.trim(),
        partner: partner,
        returnLocation: returnLocation,
      ),
    );
  }

  /// Parses a string into an [AndrilModuleType].
  ///
  /// Maps 'dating' and 'social' to [AndrilModuleType.social] for product alignment.
  static AndrilModuleType? parseModuleType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'learning':
        return AndrilModuleType.learning;
      case 'hobbies':
        return AndrilModuleType.hobbies;
      case 'social':
      case 'dating':
        return AndrilModuleType.social;
      default:
        return null;
    }
  }

  /// Standard URI path for a module's chat list.
  static String listPath(AndrilModuleType module) =>
      '/preview/chat/${module.name}';

  /// Standard URI path for an individual chat conversation.
  static String detailPath(AndrilModuleType module, String conversationId) =>
      '/preview/chat/${module.name}/$conversationId';
}

/// Known mock conversations per module for the preview test harness.
class MockConversationCatalog {
  static const Map<String, List<String>> previewAllowedConversations = {
    'learning': ['preview_learning', 'maya', 'maya_1', 'lrn_maya'],
    'hobbies': ['preview_hobbies', 'nila', 'nila_1', 'hob_nila'],
    'social': ['preview_social', 'aira', 'aira_1', 'soc_aira', 'ava', 'ava_1', 'soc_ava'],
  };

  static AndrilModuleProfile? defaultPartnerFor(
    AndrilModuleType module,
    String conversationId,
  ) {
    final lower = conversationId.toLowerCase();
    switch (module) {
      case AndrilModuleType.learning:
        if (lower.contains('maya') || lower.contains('learning')) {
          return AndrilModuleConfig.learning.defaultPartner;
        }
        return null;
      case AndrilModuleType.hobbies:
        if (lower.contains('nila') || lower.contains('hobbies')) {
          return AndrilModuleConfig.hobbies.defaultPartner;
        }
        return null;
      case AndrilModuleType.social:
        if (lower.contains('ava')) {
          return const AndrilModuleProfile(
            name: 'Ava',
            status: 'Online',
            avatarAsset: 'assets/profile/ava_avatar.webp',
            moduleType: AndrilModuleType.social,
          );
        }
        if (lower.contains('aira') || lower.contains('social')) {
          return AndrilModuleConfig.social.defaultPartner;
        }
        return null;
    }
  }
}
