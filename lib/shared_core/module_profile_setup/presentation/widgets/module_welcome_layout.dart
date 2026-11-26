import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/components/m2_buttons.dart';
import '../../domain/models/module_welcome_config.dart';
import 'module_feature_card.dart';
import 'module_welcome_hero_header.dart';
import 'module_welcome_wave_divider.dart';

/// Scaffolding layout that assembles the complete responsive module welcome screen.
class ModuleWelcomeLayout extends StatelessWidget {
  const ModuleWelcomeLayout({
    super.key,
    required this.config,
    required this.onGetStarted,
    required this.onBackToModuleSelection,
    this.onLearnMore,
    this.isSocialAuthorizedByServer = true,
  });

  final ModuleWelcomeConfig config;
  final VoidCallback onGetStarted;
  final VoidCallback onBackToModuleSelection;
  final VoidCallback? onLearnMore;
  final bool isSocialAuthorizedByServer;

  void _handleGetStarted(BuildContext context) {
    if (config.moduleId == 'social' && !isSocialAuthorizedByServer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Social is restricted to members aged 18 and older. Module eligibility required.',
          ),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    onGetStarted();
  }

  void _showLearnMoreDialog(BuildContext context) {
    if (onLearnMore != null) {
      onLearnMore!();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(config.moduleIcon, color: config.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'About ${config.moduleTitle}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                config.supportingDescription,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: config.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: config.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        config.privacyMessage,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: config.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              M2PrimaryButton(
                text: 'Got it',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: config.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header section
                    ModuleWelcomeHeroHeader(config: config),
                    const SizedBox(height: 4),

                    // Layered decorative wave divider
                    ModuleWelcomeWaveDivider(
                      waveColors: config.waveColors,
                      height: 44,
                    ),
                    const SizedBox(height: 16),

                    // Vertically stacked feature highlights matching finalized designs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          for (final feature in config.features) ...[
                            ModuleFeatureCard(
                              feature: feature,
                              primaryColor: config.primaryColor,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Primary button ("Get Started")
                          M2PrimaryButton(
                            text: config.primaryButtonText,
                            onPressed: () => _handleGetStarted(context),
                          ),
                          const SizedBox(height: 8),

                          // Secondary button ("Back to Module Selection")
                          M2SecondaryButton(
                            text: config.secondaryButtonText,
                            onPressed: onBackToModuleSelection,
                          ),

                          // Optional auxiliary link ("Learn more")
                          if (config.learnMoreText != null) ...[
                            const SizedBox(height: 4),
                            Center(
                              child: TextButton(
                                onPressed: () => _showLearnMoreDialog(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: config.primaryColor,
                                ),
                                child: Text(
                                  config.learnMoreText!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: config.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Optional Safety Notice (e.g. Social 18+ restriction)
                    if (config.safetyMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          config.safetyMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Mandatory Privacy Isolation Message
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        config.privacyMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
