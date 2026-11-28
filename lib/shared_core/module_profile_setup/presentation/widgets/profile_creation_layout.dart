import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/components/m2_buttons.dart';
import '../viewmodels/module_profile_viewmodel.dart';
import 'module_progress_badge.dart';
import 'module_welcome_wave_divider.dart';
import 'profile_about_me_field.dart';
import 'profile_gallery_uploader.dart';
import 'profile_location_selector.dart';
import 'profile_photo_uploader.dart';
import 'profile_text_field.dart';

/// Scaffolding layout for module profile creation screens (Screens 12, 14, and 16).
class ProfileCreationLayout extends StatelessWidget {
  const ProfileCreationLayout({
    super.key,
    required this.viewModel,
    required this.onBack,
    required this.onContinue,
    this.onPickProfilePhoto,
    this.onAddGalleryPhoto,
  });

  final ModuleProfileViewModel viewModel;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback? onPickProfilePhoto;
  final VoidCallback? onAddGalleryPhoto;

  void _handleContinue(BuildContext context) async {
    final success = await viewModel.saveProfile();
    if (success) {
      onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = viewModel.config;

    return Scaffold(
      backgroundColor: config.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top navigation and branding bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: Color(0xFF0F172A)),
                      onPressed: onBack,
                      tooltip: 'Back',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 14),

                    // ANDRIL Branding
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ANDRIL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          ' • Modules',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Module badge and 02 / 03 progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ModuleProgressBadge(
                  moduleTitle: config.moduleTitle,
                  moduleIcon: config.moduleIcon,
                  badgeBackgroundColor: config.badgeBackgroundColor,
                  badgeTextColor: config.badgeTextColor,
                  progressText: config.progressText,
                ),
              ),
              const SizedBox(height: 12),

              // Decorative wave divider
              ModuleWelcomeWaveDivider(
                waveColors: config.waveColors,
                height: 36,
              ),
              const SizedBox(height: 16),

              // Headline & Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.heading,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      config.subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Profile Photo Uploader
              ProfilePhotoUploader(
                primaryColor: config.primaryColor,
                isRequired: config.isProfilePhotoRequired,
                photoPath: viewModel.profilePhotoPath,
                helperText: config.profilePhotoHelperText,
                errorText: viewModel.photoError,
                isLoading: viewModel.isLoading || viewModel.isPhotoLoading,
                onPickPhoto: onPickProfilePhoto ??
                    () => viewModel.pickProfilePhoto(context: context),
                onRemovePhoto: viewModel.removeProfilePhoto,
              ),
              const SizedBox(height: 24),

              // Form fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Display Name
                    ProfileTextField(
                      label: 'Display Name *',
                      placeholder: config.displayNamePlaceholder,
                      helperText: config.displayNameHelperText,
                      initialValue: viewModel.displayName,
                      errorText: viewModel.displayNameError,
                      primaryColor: config.primaryColor,
                      onChanged: viewModel.setDisplayName,
                    ),
                    const SizedBox(height: 20),

                    // About Me
                    ProfileAboutMeField(
                      placeholder: config.aboutMePlaceholder,
                      initialValue: viewModel.aboutMe,
                      maxLength: config.aboutMeMaxLength,
                      primaryColor: config.primaryColor,
                      onChanged: viewModel.setAboutMe,
                    ),
                    const SizedBox(height: 20),

                    // Location
                    ProfileLocationSelector(
                      selectedLocation: viewModel.location,
                      placeholder: config.locationPlaceholder,
                      helperText: config.locationHelperText,
                      options: config.locationOptions,
                      primaryColor: config.primaryColor,
                      onChanged: viewModel.setLocation,
                      onClear: viewModel.clearLocation,
                    ),
                    const SizedBox(height: 24),

                    // Additional Photos Gallery
                    ProfileGalleryUploader(
                      title: config.additionalPhotosTitle,
                      subtitle: config.additionalPhotosSubtitle,
                      photoPaths: viewModel.additionalPhotoPaths,
                      maxPhotos: config.maxAdditionalPhotos,
                      primaryColor: config.primaryColor,
                      onAddPhoto: onAddGalleryPhoto ??
                          () {
                            final nextSlot =
                                viewModel.additionalPhotoPaths.length;
                            viewModel.pickAdditionalPhoto(
                              slotIndex: nextSlot,
                              context: context,
                            );
                          },
                      onRemovePhoto: viewModel.removeAdditionalPhoto,
                      onReplacePhoto: (idx) {
                        if (onAddGalleryPhoto != null) {
                          onAddGalleryPhoto!();
                        } else {
                          viewModel.pickAdditionalPhoto(
                            slotIndex: idx,
                            context: context,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 28),

                    // General Error message
                    if (viewModel.generalError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                viewModel.generalError!,
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Primary CTA button ("Continue to Preferences" / "Save & Continue")
                    M2PrimaryButton(
                      text: config.primaryButtonText,
                      isLoading: viewModel.isLoading,
                      onPressed: () => _handleContinue(context),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
