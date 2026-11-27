import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../../../../features/social/discovery/data/social_discovery_repository.dart';
import '../../../../features/social/discovery/presentation/social_discovery_viewmodel.dart';
import '../../../../features/social/discovery/presentation/social_search_viewmodel.dart';
import '../../../../features/social/home/viewmodels/social_home_viewmodel.dart';
import '../../../../features/social/home/viewmodels/social_navigation_coordinator.dart';
import '../../../../features/social/likes_matches/data/social_relationship_repository.dart';
import '../../../../features/social/likes_matches/domain/authorization/social_access_boundary.dart';
import '../../../../features/social/likes_matches/domain/authorization/social_match_communication_boundary.dart';
import '../../../../features/social/likes_matches/presentation/social_relationship_viewmodel.dart';
import '../../../../features/social/personality/data/repositories/personality_questionnaire_repository.dart';
import '../../../../features/social/personality/presentation/viewmodels/personality_questionnaire_viewmodel.dart';
import '../../../../features/social/profile/viewmodels/social_profile_management_repository.dart';
import '../../../../features/social/profile/viewmodels/social_profile_management_viewmodel.dart';
import '../../../../features/social/zones/group_contracts/social_zone_repository.dart';
import '../../../../features/social/zones/presentation/social_zone_management_viewmodel.dart';
import '../../../../features/social/zones/presentation/social_zones_viewmodel.dart';

/// Scoped dependency container managing lifecycle and instances of Social module services.
///
/// Follows M5 Fast Feature Delivery Governance (Task 103, 148):
/// - Reuses approved SessionController without constructing fake fallback production sessions.
/// - Requires authoritative Social access evidence bound to active session; fails closed otherwise.
/// - Signed-in state alone or local opt-in boolean alone does not authorize Social.
/// - Automatically unregisters callbacks, disposes owned ViewModels, and prevents post-disposal recreation.
/// - Disposal is idempotent.
class SocialDependenciesScope {
  final SessionController? _sessionController;
  final bool _isSocialOptedIn;
  final SocialAccessEvidence? _accessEvidence;
  final ISocialAccessBoundary _accessBoundary;
  final ISocialMatchCommunicationBoundary _communicationBoundary;
  final ISocialProfileManagementRepository? _profileManagementRepository;
  final IPersonalityQuestionnaireRepository? _questionnaireRepository;
  final AndrilApiClient? _apiClient;
  final AppConfig? _appConfig;

  // Lazily initialized instances within the scope
  ISocialZoneRepository? _zoneRepository;
  SocialZonesViewModel? _zonesViewModel;
  SocialZoneManagementViewModel? _zoneManagementViewModel;
  SocialNavigationCoordinator? _navigationCoordinator;
  SocialDiscoveryViewModel? _discoveryViewModel;
  SocialRelationshipViewModel? _relationshipViewModel;
  SocialSearchViewModel? _searchViewModel;
  SocialProfileManagementViewModel? _profileManagementViewModel;
  PersonalityQuestionnaireViewModel? _personalityViewModel;

  VoidCallback? _unregisterSessionClearer;
  bool _isDisposed = false;

  SocialDependenciesScope({
    SessionController? sessionController,
    bool isSocialOptedIn = false,
    SocialAccessEvidence? accessEvidence,
    ISocialAccessBoundary? accessBoundary,
    ISocialMatchCommunicationBoundary? communicationBoundary,
    ISocialProfileManagementRepository? profileManagementRepository,
    IPersonalityQuestionnaireRepository? questionnaireRepository,
    AndrilApiClient? apiClient,
    AppConfig? appConfig,
  })  : _sessionController = sessionController,
        _isSocialOptedIn = isSocialOptedIn,
        _accessEvidence = accessEvidence,
        _accessBoundary = accessBoundary ?? const SocialAccessBoundary(),
        _communicationBoundary = communicationBoundary ?? const SocialMatchCommunicationBoundary(),
        _profileManagementRepository = profileManagementRepository,
        _questionnaireRepository = questionnaireRepository,
        _apiClient = apiClient,
        _appConfig = appConfig {
    _unregisterSessionClearer = _sessionController?.registerPrivateStateClearer(dispose);
  }

