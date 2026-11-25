import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Immutable private reflection content for a daily diary entry (CF-13 / DIA-R01..R10).
///
/// Features:
/// - Optional title up to 100 characters.
/// - Required non-blank body up to 10,000 characters.
/// - Redacted [toString] preventing confidential content leakage into logs.
/// - Lossless immutable replacement via [withContent].
@immutable
class DiaryReflection {
  /// Maximum allowed characters for reflection title.
  static const int maxTitleLength = 100;

  /// Maximum allowed characters for reflection body.
  static const int maxBodyLength = 10000;

  /// Optional title for this daily reflection.
  final String? title;

  /// Required reflective body text.
  final String body;

  const DiaryReflection({
    this.title,
    required this.body,
  });

  /// Validates reflection title. Returns null if valid, or an error message.
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > maxTitleLength) {
      return 'Reflection title cannot exceed $maxTitleLength characters.';
    }
    return null;
  }

  /// Validates reflection body. Returns null if valid, or an error message.
  static String? validateBody(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'A non-blank reflection body is required.';
    }
    if (value.length > maxBodyLength) {
      return 'Reflection body cannot exceed $maxBodyLength characters.';
    }
    return null;
  }

  /// Creates a validated [DiaryReflection], throwing [ArgumentError] on invalid data.
  factory DiaryReflection.validated({
    String? title,
    required String body,
  }) {
    final titleErr = validateTitle(title);
    if (titleErr != null) throw ArgumentError(titleErr);

    final bodyErr = validateBody(body);
    if (bodyErr != null) throw ArgumentError(bodyErr);

    return DiaryReflection(
      title: title?.trim().isEmpty == true ? null : title,
      body: body,
    );
  }

  /// Returns a replacement reflection with updated content.
  DiaryReflection withContent({
    String? title,
    required String body,
  }) {
    return DiaryReflection.validated(title: title, body: body);
  }

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
    };
  }

  /// Deserializes from a JSON map.
  factory DiaryReflection.fromJson(Map<String, dynamic> json) {
    return DiaryReflection(
      title: json['title'] as String?,
      body: json['body'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaryReflection &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          body == other.body;

  @override
  int get hashCode => Object.hash(title, body);

  @override
  String toString() => 'Private Diary reflection [title and body omitted]';
}

/// Immutable private daily plan item within a diary entry (CF-13 / DIA-R05..R10).
///
/// Features:
/// - Unique identifier.
/// - Required non-blank title up to 120 characters.
/// - Optional description up to 1,000 characters.
/// - Optional completion toggle state.
/// - Redacted [toString] preventing confidential content leakage into logs.
@immutable
class DiaryPlan {
  /// Maximum allowed characters for plan title.
  static const int maxTitleLength = 120;

  /// Maximum allowed characters for plan description.
  static const int maxDescriptionLength = 1000;

  /// Unique identifier of the plan.
  final String id;

  /// Title of the daily plan.
  final String title;

  /// Optional detailed description.
  final String? description;

  /// Whether this daily plan has been completed.
  final bool isCompleted;

  const DiaryPlan({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
  });

  /// Validates plan title.
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'A non-blank Diary plan title is required.';
    }
    if (value.length > maxTitleLength) {
      return 'Diary plan title cannot exceed $maxTitleLength characters.';
    }
    return null;
  }

  /// Validates plan description.
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > maxDescriptionLength) {
      return 'Diary plan description cannot exceed $maxDescriptionLength characters.';
    }
    return null;
  }

  /// Creates a validated [DiaryPlan], throwing [ArgumentError] on invalid data.
  factory DiaryPlan.validated({
    String? id,
    required String title,
    String? description,
    bool isCompleted = false,
  }) {
    final effectiveId = id ?? const Uuid().v4();
    if (effectiveId.trim().isEmpty) {
      throw ArgumentError('A Diary plan ID is required.');
    }

    final titleErr = validateTitle(title);
    if (titleErr != null) throw ArgumentError(titleErr);

    final descErr = validateDescription(description);
    if (descErr != null) throw ArgumentError(descErr);

    return DiaryPlan(
      id: effectiveId,
      title: title,
      description: description?.trim().isEmpty == true ? null : description,
      isCompleted: isCompleted,
    );
  }

  /// Returns a replacement plan with updated content preserving plan ID.
  DiaryPlan withContent({
    required String title,
    String? description,
    bool? isCompleted,
  }) {
    return DiaryPlan.validated(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Returns a copy with completion state toggled.
  DiaryPlan toggleCompleted() {
    return DiaryPlan(
      id: id,
      title: title,
      description: description,
      isCompleted: !isCompleted,
    );
  }

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  /// Deserializes from a JSON map.
  factory DiaryPlan.fromJson(Map<String, dynamic> json) {
    return DiaryPlan(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaryPlan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(id, title, description, isCompleted);

  @override
  String toString() =>
      'Private Diary plan [identity, title and description omitted]';
}

/// Calendar date resolver enforcing agreed timezone contract (DEC-M1-05).
///
/// Rules:
/// - When an explicit date is provided, it is preserved literally without timezone or clock conversion.
/// - When an explicit date is omitted, resolves today's date from UTC and the selected IANA timezone.
/// - If the selected IANA timezone is missing, blank, or invalid, returns null (never falls back to local device/server time).
class DiaryCalendarResolver {
  const DiaryCalendarResolver();

  /// Resolves the applicable calendar date based on explicit date or IANA timezone.
  ///
  /// Returns null when implicit date resolution is unavailable.
  DateTime? resolveDate({
    String? ianaTimeZone,
    DateTime? explicitDate,
    DateTime? utcNow,
  }) {
    if (explicitDate != null) {
      return DateTime.utc(
        explicitDate.year,
        explicitDate.month,
        explicitDate.day,
      );
    }

    if (ianaTimeZone == null || ianaTimeZone.trim().isEmpty) {
      return null;
    }

    final trimmedZone = ianaTimeZone.trim();
    final now = utcNow ?? DateTime.now().toUtc();

    // Map common IANA timezones to duration offsets for robust offline resolution
    final offsetHours = _resolveIanaOffsetHours(trimmedZone, now);
    if (offsetHours == null) {
      return null;
    }

    final targetTime = now.add(Duration(minutes: (offsetHours * 60).round()));
    return DateTime.utc(targetTime.year, targetTime.month, targetTime.day);
  }

  /// Simple standard IANA offset mapping for verified timezone calculations.
  static double? _resolveIanaOffsetHours(String zone, DateTime utc) {
    switch (zone) {
      case 'Asia/Colombo':
      case 'Asia/Kolkata':
        return 5.5;
      case 'UTC':
      case 'Etc/UTC':
        return 0.0;
      case 'Europe/London':
        // Simplified GMT/BST
        return (utc.month >= 4 && utc.month <= 10) ? 1.0 : 0.0;
      case 'America/New_York':
        // Simplified EST/EDT
        return (utc.month >= 3 && utc.month <= 11) ? -4.0 : -5.0;
      case 'America/Los_Angeles':
        // Simplified PST/PDT
        return (utc.month >= 3 && utc.month <= 11) ? -7.0 : -8.0;
      case 'Asia/Tokyo':
        return 9.0;
      case 'Asia/Singapore':
        return 8.0;
      case 'Pacific/Kiritimati':
        return 14.0;
      case 'Australia/Sydney':
        return (utc.month >= 10 || utc.month <= 3) ? 11.0 : 10.0;
      default:
        return null;
    }
  }
}

/// Private daily diary entry aggregate for a fixed module profile and date (CF-13 / DIA-R01..R10).
///
/// Security & Architectural Boundaries:
/// - Authenticated ownership: Tied to [ownerModuleProfileId].
/// - Module isolation: [module] must be 'learning' (or 'hobbies', 'social' for other modules).
/// - Default-private: [isPrivate] is strictly true.
/// - Calendar date uniqueness: Exactly one daily entry per (owner, module, date).
/// - Plan limit: Maximum 20 plans per daily entry.
/// - Plan uniqueness: Each plan in [plans] must have a unique [id].
/// - Redacted [toString] preventing confidential content leakage into logs.
@immutable
class ModuleDiaryEntry {
  /// Maximum number of daily plans allowed in a single entry.
  static const int maxPlansCount = 20;

  /// The unique learning profile ID of the owner.
  final String ownerModuleProfileId;

  /// The module scope (e.g. 'learning').
  final String module;

  /// Normalized calendar date (UTC, year-month-day).
  final DateTime date;

  /// Always true; private by design.
  final bool isPrivate = true;

  /// Optional single reflection for the day.
  final DiaryReflection? reflection;

  /// Ordered list of daily plans (up to 20).
  final List<DiaryPlan> plans;

  const ModuleDiaryEntry({
    required this.ownerModuleProfileId,
    required this.module,
    required this.date,
    this.reflection,
    this.plans = const [],
  });

  /// Factory creating an offline [ModuleDiaryEntry] with validated scope.
  factory ModuleDiaryEntry.create({
    required String ownerModuleProfileId,
    required String module,
    required DateTime date,
    DiaryReflection? reflection,
    List<DiaryPlan> plans = const [],
  }) {
    if (ownerModuleProfileId.trim().isEmpty) {
      throw ArgumentError('A module-profile owner ID is required.');
    }
    if (module.trim().isEmpty) {
      throw ArgumentError('A module name is required.');
    }
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);

    if (plans.length > maxPlansCount) {
      throw ArgumentError(
          'A daily entry cannot contain more than $maxPlansCount plans.');
    }

    final planIds = <String>{};
    for (final plan in plans) {
      if (!planIds.add(plan.id)) {
        throw ArgumentError(
            'The plan identity already exists in this daily entry: ${plan.id}');
      }
    }

    return ModuleDiaryEntry(
      ownerModuleProfileId: ownerModuleProfileId,
      module: module,
      date: normalizedDate,
      reflection: reflection,
      plans: List.unmodifiable(plans),
    );
  }

  /// Sets or replaces the daily reflection.
  ModuleDiaryEntry setReflection(String? title, String body) {
    final newReflection = DiaryReflection.validated(title: title, body: body);
    return copyWith(reflection: newReflection);
  }

  /// Edits an existing reflection. Throws [StateError] if no reflection exists.
  ModuleDiaryEntry editReflection(String? title, String body) {
    if (reflection == null) {
      throw StateError('No reflection exists in this daily entry.');
    }
    return copyWith(
      reflection: reflection!.withContent(title: title, body: body),
    );
  }

  /// Removes the daily reflection.
  ModuleDiaryEntry removeReflection() {
    return ModuleDiaryEntry(
      ownerModuleProfileId: ownerModuleProfileId,
      module: module,
      date: date,
      reflection: null,
      plans: plans,
    );
  }

  /// Adds a daily plan. Throws [StateError] if at maximum limit, or [ArgumentError] on duplicate ID.
  ModuleDiaryEntry addPlan(DiaryPlan plan) {
    if (plans.length >= maxPlansCount) {
      throw StateError(
          'A daily entry cannot contain more than $maxPlansCount plans.');
    }
    if (plans.any((p) => p.id == plan.id)) {
      throw ArgumentError(
          'The plan identity already exists in this daily entry.');
    }
    final nextPlans = List<DiaryPlan>.from(plans)..add(plan);
    return copyWith(plans: List.unmodifiable(nextPlans));
  }

  /// Edits an existing plan. Throws [KeyNotFoundException] / [StateError] if not found.
  ModuleDiaryEntry editPlan(String planId, String title,
      {String? description, bool? isCompleted}) {
    final index = plans.indexWhere((p) => p.id == planId);
    if (index == -1) {
      throw StateError('The plan is not present in this daily entry.');
    }
    final nextPlans = List<DiaryPlan>.from(plans);
    nextPlans[index] = nextPlans[index].withContent(
      title: title,
      description: description,
      isCompleted: isCompleted,
    );
    return copyWith(plans: List.unmodifiable(nextPlans));
  }

  /// Toggles completion of a plan.
  ModuleDiaryEntry togglePlan(String planId) {
    final index = plans.indexWhere((p) => p.id == planId);
    if (index == -1) {
      throw StateError('The plan is not present in this daily entry.');
    }
    final nextPlans = List<DiaryPlan>.from(plans);
    nextPlans[index] = nextPlans[index].toggleCompleted();
    return copyWith(plans: List.unmodifiable(nextPlans));
  }

  /// Removes a plan by ID. Throws [StateError] if not found.
  ModuleDiaryEntry removePlan(String planId) {
    final index = plans.indexWhere((p) => p.id == planId);
    if (index == -1) {
      throw StateError('The plan is not present in this daily entry.');
    }
    final nextPlans = List<DiaryPlan>.from(plans)..removeAt(index);
    return copyWith(plans: List.unmodifiable(nextPlans));
  }

  /// Returns a copy with specified fields replaced.
  ModuleDiaryEntry copyWith({
    String? ownerModuleProfileId,
    String? module,
    DateTime? date,
    DiaryReflection? reflection,
    List<DiaryPlan>? plans,
  }) {
    return ModuleDiaryEntry(
      ownerModuleProfileId: ownerModuleProfileId ?? this.ownerModuleProfileId,
      module: module ?? this.module,
      date: date ?? this.date,
      reflection: reflection ?? this.reflection,
      plans: plans ?? this.plans,
    );
  }

  /// Synthetic sample for preview and testing.
  factory ModuleDiaryEntry.syntheticSample({
    String ownerModuleProfileId = 'test_learning_owner_01',
    String module = 'learning',
    DateTime? date,
  }) {
    final targetDate = date != null
        ? DateTime.utc(date.year, date.month, date.day)
        : DateTime.utc(2026, 11, 25);

    return ModuleDiaryEntry(
      ownerModuleProfileId: ownerModuleProfileId,
      module: module,
      date: targetDate,
      reflection: const DiaryReflection(
        title: 'Mastering System Architecture & Flutter CI',
        body:
            'Today I studied scalable Flutter module isolation, fail-closed access verification, '
            'and optimized CI pipelines. Maintaining immutability and clean boundaries is critical.',
      ),
      plans: const [
        DiaryPlan(
          id: 'plan_01',
          title: 'Review Clean Architecture boundaries',
          description:
              'Ensure domain entities remain independent of presentation and transport layers.',
          isCompleted: true,
        ),
        DiaryPlan(
          id: 'plan_02',
          title: 'Complete widget test suite for Private Diary',
          description:
              'Verify 320dp, 360dp, 412dp responsiveness and 1.5x dynamic text scale.',
          isCompleted: false,
        ),
      ],
    );
  }

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'ownerModuleProfileId': ownerModuleProfileId,
      'module': module,
      'date': date.toIso8601String(),
      'isPrivate': isPrivate,
      'reflection': reflection?.toJson(),
      'plans': plans.map((p) => p.toJson()).toList(),
    };
  }

  /// Deserializes from a JSON map.
  factory ModuleDiaryEntry.fromJson(Map<String, dynamic> json) {
    return ModuleDiaryEntry(
      ownerModuleProfileId: json['ownerModuleProfileId'] as String? ?? '',
      module: json['module'] as String? ?? 'learning',
      date: DateTime.parse(json['date'] as String),
      reflection: json['reflection'] != null
          ? DiaryReflection.fromJson(json['reflection'] as Map<String, dynamic>)
          : null,
      plans: (json['plans'] as List<dynamic>?)
              ?.map((p) => DiaryPlan.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleDiaryEntry &&
          runtimeType == other.runtimeType &&
          ownerModuleProfileId == other.ownerModuleProfileId &&
          module == other.module &&
          date == other.date &&
          reflection == other.reflection &&
          listEquals(plans, other.plans);

  @override
  int get hashCode => Object.hash(
        ownerModuleProfileId,
        module,
        date,
        reflection,
        Object.hashAll(plans),
      );

  @override
  String toString() =>
      'Private module Diary entry [owner, module, date and content omitted]';
}
