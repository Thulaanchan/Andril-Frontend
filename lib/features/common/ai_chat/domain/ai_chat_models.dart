import 'package:characters/characters.dart';

/// Role identifier for AI chat messages.
enum AiChatRole {
  /// Message authored by the authenticated human user.
  user,

  /// Message authored by the AI assistant.
  assistant,

  /// System-level notice, guidance, or operational directive.
  system,
}

/// Represents a single message in an AI conversation (CF-15 / AI-01).
///
/// Confidentiality:
/// Prompts and AI replies are sensitive user data. [toString] is redacted
/// to guarantee zero leakage into telemetry, logging, or exception reporting.
class AiChatMessage {
  /// Unique identifier for the message.
  final String id;

  /// Role of the entity authoring the message.
  final AiChatRole role;

  /// Content of the message.
  final String text;

  /// Creation timestamp in UTC.
  final DateTime timestamp;

  /// Whether this message represents a delivery/response error.
  final bool isError;

  const AiChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.isError = false,
  });

  /// Creates a copy with specified fields replaced.
  AiChatMessage copyWith({
    String? id,
    AiChatRole? role,
    String? text,
    DateTime? timestamp,
    bool? isError,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }

  /// Strictly redacted representation to prevent confidential text leakage.
  @override
  String toString() => 'AiChatMessage [private content omitted]';
}

/// Represents an isolated AI Chat conversation bounded to a specific module profile.
///
/// Bounded to the Learning module by contract. Cross-module conversation leakage
/// is strictly forbidden.
class AiConversation {
  /// Unique conversation reference identifier.
  final String conversationId;

  /// Authorized owner profile ID. Must match the current user ID.
  final String ownerLearningProfileId;

  /// Module identifier. Must be 'learning'.
  final String module;

  /// Ordered list of messages within this conversation.
  final List<AiChatMessage> messages;

  /// Whether the user has accepted the first-use AI privacy notice (AI-PRIV-02).
  final bool hasAcceptedPrivacyNotice;

  const AiConversation({
    required this.conversationId,
    required this.ownerLearningProfileId,
    this.module = 'learning',
    this.messages = const [],
    this.hasAcceptedPrivacyNotice = false,
  });

  /// Creates a copy with specified fields replaced.
  AiConversation copyWith({
    String? conversationId,
    String? ownerLearningProfileId,
    String? module,
    List<AiChatMessage>? messages,
    bool? hasAcceptedPrivacyNotice,
  }) {
    return AiConversation(
      conversationId: conversationId ?? this.conversationId,
      ownerLearningProfileId:
          ownerLearningProfileId ?? this.ownerLearningProfileId,
      module: module ?? this.module,
      messages: messages ?? this.messages,
      hasAcceptedPrivacyNotice:
          hasAcceptedPrivacyNotice ?? this.hasAcceptedPrivacyNotice,
    );
  }

  /// Adds a message to the conversation.
  AiConversation addMessage(AiChatMessage message) {
    return copyWith(messages: [...messages, message]);
  }

  /// Clears all messages from the conversation.
  AiConversation clearMessages() {
    return copyWith(messages: const []);
  }

  /// Strictly redacted representation to prevent confidential conversation leakage.
  @override
  String toString() => 'AiConversation [private content omitted]';
}

/// Public input validation rules matching the backend contract (AiChatContracts.cs).
///
/// Enforces:
/// 1. Maximum of 500 Unicode text elements (grapheme clusters).
/// 2. Exactly the same 500-element maximum for Free and Premium tiers (no invented tiers).
/// 3. Rejection of empty or whitespace-only inputs.
/// 4. Unicode grapheme cluster counting compatibility via [characters].
class AiInputValidator {
  /// Maximum permitted Unicode text elements per user prompt.
  static const int maxUserTextElements = 500;

  /// Integration status notice identifying disconnected state.
  static const String disconnectedNotice =
      'Remote AI repository integration pending. Live AI services are disconnected.';

  /// Counts the Unicode text elements (grapheme clusters) in [text].
  ///
  /// Matches .NET's `StringInfo.LengthInTextElements` semantics.
  static int countTextElements(String text) {
    return text.characters.length;
  }

  /// Validates whether [text] is acceptable for AI submission.
  ///
  /// Returns `true` if non-null, non-whitespace, and $\le$ [maxUserTextElements].
  static bool isValidInput(String? text) {
    if (text == null) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final count = countTextElements(text);
    return count >= 1 && count <= maxUserTextElements;
  }

  /// Returns a user-friendly validation error message, or `null` if valid.
  static String? getValidationError(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'AI input must contain at least 1 non-blank character.';
    }
    final count = countTextElements(text);
    if (count > maxUserTextElements) {
      return 'AI input must contain at most $maxUserTextElements characters (currently $count).';
    }
    return null;
  }
}
