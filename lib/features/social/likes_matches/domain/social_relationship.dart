import 'package:flutter/foundation.dart';
import '../../discovery/domain/social_candidate.dart';

/// Approved lifecycle states governing pairwise Social relationships (SOC-03 / CF-20).
///
/// Strictly mirrors backend `SocialRelationshipState` transition policy:
/// - [none]: No recorded relationship or interaction.
/// - [pendingUnilateral]: Caller recorded affirmative interest; counterpart decision is pending or confidential.
/// - [matched]: Bilateral affirmative interest confirmed with authoritative match evidence.
/// - [passed]: Negative decision recorded by one or both participants.
/// - [revoked]: Voluntary unmatch or relationship termination.
/// - [blocked]: Participant blocked; all interaction strictly denied.
enum SocialRelationshipState {
  none,
  pendingUnilateral,
  matched,
  passed,
  revoked,
  blocked;

  /// Whether this state represents an active, server-confirmed mutual match.
  bool get isMatched => this == SocialRelationshipState.matched;

  /// Whether this state represents a pending unilateral decision.
  bool get isPending => this == SocialRelationshipState.pendingUnilateral;

  /// Whether this state represents a passed candidate.
  bool get isPassed => this == SocialRelationshipState.passed;

  /// Whether this state represents a revoked match.
  bool get isRevoked => this == SocialRelationshipState.revoked;

  /// Whether this state represents a blocked relationship.
  bool get isBlocked => this == SocialRelationshipState.blocked;

  /// Safely parses a string value into [SocialRelationshipState], returning [defaultValue] on unrecognized inputs.
  static SocialRelationshipState parse(
    String? value, {
    SocialRelationshipState defaultValue = SocialRelationshipState.none,
  }) {
    if (value == null) return defaultValue;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'matched':
        return SocialRelationshipState.matched;
      case 'pendingunilateral':
      case 'pending':
        return SocialRelationshipState.pendingUnilateral;
      case 'passed':
        return SocialRelationshipState.passed;
      case 'revoked':
        return SocialRelationshipState.revoked;
      case 'blocked':
        return SocialRelationshipState.blocked;
      case 'none':
        return SocialRelationshipState.none;
      default:
        return defaultValue;
    }
  }
}

/// Directional dating interest signal expressed by a participant.
enum DirectionalInterest {
  /// Affirmative interest ('Like').
  positive,

  /// Negative interest ('Pass').
  negative,

  /// No decision recorded.
  none;

  /// Whether this represents an affirmative decision.
  bool get isPositive => this == DirectionalInterest.positive;

  /// Whether this represents a negative decision.
  bool get isNegative => this == DirectionalInterest.negative;

  /// Safely parses a boolean or string into [DirectionalInterest].
  static DirectionalInterest fromValue(dynamic value) {
    if (value == null) return DirectionalInterest.none;
    if (value is bool) {
      return value ? DirectionalInterest.positive : DirectionalInterest.negative;
    }
    final str = value.toString().trim().toLowerCase();
    if (str == 'true' || str == 'positive' || str == 'like') {
      return DirectionalInterest.positive;
    }
    if (str == 'false' || str == 'negative' || str == 'pass') {
      return DirectionalInterest.negative;
    }
    return DirectionalInterest.none;
  }
}

/// Confirmed mutual-match evidence produced by authoritative backend verification.
///
/// In accordance with Section 10 invariants:
/// - Unilateral interest alone never generates a match.
/// - Match creation requires server-confirmed evidence with a valid [matchId] and [matchedAtUtc].
@immutable
class SocialMatchEvidence {
  /// Server-generated unique match identifier (GUID).
  final String matchId;

  /// UTC timestamp at which mutual matching was authoritatively confirmed.
  final DateTime matchedAtUtc;

  const SocialMatchEvidence({
    required this.matchId,
    required this.matchedAtUtc,
  });

