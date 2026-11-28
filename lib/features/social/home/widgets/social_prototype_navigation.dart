import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// ANDRIL Social 2.0 — Liquid Glass Floating Bubble Navigation
///
/// Features:
/// - Floating frosted-glass dock pill with warm peach-tinted translucent surface.
/// - BackdropFilter with soft 16px background blur.
/// - Delicate reflective copper border with subtle glass highlight.
/// - Raised circular lavender-glass active bubble.
/// - Liquid stretching effect during transit (stretches along travel axis, squashes vertically).
/// - Gentle spring settling animation (Curves.easeOutBack).
/// - Active icon in deep purple (#330099) and prominent bold label.
/// - Muted plum/copper-neutral inactive icons with accessible contrast.
/// - Five preserved destinations: Home (S21), Zones (S19), Explore (S09), Chat (S17), Profile (S20).
/// - Accessible semantics and reduced-motion support.
class SocialPrototypeNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SocialPrototypeNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<SocialPrototypeNavigation> createState() =>
      _SocialPrototypeNavigationState();
}

class _SocialPrototypeNavigationState extends State<SocialPrototypeNavigation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _positionAnimation;
  int _fromIndex = 0;
  int _toIndex = 0;

  static const List<_TabItemData> _tabs = [
    _TabItemData(
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Home',
    ),
    _TabItemData(
      activeIcon: Icons.groups_rounded,
      inactiveIcon: Icons.groups_outlined,
      label: 'Zones',
    ),
    _TabItemData(
      activeIcon: Icons.explore_rounded,
      inactiveIcon: Icons.explore_outlined,
      label: 'Explore',
    ),
    _TabItemData(
      activeIcon: Icons.chat_bubble_rounded,
      inactiveIcon: Icons.chat_bubble_outline_rounded,
      label: 'Chat',
    ),
    _TabItemData(
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex.clamp(0, 4);
    _toIndex = widget.currentIndex.clamp(0, 4);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _positionAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(SocialPrototypeNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final clampedNew = widget.currentIndex.clamp(0, 4);
      final clampedOld = oldWidget.currentIndex.clamp(0, 4);
      final reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (reduceMotion) {
        _fromIndex = clampedNew;
        _toIndex = clampedNew;
        _controller.value = 1.0;
        setState(() {});
      } else {
        _fromIndex = clampedOld;
        _toIndex = clampedNew;
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If keyboard is open, do not show floating navigation to avoid covering inputs
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardInset > 0) {
      return const SizedBox.shrink();
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalMargin = screenWidth < 380 ? 12.0 : 16.0;

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalMargin,
        right: horizontalMargin,
        bottom: math.max(bottomPadding, 10.0),
        top: 4.0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dockWidth = constraints.maxWidth;
          final tabWidth = dockWidth / _tabs.length;
          const dockHeight = 64.0;
          const bubbleSize = 44.0;

          return SizedBox(
            height: dockHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // 1. Frosted Glass Dock Container
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32.0),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF330099).withValues(alpha: 0.12),
                          blurRadius: 20.0,
                          offset: const Offset(0, 8),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color:
                              const Color(0xFFC47A44).withValues(alpha: 0.10),
                          blurRadius: 10.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32.0),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            // Warm peach-tinted translucent glass surface (#F3DCD4)
                            color:
                                const Color(0xFFF3DCD4).withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(32.0),
                            border: Border.all(
                              color: const Color(0xFFC47A44)
                                  .withValues(alpha: 0.40),
                              width: 1.2,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.45),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Liquid Glass Active Bubble (animated)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = _positionAnimation.value;
                    final currentPos = ui.lerpDouble(
                      _fromIndex.toDouble(),
                      _toIndex.toDouble(),
                      t,
                    )!;

                    // Liquid stretching: max stretch occurs mid-flight (around t = 0.5)
                    final rawT = _controller.value;
                    final stretch = math.sin(math.pi * rawT.clamp(0.0, 1.0));
                    // Stretch horizontally, squash vertically to preserve liquid volume
                    final scaleX = 1.0 + 0.22 * stretch;
                    final scaleY = 1.0 - 0.12 * stretch;

                    final bubbleLeft =
                        currentPos * tabWidth + (tabWidth - bubbleSize) / 2;
                    // Centered vertically over icon
                    const bubbleTop = (dockHeight - bubbleSize) / 2 - 4.0;

                    return Positioned(
                      left: bubbleLeft,
                      top: bubbleTop,
                      child: Transform.scale(
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: Container(
                          width: bubbleSize,
                          height: bubbleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Translucent lavender active glass (#E7D8F8)
                            color:
                                const Color(0xFFE7D8F8).withValues(alpha: 0.88),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.80),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF330099)
                                    .withValues(alpha: 0.25),
                                blurRadius: 10.0,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.45),
                                blurRadius: 4.0,
                                offset: const Offset(0, -1),
                              ),
                            ],
                            gradient: const RadialGradient(
                              center: Alignment(-0.3, -0.4),
                              radius: 0.85,
                              colors: [
                                Colors.white,
                                Color(0xFFE7D8F8),
                                Color(0xFFD3BEF0),
                              ],
                              stops: [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 3. Tab Items Row (Interactive, Accessible, High Contrast)
                Positioned.fill(
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      final tab = _tabs[index];
                      final isSelected = index == widget.currentIndex;

                      return Expanded(
                        child: Semantics(
                          container: true,
                          excludeSemantics: true,
                          label:
                              '${tab.label} tab, ${isSelected ? "selected" : ""}',
                          selected: isSelected,
                          onTap: () => widget.onTap(index),
                          button: true,
                          child: InkWell(
                            onTap: () => widget.onTap(index),
                            borderRadius: BorderRadius.circular(28.0),
                            splashColor:
                                const Color(0xFFE7D8F8).withValues(alpha: 0.3),
                            highlightColor: Colors.transparent,
                            child: SizedBox(
                              height: dockHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 2.0),
                                  AnimatedScale(
                                    scale: isSelected ? 1.08 : 1.0,
                                    duration:
                                        (MediaQuery.maybeDisableAnimationsOf(
                                                    context) ??
                                                false)
                                            ? Duration.zero
                                            : const Duration(milliseconds: 250),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      isSelected
                                          ? tab.activeIcon
                                          : tab.inactiveIcon,
                                      size: 22.0,
                                      color: isSelected
                                          ? const Color(0xFF330099)
                                          : const Color(0xFF7A6672),
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  AnimatedDefaultTextStyle(
                                    duration:
                                        (MediaQuery.maybeDisableAnimationsOf(
                                                    context) ??
                                                false)
                                            ? Duration.zero
                                            : const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                    style: TextStyle(
                                      fontFamily: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.fontFamily,
                                      fontSize: 10.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF330099)
                                          : const Color(0xFF7A6672),
                                      letterSpacing: isSelected ? -0.1 : 0.0,
                                    ),
                                    child: Text(tab.label),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabItemData {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  const _TabItemData({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}
