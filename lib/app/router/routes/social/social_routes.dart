import 'package:flutter/foundation.dart';

/// Central route constants for the Social module.
///
/// Follows M5 Social Router Governance:
/// - Maps actual implemented and approved screens across Tasks 001–146.
/// - Does not modify shared application router or expose unapproved routes.
/// - Explicitly specifies required access policies (authentication, adult check, opt-in).
/// - Does not activate pending S39 Live Room Preview or contextual AI screens S74/S75 without approval.
abstract final class SocialRoutes {
  // Hub & Security
  static const String home = '/social/home';
  static const String accessDenied = '/social/access-denied';

  // Discovery & Profiles
  static const String discovery = '/social/discovery';
  static const String memberProfile = '/social/discovery/profile';
  static const String memberPhotos = '/social/discovery/photos';
  static const String photoViewer = '/social/discovery/photo-viewer';
  static const String savedProfiles = '/social/saved-profiles';
  static const String discoveryFilters = '/social/discovery/filters';
  static const String search = '/social/search';

  // Relationships & Matches
  static const String connections = '/social/connections';
  static const String likes = '/social/likes';
  static const String sentLikes = '/social/likes/sent';
  static const String receivedLikes = '/social/likes/received';
  static const String mutualMatch = '/social/matches/mutual';
  static const String matchHistory = '/social/matches';
  static const String unmatched = '/social/unmatched';

  // Preferences
  static const String preferences = '/social/preferences';
  static const String discoveryLanguages = '/social/preferences/languages';

  // Zones (Communities)
  static const String zones = '/social/zones';
  static const String zoneDiscovery = '/social/zones/discover';
  static const String zoneDetails = '/social/zones/details';
  static const String zoneMembers = '/social/zones/members';
  static const String zoneManagement = '/social/zones/manage';
  static const String zoneModeration = '/social/zones/moderation';
  static const String createZone = '/social/zones/create';
  static const String myZones = '/social/zones/my';

  // Personality & Smart Matching
  static const String personalityIntro = '/social/personality/intro';
  static const String personalityQuestionnaire = '/social/personality/quiz';
  static const String personalityReview = '/social/personality/review';
  static const String personalityAnswers = '/social/personality/answers';
  static const String smartMatching = '/social/matching/smart';

  // User Profile Management
  static const String myProfile = '/social/profile';
  static const String editProfile = '/social/profile/edit';
  static const String createProfile = '/social/profile/create';
}

/// Immutable descriptor for an approved Social route.
@immutable
class SocialRouteDescriptor {
  final String path;
  final String name;
  final bool requiresAuth;
  final bool requiresAdult;
  final bool requiresOptIn;
  final String description;
  final bool Function(Object? args)? validateArgs;

  const SocialRouteDescriptor({
    required this.path,
    required this.name,
    this.requiresAuth = true,
    this.requiresAdult = true,
    this.requiresOptIn = true,
    required this.description,
    this.validateArgs,
  });

  @override
  String toString() => 'SocialRouteDescriptor(path: $path, name: $name)';
}

