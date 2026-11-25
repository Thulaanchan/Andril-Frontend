import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';

/// Reusable Top Header for Authentication screens (Screens 04 through 07).
///
/// Includes:
/// - Back arrow button on top-left (when onBack is provided)
/// - Centered ANDRIL title
/// - Emblem or circular badge illustration
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.onBack,
    this.centerBadge,
    this.showLogoEmblem = false,
    this.emblemSize = 88.0,
  });

  final VoidCallback? onBack;
  final Widget? centerBadge;
  final bool showLogoEmblem;
  final double emblemSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top Bar: Back Button and Title
        SizedBox(
          height: 48.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (onBack != null)
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: M2Colors.primaryTeal,
                      size: 24.0,
                    ),
                    onPressed: onBack,
                    tooltip: 'Back',
                  ),
                ),
              const Center(
                child: Text(
                  'ANDRIL',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: M2Colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: M2Spacing.sm),

        // Center Emblem or Themed Badge Icon
        if (showLogoEmblem)
          Center(
            child: Image.asset(
              'assets/branding/andril_black_logo.png',
              width: emblemSize,
              height: emblemSize,
              fit: BoxFit.contain,
              semanticLabel: 'ANDRIL Emblem',
            ),
          )
        else if (centerBadge != null)
          Center(child: centerBadge!),
      ],
    );
  }
}
