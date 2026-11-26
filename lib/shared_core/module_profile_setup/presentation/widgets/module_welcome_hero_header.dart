import 'package:flutter/material.dart';
import '../../domain/models/module_welcome_config.dart';
import 'module_progress_badge.dart';

/// Top hero header displaying branding, hero imagery, badges, headline, and supporting copy.
class ModuleWelcomeHeroHeader extends StatelessWidget {
  const ModuleWelcomeHeroHeader({
    super.key,
    required this.config,
  });

  final ModuleWelcomeConfig config;

  static const String _logoAsset = 'assets/branding/andril_black_logo.png';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-right hero photo with gradient mask
        if (config.heroPhotoAsset != null)
          Positioned(
            top: 0,
            right: 0,
            width: 250,
            height: 170,
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.35, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                config.heroPhotoAsset!,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (context, error, stackTrace) {
                  // Graceful fallback when separate photograph asset is unbundled
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.2,
                        colors: [
                          config.primaryColor.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(top: 24, right: 24),
                    child: Icon(
                      config.moduleIcon,
                      size: 64,
                      color: config.primaryColor.withValues(alpha: 0.25),
                    ),
                  );
                },
              ),
            ),
          ),

        // Foreground content: Branding, Badge, Headline, Tagline
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ANDRIL Branding Logo
              Image.asset(
                _logoAsset,
                height: 32,
                fit: BoxFit.contain,
                semanticLabel: 'ANDRIL',
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'ANDRIL',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Color(0xFF0F172A),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Module badge and progress indicator
              ModuleProgressBadge(
                moduleTitle: config.moduleTitle,
                moduleIcon: config.moduleIcon,
                badgeBackgroundColor: config.badgeBackgroundColor,
                badgeTextColor: config.badgeTextColor,
                progressText: config.progressText,
              ),
              const SizedBox(height: 14),

              // Headline (e.g. "Start Your Learning Journey")
              Text.rich(
                TextSpan(
                  children: [
                    if (config.headingPrefix.isNotEmpty)
                      TextSpan(
                        text: config.headingPrefix,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                    TextSpan(
                      text: config.headingHighlight,
                      style: TextStyle(
                        color: config.primaryColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Supporting Description
              Text(
                config.supportingDescription,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),

              // Tagline Pill (if present, e.g. "Learn • Share • Grow")
              if (config.tagline != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: config.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: config.primaryColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    config.tagline!,
                    style: TextStyle(
                      color: config.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
