import 'package:flutter/foundation.dart';

import 'learning_partner_sort.dart';

/// Immutable filter criteria model for Learning Partner Explorer (CF-04).
///
/// Features:
/// - Text query for searching across skills, goals, and display names.
/// - Approved multi-select skill filters.
/// - Approved multi-select goal filters.
/// - Approved proficiency level filters (Beginner, Intermediate, Advanced).
/// - Approved communication language filters (English, Tamil, Tanglish from Q07_LUC-03).
/// - Approved availability window filters (from Q07_LUC-03).
/// - Supported sorting option.
@immutable
class LearningPartnerFilters {
  /// Standard approved proficiency options.
  static const List<String> defaultProficiencies = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  /// Standard approved communication languages from Q07_LUC-03.
  static const List<String> defaultLanguages = [
    'English',
    'Tamil',
    'Tanglish',
  ];

  /// Standard approved availability windows from Q07_LUC-03.
  static const List<String> defaultAvailabilities = [
    'Morning (6 AM – 12 PM)',
    'Afternoon (12 PM – 6 PM)',
    'Evening (6 PM – 10 PM)',
    'Late Night (10 PM – 2 AM)',
    'Flexible (Any time)',
  ];

  /// Common approved skill suggestions for filter chips.
  static const List<String> popularSkills = [
    'Flutter',
    'Dart',
    'Figma',
    'UI/UX Design',
    'Python',
    'Clean Architecture',
    'Data Science',
    'Mobile Prototyping',
    'Web Development',
    'Database Systems',
  ];

  /// Common approved goal suggestions for filter chips.
  static const List<String> popularGoals = [
    'Master state management',
    'Build production apps',
    'Career transition',
    'Learn Clean Architecture',
    'Open source contribution',
    'Portfolio creation',
  ];

  /// Search query string.
  final String searchQuery;

  /// Selected skills to filter by.
  final Set<String> _selectedSkills;

  /// Selected goals to filter by.
  final Set<String> _selectedGoals;

  /// Selected proficiency levels to filter by.
  final Set<String> _selectedProficiencies;

  /// Selected languages to filter by.
  final Set<String> _selectedLanguages;

  /// Selected availabilities to filter by.
  final Set<String> _selectedAvailabilities;

  /// Selected sorting option.
  final LearningPartnerSort sortOption;

  /// Creates an immutable [LearningPartnerFilters] container.
  LearningPartnerFilters({
    this.searchQuery = '',
    Iterable<String>? selectedSkills,
    Iterable<String>? selectedGoals,
    Iterable<String>? selectedProficiencies,
    Iterable<String>? selectedLanguages,
    Iterable<String>? selectedAvailabilities,
    this.sortOption = LearningPartnerSort.recommended,
  })  : _selectedSkills = selectedSkills == null
            ? const <String>{}
            : Set<String>.unmodifiable(Set<String>.of(selectedSkills)),
        _selectedGoals = selectedGoals == null
            ? const <String>{}
            : Set<String>.unmodifiable(Set<String>.of(selectedGoals)),
        _selectedProficiencies = selectedProficiencies == null
            ? const <String>{}
            : Set<String>.unmodifiable(Set<String>.of(selectedProficiencies)),
        _selectedLanguages = selectedLanguages == null
            ? const <String>{}
            : Set<String>.unmodifiable(Set<String>.of(selectedLanguages)),
        _selectedAvailabilities = selectedAvailabilities == null
            ? const <String>{}
            : Set<String>.unmodifiable(Set<String>.of(selectedAvailabilities));

  /// Empty filter container.
  factory LearningPartnerFilters.empty() => LearningPartnerFilters();

  /// Unmodifiable view of selected skills.
  Set<String> get selectedSkills => _selectedSkills;

  /// Unmodifiable view of selected goals.
  Set<String> get selectedGoals => _selectedGoals;

  /// Unmodifiable view of selected proficiencies.
  Set<String> get selectedProficiencies => _selectedProficiencies;

  /// Unmodifiable view of selected languages.
  Set<String> get selectedLanguages => _selectedLanguages;

