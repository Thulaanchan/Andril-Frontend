import 'package:flutter/foundation.dart';

/// In-memory draft entity representing the user's uncommitted profile data
/// during module profile setup (Screens 12, 14, and 16).
///
/// Ensures strict per-module identity isolation:
/// - Scoped to a specific [moduleId]
/// - Display name uniqueness verified per module
/// - Photo selections and bios not automatically shared across modules
@immutable
class ModuleProfileDraft {
  const ModuleProfileDraft({
    required this.moduleId,
    this.displayName = '',
    this.aboutMe = '',
    this.location = '',
    this.profilePhotoPath,
    this.additionalPhotoPaths = const [],
    this.isFaceVerified = false,
  });

  /// Module identifier ('learning', 'hobbies', 'social').
  final String moduleId;

  /// Required display name, unique within the module.
  final String displayName;

  /// Optional biography / about me text, UI presentation limited to 100 characters.
  final String aboutMe;

  /// Selected city or region.
  final String location;

  /// Local path or URI to the chosen profile photo.
  final String? profilePhotoPath;

  /// List of additional photos (up to 3 slots).
  final List<String> additionalPhotoPaths;

  /// Status of human face verification (strictly required for Social).
  final bool isFaceVerified;

  /// Whether the draft meets minimal validation for submission.
  bool isValid({bool isProfilePhotoRequired = false, bool requiresFaceVerification = false}) {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) return false;
    if (isProfilePhotoRequired && (profilePhotoPath == null || profilePhotoPath!.trim().isEmpty)) {
      return false;
    }
    if (requiresFaceVerification && !isFaceVerified) {
      return false;
    }
    return true;
  }

  ModuleProfileDraft copyWith({
    String? moduleId,
    String? displayName,
    String? aboutMe,
    String? location,
    String? profilePhotoPath,
    bool clearProfilePhoto = false,
    List<String>? additionalPhotoPaths,
    bool? isFaceVerified,
  }) {
    return ModuleProfileDraft(
      moduleId: moduleId ?? this.moduleId,
      displayName: displayName ?? this.displayName,
      aboutMe: aboutMe ?? this.aboutMe,
      location: location ?? this.location,
      profilePhotoPath: clearProfilePhoto ? null : (profilePhotoPath ?? this.profilePhotoPath),
      additionalPhotoPaths: additionalPhotoPaths ?? this.additionalPhotoPaths,
      isFaceVerified: isFaceVerified ?? this.isFaceVerified,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModuleProfileDraft &&
        other.moduleId == moduleId &&
        other.displayName == displayName &&
        other.aboutMe == aboutMe &&
        other.location == location &&
        other.profilePhotoPath == profilePhotoPath &&
        listEquals(other.additionalPhotoPaths, additionalPhotoPaths) &&
        other.isFaceVerified == isFaceVerified;
  }

  @override
  int get hashCode {
    return Object.hash(
      moduleId,
      displayName,
      aboutMe,
      location,
      profilePhotoPath,
      Object.hashAll(additionalPhotoPaths),
      isFaceVerified,
    );
  }

  @override
  String toString() {
    return 'ModuleProfileDraft(moduleId: $moduleId, displayName: $displayName, '
        'hasPhoto: ${profilePhotoPath != null}, photoCount: ${additionalPhotoPaths.length}, '
        'isFaceVerified: $isFaceVerified)';
  }
}