/// Collection and validator of all approved Social route descriptors.
class SocialRouteRegistry {
  static const List<SocialRouteDescriptor> approvedRoutes = [
    // Hub & Security
    SocialRouteDescriptor(
      path: SocialRoutes.home,
      name: 'social-home',
      description: 'Landing and hub for social activity, discovery, and connections (S21).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.accessDenied,
      name: 'social-access-denied',
      requiresAuth: false,
      requiresAdult: false,
      requiresOptIn: false,
      description: 'Graceful access restriction presentation.',
    ),

    // Discovery & Profiles
    SocialRouteDescriptor(
      path: SocialRoutes.discovery,
      name: 'social-discovery',
      description: 'Member discovery and profile cards browsing (S22).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.memberProfile,
      name: 'social-member-profile',
      description: 'Full profile view of a discovered candidate member (S26).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.memberPhotos,
      name: 'social-member-photos',
      description: 'Photo gallery browsing of candidate media (S72).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.photoViewer,
      name: 'social-photo-viewer',
      description: 'Full-screen zoomable photo viewer (S73).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.savedProfiles,
      name: 'social-saved-profiles',
      description: 'Bookmarks of saved member profiles (S70).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.discoveryFilters,
      name: 'social-discovery-filters',
      description: 'Discovery filter controls for gender, age, and location (S29).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.search,
      name: 'social-search',
      description: 'Debounced search for members and topics (S71).',
    ),

    // Relationships & Matches
    SocialRouteDescriptor(
      path: SocialRoutes.connections,
      name: 'social-connections',
      description: 'Active connections and conversation entry points (S23).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.likes,
      name: 'social-likes',
      description: 'Received and sent likes management.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.sentLikes,
      name: 'social-likes-sent',
      description: 'Outbound likes sent to other members (S79).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.receivedLikes,
      name: 'social-likes-received',
      description: 'Inbound likes received from other members (S67).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.mutualMatch,
      name: 'social-matches-mutual',
      description: 'Mutual match celebration modal and conversation trigger (S27).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.matchHistory,
      name: 'social-matches-history',
      description: 'History of confirmed mutual matches (S68).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.unmatched,
      name: 'social-unmatched',
      description: 'Archived and voluntarily terminated relationships (S69).',
    ),

    // Preferences
    SocialRouteDescriptor(
      path: SocialRoutes.preferences,
      name: 'social-preferences',
      description: 'Discovery preferences for gender, age, and languages (S80).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.discoveryLanguages,
      name: 'social-preferences-languages',
      description: 'Discovery language selection catalog (S81).',
    ),

    // Zones
    SocialRouteDescriptor(
      path: SocialRoutes.zones,
      name: 'social-zones',
      description: 'Community interest zones hub and category browsing (S38).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.zoneDiscovery,
      name: 'social-zone-discovery',
      description: 'Grid discovery view for available interest zones (S60).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.zoneDetails,
      name: 'social-zone-details',
      description: 'Detailed view of an individual interest zone (S61).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.zoneMembers,
      name: 'social-zone-members',
      description: 'Member roster of an interest zone (S62).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.zoneManagement,
      name: 'social-zone-management',
      description: 'Host settings and management tools for a zone (S44).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.zoneModeration,
      name: 'social-zone-moderation',
      description: 'Moderation actions for join requests and member standing (S65).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.createZone,
      name: 'social-create-zone',
      description: 'Create a new interest zone with rules and guidelines (S63).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.myZones,
      name: 'social-my-zones',
      description: 'User joined and managed interest zones (S64).',
    ),

    // Personality & Smart Matching
    SocialRouteDescriptor(
      path: SocialRoutes.personalityIntro,
      name: 'social-personality-intro',
      description: 'Introduction to the smart matching personality assessment (S25).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.personalityQuestionnaire,
      name: 'social-personality-quiz',
      description: 'Interactive personality assessment questionnaire (S77).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.personalityReview,
      name: 'social-personality-review',
      description: 'Review and confirm personality assessment answers (S82).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.personalityAnswers,
      name: 'social-personality-answers',
      description: 'Private review of recorded personality responses (S37).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.smartMatching,
      name: 'social-smart-matching',
      description: 'Algorithmic smart matching explanation and mutual affinity (S28).',
    ),

    // User Profile
    SocialRouteDescriptor(
      path: SocialRoutes.myProfile,
      name: 'social-my-profile',
      description: 'View private social profile and stats (S30).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.editProfile,
      name: 'social-edit-profile',
      description: 'Edit private social profile bio, photos, and prompts (S76).',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.createProfile,
      name: 'social-create-profile',
      description: 'Initial social profile creation and onboarding setup (S78).',
    ),
  ];

  /// Finds route descriptor by path.
  static SocialRouteDescriptor? findByPath(String path) {
    return approvedRoutes.where((r) => r.path == path).firstOrNull;
  }

  /// Finds route descriptor by name.
  static SocialRouteDescriptor? findByName(String name) {
    return approvedRoutes.where((r) => r.name == name).firstOrNull;
  }

  /// Whether a route path belongs to the Social module namespace.
  static bool isSocialPath(String path) => path.startsWith('/social');

  /// Whether a given path is an approved Social route.
  static bool isApproved(String path) => findByPath(path) != null;

  /// Whether the route requires authentication, adult verification, and Social opt-in.
  static bool isGuarded(String path) {
    final descriptor = findByPath(path);
    if (descriptor == null) return true;
    return descriptor.requiresAuth || descriptor.requiresAdult || descriptor.requiresOptIn;
  }

  /// Validates route arguments against descriptor rules if present.
  static bool validateArguments(String path, Object? args) {
    final descriptor = findByPath(path);
    if (descriptor == null) return false;
    return descriptor.validateArgs?.call(args) ?? true;
  }
}
