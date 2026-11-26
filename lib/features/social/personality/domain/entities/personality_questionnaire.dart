import 'package:flutter/foundation.dart';

/// Immutable domain entity representing a single option in a personality question.
@immutable
class PersonalityOption {
  final String id;
  final String label;

  PersonalityOption({
    required String id,
    required String label,
  })  : id = _validateId(id),
        label = _validateLabel(label);

  static String _validateId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'id', 'Option ID cannot be empty');
    }
    return trimmed;
  }

  static String _validateLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'label', 'Option label cannot be empty');
    }
    return trimmed;
  }

  factory PersonalityOption.fromJson(Map<String, dynamic> json) {
    return PersonalityOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalityOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label;

  @override
  int get hashCode => Object.hash(id, label);

  @override
  String toString() => 'PersonalityOption(id: $id, label: $label)';
}

/// Immutable domain entity representing a single canonical question in the questionnaire.
@immutable
class PersonalityQuestion {
  final String id;
  final String prompt;
  final bool isRequired;
  final List<PersonalityOption> options;

  PersonalityQuestion({
    required String id,
    required String prompt,
    this.isRequired = true,
    required List<PersonalityOption> options,
  })  : id = _validateId(id),
        prompt = _validatePrompt(prompt),
        options = _validateOptions(options);

  static String _validateId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'id', 'Question ID cannot be empty');
    }
    return trimmed;
  }

  static String _validatePrompt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'prompt', 'Question prompt cannot be empty');
    }
    return trimmed;
  }

  static List<PersonalityOption> _validateOptions(List<PersonalityOption> list) {
    if (list.isEmpty) {
      throw ArgumentError.value(list, 'options', 'Question must provide at least one option');
    }
    final seen = <String>{};
    for (final opt in list) {
      if (!seen.add(opt.id)) {
        throw ArgumentError.value(
          opt.id,
          'options',
          'Duplicate option ID "${opt.id}" in question',
        );
      }
    }
    return List.unmodifiable(list);
  }

  factory PersonalityQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return PersonalityQuestion(
      id: json['id'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      isRequired: json['isRequired'] as bool? ?? true,
      options: rawOptions
          .map((e) => PersonalityOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'isRequired': isRequired,
        'options': options.map((e) => e.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalityQuestion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          prompt == other.prompt &&
          isRequired == other.isRequired &&
          listEquals(options, other.options);

  @override
  int get hashCode => Object.hash(id, prompt, isRequired, Object.hashAll(options));

  @override
  String toString() =>
      'PersonalityQuestion(id: $id, prompt: $prompt, isRequired: $isRequired, optionsCount: ${options.length})';
}

/// Immutable definition of the authoritative Personality Questionnaire.
@immutable
class PersonalityQuestionnaire {
  final String version;
  final List<PersonalityQuestion> questions;

  PersonalityQuestionnaire({
    required String version,
    required List<PersonalityQuestion> questions,
  })  : version = _validateVersion(version),
        questions = _validateQuestions(questions);

  static String _validateVersion(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'version', 'Questionnaire version cannot be empty');
    }
    return trimmed;
  }

  static List<PersonalityQuestion> _validateQuestions(List<PersonalityQuestion> list) {
    if (list.isEmpty) {
      throw ArgumentError.value(list, 'questions', 'Questionnaire must contain at least one question');
    }
    final seen = <String>{};
    for (final q in list) {
      if (!seen.add(q.id)) {
        throw ArgumentError.value(
          q.id,
          'questions',
          'Duplicate question ID "${q.id}" in questionnaire',
        );
      }
    }
    return List.unmodifiable(list);
  }

  int get totalQuestions => questions.length;
  int get requiredQuestionsCount => questions.where((q) => q.isRequired).length;

  factory PersonalityQuestionnaire.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    return PersonalityQuestionnaire(
      version: json['version'] as String? ?? '',
      questions: rawQuestions
          .map((e) => PersonalityQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'questions': questions.map((e) => e.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalityQuestionnaire &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          listEquals(questions, other.questions);

  @override
  int get hashCode => Object.hash(version, Object.hashAll(questions));

  @override
  String toString() =>
      'PersonalityQuestionnaire(version: $version, questionsCount: ${questions.length})';
}

/// Immutable private answer draft maintained client-side during questionnaire progression.
///
/// Follows M5 Privacy & Security Governance:
/// - In-memory only; never written to insecure persistent cache.
/// - Redacted diagnostics (never logs raw answers).
/// - Answer draft completeness requires every `isRequired == true` question to be answered.
@immutable
class PersonalityAnswerDraft {
  final String questionnaireVersion;
  final Map<String, String> answers; // questionId -> optionId

  PersonalityAnswerDraft({
    required this.questionnaireVersion,
    Map<String, String> answers = const {},
  }) : answers = Map.unmodifiable(answers);

  /// Returns a new draft with the answer for [questionId] updated to [optionId].
  PersonalityAnswerDraft setAnswer({
    required String questionId,
    required String optionId,
  }) {
    final updated = Map<String, String>.from(answers);
    updated[questionId] = optionId;
    return PersonalityAnswerDraft(
      questionnaireVersion: questionnaireVersion,
      answers: updated,
    );
  }

  /// Returns a new draft with the answer for [questionId] removed.
  PersonalityAnswerDraft removeAnswer(String questionId) {
    if (!answers.containsKey(questionId)) return this;
    final updated = Map<String, String>.from(answers)..remove(questionId);
    return PersonalityAnswerDraft(
      questionnaireVersion: questionnaireVersion,
      answers: updated,
    );
  }

  /// Checks if all required questions in [questionnaire] have been answered.
  bool isCompleteFor(PersonalityQuestionnaire questionnaire) {
    if (questionnaire.version != questionnaireVersion) return false;
    for (final q in questionnaire.questions) {
      if (q.isRequired) {
        final chosenOptionId = answers[q.id];
        if (chosenOptionId == null || chosenOptionId.isEmpty) {
          return false;
        }
        // Verify chosen option actually exists on question
        final optionExists = q.options.any((opt) => opt.id == chosenOptionId);
        if (!optionExists) return false;
      }
    }
    return true;
  }

  /// Returns completion fraction between 0.0 and 1.0 based on total questions.
  double completionProgress(PersonalityQuestionnaire questionnaire) {
    if (questionnaire.questions.isEmpty) return 0.0;
    int answeredCount = 0;
    for (final q in questionnaire.questions) {
      if (answers.containsKey(q.id) && answers[q.id]!.isNotEmpty) {
        answeredCount++;
      }
    }
    return answeredCount / questionnaire.questions.length;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalityAnswerDraft &&
          runtimeType == other.runtimeType &&
          questionnaireVersion == other.questionnaireVersion &&
          mapEquals(answers, other.answers);

  @override
  int get hashCode => Object.hash(questionnaireVersion, Object.hashAll(answers.entries));

  /// Redacted diagnostics: answers are masked to protect user privacy.
  @override
  String toString() =>
      'PersonalityAnswerDraft(version: $questionnaireVersion, answeredCount: ${answers.length})';
}