  /// Whether this scope has already been permanently disposed.
  bool get isDisposed => _isDisposed;

  void _checkDisposed() {
    if (_isDisposed) {
      throw StateError('SocialDependenciesScope has already been disposed and cannot be accessed.');
    }
  }

  /// Session controller associated with this scope.
  SessionController? get sessionController {
    _checkDisposed();
    return _sessionController;
  }

  /// Authoritative Social access evidence.
  SocialAccessEvidence? get accessEvidence {
    _checkDisposed();
    return _accessEvidence;
  }

  /// Raw unauthoritative client opt-in preference flag.
  bool get isSocialOptedIn {
    _checkDisposed();
    return _isSocialOptedIn;
  }

  /// Evaluates whether the caller has authoritative, non-revoked adult Social module eligibility.
  ///
  /// Fails closed if session is absent/unauthenticated, or if authoritative evidence is missing.
  /// Neither signed-in state alone nor a local boolean flag grants access.
  bool get isSocialAuthorized {
    _checkDisposed();
    final session = _sessionController;
    if (session == null || session.phase != SessionPhase.signedIn) {
      return false;
    }
    final evidence = _accessEvidence;
    if (evidence == null) {
      return false; // Fails closed without authoritative evidence
    }
    return _accessBoundary.isAccessGranted(
      sessionController: session,
      evidence: evidence,
    );
  }

  /// Authoritative Social Access Boundary.
  ISocialAccessBoundary get accessBoundary {
    _checkDisposed();
    return _accessBoundary;
  }

  /// Peer match communication authorization boundary.
  ISocialMatchCommunicationBoundary get communicationBoundary {
    _checkDisposed();
    return _communicationBoundary;
  }

  /// Dormant-safe Social Zone Repository.
  ISocialZoneRepository get zoneRepository {
    _checkDisposed();
    final session = _sessionController;
    if (session == null) {
      throw StateError('Cannot initialize SocialZoneRepository without an authentic SessionController.');
    }
    return _zoneRepository ??= SocialZoneRepository(
      sessionController: session,
      isDormant: true, // Dormant in production: no fake synthetic zones or synthetic counts
    );
  }

  /// ViewModel for discovering and browsing interest zones.
  SocialZonesViewModel get zonesViewModel {
    _checkDisposed();
    return _zonesViewModel ??= SocialZonesViewModel(
      repository: zoneRepository,
      sessionController: _sessionController,
      isSocialOptedIn: isSocialAuthorized,
      accessBoundary: _accessBoundary,
      accessEvidence: _accessEvidence,
    );
  }

  /// ViewModel for creating and managing interest zones.
  SocialZoneManagementViewModel get zoneManagementViewModel {
    _checkDisposed();
    return _zoneManagementViewModel ??= SocialZoneManagementViewModel(
      sessionController: _sessionController,
      isSocialOptedIn: isSocialAuthorized,
      accessBoundary: _accessBoundary,
      accessEvidence: _accessEvidence,
    );
  }

  /// Creates a scoped [SocialHomeViewModel] instance bound to current authorization.
  SocialHomeViewModel createHomeViewModel() {
    _checkDisposed();
    return SocialHomeViewModel(
      sessionController: _sessionController,
      accessEvidence: _accessEvidence,
      accessBoundary: _accessBoundary,
      isSocialOptedIn: isSocialAuthorized,
    );
  }

  /// Creates or retrieves the scoped [SocialNavigationCoordinator] instance.
  SocialNavigationCoordinator createNavigationCoordinator({ValueChanged<String>? onChatHandoff}) {
    _checkDisposed();
    return _navigationCoordinator ??= SocialNavigationCoordinator(
      accessBoundary: _accessBoundary,
      communicationBoundary: _communicationBoundary,
      sessionController: _sessionController,
      accessEvidence: _accessEvidence,
      isSocialOptedIn: isSocialAuthorized,
      onChatHandoff: onChatHandoff,
    );
  }

