import 'package:flutter/foundation.dart';

/// Module-scoped Social interest item from the approved catalog.
class SocialInterestItem {
  final String id;
  final String label;
  final String? iconName;

  const SocialInterestItem({
    required this.id,
    required this.label,
    this.iconName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialInterestItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SocialInterestItem(id: $id, label: $label)';
}

/// Immutable draft model representing user-configured Social discovery preferences and interests.
///
/// Follows M5-FE-S03-DOM-01:
/// - Represents module-scoped Social interests independently of Learning or Hobbies.
/// - Maintains defensive immutability with unmodifiable collections.
/// - Manages discovery criteria: age boundaries, distance, relationship goals, languages, showMe.
/// - Excludes completion flags, matching weights, or cross-module data dependencies.
@immutable
class SocialPreferencesModel {
  static const int defaultMinAge = 18;
  static const int defaultMaxAge = 99;
  static const int defaultMaxDistanceKm = 50;

  /// Default approved relationship goals for Social module.
  static const List<String> defaultRelationshipGoals = [
    'Friendship',
    'Networking',
    'Casual Chat',
    'Serious Relationship',
  ];

  /// Default approved languages for Social interaction.
  static const List<String> defaultLanguages = [
    'English',
    'Tamil',
    'Sinhala',
  ];

  /// Default discovery scope options.
  static const List<String> defaultShowMeOptions = [
    'Everyone',
    'Women',
    'Men',
  ];

  /// Internal set of selected interest IDs or keys.
  final Set<String> _selectedInterests;

  /// Minimum preferred age (strictly 18+).
  final int minAge;

  /// Maximum preferred age.
  final int maxAge;

  /// Maximum preferred discovery radius in kilometers.
  final int maxDistanceKm;

  /// Internal selected relationship goals.
  final List<String> _relationshipGoals;

  /// Internal preferred languages for interaction.
  final List<String> _languages;

  /// Preferred discovery scope ('Everyone', 'Women', 'Men').
  final String showMe;

  const SocialPreferencesModel({
    Set<String> selectedInterests = const <String>{},
    this.minAge = defaultMinAge,
    this.maxAge = defaultMaxAge,
    this.maxDistanceKm = defaultMaxDistanceKm,
    List<String> relationshipGoals = const ['Friendship', 'Networking'],
    List<String> languages = const ['English'],
    this.showMe = 'Everyone',
  })  : _selectedInterests = selectedInterests,
        _relationshipGoals = relationshipGoals,
        _languages = languages;

  /// Set of selected interest IDs or keys (defensively unmodifiable).
  Set<String> get selectedInterests =>
      Set<String>.unmodifiable(_selectedInterests);

  /// Selected relationship goals (defensively unmodifiable).
  List<String> get relationshipGoals =>
      List<String>.unmodifiable(_relationshipGoals);

  /// Preferred languages for interaction (defensively unmodifiable).
  List<String> get languages => List<String>.unmodifiable(_languages);

  /// Returns whether a specific interest is selected.
  bool isInterestSelected(String interestId) =>
      _selectedInterests.contains(interestId);

  /// Toggles selection of an interest ID, returning an updated immutable copy.
  SocialPreferencesModel toggleInterest(String interestId) {
    final updated = Set<String>.from(_selectedInterests);
    if (updated.contains(interestId)) {
      updated.remove(interestId);
    } else {
      updated.add(interestId);
    }
    return copyWith(selectedInterests: updated);
  }

  /// Adds an interest to the selected set without duplicates.
  SocialPreferencesModel withInterest(String interestId) {
    if (_selectedInterests.contains(interestId)) return this;
    final updated = Set<String>.from(_selectedInterests)..add(interestId);
    return copyWith(selectedInterests: updated);
  }

  /// Removes an interest from the selected set.
  SocialPreferencesModel withoutInterest(String interestId) {
    if (!_selectedInterests.contains(interestId)) return this;
    final updated = Set<String>.from(_selectedInterests)..remove(interestId);
    return copyWith(selectedInterests: updated);
  }

  /// Toggles a relationship goal in the list.
  SocialPreferencesModel toggleRelationshipGoal(String goal) {
    final updated = List<String>.from(_relationshipGoals);
    if (updated.contains(goal)) {
      updated.remove(goal);
    } else {
      updated.add(goal);
    }
    return copyWith(relationshipGoals: updated);
  }

  /// Toggles a language in the list.
  SocialPreferencesModel toggleLanguage(String language) {
    final updated = List<String>.from(_languages);
    if (updated.contains(language)) {
      updated.remove(language);
    } else {
      updated.add(language);
    }
    return copyWith(languages: updated);
  }

  /// Creates a copy of this preferences draft with updated fields.
  SocialPreferencesModel copyWith({
    Set<String>? selectedInterests,
    int? minAge,
    int? maxAge,
    int? maxDistanceKm,
    List<String>? relationshipGoals,
    List<String>? languages,
    String? showMe,
  }) {
    return SocialPreferencesModel(
      selectedInterests: selectedInterests ?? _selectedInterests,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      relationshipGoals: relationshipGoals ?? _relationshipGoals,
      languages: languages ?? _languages,
      showMe: showMe ?? this.showMe,
    );
  }

  /// Validates that preferences meet minimal client-side boundaries.
  bool get isValid =>
      minAge >= 18 &&
      maxAge >= minAge &&
      maxDistanceKm > 0 &&
      selectedInterests.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialPreferencesModel &&
          runtimeType == other.runtimeType &&
          setEquals(selectedInterests, other.selectedInterests) &&
          minAge == other.minAge &&
          maxAge == other.maxAge &&
          maxDistanceKm == other.maxDistanceKm &&
          listEquals(relationshipGoals, other.relationshipGoals) &&
          listEquals(languages, other.languages) &&
          showMe == other.showMe;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(selectedInterests),
        minAge,
        maxAge,
        maxDistanceKm,
        Object.hashAll(relationshipGoals),
        Object.hashAll(languages),
        showMe,
      );

  @override
  String toString() =>
      'SocialPreferencesModel(selectedCount: ${selectedInterests.length}, minAge: $minAge, maxAge: $maxAge, distance: ${maxDistanceKm}km, showMe: $showMe)';
}
