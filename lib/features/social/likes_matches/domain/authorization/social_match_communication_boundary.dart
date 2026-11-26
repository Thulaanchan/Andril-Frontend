import 'package:flutter/foundation.dart';

/// Categorized authorization outcome for peer-to-peer match communication.
enum MatchCommunicationStatus {
  /// Mutual match is confirmed and authorized by M4 communication module.
  authorized,

  /// Match is one-sided or awaiting reciprocal confirmation.
  pendingMutualMatch,

  /// One of the participants has blocked communication.
  blocked,

  /// One of the participants has unmatched or dissolved the connection.
  unmatched,

  /// Match verification evidence has expired.
  expired,

  /// Communication is unauthorized by policy, identity mismatch, or missing evidence.
  unauthorized,

  /// M4 messaging/calling dependency is unavailable or not registered.
  m4Unavailable,
}

/// Authoritative evidence confirming mutual interest and M4 communication clearance.
///
/// Follows M4 Communication & M5 Matching Governance:
/// - One-sided likes NEVER authorize communication.
/// - Client-side state flags cannot manufacture a mutual match.
/// - Requires active M4 channel clearance and non-forged participant binding.
@immutable
class MatchCommunicationEvidence {
  final String matchId;
  final String participantA;
  final String participantB;
  final bool isMutual;
  final bool isBlocked;
  final bool isUnmatched;
  final bool isExpired;
  final String? m4ChannelId;
  final DateTime verifiedAt;
  final bool isM4Authorized;

  const MatchCommunicationEvidence({
    required this.matchId,
    required this.participantA,
    required this.participantB,
    required this.isMutual,
    this.isBlocked = false,
    this.isUnmatched = false,
    this.isExpired = false,
    this.m4ChannelId,
    required this.verifiedAt,
    this.isM4Authorized = false,
  });

  /// Factory for a fully verified mutual match with M4 communication authorization.
  factory MatchCommunicationEvidence.authorized({
    required String matchId,
    required String participantA,
    required String participantB,
    required String m4ChannelId,
    DateTime? verifiedAt,
    bool isExpired = false,
  }) {
    return MatchCommunicationEvidence(
      matchId: matchId,
      participantA: participantA,
      participantB: participantB,
      isMutual: true,
      isBlocked: false,
      isUnmatched: false,
      isExpired: isExpired,
      m4ChannelId: m4ChannelId,
      verifiedAt: verifiedAt ?? DateTime.now(),
      isM4Authorized: true,
    );
  }

  /// Factory for unconfirmed or one-sided interest.
  factory MatchCommunicationEvidence.pending({
    required String matchId,
    required String participantA,
    required String participantB,
  }) {
    return MatchCommunicationEvidence(
      matchId: matchId,
      participantA: participantA,
      participantB: participantB,
      isMutual: false,
      isBlocked: false,
      isUnmatched: false,
      isExpired: false,
      m4ChannelId: null,
      verifiedAt: DateTime.now(),
      isM4Authorized: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'participantA': participantA,
        'participantB': participantB,
        'isMutual': isMutual,
        'isBlocked': isBlocked,
        'isUnmatched': isUnmatched,
        'isExpired': isExpired,
        if (m4ChannelId != null) 'm4ChannelId': m4ChannelId,
        'verifiedAt': verifiedAt.toIso8601String(),
        'isM4Authorized': isM4Authorized,
      };

  factory MatchCommunicationEvidence.fromJson(Map<String, dynamic> json) {
    return MatchCommunicationEvidence(
      matchId: json['matchId'] as String? ?? '',
      participantA: json['participantA'] as String? ?? '',
      participantB: json['participantB'] as String? ?? '',
      isMutual: json['isMutual'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      isUnmatched: json['isUnmatched'] as bool? ?? false,
      isExpired: json['isExpired'] as bool? ?? false,
      m4ChannelId: json['m4ChannelId'] as String?,
      verifiedAt: DateTime.tryParse(json['verifiedAt'] as String? ?? '') ?? DateTime.now(),
      isM4Authorized: json['isM4Authorized'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'MatchCommunicationEvidence(matchId: $matchId, mutual: $isMutual, m4Auth: $isM4Authorized, expired: $isExpired)';
}

/// Abstract contract governing peer communication clearance between matched members.
abstract class ISocialMatchCommunicationBoundary {
  /// Evaluates whether communication can be initiated for the provided [evidence].
  /// Optionally validates [callerId] binding against participants.
  MatchCommunicationStatus evaluateMatchCommunication(
    MatchCommunicationEvidence? evidence, {
    String? callerId,
  });

  /// Convenience boolean check: true only when [evaluateMatchCommunication] is [MatchCommunicationStatus.authorized].
  bool canInitiateCommunication(
    MatchCommunicationEvidence? evidence, {
    String? callerId,
  });
}

/// Production implementation of [ISocialMatchCommunicationBoundary].
///
/// Follows M4/M5 Module Boundary Governance:
/// - Fails closed: communication is denied unless mutual confirmation AND M4 authorization exist.
/// - Verifies participant identity non-empty and non-identical.
/// - Validates optional caller binding strictly against participant identities.
/// - Enforces expiration checks.
class SocialMatchCommunicationBoundary implements ISocialMatchCommunicationBoundary {
  const SocialMatchCommunicationBoundary();

  @override
  MatchCommunicationStatus evaluateMatchCommunication(
    MatchCommunicationEvidence? evidence, {
    String? callerId,
  }) {
    if (evidence == null) {
      return MatchCommunicationStatus.unauthorized;
    }

    // Identity validity check: participants must be distinct non-empty IDs
    if (evidence.participantA.isEmpty ||
        evidence.participantB.isEmpty ||
        evidence.participantA == evidence.participantB) {
      return MatchCommunicationStatus.unauthorized;
    }

    // Caller binding check: if callerId is provided, caller must be one of the participants
    if (callerId != null &&
        callerId.isNotEmpty &&
        callerId != evidence.participantA &&
        callerId != evidence.participantB) {
      return MatchCommunicationStatus.unauthorized;
    }

    if (evidence.isBlocked) {
      return MatchCommunicationStatus.blocked;
    }

    if (evidence.isUnmatched) {
      return MatchCommunicationStatus.unmatched;
    }

    if (evidence.isExpired) {
      return MatchCommunicationStatus.expired;
    }

    if (!evidence.isMutual) {
      return MatchCommunicationStatus.pendingMutualMatch;
    }

    if (!evidence.isM4Authorized ||
        evidence.m4ChannelId == null ||
        evidence.m4ChannelId!.trim().isEmpty) {
      return MatchCommunicationStatus.m4Unavailable;
    }

    return MatchCommunicationStatus.authorized;
  }

  @override
  bool canInitiateCommunication(
    MatchCommunicationEvidence? evidence, {
    String? callerId,
  }) {
    return evaluateMatchCommunication(evidence, callerId: callerId) ==
        MatchCommunicationStatus.authorized;
  }
}
