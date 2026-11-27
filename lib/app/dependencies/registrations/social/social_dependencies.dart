import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../../../../features/social/home/viewmodels/social_home_viewmodel.dart';
import '../../../../features/social/home/viewmodels/social_navigation_coordinator.dart';
import '../../../../features/social/likes_matches/domain/authorization/social_access_boundary.dart';
import '../../../../features/social/likes_matches/domain/authorization/social_match_communication_boundary.dart';
import '../../../../features/social/zones/group_contracts/social_zone_repository.dart';
import '../../../../features/social/zones/presentation/social_zone_management_viewmodel.dart';
import '../../../../features/social/zones/presentation/social_zones_viewmodel.dart';

/// Scoped dependency container managing lifecycle and instances of Social module services.
///
/// Follows M5 Fast Feature Delivery Governance (Task 103):
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

  // Lazily initialized instances within the scope
  ISocialZoneRepository? _zoneRepository;
  SocialZonesViewModel? _zonesViewModel;
  SocialZoneManagementViewModel? _zoneManagementViewModel;
  SocialNavigationCoordinator? _navigationCoordinator;

  VoidCallback? _unregisterSessionClearer;
  bool _isDisposed = false;

  SocialDependenciesScope({
    SessionController? sessionController,
    bool isSocialOptedIn = false,
    SocialAccessEvidence? accessEvidence,
    ISocialAccessBoundary? accessBoundary,
    ISocialMatchCommunicationBoundary? communicationBoundary,
  })  : _sessionController = sessionController,
        _isSocialOptedIn = isSocialOptedIn,
        _accessEvidence = accessEvidence,
        _accessBoundary = accessBoundary ?? const SocialAccessBoundary(),
        _communicationBoundary = communicationBoundary ?? const SocialMatchCommunicationBoundary() {
    _unregisterSessionClearer = _sessionController?.registerPrivateStateClearer(dispose);
  }

  /// Whether this scope has already been permanently disposed.
  bool get isDisposed => _isDisposed;

  void _checkDisposed() {
    if (_isDisposed) {
      throw StateError('SocialDependenciesScope has already been disposed and cannot be accessed.');
    }
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
    // Signed-in state alone does NOT authorize. Local opt-in boolean alone does NOT authorize.
    // Must evaluate authoritative evidence through ISocialAccessBoundary.
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
  ///
  /// Fails closed if SessionController is not provided, rather than inventing fake sessions.
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

    _zoneRepository = null;

    _unregisterSessionClearer?.call();
    _unregisterSessionClearer = null;
  }
}
