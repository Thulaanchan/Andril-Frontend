import '../entities/learning_circle.dart';

/// Categorized failure reasons for Learning Circles operations.
enum LearningCirclesFailureType {
  /// Session is unauthenticated or invalid.
  unauthorized,

  /// Learning profile has not been activated or lacks permission.
  accessDenied,

  /// Target circle or goal was not found.
  notFound,

  /// User is already a member or duplicate goal conflict.
  conflict,

  /// Remote backend endpoint is dormant, pending OpenAPI v1 contract, or unreachable.
  serviceUnavailable,

  /// Invalid parameters or request formatting.
  badRequest,

  /// Transient network transport error.
  networkError,

  /// An unclassified or unexpected error occurred.
  unknown,
}

/// Generic outcome wrapper for Learning Circles domain operations.
class LearningCirclesResult<T> {
  final T? data;
  final String? errorMessage;
  final LearningCirclesFailureType? failureType;
  final bool isSuccess;

  const LearningCirclesResult.success(this.data)
      : errorMessage = null,
        failureType = null,
        isSuccess = true;

  const LearningCirclesResult.failure({
    required this.errorMessage,
    required this.failureType,
  })  : data = null,
        isSuccess = false;

  bool get isFailure => !isSuccess;
}

/// Abstract contract defining Learning Circles repository capabilities (CF-07, LRN-02).
///
/// Follows fail-closed governance:
/// - Distinguishes between public discoverable circles and enrolled "My Circles".
/// - Supports authorized circle creation, joining, leaving, and shared goal progress updates.
/// - Returns explicit [LearningCirclesResult] outcomes; never fabricates dummy success.
abstract class ILearningCirclesRepository {
  /// Retrieves discoverable learning circles with optional category and query filtering.
  Future<LearningCirclesResult<List<LearningCircle>>> getCircles({
    String? category,
    String? query,
  });

  /// Retrieves circles where current user is an enrolled member or facilitator.
  Future<LearningCirclesResult<List<LearningCircle>>> getMyCircles();

  /// Authoritatively creates a new Learning Circle.
  Future<LearningCirclesResult<LearningCircle>> createCircle({
    required String name,
    required String description,
    required String category,
    String? initialGoalText,
  });

  /// Authoritatively joins an existing Learning Circle.
  Future<LearningCirclesResult<LearningCircle>> joinCircle(String circleId);

  /// Authoritatively leaves an enrolled Learning Circle.
  Future<LearningCirclesResult<void>> leaveCircle(String circleId);

  /// Adds a collaborative shared goal to a Circle.
  Future<LearningCirclesResult<CircleSharedGoal>> addSharedGoal({
    required String circleId,
    required String goalText,
  });

  /// Updates manually self-reported progress for a shared goal (0..100).
  Future<LearningCirclesResult<CircleSharedGoal>> updateGoalProgress({
    required String circleId,
    required String goalId,
    required int progressPercent,
  });
}