  /// Unmodifiable view of selected availabilities.
  Set<String> get selectedAvailabilities => _selectedAvailabilities;

  /// Whether any filtering criteria (search or category filters) are currently active.
  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      _selectedSkills.isNotEmpty ||
      _selectedGoals.isNotEmpty ||
      _selectedProficiencies.isNotEmpty ||
      _selectedLanguages.isNotEmpty ||
      _selectedAvailabilities.isNotEmpty;

  /// Total count of categorical filter items currently active.
  int get activeFilterCount =>
      _selectedSkills.length +
      _selectedGoals.length +
      _selectedProficiencies.length +
      _selectedLanguages.length +
      _selectedAvailabilities.length;

  /// Generates a list of all active filter descriptor chips for quick display and removal.
  List<({String category, String value})> get activeFilterChips {
    final chips = <({String category, String value})>[];
    for (final skill in _selectedSkills) {
      chips.add((category: 'Skill', value: skill));
    }
    for (final goal in _selectedGoals) {
      chips.add((category: 'Goal', value: goal));
    }
    for (final prof in _selectedProficiencies) {
      chips.add((category: 'Proficiency', value: prof));
    }
    for (final lang in _selectedLanguages) {
      chips.add((category: 'Language', value: lang));
    }
    for (final avail in _selectedAvailabilities) {
      chips.add((category: 'Availability', value: avail));
    }
    return List.unmodifiable(chips);
  }

  /// Copies filters with updated options.
  LearningPartnerFilters copyWith({
    String? searchQuery,
    Iterable<String>? selectedSkills,
    Iterable<String>? selectedGoals,
    Iterable<String>? selectedProficiencies,
    Iterable<String>? selectedLanguages,
    Iterable<String>? selectedAvailabilities,
    LearningPartnerSort? sortOption,
  }) {
    return LearningPartnerFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSkills: selectedSkills ?? _selectedSkills,
      selectedGoals: selectedGoals ?? _selectedGoals,
      selectedProficiencies: selectedProficiencies ?? _selectedProficiencies,
      selectedLanguages: selectedLanguages ?? _selectedLanguages,
      selectedAvailabilities: selectedAvailabilities ?? _selectedAvailabilities,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  /// Removes an individual categorical filter value.
  LearningPartnerFilters removeFilter({
    required String category,
    required String value,
  }) {
    switch (category) {
      case 'Skill':
        final set = Set<String>.of(_selectedSkills)..remove(value);
        return copyWith(selectedSkills: set);
      case 'Goal':
        final set = Set<String>.of(_selectedGoals)..remove(value);
        return copyWith(selectedGoals: set);
      case 'Proficiency':
        final set = Set<String>.of(_selectedProficiencies)..remove(value);
        return copyWith(selectedProficiencies: set);
      case 'Language':
        final set = Set<String>.of(_selectedLanguages)..remove(value);
        return copyWith(selectedLanguages: set);
      case 'Availability':
        final set = Set<String>.of(_selectedAvailabilities)..remove(value);
        return copyWith(selectedAvailabilities: set);
      default:
        return this;
    }
  }

  /// Resets all categorical filters and search query back to initial state.
  LearningPartnerFilters clear() =>
      LearningPartnerFilters(sortOption: sortOption);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningPartnerFilters &&
        other.searchQuery == searchQuery &&
        other.sortOption == sortOption &&
        setEquals(other._selectedSkills, _selectedSkills) &&
        setEquals(other._selectedGoals, _selectedGoals) &&
        setEquals(other._selectedProficiencies, _selectedProficiencies) &&
        setEquals(other._selectedLanguages, _selectedLanguages) &&
        setEquals(other._selectedAvailabilities, _selectedAvailabilities);
  }

  @override
  int get hashCode => Object.hash(
        searchQuery,
        sortOption,
        Object.hashAllUnordered(_selectedSkills),
        Object.hashAllUnordered(_selectedGoals),
        Object.hashAllUnordered(_selectedProficiencies),
        Object.hashAllUnordered(_selectedLanguages),
        Object.hashAllUnordered(_selectedAvailabilities),
      );
}
