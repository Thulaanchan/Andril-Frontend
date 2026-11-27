import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/session/session_controller.dart';
import '../../features/common/chat/domain/module_config.dart';
import '../../features/common/chat/presentation/navigation/chat_navigation_contract.dart';
import '../../features/common/chat/presentation/screens/andril_chat_screen.dart';
import '../../features/common/chat/presentation/screens/andril_chats_list_screen.dart';
import '../../features/common/chat/preview/main_app_chat_route_preview.dart';
import '../../features/learning/circles/data/repositories/learning_circles_repository.dart';
import '../../features/learning/circles/presentation/screens/learning_circles_hub_screen.dart';
import '../../features/learning/circles/presentation/viewmodels/learning_circles_viewmodel.dart';
import '../../features/learning/classrooms/presentation/screens/learning_classrooms_hub_screen.dart';
import '../../features/learning/connections/data/repositories/learning_connections_repository.dart';
import '../../features/learning/connections/presentation/screens/learning_connections_screen.dart';
import '../../features/learning/connections/presentation/viewmodels/learning_connections_viewmodel.dart';
import '../../features/learning/cv_maker/presentation/screens/cv_editor_screen.dart';
import '../../features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';
import '../../features/learning/discovery/data/repositories/learning_discovery_repository.dart';
import '../../features/learning/discovery/presentation/screens/learning_partner_explorer_screen.dart';
import '../../features/learning/discovery/presentation/viewmodels/learning_partner_explorer_viewmodel.dart';
import '../../features/learning/growth_mentorship/data/repositories/learning_growth_repository.dart';
import '../../features/learning/growth_mentorship/presentation/screens/learning_mentorship_hub_screen.dart';
import '../../features/learning/growth_mentorship/presentation/screens/my_growth_dashboard_screen.dart';
import '../../features/learning/growth_mentorship/presentation/screens/topic_gap_explanation_screen.dart';
import '../../features/learning/growth_mentorship/presentation/viewmodels/learning_growth_viewmodel.dart';
import '../../features/learning/growth_mentorship/presentation/viewmodels/learning_mentorship_viewmodel.dart';
import '../../features/learning/growth_mentorship/presentation/viewmodels/learning_topic_gap_viewmodel.dart';
import '../../features/learning/home/screens/learning_home_container.dart';
import '../../features/learning/pacts/data/repositories/learning_pacts_repository.dart';
import '../../features/learning/pacts/presentation/screens/learning_pacts_hub_screen.dart';
import '../../features/learning/pacts/presentation/screens/learning_pact_progress_screen.dart';
import '../../features/learning/pacts/presentation/screens/propose_pact_flow_screen.dart';
import '../../features/learning/pacts/presentation/viewmodels/learning_pacts_viewmodel.dart';
import '../../features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import '../../features/learning/portfolio_maker/presentation/screens/portfolio_editor_screen.dart';
import '../../features/learning/portfolio_maker/presentation/screens/portfolio_template_selection_preview_screen.dart';
import '../../features/learning/profile/screens/learning_onboarding_screen.dart';
import '../../features/learning/profile/screens/learning_profile_screen.dart';
import '../../features/learning/profile/screens/learning_welcome_screen.dart';
import '../../features/learning/skill_exchange/presentation/screens/skill_exchange_hub_screen.dart';
import '../../features/shared/presentation/scaffolds/learning_scaffold.dart';
import '../../features/shared/presentation/widgets/andril_module_app_bar.dart';
import '../../features/shared/presentation/widgets/error_retry_card.dart';
import '../dependencies/registrations/learning/learning_dependencies.dart';
import '../themes/learning/learning_colors.dart';

/// Contract for evaluating route access to protected Learning module surfaces.
///
/// Production gates fail closed until M2 publishes official authentication
/// and module-activation contracts.
abstract interface class LearningAccessPolicy {
  /// Whether the user has an active, authenticated identity session.
  bool get isAuthenticated;

  /// Whether the user has completed onboarding and activated the Learning module.
  bool get isLearningActivated;
}

/// Default production access policy failing closed pending M2 integration.
class ProductionLearningAccessPolicy implements LearningAccessPolicy {
  const ProductionLearningAccessPolicy();

  @override
  bool get isAuthenticated => false;

