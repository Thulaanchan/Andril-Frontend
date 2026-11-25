import 'package:flutter/material.dart';
import 'package:andril_mobile/app/themes/social/social_theme.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/andril_module_app_bar.dart';

/// Header widget for Social Home (S21).
///
/// Follows M5-FE-S21-UI-04 requirements:
/// - Wraps [AndrilModuleAppBar] with Royal Purple badge (#330099), Cream background (#FAF7F2),
///   notification bell with unread indicator badge, and optional search action.
/// - Renders welcoming heading with verified user display name.
/// - Renders circular photo avatar with network fallback.
class SocialHomeHeader extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final int unreadNotificationsCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;

  const SocialHomeHeader({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.unreadNotificationsCount = 0,
    this.onNotificationTap,
    this.onSearchTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGreetingName =
        displayName.isNotEmpty ? displayName : 'Explorer';

    return Container(
      color: AndrilSocialColors.cream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrapped AndrilModuleAppBar
          AndrilModuleAppBar(
            moduleName: 'Social',
            badgeColor: AndrilSocialColors.royalPurple,
            badgeTextColor: Colors.white,
            backgroundColor: AndrilSocialColors.cream,
            foregroundColor: AndrilSocialColors.ink,
            onSearchTap: onSearchTap,
            onNotificationTap: onNotificationTap,
          ),
          // User Greeting and Avatar row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AndrilSocialColors.copper,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        effectiveGreetingName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AndrilSocialColors.ink,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onProfileTap,
                  child: Semantics(
                    label: '$effectiveGreetingName profile picture',
                    button: onProfileTap != null,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AndrilSocialColors.copper.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AndrilSocialColors.faintPurple,
                        backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                            ? NetworkImage(avatarUrl!)
                            : null,
                        child: (avatarUrl == null || avatarUrl!.isEmpty)
                            ? Text(
                                effectiveGreetingName.isNotEmpty
                                    ? effectiveGreetingName[0].toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                  color: AndrilSocialColors.royalPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero banner carousel card for Social Home (S21).
///
/// Features:
/// - Rich gradient (Royal Purple to Deep Violet).
/// - Title: "Discover Meaningful Connections".
/// - Subtitle describing matchmaking.
/// - Minimum 48dp "Explore People →" CTA pill button.
/// - 4-dot carousel indicator.
/// - Responsive [Wrap] layout preventing pixel overflow at 320dp and text scale 1.3.
class SocialHeroBanner extends StatelessWidget {
  final VoidCallback? onExploreTap;
  final int activeIndex;
  final int totalDots;

  const SocialHeroBanner({
    super.key,
    this.onExploreTap,
    this.activeIndex = 0,
    this.totalDots = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            AndrilSocialColors.royalPurple,
            Color(0xFF5A189A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AndrilSocialColors.royalPurple.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'DISCOVER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Heading
          const Text(
            'Discover Meaningful\nConnections',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          // Subtitle
          Text(
            'Explore verified profiles aligned with your interests and values.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // CTA Wrap: Pill button + 4-dot indicator (responsive wrap)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              // "Explore People →" CTA Button (minimum 48dp height)
              ElevatedButton(
                onPressed: onExploreTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AndrilSocialColors.royalPurple,
                  elevation: 0,
                  minimumSize: const Size(140, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore People',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
              // Dot indicators
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalDots, (index) {
                  final isActive = index == activeIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
