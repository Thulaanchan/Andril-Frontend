import '../../domain/entities/learning_partner_candidate.dart';
import '../../domain/entities/learning_partner_filters.dart';
import '../../domain/repositories/i_learning_discovery_repository.dart';

/// Production implementation of [ILearningDiscoveryRepository].
///
/// Follows fail-closed architectural requirements:
/// - Remote discovery contracts remain dormant until backend OpenAPI v1 activation is formally authorized.
/// - Returns explicit [LearningDiscoveryFailureType.serviceUnavailable] rather than faking production mock data.
/// - Disconnected / offline presentation mode displays an explicit in-app notice banner.
/// - Dummy fixtures belong in test suites only.
class LearningDiscoveryRepository implements ILearningDiscoveryRepository {
  /// Whether backend discovery endpoints have been formally authorized and activated for live traffic.
  /// Defaults to false (dormant safe boundary).
  final bool isBackendActivated;

  const LearningDiscoveryRepository({
    this.isBackendActivated = false,
  });

  @override
  Future<LearningDiscoveryResult<List<LearningPartnerCandidate>>>
      getCandidates({
    LearningPartnerFilters? filters,
    int offset = 0,
    int limit = 20,
  }) async {
    if (offset < 0 || limit <= 0) {
      return const LearningDiscoveryResult.failure(
        errorMessage: 'Invalid pagination arguments.',
        failureType: LearningDiscoveryFailureType.badRequest,
      );
    }

    // Dormant endpoint guard: do not invoke dormant production endpoints without authorization.
    if (!isBackendActivated) {
      return const LearningDiscoveryResult.failure(
        errorMessage:
            'Remote discovery backend contract pending in OpenAPI v1. Operating in local presentation mode.',
        failureType: LearningDiscoveryFailureType.serviceUnavailable,
      );
    }

    // Live remote HTTP transport via backend client executes here once activated.
    return const LearningDiscoveryResult.failure(
      errorMessage: 'Learning discovery service is currently unavailable.',
      failureType: LearningDiscoveryFailureType.serviceUnavailable,
    );
  }
}
