import 'package:flutter/foundation.dart';

/// Role and participation standing of a learner within a Learning Circle (CF-07, LRN-02).
enum CircleMembershipRole {
  /// Not a member of this circle.
  none,

  /// Active participating member of the circle.
  member,

  /// Circle creator and discussion facilitator.
  facilitator;

  /// Whether this standing grants active circle participation.
  bool get isEnrolled =>
      this == CircleMembershipRole.member ||
      this == CircleMembershipRole.facilitator;

  /// Safely parses a string into [CircleMembershipRole].
  static CircleMembershipRole parse(
    String? value, {
    CircleMembershipRole defaultValue = CircleMembershipRole.none,
  }) {
    if (value == null) return defaultValue;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'member':
        return CircleMembershipRole.member;
      case 'facilitator':
      case 'host':
      case 'creator':
        return CircleMembershipRole.facilitator;
      case 'none':
      default:
        return defaultValue;
    }
  }
}

/// Immutable shared collaborative goal scoped to a Learning Circle (DEC-20261120-LRN02-01).
///
/// Follows backend invariants:
/// - Progress is self-reported (0 through 100), never verified achievement or rewards.
/// - Value of 100 is self-reported completion.
/// - Goals are scoped to a specific [circleId].
@immutable
class CircleSharedGoal {
  /// Unique goal identifier.
  final String id;

  /// Parent circle identifier.
  final String circleId;

  /// Goal text description.
  final String text;

  /// Manually reported progress percentage (0..100).
  final int progressPercent;

  /// Constructs an immutable [CircleSharedGoal] with validated progress range.
  CircleSharedGoal({
    required String id,
    required String circleId,
    required String text,
    int progressPercent = 0,
  })  : id = _validateRequired(id, 'id'),
        circleId = _validateRequired(circleId, 'circleId'),
        text = _validateRequired(text, 'text'),
        progressPercent = _validateProgress(progressPercent);

  /// Whether the goal is self-reported as fully completed.
  bool get isCompleted => progressPercent >= 100;

