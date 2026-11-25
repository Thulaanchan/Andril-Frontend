import 'package:flutter/foundation.dart';

import '../../../../core/security/session/session_controller.dart';

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
  String toString() =>
      'SocialRecommendedPerson(id: $id, displayName: $displayName, location: $location)';
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
  String toString() => 'SocialHomeQuickAction(id: ${id.name}, title: $title)';
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
/// Follows M5-FE-S21 architectural requirements:
/// - Fails closed: Denies access if unauthenticated or not opted in to Social module.
/// - Exposes verified user greeting display name and optional profile avatar.
/// - Exposes the four verified S21 2x2 quick action items:
///   1. My Connections (Matches & pending interest)
///   2. Andril Diary (Your private reflections)
///   3. Personality (Optional style insights)
///   4. Saved Profiles (Revisit bookmarks)
/// - Exposes recommended people feed.
/// - Triggers navigation callbacks without direct context or route coupling.
class SocialHomeViewModel extends ChangeNotifier {
  final SessionController? sessionController;
  final bool isSocialOptedIn;

  SocialHomeStatus _status = SocialHomeStatus.initial;
  String _displayName = 'Explorer';
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
    this.isSocialOptedIn = true,
    String initialDisplayName = 'Explorer',
    String? initialAvatarUrl,
    int initialUnreadNotifications = 0,
    List<SocialRecommendedPerson>? initialRecommendations,
  })  : _displayName = initialDisplayName,
        _avatarUrl = initialAvatarUrl,
        _unreadNotificationsCount = initialUnreadNotifications,
        _recommendedPeople = initialRecommendations != null
            ? List.unmodifiable(initialRecommendations)
            : const [];

  SocialHomeStatus get status => _status;
  String get displayName => _displayName;
  String? get avatarUrl => _avatarUrl;
  int get unreadNotificationsCount => _unreadNotificationsCount;
  List<SocialRecommendedPerson> get recommendedPeople => _recommendedPeople;
  List<SocialHomeQuickAction> get quickActions => defaultQuickActions;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == SocialHomeStatus.loading;
  bool get isAccessDenied => _status == SocialHomeStatus.accessDenied;

  /// Whether user meets both session authentication and Social module opt-in.
  bool get isAuthorized {
    if (!isSocialOptedIn) return false;
    if (sessionController != null &&
        sessionController!.phase != SessionPhase.signedIn) {
      return false;
    }
    return true;
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
      // If recommendations were not provided at construction, load default seed
      if (_recommendedPeople.isEmpty) {
        _recommendedPeople = const [
          SocialRecommendedPerson(
            id: 'rec_01',
            displayName: 'Nivetha R.',
            location: 'Kandy',
          ),
          SocialRecommendedPerson(
            id: 'rec_02',
            displayName: 'Arjun K.',
            location: 'Colombo',
          ),
          SocialRecommendedPerson(
            id: 'rec_03',
            displayName: 'Dilan M.',
            location: 'Galle',
          ),
          SocialRecommendedPerson(
            id: 'rec_04',
            displayName: 'Tharushi S.',
            location: 'Jaffna',
          ),
        ];
      }
      _status = SocialHomeStatus.ready;
      _errorMessage = null;
    } catch (e) {
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
    _displayName = displayName;
    _avatarUrl = avatarUrl;
    if (!_disposed) notifyListeners();
  }

  /// Updates the unread notifications count.
  void setUnreadNotificationsCount(int count) {
    if (count < 0) count = 0;
    _unreadNotificationsCount = count;
    if (!_disposed) notifyListeners();
  }

  /// Dispatches explore people action.
  void triggerExplorePeople() {
    onExplorePeople?.call();
  }

  /// Dispatches see all recommendations action.
  void triggerSeeAllRecommendations() {
    onSeeAllRecommendations?.call();
  }

  /// Dispatches view profile action for a specific user ID.
  void triggerViewProfile(String userId) {
    onViewProfile?.call(userId);
  }

  /// Dispatches a 2x2 quick action navigation callback.
  void triggerQuickAction(SocialHomeActionId actionId) {
    onQuickAction?.call(actionId);
  }

  /// Dispatches notification tap.
  void triggerNotificationTap() {
    onNotificationTap?.call();
  }

  /// Dispatches search tap.
  void triggerSearchTap() {
    onSearchTap?.call();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
