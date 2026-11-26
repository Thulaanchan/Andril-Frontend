import 'package:flutter/foundation.dart';

/// Operational lifecycle statuses governing Learning Pacts (LRN-03, BRD v2.4-R1).
enum LearningPactStatus {
  /// Pact has been proposed and is awaiting mutual acceptance from all invitees.
  pending,

  /// All designated participants have voluntarily accepted. The pact is active.
  active,

  /// Proposal was cancelled by the proposer, or an active participant withdrew.
  cancelled,

  /// All active participants have reported completion of the pact commitments.
  completed;

  /// Whether the pact is currently active and in progress.
  bool get isActive => this == LearningPactStatus.active;

  /// Whether the pact is pending invitee acceptance.
  bool get isPending => this == LearningPactStatus.pending;

  /// Whether the pact was cancelled or terminated early.
  bool get isCancelled => this == LearningPactStatus.cancelled;

  /// Whether all participants confirmed completion.
  bool get isCompleted => this == LearningPactStatus.completed;

  /// Safely parses a string into [LearningPactStatus].
  static LearningPactStatus parse(
    String? value, {
    LearningPactStatus defaultValue = LearningPactStatus.pending,
  }) {
    if (value == null) return defaultValue;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'active':
        return LearningPactStatus.active;
      case 'cancelled':
      case 'canceled':
      case 'withdrawn':
        return LearningPactStatus.cancelled;
      case 'completed':
        return LearningPactStatus.completed;
      case 'pending':
      default:
        return defaultValue;
    }
  }
}

/// Invitation decision recorded for each designated participant (LRN-03).
enum PactInvitationDecision {
  /// Invitee has not yet accepted or declined.
  pending,

  /// Participant has voluntarily agreed to the pact terms.
  accepted,

  /// Invitee declined the invitation.
  declined;

  /// Whether the participant has accepted.
  bool get isAccepted => this == PactInvitationDecision.accepted;

  /// Whether the decision is pending.
  bool get isPending => this == PactInvitationDecision.pending;

  /// Whether the participant declined.
  bool get isDeclined => this == PactInvitationDecision.declined;

  /// Safely parses a string into [PactInvitationDecision].
  static PactInvitationDecision parse(
    String? value, {
    PactInvitationDecision defaultValue = PactInvitationDecision.pending,
  }) {
    if (value == null) return defaultValue;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'accepted':
      case 'agree':
      case 'agreed':
        return PactInvitationDecision.accepted;
      case 'declined':
      case 'rejected':
        return PactInvitationDecision.declined;
      case 'pending':
      default:
        return defaultValue;
    }
  }
}

/// Event types recorded in the read-only Pact Activity History (ANDRIL_LP_H01).
enum PactHistoryEventType {
  /// Initial pact proposed by the proposer.
  proposal,

  /// Invitee accepted the pact proposal (mutual agreement).
  agreed,

  /// Self-reported progress update on a commitment milestone.
  selfReported,

  /// Partner-reported progress update.
  partnerUpdate,

  /// Participant explicitly withdrew or pact was cancelled.
  withdrawn,

  /// Participant reported completion.
  completed;

  /// Safely parses a string into [PactHistoryEventType].
  static PactHistoryEventType parse(
    String? value, {
    PactHistoryEventType defaultValue = PactHistoryEventType.selfReported,
  }) {
    if (value == null) return defaultValue;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'proposal':
        return PactHistoryEventType.proposal;
      case 'agreed':
        return PactHistoryEventType.agreed;
      case 'selfreported':
      case 'self_reported':
        return PactHistoryEventType.selfReported;
      case 'partnerupdate':
      case 'partner_update':
        return PactHistoryEventType.partnerUpdate;
      case 'withdrawn':
        return PactHistoryEventType.withdrawn;
      case 'completed':
        return PactHistoryEventType.completed;
      default:
        return defaultValue;
    }
  }
}

/// Immutable record of an activity or state change in a Learning Pact.
@immutable
class PactHistoryEvent {
  final String id;
  final String pactId;
  final String title;
  final String description;
  final PactHistoryEventType type;
  final DateTime timestamp;
  final String? actorDisplayName;

