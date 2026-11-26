import 'package:flutter/material.dart';

/// Configuration for individual feature highlights displayed on a module welcome screen.
class ModuleFeatureItem {
  const ModuleFeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    this.illustrationAsset,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? illustrationAsset;
}

/// Comprehensive configuration defining the visual theme, copy, cards, and behavior
/// for a module welcome screen (Screens 11, 13, and 15).
class ModuleWelcomeConfig {
  const ModuleWelcomeConfig({
    required this.moduleId,
    required this.moduleTitle,
    required this.moduleIcon,
    required this.badgeBackgroundColor,
    required this.badgeTextColor,
    required this.headingPrefix,
    required this.headingHighlight,
    required this.supportingDescription,
    required this.primaryColor,
    required this.backgroundColor,
    required this.waveColors,
    required this.features,
    required this.privacyMessage,
    this.progressText,
    this.tagline,
    this.heroPhotoAsset,
    this.primaryButtonText = 'Get Started',
    this.secondaryButtonText = 'Back to Module Selection',
    this.learnMoreText,
    this.safetyMessage,
  });

  /// Module identifier ('learning', 'hobbies', 'social').
  final String moduleId;

  /// Human-readable module name.
  final String moduleTitle;

  /// Icon representing the module.
  final IconData moduleIcon;

  /// Background color for the module badge pill.
  final Color badgeBackgroundColor;

  /// Text and icon color for the module badge pill.
  final Color badgeTextColor;

  /// Optional progress step text (e.g. '01 / 03').
  ///
  /// Note: Intentionally null for the Social module to preserve the finalized
  /// reference design, which omits the progress indicator present in Learning and Hobbies.
  final String? progressText;

  /// Leading prefix of the main headline (e.g. 'Start Your ').
  final String headingPrefix;

  /// Highlighted headline text (e.g. 'Learning Journey').
  final String headingHighlight;

  /// Supporting explanatory paragraph below the headline.
  final String supportingDescription;

  /// Optional tagline pill text (e.g. 'Learn • Share • Grow').
  final String? tagline;

  /// Asset path for the hero photograph, if available.
  final String? heroPhotoAsset;

  /// Primary theme color used for buttons, active indicators, and headline highlights.
  final Color primaryColor;

  /// Canvas background color for the screen.
  final Color backgroundColor;

  /// List of layer colors for the decorative wave divider.
  final List<Color> waveColors;

  /// List of 3 feature cards for the module.
  final List<ModuleFeatureItem> features;

  /// Primary CTA label.
  final String primaryButtonText;

  /// Secondary action label.
  final String secondaryButtonText;

  /// Optional auxiliary action label (e.g. 'Learn more').
  final String? learnMoreText;

  /// Mandatory privacy isolation message.
  final String privacyMessage;

  /// Optional safety notice (e.g. 18+ requirement for Social).
  final String? safetyMessage;

  /// Pre-configured specification for Screen 11 – Learning Welcome.
  factory ModuleWelcomeConfig.learning() {
    return const ModuleWelcomeConfig(
      moduleId: 'learning',
      moduleTitle: 'Learning',
      moduleIcon: Icons.school_rounded,
      badgeBackgroundColor: Color(0xFFDBEAFE),
      badgeTextColor: Color(0xFF1E40AF),
      progressText: '01 / 03',
      headingPrefix: 'Start Your ',
      headingHighlight: 'Learning Journey',
      supportingDescription:
          'Connect, collaborate, and grow with peers, mentors, and study circles across ANDRIL.',
      tagline: 'Learn • Share • Grow',
      heroPhotoAsset: 'assets/images/learning/profile/welcome_study_desk.webp',
      primaryColor: Color(0xFF2563EB),
      backgroundColor: Color(0xFFF8FAFC),
      waveColors: [
        Color(0xFFA78BFA), // Purple accent
        Color(0xFF93B4FA), // Light blue
        Color(0xFF0057FF), // Bright blue
        Color(0xFF2563EB), // Primary blue
      ],
      features: [
        ModuleFeatureItem(
          title: 'Learn New Skills',
          description:
              'Explore curated learning paths, track your personal milestones, and learn collaboratively.',
          icon: Icons.lightbulb_outline_rounded,
        ),
        ModuleFeatureItem(
          title: 'Share Your Knowledge',
          description:
              'Host study circles, mentor peers, and exchange valuable insights across the community.',
          icon: Icons.auto_stories_rounded,
        ),
        ModuleFeatureItem(
          title: 'Connect with Learners',
          description:
              'Build lasting academic connections and collaborate in shared virtual classrooms.',
          icon: Icons.groups_rounded,
        ),
      ],
      primaryButtonText: 'Get Started',
      secondaryButtonText: 'Back to Module Selection',
      learnMoreText: 'Learn more',
      privacyMessage: 'Your Learning identity stays separate and private.',
    );
  }

