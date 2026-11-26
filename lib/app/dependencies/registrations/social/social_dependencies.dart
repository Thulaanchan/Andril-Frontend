import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../../../../features/social/home/viewmodels/social_home_viewmodel.dart';
import '../../../../features/social/likes_matches/domain/authorization/social_access_boundary.dart';
import '../../../../features/social/likes_matches/domain/authorization/social_match_communication_boundary.dart';
import '../../../../features/social/zones/group_contracts/social_zone_repository.dart';
import '../../../../features/social/zones/presentation/social_zone_management_viewmodel.dart';
import '../../../../features/social/zones/presentation/social_zones_viewmodel.dart';

/// Scoped dependency container managing lifecycle and instances of Social module services.
///
/// Follows M5 Social Architecture & M2 Session Governance:
/// - Reuses approved production repositories and ViewModels.
/// - Does not register permissive production mocks or leak cross-module state.
/// - Automatically disposes private state and unregisters listeners upon session change.
class SocialDependenciesScope {
  final SessionController? _sessionController;
  final bool _isSocialOptedIn;

  // Singletons / Lazily initialized instances within the scope
  ISocialZoneRepository? _zoneRepository;
  SocialZonesViewModel? _zonesViewModel;
  SocialZoneManagementViewModel? _zoneManagementViewModel;
  ISocialAccessBoundary? _accessBoundary;
  ISocialMatchCommunicationBoundary? _communicationBoundary;

  VoidCallback? _unregisterSessionClearer;

  SocialDependenciesScope({
    SessionController? sessionController,
    bool isSocialOptedIn = false,
  })  : _sessionController = sessionController,
        _isSocialOptedIn = isSocialOptedIn {
    _unregisterSessionClearer = _sessionController?.registerPrivateStateClearer(dispose);
  }

  /// Authoritative Social Access Boundary.
  ISocialAccessBoundary get accessBoundary =>
      _accessBoundary ??= const SocialAccessBoundary();

  /// Peer match communication authorization boundary.
  ISocialMatchCommunicationBoundary get communicationBoundary =>
      _communicationBoundary ??= const SocialMatchCommunicationBoundary();

  /// Dormant-safe Social Zone Repository.
  ISocialZoneRepository get zoneRepository =>
      _zoneRepository ??= SocialZoneRepository(
        sessionController: _sessionController ?? _FallbackSessionController(),
      );

  /// Viewmodel for discovering and browsing interest zones.
  SocialZonesViewModel get zonesViewModel =>
      _zonesViewModel ??= SocialZonesViewModel(
        repository: zoneRepository,
        sessionController: _sessionController,
        isSocialOptedIn: _isSocialOptedIn,
      );

  /// Viewmodel for creating and managing interest zones.
  SocialZoneManagementViewModel get zoneManagementViewModel =>
      _zoneManagementViewModel ??= SocialZoneManagementViewModel(
        sessionController: _sessionController,
        isSocialOptedIn: _isSocialOptedIn,
      );

  /// Creates a scoped [SocialHomeViewModel] instance.
  SocialHomeViewModel createHomeViewModel() {
    return SocialHomeViewModel(
      sessionController: _sessionController,
      isSocialOptedIn: _isSocialOptedIn,
    );
  }

  /// Disposes all created ViewModels and clears in-memory scoped dependencies.
  void dispose() {
    _zonesViewModel?.dispose();
    _zonesViewModel = null;

    _zoneManagementViewModel?.dispose();
    _zoneManagementViewModel = null;

    _zoneRepository = null;
    _accessBoundary = null;
    _communicationBoundary = null;

    _unregisterSessionClearer?.call();
    _unregisterSessionClearer = null;
  }
}

class _FallbackSessionController extends ChangeNotifier implements SessionController {
  _FallbackSessionController();

  @override
  SessionPhase get phase => SessionPhase.signedOut;

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) => () {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
