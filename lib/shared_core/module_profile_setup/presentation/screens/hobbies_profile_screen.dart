import 'package:flutter/material.dart';
import '../../domain/models/profile_creation_config.dart';
import '../viewmodels/module_profile_viewmodel.dart';
import '../widgets/profile_creation_layout.dart';

/// Screen 14 – Create Your Hobbies Profile.
///
/// Features:
/// - Teal and green decorative wave header.
/// - Hobbies badge with 02 / 03 progress indicator.
/// - Heading: "Create Your Hobbies Profile".
/// - Subtitle: "Let others get to know your creative side.".
/// - Optional profile photo.
/// - Required display name: "Enter your Hobbies display name".
/// - Optional About Me with 100-character live counter.
/// - Location dropdown with privacy explanation.
/// - "My Hobby Photos (Optional)" with up to 3 slots.
/// - Primary action: "Continue to Preferences".
class HobbiesProfileScreen extends StatefulWidget {
  const HobbiesProfileScreen({
    super.key,
    this.viewModel,
    required this.onBack,
    required this.onContinue,
    this.onPickProfilePhoto,
    this.onAddGalleryPhoto,
  });

  final ModuleProfileViewModel? viewModel;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback? onPickProfilePhoto;
  final VoidCallback? onAddGalleryPhoto;

  @override
  State<HobbiesProfileScreen> createState() => _HobbiesProfileScreenState();
}

class _HobbiesProfileScreenState extends State<HobbiesProfileScreen> {
  late final ModuleProfileViewModel _viewModel;
  late final bool _isInternallyOwned;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _isInternallyOwned = false;
    } else {
      _viewModel = ModuleProfileViewModel(
        config: ProfileCreationConfig.hobbies(),
      );
      _isInternallyOwned = true;
    }
  }

  @override
  void dispose() {
    if (_isInternallyOwned) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _handlePickProfilePhoto() async {
    if (widget.onPickProfilePhoto != null) {
      widget.onPickProfilePhoto!();
      return;
    }
    await _viewModel.pickProfilePhoto(context: context);
  }

  Future<void> _handleAddGalleryPhoto() async {
    if (widget.onAddGalleryPhoto != null) {
      widget.onAddGalleryPhoto!();
      return;
    }
    final nextSlot = _viewModel.additionalPhotoPaths.length;
    await _viewModel.pickAdditionalPhoto(
      slotIndex: nextSlot,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return ProfileCreationLayout(
          viewModel: _viewModel,
          onBack: widget.onBack,
          onContinue: widget.onContinue,
          onPickProfilePhoto: _handlePickProfilePhoto,
          onAddGalleryPhoto: _handleAddGalleryPhoto,
        );
      },
    );
  }
}
