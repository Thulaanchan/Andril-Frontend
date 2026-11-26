import '../../discovery/data/social_discovery_repository.dart';
import '../domain/social_relationship.dart';

/// Authoritative repository interface for Social dating relationships, likes, and mutual matches.
abstract class ISocialRelationshipRepository {
  /// Fetches received dating interest ('likes') for the authenticated caller (S43).
  Future<DiscoveryResult<List<SocialRelationship>>> getReceivedLikes({
    int page = 0,
    int pageSize = 20,
  });

  /// Fetches sent dating interest for the authenticated caller (S11).
  Future<DiscoveryResult<List<SocialRelationship>>> getSentLikes({
    int page = 0,
    int pageSize = 20,
  });

  /// Fetches confirmed active connections for the authenticated caller (S13).
  Future<DiscoveryResult<List<SocialRelationship>>> getConnections({
    SocialConnectionCategory category = SocialConnectionCategory.all,
    int page = 0,
    int pageSize = 20,
  });

  /// Retrieves privacy-preserving relationship standing with a target candidate.
  Future<DiscoveryResult<SocialRelationshipStatusResult>> getRelationshipStatus({
    required String targetProfileId,
  });

  /// Records caller directional interest toward a candidate profile (CF-20).
  Future<DiscoveryResult<SocialRelationshipOperationResult>> recordInterest({
    required String targetProfileId,
    required bool isPositive,
  });

  /// Revokes an active mutual match (unmatch) between participants.
  Future<DiscoveryResult<SocialRevocationResult>> revokeMatch({
    required String targetProfileId,
  });
}

/// Production implementation of [ISocialRelationshipRepository].
///
/// Follows M5-FE-S12/S13 relationship data governance:
/// - Fails closed: relationship endpoints remain dormant until backend activation is formally authorized.
/// - Returns explicit [DiscoveryFailureType.serviceUnavailable] rather than faking production mock data.
/// - Sanitizes all error messages to protect privacy and internal system state.
class SocialRelationshipRepository implements ISocialRelationshipRepository {
  /// Whether backend relationship endpoints have been formally authorized for live network traffic.
  /// Defaults to false (dormant-safe boundary).
  final bool isBackendActivated;

  const SocialRelationshipRepository({
    this.isBackendActivated = false,
  });

  @override
  Future<DiscoveryResult<List<SocialRelationship>>> getReceivedLikes({
    int page = 0,
    int pageSize = 20,
  }) async {
    if (page < 0 || pageSize <= 0) {
      return const DiscoveryResult.failure(
        errorMessage: 'Invalid pagination arguments.',
        failureType: DiscoveryFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const DiscoveryResult.failure(
        errorMessage: 'Received likes service is currently preparing and unavailable.',
        failureType: DiscoveryFailureType.serviceUnavailable,
      );
    }

    return const DiscoveryResult.failure(
      errorMessage: 'Received likes service is currently unavailable.',
      failureType: DiscoveryFailureType.serviceUnavailable,
    );
  }

  @override
  Future<DiscoveryResult<List<SocialRelationship>>> getSentLikes({
    int page = 0,
    int pageSize = 20,
  }) async {
    if (page < 0 || pageSize <= 0) {
      return const DiscoveryResult.failure(
        errorMessage: 'Invalid pagination arguments.',
        failureType: DiscoveryFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const DiscoveryResult.failure(
        errorMessage: 'Sent likes service is currently preparing and unavailable.',
        failureType: DiscoveryFailureType.serviceUnavailable,
      );
    }

    return const DiscoveryResult.failure(
      errorMessage: 'Sent likes service is currently unavailable.',
      failureType: DiscoveryFailureType.serviceUnavailable,
    );
  }

  @override
  Future<DiscoveryResult<List<SocialRelationship>>> getConnections({
    SocialConnectionCategory category = SocialConnectionCategory.all,
    int page = 0,
    int pageSize = 20,
  }) async {
    if (page < 0 || pageSize <= 0) {
      return const DiscoveryResult.failure(
        errorMessage: 'Invalid pagination arguments.',
        failureType: DiscoveryFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const DiscoveryResult.failure(
        errorMessage: 'Connections service is currently preparing and unavailable.',
        failureType: DiscoveryFailureType.serviceUnavailable,
      );
    }

    return const DiscoveryResult.failure(
      errorMessage: 'Connections service is currently unavailable.',
      failureType: DiscoveryFailureType.serviceUnavailable,
    );
  }

  @override
  Future<DiscoveryResult<SocialRelationshipStatusResult>> getRelationshipStatus({
    required String targetProfileId,
  }) async {
    if (targetProfileId.trim().isEmpty) {
      return const DiscoveryResult.failure(
        errorMessage: 'Target profile ID must not be empty.',
        failureType: DiscoveryFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const DiscoveryResult.failure(
        errorMessage: 'Relationship status service is currently preparing and unavailable.',
        failureType: DiscoveryFailureType.serviceUnavailable,
      );
    }

    return const DiscoveryResult.failure(
      errorMessage: 'Relationship status service is currently unavailable.',
      failureType: DiscoveryFailureType.serviceUnavailable,
    );
  }

  @override
  Future<DiscoveryResult<SocialRelationshipOperationResult>> recordInterest({
    required String targetProfileId,
    required bool isPositive,
  }) async {
    if (targetProfileId.trim().isEmpty) {
      return const DiscoveryResult.failure(
        errorMessage: 'Target profile ID must not be empty.',
        failureType: DiscoveryFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const DiscoveryResult.failure(
        errorMessage: 'Relationship interest service is currently preparing and unavailable.',
        failureType: DiscoveryFailureType.serviceUnavailable,
      );
    }

    return const DiscoveryResult.failure(
      errorMessage: 'Relationship interest service is currently unavailable.',
      failureType: DiscoveryFailureType.serviceUnavailable,
    );
  }

  @override
  Future<DiscoveryResult<SocialRevocationResult>> revokeMatch({
    required String targetProfileId,
  }) async {
    if (targetProfileId.trim().isEmpty) {
      return const DiscoveryResult.failure(
        errorMessage: 'Target profile ID must not be empty.',
        failureType: DiscoveryFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const DiscoveryResult.failure(
        errorMessage: 'Relationship revocation service is currently preparing and unavailable.',
        failureType: DiscoveryFailureType.serviceUnavailable,
      );
    }

    return const DiscoveryResult.failure(
      errorMessage: 'Relationship revocation service is currently unavailable.',
      failureType: DiscoveryFailureType.serviceUnavailable,
    );
  }
}
