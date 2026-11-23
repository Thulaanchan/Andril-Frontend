import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/learning/profile/screens/learning_welcome_screen.dart';
import '../../features/shared/presentation/scaffolds/learning_scaffold.dart';
import '../../features/shared/presentation/widgets/andril_module_app_bar.dart';
import '../../features/shared/presentation/widgets/error_retry_card.dart';
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

/// Creates and configures the [GoRouter] instance for the Learning module.
GoRouter createLearningRouter({
  LearningAccessPolicy accessPolicy = const ProductionLearningAccessPolicy(),
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
                builder: (context, state) =>
                    const _LearningDestinationPlaceholder(
                  destinationName: 'Home',
                  icon: Icons.home_rounded,
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
                builder: (context, state) =>
                    const _LearningDestinationPlaceholder(
                  destinationName: 'Chat',
                  icon: Icons.chat_bubble_rounded,
                ),
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

  // Public/unrestricted routes within Learning
  if (isWelcome || isDenied) {
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
