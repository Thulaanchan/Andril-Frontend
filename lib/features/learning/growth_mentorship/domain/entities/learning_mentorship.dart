import 'package:flutter/foundation.dart';

/// Status of a voluntary Learning Mentorship engagement (DEC-20261120-LRN04-01).
enum LearningMentorshipStatus {
  pending,
  accepted,
  declined,
  cancelled;

  bool get isPending => this == LearningMentorshipStatus.pending;
  bool get isAccepted => this == LearningMentorshipStatus.accepted;
  bool get isDeclined => this == LearningMentorshipStatus.declined;
  bool get isCancelled => this == LearningMentorshipStatus.cancelled;

  static LearningMentorshipStatus parse(
    String? value, {
    LearningMentorshipStatus defaultValue = LearningMentorshipStatus.pending,
  }) {
    if (value == null) return defaultValue;
    switch (value.trim().toLowerCase()) {
      case 'accepted':
      case 'active':
        return LearningMentorshipStatus.accepted;
      case 'declined':
        return LearningMentorshipStatus.declined;
      case 'cancelled':
      case 'canceled':
        return LearningMentorshipStatus.cancelled;
      case 'pending':
      default:
        return defaultValue;
    }
  }
}

/// Participant references in a voluntary Learning Mentorship (DEC-20261120-LRN04-01).
///
/// Follows fail-closed governance:
/// - Internal account and Learning-profile references only.
/// - Redacted [toString] prevents PII leakage in logs.
@immutable
class LearningMentorshipParticipant {
  final String accountId;
  final String learningProfileId;
  final String displayName;
  final String? avatarUrl;

  LearningMentorshipParticipant({
    required String accountId,
    required String learningProfileId,
    required String displayName,
    this.avatarUrl,
  })  : accountId = _validateRequired(accountId, 'accountId'),
        learningProfileId =
            _validateRequired(learningProfileId, 'learningProfileId'),
        displayName = _validateRequired(displayName, 'displayName');

