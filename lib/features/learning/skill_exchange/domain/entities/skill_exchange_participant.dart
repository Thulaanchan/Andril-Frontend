import 'package:flutter/foundation.dart';

/// Scoped domain participant in a Learning Skill Exchange.
///
/// References only, not authenticated identity, profile ownership or module eligibility.
/// M2 must freshly resolve and authorize the account and active Learning profile before use.
/// Reflects the backend contract: `Andril.Learning.SkillExchange.SkillExchangeParticipant`.
@immutable
class SkillExchangeParticipant {
  /// Internal account identifier (opaque, never rendered in UI).
  final String accountId;

  /// Active Learning profile identifier.
  final String learningProfileId;

  /// Creates a [SkillExchangeParticipant] with strict non-empty invariant checks.
  SkillExchangeParticipant({
    required String accountId,
    required String learningProfileId,
  })  : accountId = _validateId(accountId, 'accountId'),
        learningProfileId = _validateId(learningProfileId, 'learningProfileId');

  static String _validateId(String value, String fieldName) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        value,
        fieldName,
        'An internal identifier is required.',
      );
    }
    return trimmed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillExchangeParticipant &&
          runtimeType == other.runtimeType &&
          accountId == other.accountId &&
          learningProfileId == other.learningProfileId;

  @override
  int get hashCode => Object.hash(accountId, learningProfileId);

  @override
  String toString() =>
      'Learning exchange participant [private references omitted]';
}
