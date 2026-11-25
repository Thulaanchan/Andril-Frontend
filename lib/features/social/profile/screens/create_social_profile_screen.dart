import 'package:andril_mobile/app/themes/social/social_theme.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_viewmodel.dart';
import 'package:flutter/material.dart';

/// Screen S02: Create Social Profile.
///
/// Follows M5-FE-S02-UI-01 and approved Social UI specifications:
/// - Social branding with [SocialWaveBackground] and approved color tokens:
///   Royal Purple (#330099), Copper (#C47A44), Cream (#FAF7F2).
/// - Binds to [SocialProfileViewModel].
/// - Displays display-name input (3–30 graphemes) and optional bio (up to 300 graphemes).
/// - Shows photo slot with private visibility indication.
/// - Handles loading, conflict (name taken), denial (ineligible), and error states safely.
/// - Disables submit when draft is invalid or loading.
/// - Emits navigation progression via [onContinue] without bypassing backend completion.
/// - Excludes Personality Test controls and unauthorized direct navigation.
class CreateSocialProfileScreen extends StatefulWidget {
  final SocialProfileViewModel viewModel;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;

  const CreateSocialProfileScreen({
    super.key,
    required this.viewModel,
    this.onBack,
    this.onContinue,
  });

  @override
  State<CreateSocialProfileScreen> createState() =>
      _CreateSocialProfileScreenState();
}

