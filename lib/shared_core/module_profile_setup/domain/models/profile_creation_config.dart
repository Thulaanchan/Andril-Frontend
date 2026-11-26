import 'package:flutter/material.dart';

/// Configuration specifying the visual theme, copy, validation rules, and controls
/// for a module profile creation screen (Screens 12, 14, and 16).
class ProfileCreationConfig {
  const ProfileCreationConfig({
    required this.moduleId,
    required this.moduleTitle,
    required this.moduleIcon,
    required this.badgeBackgroundColor,
    required this.badgeTextColor,
    required this.heading,
    required this.subtitle,
    required this.primaryColor,
    required this.backgroundColor,
    required this.waveColors,
    required this.isProfilePhotoRequired,
    this.profilePhotoHelperText,
    required this.displayNamePlaceholder,
    required this.displayNameHelperText,
    required this.aboutMePlaceholder,
    this.aboutMeMaxLength = 100,
    required this.locationPlaceholder,
    required this.locationHelperText,
    this.locationOptions = const [
      'Colombo',
      'Kandy',
      'Galle',
      'Jaffna',
      'Gampaha',
      'Kurunegala',
      'Batticaloa',
      'Remote / Online',
    ],
    required this.additionalPhotosTitle,
    required this.additionalPhotosSubtitle,
    this.maxAdditionalPhotos = 3,
    required this.primaryButtonText,
    this.requiresFaceVerification = false,
    this.requiresSocialEligibility = false,
    this.progressText = '02 / 03',
  });

  /// Module identifier ('learning', 'hobbies', 'social').
  final String moduleId;

  /// Module human-readable name.
  final String moduleTitle;

  /// Module icon.
  final IconData moduleIcon;

  /// Badge container color.
  final Color badgeBackgroundColor;

  /// Badge text/icon color.
  final Color badgeTextColor;

  /// Progress indicator text (e.g. '02 / 03').
  final String progressText;

  /// Headline on the screen (e.g. 'Create Your Learning Profile').
  final String heading;

  /// Subtitle below the headline.
  final String subtitle;

  /// Module primary theme color.
  final Color primaryColor;

  /// Background color of the screen.
  final Color backgroundColor;

  /// Layer colors for decorative wave header.
  final List<Color> waveColors;

  /// Whether a profile photo is mandatory (true for Social, false for Learning/Hobbies).
  final bool isProfilePhotoRequired;

  /// Supporting description below profile photo uploader.
  final String? profilePhotoHelperText;

  /// Placeholder inside the display name field.
  final String displayNamePlaceholder;

  /// Supporting description below the display name field.
  final String displayNameHelperText;

  /// Placeholder inside the about me field.
  final String aboutMePlaceholder;

  /// Character presentation limit for the about me field (100).
  final int aboutMeMaxLength;

  /// Placeholder for the location selector.
  final String locationPlaceholder;

  /// Privacy explanation below the location selector.
  final String locationHelperText;

  /// Available representative location options.
  final List<String> locationOptions;

  /// Header label for the gallery section.
  final String additionalPhotosTitle;

  /// Supporting description for the gallery section.
  final String additionalPhotosSubtitle;

  /// Maximum allowed gallery photos (3).
  final int maxAdditionalPhotos;

  /// Label on the primary action button.
  final String primaryButtonText;

  /// Whether face verification is required (strictly true for Social).
  final bool requiresFaceVerification;

  /// Whether 18+ eligibility is required (strictly true for Social).
  final bool requiresSocialEligibility;

