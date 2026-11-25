import 'package:characters/characters.dart';

/// Immutable presentation draft representing Social-specific profile input.
///
/// Follows M5-FE-S02-SEC-02 and confirmed backend contract boundaries:
/// - Display name: 3–30 Unicode text elements/grapheme clusters (evaluated after trimming).
/// - Enforces backend-aligned character validation (letters, numbers, spaces, '_', '-',
///   and script combining marks following letter/digit base).
/// - Allows Tamil pulli and Sinhala al-lakuna join controls between consonants.
/// - Rejects default-ignorable marks, invisible fillers, directional controls, and emojis.
/// - Bio: optional, up to 300 Unicode text elements/grapheme clusters.
/// - Visibility: restricted strictly to the approved private state ('private').
/// - Reserved administrative display names are rejected.
/// - Client cannot set or mutate ownership, eligibility, or completion flags.
class SocialProfileDraft {
  /// Approved draft visibility is strictly private.
  static const String privateVisibility = 'private';

  /// Minimum approved display name length in Unicode text elements.
  static const int minDisplayNameLength = 3;

  /// Maximum approved display name length in Unicode text elements.
  static const int maxDisplayNameLength = 30;

  /// Maximum approved bio length in Unicode text elements.
  static const int maxBioLength = 300;

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

  static final RegExp _unicodeLetterOrDigit =
      RegExp(r'^[\p{L}\p{N}]$', unicode: true);
  static final RegExp _unicodeCombiningMark =
      RegExp(r'^\p{M}$', unicode: true);

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

  /// Checks if a string contains null characters or unmatched surrogates.
  static bool _containsInvalidUnicode(String value) {
    for (int i = 0; i < value.length; i++) {
      final codeUnit = value.codeUnitAt(i);
      if (codeUnit == 0) return true;
      // Low surrogate without high surrogate
      if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) return true;
      // High surrogate
      if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
        if (++i >= value.length) return true;
        final next = value.codeUnitAt(i);
        if (next < 0xDC00 || next > 0xDFFF) return true;
      }
    }
    return false;
  }

  /// Evaluates Tamil and Sinhala consonant joiners (virama / al-lakuna).
  static bool _isScriptJoiner(List<int> runes, int index) {
    if (index < 1 || index + 1 >= runes.length) return false;

    // Tamil pulli (0x0BCD) or Sinhala al-lakuna (0x0DCA) between consonants
    if (index >= 2 && (runes[index - 1] == 0x0BCD || runes[index - 1] == 0x0DCA)) {
      final virama = runes[index - 1];
      return _isConsonant(runes[index - 2], virama) &&
          _isConsonant(runes[index + 1], virama);
    }

    // Sinhala touching conjuncts: ZWJ before al-lakuna (0x0DCA)
    return runes[index] == 0x200D &&
        index + 2 < runes.length &&
        runes[index + 1] == 0x0DCA &&
        _isConsonant(runes[index - 1], 0x0DCA) &&
        _isConsonant(runes[index + 2], 0x0DCA);
  }

  static bool _isConsonant(int rune, int virama) {
    if (virama == 0x0BCD) {
      // Tamil consonants: 0x0B95 to 0x0BB9
      return rune >= 0x0B95 && rune <= 0x0BB9;
    } else {
      // Sinhala consonants: 0x0D9A to 0x0DC6
      return rune >= 0x0D9A && rune <= 0x0DC6;
    }
  }

  /// Validates allowed characters matching backend PrivateProfileFieldValidator.
  static bool _hasAllowedNameCharacters(String value) {
    final runes = value.runes.toList();
    bool hasLetterOrDigit = false;
    bool hasMarkBase = false;

    for (int index = 0; index < runes.length; index++) {
      final rune = runes[index];

      // ZWNJ (0x200C) and ZWJ (0x200D)
      if (rune == 0x200C || rune == 0x200D) {
        if (!_isScriptJoiner(runes, index)) return false;
        continue;
      }

      // Prohibited default-ignorable marks, fillers, keycap mark, info emoji, and directional controls
      if (rune == 0x034F ||
          rune == 0x115F ||
          rune == 0x1160 ||
          rune == 0x17B4 ||
          rune == 0x17B5 ||
          (rune >= 0x180B && rune <= 0x180D) ||
          rune == 0x180F ||
          rune == 0x20E3 ||
          rune == 0x2139 ||
          rune == 0x3164 ||
          rune == 0xFFA0 ||
          (rune >= 0xFE00 && rune <= 0xFE0F) ||
          (rune >= 0xE0100 && rune <= 0xE01EF) ||
          (rune >= 0x200E && rune <= 0x200F) ||
          (rune >= 0x202A && rune <= 0x202E) ||
          (rune >= 0x2066 && rune <= 0x2069)) {
        return false;
      }

      final charStr = String.fromCharCode(rune);
      if (_unicodeLetterOrDigit.hasMatch(charStr)) {
        hasLetterOrDigit = true;
        hasMarkBase = true;
      } else if (rune == 0x20 || rune == 0x5F || rune == 0x2D) {
        // ' ', '_', '-'
        hasMarkBase = false;
      } else if (hasMarkBase && _unicodeCombiningMark.hasMatch(charStr)) {
        // Combining mark following letter or digit base is allowed
      } else {
        return false;
      }
    }

    return hasLetterOrDigit;
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

  /// Validates the display name against approved backend boundaries.
  static String? validateDisplayName(String? value) {
    if (value == null) {
      return 'Display name cannot be empty.';
    }
    if (_containsInvalidUnicode(value)) {
      return 'Display name contains invalid characters.';
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Display name cannot be empty.';
    }
    final graphemeCount = trimmed.characters.length;
    if (graphemeCount < minDisplayNameLength) {
      return 'Display name must be at least $minDisplayNameLength characters.';
    }
    if (graphemeCount > maxDisplayNameLength) {
      return 'Display name must not exceed $maxDisplayNameLength characters.';
    }
    if (!_hasAllowedNameCharacters(trimmed)) {
      return 'Display name contains invalid characters.';
    }
    if (_isReservedDisplayName(trimmed)) {
      return 'Display name is reserved and cannot be used.';
    }
    return null;
  }

  /// Validates the optional bio against approved boundaries.
  static String? validateBio(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (_containsInvalidUnicode(value)) {
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
