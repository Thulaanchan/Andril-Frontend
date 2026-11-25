import 'package:flutter/foundation.dart';
import '../domain/social_candidate.dart';

/// Sealed failure categorization for Social Discovery operations.
enum DiscoveryFailureType {
  /// Session missing or caller not authorized (401/403).
  unauthorized,

  /// Target endpoint is dormant or service currently unavailable (503/404).
  serviceUnavailable,

  /// Client-side invalid argument or bad request (400).
  badRequest,

  /// Network timeout or unexpected connectivity breakdown.
  networkError,

  /// Unknown or unexpected exception sanitized for caller consumption.
  unknown,
}

/// Typed result container representing either a successful data payload or a sanitized failure.
@immutable
class DiscoveryResult<T> {
  final T? data;
  final String? errorMessage;
  final DiscoveryFailureType? failureType;
  final bool isSuccess;

  const DiscoveryResult.success(this.data)
      : errorMessage = null,
        failureType = null,
        isSuccess = true;

  const DiscoveryResult.failure({
    required this.errorMessage,
    required this.failureType,
  })  : data = null,
        isSuccess = false;

  bool get isFailure => !isSuccess;
}

/// Lightweight model capturing the outcome of recording directional interest (CF-20).
@immutable
class SocialInterestResult {
  final bool success;
  final bool matchCreated;
  final String? matchId;
  final String visibleState;

  const SocialInterestResult({
    required this.success,
    required this.matchCreated,
    this.matchId,
    required this.visibleState,
  });

  factory SocialInterestResult.fromJson(Map<String, dynamic> json) {
    return SocialInterestResult(
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
      other is SocialInterestResult &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          matchCreated == other.matchCreated &&
          matchId == other.matchId &&
          visibleState == other.visibleState;

  @override
  int get hashCode => Object.hash(success, matchCreated, matchId, visibleState);

  @override
  String toString() =>
      'SocialInterestResult(success: $success, matched: $matchCreated, matchId: $matchId, state: $visibleState)';
}

/// Authoritative repository interface for Social Ranked Discovery and Decisions.
abstract class ISocialDiscoveryRepository {
  /// Fetches a ranked, privacy-safe explore feed for the authenticated caller.
  Future<DiscoveryResult<List<SocialCandidate>>> getExploreFeed({
    int rotationOffset = 0,
    int limit = 20,
  });

  /// Records directional interest (Like = true, Pass = false) toward a target candidate.
  Future<DiscoveryResult<SocialInterestResult>> recordInterest({
    required String targetProfileId,
    required bool isPositive,
  });
}

/// Production implementation of [ISocialDiscoveryRepository].
///
/// Follows M5-FE-S09-DATA-01 requirements:
/// - Fails closed: Discovery endpoints remain dormant until backend activation is formally authorized.
/// - Returns explicit [DiscoveryFailureType.serviceUnavailable] rather than faking production mock data.
/// - Sanitizes all error messages to protect privacy and internal system state.
class SocialDiscoveryRepository implements ISocialDiscoveryRepository {
  /// Whether backend discovery endpoints have been formally authorized for live network traffic.
  /// Defaults to false (dormant safe boundary).
  final bool isBackendActivated;

  const SocialDiscoveryRepository({
    this.isBackendActivated = false,
  });

  @override
  Future<DiscoveryResult<List<SocialCandidate>>> getExploreFeed({
    int rotationOffset = 0,
    int limit = 20,
  }) async {
    if (rotationOffset < 0 || limit <= 0) {
      return const DiscoveryResult.failure(
        errorMessage: 'Invalid pagination arguments.',
        failureType: DiscoveryFailureType.badRequest,
      );
    }

    // Dormant endpoint guard: do not invoke dormant production endpoints without authorization.
    if (!isBackendActivated) {
      return const DiscoveryResult.failure(
        errorMessage: 'Social discovery service is currently preparing and unavailable.',
        failureType: DiscoveryFailureType.serviceUnavailable,
      );
    }

    // When backend activation is authorized, HTTP request via AndrilApiClient executes here.
    return const DiscoveryResult.failure(
      errorMessage: 'Social discovery service is currently unavailable.',
      failureType: DiscoveryFailureType.serviceUnavailable,
    );
  }

  @override
  Future<DiscoveryResult<SocialInterestResult>> recordInterest({
    required String targetProfileId,
    required bool isPositive,
  }) async {
    if (targetProfileId.trim().isEmpty) {
      return const DiscoveryResult.failure(
        errorMessage: 'Target profile ID must not be empty.',
        failureType: DiscoveryFailureType.badRequest,
      );
    }

    // Dormant endpoint guard.
    if (!isBackendActivated) {
      return const DiscoveryResult.failure(
        errorMessage: 'Social relationship service is currently preparing and unavailable.',
        failureType: DiscoveryFailureType.serviceUnavailable,
      );
    }

    return const DiscoveryResult.failure(
      errorMessage: 'Social relationship service is currently unavailable.',
      failureType: DiscoveryFailureType.serviceUnavailable,
    );
  }
}
