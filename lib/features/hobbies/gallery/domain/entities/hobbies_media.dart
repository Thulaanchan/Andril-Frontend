/// Pure Dart domain entity representing an item in the Hobbies Media Gallery.
///
/// Encapsulates core media attributes for private hobby showcase items under
/// HOB-01 (Hobbies Photo Gallery and Media Management).
///
/// Architectural & Privacy Boundaries:
/// - Isolated to the Hobbies module; must never reveal Learning or Dating profile identities.
/// - Distinct from HOB-03 Andril Map contributions (which require fresh in-app camera capture and moderation).
/// - Excludes Hobbies Photo Portfolios (which are permanently excluded per BRD v2.4-R1).
/// - Offline presentation-aligned domain model; does not assume permanently public URLs or storage-specific logic.
/// - Zero external packages, HTTP, or Flutter UI/widget dependencies.
/// - Diagnostic [toString] emits only class-level identification to prevent accidental privacy leakage.
class HobbiesMedia {
  /// Unique identifier for the media item.
  final String id;

  /// Human-readable title of the hobby media item.
  final String title;

  /// Optional descriptive caption or hobby milestone note.
  final String? caption;

  /// Optional media URI or thumbnail reference.
  final String? mediaUrl;

  /// Optional associated hobby category or tag (e.g., 'Pottery', 'Gardening').
  final String? hobbyTag;

  /// Timestamp when the media was recorded or uploaded.
  final DateTime? createdAt;

  /// Creates an immutable [HobbiesMedia] entity.
  const HobbiesMedia({
    required this.id,
    required this.title,
    this.caption,
    this.mediaUrl,
    this.hobbyTag,
    this.createdAt,
  });

  /// Creates a copy of this [HobbiesMedia] with the given fields replaced or cleared.
  ///
  /// For optional fields ([caption], [mediaUrl], [hobbyTag], [createdAt]):
  /// - Passing a non-null value replaces the existing value.
  /// - Setting the respective clear flag to `true` explicitly resets the value to `null`.
  /// - Omitting both preserves the existing value.
  ///
  /// Throws an [ArgumentError] if a replacement value and a clear flag are provided
  /// simultaneously for the same field.
  HobbiesMedia copyWith({
    String? id,
    String? title,
    String? caption,
    String? mediaUrl,
    String? hobbyTag,
    DateTime? createdAt,
    bool clearCaption = false,
    bool clearMediaUrl = false,
    bool clearHobbyTag = false,
    bool clearCreatedAt = false,
  }) {
    if (caption != null && clearCaption) {
      throw ArgumentError.value(
        caption,
        'caption',
        'Cannot provide a new caption and set clearCaption to true simultaneously.',
      );
    }
    if (mediaUrl != null && clearMediaUrl) {
      throw ArgumentError.value(
        mediaUrl,
        'mediaUrl',
        'Cannot provide a new mediaUrl and set clearMediaUrl to true simultaneously.',
      );
    }
    if (hobbyTag != null && clearHobbyTag) {
      throw ArgumentError.value(
        hobbyTag,
        'hobbyTag',
        'Cannot provide a new hobbyTag and set clearHobbyTag to true simultaneously.',
      );
    }
    if (createdAt != null && clearCreatedAt) {
      throw ArgumentError.value(
        createdAt,
        'createdAt',
        'Cannot provide a new createdAt and set clearCreatedAt to true simultaneously.',
      );
    }

    return HobbiesMedia(
      id: id ?? this.id,
      title: title ?? this.title,
      caption: clearCaption ? null : (caption ?? this.caption),
      mediaUrl: clearMediaUrl ? null : (mediaUrl ?? this.mediaUrl),
      hobbyTag: clearHobbyTag ? null : (hobbyTag ?? this.hobbyTag),
      createdAt: clearCreatedAt ? null : (createdAt ?? this.createdAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HobbiesMedia &&
        other.id == id &&
        other.title == title &&
        other.caption == caption &&
        other.mediaUrl == mediaUrl &&
        other.hobbyTag == hobbyTag &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      caption,
      mediaUrl,
      hobbyTag,
      createdAt,
    );
  }

  @override
  String toString() => 'HobbiesMedia';
}
