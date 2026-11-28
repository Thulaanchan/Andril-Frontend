import 'dart:io';
import 'package:flutter/widgets.dart';
import '../../data/repositories/unconfigured_module_profile_repository.dart';
import '../../data/services/profile_photo_picker_service_impl.dart';
import '../../data/services/profile_photo_processor_service_impl.dart';
import '../../domain/models/module_profile_draft.dart';
import '../../domain/models/photo_source.dart';
import '../../domain/models/processed_photo.dart';
import '../../domain/models/profile_creation_config.dart';
import '../../domain/repositories/module_profile_repository.dart';
import '../../domain/services/profile_photo_picker_service.dart';
import '../../domain/services/profile_photo_processor_service.dart';
import '../widgets/photo_crop_screen.dart';
import '../widgets/photo_source_bottom_sheet.dart';

/// Presentation ViewModel for module profile creation (Screens 12, 14, and 16).
///
/// Follows Clean Architecture and MVVM:
/// - Enforces module identity privacy: no cross-module copying, scoped per instance.
/// - Validates required display name (trimmed, non-empty).
/// - Enforces 100-character UI presentation limit for About Me.
/// - Enforces photo requirement for Social.
/// - Manages main profile photo (1:1 square crop, <= 5 MB, metadata stripped).
/// - Manages up to 3 optional additional photos (aspect-ratio preserved, <= 5 MB, metadata stripped).
/// - Stale asynchronous operation rejection via operation generation counters.
/// - Preserves existing valid photos on cancellation or validation failure.
/// - Prevents duplicate submissions while an asynchronous operation is in flight.
/// - Default repository is fail-closed [UnconfiguredModuleProfileRepository].
class ModuleProfileViewModel extends ChangeNotifier {
  ModuleProfileViewModel({
    required this.config,
    ModuleProfileRepository? repository,
    IProfilePhotoPickerService? photoPickerService,
    IProfilePhotoProcessorService? photoProcessorService,
    this.isSocialAuthorizedByServer = true,
  })  : _repository = repository ?? const UnconfiguredModuleProfileRepository(),
        _photoPickerService =
            photoPickerService ?? ProfilePhotoPickerServiceImpl(),
        _photoProcessorService =
            photoProcessorService ?? ProfilePhotoProcessorServiceImpl();

  final ProfileCreationConfig config;
  final ModuleProfileRepository _repository;
  final IProfilePhotoPickerService _photoPickerService;
  final IProfilePhotoProcessorService _photoProcessorService;
  final bool isSocialAuthorizedByServer;

  String _displayName = '';
  String _aboutMe = '';
  String _location = '';
  String? _profilePhotoPath;
  ProcessedPhoto? _profilePhoto;
  List<String> _additionalPhotoPaths = [];
  bool _isFaceVerified = false;

  bool _isLoading = false;
  bool _isPhotoLoading = false;
  String? _displayNameError;
  String? _photoError;
  String? _generalError;
  int _operationGeneration = 0;

  // Getters
  String get displayName => _displayName;
  String get aboutMe => _aboutMe;
  String get location => _location;
  String? get profilePhotoPath => _profilePhotoPath;
  ProcessedPhoto? get profilePhoto => _profilePhoto;
  List<String> get additionalPhotoPaths => List.unmodifiable(_additionalPhotoPaths);
  bool get canAddMoreAdditionalPhotos =>
      _additionalPhotoPaths.length < config.maxAdditionalPhotos;
  bool get isFaceVerified => _isFaceVerified;
  bool get isLoading => _isLoading;
  bool get isPhotoLoading => _isPhotoLoading;

  String? get displayNameError => _displayNameError;
  String? get photoError => _photoError;
  String? get generalError => _generalError;

  int get aboutMeCharCount => _aboutMe.length;

  /// Whether all current inputs pass client-side validation rules.
  bool get isFormValid {
    if (_displayName.trim().isEmpty) return false;
    if (config.isProfilePhotoRequired &&
        (_profilePhotoPath == null || _profilePhotoPath!.trim().isEmpty)) {
      return false;
    }
    if (config.requiresSocialEligibility && !isSocialAuthorizedByServer) {
      return false;
    }
    return true;
  }

  /// Builds a [ModuleProfileDraft] snapshot of the current form state.
  ModuleProfileDraft toDraft() {
    return ModuleProfileDraft(
      moduleId: config.moduleId,
      displayName: _displayName.trim(),
      aboutMe: _aboutMe,
      location: _location,
      profilePhotoPath: _profilePhotoPath,
      additionalPhotoPaths: List.unmodifiable(_additionalPhotoPaths),
      isFaceVerified: _isFaceVerified,
    );
  }

  /// Updates the display name, trimming spaces for validation and clearing errors.
  void setDisplayName(String value) {
    _displayName = value;
    if (_displayNameError != null && value.trim().isNotEmpty) {
      _displayNameError = null;
    }
    notifyListeners();
  }

