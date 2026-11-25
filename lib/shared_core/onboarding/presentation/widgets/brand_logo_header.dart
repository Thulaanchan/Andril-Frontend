import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';
import '../../../../app/themes/shared_core/typography/m2_typography.dart';

/// ANDRIL Member-02 Brand Logo and Tagline Header.
///
/// Features the official "A" emblem, bold brand lettering, and
/// the project tagline "Every Path Begins Here".
class BrandLogoHeader extends StatelessWidget {
  const BrandLogoHeader({
    super.key,
    this.emblemSize = 130.0,
    this.showTagline = true,
    this.spacing = M2Spacing.sm,
  });

  final double emblemSize;
  final bool showTagline;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // "A" Emblem Asset
        Image.asset(
          'assets/branding/andril_black_logo.png',
          width: emblemSize,
          height: emblemSize,
          fit: BoxFit.contain,
          semanticLabel: 'ANDRIL Emblem Logo',
        ),
        SizedBox(height: spacing),

        // "ANDRIL" Brand Wordmark
        Text(
          'ANDRIL',
          style: TextStyle(
            fontSize: emblemSize > 100 ? 32.0 : 22.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: Colors.black,
            fontFamily: 'serif',
          ),
          textAlign: TextAlign.center,
        ),

        // Subtitle Tagline
        if (showTagline) ...[
          const SizedBox(height: M2Spacing.xs),
          Text(
            'Every Path Begins Here',
            style: emblemSize > 100
                ? M2Typography.splashTagline
                : M2Typography.splashTagline.copyWith(fontSize: 13.0),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
