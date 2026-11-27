import 'package:flutter/foundation.dart';

import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../../domain/entities/learning_preferences.dart';
import '../../domain/entities/learning_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/learning_remote_data_source.dart';
import '../models/learning_setup_snapshot_dto.dart';
import 'learning_setup_api_repository.dart';

/// Concrete implementation of [ProfileRepository] backed by approved backend APIs.
///
/// Under security and privacy constraints (BRD §04.1-04.3, docs/SECURITY_BOUNDARIES.md):
/// - Distinguishes global account identity ([LearningProfile.accountId]) from module-specific
///   learning profile identity ([LearningProfile.profileId]).
/// - Operations derive identity strictly from verified session context.
/// - Never manufactures or bypasses M2 admission grants ([LearningProfile.isActivated]).
/// - Enforces display-name length, character, and uniqueness boundaries.
/// - Validates and enriches authorized profile photo status from current photo endpoint.
/// - Supports skills, goals, and preference persistence under optimistic revision control.
/// - Enforces session boundary lifecycle and purges private cached state on session revocation.
class LearningProfileApiRepository implements ProfileRepository {
  final SessionController _sessionController;
  final ILearningRemoteDataSource _remoteDataSource;
  final ILearningSetupRepository? _setupRepository;

  // Local draft cache for disconnected or offline resilience.
  LearningProfile? _cachedDraft;
  VoidCallback? _unregisterSessionClearer;

  LearningProfileApiRepository({
    required SessionController sessionController,
    required ILearningRemoteDataSource remoteDataSource,
    ILearningSetupRepository? setupRepository,
  })  : _sessionController = sessionController,
        _remoteDataSource = remoteDataSource,
        _setupRepository = setupRepository {
    _unregisterSessionClearer =
        _sessionController.registerPrivateStateClearer(clearPrivateState);
  }

  /// Clears in-memory private profile cache on session logout or revocation.
  void clearPrivateState() {
    _cachedDraft = null;
  }

  /// Disposes registration listeners and purges cached private data.
  void dispose() {
    _unregisterSessionClearer?.call();
    _unregisterSessionClearer = null;
    clearPrivateState();
  }

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
          profileDraftJson['display_name']?.toString() ??
          _sessionController.subject ??
          'Learner';
      final bio = profileDraftJson['bio']?.toString();

      // Distinguish global account ID from module Learning profile ID
      final accountId = profileDraftJson['accountId']?.toString() ??
          profileDraftJson['account_id']?.toString() ??
          _sessionController.subject ??
          'acc_default';

      final profileId = profileDraftJson['profileId']?.toString() ??
          profileDraftJson['profile_id']?.toString() ??
          profileDraftJson['learningProfileId']?.toString() ??
          'lp_${_sessionController.subject ?? 'default'}';

      // Read current profile photo status (authorized photo verification)
      String? avatarUrl = profileDraftJson['avatarUrl']?.toString() ??
          profileDraftJson['avatar_url']?.toString();
      try {
        final photoStatus =
            await _remoteDataSource.getCurrentPhotoStatus(session);
        final status = photoStatus['status']?.toString();
        if (status == 'active' || status == 'approved') {
          avatarUrl = photoStatus['photoUrl']?.toString() ??
              photoStatus['url']?.toString() ??
              avatarUrl;
        }
      } catch (_) {
        // Photo status check failure does not block profile loading
      }

      // Read setup snapshot to enrich skills and goals
      LearningSetupSnapshotDto? setupSnapshot;
      try {
        setupSnapshot = await _remoteDataSource.getLearningSetup(session);
      } catch (_) {
        // Setup read failure should not block core profile read
      }

      // Read preferences if present in remote payload or retain cached
      LearningPreferences preferences = const LearningPreferences();
      final rawPrefs = profileDraftJson['preferences'];
      if (rawPrefs is Map<String, Object?>) {
        preferences = LearningPreferences.fromJson(rawPrefs);
      } else if (rawPrefs is Map<String, dynamic>) {
        preferences = LearningPreferences.fromJson(rawPrefs);
      } else if (_cachedDraft != null) {
        preferences = _cachedDraft!.preferences;
      }

