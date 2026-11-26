import '../../domain/entities/learning_growth_evidence.dart';
import '../../domain/entities/learning_mentorship.dart';
import '../../domain/entities/learning_topic_gap.dart';
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

  @override
  Future<LearningGrowthResult<List<LearningTopicGap>>> getTopicGaps() async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningTopicGap.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    return const LearningGrowthResult.success(<LearningTopicGap>[]);
  }

  @override
  Future<LearningGrowthResult<LearningTopicGap>> getTopicGapById(
    String gapId,
  ) async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningTopicGap.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    final cleanId = gapId.trim();
    if (cleanId.isEmpty) {
      return const LearningGrowthResult.failure(
        errorMessage: 'Topic Gap ID cannot be empty.',
        failureType: LearningGrowthFailureType.validationError,
      );
    }
    return const LearningGrowthResult.failure(
      errorMessage: 'Topic gap record not found.',
      failureType: LearningGrowthFailureType.notFound,
    );
  }

  @override
  Future<LearningGrowthResult<List<LearningMentorshipOffer>>>
      getMentorshipOffers() async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    return const LearningGrowthResult.success(<LearningMentorshipOffer>[]);
  }

  @override
  Future<LearningGrowthResult<List<LearningMentorship>>>
      getMentorships() async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    return const LearningGrowthResult.success(<LearningMentorship>[]);
  }

  @override
  Future<LearningGrowthResult<LearningMentorship>> requestMentorship({
    required String offerId,
    required String learningGoal,
    required String message,
  }) async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    final cleanGoal = learningGoal.trim();
    final cleanMsg = message.trim();
    if (cleanGoal.isEmpty || cleanMsg.isEmpty) {
      return const LearningGrowthResult.failure(
        errorMessage: 'Learning goal and message are required.',
        failureType: LearningGrowthFailureType.validationError,
      );
    }
    final dummyOffer = LearningMentorshipOffer(
      id: offerId,
      mentor: LearningMentorshipParticipant(
        accountId: 'acc_dummy_mentor',
        learningProfileId: 'prof_dummy_mentor',
        displayName: 'Volunteer Mentor',
      ),
    );
    final mentorship = LearningMentorship.request(
      id: 'mentorship_${DateTime.now().millisecondsSinceEpoch}',
      learner: LearningMentorshipParticipant(
        accountId: 'acc_dummy_learner',
        learningProfileId: 'prof_dummy_learner',
        displayName: 'Current Learner',
      ),
      offer: dummyOffer,
      learningGoal: cleanGoal,
      message: cleanMsg,
    );
    return LearningGrowthResult.success(mentorship);
  }

  @override
  Future<LearningGrowthResult<LearningMentorship>> acceptMentorship(
    String mentorshipId,
  ) async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    return const LearningGrowthResult.failure(
      errorMessage: 'Mentorship record not found.',
      failureType: LearningGrowthFailureType.notFound,
    );
  }

  @override
  Future<LearningGrowthResult<LearningMentorship>> declineMentorship(
    String mentorshipId,
  ) async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    return const LearningGrowthResult.failure(
      errorMessage: 'Mentorship record not found.',
      failureType: LearningGrowthFailureType.notFound,
    );
  }

  @override
  Future<LearningGrowthResult<LearningMentorship>> cancelMentorship(
    String mentorshipId,
  ) async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    return const LearningGrowthResult.failure(
      errorMessage: 'Mentorship record not found.',
      failureType: LearningGrowthFailureType.notFound,
    );
  }
}
