import '../../domain/entities/learning_connection.dart';
import '../../domain/entities/learning_connection_request.dart';
import '../../domain/repositories/i_learning_connections_repository.dart';

/// Production implementation of [ILearningConnectionsRepository].
///
/// Follows fail-closed architectural requirements:
/// - Remote connections contracts remain dormant until backend OpenAPI v1 activation is formally authorized.
/// - Returns explicit [LearningConnectionsFailureType.serviceUnavailable] rather than faking production mock data.
/// - Disconnected presentation mode displays an explicit in-app notice banner.
/// - Test fixtures belong in test suites only.
class LearningConnectionsRepository implements ILearningConnectionsRepository {
  /// Whether backend connection endpoints have been formally authorized and activated for live traffic.
  /// Defaults to false (dormant safe boundary).
  final bool isBackendActivated;

  /// Notice displayed when running under disconnected / pending backend contract.
  static const String disconnectedNotice =
      'Remote connections backend contract pending in OpenAPI v1. Operating in local presentation mode.';

  const LearningConnectionsRepository({
    this.isBackendActivated = false,
  });

  @override
  Future<LearningConnectionsResult<List<LearningConnection>>>
      getConnections() async {
    if (!isBackendActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }

    return const LearningConnectionsResult.failure(
      errorMessage: 'Learning connections service is currently unavailable.',
      failureType: LearningConnectionsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningConnectionsResult<List<LearningConnectionRequest>>>
      getIncomingRequests() async {
    if (!isBackendActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }

    return const LearningConnectionsResult.failure(
      errorMessage: 'Learning requests service is currently unavailable.',
      failureType: LearningConnectionsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningConnectionsResult<List<LearningConnectionRequest>>>
      getOutgoingRequests() async {
    if (!isBackendActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }

    return const LearningConnectionsResult.failure(
      errorMessage: 'Learning requests service is currently unavailable.',
      failureType: LearningConnectionsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> sendRequest({
    required String recipientProfileId,
    required String recipientDisplayName,
    Iterable<String>? recipientSkills,
    String? note,
  }) async {
    final trimmedId = recipientProfileId.trim();
    if (trimmedId.isEmpty) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Invalid recipient profile ID.',
        failureType: LearningConnectionsFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }

    return const LearningConnectionsResult.failure(
      errorMessage: 'Learning connection service is currently unavailable.',
      failureType: LearningConnectionsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> acceptRequest(
    String requestId,
  ) async {
    final trimmedId = requestId.trim();
    if (trimmedId.isEmpty) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Invalid request ID.',
        failureType: LearningConnectionsFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }

    return const LearningConnectionsResult.failure(
      errorMessage: 'Learning connection service is currently unavailable.',
      failureType: LearningConnectionsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> declineRequest(
    String requestId,
  ) async {
    final trimmedId = requestId.trim();
    if (trimmedId.isEmpty) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Invalid request ID.',
        failureType: LearningConnectionsFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }

    return const LearningConnectionsResult.failure(
      errorMessage: 'Learning connection service is currently unavailable.',
      failureType: LearningConnectionsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> cancelRequest(
    String requestId,
  ) async {
    final trimmedId = requestId.trim();
    if (trimmedId.isEmpty) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Invalid request ID.',
        failureType: LearningConnectionsFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }

    return const LearningConnectionsResult.failure(
      errorMessage: 'Learning connection service is currently unavailable.',
      failureType: LearningConnectionsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningConnectionsResult<void>> removeConnection(
    String connectionId,
  ) async {
    final trimmedId = connectionId.trim();
    if (trimmedId.isEmpty) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Invalid connection ID.',
        failureType: LearningConnectionsFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }

    return const LearningConnectionsResult.failure(
      errorMessage: 'Learning connection service is currently unavailable.',
      failureType: LearningConnectionsFailureType.serviceUnavailable,
    );
  }
}
