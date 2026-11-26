import 'package:flutter/foundation.dart';

/// Private explanation of an identified topic gap grounded in authoritative evidence (LRN-04, GRW-01-05).
///
/// Follows strict ANDRIL M1 governance:
/// - Only presented when authoritative evidence sufficiency is established.
/// - Never interprets missing evidence as missing skill.
/// - Does not calculate scores, XP rewards, or proficiency ratings.
/// - Redacted [toString] prevents PII leakage in diagnostic logs.
@immutable
class LearningTopicGap {
  static const String moduleScope = 'learning';

  /// Standard disconnected notice when operating in presentation mode.
  static const String disconnectedNotice =
      'Remote Growth backend contract pending in OpenAPI v1. Topic Gap analysis operates in local presentation mode.';

  /// Insufficient evidence governance warning.
  static const String insufficientEvidenceNotice =
      'Evidence is currently insufficient to substantiate a topic gap analysis. Missing evidence does not imply absence of skill.';

  /// Unique identifier of the topic gap explanation.
  final String id;

  /// Internal account identifier reference.
  final String accountId;

  /// Opaque Learning profile identifier.
  final String learningProfileId;

  /// Canonical module (strictly 'learning').
  final String module;

  /// Suggested topic area title (e.g. 'Flutter State Management').
  final String topicTitle;

  /// High-level domain or skill category (e.g. 'Mobile Development').
  final String topicDomain;

  /// List of evidence record titles or artifacts reviewed.
  final List<String> reviewedEvidenceTitles;

  /// Objective explanation explaining the context of the reviewed work.
  final String explanation;

  /// Constructive suggested next step for the learner.
  final String suggestedNextStep;

  /// Whether authoritative evidence sufficiency was established.
  final bool isSufficientEvidence;

  /// Privacy flag (strictly true for private dashboard).
  final bool isPrivate;

  /// Timestamp when the explanation was generated.
  final DateTime generatedAt;

  LearningTopicGap({
    required String id,
    required String accountId,
    required String learningProfileId,
    String module = moduleScope,
    required String topicTitle,
    required String topicDomain,
    Iterable<String>? reviewedEvidenceTitles,
    required String explanation,
    required String suggestedNextStep,
    this.isSufficientEvidence = true,
    bool isPrivate = true,
    DateTime? generatedAt,
  })  : id = _validateRequired(id, 'id'),
        accountId = _validateRequired(accountId, 'accountId'),
        learningProfileId =
            _validateRequired(learningProfileId, 'learningProfileId'),
        module = _validateModule(module),
        topicTitle = _validateRequired(topicTitle, 'topicTitle'),
        topicDomain = _validateRequired(topicDomain, 'topicDomain'),
        reviewedEvidenceTitles = List<String>.unmodifiable(
          reviewedEvidenceTitles
                  ?.map((e) => e.trim())
                  .where((e) => e.isNotEmpty) ??
              const <String>[],
        ),
        explanation = _validateRequired(explanation, 'explanation'),
        suggestedNextStep =
            _validateRequired(suggestedNextStep, 'suggestedNextStep'),
        isPrivate = _validatePrivate(isPrivate),
        generatedAt = generatedAt ?? DateTime.now();

  static bool _validatePrivate(bool isPrivate) {
    if (!isPrivate) {
      throw ArgumentError.value(
        isPrivate,
        'isPrivate',
        'Topic gap explanation must strictly be private.',
      );
    }
    return true;
  }

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
        'Topic gap module must strictly be "$moduleScope".',
      );
    }
    return moduleScope;
  }

  /// Factory constructing an insufficient evidence fallback explanation.
  factory LearningTopicGap.insufficientEvidence({
    required String id,
    required String accountId,
    required String learningProfileId,
    required String topicTitle,
    required String topicDomain,
  }) {
    return LearningTopicGap(
      id: id,
      accountId: accountId,
      learningProfileId: learningProfileId,
      topicTitle: topicTitle,
      topicDomain: topicDomain,
      reviewedEvidenceTitles: const [],
      explanation: insufficientEvidenceNotice,
      suggestedNextStep:
          'Record self-reported practice reflections or complete learning pact activities to substantiate evidence.',
      isSufficientEvidence: false,
      isPrivate: true,
    );
  }

  LearningTopicGap copyWith({
    String? id,
    String? accountId,
    String? learningProfileId,
    String? module,
    String? topicTitle,
    String? topicDomain,
    List<String>? reviewedEvidenceTitles,
    String? explanation,
    String? suggestedNextStep,
    bool? isSufficientEvidence,
    bool? isPrivate,
    DateTime? generatedAt,
  }) {
    return LearningTopicGap(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      learningProfileId: learningProfileId ?? this.learningProfileId,
      module: module ?? this.module,
      topicTitle: topicTitle ?? this.topicTitle,
      topicDomain: topicDomain ?? this.topicDomain,
      reviewedEvidenceTitles:
          reviewedEvidenceTitles ?? this.reviewedEvidenceTitles,
      explanation: explanation ?? this.explanation,
      suggestedNextStep: suggestedNextStep ?? this.suggestedNextStep,
      isSufficientEvidence: isSufficientEvidence ?? this.isSufficientEvidence,
      isPrivate: isPrivate ?? this.isPrivate,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'learningProfileId': learningProfileId,
        'module': module,
        'topicTitle': topicTitle,
        'topicDomain': topicDomain,
        'reviewedEvidenceTitles': reviewedEvidenceTitles,
        'explanation': explanation,
        'suggestedNextStep': suggestedNextStep,
        'isSufficientEvidence': isSufficientEvidence,
        'isPrivate': isPrivate,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory LearningTopicGap.fromJson(Map<String, dynamic> json) {
    final rawReviewed = json['reviewedEvidenceTitles'];
    final parsedReviewed = <String>[];
    if (rawReviewed is Iterable) {
      for (final item in rawReviewed) {
        if (item != null && item.toString().trim().isNotEmpty) {
          parsedReviewed.add(item.toString().trim());
        }
      }
    }

    return LearningTopicGap(
      id: json['id']?.toString() ?? '',
      accountId: json['accountId']?.toString() ?? '',
      learningProfileId: json['learningProfileId']?.toString() ?? '',
      module: json['module']?.toString() ?? moduleScope,
      topicTitle: json['topicTitle']?.toString() ?? '',
      topicDomain: json['topicDomain']?.toString() ?? '',
      reviewedEvidenceTitles: parsedReviewed,
      explanation: json['explanation']?.toString() ?? '',
      suggestedNextStep: json['suggestedNextStep']?.toString() ?? '',
      isSufficientEvidence: json['isSufficientEvidence'] != false,
      isPrivate: json['isPrivate'] != false,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString())
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningTopicGap &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          accountId == other.accountId &&
          learningProfileId == other.learningProfileId &&
          module == other.module &&
          topicTitle == other.topicTitle &&
          topicDomain == other.topicDomain &&
          listEquals(reviewedEvidenceTitles, other.reviewedEvidenceTitles) &&
          explanation == other.explanation &&
          suggestedNextStep == other.suggestedNextStep &&
          isSufficientEvidence == other.isSufficientEvidence &&
          isPrivate == other.isPrivate;

  @override
  int get hashCode => Object.hash(
        id,
        accountId,
        learningProfileId,
        module,
        topicTitle,
        topicDomain,
        Object.hashAll(reviewedEvidenceTitles),
        explanation,
        suggestedNextStep,
        isSufficientEvidence,
        isPrivate,
      );

  @override
  String toString() => 'LearningTopicGap [private references omitted]';
}
