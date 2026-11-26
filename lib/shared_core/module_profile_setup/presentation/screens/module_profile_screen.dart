import 'package:flutter/material.dart';
import '../../domain/models/profile_creation_config.dart';
import '../viewmodels/module_profile_viewmodel.dart';
import 'hobbies_profile_screen.dart';
import 'learning_profile_screen.dart';
import 'social_profile_screen.dart';

/// Unified entry point for all three module profile creation screens (Screens 12, 14, and 16).
class ModuleProfileScreen extends StatelessWidget {
  const ModuleProfileScreen({
    super.key,
    required this.config,
    this.viewModel,
    required this.onBack,
    required this.onContinue,
    this.isSocialAuthorizedByServer = true,
  });

  /// Factory constructor for Screen 12 – Learning Profile.
  factory ModuleProfileScreen.learning({
    Key? key,
    ModuleProfileViewModel? viewModel,
    required VoidCallback onBack,
    required VoidCallback onContinue,
  }) {
    return ModuleProfileScreen(
      key: key,
      config: ProfileCreationConfig.learning(),
      viewModel: viewModel,
      onBack: onBack,
      onContinue: onContinue,
      isSocialAuthorizedByServer: true,
    );
  }

  /// Factory constructor for Screen 14 – Hobbies Profile.
  factory ModuleProfileScreen.hobbies({
    Key? key,
    ModuleProfileViewModel? viewModel,
    required VoidCallback onBack,
    required VoidCallback onContinue,
  }) {
    return ModuleProfileScreen(
      key: key,
      config: ProfileCreationConfig.hobbies(),
      viewModel: viewModel,
      onBack: onBack,
      onContinue: onContinue,
      isSocialAuthorizedByServer: true,
    );
  }

  /// Factory constructor for Screen 16 – Social Profile.
  factory ModuleProfileScreen.social({
    Key? key,
    ModuleProfileViewModel? viewModel,
    required VoidCallback onBack,
    required VoidCallback onContinue,
    bool isSocialAuthorizedByServer = true,
  }) {
    return ModuleProfileScreen(
      key: key,
      config: ProfileCreationConfig.social(),
      viewModel: viewModel,
      onBack: onBack,
      onContinue: onContinue,
      isSocialAuthorizedByServer: isSocialAuthorizedByServer,
    );
  }

  /// Dynamic dispatch based on module identifier ('learning', 'hobbies', 'social').
  factory ModuleProfileScreen.fromModuleId({
    Key? key,
    required String moduleId,
    ModuleProfileViewModel? viewModel,
    required VoidCallback onBack,
    required VoidCallback onContinue,
    bool isSocialAuthorizedByServer = true,
  }) {
    switch (moduleId.toLowerCase()) {
      case 'learning':
        return ModuleProfileScreen.learning(
          key: key,
          viewModel: viewModel,
          onBack: onBack,
          onContinue: onContinue,
        );
      case 'hobbies':
        return ModuleProfileScreen.hobbies(
          key: key,
          viewModel: viewModel,
          onBack: onBack,
          onContinue: onContinue,
        );
      case 'social':
        return ModuleProfileScreen.social(
          key: key,
          viewModel: viewModel,
          onBack: onBack,
          onContinue: onContinue,
          isSocialAuthorizedByServer: isSocialAuthorizedByServer,
        );
      default:
        return ModuleProfileScreen.learning(
          key: key,
          viewModel: viewModel,
          onBack: onBack,
          onContinue: onContinue,
        );
    }
  }

  final ProfileCreationConfig config;
  final ModuleProfileViewModel? viewModel;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final bool isSocialAuthorizedByServer;

  @override
  Widget build(BuildContext context) {
    switch (config.moduleId.toLowerCase()) {
      case 'hobbies':
        return HobbiesProfileScreen(
          viewModel: viewModel,
          onBack: onBack,
          onContinue: onContinue,
        );
      case 'social':
        return SocialProfileScreen(
          viewModel: viewModel,
          isSocialAuthorizedByServer: isSocialAuthorizedByServer,
          onBack: onBack,
          onContinue: onContinue,
        );
      case 'learning':
      default:
        return LearningProfileScreen(
          viewModel: viewModel,
          onBack: onBack,
          onContinue: onContinue,
        );
    }
  }
}
