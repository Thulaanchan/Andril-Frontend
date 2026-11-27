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
  final String? _boundSubject;

  SocialProfileManagementRepository({
    required SocialProfileRepository innerRepository,
    required SessionController sessionController,
    String? boundSubject,
  })  : _innerRepository = innerRepository,
        _sessionController = sessionController,
        _boundSubject = boundSubject ?? _extractSubject(sessionController);

  static String? _extractSubject(SessionController session) {
    try {
      return session.subject;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SocialProfileResult> getProfile() async {
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.authorizationDenied,
        message: 'Caller is not authenticated.',
      ));
    }

    try {
      if (_boundSubject != null && _sessionController.subject != _boundSubject) {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.authorizationDenied,
          message: 'Account context mismatch detected.',
        ));
      }
    } catch (_) {}

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

    try {
      if (_boundSubject != null && _sessionController.subject != _boundSubject) {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.authorizationDenied,
          message: 'Account context mismatch detected.',
        ));
      }
    } catch (_) {}

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