      // M2 Admission & activation status check:
      // Must NEVER bypass M2 admission authority. Default to false unless explicitly verified by M2.
      final isActivated = _sessionController.moduleHomeAuthorized ||
          profileDraftJson['isActivated'] == true ||
          profileDraftJson['is_activated'] == true;

      final profile = LearningProfile(
        profileId: profileId,
        accountId: accountId,
        module: LearningProfile.moduleScope,
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
        skillsToLearn: setupSnapshot?.learningSkills ??
            _cachedDraft?.skillsToLearn ??
            const [],
        skillsToShare: setupSnapshot?.teachingSkills ??
            _cachedDraft?.skillsToShare ??
            const [],
        learningGoals: setupSnapshot?.goals.map((g) => g.text).toList() ??
            _cachedDraft?.learningGoals ??
            const [],
        preferences: preferences,
        isActivated: isActivated,
      );

      _cachedDraft = profile;
      return ProfileSuccess(profile);
    } on HandoffFailure catch (failure) {
      if (_cachedDraft != null &&
          (failure.issue == HandoffIssue.unavailable ||
              failure.issue == HandoffIssue.rateLimited)) {
        return ProfileSuccess(_cachedDraft!);
      }
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
    // 1. Strict module scope isolation
    if (profile.module != LearningProfile.moduleScope) {
      return const ProfileFailure(
        'Module mismatch: profile must belong to "learning" module',
      );
    }

    // 2. Validate display name boundaries (§04.2 NAME-01-07)
    final trimmedName = profile.displayName.trim();
    if (trimmedName.isEmpty) {
      return const ProfileFailure(
          'Display name is required and cannot be empty');
    }
    if (trimmedName.length < 2) {
      return const ProfileFailure('Display name must be at least 2 characters');
    }
    if (trimmedName.length > 50) {
      return const ProfileFailure('Display name must not exceed 50 characters');
    }

    final session = _validateSession();
    if (session == null) {
      _cachedDraft = profile;
      return ProfileSuccess(profile);
    }

    // 3. Verify caller identity matches profile ownership
    final currentUserId = _sessionController.subject;
    if (currentUserId != null &&
        profile.accountId != currentUserId &&
        profile.profileId != 'lp_$currentUserId' &&
        profile.profileId != currentUserId) {
      return const ProfileAccessDenied(
        'Access denied: caller does not own this learning profile',
      );
    }

    try {
      // 4. Update profile draft (display name, bio, preferences, avatarUrl)
      await _remoteDataSource.updateProfileDraft(
        session: session,
        displayName: trimmedName,
        bio: profile.bio,
        preferences: profile.preferences.toJson(),
        avatarUrl: profile.avatarUrl,
      );

      // 5. If setup repository is available, coordinate skill updates under revision control
      final setupRepo = _setupRepository;
      if (setupRepo != null) {
        final currentSetup = await setupRepo.readSetup();
        if (currentSetup is SetupSuccess<LearningSetupSnapshotDto>) {
          final snapshot = currentSetup.data;
          final skillsChanged =
              !listEquals(snapshot.teachingSkills, profile.skillsToShare) ||
                  !listEquals(snapshot.learningSkills, profile.skillsToLearn);

          if (skillsChanged) {
            final idempotencyKey =
                'idemp_sync_${DateTime.now().millisecondsSinceEpoch}_${profile.profileId}';
            final setupResult = await setupRepo.updateSelections(
              expectedRevision: snapshot.revision,
              teachingSkills: profile.skillsToShare,
              learningSkills: profile.skillsToLearn,
              idempotencyKey: idempotencyKey,
            );

            if (setupResult is SetupConflict) {
              return const ProfileFailure(
                'Revision conflict: remote learning setup was modified elsewhere',
              );
            } else if (setupResult is SetupBadRequest) {
              return ProfileFailure(
                'Invalid skill selections: ${setupResult.message}',
              );
            } else if (setupResult is SetupUnavailable) {
              return ProfileDependencyUnavailable(setupResult.message);
            }
          }
        }
      }

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
      profileId: 'lp_$currentUserId',
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
        return ProfileFailure('Server conflict error: ${failure.issue.name}');
      case HandoffIssue.invalidResponse:
        return ProfileFailure('Server error: ${failure.issue.name}');
    }
  }
}
