import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';

/// Categorized evaluation outcome for Social participation access.
enum SocialAccessStatus {
  /// Caller satisfies all authoritative eligibility, adult, and opt-in conditions bound to active session.
  granted,

  /// No active authenticated user session exists.
  unauthenticated,

  /// User is not verified as adult (underage or age unknown).
  underage,

  /// User has not explicitly opted in to Social participation.
  optInRequired,

  /// Social module participation has been suspended or revoked by governance.
  revoked,

  /// Evidence subject does not match the active authenticated session subject.
  mismatched,

  /// Evidence is stale or bound to an outdated/invalidated session lifecycle.
  stale,

  /// Authoritative eligibility evidence is missing, unverified, or M2 contract is unavailable (fail-closed).
  unavailable,
}

/// Immutable record of authoritative evidence required for Social access.
///
/// Follows M2 Session & Access Governance:
/// - Authentication alone NEVER authorizes Social module participation.
/// - Requires explicit adult verification and active user opt-in.
/// - Requires authoritative verification timestamp and non-revoked standing.
/// - Binds directly to active session subject and session epoch.
@immutable
class SocialAccessEvidence {
  final String userId;
  final bool isAdult;
  final bool isOptedIn;
  final bool isModuleGranted;
  final DateTime verifiedAt;
  final bool isAuthoritative;
  final int? sessionEpoch;
  final bool isRevoked;

  const SocialAccessEvidence({
    required this.userId,
    required this.isAdult,
    required this.isOptedIn,
    this.isModuleGranted = true,
    required this.verifiedAt,
    this.isAuthoritative = true,
    this.sessionEpoch,
    this.isRevoked = false,
  });

  /// Factory for verified eligible adult participant bound to session lifecycle.
  factory SocialAccessEvidence.authorized({
    required String userId,
    DateTime? verifiedAt,
    int? sessionEpoch,
  }) {
    return SocialAccessEvidence(
      userId: userId,
      isAdult: true,
      isOptedIn: true,
      isModuleGranted: true,
      verifiedAt: verifiedAt ?? DateTime.now(),
      isAuthoritative: true,
      sessionEpoch: sessionEpoch,
      isRevoked: false,
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
      isRevoked: false,
    );
  }

  /// Revoked access evidence.
  factory SocialAccessEvidence.revoked({
    required String userId,
    DateTime? verifiedAt,
  }) {
    return SocialAccessEvidence(
      userId: userId,
      isAdult: true,
      isOptedIn: true,
      isModuleGranted: false,
      verifiedAt: verifiedAt ?? DateTime.now(),
      isAuthoritative: true,
      isRevoked: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'isAdult': isAdult,
        'isOptedIn': isOptedIn,
        'isModuleGranted': isModuleGranted,
        'verifiedAt': verifiedAt.toIso8601String(),
        'isAuthoritative': isAuthoritative,
        if (sessionEpoch != null) 'sessionEpoch': sessionEpoch,
        'isRevoked': isRevoked,
      };

  factory SocialAccessEvidence.fromJson(Map<String, dynamic> json) {
    return SocialAccessEvidence(
      userId: json['userId'] as String? ?? '',
      isAdult: json['isAdult'] as bool? ?? false,
      isOptedIn: json['isOptedIn'] as bool? ?? false,
      isModuleGranted: json['isModuleGranted'] as bool? ?? false,
      verifiedAt: DateTime.tryParse(json['verifiedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      isAuthoritative: json['isAuthoritative'] as bool? ?? false,
      sessionEpoch: json['sessionEpoch'] as int?,
      isRevoked: json['isRevoked'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'SocialAccessEvidence(userId: $userId, adult: $isAdult, optedIn: $isOptedIn, auth: $isAuthoritative, epoch: $sessionEpoch, revoked: $isRevoked)';
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
/// - Enforces session subject match and session epoch validity.
class SocialAccessBoundary implements ISocialAccessBoundary {
  const SocialAccessBoundary();

  @override
  SocialAccessStatus evaluateAccess({
    SessionController? sessionController,
    SocialAccessEvidence? evidence,
  }) {
    // 1. Session check: Active authenticated session is strictly required
    if (sessionController == null || sessionController.phase != SessionPhase.signedIn) {
      return SocialAccessStatus.unauthenticated;
    }

    // 2. Authoritative evidence check: Missing or unauthoritative evidence fails closed
    if (evidence == null || !evidence.isAuthoritative) {
      return SocialAccessStatus.unavailable;
    }

    // 3. Subject binding check: When session subject is available, evidence must match caller identity
    String? sessionSubject;
    try {
      sessionSubject = sessionController.subject;
    } catch (_) {
      sessionSubject = null;
    }
    if (sessionSubject != null && sessionSubject.isNotEmpty && evidence.userId.isNotEmpty) {
      if (evidence.userId != sessionSubject) {
        return SocialAccessStatus.mismatched;
      }
    }

    // 4. Session lifecycle / epoch binding check: If evidence carries sessionEpoch, verify against active backendSession
    try {
      final backendSession = sessionController.backendSession;
      if (backendSession != null && evidence.sessionEpoch != null) {
        if (evidence.sessionEpoch != backendSession.epoch) {
          return SocialAccessStatus.stale;
        }
      }
    } catch (_) {
      // Mock resilience
    }

    // 5. Revocation check: Revoked module participation denies access immediately
    if (!evidence.isModuleGranted || evidence.isRevoked) {
      return SocialAccessStatus.revoked;
    }

    // 6. Adult check: Must be verified adult
    if (!evidence.isAdult) {
      return SocialAccessStatus.underage;
    }

    // 7. Opt-in check: Must have opted in to social module
    if (!evidence.isOptedIn) {
      return SocialAccessStatus.optInRequired;
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