class _CreateSocialProfileScreenState extends State<CreateSocialProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.viewModel.draft.displayName);
    _bioController =
        TextEditingController(text: widget.viewModel.draft.bio ?? '');
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    // Sync external changes (e.g. session invalidation) into text controllers
    if (_nameController.text != widget.viewModel.draft.displayName) {
      _nameController.text = widget.viewModel.draft.displayName;
    }
    if (_bioController.text != (widget.viewModel.draft.bio ?? '')) {
      _bioController.text = widget.viewModel.draft.bio ?? '';
    }
    setState(() {});
  }

  Future<void> _handleContinue() async {
    final success = await widget.viewModel.saveDraft();
    if (success && mounted) {
      widget.onContinue?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final draft = vm.draft;

    return Scaffold(
      backgroundColor: AndrilSocialColors.cream,
      body: Stack(
        children: [
          const SocialWaveBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (vm.isConflict) _buildConflictBanner(vm.errorMessage),
                        if (vm.isDenied) _buildDeniedBanner(vm.errorMessage),
                        if (vm.isError && !vm.isConflict && !vm.isDenied)
                          _buildErrorBanner(vm.errorMessage),
                        const SizedBox(height: 12.0),
                        _buildPhotoSection(draft.profilePhotoPath),
                        const SizedBox(height: 24.0),
                        _buildDisplayNameField(draft.displayNameError),
                        const SizedBox(height: 20.0),
                        _buildBioField(draft.bioError),
                        const SizedBox(height: 20.0),
                        _buildEligibilityNotice(),
                        const SizedBox(height: 32.0),
                        _buildContinueButton(vm),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Semantics(
            label: 'Back',
            button: true,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AndrilSocialColors.ink,
                size: 22.0,
              ),
              tooltip: 'Back',
              onPressed: widget.onBack,
            ),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Create Profile',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                    color: AndrilSocialColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2.0),
                Text(
                  'Step 1 of 2 • Basic Information',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: AndrilSocialColors.copper,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48.0), // Visual balance for back button
        ],
      ),
    );
  }

  Widget _buildConflictBanner(String? message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AndrilSocialColors.copper.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AndrilSocialColors.copper),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AndrilSocialColors.copper),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              message ?? 'Display name is already taken.',
              style: const TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: AndrilSocialColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeniedBanner(String? message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AndrilSocialColors.royalPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AndrilSocialColors.royalPurple),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: AndrilSocialColors.royalPurple),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              message ?? 'Adult eligibility required to create a Social profile.',
              style: const TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: AndrilSocialColors.royalPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String? message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.shade400),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              message ?? 'Failed to save profile draft.',
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String? photoPath) {
    return Center(
      child: Column(
        children: [
          Semantics(
            label: 'Profile photo, private',
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(32.0),
              onTap: () {
                // Handoff to local photo selection
                widget.viewModel
                    .updateProfilePhoto('/local/placeholder/avatar.jpg');
              },
              child: Container(
                width: 108.0,
                height: 108.0,
                decoration: BoxDecoration(
                  color: AndrilSocialColors.faintPurple,
                  borderRadius: BorderRadius.circular(32.0),
                  border: Border.all(
                    color: photoPath != null
                        ? AndrilSocialColors.copper
                        : AndrilSocialColors.border,
                    width: 2.0,
                  ),
                ),
                child: Center(
                  child: photoPath != null
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AndrilSocialColors.copper,
                          size: 38.0,
                        )
                      : const Icon(
                          Icons.add_a_photo_outlined,
                          color: AndrilSocialColors.royalPurple,
                          size: 36.0,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Profile Photo (Private)',
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: AndrilSocialColors.ink,
            ),
          ),
          const SizedBox(height: 2.0),
          const Text(
            'Kept private to authorized connections',
            style: TextStyle(
              fontSize: 11.0,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayNameField(String? errorText) {
    final count = widget.viewModel.draft.displayNameGraphemeCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Display Name *',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w700,
            color: AndrilSocialColors.ink,
          ),
        ),
        const SizedBox(height: 6.0),
        TextFormField(
          key: const Key('displayNameField'),
          controller: _nameController,
          enabled: !widget.viewModel.isLoading,
          maxLength: 30,
          decoration: InputDecoration(
            hintText: 'Enter your name (3–30 characters)',
            counterText: '$count/30',
            errorText: errorText,
            filled: true,
            fillColor: AndrilSocialColors.canvasCream,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AndrilSocialColors.copper,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(color: AndrilSocialColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(color: AndrilSocialColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(
                color: AndrilSocialColors.royalPurple,
                width: 1.8,
              ),
            ),
          ),
          onChanged: widget.viewModel.updateDisplayName,
        ),
      ],
    );
  }

  Widget _buildBioField(String? errorText) {
    final count = widget.viewModel.draft.bioGraphemeCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About Me (Optional)',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w700,
            color: AndrilSocialColors.ink,
          ),
        ),
        const SizedBox(height: 6.0),
        TextFormField(
          key: const Key('bioField'),
          controller: _bioController,
          enabled: !widget.viewModel.isLoading,
          maxLength: 300,
          maxLines: 4,
          minLines: 3,
          decoration: InputDecoration(
            hintText: 'Share a brief introduction (up to 300 characters)...',
            counterText: '$count/300',
            errorText: errorText,
            filled: true,
            fillColor: AndrilSocialColors.canvasCream,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 48.0),
              child: Icon(
                Icons.description_outlined,
                color: AndrilSocialColors.copper,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(color: AndrilSocialColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(color: AndrilSocialColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(
                color: AndrilSocialColors.royalPurple,
                width: 1.8,
              ),
            ),
          ),
          onChanged: widget.viewModel.updateBio,
        ),
      ],
    );
  }

  Widget _buildEligibilityNotice() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AndrilSocialColors.giftTile.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AndrilSocialColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AndrilSocialColors.copper,
            size: 20.0,
          ),
          SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Social profile drafts are restricted to confirmed adult participants. Profile drafts do not complete module onboarding until verified.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: AndrilSocialColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(SocialProfileViewModel vm) {
    final canSubmit = vm.canSubmit;
    final isLoading = vm.isLoading;

    return Semantics(
      button: true,
      enabled: canSubmit,
      label: 'Continue',
      child: SizedBox(
        height: 52.0,
        child: ElevatedButton(
          key: const Key('continueButton'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AndrilSocialColors.royalPurple,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AndrilSocialColors.royalPurple.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: canSubmit ? 2.0 : 0.0,
          ),
          onPressed: canSubmit ? _handleContinue : null,
          child: isLoading
              ? const SizedBox(
                  width: 24.0,
                  height: 24.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
