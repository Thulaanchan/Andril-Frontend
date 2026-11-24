import 'package:flutter/material.dart';

/// A controlled pagination indicator widget for the Welcome screen.
///
/// Renders exactly three circular indicator dots with an active accent of #0057FF
/// and an inactive color of #CBD5E1. Provides accessible touch targets and
/// callbacks without introducing automatic timers or internal navigation.
class WelcomePageIndicator extends StatelessWidget {
  /// Total number of indicators rendered.
  static const int count = 3;

  /// Visible dot diameter in logical pixels.
  static const double dotDiameter = 8.0;

  /// Active accent color (#0057FF).
  static const Color activeColor = Color(0xFF0057FF);

  /// Inactive dot color (#CBD5E1).
  static const Color inactiveColor = Color(0xFFCBD5E1);

  /// The currently active page index (0, 1, or 2).
  final int activeIndex;

  /// Optional callback invoked when a specific indicator dot is tapped.
  final ValueChanged<int>? onIndicatorTapped;

  /// Creates a [WelcomePageIndicator].
  const WelcomePageIndicator({
    super.key,
    required this.activeIndex,
    this.onIndicatorTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Safely clamp activeIndex to valid 0..2 bounds to guard against out-of-range values.
    final int safeIndex = activeIndex.clamp(0, count - 1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final bool isActive = index == safeIndex;

        return Semantics(
          button: onIndicatorTapped != null,
          label: 'Page ${index + 1} of $count',
          selected: isActive,
          child: InkResponse(
            onTap: onIndicatorTapped != null
                ? () => onIndicatorTapped!(index)
                : null,
            radius: 24,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: dotDiameter,
                  height: dotDiameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
