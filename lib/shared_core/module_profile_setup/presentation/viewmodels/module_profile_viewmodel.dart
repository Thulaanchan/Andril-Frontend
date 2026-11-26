import 'package:flutter/foundation.dart';
import '../../data/repositories/unconfigured_module_profile_repository.dart';
import '../../domain/models/module_profile_draft.dart';
import '../../domain/models/profile_creation_config.dart';
import '../../domain/repositories/module_profile_repository.dart';

/// Presentation ViewModel for module profile creation (Screens 12, 14, and 16).
///
/// Follows Clean Architecture and MVVM:
/// - Enforces module identity privacy: no cross-module copying, scoped per instance.
/// - Validates required display name (trimmed, non-empty).
/// - Enforces 100-character UI presentation limit for About Me.
/// - Enforces photo requirement and facial detection boundary for Social.
/// - Prevents duplicate submissions while an asynchronous operation is in flight.
/// - Default repository is fail-closed [UnconfiguredModuleProfileRepository].
class ModuleProfileViewModel extends ChangeNotifier {
  ModuleProfileViewModel({
    required this.config,
    ModuleProfileRepository? repository,
    this.isSocialAuthorizedByServer = true,
  }) : _repository = repository ?? const UnconfiguredModuleProfileRepository();

  final ProfileCreationConfig config;
  final ModuleProfileRepository _repository;
  final bool isSocialAuthorizedByServer;

  String _displayName = '';
  String _aboutMe = '';
  String _location = '';
  String? _profilePhotoPath;
  List<String> _additionalPhotoPaths = [];
  bool _isFaceVerified = false;

  bool _isLoading = false;
  String? _displayNameError;
  String? _photoError;
  String? _generalError;

  // Getters
  String get displayName => _displayName;
  String get aboutMe => _aboutMe;
  String get location => _location;
  String? get profilePhotoPath => _profilePhotoPath;
  List<String> get additionalPhotoPaths => List.unmodifiable(_additionalPhotoPaths);
  bool get isFaceVerified => _isFaceVerified;
  bool get isLoading => _isLoading;

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

  /// Sets the primary profile photo.
  Future<void> setProfilePhoto(String path) async {
    _profilePhotoPath = path;
    _photoError = null;
    notifyListeners();
  }

  /// Removes the primary profile photo.
  void removeProfilePhoto() {
    _profilePhotoPath = null;
    _isFaceVerified = false;
    if (config.isProfilePhotoRequired) {
      _photoError = 'Profile photo is required for Social.';
    } else {
      _photoError = null;
    }
    notifyListeners();
  }

  /// Adds a photo to the gallery up to [config.maxAdditionalPhotos] (3).
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
      final updated = List<String>.from(_additionalPhotoPaths);
      updated.removeAt(index);
      _additionalPhotoPaths = updated;
      notifyListeners();
    }
  }

  /// Replaces a gallery photo at the specified index.
  void replaceAdditionalPhoto(int index, String newPath) {
    if (index >= 0 && index < _additionalPhotoPaths.length) {
      final updated = List<String>.from(_additionalPhotoPaths);
      updated[index] = newPath;
      _additionalPhotoPaths = updated;
      notifyListeners();
    }
  }

  /// Validates and submits the profile draft.
  ///
  /// Prevents duplicate submissions while in-flight.
  /// Returns `true` if saved successfully, `false` otherwise.
  Future<bool> saveProfile() async {
    if (_isLoading) return false;

    // Validate Social 18+ eligibility
    if (config.requiresSocialEligibility && !isSocialAuthorizedByServer) {
      _generalError =
          'Social is restricted to members aged 18 and older. Module eligibility required.';
      notifyListeners();
      return false;
    }

    // Validate Display Name
    final trimmedName = _displayName.trim();
    if (trimmedName.isEmpty) {
      _displayNameError = 'Display name is required.';
      notifyListeners();
      return false;
    }

    // Validate Profile Photo
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
      if (success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _generalError = 'Unable to save profile. Service unavailable.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _generalError = 'Unable to save profile: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Clears all input state and error messages for account switching or logout.
  void reset() {
    _displayName = '';
    _aboutMe = '';
    _location = '';
    _profilePhotoPath = null;
    _additionalPhotoPaths = [];
    _isFaceVerified = false;
    _isLoading = false;
    _displayNameError = null;
    _photoError = null;
    _generalError = null;
    notifyListeners();
  }
}