  /// Configuration for Screen 12 – Create Your Learning Profile.
  factory ProfileCreationConfig.learning() {
    return const ProfileCreationConfig(
      moduleId: 'learning',
      moduleTitle: 'Learning',
      moduleIcon: Icons.school_rounded,
      badgeBackgroundColor: Color(0xFFDBEAFE),
      badgeTextColor: Color(0xFF1E40AF),
      heading: 'Create Your Learning Profile',
      subtitle: 'Let others get to know your learning side.',
      primaryColor: Color(0xFF2563EB),
      backgroundColor: Color(0xFFF8FAFC),
      waveColors: [
        Color(0xFFA78BFA),
        Color(0xFF93B4FA),
        Color(0xFF0057FF),
        Color(0xFF2563EB),
      ],
      isProfilePhotoRequired: false,
      profilePhotoHelperText: null,
      displayNamePlaceholder: 'Enter your Learning display name',
      displayNameHelperText:
          'Unique within Learning; different from your other identities.',
      aboutMePlaceholder:
          'Tell others about your interests, skills and what you love to learn...',
      aboutMeMaxLength: 100,
      locationPlaceholder: 'Select your city or region',
      locationHelperText:
          'Your city helps us find nearby peers. Exact address is never shared.',
      additionalPhotosTitle: 'My Learning Photos (Optional)',
      additionalPhotosSubtitle:
          'Add photos that show your learning journey or projects.',
      maxAdditionalPhotos: 3,
      primaryButtonText: 'Continue to Preferences',
      requiresFaceVerification: false,
      requiresSocialEligibility: false,
    );
  }

  /// Configuration for Screen 14 – Create Your Hobbies Profile.
  factory ProfileCreationConfig.hobbies() {
    return const ProfileCreationConfig(
      moduleId: 'hobbies',
      moduleTitle: 'Hobbies',
      moduleIcon: Icons.palette_rounded,
      badgeBackgroundColor: Color(0xFFD1FAE5),
      badgeTextColor: Color(0xFF065F46),
      heading: 'Create Your Hobbies Profile',
      subtitle: 'Let others get to know your creative side.',
      primaryColor: Color(0xFF0D9488),
      backgroundColor: Color(0xFFECFDF5),
      waveColors: [
        Color(0xFF01999A),
        Color(0xFF006D77),
        Color(0xFF16A34A),
        Color(0xFF34D399),
      ],
      isProfilePhotoRequired: false,
      profilePhotoHelperText: null,
      displayNamePlaceholder: 'Enter your Hobbies display name',
      displayNameHelperText:
          'Unique within Hobbies; different from your other identities.',
      aboutMePlaceholder:
          'Tell others about your interests, skills and what you love to do...',
      aboutMeMaxLength: 100,
      locationPlaceholder: 'Select your city or region',
      locationHelperText:
          'Your city helps us find nearby peers. Exact address is never shared.',
      additionalPhotosTitle: 'My Hobby Photos (Optional)',
      additionalPhotosSubtitle:
          'Add photos that show your hobbies or creations.',
      maxAdditionalPhotos: 3,
      primaryButtonText: 'Continue to Preferences',
      requiresFaceVerification: false,
      requiresSocialEligibility: false,
    );
  }

  /// Configuration for Screen 16 – Create Your Social Profile.
  factory ProfileCreationConfig.social() {
    return const ProfileCreationConfig(
      moduleId: 'social',
      moduleTitle: 'Social',
      moduleIcon: Icons.favorite_rounded,
      badgeBackgroundColor: Color(0xFFF3E8FF),
      badgeTextColor: Color(0xFF6B21A8),
      heading: 'Create Your Social Profile',
      subtitle: 'Let others get to know the real you.',
      primaryColor: Color(0xFF7E22CE),
      backgroundColor: Color(0xFFFAF7F2),
      waveColors: [
        Color(0xFF330099),
        Color(0xFF7E22CE),
        Color(0xFFC47A44),
        Color(0xFFEF8D49),
      ],
      isProfilePhotoRequired: true,
      profilePhotoHelperText:
          'Add a clear photo of yourself. This helps build trust and meaningful connections.',
      displayNamePlaceholder: 'Enter your Social display name',
      displayNameHelperText: 'This name will appear on your Social profile.',
      aboutMePlaceholder:
          'Tell others a little about yourself, your personality and what makes you unique...',
      aboutMeMaxLength: 100,
      locationPlaceholder: 'Select your city or region',
      locationHelperText:
          'Your city helps us find nearby peers. Exact address is never shared.',
      additionalPhotosTitle: 'My Photos (Optional)',
      additionalPhotosSubtitle:
          'Add up to 3 photos to share more about yourself.',
      maxAdditionalPhotos: 3,
      primaryButtonText: 'Save & Continue',
      requiresFaceVerification: false,
      requiresSocialEligibility: true,
    );
  }
}