  /// Constructs [SocialMatchEvidence] from backend JSON payload.
  factory SocialMatchEvidence.fromJson(Map<String, dynamic> json) {
    final mId = json['matchId']?.toString() ?? '';
    final parsedDate = json['matchedAtUtc'] != null
        ? DateTime.tryParse(json['matchedAtUtc'].toString())?.toUtc()
        : null;

    return SocialMatchEvidence(
      matchId: mId,
      matchedAtUtc: parsedDate ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  /// Serializes evidence to JSON.
  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'matchedAtUtc': matchedAtUtc.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialMatchEvidence &&
          runtimeType == other.runtimeType &&
          matchId == other.matchId &&
          matchedAtUtc == other.matchedAtUtc;

  @override
  int get hashCode => Object.hash(matchId, matchedAtUtc);

  @override
  String toString() =>
      'SocialMatchEvidence(matchId: [redacted], matchedAtUtc: ${matchedAtUtc.toIso8601String()})';
}

/// Category filtering for My Connections presentation (S13).
enum SocialConnectionCategory {
  all,
  recent,
  favorites;

  String get displayName {
    switch (this) {
      case SocialConnectionCategory.all:
        return 'All Connections';
      case SocialConnectionCategory.recent:
        return 'Recent';
      case SocialConnectionCategory.favorites:
        return 'Favorites';
    }
  }
}

/// Immutable domain model representing a pairwise Social relationship or connection.
///
/// Conforms to M5-FE-S12/S13 relationship domain governance:
/// - Strictly encapsulates social-scoped identifiers; never exposes account emails, phone numbers,
///   passwords, or internal surrogate integer IDs.
/// - Differentiates directional interest from server-confirmed mutual matching.
/// - Enforces defensive collection immutability for tags and auxiliary metadata.
/// - Produces redacted diagnostic representations to prevent inadvertent sensitive log emission.
@immutable
class SocialRelationship {
  /// Social-scoped unique relationship or connection identifier.
  final String id;

  /// Social-scoped unique candidate profile identifier (GUID string).
  final String targetProfileId;

  /// Candidate presentation model associated with this relationship.
  final SocialCandidate candidate;

  /// Approved pairwise lifecycle state.
  final SocialRelationshipState state;

  /// The authenticated caller's recorded directional interest toward this candidate.
  final DirectionalInterest callerInterest;

  /// Server-confirmed mutual-match evidence, populated strictly when [state] is [SocialRelationshipState.matched].
  final SocialMatchEvidence? matchEvidence;

  /// UTC timestamp of relationship initiation or first interaction.
  final DateTime? createdAtUtc;

  /// User-controlled favorite bookmark flag.
  final bool isFavorite;

  /// Defensively immutable list of connection tags or note chips.
  final List<String> _tags;

  /// Constructs an immutable [SocialRelationship] with defensive collection copying.
  SocialRelationship({
    required this.id,
    required this.targetProfileId,
    required this.candidate,
    this.state = SocialRelationshipState.none,
    this.callerInterest = DirectionalInterest.none,
    this.matchEvidence,
    this.createdAtUtc,
    this.isFavorite = false,
    Iterable<String>? tags,
  })  : _tags = tags == null
            ? const <String>[]
            : List<String>.unmodifiable(List<String>.of(tags));

  /// Unmodifiable view of connection tags.
  List<String> get tags => _tags;

  /// Whether this relationship has an active, server-confirmed mutual match.
  bool get hasActiveMatch =>
      state == SocialRelationshipState.matched && matchEvidence != null;

  /// Whether direct communication (M4 Chat) entry is eligible.
  ///
  /// Strictly requires active mutual matching. Directional interest or pending states
  /// CANNOT unlock communication access.
  bool get canCommunicate => hasActiveMatch;

  /// Convenience accessor for target candidate display name.
  String get displayName => candidate.displayName;

  /// Convenience accessor for target candidate photo URL.
  String? get primaryPhotoUrl => candidate.primaryPhotoUrl;

  /// Constructs a [SocialRelationship] from JSON.
  factory SocialRelationship.fromJson(Map<String, dynamic> json) {
    final candidateObj = json['candidate'] is Map<String, dynamic>
        ? SocialCandidate.fromJson(json['candidate'] as Map<String, dynamic>)
        : SocialCandidate(
            id: json['targetProfileId']?.toString() ?? '',
            displayName: json['displayName']?.toString() ?? 'Explorer',
            age: 18,
          );

    final rawEvidence = json['matchEvidence'];
    final evidence = rawEvidence is Map<String, dynamic>
        ? SocialMatchEvidence.fromJson(rawEvidence)
        : null;

    final rawTags = json['tags'] as List<dynamic>?;
    final tagList = rawTags?.map((e) => e.toString()).toList();

    return SocialRelationship(
      id: json['id']?.toString() ?? '',
      targetProfileId: json['targetProfileId']?.toString() ?? candidateObj.id,
      candidate: candidateObj,
      state: SocialRelationshipState.parse(json['state']?.toString()),
      callerInterest: DirectionalInterest.fromValue(json['callerInterest']),
      matchEvidence: evidence,
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.tryParse(json['createdAtUtc'].toString())?.toUtc()
          : null,
      isFavorite: json['isFavorite'] == true,
      tags: tagList,
    );
  }

  /// Serializes to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'targetProfileId': targetProfileId,
        'candidate': candidate.toJson(),
        'state': state.name,
        'callerInterest': callerInterest.name,
        if (matchEvidence != null) 'matchEvidence': matchEvidence!.toJson(),
        if (createdAtUtc != null) 'createdAtUtc': createdAtUtc!.toIso8601String(),
        'isFavorite': isFavorite,
        'tags': _tags,
      };

  /// Creates a copy of this relationship with specified properties replaced.
  SocialRelationship copyWith({
    String? id,
    String? targetProfileId,
    SocialCandidate? candidate,
    SocialRelationshipState? state,
    DirectionalInterest? callerInterest,
    SocialMatchEvidence? matchEvidence,
    DateTime? createdAtUtc,
    bool? isFavorite,
    Iterable<String>? tags,
  }) {
    return SocialRelationship(
      id: id ?? this.id,
      targetProfileId: targetProfileId ?? this.targetProfileId,
      candidate: candidate ?? this.candidate,
      state: state ?? this.state,
      callerInterest: callerInterest ?? this.callerInterest,
      matchEvidence: matchEvidence ?? this.matchEvidence,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? _tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialRelationship &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          targetProfileId == other.targetProfileId &&
          candidate == other.candidate &&
          state == other.state &&
          callerInterest == other.callerInterest &&
          matchEvidence == other.matchEvidence &&
          createdAtUtc == other.createdAtUtc &&
          isFavorite == other.isFavorite &&
          listEquals(_tags, other._tags);

  @override
  int get hashCode => Object.hash(
        id,
        targetProfileId,
        candidate,
        state,
        callerInterest,
        matchEvidence,
        createdAtUtc,
        isFavorite,
        Object.hashAll(_tags),
      );

  @override
  String toString() {
    return 'SocialRelationship(id: $id, targetProfileId: $targetProfileId, state: ${state.name}, hasActiveMatch: $hasActiveMatch, isFavorite: $isFavorite)';
  }
}

/// Lightweight DTO representing backend relationship operation response (`SocialRelationshipOperationResponseDto`).
@immutable
class SocialRelationshipOperationResult {
  final bool success;
  final bool matchCreated;
  final String? matchId;
  final String visibleState;

  const SocialRelationshipOperationResult({
    required this.success,
    required this.matchCreated,
    this.matchId,
    required this.visibleState,
  });

  factory SocialRelationshipOperationResult.fromJson(Map<String, dynamic> json) {
    return SocialRelationshipOperationResult(
      success: json['success'] == true,
      matchCreated: json['matchCreated'] == true,
      matchId: json['matchId']?.toString(),
      visibleState: json['visibleState']?.toString() ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'matchCreated': matchCreated,
        if (matchId != null) 'matchId': matchId,
        'visibleState': visibleState,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialRelationshipOperationResult &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          matchCreated == other.matchCreated &&
          matchId == other.matchId &&
          visibleState == other.visibleState;

  @override
  int get hashCode => Object.hash(success, matchCreated, matchId, visibleState);

  @override
  String toString() =>
      'SocialRelationshipOperationResult(success: $success, matchCreated: $matchCreated, state: $visibleState)';
}

/// Lightweight DTO representing backend relationship status response (`SocialRelationshipStatusResponseDto`).
@immutable
class SocialRelationshipStatusResult {
  final bool hasActiveMatch;
  final String? matchId;
  final DateTime? matchedAtUtc;

  const SocialRelationshipStatusResult({
    required this.hasActiveMatch,
    this.matchId,
    this.matchedAtUtc,
  });

  factory SocialRelationshipStatusResult.fromJson(Map<String, dynamic> json) {
    return SocialRelationshipStatusResult(
      hasActiveMatch: json['hasActiveMatch'] == true,
      matchId: json['matchId']?.toString(),
      matchedAtUtc: json['matchedAtUtc'] != null
          ? DateTime.tryParse(json['matchedAtUtc'].toString())?.toUtc()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'hasActiveMatch': hasActiveMatch,
        if (matchId != null) 'matchId': matchId,
        if (matchedAtUtc != null) 'matchedAtUtc': matchedAtUtc!.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialRelationshipStatusResult &&
          runtimeType == other.runtimeType &&
          hasActiveMatch == other.hasActiveMatch &&
          matchId == other.matchId &&
          matchedAtUtc == other.matchedAtUtc;

  @override
  int get hashCode => Object.hash(hasActiveMatch, matchId, matchedAtUtc);

  @override
  String toString() =>
      'SocialRelationshipStatusResult(hasActiveMatch: $hasActiveMatch, matchId: $matchId)';
}

/// Lightweight DTO representing backend match revocation response (`SocialRevocationResponseDto`).
@immutable
class SocialRevocationResult {
  final bool success;
  final bool matchRevoked;

  const SocialRevocationResult({
    required this.success,
    required this.matchRevoked,
  });

  factory SocialRevocationResult.fromJson(Map<String, dynamic> json) {
    return SocialRevocationResult(
      success: json['success'] == true,
      matchRevoked: json['matchRevoked'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'matchRevoked': matchRevoked,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialRevocationResult &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          matchRevoked == other.matchRevoked;

  @override
  int get hashCode => Object.hash(success, matchRevoked);

  @override
  String toString() =>
      'SocialRevocationResult(success: $success, matchRevoked: $matchRevoked)';
}
