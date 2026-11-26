import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/profile_creation_config.dart';
import '../viewmodels/module_profile_viewmodel.dart';
import '../widgets/profile_creation_layout.dart';

/// Screen 12 – Create Your Learning Profile.
///
/// Features:
/// - Blue and purple decorative wave header.
/// - Learning badge with 02 / 03 progress indicator.
/// - Heading: "Create Your Learning Profile".
/// - Subtitle: "Let others get to know your learning side.".
/// - Optional profile photo.
/// - Required display name: "Enter your Learning display name".
/// - Optional About Me with 100-character live counter.
/// - Location dropdown with privacy explanation.
/// - "My Learning Photos (Optional)" with up to 3 slots.
/// - Primary action: "Continue to Preferences".
class LearningProfileScreen extends StatefulWidget {
  const LearningProfileScreen({
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
  State<LearningProfileScreen> createState() => _LearningProfileScreenState();
}

class _LearningProfileScreenState extends State<LearningProfileScreen> {
  late final ModuleProfileViewModel _viewModel;
  late final bool _isInternallyOwned;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _isInternallyOwned = false;
    } else {
      _viewModel = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
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
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null && mounted) {
        await _viewModel.setProfilePhoto(picked.path);
      }
    } catch (_) {
      // In headless test environments or restricted platforms, fail gracefully
    }
  }

  Future<void> _handleAddGalleryPhoto() async {
    if (widget.onAddGalleryPhoto != null) {
      widget.onAddGalleryPhoto!();
      return;
    }
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null && mounted) {
        _viewModel.addAdditionalPhoto(picked.path);
      }
    } catch (_) {
      // Fail gracefully
    }
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
