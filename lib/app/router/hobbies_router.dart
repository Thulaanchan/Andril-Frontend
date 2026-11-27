import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/hobbies/gallery/presentation/viewmodels/hobbies_gallery_viewmodel.dart';
import '../../features/hobbies/gallery/presentation/widgets/hobbies_gallery_binding.dart';
import '../../features/hobbies/presentation/widgets/andril_hobbies_scaffold.dart';
import '../themes/hobbies/hobbies_colors.dart';
import '../themes/hobbies/hobbies_theme.dart';
import '../themes/hobbies/hobbies_typography.dart';

/// Contract for evaluating route access to protected Hobbies module surfaces.
///
/// Production gates fail closed until M2 publishes official authentication
/// and module-activation contracts.
abstract interface class HobbiesAccessPolicy {
  /// Whether the user has an active, authenticated identity session.
  bool get isAuthenticated;

  /// Whether the user has completed onboarding and activated the Hobbies module.
  bool get isHobbiesActivated;
}

/// Default production access policy failing closed pending M2 integration.
class ProductionHobbiesAccessPolicy implements HobbiesAccessPolicy {
  const ProductionHobbiesAccessPolicy();

  @override
  bool get isAuthenticated => false;

  @override
  bool get isHobbiesActivated => false;
}

/// Route path constants for the Hobbies module.
abstract final class HobbiesRoutes {
  HobbiesRoutes._();

  static const String welcome = '/hobbies/welcome';
  static const String accessDenied = '/hobbies/access-denied';
  static const String home = '/hobbies/home';
  static const String gallery = '/hobbies/gallery';
}

/// Creates and configures the standalone [GoRouter] instance for the Hobbies module.
///
/// Security & Architecture Rules:
/// - Sole Injection Path: Uses [galleryViewModelBuilder] as the only trusted ViewModel
///   creation mechanism. Route arguments or `state.extra` are strictly ignored to prevent
///   arbitrary, stale, or unverified ViewModels from bypassing active profile boundaries.
/// - Route Ownership: Creates one route-owned ViewModel per route entry and disposes it
///   upon route exit.
/// - Fail-Closed Fallback: When no trusted [galleryViewModelBuilder] is provided, renders
///   a safe pending screen without fabricating mock media or credentials.
/// - Reactive Session Boundary: Optionally accepts [refreshListenable] (or listens to [accessPolicy]
///   when it implements [Listenable]) to trigger immediate route re-evaluation on logout or
///   module deactivation.
GoRouter createHobbiesRouter({
  HobbiesAccessPolicy accessPolicy = const ProductionHobbiesAccessPolicy(),
  HobbiesGalleryViewModel Function()? galleryViewModelBuilder,
  String initialLocation = HobbiesRoutes.home,
  List<NavigatorObserver>? observers,
  Listenable? refreshListenable,
}) {
  final Listenable? effectiveRefresh = refreshListenable ??
      (accessPolicy is Listenable ? accessPolicy as Listenable : null);

  return GoRouter(
    initialLocation: initialLocation,
    observers: observers,
    refreshListenable: effectiveRefresh,
    redirect: (BuildContext context, GoRouterState state) =>
        _handleHobbiesRedirect(context, state, accessPolicy),
    routes: <RouteBase>[
      GoRoute(
        path: HobbiesRoutes.welcome,
        name: 'hobbies-welcome',
        builder: (BuildContext context, GoRouterState state) =>
            _HobbiesWelcomeScreen(
          onContinue: () {
            if (accessPolicy.isAuthenticated &&
                accessPolicy.isHobbiesActivated) {
              context.go(HobbiesRoutes.home);
            } else {
              context.go(HobbiesRoutes.accessDenied);
            }
          },
        ),
      ),
      GoRoute(
        path: HobbiesRoutes.accessDenied,
        name: 'hobbies-access-denied',
        builder: (BuildContext context, GoRouterState state) =>
            const _HobbiesAccessDeniedScreen(),
      ),
      GoRoute(
        path: HobbiesRoutes.home,
        name: 'hobbies-home',
        builder: (BuildContext context, GoRouterState state) =>
            _HobbiesHomeScreen(
          onOpenGallery: () => context.push(HobbiesRoutes.gallery),
        ),
      ),
      GoRoute(
        path: HobbiesRoutes.gallery,
        name: 'hobbies-gallery',
        builder: (BuildContext context, GoRouterState state) {
          // Security Invariant: Arbitrary `state.extra` is strictly ignored.
          // Only the trusted injected builder is authorized to create the ViewModel.
          return _HobbiesGalleryRouteEntry(
            viewModelBuilder: galleryViewModelBuilder,
          );
        },
      ),
    ],
  );
}