  /// Updates the About Me text, respecting the 100-character UI constraint.
  void setAboutMe(String value) {
    if (value.length > config.aboutMeMaxLength) {
      _aboutMe = value.substring(0, config.aboutMeMaxLength);
    } else {
      _aboutMe = value;
    }
    notifyListeners();
  }

  /// Sets the selected location.
  void setLocation(String value) {
    _location = value;
    notifyListeners();
  }

  /// Clears the selected location.
  void clearLocation() {
    _location = '';
    notifyListeners();
  }

  /// Directly sets the primary profile photo path (used in tests or manual overrides).
  Future<void> setProfilePhoto(String path) async {
    _profilePhotoPath = path;
    _photoError = null;
    notifyListeners();
  }

  /// Picks and processes the main profile photo with square crop.
  ///
  /// Preserves previous valid photo if picking, cropping, or processing fails or cancels.
  Future<void> pickProfilePhoto({
    BuildContext? context,
    PhotoSource? source,
    String? directPath,
    Rect? directCropRect,
  }) async {
    if (_isPhotoLoading) return;
    final int currentGen = ++_operationGeneration;

    PhotoSource? chosenSource = source;
    if (chosenSource == null && directPath == null) {
      if (context == null) return;
      chosenSource = await PhotoSourceBottomSheet.show(context);
      if (chosenSource == null) return; // User cancelled source selection
    }

    _isPhotoLoading = true;
    _photoError = null;
    notifyListeners();

    try {
      final String? rawPath = directPath ??
          await _photoPickerService.pickPhoto(chosenSource!);

      if (rawPath == null) {
        // User cancelled picker
        if (currentGen == _operationGeneration) {
          _isPhotoLoading = false;
          notifyListeners();
        }
        return;
      }

      // 1. Source image technical validation (magic bytes, dimensions)
      final validation =
          await _photoProcessorService.validateSourceImage(rawPath);
      if (!validation.isSuccess) {
        if (currentGen == _operationGeneration) {
          _photoError = validation.message;
          _isPhotoLoading = false;
          notifyListeners();
        }
        return;
      }

      // 2. Interactive Square Cropping (1:1 aspect ratio)
      Rect? cropRect = directCropRect;
      if (cropRect == null && context != null && context.mounted) {
        cropRect = await PhotoCropScreen.start(context, File(rawPath));
        if (cropRect == null) {
          // User cancelled crop -> preserve previous valid photo
          if (currentGen == _operationGeneration) {
            _isPhotoLoading = false;
            notifyListeners();
          }
          return;
        }
      }

      // 3. Process & sanitize (bake orientation, square crop, resize max 1024, strip EXIF/GPS, compress)
      final processed = await _photoProcessorService.processMainPhoto(
        sourcePath: rawPath,
        cropRect: cropRect,
      );

      if (currentGen != _operationGeneration) {
        // Discard stale result
        await _photoProcessorService.cleanupTemporaryPhoto(processed.path);
        return;
      }

      // Clean up previous application-owned temp photo if replacing
      if (_profilePhotoPath != null) {
        await _photoProcessorService.cleanupTemporaryPhoto(_profilePhotoPath!);
      }

      _profilePhoto = processed;
      _profilePhotoPath = processed.path;
      _photoError = null;
      _isPhotoLoading = false;
      notifyListeners();
    } catch (e) {
      if (currentGen == _operationGeneration) {
        _photoError = e.toString().replaceFirst('Exception: ', '');
        _isPhotoLoading = false;
        notifyListeners();
      }
    }
  }

  /// Removes the primary profile photo.
  void removeProfilePhoto() {
    if (_profilePhotoPath != null) {
      _photoProcessorService.cleanupTemporaryPhoto(_profilePhotoPath!);
    }
    _profilePhotoPath = null;
    _profilePhoto = null;
    _isFaceVerified = false;
    if (config.isProfilePhotoRequired) {
      _photoError = 'Profile photo is required for Social.';
    } else {
      _photoError = null;
    }
    notifyListeners();
  }

