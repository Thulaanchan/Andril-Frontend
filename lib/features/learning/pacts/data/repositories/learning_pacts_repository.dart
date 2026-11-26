import '../../domain/entities/learning_pact.dart';
import '../../domain/repositories/i_learning_pacts_repository.dart';

/// Concrete repository implementation for Learning Pacts (LRN-03).
///
/// Follows fail-closed governance:
/// - Defaults to [isBackendActivated] = false because the remote Pacts endpoints
///   remain pending in the active backend OpenAPI contract.
/// - Validates all inputs defensively.
/// - Never fabricates fake backend approvals, XP rewards, or communication permissions.
class LearningPactsRepository implements ILearningPactsRepository {
  /// Whether remote backend Pacts endpoints are active.
  final bool isBackendActivated;

  const LearningPactsRepository({
    this.isBackendActivated = false,
  });

  @override
  Future<LearningPactsResult<List<LearningPact>>> getPacts() async {
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPact.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    return const LearningPactsResult.success(<LearningPact>[]);
  }

  @override
  Future<LearningPactsResult<LearningPact>> getPactById(String pactId) async {
    final cleanId = pactId.trim();
    if (cleanId.isEmpty) {
      return const LearningPactsResult.failure(
        errorMessage: 'A pact identifier is required.',
        failureType: LearningPactsFailureType.validationError,
      );
    }
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPact.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Pact not found.',
      failureType: LearningPactsFailureType.notFound,
    );
  }

  @override
  Future<LearningPactsResult<LearningPact>> proposePact({
    required String title,
    required String sharedGoal,
    required String partnerProfileId,
    required String partnerDisplayName,
    String? partnerAvatarUrl,
    String? duration,
    String? studyPlan,
    Iterable<String>? commitmentTexts,
  }) async {
    final cleanTitle = title.trim();
    final cleanGoal = sharedGoal.trim();
    final cleanPartnerId = partnerProfileId.trim();
    final cleanPartnerName = partnerDisplayName.trim();

    if (cleanTitle.isEmpty ||
        cleanGoal.isEmpty ||
        cleanPartnerId.isEmpty ||
        cleanPartnerName.isEmpty) {
      return const LearningPactsResult.failure(
        errorMessage: 'Pact title, shared goal, and partner are required.',
        failureType: LearningPactsFailureType.validationError,
      );
    }

    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPact.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }

    return const LearningPactsResult.failure(
      errorMessage: 'Remote Pacts backend is currently inactive.',
      failureType: LearningPactsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningPactsResult<LearningPact>> acceptPact(String pactId) async {
    final cleanId = pactId.trim();
    if (cleanId.isEmpty) {
      return const LearningPactsResult.failure(
        errorMessage: 'A pact identifier is required.',
        failureType: LearningPactsFailureType.validationError,
      );
    }
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPact.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Remote Pacts backend is currently inactive.',
      failureType: LearningPactsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningPactsResult<LearningPact>> declinePact(String pactId) async {
    final cleanId = pactId.trim();
    if (cleanId.isEmpty) {
      return const LearningPactsResult.failure(
        errorMessage: 'A pact identifier is required.',
        failureType: LearningPactsFailureType.validationError,
      );
    }
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPact.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Remote Pacts backend is currently inactive.',
      failureType: LearningPactsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningPactsResult<LearningPact>> cancelPact(String pactId) async {
    final cleanId = pactId.trim();
    if (cleanId.isEmpty) {
      return const LearningPactsResult.failure(
        errorMessage: 'A pact identifier is required.',
        failureType: LearningPactsFailureType.validationError,
      );
    }
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPact.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Remote Pacts backend is currently inactive.',
      failureType: LearningPactsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningPactsResult<LearningPact>> withdrawPact(String pactId) async {
    final cleanId = pactId.trim();
    if (cleanId.isEmpty) {
      return const LearningPactsResult.failure(
        errorMessage: 'A pact identifier is required.',
        failureType: LearningPactsFailureType.validationError,
      );
    }
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPact.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Remote Pacts backend is currently inactive.',
      failureType: LearningPactsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningPactsResult<LearningPact>> confirmCompletion(
      String pactId) async {
    final cleanId = pactId.trim();
    if (cleanId.isEmpty) {
      return const LearningPactsResult.failure(
        errorMessage: 'A pact identifier is required.',
        failureType: LearningPactsFailureType.validationError,
      );
    }
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPact.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Remote Pacts backend is currently inactive.',
      failureType: LearningPactsFailureType.serviceUnavailable,
    );
  }

  @override
  Future<LearningPactsResult<LearningPact>> updateCommitmentProgress({
    required String pactId,
    required String commitmentId,
    required bool isCompleted,
  }) async {
    final cleanPactId = pactId.trim();
    final cleanCmtId = commitmentId.trim();
    if (cleanPactId.isEmpty || cleanCmtId.isEmpty) {
      return const LearningPactsResult.failure(
        errorMessage: 'Pact identifier and commitment identifier are required.',
        failureType: LearningPactsFailureType.validationError,
      );
    }
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPact.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Remote Pacts backend is currently inactive.',
      failureType: LearningPactsFailureType.serviceUnavailable,
    );
  }
}
