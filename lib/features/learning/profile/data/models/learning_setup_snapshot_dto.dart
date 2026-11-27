import 'package:flutter/foundation.dart';

/// DTO representing an individual learning goal item in setup.
@immutable
class LearningGoalItemDto {
  final String goalId;
  final String text;

  const LearningGoalItemDto({
    required this.goalId,
    required this.text,
  });

  factory LearningGoalItemDto.fromJson(Map<String, dynamic> json) {
    final id = json['goalId'] ?? json['goal_id'] ?? json['id'];
    final text = json['text'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Missing or invalid goalId');
    }
    if (text is! String) {
      throw const FormatException('Missing or invalid goal text');
    }
    return LearningGoalItemDto(
      goalId: id.trim(),
      text: text.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'goalId': goalId,
        'text': text,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningGoalItemDto &&
          other.goalId == goalId &&
          other.text == text);

  @override
  int get hashCode => Object.hash(goalId, text);
}

/// DTO representing the authoritative snapshot returned by GET /api/v1/learning/setup.
@immutable
class LearningSetupSnapshotDto {
  final String revision;
  final List<String> teachingSkills;
  final List<String> learningSkills;
  final List<LearningGoalItemDto> goals;

  const LearningSetupSnapshotDto({
    required this.revision,
    this.teachingSkills = const [],
    this.learningSkills = const [],
    this.goals = const [],
  });

  factory LearningSetupSnapshotDto.fromJson(Map<String, dynamic> json) {
    final revision = json['revision'];
    if (revision is! String || revision.trim().isEmpty) {
      throw const FormatException('Missing or invalid revision token');
    }

    final teachingList = json['teachingSkills'] ?? json['teaching_skills'];
    final learningList = json['learningSkills'] ?? json['learning_skills'];
    final goalsList = json['goals'];

    final teaching = <String>[];
    if (teachingList is List) {
      for (final item in teachingList) {
        if (item is String && item.trim().isNotEmpty) {
          teaching.add(item.trim());
        }
      }
    }

    final learning = <String>[];
    if (learningList is List) {
      for (final item in learningList) {
        if (item is String && item.trim().isNotEmpty) {
          learning.add(item.trim());
        }
      }
    }

    final parsedGoals = <LearningGoalItemDto>[];
    if (goalsList is List) {
      for (final item in goalsList) {
        if (item is Map<String, dynamic>) {
          parsedGoals.add(LearningGoalItemDto.fromJson(item));
        } else if (item is Map) {
          parsedGoals.add(LearningGoalItemDto.fromJson(
              item.map((k, v) => MapEntry(k.toString(), v))));
        }
      }
    }

    return LearningSetupSnapshotDto(
      revision: revision.trim(),
      teachingSkills: List.unmodifiable(teaching),
      learningSkills: List.unmodifiable(learning),
      goals: List.unmodifiable(parsedGoals),
    );
  }

  Map<String, dynamic> toJson() => {
        'revision': revision,
        'teachingSkills': teachingSkills,
        'learningSkills': learningSkills,
        'goals': goals.map((g) => g.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningSetupSnapshotDto &&
          other.revision == revision &&
          listEquals(other.teachingSkills, teachingSkills) &&
          listEquals(other.learningSkills, learningSkills) &&
          listEquals(other.goals, goals));

  @override
  int get hashCode => Object.hash(
        revision,
        Object.hashAll(teachingSkills),
        Object.hashAll(learningSkills),
        Object.hashAll(goals),
      );
}
