import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'social_profile_draft.dart';
import 'social_profile_repository.dart';

/// Abstract contract for managing and updating the authenticated user's private Social profile.
///
/// Follows confirmed M2 backend contract boundaries:
/// - GET & PUT `/api/v1/account/profiles/social`.
/// - Always relies on authenticated caller context; no caller-supplied ownership parameters.
/// - Enforces strictly private profile visibility.
abstract class ISocialProfileManagementRepository {
  /// Fetches the authenticated user's private Social profile.
  Future<SocialProfileResult> getProfile();

  /// Updates the authenticated user's private Social profile draft.
  Future<SocialProfileResult> updateProfile(SocialProfileDraft draft);
}

/// Implementation of [ISocialProfileManagementRepository] adapting M2-owned profile infrastructure.
class SocialProfileManagementRepository implements ISocialProfileManagementRepository {
  final SocialProfileRepository _innerRepository;
  final SessionController _sessionController;

  SocialProfileManagementRepository({
    required SocialProfileRepository innerRepository,
    required SessionController sessionController,
  })  : _innerRepository = innerRepository,
        _sessionController = sessionController;

  @override
  Future<SocialProfileResult> getProfile() async {
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.authorizationDenied,
        message: 'Caller is not authenticated.',
      ));
    }

    try {
      return await _innerRepository.getProfileDraft();
    } catch (_) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.dependencyFailure,
        message: 'Failed to retrieve profile from server.',
      ));
    }
  }

  @override
  Future<SocialProfileResult> updateProfile(SocialProfileDraft draft) async {
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.authorizationDenied,
        message: 'Caller is not authenticated.',
      ));
    }

    // Invariant: Visibility must remain strictly private
    if (draft.visibility != SocialProfileDraft.privateVisibility) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.validationFailure,
        message: 'Profile visibility must be strictly private.',
      ));
    }

    try {
      return await _innerRepository.saveProfileDraft(draft);
    } catch (_) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.dependencyFailure,
        message: 'Failed to update profile on server.',
      ));
    }
  }
}
