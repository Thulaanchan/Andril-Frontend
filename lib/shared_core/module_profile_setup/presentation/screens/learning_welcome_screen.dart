import 'package:flutter/material.dart';
import '../../domain/models/module_welcome_config.dart';
import '../widgets/module_welcome_layout.dart';

/// Screen 11 – Learning Welcome Screen.
///
/// Displays the approved Member-02 Learning onboarding welcome surface with:
/// - ANDRIL branding and tagline
/// - Learning-themed hero photograph
/// - Blue and purple decorative waves
/// - Learning module badge and progress indicator (01 / 03)
/// - Heading: "Start Your Learning Journey"
/// - Tagline: "Learn • Share • Grow"
/// - Feature highlights: "Learn New Skills", "Share Your Knowledge", "Connect with Learners"
/// - Actions: "Get Started", "Back to Module Selection", "Learn more"
/// - Privacy message: "Your Learning identity stays separate and private."
class LearningWelcomeScreen extends StatelessWidget {
  const LearningWelcomeScreen({
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
      config: config ?? ModuleWelcomeConfig.learning(),
      onGetStarted: onGetStarted,
      onBackToModuleSelection: onBackToModuleSelection,
      onLearnMore: onLearnMore,
    );
  }
}

