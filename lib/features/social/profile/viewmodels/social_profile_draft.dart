import 'package:characters/characters.dart';

/// Immutable presentation draft representing Social-specific profile input.
///
/// Follows M5-FE-S02-DOM-01 and confirmed backend contract boundaries:
/// - Display name: 3–30 Unicode grapheme clusters (evaluated after trimming).
/// - Bio: optional, up to 300 Unicode grapheme clusters.
/// - Visibility: restricted to the approved private state ('private').
/// - Reserved administrative display names are rejected.
/// - Client cannot set or mutate ownership, eligibility, or completion flags.
class SocialProfileDraft {
  /// Approved draft visibility is strictly private.
  static const String privateVisibility = 'private';

  /// Minimum approved display name length in Unicode grapheme clusters.
  static const int minDisplayNameLength = 3;

  /// Maximum approved display name length in Unicode grapheme clusters.
  static const int maxDisplayNameLength = 30;

  /// Maximum approved bio length in Unicode grapheme clusters.
  static const int maxBioLength = 300;

  /// Disallowed C0 and C1 control characters (excluding standard whitespace).
  static final RegExp _disallowedControlRegex =
      RegExp(r'[\u0000-\u001F\u007F-\u009F]');

  /// Reserved administrative display names matching backend contracts.
  static const Set<String> _reservedNames = {
    'andril',
    'admin',
    'administrator',
    'moderator',
    'support',
    'system',
    'official',
    'andriladmin',
    'andrilmoderator',
    'andrilsupport',
    'andrilofficial',
    'andrilteam',
  };

  /// The draft display name entered by the user.
  final String displayName;

  /// The optional draft bio entered by the user.
  final String? bio;

  /// Optional local draft photo path selected on device (remains private).
  final String? profilePhotoPath;

  /// Draft visibility is strictly private and cannot be set to public.
  final String visibility;

  const SocialProfileDraft({
    this.displayName = '',
    this.bio,
    this.profilePhotoPath,
    String? visibility,
  })  : assert(
          visibility == null || visibility == privateVisibility,
          'Draft visibility must be private',
        ),
        visibility = privateVisibility;

  /// Creates a copy of this draft with the given fields replaced.
  ///
  /// Visibility remains strictly [privateVisibility].
  /// Pass [clearBio] or [clearProfilePhoto] to explicitly reset nullable fields.
  SocialProfileDraft copyWith({
    String? displayName,
    String? bio,
    String? profilePhotoPath,
    bool clearBio = false,
    bool clearProfilePhoto = false,
  }) {
    return SocialProfileDraft(
      displayName: displayName ?? this.displayName,
      bio: clearBio ? null : (bio ?? this.bio),
      profilePhotoPath:
          clearProfilePhoto ? null : (profilePhotoPath ?? this.profilePhotoPath),
      visibility: privateVisibility,
    );
  }

  /// Checks if a normalized string matches any backend reserved display name.
  static bool _isReservedDisplayName(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (char == ' ' || char == '_' || char == '-') continue;
      buffer.write(char.toLowerCase());
    }
    return _reservedNames.contains(buffer.toString());
  }

  /// Validates the display name against approved boundaries.
  ///
  /// Evaluates trimmed text element length and rejects reserved administrative names.
  /// Returns a validation error description, or null if valid.
  static String? validateDisplayName(String? value) {
    if (value == null) {
      return 'Display name cannot be empty.';
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Display name cannot be empty.';
    }
    if (_disallowedControlRegex.hasMatch(value)) {
      return 'Display name contains invalid characters.';
    }
    final graphemeCount = trimmed.characters.length;
    if (graphemeCount < minDisplayNameLength) {
      return 'Display name must be at least $minDisplayNameLength characters.';
    }
    if (graphemeCount > maxDisplayNameLength) {
      return 'Display name must not exceed $maxDisplayNameLength characters.';
    }
    if (_isReservedDisplayName(trimmed)) {
      return 'Display name is reserved and cannot be used.';
    }
    return null;
  }

  /// Validates the optional bio against approved boundaries.
  ///
  /// Returns a validation error description, or null if valid.
  static String? validateBio(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    // Allow standard newlines in bio, but disallow other control codes.
    final sanitizedForControlCheck =
        value.replaceAll('\n', '').replaceAll('\r', '').replaceAll('\t', '');
    if (_disallowedControlRegex.hasMatch(sanitizedForControlCheck)) {
      return 'Bio contains invalid characters.';
    }
    final graphemeCount = value.characters.length;
    if (graphemeCount > maxBioLength) {
      return 'Bio must not exceed $maxBioLength characters.';
    }
    return null;
  }

  /// Whether the current draft fields satisfy all client validation rules.
  bool get isValid =>
      validateDisplayName(displayName) == null && validateBio(bio) == null;

  /// Validation error message for display name, or null if valid.
  String? get displayNameError => validateDisplayName(displayName);

  /// Validation error message for bio, or null if valid.
  String? get bioError => validateBio(bio);

  /// Returns grapheme cluster count of display name.
  int get displayNameGraphemeCount => displayName.characters.length;

  /// Returns grapheme cluster count of bio.
  int get bioGraphemeCount => bio?.characters.length ?? 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialProfileDraft &&
          runtimeType == other.runtimeType &&
          displayName == other.displayName &&
          bio == other.bio &&
          profilePhotoPath == other.profilePhotoPath &&
          visibility == other.visibility;

  @override
  int get hashCode =>
      Object.hash(displayName, bio, profilePhotoPath, visibility);

  /// Diagnostic string avoiding sensitive data leaks.
  @override
  String toString() =>
      'SocialProfileDraft(displayNameLength: $displayNameGraphemeCount, hasBio: ${bio != null && bio!.isNotEmpty}, hasPhoto: ${profilePhotoPath != null}, visibility: $visibility)';
}
