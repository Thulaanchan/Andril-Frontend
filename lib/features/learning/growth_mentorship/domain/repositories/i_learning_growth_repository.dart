import '../entities/learning_growth_evidence.dart';

/// Operational failure classifications for Learning Growth operations (LRN-04).
enum LearningGrowthFailureType {
  /// Session is unauthenticated or Learning profile is not activated.
  accessDenied,

  /// Target evidence or skill record was not found.
  notFound,

  /// Validation constraint violated.
  validationError,

  /// Service is unavailable or remote contract is dormant/pending in OpenAPI v1.
  serviceUnavailable,

  /// General operational error.
  unknown,
}

/// Explicit result wrapper for Learning Growth operations.
class LearningGrowthResult<T> {
  final T? data;
  final String? errorMessage;
  final LearningGrowthFailureType? failureType;
  final bool isSuccess;

  const LearningGrowthResult.success(this.data)
      : errorMessage = null,
        failureType = null,
        isSuccess = true;

  const LearningGrowthResult.failure({
    required this.errorMessage,
    required this.failureType,
  })  : data = null,
        isSuccess = false;

  bool get isFailure => !isSuccess;
}

/// Abstract contract governing Learning Growth Dashboard repository operations (LRN-04).
///
/// Follows fail-closed governance:
/// - Enforces private default visibility.
/// - Never invents XP rewards, assessment scores, or certification claims.
/// - Clearly distinguishes verified-source from self-reported evidence.
abstract class ILearningGrowthRepository {
  /// Retrieves the aggregate growth summary for the private overview.
  Future<LearningGrowthResult<LearningGrowthSummary>> getGrowthSummary();

  /// Retrieves the list of recorded learning evidence records.
  Future<LearningGrowthResult<List<LearningGrowthEvidence>>> getEvidenceList({
    LearningEvidenceKind? kindFilter,
    String? skillId,
  });

  /// Retrieves a specific evidence record by its unique identifier.
  Future<LearningGrowthResult<LearningGrowthEvidence>> getEvidenceById(
    String evidenceId,
  );

  /// Retrieves the list of tracked skills and their evidence sufficiency status.
  Future<LearningGrowthResult<List<LearningTrackedSkill>>> getTrackedSkills();

  /// Records self-reported evidence voluntarily declared by the learner.
  Future<LearningGrowthResult<LearningGrowthEvidence>>
      recordSelfReportedEvidence({
    required String title,
    required String description,
    Iterable<String>? skillIds,
    Iterable<String>? skillNames,
    String? sourceReference,
  });
}
