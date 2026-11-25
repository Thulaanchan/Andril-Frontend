import 'package:flutter/material.dart';
import '../colors/m2_colors.dart';
import '../spacing/m2_spacing.dart';
import '../typography/m2_typography.dart';

/// ANDRIL Member-02 Reusable Primary Action Button.
///
/// Matches the finalized onboarding designs with a rich teal gradient,
/// rounded pill shape, and optional circular arrow forward indicator.
class M2PrimaryButton extends StatelessWidget {
  const M2PrimaryButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.showArrow = true,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool showArrow;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.0,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? const LinearGradient(
                colors: [Color(0xFF94A3B8), Color(0xFFCBD5E1)],
              )
            : M2Colors.primaryButtonGradient,
        borderRadius: BorderRadius.circular(M2Spacing.radiusPill),
        boxShadow: onPressed == null
            ? []
            : [
                BoxBoxShadow(
                  color: M2Colors.primaryTeal.withValues(alpha: 0.3),
                  blurRadius: 14.0,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(M2Spacing.radiusPill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: M2Spacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showArrow) const SizedBox(width: 32.0),
                Expanded(
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 22.0,
                            height: 22.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            text,
                            style: M2Typography.buttonPrimary,
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
                if (showArrow && !isLoading)
                  Container(
                    width: 34.0,
                    height: 34.0,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20.0,
                    ),
                  )
                else if (showArrow)
                  const SizedBox(width: 32.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper for BoxShadow with modern Flutter compatibility
class BoxBoxShadow extends BoxShadow {
  const BoxBoxShadow({
    super.color,
    super.offset,
    super.blurRadius,
    super.spreadRadius,
  });
}

/// ANDRIL Member-02 Reusable Secondary Action Button.
///
/// Matches the finalized designs with a clean outlined pill shape,
/// solid teal border, and teal typography.
class M2SecondaryButton extends StatelessWidget {
  const M2SecondaryButton({
    required this.text,
    required this.onPressed,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.0,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: Border.all(
          color: M2Colors.primaryTeal,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(M2Spacing.radiusPill),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(M2Spacing.radiusPill),
          child: Center(
            child: Text(
              text,
              style: M2Typography.buttonSecondary,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
