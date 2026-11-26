import 'package:flutter/foundation.dart';

/// Provenance kind distinguishing source authority for Learning Growth Evidence (LRN-04, DEC-20261120-LRN04-01).
enum LearningEvidenceKind {
  /// Self-reported evidence recorded voluntarily by the learner.
  selfReported,

  /// Formally verified evidence from recognized external sources or authorized assessments.
  verified;

  bool get isSelfReported => this == LearningEvidenceKind.selfReported;
  bool get isVerified => this == LearningEvidenceKind.verified;

  /// Safely parses a string into [LearningEvidenceKind].
  static LearningEvidenceKind parse(
    String? value, {
    LearningEvidenceKind defaultValue = LearningEvidenceKind.selfReported,
  }) {
    if (value == null) return defaultValue;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'verified':
      case 'verifiedsource':
      case 'verified_source':
        return LearningEvidenceKind.verified;
      case 'selfreported':
      case 'self_reported':
      case 'self':
      default:
        return defaultValue;
    }
  }
}

/// Qualitative evidence sufficiency classification for a tracked skill (LRN-04, BRD v2.4-R1).
///
/// GOVERNANCE RULE:
/// Never equates evidence to XP, skill mastery, or formal certification.
/// Missing evidence is NOT proof of a missing skill.
enum EvidenceSufficiencyStatus {
  /// Skill has substantiated evidence from verified sources.
  verifiedSource,

  /// Skill has self-reported learner evidence only.
  selfReportedOnly,

  /// Insufficient or absent evidence to substantiate external assessment.
  insufficientEvidence;

  bool get isVerifiedSource => this == EvidenceSufficiencyStatus.verifiedSource;
  bool get isSelfReportedOnly =>
      this == EvidenceSufficiencyStatus.selfReportedOnly;
  bool get isInsufficientEvidence =>
      this == EvidenceSufficiencyStatus.insufficientEvidence;

  /// Safely parses a string into [EvidenceSufficiencyStatus].
  static EvidenceSufficiencyStatus parse(
    String? value, {
    EvidenceSufficiencyStatus defaultValue =
        EvidenceSufficiencyStatus.insufficientEvidence,
  }) {
    if (value == null) return defaultValue;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'verifiedsource':
      case 'verified_source':
      case 'verified':
        return EvidenceSufficiencyStatus.verifiedSource;
      case 'selfreportedonly':
      case 'self_reported_only':
      case 'selfreported':
        return EvidenceSufficiencyStatus.selfReportedOnly;
      case 'insufficientevidence':
      case 'insufficient_evidence':
      case 'insufficient':
      default:
        return defaultValue;
    }
  }
}

/// Immutable record of Learning Growth Evidence (LRN-04, DEC-20261120-LRN04-01).
///
/// Follows backend and security governance:
/// - Strictly scoped to module 'learning'.
/// - [isPrivate] is always true (growth is private by default).
/// - Never exposes internal account IDs to public view.
/// - Does not award automated XP, skill-gap verdicts, or credentials.
/// - Redacted [toString] prevents accidental PII leakage in logs.
@immutable
class LearningGrowthEvidence {
  /// Canonical module scope invariant.
  static const String moduleScope = 'learning';

  /// Standard disconnected persistence notice when running in local presentation mode.
  static const String disconnectedNotice =
      'Remote Growth backend contract pending in OpenAPI v1. Growth Dashboard operates in local presentation mode.';

  /// Unique evidence identifier.
  final String id;

  /// Internal account identifier reference.
  final String accountId;

  /// Opaque Learning profile identifier.
  final String learningProfileId;

  /// Canonical module (strictly 'learning').
  final String module;

  /// Provenance classification (self-reported vs verified).
  final LearningEvidenceKind kind;

  /// Privacy flag (strictly true for private dashboard).
  final bool isPrivate;

  /// Descriptive title of the evidence artifact.
  final String title;

  /// Contextual narrative or description of the learning activity.
  final String description;

  /// Associated opaque skill identifiers.
  final List<String> skillIds;

  /// Associated skill display names for presentation.
  final List<String> skillNames;

  /// Optional source or artifact reference (e.g. "Self-Reflection", "Project: Clean Architecture").
  final String? sourceReference;

  /// Timestamp when the evidence was recorded.
  final DateTime recordedAt;

  /// Timestamp when formally verified, if applicable.
  final DateTime? verifiedAt;

  /// Optional display name of verifying institution or assessor.
  final String? verifierName;