  /// Picks and processes an additional slot photo, preserving original visual aspect ratio.
  Future<void> pickAdditionalPhoto({
    required int slotIndex,
    BuildContext? context,
    PhotoSource? source,
    String? directPath,
  }) async {
    if (_isPhotoLoading) return;
    if (slotIndex < 0 || slotIndex >= config.maxAdditionalPhotos) return;
    if (_additionalPhotoPaths.length >= config.maxAdditionalPhotos &&
        slotIndex >= _additionalPhotoPaths.length) {
      return; // 4th photo cannot be added
    }

    final int currentGen = ++_operationGeneration;

    PhotoSource? chosenSource = source;
    if (chosenSource == null && directPath == null) {
      if (context == null) return;
      chosenSource = await PhotoSourceBottomSheet.show(context);
      if (chosenSource == null) return;
    }

    _isPhotoLoading = true;
    _photoError = null;
    notifyListeners();

    try {
      final String? rawPath = directPath ??
          await _photoPickerService.pickPhoto(chosenSource!);

      if (rawPath == null) {
        if (currentGen == _operationGeneration) {
          _isPhotoLoading = false;
          notifyListeners();
        }
        return;
      }

      // 1. Source image technical validation
      final validation =
          await _photoProcessorService.validateSourceImage(rawPath);
      if (!validation.isSuccess) {
        if (currentGen == _operationGeneration) {
          _photoError = validation.message;
          _isPhotoLoading = false;
          notifyListeners();
        }
        return;
      }

      // 2. Process additional photo (preserves aspect ratio, resizes max 1024, strips EXIF/GPS, compresses)
      final processed = await _photoProcessorService.processAdditionalPhoto(
        sourcePath: rawPath,
      );

      if (currentGen != _operationGeneration) {
        await _photoProcessorService.cleanupTemporaryPhoto(processed.path);
        return;
      }

      // 3. Update slot atomically
      if (slotIndex < _additionalPhotoPaths.length) {
        // Replace existing slot
        final oldPath = _additionalPhotoPaths[slotIndex];
        await _photoProcessorService.cleanupTemporaryPhoto(oldPath);
        final updated = List<String>.from(_additionalPhotoPaths);
        updated[slotIndex] = processed.path;
        _additionalPhotoPaths = updated;
      } else {
        // Add new slot
        _additionalPhotoPaths = [..._additionalPhotoPaths, processed.path];
      }

      _photoError = null;
      _isPhotoLoading = false;
      notifyListeners();
    } catch (e) {
      if (currentGen == _operationGeneration) {
        _photoError = e.toString().replaceFirst('Exception: ', '');
        _isPhotoLoading = false;
        notifyListeners();
      }
    }
  }

  /// Adds a photo to the gallery directly up to [config.maxAdditionalPhotos] (3).
  bool addAdditionalPhoto(String path) {
    if (_additionalPhotoPaths.length >= config.maxAdditionalPhotos) {
      return false;
    }
    _additionalPhotoPaths = [..._additionalPhotoPaths, path];
    notifyListeners();
    return true;
  }

  /// Removes a gallery photo at the specified index.
  void removeAdditionalPhoto(int index) {
    if (index >= 0 && index < _additionalPhotoPaths.length) {
      final oldPath = _additionalPhotoPaths[index];
      _photoProcessorService.cleanupTemporaryPhoto(oldPath);
      final updated = List<String>.from(_additionalPhotoPaths);
      updated.removeAt(index);
      _additionalPhotoPaths = updated;
      notifyListeners();
    }
  }

  /// Replaces a gallery photo at the specified index.
  void replaceAdditionalPhoto(int index, String newPath) {
    if (index >= 0 && index < _additionalPhotoPaths.length) {
      final oldPath = _additionalPhotoPaths[index];
      _photoProcessorService.cleanupTemporaryPhoto(oldPath);
      final updated = List<String>.from(_additionalPhotoPaths);
      updated[index] = newPath;
      _additionalPhotoPaths = updated;
      notifyListeners();
    }
  }

  /// Clears in-memory photograph state and releases application-owned temp files.
  void clearPhotos() {
    if (_profilePhotoPath != null) {
      _photoProcessorService.cleanupTemporaryPhoto(_profilePhotoPath!);
      _profilePhotoPath = null;
      _profilePhoto = null;
    }
    for (final p in _additionalPhotoPaths) {
      _photoProcessorService.cleanupTemporaryPhoto(p);
    }
    _additionalPhotoPaths = [];
    _photoError = null;
    notifyListeners();
  }

  /// Resets all form fields and photograph state to empty.
  void reset() {
    _displayName = '';
    _aboutMe = '';
    _location = '';
    clearPhotos();
    _displayNameError = null;
    _photoError = null;
    _generalError = null;
    notifyListeners();
  }

  /// Validates and submits the profile draft.
  Future<bool> saveProfile() async {
    if (_isLoading) return false;

    // Validate Social 18+ eligibility
    if (config.requiresSocialEligibility && !isSocialAuthorizedByServer) {
      _generalError =
          'Social is restricted to members aged 18 and older. Module eligibility required.';
      notifyListeners();
      return false;
    }

    // Validate display name
    if (_displayName.trim().isEmpty) {
      _displayNameError = 'Display name is required.';
      notifyListeners();
      return false;
    }

    // Validate Social profile photo requirement
    if (config.isProfilePhotoRequired &&
        (_profilePhotoPath == null || _profilePhotoPath!.trim().isEmpty)) {
      _photoError = 'Profile photo is required for Social.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _generalError = null;
    notifyListeners();

    try {
      final draft = toDraft();
      final success = await _repository.saveProfile(draft);
      if (!success) {
        _generalError = 'Unable to save profile. Service temporarily unavailable.';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (_) {
      _isLoading = false;
      _generalError = 'Unable to save profile. Service temporarily unavailable.';
      notifyListeners();
      return false;
    }
  }
}
