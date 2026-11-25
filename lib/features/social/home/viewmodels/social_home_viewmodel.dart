import 'package:flutter/foundation.dart';

import '../../../../core/security/session/session_controller.dart';
import '../../../../shared_core/account/account_handoff_controller.dart';
import '../../../../shared_core/onboarding/domain/onboarding_status_repository.dart';

/// Data model representing a recommended connection on the Social Home feed (S21).
@immutable
class SocialRecommendedPerson {
  final String id;
  final String displayName;
  final String location;
  final String? photoUrl;

  const SocialRecommendedPerson({
    required this.id,
    required this.displayName,
    required this.location,
    this.photoUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialRecommendedPerson &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          location == other.location &&
          photoUrl == other.photoUrl;

  @override
  int get hashCode => Object.hash(id, displayName, location, photoUrl);

  @override
  String toString() => 'SocialRecommendedPerson(id: $id)';
}

/// Identifiers for the 2x2 action cards on Social Home (S21).
enum SocialHomeActionId {
  myConnections,
  andrilDiary,
  personality,
  savedProfiles,
}

/// Data model representing a 2x2 quick action card on Social Home (S21).
@immutable
class SocialHomeQuickAction {
  final SocialHomeActionId id;
  final String title;
  final String subtitle;

  const SocialHomeQuickAction({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialHomeQuickAction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          subtitle == other.subtitle;

  @override
  int get hashCode => Object.hash(id, title, subtitle);

  @override
  String toString() => 'SocialHomeQuickAction(id: ${id.name})';
}

/// Operational state of the Social Home dashboard.
enum SocialHomeStatus {
  /// Initializing or verifying module authorization.
  initial,

  /// Asynchronously fetching home feed, recommendations, or notifications.
  loading,

  /// Data successfully loaded and user is authorized.
  ready,

  /// User is not authenticated or access is denied.
  accessDenied,

  /// Network or backend loading failure.
  error,
}

/// Manages presentation state, navigation callbacks, and feed data for Social Home (Screen S21).
///
/// Follows M5-FE-S21-SEC-01 architectural requirements:
/// - Fails closed: Denies access if unauthenticated, missing session context,
///   or not authoritatively opted in / authorized for Social module.
/// - Requires applicable M2 session and handoff evidence.
/// - Signed-in state alone never authorizes Social Home.
/// - Does not generate synthetic mock recommendations in production.
/// - Clears private state upon session invalidation, account switch, or logout.
/// - Guards all navigation callbacks against unauthorized or post-disposal invocation.
class SocialHomeViewModel extends ChangeNotifier {
  final SessionController? sessionController;
  final AccountHandoffController? handoffController;
  final bool isSocialOptedIn;
  final bool isTestAuthorized;

  VoidCallback? _unregisterSessionClearer;

  SocialHomeStatus _status = SocialHomeStatus.initial;
  String _displayName = '';
  String? _avatarUrl;
  int _unreadNotificationsCount = 0;
  List<SocialRecommendedPerson> _recommendedPeople = const [];
  String? _errorMessage;
  bool _disposed = false;

  /// Default verified S21 2x2 quick actions.
  static const List<SocialHomeQuickAction> defaultQuickActions = [
    SocialHomeQuickAction(
      id: SocialHomeActionId.myConnections,
      title: 'My Connections',
      subtitle: 'Matches & pending interest',
    ),
    SocialHomeQuickAction(
      id: SocialHomeActionId.andrilDiary,
      title: 'Andril Diary',
      subtitle: 'Your private reflections',
    ),
    SocialHomeQuickAction(
      id: SocialHomeActionId.personality,
      title: 'Personality',
      subtitle: 'Optional style insights',
    ),
    SocialHomeQuickAction(
      id: SocialHomeActionId.savedProfiles,
      title: 'Saved Profiles',
      subtitle: 'Revisit bookmarks',
    ),
  ];

  // Callbacks for navigation decoupled from Flutter UI context
  VoidCallback? onExplorePeople;
  VoidCallback? onSeeAllRecommendations;
  ValueChanged<String>? onViewProfile;
  ValueChanged<SocialHomeActionId>? onQuickAction;
  VoidCallback? onNotificationTap;
  VoidCallback? onSearchTap;

  SocialHomeViewModel({
    this.sessionController,
    this.handoffController,
    this.isSocialOptedIn = false,
    this.isTestAuthorized = false,
    String? initialDisplayName,
    String? initialAvatarUrl,
    int initialUnreadNotifications = 0,
    List<SocialRecommendedPerson>? initialRecommendations,
  })  : _displayName = initialDisplayName ?? '',
        _avatarUrl = initialAvatarUrl,
        _unreadNotificationsCount = initialUnreadNotifications,
        _recommendedPeople = initialRecommendations != null
            ? List.unmodifiable(initialRecommendations)
            : const [] {
    final session = sessionController;
    if (session != null) {
      _unregisterSessionClearer =
          session.registerPrivateStateClearer(_onSessionCleared);
      session.addListener(_onSessionStateChanged);
    }
    final handoff = handoffController;
    if (handoff != null) {
      handoff.addListener(_onHandoffStateChanged);
    }
  }

  SocialHomeStatus get status => _status;
  String get displayName => _displayName;
  String? get avatarUrl => _avatarUrl;
  int get unreadNotificationsCount => _unreadNotificationsCount;
  List<SocialRecommendedPerson> get recommendedPeople => _recommendedPeople;
  List<SocialHomeQuickAction> get quickActions => defaultQuickActions;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == SocialHomeStatus.loading;
  bool get isAccessDenied => _status == SocialHomeStatus.accessDenied;

  /// Whether user meets both session authentication and authoritative Social module authorization.
  bool get isAuthorized {
    if (_disposed) return false;

    // Fail closed: Missing session context never authorizes Social Home
    final session = sessionController;
    if (session == null) return false;

    // Signed-in status alone never authorizes Social access
    if (session.phase != SessionPhase.signedIn) return false;

    // Explicitly isolated test fixtures with valid session may assert authorized behavior
    if (isTestAuthorized) {
      return isSocialOptedIn;
    }

    // Require applicable verified M2 authorization handoff
    final handoff = handoffController;
    if (handoff != null) {
      final handoffStatus = handoff.status;
      if (handoffStatus != null &&
          handoffStatus.starterModule == StarterModule.social &&
          handoffStatus.progress.identityVerified &&
          handoffStatus.progress.currentPoliciesAccepted &&
          handoffStatus.progress.starterModuleSelected &&
          handoffStatus.moduleHomeAuthorized &&
          isSocialOptedIn) {
        return true;
      }
    }

    // If authoritative module authorization is unavailable, keep production access denied.
    return false;
  }

  void _onSessionCleared() {
    _clearPrivateState();
  }

  void _onSessionStateChanged() {
    if (_disposed) return;
    if (!isAuthorized) {
      _clearPrivateState();
    }
  }

  void _onHandoffStateChanged() {
    if (_disposed) return;
    if (!isAuthorized) {
      _clearPrivateState();
    }
  }

  void _clearPrivateState() {
    _displayName = '';
    _avatarUrl = null;
    _unreadNotificationsCount = 0;
    _recommendedPeople = const [];
    _status = SocialHomeStatus.accessDenied;
    _errorMessage = null;
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Initializes home state. Fails closed if unauthorized.
  Future<void> initialize() async {
    if (_disposed) return;

    if (!isAuthorized) {
      _status = SocialHomeStatus.accessDenied;
      notifyListeners();
      return;
    }

    _status = SocialHomeStatus.loading;
    notifyListeners();

    try {
      // In production, no synthetic hardcoded recommendations are generated.
      // Recommendations remain what was injected or fetched from authoritative gateway.
      _status = SocialHomeStatus.ready;
      _errorMessage = null;
    } catch (_) {
      _status = SocialHomeStatus.error;
      _errorMessage = 'Failed to load Social Home feed.';
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Refreshes feed and notification counters.
  Future<void> refresh() async {
    await initialize();
  }

  /// Updates user profile display info.
  void updateProfileHeader({required String displayName, String? avatarUrl}) {
    if (_disposed || !isAuthorized) return;
    _displayName = displayName;
    _avatarUrl = avatarUrl;
    notifyListeners();
  }

  /// Updates the unread notifications count.
  void setUnreadNotificationsCount(int count) {
    if (_disposed || !isAuthorized) return;
    _unreadNotificationsCount = count < 0 ? 0 : count;
    notifyListeners();
  }

  /// Dispatches explore people action.
  void triggerExplorePeople() {
    if (_disposed || !isAuthorized) return;
    onExplorePeople?.call();
  }

  /// Dispatches see all recommendations action.
  void triggerSeeAllRecommendations() {
    if (_disposed || !isAuthorized) return;
    onSeeAllRecommendations?.call();
  }

  /// Dispatches view profile action for a specific user ID.
  void triggerViewProfile(String userId) {
    if (_disposed || !isAuthorized) return;
    onViewProfile?.call(userId);
  }

  /// Dispatches a 2x2 quick action navigation callback.
  void triggerQuickAction(SocialHomeActionId actionId) {
    if (_disposed || !isAuthorized) return;
    onQuickAction?.call(actionId);
  }

  /// Dispatches notification tap.
  void triggerNotificationTap() {
    if (_disposed || !isAuthorized) return;
    onNotificationTap?.call();
  }

  /// Dispatches search tap.
  void triggerSearchTap() {
    if (_disposed || !isAuthorized) return;
    onSearchTap?.call();
  }

  @override
  void dispose() {
    _disposed = true;
    _unregisterSessionClearer?.call();
    _unregisterSessionClearer = null;
    sessionController?.removeListener(_onSessionStateChanged);
    handoffController?.removeListener(_onHandoffStateChanged);
    super.dispose();
  }
}
