import '../entities/learning_pact.dart';

/// Explicit operational failure classifications for Learning Pacts (LRN-03).
enum LearningPactsFailureType {
  /// Session is unauthenticated or Learning profile is not activated.
  accessDenied,

  /// Target pact was not found.
  notFound,

  /// Validation constraint violated.
  validationError,

  /// Service is unavailable or remote contract is dormant/pending in OpenAPI v1.
  serviceUnavailable,

  /// General operational error.
  unknown,
}

/// Explicit result wrapper for Learning Pacts operations.
class LearningPactsResult<T> {
  final T? data;
  final String? errorMessage;
  final LearningPactsFailureType? failureType;
  final bool isSuccess;

  const LearningPactsResult.success(this.data)
      : errorMessage = null,
        failureType = null,
        isSuccess = true;

  const LearningPactsResult.failure({
    required this.errorMessage,
    required this.failureType,
  })  : data = null,
        isSuccess = false;

  bool get isFailure => !isSuccess;
}

/// Abstract contract defining Learning Pacts repository operations (LRN-03).
///
/// Follows fail-closed governance:
/// - Enforces voluntary mutual acceptance before any pact can activate.
/// - Validates participants and commitment terms.
/// - Never invents rewards, XP, study quotas, or communication permissions.
abstract class ILearningPactsRepository {
  /// Retrieves all Learning Pacts where the current user is a designated participant.
  Future<LearningPactsResult<List<LearningPact>>> getPacts();

  /// Retrieves a specific Learning Pact by its unique identifier.
  Future<LearningPactsResult<LearningPact>> getPactById(String pactId);

  /// Proposes a new Learning Pact between the current user and a selected partner.
  Future<LearningPactsResult<LearningPact>> proposePact({
    required String title,
    required String sharedGoal,
    required String partnerProfileId,
    required String partnerDisplayName,
    String? partnerAvatarUrl,
    String? duration,
    String? studyPlan,
    Iterable<String>? commitmentTexts,
  });

  /// Records the current user's voluntary acceptance of an incoming pact invitation.
  Future<LearningPactsResult<LearningPact>> acceptPact(String pactId);

  /// Records the current user's decision to decline an incoming pact invitation.
  Future<LearningPactsResult<LearningPact>> declinePact(String pactId);

  /// Cancels a pending pact proposal initiated by the current user.
  Future<LearningPactsResult<LearningPact>> cancelPact(String pactId);

  /// Explicitly withdraws the current user from an active pact, ending participation.
  Future<LearningPactsResult<LearningPact>> withdrawPact(String pactId);

  /// Records this participant's report of pact completion.
  Future<LearningPactsResult<LearningPact>> confirmCompletion(String pactId);

  /// Toggles self-reported completion of an agreed commitment milestone.
  Future<LearningPactsResult<LearningPact>> updateCommitmentProgress({
    required String pactId,
    required String commitmentId,
    required bool isCompleted,
  });
}
