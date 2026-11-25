import 'package:flutter/foundation.dart';

/// Immutable domain model representing an eligible Social candidate card (SOC-02).
///
/// Follows M5-FE-S09-DOM-01 architectural requirements:
/// - Maps to backend `SocialExploreCandidateDto` without exposing confidential account identities,
///   matching weights, raw questionnaire answers, or unauthorized precise GPS coordinates.
/// - Defensive immutability: copies and freezes all collection properties upon construction.
/// - Order-independent set hashing for consistent equality and hashing contracts.
/// - Sanitized diagnostic string representation.
@immutable
class SocialCandidate {
  /// Social-scoped unique candidate profile identifier (GUID string).
  final String id;

  /// User-visible approved display name.
  final String displayName;

  /// Verified age of the candidate (adult 18+).
  final int age;

  /// Approximate geographic distance in kilometers (optional, coarse distance only).
  final int? approximateDistanceKm;

  /// Defensively immutable list of shared languages.
  final List<String> _sharedLanguages;

  /// Defensively immutable list of shared connection/relationship goals.
  final List<String> _sharedConnectionGoals;

  /// Optional presentation biography text where provided.
  final String? biography;

  /// Defensively immutable set of approved interests.
  final Set<String> _interests;

  /// Defensively immutable list of approved profile photo references.
  final List<String> _photoUrls;

  /// Coarse approximate location name (e.g., 'Kandy', 'Colombo') without precise coordinates.
  final String? locationName;

  /// Whether the candidate profile holds an active verified badge.
  final bool isVerified;

  /// Constructs an immutable [SocialCandidate] with defensive collection copying.
  SocialCandidate({
    required this.id,
    required this.displayName,
    required this.age,
    this.approximateDistanceKm,
    Iterable<String>? sharedLanguages,
    Iterable<String>? sharedConnectionGoals,
    this.biography,
    Iterable<String>? interests,
    Iterable<String>? photoUrls,
    this.locationName,
    this.isVerified = false,
  })  : _sharedLanguages = sharedLanguages == null
            ? const <String>[]
            : List<String>.unmodifiable(List<String>.of(sharedLanguages)),
        _sharedConnectionGoals = sharedConnectionGoals == null
            ? const <String>[]
            : List<String>.unmodifiable(List<String>.of(sharedConnectionGoals)),
        _interests = interests == null
            ? const <String>{}
            : Set<String>.unmodifiable(Set<String>.of(interests)),
        _photoUrls = photoUrls == null
            ? const <String>[]
            : List<String>.unmodifiable(List<String>.of(photoUrls));

  /// Unmodifiable view of shared languages.
  List<String> get sharedLanguages => _sharedLanguages;

  /// Unmodifiable view of shared connection goals.
  List<String> get sharedConnectionGoals => _sharedConnectionGoals;

  /// Unmodifiable view of candidate interests.
  Set<String> get interests => _interests;

  /// Unmodifiable view of profile photo URLs.
  List<String> get photoUrls => _photoUrls;

  /// Primary avatar photo URL (convenience accessor).
  String? get primaryPhotoUrl =>
      _photoUrls.isNotEmpty ? _photoUrls.first : null;

  /// Constructs a [SocialCandidate] from backend JSON payload.
  ///
  /// Supports backend `SocialExploreCandidateDto` field naming conventions:
  /// `candidateProfileId` or `id`, `displayName`, `age`, `approximateDistanceKm`,
  /// `sharedLanguages`, and `sharedConnectionGoals`.
  factory SocialCandidate.fromJson(Map<String, dynamic> json) {
    final candidateId =
        json['candidateProfileId']?.toString() ?? json['id']?.toString() ?? '';
    final name = json['displayName']?.toString() ?? 'Explorer';
    final candidateAge = json['age'] is num ? (json['age'] as num).toInt() : 18;
    final distance = json['approximateDistanceKm'] is num
        ? (json['approximateDistanceKm'] as num).toInt()
        : null;

    final languages = (json['sharedLanguages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    final goals = (json['sharedConnectionGoals'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    final bio = json['biography']?.toString() ?? json['bio']?.toString();

    final interestItems = (json['interests'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        const <String>{};

    final photos = (json['photoUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['photos'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    final loc = json['locationName']?.toString() ?? json['location']?.toString();
    final verified = json['isVerified'] == true;

    return SocialCandidate(
      id: candidateId,
      displayName: name,
      age: candidateAge,
      approximateDistanceKm: distance,
      sharedLanguages: languages,
      sharedConnectionGoals: goals,
      biography: bio,
      interests: interestItems,
      photoUrls: photos,
      locationName: loc,
      isVerified: verified,
    );
  }

  /// Serializes candidate to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'candidateProfileId': id,
      'displayName': displayName,
      'age': age,
      if (approximateDistanceKm != null)
        'approximateDistanceKm': approximateDistanceKm,
      'sharedLanguages': _sharedLanguages,
      'sharedConnectionGoals': _sharedConnectionGoals,
      if (biography != null) 'biography': biography,
      'interests': _interests.toList(),
      'photoUrls': _photoUrls,
      if (locationName != null) 'locationName': locationName,
      'isVerified': isVerified,
    };
  }

  /// Creates a copy of this candidate with specified properties replaced.
  SocialCandidate copyWith({
    String? id,
    String? displayName,
    int? age,
    int? approximateDistanceKm,
    Iterable<String>? sharedLanguages,
    Iterable<String>? sharedConnectionGoals,
    String? biography,
    Iterable<String>? interests,
    Iterable<String>? photoUrls,
    String? locationName,
    bool? isVerified,
  }) {
    return SocialCandidate(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      approximateDistanceKm:
          approximateDistanceKm ?? this.approximateDistanceKm,
      sharedLanguages: sharedLanguages ?? _sharedLanguages,
      sharedConnectionGoals:
          sharedConnectionGoals ?? _sharedConnectionGoals,
      biography: biography ?? this.biography,
      interests: interests ?? _interests,
      photoUrls: photoUrls ?? _photoUrls,
      locationName: locationName ?? this.locationName,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  static int _hashUnorderedSet(Set<Object?> elements) {
    var hash = 0;
    for (final element in elements) {
      hash = (hash + (element?.hashCode ?? 0)) & 0x7FFFFFFF;
    }
    return hash;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialCandidate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          age == other.age &&
          approximateDistanceKm == other.approximateDistanceKm &&
          listEquals(_sharedLanguages, other._sharedLanguages) &&
          listEquals(_sharedConnectionGoals, other._sharedConnectionGoals) &&
          biography == other.biography &&
          setEquals(_interests, other._interests) &&
          listEquals(_photoUrls, other._photoUrls) &&
          locationName == other.locationName &&
          isVerified == other.isVerified;

  @override
  int get hashCode => Object.hash(
        id,
        displayName,
        age,
        approximateDistanceKm,
        Object.hashAll(_sharedLanguages),
        Object.hashAll(_sharedConnectionGoals),
        biography,
        _hashUnorderedSet(_interests),
        Object.hashAll(_photoUrls),
        locationName,
        isVerified,
      );

  @override
  String toString() {
    final distStr = approximateDistanceKm != null ? '${approximateDistanceKm}km' : 'unknown';
    return 'SocialCandidate(id: $id, name: $displayName, age: $age, distance: $distStr, verified: $isVerified)';
  }
}