  static String _validateRequired(String value, String fieldName) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
          value, fieldName, '$fieldName cannot be empty.');
    }
    return trimmed;
  }

  static int _validateProgress(int value) {
    if (value < 0 || value > 100) {
      throw ArgumentOutOfRangeException(
        'progressPercent',
        value,
        'Reported progress must be from 0 through 100.',
      );
    }
    return value;
  }

  /// Constructs a [CircleSharedGoal] from serialized JSON.
  factory CircleSharedGoal.fromJson(Map<String, dynamic> json) {
    return CircleSharedGoal(
      id: json['id']?.toString() ?? '',
      circleId: json['circleId']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      progressPercent:
          int.tryParse(json['progressPercent']?.toString() ?? '0') ?? 0,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'circleId': circleId,
        'text': text,
        'progressPercent': progressPercent,
      };

  /// Copies this goal with optional overrides.
  CircleSharedGoal copyWith({
    String? id,
    String? circleId,
    String? text,
    int? progressPercent,
  }) {
    return CircleSharedGoal(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      text: text ?? this.text,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CircleSharedGoal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          circleId == other.circleId &&
          text == other.text &&
          progressPercent == other.progressPercent;

  @override
  int get hashCode => Object.hash(id, circleId, text, progressPercent);

  @override
  String toString() => 'CircleSharedGoal [private identity and text omitted]';
}

/// Out-of-range exception helper matching backend conventions.
class ArgumentOutOfRangeException implements Exception {
  final String paramName;
  final dynamic actualValue;
  final String message;

  const ArgumentOutOfRangeException(
    this.paramName,
    this.actualValue,
    this.message,
  );

  @override
  String toString() =>
      'ArgumentOutOfRangeException: $message (parameter: $paramName, actual: $actualValue)';
}

/// Domain entity representing a collaborative peer-led Learning Circle (CF-07, LRN-02).
///
/// Complies with Learning visual and architecture governance:
/// - Strictly scoped to module 'learning'. Cross-module circles are prohibited.
/// - Uses PII-safe profile IDs and display names. Never exposes internal account IDs.
/// - Unmodifiable goals collection.
/// - Circle capacity limits and detailed ownership transitions remain pending.
@immutable
class LearningCircle {
  /// Canonical module scope identifier.
  static const String moduleScope = 'learning';

  /// Standard disconnected persistence disclaimer notice.
  static const String disconnectedNotice =
      'Remote Groups backend contract pending in OpenAPI v1. Circles operate in local presentation mode.';

  /// Unique circle identifier.
  final String id;

  /// Canonical module (strictly 'learning').
  final String module;

  /// Display name of the circle.
  final String name;

  /// Purpose, focus, or study syllabus description.
  final String description;

  /// Subject category (e.g. Programming, System Design, Algorithms, Data Science).
  final String category;

  /// Profile identifier of the circle facilitator / creator.
  final String facilitatorProfileId;

  /// Public display name of the circle facilitator.
  final String facilitatorDisplayName;

  /// Current number of enrolled members.
  final int memberCount;

  /// Membership role of the viewing user in this circle.
  final CircleMembershipRole membershipRole;

  /// Unmodifiable list of collaborative shared goals.
  final List<CircleSharedGoal> _goals;

  /// Whether the circle is listed in public discovery.
  final bool isDiscoverable;

  /// When the circle was created.
  final DateTime createdAt;

  const LearningCircle._({
    required this.id,
    required this.module,
    required this.name,
    required this.description,
    required this.category,
    required this.facilitatorProfileId,
    required this.facilitatorDisplayName,
    required this.memberCount,
    required this.membershipRole,
    required List<CircleSharedGoal> goals,
    required this.isDiscoverable,
    required this.createdAt,
  }) : _goals = goals;

  /// Factory constructor validating structural domain invariants.
  factory LearningCircle.create({
    required String id,
    String module = moduleScope,
    required String name,
    required String description,
    required String category,
    required String facilitatorProfileId,
    required String facilitatorDisplayName,
    int memberCount = 1,
    CircleMembershipRole membershipRole = CircleMembershipRole.none,
    Iterable<CircleSharedGoal>? goals,
    bool isDiscoverable = true,
    DateTime? createdAt,
  }) {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'A circle ID is required.');
    }
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'A circle name is required.');
    }
    final cleanDesc = description.trim();
    if (cleanDesc.isEmpty) {
      throw ArgumentError.value(
        description,
        'description',
        'A circle description is required.',
      );
    }
    final cleanFacilitatorId = facilitatorProfileId.trim();
    if (cleanFacilitatorId.isEmpty) {
      throw ArgumentError.value(
        facilitatorProfileId,
        'facilitatorProfileId',
        'A facilitator profile ID is required.',
      );
    }
    final cleanFacilitatorName = facilitatorDisplayName.trim();
    if (cleanFacilitatorName.isEmpty) {
      throw ArgumentError.value(
        facilitatorDisplayName,
        'facilitatorDisplayName',
        'A facilitator display name is required.',
      );
    }
    if (memberCount < 0) {
      throw ArgumentError.value(
        memberCount,
        'memberCount',
        'Member count cannot be negative.',
      );
    }

    return LearningCircle._(
      id: cleanId,
      module: module.trim().isEmpty ? moduleScope : module.trim(),
      name: cleanName,
      description: cleanDesc,
      category: category.trim().isEmpty ? 'General' : category.trim(),
      facilitatorProfileId: cleanFacilitatorId,
      facilitatorDisplayName: cleanFacilitatorName,
      memberCount: memberCount,
      membershipRole: membershipRole,
      goals: goals == null
          ? const <CircleSharedGoal>[]
          : List<CircleSharedGoal>.unmodifiable(List.of(goals)),
      isDiscoverable: isDiscoverable,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Unmodifiable list of shared goals for this circle.
  List<CircleSharedGoal> get goals => _goals;

  /// Whether the user can directly join this circle.
  bool get canJoin => membershipRole == CircleMembershipRole.none;

  /// Whether the user is an enrolled member or facilitator.
  bool get isMember => membershipRole.isEnrolled;

  /// Whether the user is the circle facilitator.
  bool get isFacilitator => membershipRole == CircleMembershipRole.facilitator;

  /// Average completion percentage across all shared goals.
  double get averageGoalProgress {
    if (_goals.isEmpty) return 0.0;
    final total = _goals.fold<int>(0, (sum, g) => sum + g.progressPercent);
    return total / _goals.length;
  }

  /// Creates a copy with optional property overrides.
  LearningCircle copyWith({
    String? id,
    String? module,
    String? name,
    String? description,
    String? category,
    String? facilitatorProfileId,
    String? facilitatorDisplayName,
    int? memberCount,
    CircleMembershipRole? membershipRole,
    Iterable<CircleSharedGoal>? goals,
    bool? isDiscoverable,
    DateTime? createdAt,
  }) {
    return LearningCircle._(
      id: id ?? this.id,
      module: module ?? this.module,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      facilitatorProfileId: facilitatorProfileId ?? this.facilitatorProfileId,
      facilitatorDisplayName:
          facilitatorDisplayName ?? this.facilitatorDisplayName,
      memberCount: memberCount ?? this.memberCount,
      membershipRole: membershipRole ?? this.membershipRole,
      goals: goals != null
          ? List<CircleSharedGoal>.unmodifiable(List.of(goals))
          : _goals,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'module': module,
        'name': name,
        'description': description,
        'category': category,
        'facilitatorProfileId': facilitatorProfileId,
        'facilitatorDisplayName': facilitatorDisplayName,
        'memberCount': memberCount,
        'membershipRole': membershipRole.name,
        'goals': _goals.map((g) => g.toJson()).toList(),
        'isDiscoverable': isDiscoverable,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Constructs from JSON.
  factory LearningCircle.fromJson(Map<String, dynamic> json) {
    final parsedGoals = <CircleSharedGoal>[];
    if (json['goals'] is Iterable) {
      for (final item in json['goals'] as Iterable) {
        if (item is Map<String, dynamic>) {
          parsedGoals.add(CircleSharedGoal.fromJson(item));
        }
      }
    }

    return LearningCircle.create(
      id: json['id']?.toString() ?? '',
      module: json['module']?.toString() ?? moduleScope,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      facilitatorProfileId: json['facilitatorProfileId']?.toString() ?? '',
      facilitatorDisplayName: json['facilitatorDisplayName']?.toString() ?? '',
      memberCount: int.tryParse(json['memberCount']?.toString() ?? '1') ?? 1,
      membershipRole:
          CircleMembershipRole.parse(json['membershipRole']?.toString()),
      goals: parsedGoals,
      isDiscoverable: json['isDiscoverable'] != false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningCircle &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          module == other.module &&
          name == other.name &&
          description == other.description &&
          category == other.category &&
          facilitatorProfileId == other.facilitatorProfileId &&
          facilitatorDisplayName == other.facilitatorDisplayName &&
          memberCount == other.memberCount &&
          membershipRole == other.membershipRole &&
          isDiscoverable == other.isDiscoverable &&
          listEquals(_goals, other._goals);

  @override
  int get hashCode => Object.hash(
        id,
        module,
        name,
        description,
        category,
        facilitatorProfileId,
        facilitatorDisplayName,
        memberCount,
        membershipRole,
        isDiscoverable,
        Object.hashAll(_goals),
      );

  @override
  String toString() => 'Learning Circle [private identity and goals omitted]';

  /// Predefined baseline samples for presentation and widget testing.
  static List<LearningCircle> get sampleCircles => [
        LearningCircle.create(
          id: 'circle_01',
          name: 'Mobile Architecture Circle',
          description:
              'Weekly peer study group analyzing clean architecture, MVVM, and offline sync patterns in Flutter.',
          category: 'Programming',
          facilitatorProfileId: 'prof_fac_01',
          facilitatorDisplayName: 'Kavitha Dev',
          memberCount: 5,
          membershipRole: CircleMembershipRole.none,
          goals: [
            CircleSharedGoal(
              id: 'goal_01',
              circleId: 'circle_01',
              text: 'Complete Clean Architecture module refactoring',
              progressPercent: 75,
            ),
            CircleSharedGoal(
              id: 'goal_02',
              circleId: 'circle_01',
              text: 'Implement repository caching & offline boundaries',
              progressPercent: 40,
            ),
          ],
        ),
        LearningCircle.create(
          id: 'circle_02',
          name: 'Algorithms & LeetCode Study',
          description:
              'Daily problem solving and peer algorithm explanations covering dynamic programming and trees.',
          category: 'Algorithms',
          facilitatorProfileId: 'prof_fac_02',
          facilitatorDisplayName: 'Rohan Sharma',
          memberCount: 8,
          membershipRole: CircleMembershipRole.member,
          goals: [
            CircleSharedGoal(
              id: 'goal_03',
              circleId: 'circle_02',
              text: 'Solve 20 Dynamic Programming challenges',
              progressPercent: 60,
            ),
          ],
        ),
        LearningCircle.create(
          id: 'circle_03',
          name: 'UI/UX Design Systems Circle',
          description:
              'Designers and frontend engineers collaborating on accessible tokens, typography, and atomic components.',
          category: 'Design',
          facilitatorProfileId: 'prof_fac_03',
          facilitatorDisplayName: 'Sara Lin',
          memberCount: 4,
          membershipRole: CircleMembershipRole.facilitator,
          goals: [
            CircleSharedGoal(
              id: 'goal_04',
              circleId: 'circle_03',
              text: 'Audit WCAG 2.1 AA color contrasts across all flows',
              progressPercent: 100,
            ),
          ],
        ),
      ];
}
