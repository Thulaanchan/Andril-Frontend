import 'package:flutter/foundation.dart';

/// Immutable domain model representing an eligible Social candidate card (SOC-02).
///
/// Follows Task 107 Fast Feature Delivery Governance:
/// - Maps to backend `SocialExploreCandidateDto` without exposing confidential account identities,
///   matching weights, raw questionnaire answers, or unauthorized precise GPS coordinates.
/// - Enforces strict validation: rejects missing/malformed required identifiers, missing display names,
///   and non-adult ages (< 18).
/// - Does not manufacture missing age (does not default to 18) or missing display names (no 'Explorer').
/// - Defensive immutability: copies and freezes all collection properties upon construction.
/// - Sanitized diagnostic string representation (redacts candidate ID, names, ages, distances).
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
  })  : assert(id.trim().isNotEmpty, 'Candidate ID cannot be empty'),
        assert(displayName.trim().isNotEmpty, 'Candidate displayName cannot be empty'),
        assert(age >= 18, 'Candidate must be an adult aged 18 or older'),
        _sharedLanguages = sharedLanguages == null
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
  /// Rejects malformed or missing identifiers, missing names, or non-adult ages.
  /// Does not manufacture synthetic defaults for required attributes.
  factory SocialCandidate.fromJson(Map<String, dynamic> json) {
    // 1. Required identifier validation
    final rawId = json['candidateProfileId'] ?? json['id'];
    if (rawId == null || rawId is! String || rawId.trim().isEmpty) {
      throw const FormatException('Missing or invalid required candidate identifier.');
    }
    final candidateId = rawId.trim();

    // 2. Required display name validation (do not default to 'Explorer')
    final rawName = json['displayName'];
    if (rawName == null || rawName is! String || rawName.trim().isEmpty) {
      throw const FormatException('Missing or invalid required candidate display name.');
    }
    final name = rawName.trim();

    // 3. Required age validation (do not default to 18; must be adult 18+)
    final rawAge = json['age'];
    if (rawAge == null || rawAge is! num) {
      throw const FormatException('Missing or invalid candidate age: must be a number.');
    }
    final candidateAge = rawAge.toInt();
    if (candidateAge < 18) {
      throw const FormatException('Invalid candidate age: must be an adult 18 or older.');
    }

    // 4. Optional distance validation
    int? distance;
    if (json['approximateDistanceKm'] != null) {
      if (json['approximateDistanceKm'] is num) {
        distance = (json['approximateDistanceKm'] as num).toInt();
        if (distance < 0) distance = null;
      }
    }

    final languages = (json['sharedLanguages'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];

    final goals = (json['sharedConnectionGoals'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];

    final bio = (json['biography'] ?? json['bio'])?.toString();

    final interestItems = (json['interests'] as List<dynamic>?)
            ?.whereType<String>()
            .toSet() ??
        const <String>{};

    final photos = (json['photoUrls'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        (json['photos'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];

    final loc = (json['locationName'] ?? json['location'])?.toString();
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialCandidate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          age == other.age &&
          approximateDistanceKm == other.approximateDistanceKm &&
          biography == other.biography &&
          locationName == other.locationName &&
          isVerified == other.isVerified &&
          setEquals(_interests, other._interests) &&
          listEquals(_sharedLanguages, other._sharedLanguages) &&
          listEquals(_sharedConnectionGoals, other._sharedConnectionGoals) &&
          listEquals(_photoUrls, other._photoUrls);

  @override
  int get hashCode => Object.hash(
        id,
        displayName,
        age,
        approximateDistanceKm,
        biography,
        locationName,
        isVerified,
        Object.hashAllUnordered(_interests),
        Object.hashAll(_sharedLanguages),
        Object.hashAll(_sharedConnectionGoals),
        Object.hashAll(_photoUrls),
      );

  /// Redacted diagnostic representation that prevents private profile data leakage.
  @override
  String toString() => 'SocialCandidate(redacted)';
}
