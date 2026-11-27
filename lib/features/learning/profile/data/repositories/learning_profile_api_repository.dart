import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../../domain/entities/learning_preferences.dart';
import '../../domain/entities/learning_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/learning_remote_data_source.dart';
import '../models/learning_setup_snapshot_dto.dart';

/// Concrete implementation of [ProfileRepository] backed by approved backend APIs.
///
/// Under security and privacy constraints (BRD §04.1-04.3, docs/SECURITY_BOUNDARIES.md),
/// operations derive identity strictly from the verified session context. The repository
/// never accepts caller-supplied profile IDs that could bypass backend ownership validation.
class LearningProfileApiRepository implements ProfileRepository {
  final SessionController _sessionController;
  final ILearningRemoteDataSource _remoteDataSource;

  // Local draft cache for disconnected or offline resilience.
  LearningProfile? _cachedDraft;

  LearningProfileApiRepository({
    required SessionController sessionController,
    required ILearningRemoteDataSource remoteDataSource,
  })  : _sessionController = sessionController,
        _remoteDataSource = remoteDataSource;

  @override
  Future<ProfileResult<LearningProfile>> getProfile() async {
    final session = _validateSession();
    if (session == null) {
      if (_cachedDraft != null) {
        return ProfileSuccess(_cachedDraft!);
      }
      return const ProfileAccessDenied();
    }

    try {
      final profileDraftJson = await _remoteDataSource.getProfileDraft(session);
      final displayName = profileDraftJson['displayName']?.toString() ??
          _sessionController.subject ??
          'Learner';
      final bio = profileDraftJson['bio']?.toString();

      // Read setup snapshot to enrich skills and goals
      LearningSetupSnapshotDto? setupSnapshot;
      try {
        setupSnapshot = await _remoteDataSource.getLearningSetup(session);
      } catch (_) {
        // Setup read failure should not block core profile read
      }

      final profile = LearningProfile(
        profileId: _sessionController.subject ?? 'learning_profile_id',
        accountId: _sessionController.subject ?? 'acc_default',
        module: LearningProfile.moduleScope,
        displayName: displayName,
        bio: bio,
        skillsToLearn: setupSnapshot?.learningSkills ?? const [],
        skillsToShare: setupSnapshot?.teachingSkills ?? const [],
        learningGoals:
            setupSnapshot?.goals.map((g) => g.text).toList() ?? const [],
        preferences: const LearningPreferences(),
        isActivated: true,
      );

      _cachedDraft = profile;
      return ProfileSuccess(profile);
    } on HandoffFailure catch (failure) {
      return _mapHandoffFailure(failure);
    } catch (e) {
      if (_cachedDraft != null) {
        return ProfileSuccess(_cachedDraft!);
      }
      return ProfileFailure('Failed to load learning profile', e);
    }
  }

  @override
  Future<ProfileResult<LearningProfile>> updateProfile(
      LearningProfile profile) async {
    if (profile.module != LearningProfile.moduleScope) {
      return const ProfileFailure(
        'Module mismatch: profile must belong to "learning" module',
      );
    }

    final session = _validateSession();
    if (session == null) {
      _cachedDraft = profile;
      return ProfileSuccess(profile);
    }

    // Verify caller identity matches profile ownership
    final currentUserId = _sessionController.subject;
    if (currentUserId != null &&
        profile.accountId != currentUserId &&
        profile.profileId != currentUserId) {
      return const ProfileAccessDenied(
        'Access denied: caller does not own this learning profile',
      );
    }

    try {
      await _remoteDataSource.updateProfileDraft(
        session: session,
        displayName: profile.displayName,
        bio: profile.bio,
      );

      _cachedDraft = profile;
      return ProfileSuccess(profile);
    } on HandoffFailure catch (failure) {
      return _mapHandoffFailure(failure);
    } catch (e) {
      return ProfileFailure('Failed to update learning profile', e);
    }
  }

  @override
  Future<ProfileResult<LearningProfile>> saveDraftProfile({
    required String displayName,
    List<String> skillsToLearn = const [],
    List<String> skillsToShare = const [],
    List<String> learningGoals = const [],
  }) async {
    final currentUserId = _sessionController.subject ?? 'local_user';
    final draft = LearningProfile(
      profileId: currentUserId,
      accountId: currentUserId,
      module: LearningProfile.moduleScope,
      displayName: displayName,
      skillsToLearn: skillsToLearn,
      skillsToShare: skillsToShare,
      learningGoals: learningGoals,
      preferences: const LearningPreferences(),
      isActivated: false,
    );

    _cachedDraft = draft;

    final session = _validateSession();
    if (session != null) {
      try {
        await _remoteDataSource.updateProfileDraft(
          session: session,
          displayName: displayName,
        );
      } catch (_) {
        // Retained locally in _cachedDraft if network update fails
      }
    }

    return ProfileSuccess(draft);
  }

  BackendSession? _validateSession() {
    if (_sessionController.phase != SessionPhase.signedIn) return null;
    return _sessionController.backendSession;
  }

  ProfileResult<LearningProfile> _mapHandoffFailure(HandoffFailure failure) {
    switch (failure.issue) {
      case HandoffIssue.reauthenticationRequired:
      case HandoffIssue.forbidden:
      case HandoffIssue.verificationRequired:
      case HandoffIssue.sessionChanged:
        return const ProfileAccessDenied();
      case HandoffIssue.accountNotInitialized:
        return const ProfileNotFound();
      case HandoffIssue.unavailable:
      case HandoffIssue.rateLimited:
        return const ProfileDependencyUnavailable();
      case HandoffIssue.badRequest:
      case HandoffIssue.conflict:
      case HandoffIssue.invalidResponse:
        return ProfileFailure('Server error: ${failure.issue.name}');
    }
  }
}
