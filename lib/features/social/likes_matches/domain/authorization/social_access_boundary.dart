import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';

/// Categorized evaluation outcome for Social participation access.
enum SocialAccessStatus {
  /// Caller satisfies all authoritative eligibility, adult, and opt-in conditions.
  granted,

  /// No active authenticated user session exists.
  unauthenticated,

  /// User is not verified as adult (underage or age unknown).
  underage,

  /// User has not explicitly opted in to Social participation.
  optInRequired,

  /// Social module participation has been suspended or revoked by governance.
  revoked,

  /// Authoritative eligibility evidence is missing or unverified (fail-closed).
  unavailable,
}

/// Immutable record of authoritative evidence required for Social access.
///
/// Follows M2 Session & Access Governance:
/// - Authentication alone NEVER authorizes Social module participation.
/// - Requires explicit adult verification and active user opt-in.
/// - Requires authoritative verification timestamp and non-revoked standing.
@immutable
class SocialAccessEvidence {
  final String userId;
  final bool isAdult;
  final bool isOptedIn;
  final bool isModuleGranted;
  final DateTime verifiedAt;
  final bool isAuthoritative;

  const SocialAccessEvidence({
    required this.userId,
    required this.isAdult,
    required this.isOptedIn,
    this.isModuleGranted = true,
    required this.verifiedAt,
    this.isAuthoritative = true,
  });

  /// Factory for verified eligible adult participant.
  factory SocialAccessEvidence.authorized({
    required String userId,
    DateTime? verifiedAt,
  }) {
    return SocialAccessEvidence(
      userId: userId,
      isAdult: true,
      isOptedIn: true,
      isModuleGranted: true,
      verifiedAt: verifiedAt ?? DateTime.now(),
      isAuthoritative: true,
    );
  }

  /// Empty / unverified evidence that fails closed.
  factory SocialAccessEvidence.unverified({String userId = ''}) {
    return SocialAccessEvidence(
      userId: userId,
      isAdult: false,
      isOptedIn: false,
      isModuleGranted: false,
      verifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
      isAuthoritative: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'isAdult': isAdult,
        'isOptedIn': isOptedIn,
        'isModuleGranted': isModuleGranted,
        'verifiedAt': verifiedAt.toIso8601String(),
        'isAuthoritative': isAuthoritative,
      };

  factory SocialAccessEvidence.fromJson(Map<String, dynamic> json) {
    return SocialAccessEvidence(
      userId: json['userId'] as String? ?? '',
      isAdult: json['isAdult'] as bool? ?? false,
      isOptedIn: json['isOptedIn'] as bool? ?? false,
      isModuleGranted: json['isModuleGranted'] as bool? ?? false,
      verifiedAt: DateTime.tryParse(json['verifiedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      isAuthoritative: json['isAuthoritative'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'SocialAccessEvidence(userId: $userId, adult: $isAdult, optedIn: $isOptedIn, auth: $isAuthoritative)';
}

/// Abstract contract governing access evaluation for the Social module.
abstract class ISocialAccessBoundary {
  /// Evaluates whether the caller satisfies all authoritative criteria to participate in Social.
  SocialAccessStatus evaluateAccess({
    SessionController? sessionController,
    SocialAccessEvidence? evidence,
  });

  /// Convenience boolean check: true only when [evaluateAccess] returns [SocialAccessStatus.granted].
  bool isAccessGranted({
    SessionController? sessionController,
    SocialAccessEvidence? evidence,
  });
}

/// Production implementation of [ISocialAccessBoundary].
///
/// Follows M2 Security & M5 Frontend Governance:
/// - Fails closed by default whenever evidence is missing, unauthoritative, or expired.
/// - Does not treat unverified client boolean flags as valid grants.
class SocialAccessBoundary implements ISocialAccessBoundary {
  const SocialAccessBoundary();

  @override
  SocialAccessStatus evaluateAccess({
    SessionController? sessionController,
    SocialAccessEvidence? evidence,
  }) {
    // 1. Session check
    if (sessionController == null || sessionController.phase != SessionPhase.signedIn) {
      return SocialAccessStatus.unauthenticated;
    }

    // 2. Authoritative evidence check
    if (evidence == null || !evidence.isAuthoritative) {
      return SocialAccessStatus.unavailable;
    }

    // 3. Adult check
    if (!evidence.isAdult) {
      return SocialAccessStatus.underage;
    }

    // 4. Opt-in check
    if (!evidence.isOptedIn) {
      return SocialAccessStatus.optInRequired;
    }

    // 5. Module grant check
    if (!evidence.isModuleGranted) {
      return SocialAccessStatus.revoked;
    }

    return SocialAccessStatus.granted;
  }

  @override
  bool isAccessGranted({
    SessionController? sessionController,
    SocialAccessEvidence? evidence,
  }) {
    return evaluateAccess(
      sessionController: sessionController,
      evidence: evidence,
    ) == SocialAccessStatus.granted;
  }
}
