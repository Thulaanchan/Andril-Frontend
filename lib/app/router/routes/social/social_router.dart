import 'package:flutter/material.dart';

import '../../../../features/social/discovery/domain/social_candidate.dart';
import '../../../../features/social/discovery/presentation/social_discovery_filters_screen.dart';
import '../../../../features/social/discovery/presentation/social_discovery_screen.dart';
import '../../../../features/social/discovery/presentation/social_discovery_viewmodel.dart';
import '../../../../features/social/discovery/presentation/social_member_photo_gallery_screen.dart';
import '../../../../features/social/discovery/presentation/social_member_profile_screen.dart';
import '../../../../features/social/discovery/presentation/social_photo_viewer_screen.dart';
import '../../../../features/social/discovery/presentation/social_saved_profiles_screen.dart';
import '../../../../features/social/discovery/presentation/social_search_screen.dart';
import '../../../../features/social/discovery/presentation/social_search_viewmodel.dart';
import '../../../../features/social/home/screens/social_shell_screen.dart';
import '../../../../features/social/interests_preferences/domain/social_preferences_model.dart';
import '../../../../features/social/interests_preferences/presentation/social_discovery_languages_screen.dart';
import '../../../../features/social/interests_preferences/presentation/social_preferences_screen.dart';
import '../../../../features/social/likes_matches/domain/social_relationship.dart';
import '../../../../features/social/likes_matches/presentation/social_connections_screen.dart';
import '../../../../features/social/likes_matches/presentation/social_match_history_screen.dart';
import '../../../../features/social/likes_matches/presentation/social_mutual_match_screen.dart';
import '../../../../features/social/likes_matches/presentation/social_received_likes_screen.dart';
import '../../../../features/social/likes_matches/presentation/social_relationship_viewmodel.dart';
import '../../../../features/social/likes_matches/presentation/social_sent_likes_screen.dart';
import '../../../../features/social/likes_matches/presentation/social_unmatched_screen.dart';
import '../../../../features/social/personality/presentation/screens/personality_answers_screen.dart';
import '../../../../features/social/personality/presentation/screens/personality_intro_screen.dart';
import '../../../../features/social/personality/presentation/screens/personality_questionnaire_screen.dart';
import '../../../../features/social/personality/presentation/screens/personality_review_screen.dart';
import '../../../../features/social/personality/presentation/viewmodels/personality_questionnaire_viewmodel.dart';
import '../../../../features/social/profile/screens/create_social_profile_screen.dart';
import '../../../../features/social/profile/screens/social_edit_profile_screen.dart';
import '../../../../features/social/profile/screens/social_my_profile_screen.dart';
import '../../../../features/social/profile/viewmodels/social_profile_management_viewmodel.dart';
import '../../../../features/social/profile/viewmodels/social_profile_viewmodel.dart';
import '../../../../features/social/smart_matching/presentation/social_smart_matching_screen.dart';
import '../../../../features/social/zones/group_contracts/social_zone.dart';
import '../../../../features/social/zones/presentation/social_create_zone_screen.dart';
import '../../../../features/social/zones/presentation/social_my_zones_screen.dart';
import '../../../../features/social/zones/presentation/social_zone_details_screen.dart';
import '../../../../features/social/zones/presentation/social_zone_discovery_screen.dart';
import '../../../../features/social/zones/presentation/social_zone_management_screen.dart';
import '../../../../features/social/zones/presentation/social_zone_members_screen.dart';
import '../../../../features/social/zones/presentation/social_zone_moderation_screen.dart';
import '../../../../features/social/zones/presentation/social_zones_screen.dart';
import '../../../dependencies/registrations/social/social_dependencies.dart';
import 'social_routes.dart';

/// Presentation screen displayed when Social module access is restricted.
class SocialAccessDeniedScreen extends StatelessWidget {
  final String? message;
  final VoidCallback? onReturn;

  const SocialAccessDeniedScreen({
    super.key,
    this.message,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        leading: onReturn != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onReturn,
              )
            : null,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: Color(0xFFE63946),
              ),
              const SizedBox(height: 16),
              const Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    'Active adult opt-in and authentication are required to access Social features.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scoped route generator and access controller for the Social module.
///
/// Follows M5 Router Governance (Tasks 147–148):
/// - Resolves approved Social routes safely to actual implemented screens.
/// - Validates caller authentication and authoritative adult opt-in evidence.
/// - Fails closed: unapproved or unguarded access redirects to [SocialAccessDeniedScreen].
/// - Validates required route arguments and prevents cross-module data leakage.
class SocialRouter {
  final SocialDependenciesScope scope;
  final ValueChanged<String>? onChatHandoff;