  LearningGrowthEvidence({
    required String id,
    required String accountId,
    required String learningProfileId,
    String module = moduleScope,
    this.kind = LearningEvidenceKind.selfReported,
    this.isPrivate = true,
    required String title,
    required String description,
    Iterable<String>? skillIds,
    Iterable<String>? skillNames,
    this.sourceReference,
    DateTime? recordedAt,
    this.verifiedAt,
    this.verifierName,
  })  : id = _validateRequired(id, 'id'),
        accountId = _validateRequired(accountId, 'accountId'),
        learningProfileId =
            _validateRequired(learningProfileId, 'learningProfileId'),
        module = _validateModule(module),
        title = _validateRequired(title, 'title'),
        description = _validateRequired(description, 'description'),
        skillIds = List<String>.unmodifiable(
          _validateDistinctSkills(skillIds ?? const <String>[]),
        ),
        skillNames = List<String>.unmodifiable(
          skillNames?.map((s) => s.trim()).where((s) => s.isNotEmpty) ??
              const <String>[],
        ),
        recordedAt = recordedAt ?? DateTime.now();

  static String _validateRequired(String value, String fieldName) {
    final clean = value.trim();
    if (clean.isEmpty) {
      throw ArgumentError.value(
          value, fieldName, '$fieldName cannot be empty.');
    }
    return clean;
  }

  static String _validateModule(String module) {
    final clean = module.trim();
    if (clean.isNotEmpty && clean != moduleScope) {
      throw ArgumentError.value(
        module,
        'module',
        'Growth evidence module must strictly be "$moduleScope".',
      );
    }
    return moduleScope;
  }

  static List<String> _validateDistinctSkills(Iterable<String> skills) {
    final distinct = <String>{};
    final list = <String>[];
    for (final s in skills) {
      final clean = s.trim();
      if (clean.isNotEmpty && distinct.add(clean)) {
        list.add(clean);
      }
    }
    return list;
  }

  /// Factory for recording self-reported evidence.
  factory LearningGrowthEvidence.recordSelfReport({
    required String id,
    required String accountId,
    required String learningProfileId,
    required String title,
    required String description,
    Iterable<String>? skillIds,
    Iterable<String>? skillNames,
    String? sourceReference,
    DateTime? recordedAt,
  }) {
    return LearningGrowthEvidence(
      id: id,
      accountId: accountId,
      learningProfileId: learningProfileId,
      kind: LearningEvidenceKind.selfReported,
      isPrivate: true,
      title: title,
      description: description,
      skillIds: skillIds,
      skillNames: skillNames,
      sourceReference: sourceReference,
      recordedAt: recordedAt,
    );
  }

  /// Factory for recording verified-source evidence.
  factory LearningGrowthEvidence.recordVerified({
    required String id,
    required String accountId,
    required String learningProfileId,
    required String title,
    required String description,
    Iterable<String>? skillIds,
    Iterable<String>? skillNames,
    required String sourceReference,
    required String verifierName,
    DateTime? recordedAt,
    DateTime? verifiedAt,
  }) {
    return LearningGrowthEvidence(
      id: id,
      accountId: accountId,
      learningProfileId: learningProfileId,
      kind: LearningEvidenceKind.verified,
      isPrivate: true,
      title: title,
      description: description,
      skillIds: skillIds,
      skillNames: skillNames,
      sourceReference: sourceReference,
      verifierName: verifierName,
      recordedAt: recordedAt,
      verifiedAt: verifiedAt ?? DateTime.now(),
    );
  }

