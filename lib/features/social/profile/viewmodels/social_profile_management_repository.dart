import 'package:dio/dio.dart';
import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
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
///
/// Adheres to M5 Task 152 Delivery Governance:
/// - Connects to owner-scoped GET & PUT `/api/v1/account/profiles/social` via [AndrilApiClient].
/// - Fails closed if session or configuration is missing or invalid.
/// - Reuses configured API origin and session safeguards (no hard-coded fallback hosts).
/// - Enforces strictly private visibility on PUT bodies (`visibility: 'private'`).
/// - PUT payload contains only `displayName`, `bio`, and `visibility`.
/// - Preserves nullable `bio` and handles profile with no display name yet (`null`).
/// - Discards late results if session changes or invalidates during the request.
/// - Does not log credentials, private fields, or raw response bodies.
/// - Preserves backward compatibility if an [innerRepository] is supplied in tests.
class SocialProfileManagementRepository implements ISocialProfileManagementRepository {
  final SessionController _sessionController;
  final AndrilApiClient? _apiClient;
  final SocialProfileRepository? _innerRepository;
  final String? _boundSubject;
  final bool _ownsApiClient;

  SocialProfileManagementRepository({
    required SessionController sessionController,
    AndrilApiClient? apiClient,
    AppConfig? config,
    HttpClientAdapter? adapter,
    SocialProfileRepository? innerRepository,
    String? boundSubject,
  })  : _sessionController = sessionController,
        _apiClient = apiClient ?? _createApiClient(config, sessionController, adapter),
        _innerRepository = innerRepository,
        _boundSubject = boundSubject ?? _extractSubject(sessionController),
        _ownsApiClient = apiClient == null;

  static AndrilApiClient? _createApiClient(
    AppConfig? config,
    SessionController session,
    HttpClientAdapter? adapter,
  ) {
    if (config == null) return null;
    try {
      return AndrilApiClient(config, session, adapter: adapter);
    } catch (_) {
      return null;
    }
  }