  const SocialRouter({
    required this.scope,
    this.onChatHandoff,
  });

  /// Generates a [Route] for the given [RouteSettings].
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final path = settings.name ?? '';

    // Route boundary check: enforce Social module path isolation
    if (!SocialRouteRegistry.isSocialPath(path) ||
        !SocialRouteRegistry.isApproved(path)) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SocialAccessDeniedScreen(
          message: 'Requested route is not an approved Social destination.',
        ),
      );
    }

    // Access authorization check: fail closed if guarded and unauthorized
    if (SocialRouteRegistry.isGuarded(path) && !scope.isSocialAuthorized) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SocialAccessDeniedScreen(
          message:
              'Active adult opt-in is required to access Social features.',
        ),
      );
    }

    // Argument validation
    if (!SocialRouteRegistry.validateArguments(path, settings.arguments)) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SocialAccessDeniedScreen(
          message: 'Invalid arguments provided for destination route.',
        ),
      );
    }

    final args = settings.arguments;

    final Widget screen = switch (path) {
      SocialRoutes.home => SocialShellScreen(
          scope: scope,
          onChatHandoff: onChatHandoff,
        ),
      SocialRoutes.accessDenied => SocialAccessDeniedScreen(
          message: args is String ? args : null,
        ),
      SocialRoutes.discovery => SocialDiscoveryScreen(
          viewModel: args is SocialDiscoveryViewModel
              ? args
              : scope.createDiscoveryViewModel(),
        ),
      SocialRoutes.memberProfile => args is SocialCandidate
          ? SocialMemberProfileScreen(candidate: args)
          : SocialDiscoveryScreen(
              viewModel: scope.createDiscoveryViewModel(),
            ),
      SocialRoutes.memberPhotos => args is Map<String, dynamic>
          ? SocialMemberPhotoGalleryScreen(
              memberName: args['name'] as String? ?? 'Member',
              memberId: args['id'] as String? ?? '',
              photoUrls: (args['photos'] as List?)?.cast<String>() ?? const [],
            )
          : SocialDiscoveryScreen(
              viewModel: scope.createDiscoveryViewModel(),
            ),
      SocialRoutes.photoViewer => args is Map<String, dynamic>
          ? SocialPhotoViewerScreen(
              memberName: args['name'] as String? ?? 'Photo',
              photoUrls: (args['photos'] as List?)?.cast<String>() ?? const [],
              initialIndex: args['index'] as int? ?? 0,
            )
          : SocialDiscoveryScreen(
              viewModel: scope.createDiscoveryViewModel(),
            ),
      SocialRoutes.savedProfiles => SocialSavedProfilesScreen(
          savedProfiles: args is List<SocialCandidate> ? args : const [],
        ),
      SocialRoutes.discoveryFilters => SocialDiscoveryFiltersScreen(
          initialFilters: args is SocialPreferencesModel ? args : null,
        ),
      SocialRoutes.search => SocialSearchScreen(
          viewModel: args is SocialSearchViewModel
              ? args
              : scope.createSearchViewModel(),
        ),
      SocialRoutes.connections => SocialConnectionsScreen(
          viewModel: args is SocialRelationshipViewModel
              ? args
              : scope.createRelationshipViewModel(),
          onOpenChat: onChatHandoff,
        ),
      SocialRoutes.likes || SocialRoutes.receivedLikes =>
        SocialReceivedLikesScreen(
          viewModel: args is SocialRelationshipViewModel
              ? args
              : scope.createRelationshipViewModel(),
        ),
      SocialRoutes.sentLikes => SocialSentLikesScreen(
          viewModel: args is SocialRelationshipViewModel
              ? args
              : scope.createRelationshipViewModel(),
        ),
      SocialRoutes.mutualMatch => args is SocialRelationship
          ? SocialMutualMatchScreen(
              relationship: args,
              communicationBoundary: scope.communicationBoundary,
            )
          : SocialConnectionsScreen(
              viewModel: scope.createRelationshipViewModel(),
            ),
      SocialRoutes.matchHistory => SocialMatchHistoryScreen(
          historyRecords:
              args is List<SocialMatchHistoryRecord> ? args : const [],
        ),
      SocialRoutes.unmatched => SocialUnmatchedScreen(
          targetName: args is String ? args : 'Member',
        ),
      SocialRoutes.preferences => SocialPreferencesScreen(
          initialPreferences: args is SocialPreferencesModel ? args : null,
        ),
      SocialRoutes.discoveryLanguages =>
        const SocialDiscoveryLanguagesScreen(),
      SocialRoutes.zones => SocialZonesScreen(
          viewModel: scope.zonesViewModel,
        ),
      SocialRoutes.zoneDiscovery => SocialZoneDiscoveryScreen(
          viewModel: scope.zonesViewModel,
        ),
      SocialRoutes.zoneDetails => args is SocialZone
          ? SocialZoneDetailsScreen(
              zone: args,
              viewModel: scope.zonesViewModel,
            )
          : SocialZonesScreen(viewModel: scope.zonesViewModel),
      SocialRoutes.zoneMembers => args is SocialZone
          ? SocialZoneMembersScreen(
              zone: args,
              viewModel: scope.zoneManagementViewModel,
            )
          : SocialZonesScreen(viewModel: scope.zonesViewModel),
      SocialRoutes.zoneManagement => args is SocialZone
          ? SocialZoneManagementScreen(
              zone: args,
              viewModel: scope.zoneManagementViewModel,
            )
          : SocialZonesScreen(viewModel: scope.zonesViewModel),
      SocialRoutes.zoneModeration => args is SocialZone
          ? SocialZoneModerationScreen(
              zone: args,
              viewModel: scope.zoneManagementViewModel,
            )
          : SocialZonesScreen(viewModel: scope.zonesViewModel),
      SocialRoutes.createZone => SocialCreateZoneScreen(
          viewModel: scope.zoneManagementViewModel,
        ),
      SocialRoutes.myZones => SocialMyZonesScreen(
          viewModel: scope.zonesViewModel,
        ),
      SocialRoutes.personalityIntro => PersonalityIntroScreen(
          onStart: () {},
          onSkip: () {},
        ),
      SocialRoutes.personalityQuestionnaire =>
        args is PersonalityQuestionnaireViewModel
            ? PersonalityQuestionnaireScreen(viewModel: args)
            : scope.createPersonalityQuestionnaireViewModel() != null
                ? PersonalityQuestionnaireScreen(
                    viewModel:
                        scope.createPersonalityQuestionnaireViewModel()!,
                  )
                : const SocialAccessDeniedScreen(
                    message: 'Personality assessment unavailable.',
                  ),
      SocialRoutes.personalityReview => args
              is PersonalityQuestionnaireViewModel
          ? PersonalityReviewScreen(viewModel: args)
          : PersonalityIntroScreen(onStart: () {}, onSkip: () {}),
      SocialRoutes.personalityAnswers => args
              is PersonalityQuestionnaireViewModel
          ? PersonalityAnswersScreen(viewModel: args)
          : PersonalityIntroScreen(onStart: () {}, onSkip: () {}),
      SocialRoutes.smartMatching => const SocialSmartMatchingScreen(),
      SocialRoutes.myProfile => args is SocialProfileManagementViewModel
          ? SocialMyProfileScreen(viewModel: args)
          : scope.createProfileManagementViewModel() != null
              ? SocialMyProfileScreen(
                  viewModel: scope.createProfileManagementViewModel()!,
                )
              : const SocialAccessDeniedScreen(
                  message:
                      'Profile management requires active profile draft.',
                ),
      SocialRoutes.editProfile => args is SocialProfileManagementViewModel
          ? SocialEditProfileScreen(viewModel: args)
          : scope.createProfileManagementViewModel() != null
              ? SocialEditProfileScreen(
                  viewModel: scope.createProfileManagementViewModel()!,
                )
              : const SocialAccessDeniedScreen(
                  message:
                      'Profile management requires active profile draft.',
                ),
      SocialRoutes.createProfile => args is SocialProfileViewModel
          ? CreateSocialProfileScreen(viewModel: args)
          : const SocialAccessDeniedScreen(
              message: 'Initial profile setup ViewModel required.',
            ),
      _ => const SocialAccessDeniedScreen(
          message: 'Unhandled destination path.',
        ),
    };

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => screen,
    );
  }
}