  PactHistoryEvent({
    required String id,
    required String pactId,
    required String title,
    required String description,
    required this.type,
    DateTime? timestamp,
    this.actorDisplayName,
  })  : id = _validateRequired(id, 'id'),
        pactId = _validateRequired(pactId, 'pactId'),
        title = _validateRequired(title, 'title'),
        description = _validateRequired(description, 'description'),
        timestamp = timestamp ?? DateTime.now();

  static String _validateRequired(String value, String fieldName) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
          value, fieldName, '$fieldName cannot be empty.');
    }
    return trimmed;
  }

  PactHistoryEvent copyWith({
    String? id,
    String? pactId,
    String? title,
    String? description,
    PactHistoryEventType? type,
    DateTime? timestamp,
    String? actorDisplayName,
  }) {
    return PactHistoryEvent(
      id: id ?? this.id,
      pactId: pactId ?? this.pactId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      actorDisplayName: actorDisplayName ?? this.actorDisplayName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pactId': pactId,
        'title': title,
        'description': description,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'actorDisplayName': actorDisplayName,
      };

  factory PactHistoryEvent.fromJson(Map<String, dynamic> json) {
    return PactHistoryEvent(
      id: json['id']?.toString() ?? '',
      pactId: json['pactId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: PactHistoryEventType.parse(json['type']?.toString()),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      actorDisplayName: json['actorDisplayName']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PactHistoryEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pactId == other.pactId &&
          title == other.title &&
          description == other.description &&
          type == other.type &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      Object.hash(id, pactId, title, description, type, timestamp);

  @override
  String toString() => 'PactHistoryEvent [private record omitted]';
}

/// Immutable participation snapshot for a single learner in a Learning Pact (LRN-03).
///
/// Follows backend and security governance:
/// - Uses opaque module-profile IDs ([participantProfileId]). Internal account IDs are never exposed.
/// - Neither decision nor report provides verified achievement or automated XP.
@immutable
class PactParticipation {
  /// Opaque Learning profile identifier.
  final String participantProfileId;

  /// Public display name of the participant.
  final String participantDisplayName;

  /// Optional avatar URL or asset resource.
  final String? participantAvatarUrl;

  /// Invitation decision.
  final PactInvitationDecision decision;

  /// Whether this participant has confirmed completion of the pact.
  final bool completionConfirmed;

  /// Timestamp when the decision was recorded.
  final DateTime? agreedAt;

  PactParticipation({
    required String participantProfileId,
    required String participantDisplayName,
    this.participantAvatarUrl,
    this.decision = PactInvitationDecision.pending,
    this.completionConfirmed = false,
    this.agreedAt,
  })  : participantProfileId =
            _validateRequired(participantProfileId, 'participantProfileId'),
        participantDisplayName =
            _validateRequired(participantDisplayName, 'participantDisplayName');

  static String _validateRequired(String value, String fieldName) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
          value, fieldName, '$fieldName cannot be empty.');
    }
    return trimmed;
  }

  bool get isAccepted => decision == PactInvitationDecision.accepted;
  bool get isPending => decision == PactInvitationDecision.pending;
  bool get isDeclined => decision == PactInvitationDecision.declined;

  PactParticipation copyWith({
    String? participantProfileId,
    String? participantDisplayName,
    String? participantAvatarUrl,
    PactInvitationDecision? decision,
    bool? completionConfirmed,
    DateTime? agreedAt,
  }) {
    return PactParticipation(
      participantProfileId: participantProfileId ?? this.participantProfileId,
      participantDisplayName:
          participantDisplayName ?? this.participantDisplayName,
      participantAvatarUrl: participantAvatarUrl ?? this.participantAvatarUrl,
      decision: decision ?? this.decision,
      completionConfirmed: completionConfirmed ?? this.completionConfirmed,
      agreedAt: agreedAt ?? this.agreedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'participantProfileId': participantProfileId,
        'participantDisplayName': participantDisplayName,
        'participantAvatarUrl': participantAvatarUrl,
        'decision': decision.name,
        'completionConfirmed': completionConfirmed,
        'agreedAt': agreedAt?.toIso8601String(),
      };

  factory PactParticipation.fromJson(Map<String, dynamic> json) {
    return PactParticipation(
      participantProfileId: json['participantProfileId']?.toString() ?? '',
      participantDisplayName: json['participantDisplayName']?.toString() ?? '',
      participantAvatarUrl: json['participantAvatarUrl']?.toString(),
      decision: PactInvitationDecision.parse(json['decision']?.toString()),
      completionConfirmed: json['completionConfirmed'] == true,
      agreedAt: json['agreedAt'] != null
          ? DateTime.tryParse(json['agreedAt'].toString())
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PactParticipation &&
          runtimeType == other.runtimeType &&
          participantProfileId == other.participantProfileId &&
          participantDisplayName == other.participantDisplayName &&
          decision == other.decision &&
          completionConfirmed == other.completionConfirmed;

  @override
  int get hashCode => Object.hash(
        participantProfileId,
        participantDisplayName,
        decision,
        completionConfirmed,
      );

  @override
  String toString() => 'PactParticipation [private identity omitted]';
}

/// Immutable commitment milestone agreed upon in a Learning Pact (LRN-03).
///
/// Follows backend invariants:
/// - Text is retained exactly as agreed; no artificial deadlines or quotas.
/// - Completion is self-reported for peer study alignment.
@immutable
class PactCommitment {
  /// Unique commitment identifier.
  final String id;

  /// Identifier of the parent pact.
  final String pactId;

  /// Commitment milestone description text.
  final String text;

  /// Whether this milestone has been marked completed by the learners.
  final bool isCompleted;

  /// Timestamp when completed.
  final DateTime? completedAt;

  PactCommitment({
    required String id,
    required String pactId,
    required String text,
    this.isCompleted = false,
    this.completedAt,
  })  : id = _validateRequired(id, 'id'),
        pactId = _validateRequired(pactId, 'pactId'),
        text = _validateRequired(text, 'text');

  static String _validateRequired(String value, String fieldName) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
          value, fieldName, '$fieldName cannot be empty.');
    }
    return trimmed;
  }

  PactCommitment copyWith({
    String? id,
    String? pactId,
    String? text,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return PactCommitment(
      id: id ?? this.id,
      pactId: pactId ?? this.pactId,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pactId': pactId,
        'text': text,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory PactCommitment.fromJson(Map<String, dynamic> json) {
    return PactCommitment(
      id: json['id']?.toString() ?? '',
      pactId: json['pactId']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isCompleted: json['isCompleted'] == true,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PactCommitment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pactId == other.pactId &&
          text == other.text &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(id, pactId, text, isCompleted);

  @override
  String toString() => 'PactCommitment [private terms omitted]';
}

/// Domain entity representing a collaborative peer-to-peer Learning Pact (LRN-03, BRD v2.4-R1).
///
/// Follows strict ANDRIL M1 Learning Module governance:
/// - Module scope invariant: strictly equals 'learning'. Cross-module leakage is prohibited.
/// - Never activates before mutual acceptance from all designated participants (DEC-20261120-LRN03-01).
/// - Proposer agrees by proposing; invitees must voluntarily accept.
/// - PII protection: Uses opaque profile IDs and display names. Never exposes internal account IDs.
/// - Unmodifiable participants and commitments collections.
/// - Zero invented durations, study quotas, XP rewards, or communication permissions.
@immutable
class LearningPact {
  /// Canonical module scope invariant.
  static const String moduleScope = 'learning';

  /// Standard disconnected persistence notice when running in local presentation mode.
  static const String disconnectedNotice =
      'Remote Pacts backend contract pending in OpenAPI v1. Pacts operate in local presentation mode.';

  /// Unique pact identifier.
  final String id;

  /// Canonical module (strictly 'learning').
  final String module;

  /// User-defined pact title (e.g., 'Build a Flutter project').
  final String title;

  /// Shared learning goal description.
  final String sharedGoal;

  /// Optional duration label (e.g. '4 weeks', strictly as agreed; never invented).
  final String? duration;

  /// Optional study plan label (e.g. '3 days per week', strictly as agreed; never invented).
  final String? studyPlan;

  /// Profile ID of the learner who initiated the proposal.
  final String proposerProfileId;

  /// Display name of the proposer.
  final String proposerDisplayName;

  /// Current lifecycle status.
  final LearningPactStatus status;

  /// Unmodifiable list of designated participants (minimum 2 distinct learners).
  final List<PactParticipation> _participants;

  /// Unmodifiable list of agreed commitment milestones.
  final List<PactCommitment> _commitments;

  /// Unmodifiable list of activity history events.
  final List<PactHistoryEvent> _history;

  /// Timestamp when the proposal was created.
  final DateTime createdAt;

  const LearningPact._({
    required this.id,
    required this.module,
    required this.title,
    required this.sharedGoal,
    this.duration,
    this.studyPlan,
    required this.proposerProfileId,
    required this.proposerDisplayName,
    required this.status,
    required List<PactParticipation> participants,
    required List<PactCommitment> commitments,
    required List<PactHistoryEvent> history,
    required this.createdAt,
  })  : _participants = participants,
        _commitments = commitments,
        _history = history;

  /// Factory constructor for authoring a Learning Pact with domain invariant validation.
  factory LearningPact.create({
    required String id,
    String module = moduleScope,
    required String title,
    required String sharedGoal,
    String? duration,
    String? studyPlan,
    required String proposerProfileId,
    required String proposerDisplayName,
    LearningPactStatus status = LearningPactStatus.pending,
    required Iterable<PactParticipation> participants,
    Iterable<PactCommitment>? commitments,
    Iterable<PactHistoryEvent>? history,
    DateTime? createdAt,
  }) {
    final cleanModule = module.trim();
    if (cleanModule.isNotEmpty && cleanModule != moduleScope) {
      throw ArgumentError.value(
        module,
        'module',
        'Pact module must strictly be "$moduleScope".',
      );
    }

    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'A pact ID is required.');
    }
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'A pact title is required.');
    }
    final cleanGoal = sharedGoal.trim();
    if (cleanGoal.isEmpty) {
      throw ArgumentError.value(
          sharedGoal, 'sharedGoal', 'A shared goal is required.');
    }
    final cleanProposerId = proposerProfileId.trim();
    if (cleanProposerId.isEmpty) {
      throw ArgumentError.value(proposerProfileId, 'proposerProfileId',
          'A proposer profile ID is required.');
    }
    final cleanProposerName = proposerDisplayName.trim();
    if (cleanProposerName.isEmpty) {
      throw ArgumentError.value(proposerDisplayName, 'proposerDisplayName',
          'A proposer display name is required.');
    }

    final peopleList = List<PactParticipation>.of(participants);
    if (peopleList.length < 2) {
      throw ArgumentError.value(
        peopleList.length,
        'participants',
        'At least two distinct Learning participants are required.',
      );
    }

    final distinctProfileIds = <String>{};
    for (final p in peopleList) {
      if (!distinctProfileIds.add(p.participantProfileId)) {
        throw ArgumentError.value(
          p.participantProfileId,
          'participants',
          'Participant profile identities must be distinct.',
        );
      }
    }

    if (!peopleList.any((p) => p.participantProfileId == cleanProposerId)) {
      throw ArgumentError.value(
        cleanProposerId,
        'participants',
        'The proposer must be included as a designated participant.',
      );
    }

    // Determine authoritative status: Must NEVER activate before mutual acceptance!
    final isMutuallyAccepted =
        peopleList.every((p) => p.decision == PactInvitationDecision.accepted);
    if (status == LearningPactStatus.active && !isMutuallyAccepted) {
      throw StateError(
        'A Learning Pact cannot be active before mutual acceptance from all designated participants.',
      );
    }

    return LearningPact._(
      id: cleanId,
      module: cleanModule.isEmpty ? moduleScope : cleanModule,
      title: cleanTitle,
      sharedGoal: cleanGoal,
      duration: duration?.trim().isNotEmpty == true ? duration!.trim() : null,
      studyPlan:
          studyPlan?.trim().isNotEmpty == true ? studyPlan!.trim() : null,
      proposerProfileId: cleanProposerId,
      proposerDisplayName: cleanProposerName,
      status: status,
      participants: List<PactParticipation>.unmodifiable(peopleList),
      commitments: commitments == null
          ? const <PactCommitment>[]
          : List<PactCommitment>.unmodifiable(List.of(commitments)),
      history: history == null
          ? const <PactHistoryEvent>[]
          : List<PactHistoryEvent>.unmodifiable(List.of(history)),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Helper factory to propose a new Pact between a proposer and a partner.
  factory LearningPact.propose({
    required String id,
    required String title,
    required String sharedGoal,
    required String proposerProfileId,
    required String proposerDisplayName,
    required String partnerProfileId,
    required String partnerDisplayName,
    String? partnerAvatarUrl,
    String? duration,
    String? studyPlan,
    Iterable<String>? commitmentTexts,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();

    final proposerParticipation = PactParticipation(
      participantProfileId: proposerProfileId,
      participantDisplayName: proposerDisplayName,
      decision: PactInvitationDecision.accepted,
      agreedAt: now,
    );

    final partnerParticipation = PactParticipation(
      participantProfileId: partnerProfileId,
      participantDisplayName: partnerDisplayName,
      participantAvatarUrl: partnerAvatarUrl,
      decision: PactInvitationDecision.pending,
    );

    final commitmentList = <PactCommitment>[];
    if (commitmentTexts != null) {
      var idx = 1;
      for (final text in commitmentTexts) {
        if (text.trim().isNotEmpty) {
          commitmentList.add(PactCommitment(
            id: 'cmt_${id}_$idx',
            pactId: id,
            text: text.trim(),
          ));
          idx++;
        }
      }
    }

    final initialHistory = [
      PactHistoryEvent(
        id: 'hist_${id}_1',
        pactId: id,
        title: 'Pact proposed',
        description: 'You proposed this private Learning Pact.',
        type: PactHistoryEventType.proposal,
        timestamp: now,
        actorDisplayName: proposerDisplayName,
      ),
    ];

    return LearningPact.create(
      id: id,
      title: title,
      sharedGoal: sharedGoal,
      duration: duration,
      studyPlan: studyPlan,
      proposerProfileId: proposerProfileId,
      proposerDisplayName: proposerDisplayName,
      status: LearningPactStatus.pending,
      participants: [proposerParticipation, partnerParticipation],
      commitments: commitmentList,
      history: initialHistory,
      createdAt: now,
    );
  }

  /// Unmodifiable participants.
  List<PactParticipation> get participants => _participants;

  /// Unmodifiable commitments.
  List<PactCommitment> get commitments => _commitments;

  /// Unmodifiable activity history.
  List<PactHistoryEvent> get history => _history;

  /// Whether all participants have accepted the pact terms.
  bool get isMutualAccepted =>
      _participants.every((p) => p.decision == PactInvitationDecision.accepted);

  /// Whether the pact is active.
  bool get isActive => status == LearningPactStatus.active;

  /// Whether the pact is pending invitee response.
  bool get isPending => status == LearningPactStatus.pending;

  /// Whether the pact was cancelled.
  bool get isCancelled => status == LearningPactStatus.cancelled;

  /// Whether the pact was completed.
  bool get isCompleted => status == LearningPactStatus.completed;

  /// Checks if a given profile is the proposer.
  bool isProposer(String profileId) => proposerProfileId == profileId;

  /// Checks if a given profile is a designated participant.
  bool isParticipant(String profileId) =>
      _participants.any((p) => p.participantProfileId == profileId);

  /// Returns the other partner's participation relative to the viewing profile.
  PactParticipation? getPartner(String currentProfileId) {
    return _participants.firstWhere(
      (p) => p.participantProfileId != currentProfileId,
      orElse: () => _participants.first,
    );
  }

  /// Returns the current profile's own participation entry.
  PactParticipation? myParticipation(String currentProfileId) {
    try {
      return _participants.firstWhere(
        (p) => p.participantProfileId == currentProfileId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Count of completed commitments.
  int get completedCommitmentsCount =>
      _commitments.where((c) => c.isCompleted).length;

  /// Self-reported completion progress percentage (0..100).
  int get progressPercent {
    if (_commitments.isEmpty) return 0;
    return ((completedCommitmentsCount / _commitments.length) * 100).round();
  }

  /// Creates a copy with optional updated properties.
  LearningPact copyWith({
    String? id,
    String? module,
    String? title,
    String? sharedGoal,
    String? duration,
    String? studyPlan,
    String? proposerProfileId,
    String? proposerDisplayName,
    LearningPactStatus? status,
    Iterable<PactParticipation>? participants,
    Iterable<PactCommitment>? commitments,
    Iterable<PactHistoryEvent>? history,
    DateTime? createdAt,
  }) {
    final nextParticipants = participants != null
        ? List<PactParticipation>.unmodifiable(List.of(participants))
        : _participants;

    final nextStatus = status ?? this.status;

    // Invariant check: cannot be active unless mutually accepted
    final isMutuallyAccepted = nextParticipants
        .every((p) => p.decision == PactInvitationDecision.accepted);
    final validatedStatus =
        (nextStatus == LearningPactStatus.active && !isMutuallyAccepted)
            ? LearningPactStatus.pending
            : nextStatus;

    return LearningPact._(
      id: id ?? this.id,
      module: module ?? this.module,
      title: title ?? this.title,
      sharedGoal: sharedGoal ?? this.sharedGoal,
      duration: duration ?? this.duration,
      studyPlan: studyPlan ?? this.studyPlan,
      proposerProfileId: proposerProfileId ?? this.proposerProfileId,
      proposerDisplayName: proposerDisplayName ?? this.proposerDisplayName,
      status: validatedStatus,
      participants: nextParticipants,
      commitments: commitments != null
          ? List<PactCommitment>.unmodifiable(List.of(commitments))
          : _commitments,
      history: history != null
          ? List<PactHistoryEvent>.unmodifiable(List.of(history))
          : _history,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'module': module,
        'title': title,
        'sharedGoal': sharedGoal,
        'duration': duration,
        'studyPlan': studyPlan,
        'proposerProfileId': proposerProfileId,
        'proposerDisplayName': proposerDisplayName,
        'status': status.name,
        'participants': _participants.map((p) => p.toJson()).toList(),
        'commitments': _commitments.map((c) => c.toJson()).toList(),
        'history': _history.map((h) => h.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory LearningPact.fromJson(Map<String, dynamic> json) {
    final parsedParticipants = <PactParticipation>[];
    if (json['participants'] is Iterable) {
      for (final item in json['participants'] as Iterable) {
        if (item is Map<String, dynamic>) {
          parsedParticipants.add(PactParticipation.fromJson(item));
        }
      }
    }

    final parsedCommitments = <PactCommitment>[];
    if (json['commitments'] is Iterable) {
      for (final item in json['commitments'] as Iterable) {
        if (item is Map<String, dynamic>) {
          parsedCommitments.add(PactCommitment.fromJson(item));
        }
      }
    }

    final parsedHistory = <PactHistoryEvent>[];
    if (json['history'] is Iterable) {
      for (final item in json['history'] as Iterable) {
        if (item is Map<String, dynamic>) {
          parsedHistory.add(PactHistoryEvent.fromJson(item));
        }
      }
    }

    return LearningPact.create(
      id: json['id']?.toString() ?? '',
      module: json['module']?.toString() ?? moduleScope,
      title: json['title']?.toString() ?? '',
      sharedGoal: json['sharedGoal']?.toString() ?? '',
      duration: json['duration']?.toString(),
      studyPlan: json['studyPlan']?.toString(),
      proposerProfileId: json['proposerProfileId']?.toString() ?? '',
      proposerDisplayName: json['proposerDisplayName']?.toString() ?? '',
      status: LearningPactStatus.parse(json['status']?.toString()),
      participants: parsedParticipants,
      commitments: parsedCommitments,
      history: parsedHistory,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningPact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          module == other.module &&
          title == other.title &&
          sharedGoal == other.sharedGoal &&
          duration == other.duration &&
          studyPlan == other.studyPlan &&
          proposerProfileId == other.proposerProfileId &&
          proposerDisplayName == other.proposerDisplayName &&
          status == other.status &&
          listEquals(_participants, other._participants) &&
          listEquals(_commitments, other._commitments);

  @override
  int get hashCode => Object.hash(
        id,
        module,
        title,
        sharedGoal,
        duration,
        studyPlan,
        proposerProfileId,
        proposerDisplayName,
        status,
        Object.hashAll(_participants),
        Object.hashAll(_commitments),
      );

  @override
  String toString() => 'LearningPact (${status.name}) [private terms omitted]';
}