  /// Creates a scoped [SocialDiscoveryViewModel].
  SocialDiscoveryViewModel createDiscoveryViewModel({ISocialDiscoveryRepository? repository}) {
    _checkDisposed();
    return _discoveryViewModel ??= SocialDiscoveryViewModel(
      repository: repository ?? const SocialDiscoveryRepository(isBackendActivated: false),
      sessionController: _sessionController,
      accessEvidence: _accessEvidence,
      accessBoundary: _accessBoundary,
      isSocialOptedIn: isSocialAuthorized,
    );
  }

  /// Creates a scoped [SocialRelationshipViewModel].
  SocialRelationshipViewModel createRelationshipViewModel({ISocialRelationshipRepository? repository}) {
    _checkDisposed();
    return _relationshipViewModel ??= SocialRelationshipViewModel(
      repository: repository ?? const SocialRelationshipRepository(isBackendActivated: false),
      sessionController: _sessionController,
      accessEvidence: _accessEvidence,
      accessBoundary: _accessBoundary,
      isSocialOptedIn: isSocialAuthorized,
    );
  }

  /// Creates a scoped [SocialSearchViewModel].
  SocialSearchViewModel createSearchViewModel() {
    _checkDisposed();
    final session = _sessionController;
    if (session == null) {
      throw StateError('Cannot initialize SocialSearchViewModel without an authentic SessionController.');
    }
    return _searchViewModel ??= SocialSearchViewModel(
      sessionController: session,
      accessBoundary: _accessBoundary,
      accessEvidence: _accessEvidence,
      isSocialOptedIn: isSocialAuthorized,
    );
  }

  /// Creates a scoped [SocialProfileManagementViewModel].
  SocialProfileManagementViewModel createProfileManagementViewModel({
    ISocialProfileManagementRepository? repository,
    bool isOnboarding = false,
  }) {
    _checkDisposed();
    final session = _sessionController;
    if (session == null) {
      throw StateError('Cannot initialize SocialProfileManagementViewModel without an authentic SessionController.');
    }
    return _profileManagementViewModel ??= SocialProfileManagementViewModel(
      repository: repository ??
          _profileManagementRepository ??
          SocialProfileManagementRepository(
            sessionController: session,
            apiClient: _apiClient,
            config: _appConfig,
          ),
      sessionController: session,
      accessBoundary: _accessBoundary,
      accessEvidence: _accessEvidence,
      isSocialOptedIn: isSocialAuthorized,
      isOnboarding: isOnboarding,
    );
  }

  /// Creates a scoped [PersonalityQuestionnaireViewModel].
  PersonalityQuestionnaireViewModel createPersonalityQuestionnaireViewModel({
    IPersonalityQuestionnaireRepository? repository,
  }) {
    _checkDisposed();
    final session = _sessionController;
    if (session == null) {
      throw StateError('Cannot initialize PersonalityQuestionnaireViewModel without an authentic SessionController.');
    }
    return _personalityViewModel ??= PersonalityQuestionnaireViewModel(
      repository: repository ??
          _questionnaireRepository ??
          PersonalityQuestionnaireRepository(
            sessionController: session,
            apiClient: _apiClient,
            config: _appConfig,
          ),
      sessionController: session,
      accessBoundary: _accessBoundary,
      accessEvidence: _accessEvidence,
      isSocialOptedIn: isSocialAuthorized,
    );
  }

  /// Idempotently disposes all created ViewModels, unregisters listeners, and clears private dependencies.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _navigationCoordinator?.dispose();
    _navigationCoordinator = null;

    _zonesViewModel?.dispose();
    _zonesViewModel = null;

    _zoneManagementViewModel?.dispose();
    _zoneManagementViewModel = null;

    _discoveryViewModel?.dispose();
    _discoveryViewModel = null;

    _relationshipViewModel?.dispose();
    _relationshipViewModel = null;

    _searchViewModel?.dispose();
    _searchViewModel = null;

    _profileManagementViewModel?.dispose();
    _profileManagementViewModel = null;

    _personalityViewModel?.dispose();
    _personalityViewModel = null;

    _zoneRepository = null;

    _unregisterSessionClearer?.call();
    _unregisterSessionClearer = null;
  }
}
