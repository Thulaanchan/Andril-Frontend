import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../../likes_matches/domain/authorization/social_access_boundary.dart';
import '../../likes_matches/domain/authorization/social_match_communication_boundary.dart';

/// Approved top-level and sub-surface destinations within the Social module.
enum SocialDestination {
  home,
  discovery,
  connections,
  zones,
  profile,
  personality,
  search,
  accessDenied,
}

/// Navigation coordinator providing guarded transitions between Social destinations.
///
/// Follows M5 Social Architecture & M4 Communication Boundary Governance:
/// - Enforces adult eligibility and active opt-in before permitting navigation to Social surfaces.
/// - Unauthenticated or unverified users are strictly redirected to [SocialDestination.accessDenied].
/// - Handoff to peer chat requires authoritative [MatchCommunicationEvidence] validated by M4 boundary.
/// - Clears navigation history and resets destination on session invalidation.
class SocialNavigationCoordinator extends ChangeNotifier {
  final ISocialAccessBoundary _accessBoundary;
  final ISocialMatchCommunicationBoundary _communicationBoundary;
  final SessionController? _sessionController;
  final bool _isSocialOptedIn;
  final ValueChanged<String>? _onChatHandoff;

  SocialDestination _currentDestination = SocialDestination.home;
  String? _navigationDeniedReason;
  VoidCallback? _unregisterSessionClearer;

  SocialNavigationCoordinator({
    ISocialAccessBoundary accessBoundary = const SocialAccessBoundary(),
    ISocialMatchCommunicationBoundary communicationBoundary = const SocialMatchCommunicationBoundary(),
    SessionController? sessionController,
    bool isSocialOptedIn = false,
    ValueChanged<String>? onChatHandoff,
  })  : _accessBoundary = accessBoundary,
        _communicationBoundary = communicationBoundary,
        _sessionController = sessionController,
        _isSocialOptedIn = isSocialOptedIn,
        _onChatHandoff = onChatHandoff {
    _unregisterSessionClearer = _sessionController?.registerPrivateStateClearer(_clearPrivateState);
  }

  SocialDestination get currentDestination => _currentDestination;
  String? get navigationDeniedReason => _navigationDeniedReason;
  ISocialAccessBoundary get accessBoundary => _accessBoundary;
  ISocialMatchCommunicationBoundary get communicationBoundary => _communicationBoundary;

  bool get isAuthorized =>
      _sessionController?.phase == SessionPhase.signedIn && _isSocialOptedIn;

  /// Guarded navigation to an approved Social destination.
  bool navigateTo(SocialDestination destination) {
    if (destination == SocialDestination.accessDenied) {
      _currentDestination = destination;
      notifyListeners();
      return true;
    }

    if (!isAuthorized) {
      _currentDestination = SocialDestination.accessDenied;
      _navigationDeniedReason = 'Active adult opt-in is required to access Social features.';
      notifyListeners();
      return false;
    }

    _currentDestination = destination;
    _navigationDeniedReason = null;
    notifyListeners();
    return true;
  }

  /// Guarded handoff to M4 peer messaging for matched connections.
  bool navigateToChat(MatchCommunicationEvidence evidence) {
    if (!isAuthorized) {
      _navigationDeniedReason = 'Session is not authorized for peer communication.';
      notifyListeners();
      return false;
    }

    final isClear = _communicationBoundary.canInitiateCommunication(evidence);
    if (!isClear) {
      final status = _communicationBoundary.evaluateMatchCommunication(evidence);
      _navigationDeniedReason = 'Chat handoff denied: $status';
      notifyListeners();
      return false;
    }

    _navigationDeniedReason = null;
    _onChatHandoff?.call(evidence.m4ChannelId!);
    notifyListeners();
    return true;
  }

  void _clearPrivateState() {
    _currentDestination = SocialDestination.home;
    _navigationDeniedReason = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _unregisterSessionClearer?.call();
    _unregisterSessionClearer = null;
    super.dispose();
  }
}
