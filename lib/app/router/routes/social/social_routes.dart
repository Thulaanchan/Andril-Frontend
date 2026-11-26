import 'package:flutter/foundation.dart';

/// Central route constants and descriptors for the Social module.
///
/// Follows M5 Social Router Governance:
/// - Maps actual implemented and approved screens across Tasks 001–084.
/// - Does not modify shared application router or expose unapproved routes.
/// - Explicitly specifies required access policies (authentication, adult check, opt-in).
abstract final class SocialRoutes {
  static const String home = '/social/home';
  static const String discovery = '/social/discovery';
  static const String connections = '/social/connections';
  static const String likes = '/social/likes';
  static const String search = '/social/search';
  static const String zones = '/social/zones';
  static const String zoneDiscovery = '/social/zones/discover';
  static const String zoneDetails = '/social/zones/details';
  static const String createZone = '/social/zones/create';
  static const String myZones = '/social/zones/my';
  static const String personalityIntro = '/social/personality/intro';
  static const String personalityQuestionnaire = '/social/personality/quiz';
  static const String smartMatching = '/social/matching/smart';
  static const String myProfile = '/social/profile';
  static const String editProfile = '/social/profile/edit';
  static const String accessDenied = '/social/access-denied';
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

  const SocialRouteDescriptor({
    required this.path,
    required this.name,
    this.requiresAuth = true,
    this.requiresAdult = true,
    this.requiresOptIn = true,
    required this.description,
  });

  @override
  String toString() => 'SocialRouteDescriptor(path: $path, name: $name)';
}

/// Collection of all approved Social route descriptors.
class SocialRouteRegistry {
  static const List<SocialRouteDescriptor> approvedRoutes = [
    SocialRouteDescriptor(
      path: SocialRoutes.home,
      name: 'social-home',
      description: 'Landing and hub for social activity, discovery, and connections.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.discovery,
      name: 'social-discovery',
      description: 'Member discovery and profile cards browsing.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.connections,
      name: 'social-connections',
      description: 'Active connections and conversation entry points.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.likes,
      name: 'social-likes',
      description: 'Received and sent likes management.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.search,
      name: 'social-search',
      description: 'Debounced search for members and topics.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.zones,
      name: 'social-zones',
      description: 'Community interest zones hub and category browsing.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.zoneDiscovery,
      name: 'social-zone-discovery',
      description: 'Grid discovery view for available interest zones.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.zoneDetails,
      name: 'social-zone-details',
      description: 'Detailed view of an individual interest zone.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.createZone,
      name: 'social-create-zone',
      description: 'Create a new interest zone with rules and guidelines.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.myZones,
      name: 'social-my-zones',
      description: 'User joined and managed interest zones.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.personalityIntro,
      name: 'social-personality-intro',
      description: 'Introduction to the smart matching personality assessment.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.personalityQuestionnaire,
      name: 'social-personality-quiz',
      description: 'Interactive personality assessment questionnaire.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.smartMatching,
      name: 'social-smart-matching',
      description: 'Algorithmic smart matching results.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.myProfile,
      name: 'social-my-profile',
      description: 'View private social profile and stats.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.editProfile,
      name: 'social-edit-profile',
      description: 'Edit private social profile bio, photos, and prompts.',
    ),
    SocialRouteDescriptor(
      path: SocialRoutes.accessDenied,
      name: 'social-access-denied',
      requiresAuth: false,
      requiresAdult: false,
      requiresOptIn: false,
      description: 'Graceful access restriction presentation.',
    ),
  ];

  static SocialRouteDescriptor? findByPath(String path) {
    return approvedRoutes.where((r) => r.path == path).firstOrNull;
  }
}
