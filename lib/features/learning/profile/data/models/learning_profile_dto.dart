import 'package:flutter/foundation.dart';

import '../../domain/entities/learning_profile.dart';

/// Data Transfer Object for serialization and deserialization of Learning profile projections.
///
/// Notice: This DTO represents an isolated frontend mapping for local persistence
/// and testing. It does NOT claim to represent an approved M2 backend OpenAPI contract.
@immutable
class LearningProfileDto {
  final String profileId;
  final String accountId;
  final String module;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final List<String> skillsToLearn;
  final List<String> skillsToShare;
  final List<String> learningGoals;
  final bool isActivated;

  const LearningProfileDto({
    required this.profileId,
    required this.accountId,
    this.module = LearningProfile.moduleScope,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.skillsToLearn = const [],
    this.skillsToShare = const [],
    this.learningGoals = const [],
    this.isActivated = false,
  });

  /// Converts this DTO to an immutable domain [LearningProfile] entity.
  LearningProfile toDomain() {
    return LearningProfile(
      profileId: profileId,
      accountId: accountId,
      module: module,
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      skillsToLearn: skillsToLearn,
      skillsToShare: skillsToShare,
      learningGoals: learningGoals,
      isActivated: isActivated,
    );
  }

  /// Creates a [LearningProfileDto] from a domain [LearningProfile] entity.
  factory LearningProfileDto.fromDomain(LearningProfile entity) {
    return LearningProfileDto(
      profileId: entity.profileId,
      accountId: entity.accountId,
      module: entity.module,
      displayName: entity.displayName,
      bio: entity.bio,
      avatarUrl: entity.avatarUrl,
      skillsToLearn: entity.skillsToLearn,
      skillsToShare: entity.skillsToShare,
      learningGoals: entity.learningGoals,
      isActivated: entity.isActivated,
    );
  }

  /// Deserializes a [LearningProfileDto] from JSON map.
  ///
  /// Throws [FormatException] if required fields are missing, invalid types are found,
  /// or if [module] is mismatched.
  factory LearningProfileDto.fromJson(Map<String, dynamic> json) {
    final profileId = _extractRequiredString(json, 'profile_id', 'profileId');
    final accountId = _extractRequiredString(json, 'account_id', 'accountId');
    final module = _extractRequiredString(json, 'module', 'module');

    if (module != LearningProfile.moduleScope) {
      throw const FormatException(
        'Invalid module scope: expected "learning"',
      );
    }

    final displayName =
        _extractRequiredString(json, 'display_name', 'displayName');

    final bio = _extractOptionalString(json, 'bio');
    final avatarUrl = _extractOptionalString(json, 'avatar_url', 'avatarUrl');

    final skillsToLearn =
        _extractStringList(json, 'skills_to_learn', 'skillsToLearn');
    final skillsToShare =
        _extractStringList(json, 'skills_to_share', 'skillsToShare');
    final learningGoals =
        _extractStringList(json, 'learning_goals', 'learningGoals');

    final isActivatedRaw = json['is_activated'] ?? json['isActivated'];
    if (isActivatedRaw != null && isActivatedRaw is! bool) {
      throw const FormatException(
        'Invalid type for field "is_activated": expected boolean',
      );
    }
    final isActivated = isActivatedRaw as bool? ?? false;

    return LearningProfileDto(
      profileId: profileId,
      accountId: accountId,
      module: module,
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      skillsToLearn: skillsToLearn,
      skillsToShare: skillsToShare,
      learningGoals: learningGoals,
      isActivated: isActivated,
    );
  }

  /// Serializes this DTO to a standard JSON map.
  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'account_id': accountId,
      'module': module,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'skills_to_learn': skillsToLearn,
      'skills_to_share': skillsToShare,
      'learning_goals': learningGoals,
      'is_activated': isActivated,
    };
  }

  static String _extractRequiredString(
    Map<String, dynamic> json,
    String primaryKey, [
    String? fallbackKey,
  ]) {
    final dynamic rawValue = json.containsKey(primaryKey)
        ? json[primaryKey]
        : (fallbackKey != null ? json[fallbackKey] : null);

    if (rawValue == null) {
      throw FormatException('Missing required field "$primaryKey"');
    }
    if (rawValue is! String) {
      throw FormatException('Field "$primaryKey" must be a string');
    }
    if (rawValue.trim().isEmpty) {
      throw FormatException('Field "$primaryKey" must not be empty');
    }
    return rawValue.trim();
  }

  static String? _extractOptionalString(
    Map<String, dynamic> json,
    String primaryKey, [
    String? fallbackKey,
  ]) {
    final dynamic rawValue = json.containsKey(primaryKey)
        ? json[primaryKey]
        : (fallbackKey != null ? json[fallbackKey] : null);

    if (rawValue == null) return null;
    if (rawValue is! String) {
      throw FormatException('Field "$primaryKey" must be a string if provided');
    }
    return rawValue;
  }

  static List<String> _extractStringList(
    Map<String, dynamic> json,
    String primaryKey, [
    String? fallbackKey,
  ]) {
    final dynamic rawValue = json.containsKey(primaryKey)
        ? json[primaryKey]
        : (fallbackKey != null ? json[fallbackKey] : null);

    if (rawValue == null) return const [];
    if (rawValue is! List) {
      throw FormatException('Field "$primaryKey" must be a list');
    }
    final List<String> result = [];
    for (int i = 0; i < rawValue.length; i++) {
      final item = rawValue[i];
      if (item is! String) {
        throw FormatException(
          'Element at index $i in "$primaryKey" must be a string',
        );
      }
      result.add(item);
    }
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningProfileDto &&
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
}
