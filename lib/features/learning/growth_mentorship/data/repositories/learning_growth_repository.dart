import '../../domain/entities/learning_growth_evidence.dart';
import '../../domain/repositories/i_learning_growth_repository.dart';

/// Concrete implementation of [ILearningGrowthRepository] (LRN-04).
///
/// Follows fail-closed governance:
/// - Defaults to [isBackendActivated] = false (pending OpenAPI v1 contract).
/// - Operates in local presentation mode with explicit user-facing notice banner.
/// - Never invents verified claims without authorized external verification provenance.
class LearningGrowthRepository implements ILearningGrowthRepository {
  /// Whether the remote backend contract is active. Defaults to false.
  final bool isBackendActivated;

  const LearningGrowthRepository({
    this.isBackendActivated = false,
  });

  @override
  Future<LearningGrowthResult<LearningGrowthSummary>> getGrowthSummary() async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    return const LearningGrowthResult.success(LearningGrowthSummary());
  }

  @override
  Future<LearningGrowthResult<List<LearningGrowthEvidence>>> getEvidenceList({
    LearningEvidenceKind? kindFilter,
    String? skillId,
  }) async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    return const LearningGrowthResult.success(<LearningGrowthEvidence>[]);
  }

  @override
  Future<LearningGrowthResult<LearningGrowthEvidence>> getEvidenceById(
    String evidenceId,
  ) async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    final cleanId = evidenceId.trim();
    if (cleanId.isEmpty) {
      return const LearningGrowthResult.failure(
        errorMessage: 'Evidence ID cannot be empty.',
        failureType: LearningGrowthFailureType.validationError,
      );
    }
    return const LearningGrowthResult.failure(
      errorMessage: 'Evidence record not found.',
      failureType: LearningGrowthFailureType.notFound,
    );
  }

  @override
  Future<LearningGrowthResult<List<LearningTrackedSkill>>>
      getTrackedSkills() async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    return const LearningGrowthResult.success(<LearningTrackedSkill>[]);
  }

  @override
  Future<LearningGrowthResult<LearningGrowthEvidence>>
      recordSelfReportedEvidence({
    required String title,
    required String description,
    Iterable<String>? skillIds,
    Iterable<String>? skillNames,
    String? sourceReference,
  }) async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();
    if (cleanTitle.isEmpty || cleanDesc.isEmpty) {
      return const LearningGrowthResult.failure(
        errorMessage: 'Title and description are required.',
        failureType: LearningGrowthFailureType.validationError,
      );
    }

    final newEvidence = LearningGrowthEvidence.recordSelfReport(
      id: 'ev_${DateTime.now().millisecondsSinceEpoch}',
      accountId: 'current_acc',
      learningProfileId: 'current_prof',
      title: cleanTitle,
      description: cleanDesc,
      skillIds: skillIds,
      skillNames: skillNames,
      sourceReference: sourceReference,
    );
    return LearningGrowthResult.success(newEvidence);
  }
}