  LearningGrowthEvidence copyWith({
    String? id,
    String? accountId,
    String? learningProfileId,
    String? module,
    LearningEvidenceKind? kind,
    bool? isPrivate,
    String? title,
    String? description,
    List<String>? skillIds,
    List<String>? skillNames,
    String? sourceReference,
    DateTime? recordedAt,
    DateTime? verifiedAt,
    String? verifierName,
  }) {
    return LearningGrowthEvidence(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      learningProfileId: learningProfileId ?? this.learningProfileId,
      module: module ?? this.module,
      kind: kind ?? this.kind,
      isPrivate: isPrivate ?? this.isPrivate,
      title: title ?? this.title,
      description: description ?? this.description,
      skillIds: skillIds ?? this.skillIds,
      skillNames: skillNames ?? this.skillNames,
      sourceReference: sourceReference ?? this.sourceReference,
      recordedAt: recordedAt ?? this.recordedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifierName: verifierName ?? this.verifierName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'learningProfileId': learningProfileId,
        'module': module,
        'kind': kind.name,
        'isPrivate': isPrivate,
        'title': title,
        'description': description,
        'skillIds': skillIds,
        'skillNames': skillNames,
        'sourceReference': sourceReference,
        'recordedAt': recordedAt.toIso8601String(),
        'verifiedAt': verifiedAt?.toIso8601String(),
        'verifierName': verifierName,
      };

  factory LearningGrowthEvidence.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skillIds'];
    final parsedSkills = <String>[];
    if (rawSkills is Iterable) {
      for (final item in rawSkills) {
        if (item != null && item.toString().trim().isNotEmpty) {
          parsedSkills.add(item.toString().trim());
        }
      }
    }

    final rawNames = json['skillNames'];
    final parsedNames = <String>[];
    if (rawNames is Iterable) {
      for (final item in rawNames) {
        if (item != null && item.toString().trim().isNotEmpty) {
          parsedNames.add(item.toString().trim());
        }
      }
    }

    return LearningGrowthEvidence(
      id: json['id']?.toString() ?? '',
      accountId: json['accountId']?.toString() ?? '',
      learningProfileId: json['learningProfileId']?.toString() ?? '',
      module: json['module']?.toString() ?? moduleScope,
      kind: LearningEvidenceKind.parse(json['kind']?.toString()),
      isPrivate: json['isPrivate'] != false,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      skillIds: parsedSkills,
      skillNames: parsedNames,
      sourceReference: json['sourceReference']?.toString(),
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'].toString())
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'].toString())
          : null,
      verifierName: json['verifierName']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningGrowthEvidence &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          accountId == other.accountId &&
          learningProfileId == other.learningProfileId &&
          module == other.module &&
          kind == other.kind &&
          isPrivate == other.isPrivate &&
          title == other.title &&
          description == other.description &&
          listEquals(skillIds, other.skillIds) &&
          sourceReference == other.sourceReference;

  @override
  int get hashCode => Object.hash(
        id,
        accountId,
        learningProfileId,
        module,
        kind,
        isPrivate,
        title,
        description,
        Object.hashAll(skillIds),
        sourceReference,
      );

  @override
  String toString() =>
      'LearningGrowthEvidence [identities and associations omitted]';
}

/// A skill actively tracked by the learner within their private growth profile (LRN-04).
@immutable
class LearningTrackedSkill {
  /// Unique skill identifier.
  final String id;

  /// Display name of the skill (e.g., 'Flutter Architecture', 'Dart').
  final String name;

  /// Category or domain grouping (e.g., 'Mobile Development', 'System Design').
  final String category;

  /// List of associated evidence record IDs.
  final List<String> associatedEvidenceIds;

  /// Sufficiency status based on associated evidence provenance.
  final EvidenceSufficiencyStatus sufficiencyStatus;

  /// Optional qualitative context or notes.
  final String? notes;

  LearningTrackedSkill({
    required String id,
    required String name,
    required String category,
    Iterable<String>? associatedEvidenceIds,
    this.sufficiencyStatus = EvidenceSufficiencyStatus.insufficientEvidence,
    this.notes,
  })  : id = _validateRequired(id, 'id'),
        name = _validateRequired(name, 'name'),
        category = _validateRequired(category, 'category'),
        associatedEvidenceIds = List<String>.unmodifiable(
          associatedEvidenceIds
                  ?.map((e) => e.trim())
                  .where((e) => e.isNotEmpty) ??
              const <String>[],
        );

  static String _validateRequired(String value, String fieldName) {
    final clean = value.trim();
    if (clean.isEmpty) {
      throw ArgumentError.value(
          value, fieldName, '$fieldName cannot be empty.');
    }
    return clean;
  }

  int get evidenceCount => associatedEvidenceIds.length;

  bool get hasEvidence => associatedEvidenceIds.isNotEmpty;

  LearningTrackedSkill copyWith({
    String? id,
    String? name,
    String? category,
    List<String>? associatedEvidenceIds,
    EvidenceSufficiencyStatus? sufficiencyStatus,
    String? notes,
  }) {
    return LearningTrackedSkill(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      associatedEvidenceIds:
          associatedEvidenceIds ?? this.associatedEvidenceIds,
      sufficiencyStatus: sufficiencyStatus ?? this.sufficiencyStatus,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'associatedEvidenceIds': associatedEvidenceIds,
        'sufficiencyStatus': sufficiencyStatus.name,
        'notes': notes,
      };

  factory LearningTrackedSkill.fromJson(Map<String, dynamic> json) {
    final rawEv = json['associatedEvidenceIds'];
    final parsedEv = <String>[];
    if (rawEv is Iterable) {
      for (final item in rawEv) {
        if (item != null && item.toString().trim().isNotEmpty) {
          parsedEv.add(item.toString().trim());
        }
      }
    }

    return LearningTrackedSkill(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      associatedEvidenceIds: parsedEv,
      sufficiencyStatus: EvidenceSufficiencyStatus.parse(
          json['sufficiencyStatus']?.toString()),
      notes: json['notes']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningTrackedSkill &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          listEquals(associatedEvidenceIds, other.associatedEvidenceIds) &&
          sufficiencyStatus == other.sufficiencyStatus;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        category,
        Object.hashAll(associatedEvidenceIds),
        sufficiencyStatus,
      );

  @override
  String toString() => 'LearningTrackedSkill [skill identity omitted]';
}

/// Aggregate summary of private growth metrics for the Overview presentation (LRN-04).
@immutable
class LearningGrowthSummary {
  final int totalEvidenceCount;
  final int verifiedEvidenceCount;
  final int selfReportedEvidenceCount;
  final int trackedSkillsCount;
  final int verifiedSkillsCount;
  final int selfReportedOnlySkillsCount;
  final int insufficientEvidenceSkillsCount;
  final List<LearningGrowthEvidence> recentEvidence;

  const LearningGrowthSummary({
    this.totalEvidenceCount = 0,
    this.verifiedEvidenceCount = 0,
    this.selfReportedEvidenceCount = 0,
    this.trackedSkillsCount = 0,
    this.verifiedSkillsCount = 0,
    this.selfReportedOnlySkillsCount = 0,
    this.insufficientEvidenceSkillsCount = 0,
    this.recentEvidence = const <LearningGrowthEvidence>[],
  });

  /// Factory calculating summary aggregate from raw evidence and skills lists.
  factory LearningGrowthSummary.fromData({
    required List<LearningGrowthEvidence> evidence,
    required List<LearningTrackedSkill> skills,
  }) {
    final verifiedEv =
        evidence.where((e) => e.kind == LearningEvidenceKind.verified).length;
    final selfReportedEv = evidence
        .where((e) => e.kind == LearningEvidenceKind.selfReported)
        .length;

    final verifiedSk = skills
        .where((s) =>
            s.sufficiencyStatus == EvidenceSufficiencyStatus.verifiedSource)
        .length;
    final selfReportedSk = skills
        .where((s) =>
            s.sufficiencyStatus == EvidenceSufficiencyStatus.selfReportedOnly)
        .length;
    final insufficientSk = skills
        .where((s) =>
            s.sufficiencyStatus ==
            EvidenceSufficiencyStatus.insufficientEvidence)
        .length;

    final sortedRecent = List<LearningGrowthEvidence>.of(evidence)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return LearningGrowthSummary(
      totalEvidenceCount: evidence.length,
      verifiedEvidenceCount: verifiedEv,
      selfReportedEvidenceCount: selfReportedEv,
      trackedSkillsCount: skills.length,
      verifiedSkillsCount: verifiedSk,
      selfReportedOnlySkillsCount: selfReportedSk,
      insufficientEvidenceSkillsCount: insufficientSk,
      recentEvidence: sortedRecent.take(5).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalEvidenceCount': totalEvidenceCount,
        'verifiedEvidenceCount': verifiedEvidenceCount,
        'selfReportedEvidenceCount': selfReportedEvidenceCount,
        'trackedSkillsCount': trackedSkillsCount,
        'verifiedSkillsCount': verifiedSkillsCount,
        'selfReportedOnlySkillsCount': selfReportedOnlySkillsCount,
        'insufficientEvidenceSkillsCount': insufficientEvidenceSkillsCount,
        'recentEvidence': recentEvidence.map((e) => e.toJson()).toList(),
      };

  factory LearningGrowthSummary.fromJson(Map<String, dynamic> json) {
    final rawRecent = json['recentEvidence'];
    final parsedRecent = <LearningGrowthEvidence>[];
    if (rawRecent is Iterable) {
      for (final item in rawRecent) {
        if (item is Map<String, dynamic>) {
          parsedRecent.add(LearningGrowthEvidence.fromJson(item));
        }
      }
    }

    return LearningGrowthSummary(
      totalEvidenceCount: json['totalEvidenceCount'] as int? ?? 0,
      verifiedEvidenceCount: json['verifiedEvidenceCount'] as int? ?? 0,
      selfReportedEvidenceCount: json['selfReportedEvidenceCount'] as int? ?? 0,
      trackedSkillsCount: json['trackedSkillsCount'] as int? ?? 0,
      verifiedSkillsCount: json['verifiedSkillsCount'] as int? ?? 0,
      selfReportedOnlySkillsCount:
          json['selfReportedOnlySkillsCount'] as int? ?? 0,
      insufficientEvidenceSkillsCount:
          json['insufficientEvidenceSkillsCount'] as int? ?? 0,
      recentEvidence: parsedRecent,
    );
  }

  @override
  String toString() =>
      'LearningGrowthSummary [private growth summary metrics omitted]';
}
