import 'package:flutter/material.dart';
import '../../domain/models/module_welcome_config.dart';
import '../widgets/module_welcome_layout.dart';

/// Screen 15 – Social Welcome Screen.
///
/// Displays the approved Member-02 Social onboarding welcome surface with:
/// - ANDRIL branding and tagline
/// - Social-themed hero photograph
/// - Purple and orange decorative waves
/// - Social module badge (progress indicator omitted per finalized design reference)
/// - Heading: "Find your people."
/// - Feature highlights: "Smart Matching", "Real Conversations", "Shared Experiences"
/// - Actions: "Get Started", "Back to Module Selection", "Learn more"
/// - Safety message: "Social is available for users aged 18+ only."
/// - Privacy message: "Your information is private and not shared with other modules."
/// - Eligibility enforcement: requires backend-confirmed eligibility.
class SocialWelcomeScreen extends StatelessWidget {
  const SocialWelcomeScreen({
    super.key,
    required this.onGetStarted,
    required this.onBackToModuleSelection,
    this.onLearnMore,
    this.isSocialAuthorizedByServer = true,
    this.config,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onBackToModuleSelection;
  final VoidCallback? onLearnMore;
  final bool isSocialAuthorizedByServer;
  final ModuleWelcomeConfig? config;

  @override
  Widget build(BuildContext context) {
    return ModuleWelcomeLayout(
      config: config ?? ModuleWelcomeConfig.social(),
      onGetStarted: onGetStarted,
      onBackToModuleSelection: onBackToModuleSelection,
      onLearnMore: onLearnMore,
      isSocialAuthorizedByServer: isSocialAuthorizedByServer,
    );
  }
}