  static String _validateRequired(String value, String fieldName) {
    final clean = value.trim();
    if (clean.isEmpty) {
      throw ArgumentError.value(
          value, fieldName, '$fieldName cannot be empty.');
    }
    return clean;
  }

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'learningProfileId': learningProfileId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
      };

  factory LearningMentorshipParticipant.fromJson(Map<String, dynamic> json) {
    return LearningMentorshipParticipant(
      accountId: json['accountId']?.toString() ?? '',
      learningProfileId: json['learningProfileId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningMentorshipParticipant &&
          runtimeType == other.runtimeType &&
          accountId == other.accountId &&
          learningProfileId == other.learningProfileId;

  @override
  int get hashCode => Object.hash(accountId, learningProfileId);

  @override
  String toString() =>
      'LearningMentorshipParticipant [private references omitted]';
}

/// Immutable declaration of voluntary offering intent by a mentor (DEC-20261120-LRN04-01).
///
/// Not evidence of authentication, mentor eligibility, experience, or credentials.
@immutable
class LearningMentorshipOffer {
  static const String moduleScope = 'learning';

  final String id;
  final String module;
  final LearningMentorshipParticipant mentor;
  final List<String> specialtyTopics;
  final bool isAvailable;

  LearningMentorshipOffer({
    required String id,
    String module = moduleScope,
    required this.mentor,
    Iterable<String>? specialtyTopics,
    this.isAvailable = true,
  })  : id = _validateRequired(id, 'id'),
        module = _validateModule(module),
        specialtyTopics = List<String>.unmodifiable(
          specialtyTopics?.map((s) => s.trim()).where((s) => s.isNotEmpty) ??
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

  static String _validateModule(String module) {
    final clean = module.trim();
    if (clean.isNotEmpty && clean != moduleScope) {
      throw ArgumentError.value(
        module,
        'module',
        'Mentorship offer module must strictly be "$moduleScope".',
      );
    }
    return moduleScope;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'module': module,
        'mentor': mentor.toJson(),
        'specialtyTopics': specialtyTopics,
        'isAvailable': isAvailable,
      };

  factory LearningMentorshipOffer.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['specialtyTopics'];
    final parsedTopics = <String>[];
    if (rawTopics is Iterable) {
      for (final item in rawTopics) {
        if (item != null && item.toString().trim().isNotEmpty) {
          parsedTopics.add(item.toString().trim());
        }
      }
    }

    return LearningMentorshipOffer(
      id: json['id']?.toString() ?? '',
      module: json['module']?.toString() ?? moduleScope,
      mentor: LearningMentorshipParticipant.fromJson(
        json['mentor'] as Map<String, dynamic>? ?? const {},
      ),
      specialtyTopics: parsedTopics,
      isAvailable: json['isAvailable'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningMentorshipOffer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          mentor == other.mentor;

  @override
  int get hashCode => Object.hash(id, mentor);

  @override
  String toString() => 'LearningMentorshipOffer [private references omitted]';
}

/// Mutual voluntary Learning Mentorship engagement record (DEC-20261120-LRN04-01).
///
/// Follows strict ANDRIL M1 governance:
/// - Rejects self-mentorship or shared participant accounts.
/// - Mutually agreed: activation occurs ONLY upon mentor acceptance.
/// - Does NOT grant automatic chat, connection, or XP rewards.
/// - Redacted [toString] prevents PII leakage in diagnostic logs.
@immutable
class LearningMentorship {
  static const String moduleScope = 'learning';

  final String id;
  final String module;
  final LearningMentorshipParticipant learner;
  final LearningMentorshipOffer offer;
  final String learningGoal;
  final String message;
  final LearningMentorshipStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LearningMentorshipParticipant get mentor => offer.mentor;

  bool get isActive => status == LearningMentorshipStatus.accepted;

  LearningMentorship({
    required String id,
    String module = moduleScope,
    required this.learner,
    required this.offer,
    required String learningGoal,
    required String message,
    this.status = LearningMentorshipStatus.pending,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = _validateRequired(id, 'id'),
        module = _validateModule(module),
        learningGoal = _validateRequired(learningGoal, 'learningGoal'),
        message = _validateRequired(message, 'message'),
        createdAt = createdAt ?? DateTime.now() {
    _validateDistinctParticipants(learner, offer.mentor);
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
        'Mentorship module must strictly be "$moduleScope".',
      );
    }
    return moduleScope;
  }

  static void _validateDistinctParticipants(
    LearningMentorshipParticipant learner,
    LearningMentorshipParticipant mentor,
  ) {
    if (learner.accountId == mentor.accountId ||
        learner.learningProfileId == mentor.learningProfileId) {
      throw ArgumentError(
        'Self-mentorship or a shared participant profile is not permitted.',
      );
    }
  }

  /// Factory creating a learner-initiated voluntary mentorship request.
  factory LearningMentorship.request({
    required String id,
    required LearningMentorshipParticipant learner,
    required LearningMentorshipOffer offer,
    required String learningGoal,
    required String message,
    DateTime? createdAt,
  }) {
    return LearningMentorship(
      id: id,
      learner: learner,
      offer: offer,
      learningGoal: learningGoal,
      message: message,
      status: LearningMentorshipStatus.pending,
      createdAt: createdAt,
    );
  }

  /// Transitions mentorship to accepted state (mentor authorization required).
  LearningMentorship accept(LearningMentorshipParticipant participant) {
    if (participant != mentor) {
      throw StateError(
          'Only the designated mentor can accept a mentorship request.');
    }
    if (status != LearningMentorshipStatus.pending) {
      throw StateError('Only pending mentorship requests can be accepted.');
    }
    return copyWith(
      status: LearningMentorshipStatus.accepted,
      updatedAt: DateTime.now(),
    );
  }

  /// Transitions mentorship to declined state (mentor authorization required).
  LearningMentorship decline(LearningMentorshipParticipant participant) {
    if (participant != mentor) {
      throw StateError(
          'Only the designated mentor can decline a mentorship request.');
    }
    if (status != LearningMentorshipStatus.pending) {
      throw StateError('Only pending mentorship requests can be declined.');
    }
    return copyWith(
      status: LearningMentorshipStatus.declined,
      updatedAt: DateTime.now(),
    );
  }

  /// Transitions mentorship to cancelled state (learner authorization required).
  LearningMentorship cancel(LearningMentorshipParticipant participant) {
    if (participant != learner) {
      throw StateError(
          'Only the initiating learner can cancel a mentorship request.');
    }
    if (status != LearningMentorshipStatus.pending) {
      throw StateError('Only pending mentorship requests can be cancelled.');
    }
    return copyWith(
      status: LearningMentorshipStatus.cancelled,
      updatedAt: DateTime.now(),
    );
  }

  LearningMentorship copyWith({
    String? id,
    String? module,
    LearningMentorshipParticipant? learner,
    LearningMentorshipOffer? offer,
    String? learningGoal,
    String? message,
    LearningMentorshipStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearningMentorship(
      id: id ?? this.id,
      module: module ?? this.module,
      learner: learner ?? this.learner,
      offer: offer ?? this.offer,
      learningGoal: learningGoal ?? this.learningGoal,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'module': module,
        'learner': learner.toJson(),
        'offer': offer.toJson(),
        'learningGoal': learningGoal,
        'message': message,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory LearningMentorship.fromJson(Map<String, dynamic> json) {
    return LearningMentorship(
      id: json['id']?.toString() ?? '',
      module: json['module']?.toString() ?? moduleScope,
      learner: LearningMentorshipParticipant.fromJson(
        json['learner'] as Map<String, dynamic>? ?? const {},
      ),
      offer: LearningMentorshipOffer.fromJson(
        json['offer'] as Map<String, dynamic>? ?? const {},
      ),
      learningGoal: json['learningGoal']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: LearningMentorshipStatus.parse(json['status']?.toString()),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningMentorship &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          learner == other.learner &&
          offer == other.offer &&
          learningGoal == other.learningGoal &&
          message == other.message &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
        id,
        learner,
        offer,
        learningGoal,
        message,
        status,
      );

  @override
  String toString() =>
      'LearningMentorship (${status.name}) [private references omitted]';
}
