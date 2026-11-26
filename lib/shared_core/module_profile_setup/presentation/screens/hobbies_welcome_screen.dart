import 'package:flutter/material.dart';
import '../../domain/models/module_welcome_config.dart';
import '../widgets/module_welcome_layout.dart';

/// Screen 13 – Hobbies Welcome Screen.
///
/// Displays the approved Member-02 Hobbies onboarding welcome surface with:
/// - ANDRIL branding and tagline
/// - Hobbies-themed hero photograph
/// - Teal and green decorative waves
/// - Hobbies module badge and progress indicator (01 / 03)
/// - Heading: "Explore Your Hobbies"
/// - Tagline: "Explore • Create • Connect"
/// - Feature highlights: "Find Hobby Friends", "Join Clubs", "Explore Andril Map"
/// - Actions: "Get Started", "Back to Module Selection"
/// - Privacy message: "Your Hobbies identity stays separate and private."
class HobbiesWelcomeScreen extends StatelessWidget {
  const HobbiesWelcomeScreen({
    super.key,
    required this.onGetStarted,
    required this.onBackToModuleSelection,
    this.onLearnMore,
    this.config,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onBackToModuleSelection;
  final VoidCallback? onLearnMore;
  final ModuleWelcomeConfig? config;

  @override
  Widget build(BuildContext context) {
    return ModuleWelcomeLayout(
      config: config ?? ModuleWelcomeConfig.hobbies(),
      onGetStarted: onGetStarted,
      onBackToModuleSelection: onBackToModuleSelection,
      onLearnMore: onLearnMore,
    );
  }
}