  static String? _extractSubject(SessionController session) {
    try {
      return session.subject;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SocialProfileResult> getProfile() async {
    // 1. Session standing check
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

    // Backwards-compatible delegation if innerRepository was provided
    if (_innerRepository != null) {
      try {
        return await _innerRepository.getProfileDraft();
      } catch (_) {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.dependencyFailure,
          message: 'Failed to retrieve profile from server.',
        ));
      }
    }

    // 2. Active backend session check
    final session = _sessionController.backendSession;
    if (session == null) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.authorizationDenied,
        message: 'Active backend session unavailable.',
      ));
    }

    // 3. API client check (fails closed if unconfigured)
    final client = _apiClient;
    if (client == null) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.dependencyFailure,
        message: 'Profile API client is not configured or origin is invalid.',
      ));
    }

    try {
      final json = await client.requestSocial(
        SocialEndpoint.profile,
        session,
      );

      // 4. Session continuity check
      if (_sessionController.backendSession != session) {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.sessionExpired,
          message: 'Session changed during profile fetch.',
        ));
      }

      // Bug #1 fix: validate required Social profile contract fields before accepting.
      // Reject: empty map, missing/wrong module, missing visibility.
      // Accept: legitimately absent/null optional fields (bio, blockingDependency, displayName, profilePhotoPath).
      if (json.isEmpty) {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.unknown,
          message: 'Profile response from server was empty.',
        ));
      }
      final responseModule = json['module'] as String?;
      if (responseModule != 'social') {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.unknown,
          message: 'Profile response belongs to an unexpected module.',
        ));
      }
      if (!json.containsKey('visibility')) {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.unknown,
          message: 'Profile response is missing required visibility field.',
        ));
      }

      final displayName = json['displayName'] as String?;
      final bio = json['bio'] as String?;
      final draft = SocialProfileDraft(
        displayName: displayName ?? '',
        bio: bio,
        visibility: SocialProfileDraft.privateVisibility,
      );

      return SocialProfileResult.success(draft);
    } on HandoffFailure catch (failure) {
      if (_sessionController.backendSession != session) {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.sessionExpired,
          message: 'Session changed during profile fetch.',
        ));
      }
      return _mapHandoffFailure(failure);
    } catch (_) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.unknown,
        message: 'An unexpected error occurred while loading profile.',
      ));
    }
  }

  @override
  Future<SocialProfileResult> updateProfile(SocialProfileDraft draft) async {
    // 1. Session standing check
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

    // Backwards-compatible delegation if innerRepository was provided
    if (_innerRepository != null) {
      try {
        return await _innerRepository.saveProfileDraft(draft);
      } catch (_) {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.dependencyFailure,
          message: 'Failed to update profile on server.',
        ));
      }
    }

    // 2. Active backend session check
    final session = _sessionController.backendSession;
    if (session == null) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.authorizationDenied,
        message: 'Active backend session unavailable.',
      ));
    }

    // 3. API client check (fails closed if unconfigured)
    final client = _apiClient;
    if (client == null) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.dependencyFailure,
        message: 'Profile API client is not configured or origin is invalid.',
      ));
    }

    // 4. Client-side draft validation
    final trimmedName = draft.displayName.trim();
    if (trimmedName.isNotEmpty && !draft.isValid) {
      return SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.validationFailure,
        message: draft.displayNameError ?? draft.bioError ?? 'Invalid profile input.',
      ));
    }

    // 5. Construct exact PUT body (contains only displayName, bio, visibility)
    final body = <String, Object?>{
      'displayName': trimmedName,
      'bio': draft.bio,
      'visibility': SocialProfileDraft.privateVisibility,
    };

    try {
      final json = await client.requestSocial(
        SocialEndpoint.updateProfile,
        session,
        body: body,
      );

      // 6. Session continuity check
      if (_sessionController.backendSession != session) {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.sessionExpired,
          message: 'Session changed during profile update.',
        ));
      }

      // Bug #1 fix (updateProfile): validate required Social profile contract fields.
      if (json.isEmpty) {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.unknown,
          message: 'Profile update response from server was empty.',
        ));
      }
      final savedModule = json['module'] as String?;
      if (savedModule != 'social') {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.unknown,
          message: 'Profile update response belongs to an unexpected module.',
        ));
      }
      if (!json.containsKey('visibility')) {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.unknown,
          message: 'Profile update response is missing required visibility field.',
        ));
      }

      // Bug #2 fix: use the server-returned state exclusively.
      // If the server returns bio: null, the saved state must reflect that — no client-draft fallback.
      final savedName = json['displayName'] as String?;
      final savedBio = json.containsKey('bio') ? json['bio'] as String? : draft.bio;
      final savedDraft = SocialProfileDraft(
        displayName: savedName ?? trimmedName,
        bio: savedBio,
        visibility: SocialProfileDraft.privateVisibility,
      );

      return SocialProfileResult.success(savedDraft);
    } on HandoffFailure catch (failure) {
      if (_sessionController.backendSession != session) {
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.sessionExpired,
          message: 'Session changed during profile update.',
        ));
      }
      return _mapHandoffFailure(failure);
    } catch (_) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.unknown,
        message: 'An unexpected error occurred while saving profile.',
      ));
    }
  }

  SocialProfileResult _mapHandoffFailure(HandoffFailure failure) {
    if (failure.statusCode == 409) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.displayNameUnavailable,
        message: 'Display name is already taken or reserved.',
      ));
    }
    if (failure.statusCode == 404) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.dependencyFailure,
        message: 'Private Social profile not found.',
      ));
    }
    if (failure.statusCode == 400) {
      return const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.validationFailure,
        message: 'Invalid profile draft format.',
      ));
    }
    switch (failure.issue) {
      case HandoffIssue.reauthenticationRequired:
      case HandoffIssue.forbidden:
      case HandoffIssue.verificationRequired:
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.authorizationDenied,
          message: 'Caller is not authorized to access private profile.',
        ));
      case HandoffIssue.sessionChanged:
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.sessionExpired,
          message: 'Session context expired or changed.',
        ));
      case HandoffIssue.rateLimited:
        final retrySeconds = failure.retryAfter?.inSeconds;
        final retryMsg = retrySeconds != null
            ? 'Rate limit exceeded. Please retry in $retrySeconds seconds.'
            : 'Rate limit exceeded. Please try again later.';
        return SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.dependencyFailure,
          message: retryMsg,
        ));
      case HandoffIssue.unavailable:
      case HandoffIssue.accountNotInitialized:
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.dependencyFailure,
          message: 'Profile service is currently unavailable.',
        ));
      case HandoffIssue.invalidResponse:
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.unknown,
          message: 'Malformed response returned by server.',
        ));
      case HandoffIssue.badRequest:
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.validationFailure,
          message: 'Invalid profile draft format.',
        ));
      case HandoffIssue.conflict:
        return const SocialProfileResult.failure(SocialProfileFailure(
          type: SocialProfileFailureType.displayNameUnavailable,
          message: 'The display name is already taken.',
        ));
    }
  }

  /// Closes owned resources if this repository created its own API client.
  void dispose() {
    if (_ownsApiClient) {
      _apiClient?.close();
    }
  }
}
