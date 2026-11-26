import 'package:flutter/material.dart';
import '../../domain/models/module_welcome_config.dart';
import 'hobbies_welcome_screen.dart';
import 'learning_welcome_screen.dart';
import 'social_welcome_screen.dart';

/// Unified entry point for all three module welcome screens (Screens 11, 13, and 15).
class ModuleWelcomeScreen extends StatelessWidget {
  const ModuleWelcomeScreen({
    super.key,
    required this.config,
    required this.onGetStarted,
    required this.onBackToModuleSelection,
    this.onLearnMore,
    this.isSocialAuthorizedByServer = true,
  });

  /// Factory constructor for Screen 11 – Learning Welcome.
  const ModuleWelcomeScreen.learning({
    super.key,
    required this.onGetStarted,
    required this.onBackToModuleSelection,
    this.onLearnMore,
  })  : config = null,
        isSocialAuthorizedByServer = true;

  /// Factory constructor for Screen 13 – Hobbies Welcome.
  const ModuleWelcomeScreen.hobbies({
    super.key,
    required this.onGetStarted,
    required this.onBackToModuleSelection,
    this.onLearnMore,
  })  : config = null,
        isSocialAuthorizedByServer = true;

  /// Factory constructor for Screen 15 – Social Welcome.
  const ModuleWelcomeScreen.social({
    super.key,
    required this.onGetStarted,
    required this.onBackToModuleSelection,
    this.onLearnMore,
    this.isSocialAuthorizedByServer = true,
  }) : config = null;

  /// Dynamic dispatch based on module identifier ('learning', 'hobbies', 'social').
  factory ModuleWelcomeScreen.fromModuleId({
    Key? key,
    required String moduleId,
    required VoidCallback onGetStarted,
    required VoidCallback onBackToModuleSelection,
    VoidCallback? onLearnMore,
    bool isSocialAuthorizedByServer = true,
  }) {
    switch (moduleId.toLowerCase()) {
      case 'learning':
        return ModuleWelcomeScreen(
          key: key,
          config: ModuleWelcomeConfig.learning(),
          onGetStarted: onGetStarted,
          onBackToModuleSelection: onBackToModuleSelection,
          onLearnMore: onLearnMore,
        );
      case 'hobbies':
        return ModuleWelcomeScreen(
          key: key,
          config: ModuleWelcomeConfig.hobbies(),
          onGetStarted: onGetStarted,
          onBackToModuleSelection: onBackToModuleSelection,
          onLearnMore: onLearnMore,
        );
      case 'social':
        return ModuleWelcomeScreen(
          key: key,
          config: ModuleWelcomeConfig.social(),
          onGetStarted: onGetStarted,
          onBackToModuleSelection: onBackToModuleSelection,
          onLearnMore: onLearnMore,
          isSocialAuthorizedByServer: isSocialAuthorizedByServer,
        );
      default:
        return ModuleWelcomeScreen(
          key: key,
          config: ModuleWelcomeConfig.learning(),
          onGetStarted: onGetStarted,
          onBackToModuleSelection: onBackToModuleSelection,
          onLearnMore: onLearnMore,
        );
    }
  }

  final ModuleWelcomeConfig? config;
  final VoidCallback onGetStarted;
  final VoidCallback onBackToModuleSelection;
  final VoidCallback? onLearnMore;
  final bool isSocialAuthorizedByServer;

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = config ?? ModuleWelcomeConfig.learning();
    switch (effectiveConfig.moduleId) {
      case 'hobbies':
        return HobbiesWelcomeScreen(
          config: effectiveConfig,
          onGetStarted: onGetStarted,
          onBackToModuleSelection: onBackToModuleSelection,
          onLearnMore: onLearnMore,
        );
      case 'social':
        return SocialWelcomeScreen(
          config: effectiveConfig,
          onGetStarted: onGetStarted,
          onBackToModuleSelection: onBackToModuleSelection,
          onLearnMore: onLearnMore,
          isSocialAuthorizedByServer: isSocialAuthorizedByServer,
        );
      case 'learning':
      default:
        return LearningWelcomeScreen(
          config: effectiveConfig,
          onGetStarted: onGetStarted,
          onBackToModuleSelection: onBackToModuleSelection,
          onLearnMore: onLearnMore,
        );
    }
  }
}

