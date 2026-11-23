import 'package:flutter/foundation.dart';

/// Scoped domain entity representing a learner's module-specific profile projection.
///
/// Under ANDRIL architecture (§04.1-04.3, §05 CF-01, CF-02, §06), M2 owns global
/// account identity, module identity resolution, and activation authority. This entity
/// models only the Learning-specific profile projection. It is strictly scoped to the
/// 'learning' module and enforces immutability and defensive collection encapsulation.
@immutable
class LearningProfile {
  /// The canonical module identifier for the Learning surface.
  static const String moduleScope = 'learning';

  /// Externally assigned module-profile identity from M2 authority.
  final String profileId;

  /// Externally assigned owning account identifier from M2 authority.
  final String accountId;

  /// Module identifier. Invariant: must strictly equal [moduleScope] ('learning').
  final String module;

  /// Module-specific display name (BRD §04.2 NAME-01-07).
  final String displayName;

  /// Optional biographical summary or learning mission.
  final String? bio;

  /// Optional avatar image URL or asset reference.
  final String? avatarUrl;

  /// Defensive unmodifiable collection of skills the learner wishes to acquire.
  final List<String> skillsToLearn;

  /// Defensive unmodifiable collection of skills the learner can teach or share.
  final List<String> skillsToShare;

  /// Defensive unmodifiable collection of learning goals or intentions.
  final List<String> learningGoals;

  /// External activation status reported by M2 authority (default: false).
  ///
  /// Activation is never locally fabricated or assumed.
  final bool isActivated;

  /// Creates an immutable [LearningProfile] instance with structural invariant validation.
  ///
  /// Throws [ArgumentError] if [profileId] or [accountId] are empty or whitespace,
  /// or if [module] is not equal to [moduleScope] ('learning').
  LearningProfile({
    required String profileId,
    required String accountId,
    String module = moduleScope,
    required String displayName,
    this.bio,
    this.avatarUrl,
    List<String> skillsToLearn = const [],
    List<String> skillsToShare = const [],
    List<String> learningGoals = const [],
    this.isActivated = false,
  })  : profileId = _validateId(profileId, 'profileId'),
        accountId = _validateId(accountId, 'accountId'),
        module = _validateModule(module),
        displayName = displayName,
        skillsToLearn = List.unmodifiable(skillsToLearn),
        skillsToShare = List.unmodifiable(skillsToShare),
        learningGoals = List.unmodifiable(learningGoals);

  static String _validateId(String value, String paramName) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        paramName,
        '$paramName must not be empty or whitespace-only',
      );
    }
    return value.trim();
  }

  static String _validateModule(String value) {
    if (value != moduleScope) {
      throw ArgumentError.value(
        value,
        'module',
        'LearningProfile must have module "$moduleScope", got "$value"',
      );
    }
    return value;
  }

  /// Creates a copy of this [LearningProfile] with updated presentation fields.
  ///
  /// Note: Identity fields ([profileId], [accountId], [module]) and authority flags
  /// ([isActivated]) are strictly preserved unless explicitly provided.
  LearningProfile copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    List<String>? skillsToLearn,
    List<String>? skillsToShare,
    List<String>? learningGoals,
    bool? isActivated,
  }) {
    return LearningProfile(
      profileId: profileId,
      accountId: accountId,
      module: module,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      skillsToLearn: skillsToLearn ?? this.skillsToLearn,
      skillsToShare: skillsToShare ?? this.skillsToShare,
      learningGoals: learningGoals ?? this.learningGoals,
      isActivated: isActivated ?? this.isActivated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningProfile &&
        other.profileId == profileId &&
        other.accountId == accountId &&
        other.module == module &&
        other.displayName == displayName &&
        other.bio == bio &&
        other.avatarUrl == avatarUrl &&
        other.isActivated == isActivated &&
        listEquals(other.skillsToLearn, skillsToLearn) &&
        listEquals(other.skillsToShare, skillsToShare) &&
        listEquals(other.learningGoals, learningGoals);
  }

  @override
  int get hashCode {
    return Object.hash(
      profileId,
      accountId,
      module,
      displayName,
      bio,
      avatarUrl,
      isActivated,
      Object.hashAll(skillsToLearn),
      Object.hashAll(skillsToShare),
      Object.hashAll(learningGoals),
    );
  }

  @override
  String toString() {
    return 'LearningProfile('
        'profileId: $profileId, '
        'displayName: $displayName, '
        'skillsToLearn: ${skillsToLearn.length}, '
        'skillsToShare: ${skillsToShare.length}, '
        'learningGoals: ${learningGoals.length}, '
        'isActivated: $isActivated)';
  }
}
