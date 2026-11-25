import 'package:flutter/foundation.dart';

/// Classroom privacy and admission rule matching CF-06 / CF-07.
enum ClassroomPrivacy {
  /// Open to all learners; instant enrollment.
  public,

  /// Admission requires educator or host approval via join request.
  requestToJoin,

  /// Private or invitation-only; not open to unsolicited requests.
  closed,
}

/// Membership standing for a viewing Learning profile.
enum ClassroomMembershipStatus {
  /// Not enrolled and no active pending request.
  none,

  /// Join request submitted; awaiting host decision.
  pending,

  /// Confirmed enrolled learner in the classroom.
  member,

  /// Educator or moderator host who manages the classroom.
  host,
}

/// Domain entity representing a classroom in the Learning module.
///
/// Follows CF-06 / CF-07 (BRD v2.4-R1, pages 7 and 15) and M5 group integration boundaries.
/// Strictly scoped to module 'learning' with fail-closed privacy.
@immutable
class LearningClassroom {
  /// Canonical module scope identifier.
  static const String moduleScope = 'learning';

  /// Standard disconnected persistence disclaimer notice.
  static const String disconnectedNotice =
      'Remote Groups backend contract pending in OpenAPI v1. Classrooms operate in local presentation mode.';

  /// Unique classroom identifier.
  final String id;

  /// Module identifier (strictly 'learning').
  final String module;

  /// Display name of the classroom.
  final String name;

  /// Curriculum description or learning objectives.
  final String description;

  /// Subject category (e.g. Programming, Design, Languages, Business).
  final String category;

  /// Privacy and admission model.
  final ClassroomPrivacy privacy;

  /// Current number of enrolled members.
  final int memberCount;

  /// Optional maximum learner capacity.
  final int? capacity;

  /// Profile identifier of the educator/host.
  final String hostProfileId;

  /// Display name of the educator/host (PII-safe display name).
  final String hostDisplayName;

  /// Membership standing of the current viewing profile.
  final ClassroomMembershipStatus membershipStatus;

  /// Associated topic tags.
  final List<String> tags;

  /// Whether the classroom appears in public discovery.
  final bool isDiscoverable;

  /// When the classroom was created.
  final DateTime createdAt;

  const LearningClassroom._({
    required this.id,
    required this.module,
    required this.name,
    required this.description,
    required this.category,
    required this.privacy,
    required this.memberCount,
    this.capacity,
    required this.hostProfileId,
    required this.hostDisplayName,
    required this.membershipStatus,
    required this.tags,
    required this.isDiscoverable,
    required this.createdAt,
  });

