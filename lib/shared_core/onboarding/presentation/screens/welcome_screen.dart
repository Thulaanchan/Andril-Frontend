import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/components/m2_background_scaffold.dart';
import '../../../../app/themes/shared_core/components/m2_buttons.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';
import '../../../../app/themes/shared_core/typography/m2_typography.dart';
import '../viewmodels/welcome_viewmodel.dart';
import '../widgets/brand_logo_header.dart';
import '../widgets/module_showcase_widget.dart';
import '../widgets/value_proposition_bar.dart';

/// Screen 03: Welcome to Andril Screen.
///
/// Implements the finalized `03 Andril Welcome_screen.png` design:
/// - Brand logo and tagline at top.
/// - "Welcome to Andril" hero heading and three-module value proposition text.
/// - Overlapping circular module showcase (Learning, Hobbies, Social).
/// - Three-pillar value bar ("Real people", "Safe & private", "Multiple ways").
/// - "Create Account" primary action button with forward arrow.
/// - "Log In" secondary outlined action button.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    this.onCreateAccount,
    this.onLogIn,
    this.viewModel,
  });

  final VoidCallback? onCreateAccount;
  final VoidCallback? onLogIn;
  final WelcomeViewModel? viewModel;

  @override
  Widget build(BuildContext context) {
    final effectiveViewModel = viewModel ??
        WelcomeViewModel(
          onNavigateToRegister: onCreateAccount,
          onNavigateToLogin: onLogIn,
        );

    return M2BackgroundScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: M2Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: M2Spacing.xs),

              // Top Compact Brand Logo
              const Center(
                child: BrandLogoHeader(
                  emblemSize: 56.0,
                  spacing: 4.0,
                ),
              ),

              const SizedBox(height: M2Spacing.md),

              // Hero Headings
              const Text(
                'Welcome to Andril',
                style: M2Typography.welcomeHeadline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: M2Spacing.xs),
              const Text(
                'One account, three independent spaces for your\nlearning, hobbies and social connections.',
                style: M2Typography.welcomeDescription,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: M2Spacing.sm),

              // Three-Module Overlapping Circular Showcase
              const ModuleShowcaseWidget(),

              const SizedBox(height: M2Spacing.sm),

              // Value Proposition Pillars Bar
              const ValuePropositionBar(),

              const SizedBox(height: M2Spacing.lg),

              // Primary "Create Account" Button
              M2PrimaryButton(
                text: 'Create Account',
                onPressed: effectiveViewModel.createAccount,
              ),

              const SizedBox(height: M2Spacing.sm),

              // Secondary "Log In" Button
              M2SecondaryButton(
                text: 'Log In',
                onPressed: effectiveViewModel.logIn,
              ),

              const SizedBox(height: M2Spacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
