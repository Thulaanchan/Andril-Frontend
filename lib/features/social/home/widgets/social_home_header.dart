import 'package:flutter/material.dart';
import '../../../../app/themes/social/social_prototype_theme.dart';

/// S21 source layout, bound to the current identity and authorized callbacks.
class SocialHomeHeader extends StatelessWidget {
  final bool showBrandBar;
  final String displayName;
  final String? avatarUrl;
  final int unreadNotificationsCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;

  const SocialHomeHeader(
      {super.key,
      required this.displayName,
      this.showBrandBar = true,
      this.avatarUrl,
      this.unreadNotificationsCount = 0,
      this.onNotificationTap,
      this.onSearchTap,
      this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final name = displayName.trim().isEmpty ? 'Explorer' : displayName;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (showBrandBar)
        SocialHomeBrandBar(
            unreadNotificationsCount: unreadNotificationsCount,
            onNotificationTap: onNotificationTap,
            onSearchTap: onSearchTap,
            onProfileTap: onProfileTap),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('YOUR SOCIAL SPACE',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: SocialPrototypeColors.copperAccent,
                    letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text('Welcome back, $name!',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: SocialPrototypeColors.textPrimary,
                    letterSpacing: -.4)),
            const SizedBox(height: 4),
            const Text(
                'Meaningful connections start with you. Discover people, grow trust and reflect.',
                style: TextStyle(
                    fontSize: 13.5,
                    color: SocialPrototypeColors.textMuted,
                    height: 1.35)),
            const SizedBox(height: 16),
          ])),
    ]);
  }
}

/// Fixed brand header; greeting and content scroll independently, as in SocialFrame.
class SocialHomeBrandBar extends StatelessWidget {
  final int unreadNotificationsCount;
  final VoidCallback? onNotificationTap, onSearchTap, onProfileTap;
  const SocialHomeBrandBar(
      {super.key,
      this.unreadNotificationsCount = 0,
      this.onNotificationTap,
      this.onSearchTap,
      this.onProfileTap});
  @override
  Widget build(BuildContext context) => SafeArea(
      bottom: false,
      child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                      label: onProfileTap == null
                          ? 'ANDRIL'
                          : 'Open your Social profile',
                      image: onProfileTap == null,
                      button: onProfileTap != null,
                      child: InkWell(
                          onTap: onProfileTap,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                              height: 48,
                              width: 48,
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Image.asset(
                                      'assets/profile/social_black_logo.png',
                                      height: 32,
                                      fit: BoxFit.contain))))),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    // Retain an existing optional action; this is absent in the prototype-only fixture.
                    if (onSearchTap != null)
                      IconButton(
                          tooltip: 'Search people',
                          onPressed: onSearchTap,
                          icon: const Icon(Icons.search_rounded,
                              color: SocialPrototypeColors.textPrimary)),
                    SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(alignment: Alignment.center, children: [
                          Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: SocialPrototypeColors.borderLight),
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: .04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2))
                                  ])),
                          IconButton(
                              tooltip: 'Notifications',
                              constraints: const BoxConstraints.tightFor(
                                  width: 48, height: 48),
                              padding: EdgeInsets.zero,
                              onPressed: onNotificationTap,
                              icon: const Icon(Icons.notifications_none_rounded,
                                  size: 22,
                                  color: SocialPrototypeColors.textPrimary)),
                          if (unreadNotificationsCount > 0)
                            Positioned(
                                top: 13,
                                right: 14,
                                child: IgnorePointer(
                                    child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                            color: SocialPrototypeColors
                                                .copperAccent,
                                            shape: BoxShape.circle)))),
                        ])),
                  ]),
                ]),
          )));
}

/// The original banner artwork is a reusable media asset; the action remains a widget.
class SocialHeroBanner extends StatelessWidget {
  final VoidCallback? onExploreTap;
  final int activeIndex, totalDots;
  const SocialHeroBanner(
      {super.key, this.onExploreTap, this.activeIndex = 0, this.totalDots = 4});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        Semantics(
            button: true,
            label: 'Explore People',
            onTap: onExploreTap,
            child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                    onTap: onExploreTap,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: SocialPrototypeColors.borderLight),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x0C2D1155),
                                  blurRadius: 10,
                                  offset: Offset(0, 3))
                            ]),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.asset(
                                    'assets/profile/social_home_banner.png',
                                    fit: BoxFit.cover,
                                    excludeFromSemantics: true))))))),
        const SizedBox(height: 10),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                totalDots,
                (i) => Container(
                    margin: EdgeInsets.only(right: i == totalDots - 1 ? 0 : 6),
                    width: i == activeIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: i == activeIndex
                            ? SocialPrototypeColors.primaryPurple
                            : const Color(0xFFD8C8BC),
                        borderRadius: BorderRadius.circular(3))))),
        const SizedBox(height: 24),
      ]));
}
