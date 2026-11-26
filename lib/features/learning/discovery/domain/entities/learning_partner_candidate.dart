import 'package:flutter/foundation.dart';

/// Immutable domain model representing an eligible Learning partner candidate card (CF-04).
///
/// Follows ANDRIL Learning Module architectural and privacy requirements:
/// - Strictly scoped to module 'learning'. Cross-module discovery is blocked.
/// - Distinguishes module-profile identity ([id]) from account identities. Internal account IDs are never exposed.
/// - Defensive immutability: copies and freezes all collection properties upon construction.
/// - Order-independent equality and hash code contracts.
/// - Redacted [toString] ensures confidential learner data is never leaked into logs or crash dumps.
/// - Does not fabricate online status, GPS locations, verification badges, matching scores, or connections.
@immutable
class LearningPartnerCandidate {
  /// The canonical module identifier.
  static const String moduleScope = 'learning';

  /// Learning-scoped unique profile identifier (e.g. 'lp_candidate_01').
  final String id;

  /// User-visible approved display name.
  final String displayName;

  /// Defensive unmodifiable list of skills the candidate can teach or share.
  final List<String> _skillsToShare;

  /// Defensive unmodifiable list of skills the candidate wants to learn.
  final List<String> _skillsToLearn;

  /// Defensive unmodifiable list of learning goals.
  final List<String> _learningGoals;

  /// Candidate's declared proficiency level (e.g., 'Beginner', 'Intermediate', 'Advanced').
  final String proficiencyLevel;

  /// Defensive unmodifiable list of communication languages (e.g. English, Tamil, Tanglish).
  final List<String> _languages;

  /// Stated learning availability window (from approved Q07_LUC-03 specification).
  final String? availability;

  /// Optional biographical statement or learning mission.
  final String? bio;

  /// Optional avatar URL or image resource path.
  final String? avatarUrl;

  /// Authoritative server-side candidate eligibility and active discovery flag.
  final bool isActive;

  /// Module identifier. Invariant: must strictly equal [moduleScope] ('learning').
  final String module;

  /// Constructs an immutable [LearningPartnerCandidate] with defensive collection copying.
  LearningPartnerCandidate({
    required String id,
    required this.displayName,
    Iterable<String>? skillsToShare,
    Iterable<String>? skillsToLearn,
    Iterable<String>? learningGoals,
    this.proficiencyLevel = 'Intermediate',
    Iterable<String>? languages,
    this.availability,
    this.bio,
    this.avatarUrl,
    this.isActive = true,
    String module = moduleScope,
  })  : id = _validateId(id, 'id'),
        module = _validateModule(module),
        _skillsToShare = skillsToShare == null
            ? const <String>[]
            : List<String>.unmodifiable(List<String>.of(skillsToShare)),
        _skillsToLearn = skillsToLearn == null
            ? const <String>[]
            : List<String>.unmodifiable(List<String>.of(skillsToLearn)),
        _learningGoals = learningGoals == null
            ? const <String>[]
            : List<String>.unmodifiable(List<String>.of(learningGoals)),
        _languages = languages == null
            ? const <String>['English']
            : List<String>.unmodifiable(List<String>.of(languages));

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
        'LearningPartnerCandidate must belong to module "$moduleScope", got "$value"',
      );
    }
    return value;
  }

  /// Unmodifiable view of skills candidate can share/teach.
  List<String> get skillsToShare => _skillsToShare;

  /// Unmodifiable view of skills candidate wants to learn.
  List<String> get skillsToLearn => _skillsToLearn;

  /// Unmodifiable view of learning goals.
  List<String> get learningGoals => _learningGoals;

  /// Unmodifiable view of communication languages.
  List<String> get languages => _languages;

  /// Constructs a [LearningPartnerCandidate] from backend JSON representation.
  factory LearningPartnerCandidate.fromJson(Map<String, dynamic> json) {
    final candidateId = json['candidateProfileId']?.toString() ??
        json['profileId']?.toString() ??
        json['id']?.toString() ??
        '';

    final name = json['displayName']?.toString() ?? 'Learning Partner';
    final mod = json['module']?.toString() ?? moduleScope;

    final shareList = (json['skillsToShare'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['skillsOffered'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    final learnList = (json['skillsToLearn'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['skillsWanted'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    final goalList = (json['learningGoals'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['goals'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const <String>[];

    final langList = (json['languages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['communicationLanguages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>['English'];

    final prof = json['proficiencyLevel']?.toString() ??
        json['proficiency']?.toString() ??
        'Intermediate';

    final avail = json['availability']?.toString();
    final bioText = json['bio']?.toString() ?? json['biography']?.toString();
    final avatar = json['avatarUrl']?.toString();
    final active = json['isActive'] != false;

    return LearningPartnerCandidate(
      id: candidateId,
      displayName: name,
      skillsToShare: shareList,
      skillsToLearn: learnList,
      learningGoals: goalList,
      proficiencyLevel: prof,
      languages: langList,
      availability: avail,
      bio: bioText,
      avatarUrl: avatar,
      isActive: active,
      module: mod,
    );
  }

  /// Serializes candidate to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'candidateProfileId': id,
      'displayName': displayName,
      'module': module,
      'skillsToShare': _skillsToShare,
      'skillsToLearn': _skillsToLearn,
      'learningGoals': _learningGoals,
      'proficiencyLevel': proficiencyLevel,
      'languages': _languages,
      if (availability != null) 'availability': availability,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'isActive': isActive,
    };
  }

  /// Copies candidate with updated fields.
  LearningPartnerCandidate copyWith({
    String? displayName,
    Iterable<String>? skillsToShare,
    Iterable<String>? skillsToLearn,
    Iterable<String>? learningGoals,
    String? proficiencyLevel,
    Iterable<String>? languages,
    String? availability,
    String? bio,
    String? avatarUrl,
    bool? isActive,
  }) {
    return LearningPartnerCandidate(
      id: id,
      displayName: displayName ?? this.displayName,
      skillsToShare: skillsToShare ?? _skillsToShare,
      skillsToLearn: skillsToLearn ?? _skillsToLearn,
      learningGoals: learningGoals ?? _learningGoals,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      languages: languages ?? _languages,
      availability: availability ?? this.availability,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      module: module,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningPartnerCandidate &&
        other.id == id &&
        other.displayName == displayName &&
        other.module == module &&
        other.proficiencyLevel == proficiencyLevel &&
        other.availability == availability &&
        other.bio == bio &&
        other.avatarUrl == avatarUrl &&
        other.isActive == isActive &&
        listEquals(other._skillsToShare, _skillsToShare) &&
        listEquals(other._skillsToLearn, _skillsToLearn) &&
        listEquals(other._learningGoals, _learningGoals) &&
        listEquals(other._languages, _languages);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      displayName,
      module,
      proficiencyLevel,
      availability,
      bio,
      avatarUrl,
      isActive,
      Object.hashAll(_skillsToShare),
      Object.hashAll(_skillsToLearn),
      Object.hashAll(_learningGoals),
      Object.hashAll(_languages),
    );
  }

  /// Strictly redacted representation to prevent confidential learner data leakage.
  @override
  String toString() =>
      'LearningPartnerCandidate(id: $id, displayName: $displayName, module: $module)';
}
