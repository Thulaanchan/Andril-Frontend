import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';

/// Animated three-dot loading / transition indicator for the splash screen.
class AnimatedDotsIndicator extends StatefulWidget {
  const AnimatedDotsIndicator({
    super.key,
    this.dotSize = 7.0,
    this.dotSpacing = 8.0,
    this.color = M2Colors.primaryTealLight,
  });

  final double dotSize;
  final double dotSpacing;
  final Color color;

  @override
  State<AnimatedDotsIndicator> createState() => _AnimatedDotsIndicatorState();
}

class _AnimatedDotsIndicatorState extends State<AnimatedDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.25;
            final progress = (_controller.value - delay) % 1.0;
            // Smooth sine wave bounce/scale
            final scale = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(progress * 2 * math.pi));
            final opacity = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(progress * 2 * math.pi));

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.dotSpacing / 2),
              child: Opacity(
                opacity: opacity.clamp(0.2, 1.0),
                child: Transform.scale(
                  scale: scale.clamp(0.5, 1.2),
                  child: Container(
                    width: widget.dotSize,
                    height: widget.dotSize,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