  /// Factory constructor to instantiate a validated [LearningClassroom].
  ///
  /// Enforces structural invariants:
  /// - [id] non-empty.
  /// - [name] non-empty.
  /// - [description] non-empty.
  /// - [hostProfileId] non-empty.
  /// - [hostDisplayName] non-empty.
  /// - [memberCount] >= 0.
  /// - [capacity] if provided must be >= [memberCount] and > 0.
  factory LearningClassroom.create({
    required String id,
    required String name,
    required String description,
    required String category,
    ClassroomPrivacy privacy = ClassroomPrivacy.public,
    int memberCount = 0,
    int? capacity,
    required String hostProfileId,
    required String hostDisplayName,
    ClassroomMembershipStatus membershipStatus = ClassroomMembershipStatus.none,
    List<String> tags = const [],
    bool isDiscoverable = true,
    DateTime? createdAt,
  }) {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'A classroom ID is required.');
    }
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'A classroom name is required.');
    }
    final cleanDesc = description.trim();
    if (cleanDesc.isEmpty) {
      throw ArgumentError.value(
        description,
        'description',
        'A classroom description is required.',
      );
    }
    final cleanHostId = hostProfileId.trim();
    if (cleanHostId.isEmpty) {
      throw ArgumentError.value(
        hostProfileId,
        'hostProfileId',
        'A host profile ID is required.',
      );
    }
    final cleanHostName = hostDisplayName.trim();
    if (cleanHostName.isEmpty) {
      throw ArgumentError.value(
        hostDisplayName,
        'hostDisplayName',
        'A host display name is required.',
      );
    }
    if (memberCount < 0) {
      throw ArgumentError.value(
        memberCount,
        'memberCount',
        'Member count cannot be negative.',
      );
    }
    if (capacity != null && capacity <= 0) {
      throw ArgumentError.value(
        capacity,
        'capacity',
        'Capacity must be greater than zero.',
      );
    }
    if (capacity != null && memberCount > capacity) {
      throw ArgumentError.value(
        memberCount,
        'memberCount',
        'Member count cannot exceed capacity.',
      );
    }

    return LearningClassroom._(
      id: cleanId,
      module: moduleScope,
      name: cleanName,
      description: cleanDesc,
      category: category.trim().isEmpty ? 'General' : category.trim(),
      privacy: privacy,
      memberCount: memberCount,
      capacity: capacity,
      hostProfileId: cleanHostId,
      hostDisplayName: cleanHostName,
      membershipStatus: membershipStatus,
      tags: List.unmodifiable(
          tags.map((t) => t.trim()).where((t) => t.isNotEmpty)),
      isDiscoverable: isDiscoverable,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Whether a learner can join directly without waiting for approval.
  bool get canJoinDirectly =>
      privacy == ClassroomPrivacy.public &&
      membershipStatus == ClassroomMembershipStatus.none;

  /// Whether a learner must submit a join request.
  bool get canRequestToJoin =>
      privacy == ClassroomPrivacy.requestToJoin &&
      membershipStatus == ClassroomMembershipStatus.none;

  /// Whether the user is an enrolled participant (member or host).
  bool get isEnrolled =>
      membershipStatus == ClassroomMembershipStatus.member ||
      membershipStatus == ClassroomMembershipStatus.host;

  /// Whether a join request has been submitted and is awaiting decision.
  bool get isPending => membershipStatus == ClassroomMembershipStatus.pending;

  /// Creates a copy of this classroom with optional property overrides.
  LearningClassroom copyWith({
    String? name,
    String? description,
    String? category,
    ClassroomPrivacy? privacy,
    int? memberCount,
    int? capacity,
    String? hostDisplayName,
    ClassroomMembershipStatus? membershipStatus,
    List<String>? tags,
    bool? isDiscoverable,
  }) {
    return LearningClassroom.create(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      privacy: privacy ?? this.privacy,
      memberCount: memberCount ?? this.memberCount,
      capacity: capacity ?? this.capacity,
      hostProfileId: hostProfileId,
      hostDisplayName: hostDisplayName ?? this.hostDisplayName,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      tags: tags ?? this.tags,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningClassroom &&
        other.id == id &&
        other.module == module &&
        other.name == name &&
        other.privacy == privacy &&
        other.memberCount == memberCount &&
        other.membershipStatus == membershipStatus;
  }

  @override
  int get hashCode =>
      Object.hash(id, module, name, privacy, memberCount, membershipStatus);

  @override
  String toString() {
    // Redact internal ID and sensitive data in diagnostic logs.
    return 'LearningClassroom(name: $name, privacy: $privacy, members: $memberCount, status: $membershipStatus)';
  }

  /// Curated sample classrooms across categories for local presentation.
  static List<LearningClassroom> get sampleClassrooms => [
        LearningClassroom.create(
          id: 'cls_flutter_mastery_01',
          name: 'Flutter & Dart Mastery',
          description:
              'Hands-on interactive classroom covering advanced state management, animations, and Clean Architecture for cross-platform apps.',
          category: 'Programming',
          privacy: ClassroomPrivacy.public,
          memberCount: 42,
          capacity: 100,
          hostProfileId: 'prof_mentor_sarah',
          hostDisplayName: 'Sarah Chen, GDE',
          membershipStatus: ClassroomMembershipStatus.none,
          tags: ['Flutter', 'Dart', 'Architecture'],
        ),
        LearningClassroom.create(
          id: 'cls_uiux_design_02',
          name: 'UI/UX Design Systems Workshop',
          description:
              'Design token architectures, responsive design grids, and accessible components in Figma and Flutter.',
          category: 'Design',
          privacy: ClassroomPrivacy.requestToJoin,
          memberCount: 28,
          capacity: 50,
          hostProfileId: 'prof_mentor_alex',
          hostDisplayName: 'Alex Rivera, Product Designer',
          membershipStatus: ClassroomMembershipStatus.none,
          tags: ['Figma', 'Design Systems', 'Accessibility'],
        ),
        LearningClassroom.create(
          id: 'cls_spanish_conversational_03',
          name: 'Conversational Spanish for Tech',
          description:
              'Weekly peer conversation circles, vocabulary practice, and cultural immersion for software professionals.',
          category: 'Languages',
          privacy: ClassroomPrivacy.public,
          memberCount: 19,
          capacity: 30,
          hostProfileId: 'prof_mentor_lucia',
          hostDisplayName: 'Lucia Morales, Polyglot',
          membershipStatus: ClassroomMembershipStatus.member,
          tags: ['Spanish', 'Speaking', 'Conversation'],
        ),
        LearningClassroom.create(
          id: 'cls_startup_product_04',
          name: 'Product Strategy & Lean MVPs',
          description:
              'Frameworks for user research, product discovery, metrics definition, and rapid prototype validation.',
          category: 'Business',
          privacy: ClassroomPrivacy.requestToJoin,
          memberCount: 35,
          capacity: 40,
          hostProfileId: 'prof_mentor_marcus',
          hostDisplayName: 'Marcus Vance, Startup Advisor',
          membershipStatus: ClassroomMembershipStatus.pending,
          tags: ['Product Management', 'Lean', 'Startup'],
        ),
        LearningClassroom.create(
          id: 'cls_ml_fundamentals_05',
          name: 'Machine Learning Fundamentals',
          description:
              'Core concepts in deep learning, PyTorch models, data preprocessing, and model evaluation techniques.',
          category: 'Programming',
          privacy: ClassroomPrivacy.closed,
          memberCount: 25,
          capacity: 25,
          hostProfileId: 'prof_mentor_david',
          hostDisplayName: 'Dr. David Kim',
          membershipStatus: ClassroomMembershipStatus.none,
          tags: ['Python', 'Machine Learning', 'Data Science'],
        ),
        LearningClassroom.create(
          id: 'cls_my_mentorship_classroom_06',
          name: 'Mobile App Architecture Labs',
          description:
              'Hosted workshop series analyzing scalable mobile frontend codebases, offline sync, and automated CI pipelines.',
          category: 'Programming',
          privacy: ClassroomPrivacy.requestToJoin,
          memberCount: 15,
          capacity: 30,
          hostProfileId: 'current_user_profile_id',
          hostDisplayName: 'Thusa Learner (Host)',
          membershipStatus: ClassroomMembershipStatus.host,
          tags: ['Architecture', 'CI/CD', 'Mobile'],
        ),
      ];
}
