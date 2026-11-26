import '../../domain/entities/learning_circle.dart';
import '../../domain/repositories/i_learning_circles_repository.dart';

/// Production implementation of [ILearningCirclesRepository].
///
/// Follows fail-closed architectural requirements:
/// - Remote circles contracts remain dormant until backend OpenAPI v1 activation is formally authorized.
/// - Returns explicit [LearningCirclesFailureType.serviceUnavailable] rather than faking production mock data.
/// - Disconnected presentation mode displays an explicit in-app notice banner.
/// - Test fixtures belong in test suites only.
class LearningCirclesRepository implements ILearningCirclesRepository {
  /// Whether backend circle endpoints have been formally authorized and activated for live traffic.
  /// Defaults to false (dormant safe boundary).
  final bool isBackendActivated;

  /// Notice displayed when running under disconnected / pending backend contract.
  static const String disconnectedNotice =
      'Remote Groups backend contract pending in OpenAPI v1. Circles operate in local presentation mode.';

  const LearningCirclesRepository({
    this.isBackendActivated = false,
  });

  @override
  Future<LearningCirclesResult<List<LearningCircle>>> getCircles({
    String? category,
    String? query,
  }) async {
    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }

    return const LearningCirclesResult.failure(
      errorMessage: 'Learning circles service is currently unavailable.',
      failureType: LearningCirclesFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningCirclesResult<List<LearningCircle>>> getMyCircles() async {
    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }

    return const LearningCirclesResult.failure(
      errorMessage: 'Learning circles service is currently unavailable.',
      failureType: LearningCirclesFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningCirclesResult<LearningCircle>> createCircle({
    required String name,
    required String description,
    required String category,
    String? initialGoalText,
  }) async {
    final cleanName = name.trim();
    final cleanDesc = description.trim();
    if (cleanName.isEmpty || cleanDesc.isEmpty) {
      return const LearningCirclesResult.failure(
        errorMessage: 'Circle name and description are required.',
        failureType: LearningCirclesFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }

    return const LearningCirclesResult.failure(
      errorMessage: 'Learning circles service is currently unavailable.',
      failureType: LearningCirclesFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningCirclesResult<LearningCircle>> joinCircle(
    String circleId,
  ) async {
    final cleanId = circleId.trim();
    if (cleanId.isEmpty) {
      return const LearningCirclesResult.failure(
        errorMessage: 'Invalid circle ID.',
        failureType: LearningCirclesFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }

    return const LearningCirclesResult.failure(
      errorMessage: 'Learning circles service is currently unavailable.',
      failureType: LearningCirclesFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningCirclesResult<void>> leaveCircle(String circleId) async {
    final cleanId = circleId.trim();
    if (cleanId.isEmpty) {
      return const LearningCirclesResult.failure(
        errorMessage: 'Invalid circle ID.',
        failureType: LearningCirclesFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }

    return const LearningCirclesResult.failure(
      errorMessage: 'Learning circles service is currently unavailable.',
      failureType: LearningCirclesFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningCirclesResult<CircleSharedGoal>> addSharedGoal({
    required String circleId,
    required String goalText,
  }) async {
    final cleanId = circleId.trim();
    final cleanText = goalText.trim();
    if (cleanId.isEmpty || cleanText.isEmpty) {
      return const LearningCirclesResult.failure(
        errorMessage: 'Circle ID and goal text are required.',
        failureType: LearningCirclesFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }

    return const LearningCirclesResult.failure(
      errorMessage: 'Learning circles service is currently unavailable.',
      failureType: LearningCirclesFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningCirclesResult<CircleSharedGoal>> updateGoalProgress({
    required String circleId,
    required String goalId,
    required int progressPercent,
  }) async {
    final cleanCircleId = circleId.trim();
    final cleanGoalId = goalId.trim();
    if (cleanCircleId.isEmpty || cleanGoalId.isEmpty) {
      return const LearningCirclesResult.failure(
        errorMessage: 'Circle ID and goal ID are required.',
        failureType: LearningCirclesFailureType.badRequest,
      );
    }

    if (progressPercent < 0 || progressPercent > 100) {
      return const LearningCirclesResult.failure(
        errorMessage: 'Progress percent must be between 0 and 100.',
        failureType: LearningCirclesFailureType.badRequest,
      );
    }

    if (!isBackendActivated) {
      return const LearningCirclesResult.failure(
        errorMessage: disconnectedNotice,
        failureType: LearningCirclesFailureType.serviceUnavailable,
      );
    }

    return const LearningCirclesResult.failure(
      errorMessage: 'Learning circles service is currently unavailable.',
      failureType: LearningCirclesFailureType.serviceUnavailable,
    );
  }
}