  @override
  bool get isLearningActivated => false;
}

/// Evaluates Learning route access against an active [SessionController] standing.
///
/// Under M2 admission governance:
/// - [isAuthenticated] requires an active, signed-in session with verified backend credential.
/// - [isLearningActivated] requires verified module authorization ([SessionController.moduleHomeAuthorized]).
class SessionLearningAccessPolicy implements LearningAccessPolicy {
  final SessionController? session;
  const SessionLearningAccessPolicy(this.session);

  @override
  bool get isAuthenticated =>
      session != null &&
      session!.phase == SessionPhase.signedIn &&
      session!.backendSession != null;

  @override
  bool get isLearningActivated =>
      session != null && session!.moduleHomeAuthorized;
}

/// Creates and configures the [GoRouter] instance for the Learning module.
GoRouter createLearningRouter({
  LearningAccessPolicy accessPolicy = const ProductionLearningAccessPolicy(),
  LearningDependenciesScope? dependencies,
  String initialLocation = '/learning/welcome',
  List<NavigatorObserver>? observers,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    observers: observers,
    redirect: (context, state) => _handleRedirect(context, state, accessPolicy),
    routes: [
      GoRoute(
        path: '/learning/welcome',
        name: 'learning-welcome',
        builder: (context, state) => LearningWelcomeScreen(
          onContinue: () {
            if (accessPolicy.isAuthenticated &&
                accessPolicy.isLearningActivated) {
              context.go('/learning/home');
            } else {
              context.go('/learning/access-denied');
            }
          },
          onBack: () {
            // Root entry - no back navigation available
          },
        ),
      ),
      GoRoute(
        path: '/learning/access-denied',
        name: 'learning-access-denied',
        builder: (context, state) => const _AccessDeniedPlaceholderScreen(),
      ),
      GoRoute(
        path: '/learning/onboarding',
        name: 'learning-onboarding',
        builder: (context, state) => LearningOnboardingScreen(
          viewModel: dependencies?.onboardingViewModel,
          onExit: () => context.go('/learning/welcome'),
        ),
      ),
      GoRoute(
        path: '/learning/circles',
        name: 'learning-circles',
        builder: (context, state) => LearningCirclesHubScreen(
          viewModel: dependencies?.circlesViewModel ??
              LearningCirclesViewModel(
                repository: const LearningCirclesRepository(),
              ),
        ),
      ),
      GoRoute(
        path: '/learning/pacts',
        name: 'learning-pacts',
        builder: (context, state) => LearningPactsHubScreen(
          viewModel: dependencies?.pactsViewModel ??
              LearningPactsViewModel(
                repository: const LearningPactsRepository(),
              ),
        ),
        routes: [
          GoRoute(
            path: 'progress',
            name: 'learning-pacts-progress',
            builder: (context, state) {
              final pactId =
                  state.uri.queryParameters['pactId'] ?? 'pact_default';
              return LearningPactProgressScreen(
                pactId: pactId,
                viewModel: dependencies?.pactsViewModel ??
                    LearningPactsViewModel(
                      repository: const LearningPactsRepository(),
                    ),
              );
            },
          ),
          GoRoute(
            path: 'propose',
            name: 'learning-pacts-propose',
            builder: (context, state) => ProposePactFlowScreen(
              viewModel: dependencies?.pactsViewModel ??
                  LearningPactsViewModel(
                    repository: const LearningPactsRepository(),
                  ),
              onPactProposed: () => context.go('/learning/pacts'),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/learning/growth',
        name: 'learning-growth',
        builder: (context, state) => MyGrowthDashboardScreen(
          viewModel: dependencies?.growthViewModel ??
              LearningGrowthViewModel(
                repository: const LearningGrowthRepository(),
              ),
        ),
        routes: [
          GoRoute(
            path: 'topic-gap',
            name: 'learning-growth-topic-gap',
            builder: (context, state) {
              final gapId =
                  state.uri.queryParameters['gapId'] ?? 'gap_flutter_state';
              return TopicGapExplanationScreen(
                viewModel: LearningTopicGapViewModel(
                  repository: const LearningGrowthRepository(),
                  gapId: gapId,
                ),
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go('/learning/growth'),
              );
            },
          ),
          GoRoute(
            path: 'mentorship',
            name: 'learning-growth-mentorship',
            builder: (context, state) => LearningMentorshipHubScreen(
              viewModel: dependencies?.mentorshipViewModel ??
                  LearningMentorshipViewModel(
                    repository: const LearningGrowthRepository(),
                  ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/learning/cv-maker',
        name: 'learning-cv-maker',
        builder: (context, state) => CvEditorScreen(
          onPreview: (draft) =>
              context.go('/learning/cv-maker/preview', extra: draft),
        ),
        routes: [
          GoRoute(
            path: 'preview',
            name: 'learning-cv-maker-preview',
            builder: (context, state) {
              final draft = state.extra is CvDraftData
                  ? state.extra as CvDraftData
                  : CvDraftData.empty();
              return CvTemplateSelectionPreviewScreen(
                initialDraft: draft,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/learning/portfolio-maker',
        name: 'learning-portfolio-maker',
        builder: (context, state) => PortfolioEditorScreen(
          onPreviewPortfolio: (portfolio) =>
              context.go('/learning/portfolio-maker/preview', extra: portfolio),
        ),
        routes: [
          GoRoute(
            path: 'preview',
            name: 'learning-portfolio-maker-preview',
            builder: (context, state) {
              final portfolio = state.extra is LearningPortfolio
                  ? state.extra as LearningPortfolio
                  : LearningPortfolio.empty(
                      ownerLearningProfileId: 'preview_user');
              return PortfolioTemplateSelectionPreviewScreen(
                initialPortfolio: portfolio,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/learning/discovery',
        name: 'learning-discovery',
        builder: (context, state) => LearningPartnerExplorerScreen(
          viewModel: dependencies?.discoveryViewModel ??
              LearningPartnerExplorerViewModel(
                repository: const LearningDiscoveryRepository(),
              ),
        ),
      ),
      GoRoute(
        path: '/learning/connections',
        name: 'learning-connections',
        builder: (context, state) => LearningConnectionsScreen(
          viewModel: dependencies?.connectionsViewModel ??
              LearningConnectionsViewModel(
                repository: const LearningConnectionsRepository(),
              ),
        ),
      ),
      GoRoute(
        path: '/learning/skill-exchange',
        name: 'learning-skill-exchange',
        builder: (context, state) => const SkillExchangeHubScreen(
          currentUserId: 'learner_current',
        ),
      ),
      GoRoute(
        path: '/learning/classrooms/hub',
        name: 'learning-classrooms-hub',
        builder: (context, state) => const LearningClassroomsHubScreen(
          currentUserId: 'learner_current',
        ),
      ),
      GoRoute(
        path: '/learning/profile/editor',
        name: 'learning-profile-editor',
        builder: (context, state) {
          final session = dependencies?.sessionController;
          final currentUserId = session?.subject ?? 'lp_current_user';
          return LearningProfileScreen(
            isEditMode: true,
            currentUserId: currentUserId,
            onSaveProfile: (profile) async {
              await dependencies?.profileRepository?.updateProfile(profile);
            },
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/learning/home');
              }
            },
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return LearningScaffold(
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learning/home',
                name: 'learning-home',
                builder: (context, state) => LearningHomeContainer(
                  dependencies: dependencies,
                  accessPolicy: accessPolicy,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learning/classrooms',
                name: 'learning-classrooms',
                builder: (context, state) =>
                    const _LearningDestinationPlaceholder(
                  destinationName: 'Classrooms',
                  icon: Icons.school_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learning/explore',
                name: 'learning-explore',
                builder: (context, state) =>
                    const _LearningDestinationPlaceholder(
                  destinationName: 'Explore',
                  icon: Icons.explore_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learning/chat',
                name: 'learning-chat',
                builder: (context, state) => AndrilChatsListScreen(
                  key: const ValueKey('learning_chats_list_screen'),
                  moduleConfig: AndrilModuleConfig.learning,
                  onOpenConversation: (item) {
                    context.go(
                      '/learning/chat/${item.id}',
                      extra: item.partner,
                    );
                  },
                ),
                routes: [
                  GoRoute(
                    path: ':conversationId',
                    name: 'learning-chat-detail',
                    builder: (context, state) {
                      final conversationId =
                          state.pathParameters['conversationId'];
                      final partnerExtra = state.extra is AndrilModuleProfile
                          ? state.extra as AndrilModuleProfile
                          : null;

                      // Validate conversation against Learning module scope
                      final validation = ChatNavigationParams.validate(
                        rawModule: 'learning',
                        conversationId: conversationId,
                        partner: partnerExtra,
                        allowedConversationsByModule:
                            MockConversationCatalog.previewAllowedConversations,
                      );

                      if (!validation.isValid) {
                        return ChatRouteDeniedScreen(
                          reason: validation.denialReason ??
                              'Invalid Learning chat navigation parameters.',
                          onReturn: () => context.go('/learning/chat'),
                        );
                      }

                      final params = validation.params!;
                      final catalogPartner =
                          MockConversationCatalog.defaultPartnerFor(
                        params.moduleType,
                        params.conversationId,
                      );

                      if (catalogPartner == null) {
                        return ChatRouteDeniedScreen(
                          reason:
                              'Conversation "${params.conversationId}" is not available in Learning.',
                          onReturn: () => context.go('/learning/chat'),
                        );
                      }

                      // Verify partner consistency if extra was provided (reject spoofed partners).
                      if (partnerExtra != null) {
                        if (partnerExtra.moduleType !=
                                AndrilModuleType.learning ||
                            partnerExtra.name != catalogPartner.name ||
                            partnerExtra.avatarAsset !=
                                catalogPartner.avatarAsset) {
                          return ChatRouteDeniedScreen(
                            reason:
                                'Partner profile mismatch for conversation "${params.conversationId}".',
                            onReturn: () => context.go('/learning/chat'),
                          );
                        }
                      }

                      return AndrilChatScreen(
                        key: ValueKey('learning_chat_${params.conversationId}'),
                        moduleConfig: params.moduleConfig,
                        partner: catalogPartner,
                        conversationId: params.conversationId,
                        onBackPressed: () => context.go('/learning/chat'),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learning/profile',
                name: 'learning-profile',
                builder: (context, state) =>
                    const _LearningDestinationPlaceholder(
                  destinationName: 'Profile',
                  icon: Icons.person_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String? _handleRedirect(
  BuildContext context,
  GoRouterState state,
  LearningAccessPolicy policy,
) {
  final location = state.uri.path;
  final isWelcome = location == '/learning/welcome';
  final isDenied = location == '/learning/access-denied';
  final isOnboarding = location == '/learning/onboarding';

  // Public/unrestricted routes within Learning
  if (isWelcome || isDenied) {
    return null;
  }

  // Onboarding requires authenticated identity session
  if (isOnboarding) {
    if (!policy.isAuthenticated) {
      return '/learning/welcome';
    }
    return null;
  }

  // Handle protected /learning/... tab routes
  if (location.startsWith('/learning')) {
    if (!policy.isAuthenticated) {
      // Unauthenticated access fails closed to Welcome screen
      return '/learning/welcome';
    }
    if (!policy.isLearningActivated) {
      // Authenticated but unactivated access is directed to Access Denied
      return '/learning/access-denied';
    }
    return null;
  }

  // Module isolation: non-learning routes fail closed to learning welcome
  return '/learning/welcome';
}

/// Lightweight, presentation-only placeholder for unimplemented Learning tab destinations.
class _LearningDestinationPlaceholder extends StatelessWidget {
  final String destinationName;
  final IconData icon;

  const _LearningDestinationPlaceholder({
    required this.destinationName,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: LearningColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: LearningColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Learning $destinationName',
                  style: const TextStyle(
                    color: LearningColors.heading,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This feature is currently under active development. No production data or live services are available yet.',
                  style: TextStyle(
                    color: LearningColors.secondaryText,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Text(
                    'Feature Pending Implementation',
                    style: TextStyle(
                      color: LearningColors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Presentation-only screen for locked / denied Learning route access states.
class _AccessDeniedPlaceholderScreen extends StatelessWidget {
  const _AccessDeniedPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: LearningColors.background,
      appBar: AndrilModuleAppBar(),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: ErrorRetryCard(
              title: 'Access Restricted',
              message:
                  'Access to Learning destinations requires authentication and module activation.',
              icon: Icons.lock_outline_rounded,
            ),
          ),
        ),
      ),
    );
  }
}