  /// Pre-configured specification for Screen 13 – Hobbies Welcome.
  factory ModuleWelcomeConfig.hobbies() {
    return const ModuleWelcomeConfig(
      moduleId: 'hobbies',
      moduleTitle: 'Hobbies',
      moduleIcon: Icons.palette_rounded,
      badgeBackgroundColor: Color(0xFFD1FAE5),
      badgeTextColor: Color(0xFF065F46),
      progressText: '01 / 03',
      headingPrefix: 'Explore Your ',
      headingHighlight: 'Hobbies',
      supportingDescription:
          'Discover new passions, share your creations, and connect with creators who share what you love.',
      tagline: 'Explore • Create • Connect',
      heroPhotoAsset:
          'assets/images/shared_core/module_profile_setup/hobbies/01_hobbies_welcome.png.png',
      primaryColor: Color(0xFF0D9488),
      backgroundColor: Color(0xFFECFDF5),
      waveColors: [
        Color(0xFF01999A), // Prototype teal start
        Color(0xFF006D77), // Deep teal
        Color(0xFF16A34A), // Approved Hobbies emerald
        Color(0xFF34D399), // Soft green
      ],
      features: [
        ModuleFeatureItem(
          title: 'Find Hobby Friends',
          description:
              'Meet fellow enthusiasts who share your artistic, outdoor, craft, or technical passions.',
          icon: Icons.handshake_outlined,
        ),
        ModuleFeatureItem(
          title: 'Join Clubs',
          description:
              'Participate in dedicated photography, music, gaming, and art circles with regular events.',
          icon: Icons.diversity_3_rounded,
        ),
        ModuleFeatureItem(
          title: 'Explore Andril Map',
          description:
              'Discover real-world hobby meetups, exhibitions, and outdoor activities happening nearby.',
          icon: Icons.map_rounded,
        ),
      ],
      primaryButtonText: 'Get Started',
      secondaryButtonText: 'Back to Module Selection',
      learnMoreText: null,
      privacyMessage: 'Your Hobbies identity stays separate and private.',
    );
  }

  /// Pre-configured specification for Screen 15 – Social Welcome.
  factory ModuleWelcomeConfig.social() {
    return const ModuleWelcomeConfig(
      moduleId: 'social',
      moduleTitle: 'Social',
      moduleIcon: Icons.favorite_rounded,
      badgeBackgroundColor: Color(0xFFF3E8FF),
      badgeTextColor: Color(0xFF6B21A8),
      progressText: null, // Omitted in the finalized reference design
      headingPrefix: '',
      headingHighlight: 'Find your people.',
      supportingDescription:
          'Build genuine friendships, find activity partners, and expand your social horizons.',
      tagline: null,
      heroPhotoAsset:
          'assets/images/shared_core/module_profile_setup/social/01_social_welcome.png.png',
      primaryColor: Color(0xFF7E22CE),
      backgroundColor: Color(0xFFFAF7F2),
      waveColors: [
        Color(0xFF330099), // Royal purple
        Color(0xFF7E22CE), // Violet
        Color(0xFFC47A44), // Copper / Orange
        Color(0xFFEF8D49), // Warm orange
      ],
      features: [
        ModuleFeatureItem(
          title: 'Smart Matching',
          description:
              'Discover people who align with your values, personality traits, and communication style.',
          icon: Icons.auto_awesome_rounded,
        ),
        ModuleFeatureItem(
          title: 'Real Conversations',
          description:
              'Engage in authentic, meaningful discussions in private, safe, and moderated spaces.',
          icon: Icons.chat_bubble_outline_rounded,
        ),
        ModuleFeatureItem(
          title: 'Shared Experiences',
          description:
              'Plan hangouts, attend events together, and build lasting real-world friendships.',
          icon: Icons.celebration_rounded,
        ),
      ],
      primaryButtonText: 'Get Started',
      secondaryButtonText: 'Back to Module Selection',
      learnMoreText: 'Learn more',
      safetyMessage: 'Social is available for users aged 18+ only.',
      privacyMessage:
          'Your information is private and not shared with other modules.',
    );
  }
}

