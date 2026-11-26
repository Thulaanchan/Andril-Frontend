import '../entities/learning_growth_evidence.dart';
import '../entities/learning_mentorship.dart';
import '../entities/learning_topic_gap.dart';

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

  /// Retrieves the list of topic gap explanations for the private dashboard.
  Future<LearningGrowthResult<List<LearningTopicGap>>> getTopicGaps();

  /// Retrieves a specific topic gap explanation by its identifier.
  Future<LearningGrowthResult<LearningTopicGap>> getTopicGapById(String gapId);

  /// Retrieves available voluntary mentorship offers.
  Future<LearningGrowthResult<List<LearningMentorshipOffer>>>
      getMentorshipOffers();

  /// Retrieves the learner's active, pending, or historical mentorship engagements.
  Future<LearningGrowthResult<List<LearningMentorship>>> getMentorships();

  /// Initiates a voluntary mentorship request to an available mentor offer.
  Future<LearningGrowthResult<LearningMentorship>> requestMentorship({
    required String offerId,
    required String learningGoal,
    required String message,
  });

  /// Transitions a pending mentorship to accepted (mentor action).
  Future<LearningGrowthResult<LearningMentorship>> acceptMentorship(
    String mentorshipId,
  );

  /// Transitions a pending mentorship to declined (mentor action).
  Future<LearningGrowthResult<LearningMentorship>> declineMentorship(
    String mentorshipId,
  );

  /// Transitions a pending mentorship to cancelled (learner action).
  Future<LearningGrowthResult<LearningMentorship>> cancelMentorship(
    String mentorshipId,
  );
}