/// Handles access-boundary redirection for all Hobbies module routes.
String? _handleHobbiesRedirect(
  BuildContext context,
  GoRouterState state,
  HobbiesAccessPolicy policy,
) {
  final String location = state.uri.path;
  final bool isWelcome = location == HobbiesRoutes.welcome;
  final bool isDenied = location == HobbiesRoutes.accessDenied;

  // Public/unrestricted routes within Hobbies
  if (isWelcome || isDenied) {
    return null;
  }

  // Handle protected /hobbies/... routes
  if (location.startsWith('/hobbies')) {
    if (!policy.isAuthenticated) {
      // Unauthenticated access fails closed to Welcome screen
      return HobbiesRoutes.welcome;
    }
    if (!policy.isHobbiesActivated) {
      // Authenticated but non-activated access is directed to Access Denied
      return HobbiesRoutes.accessDenied;
    }
    return null;
  }

  // Module isolation: non-hobbies routes fail closed to hobbies welcome
  return HobbiesRoutes.welcome;
}

/// Route-level entry managing ViewModel lifecycle and fallback rendering.
class _HobbiesGalleryRouteEntry extends StatefulWidget {
  final HobbiesGalleryViewModel Function()? viewModelBuilder;

  const _HobbiesGalleryRouteEntry({
    this.viewModelBuilder,
  });

  @override
  State<_HobbiesGalleryRouteEntry> createState() =>
      _HobbiesGalleryRouteEntryState();
}

class _HobbiesGalleryRouteEntryState extends State<_HobbiesGalleryRouteEntry> {
  HobbiesGalleryViewModel? _routeOwnedViewModel;

  @override
  void initState() {
    super.initState();
    if (widget.viewModelBuilder != null) {
      _routeOwnedViewModel = widget.viewModelBuilder!();
    }
  }

  @override
  void dispose() {
    _routeOwnedViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HobbiesGalleryViewModel? vm = _routeOwnedViewModel;

    if (vm == null) {
      return const _HobbiesGalleryPendingScreen();
    }

    return HobbiesGalleryBinding(
      viewModel: vm,
      autoLoad: true,
    );
  }
}

/// Provisional route-integration UI: Welcome / landing screen for the Hobbies module.
class _HobbiesWelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const _HobbiesWelcomeScreen({
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AndrilHobbiesScaffold(
      title: 'Welcome to Hobbies',
      showWave: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.palette_outlined,
                size: 64.0,
                color: HobbiesColors.primary,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Explore Hobbies & Creative Media',
                textAlign: TextAlign.center,
                style: HobbiesTypography.screenTitle.copyWith(
                  color: HobbiesTheme.textDark,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Explore your interests and share your hobby moments.',
                textAlign: TextAlign.center,
                style: HobbiesTypography.secondaryText.copyWith(
                  color: HobbiesTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24.0),
              FilledButton(
                key: const Key('hobbies_welcome_continue_button'),
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: HobbiesColors.primary,
                  foregroundColor: HobbiesTheme.textDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 14.0,
                  ),
                ),
                child: const Text('Enter Hobbies'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Provisional route-integration UI: Access denied screen when Hobbies is not activated.
class _HobbiesAccessDeniedScreen extends StatelessWidget {
  const _HobbiesAccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return AndrilHobbiesScaffold(
      title: 'Access Restricted',
      showWave: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.lock_outline_rounded,
                size: 64.0,
                color: HobbiesTheme.errorColor,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Hobbies Profile Inactive',
                textAlign: TextAlign.center,
                style: HobbiesTypography.screenTitle.copyWith(
                  color: HobbiesTheme.textDark,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Access to Hobbies features requires an active Hobbies profile and verified account.',
                textAlign: TextAlign.center,
                style: HobbiesTypography.secondaryText.copyWith(
                  color: HobbiesTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Provisional route-integration UI: Authorized Hobbies Home screen providing entry point into Gallery.
class _HobbiesHomeScreen extends StatelessWidget {
  final VoidCallback onOpenGallery;

  const _HobbiesHomeScreen({
    required this.onOpenGallery,
  });

  @override
  Widget build(BuildContext context) {
    return AndrilHobbiesScaffold(
      title: 'Hobbies Home',
      showWave: true,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Card(
            key: const Key('hobbies_home_gallery_card'),
            color: HobbiesTheme.cardSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: const BorderSide(
                color: Color(0xFFD1FAE5),
                width: 1.0,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16.0),
              onTap: onOpenGallery,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: HobbiesColors.primary,
                        size: 26.0,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Photo Gallery',
                            style: HobbiesTypography.sectionTitle.copyWith(
                              color: HobbiesTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Manage and showcase your hobby moments',
                            style: HobbiesTypography.caption.copyWith(
                              color: HobbiesTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: HobbiesColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Provisional route-integration UI: Fail-closed fallback screen when data service is unconnected.
class _HobbiesGalleryPendingScreen extends StatelessWidget {
  const _HobbiesGalleryPendingScreen();

  @override
  Widget build(BuildContext context) {
    return AndrilHobbiesScaffold(
      title: 'Photo Gallery',
      showWave: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.cloud_off_rounded,
                size: 56.0,
                color: HobbiesTheme.textSecondary,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Gallery Integration Pending',
                textAlign: TextAlign.center,
                style: HobbiesTypography.screenTitle.copyWith(
                  color: HobbiesTheme.textDark,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'The Hobbies Photo Gallery data service has not yet been connected to backend storage.',
                textAlign: TextAlign.center,
                style: HobbiesTypography.secondaryText.copyWith(
                  color: HobbiesTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
