import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/discovery/domain/entities/learning_partner_filters.dart';
import 'package:andril_mobile/features/learning/discovery/domain/entities/learning_partner_sort.dart';

void main() {
  group('LearningPartnerFilters Domain & Filtering Model Tests', () {
    test('initializes empty filters with zero active criteria', () {
      final filters = LearningPartnerFilters();

      expect(filters.searchQuery, isEmpty);
      expect(filters.selectedSkills, isEmpty);
      expect(filters.selectedGoals, isEmpty);
      expect(filters.selectedProficiencies, isEmpty);
      expect(filters.selectedLanguages, isEmpty);
      expect(filters.selectedAvailabilities, isEmpty);
      expect(filters.sortOption, equals(LearningPartnerSort.recommended));
      expect(filters.hasActiveFilters, isFalse);
      expect(filters.activeFilterCount, equals(0));
      expect(filters.activeFilterChips, isEmpty);
    });

    test('computes activeFilterCount and activeFilterChips accurately', () {
      final filters = LearningPartnerFilters(
        selectedSkills: const ['Flutter', 'Dart'],
        selectedGoals: const ['Build production apps'],
        selectedProficiencies: const ['Intermediate'],
        selectedLanguages: const ['English', 'Tamil'],
        selectedAvailabilities: const ['Flexible (Any time)'],
      );

      expect(filters.activeFilterCount, equals(7));
      expect(filters.hasActiveFilters, isTrue);

      final chips = filters.activeFilterChips;
      expect(chips.length, equals(7));
      expect(chips.any((c) => c.category == 'Skill' && c.value == 'Flutter'),
          isTrue);
      expect(
          chips.any((c) =>
              c.category == 'Goal' && c.value == 'Build production apps'),
          isTrue);
      expect(
          chips.any(
              (c) => c.category == 'Proficiency' && c.value == 'Intermediate'),
          isTrue);
      expect(chips.any((c) => c.category == 'Language' && c.value == 'Tamil'),
          isTrue);
      expect(
          chips.any((c) =>
              c.category == 'Availability' && c.value == 'Flexible (Any time)'),
          isTrue);
    });

    test('removeFilter removes specific categorical item', () {
      final initial = LearningPartnerFilters(
        selectedSkills: const ['Flutter', 'Dart'],
        selectedLanguages: const ['English', 'Tamil'],
      );

      final updated = initial.removeFilter(category: 'Skill', value: 'Dart');
      expect(updated.selectedSkills, equals({'Flutter'}));
      expect(updated.selectedLanguages, equals({'English', 'Tamil'}));

      final updated2 =
          updated.removeFilter(category: 'Language', value: 'Tamil');
      expect(updated2.selectedLanguages, equals({'English'}));
    });

    test('clear resets all categorical filters and search text', () {
      final filters = LearningPartnerFilters(
        searchQuery: 'Mobile',
        selectedSkills: const ['Flutter'],
        selectedProficiencies: const ['Advanced'],
        sortOption: LearningPartnerSort.nameAsc,
      );

      final cleared = filters.clear();
      expect(cleared.searchQuery, isEmpty);
      expect(cleared.selectedSkills, isEmpty);
      expect(cleared.selectedProficiencies, isEmpty);
      expect(cleared.hasActiveFilters, isFalse);
      expect(cleared.sortOption, equals(LearningPartnerSort.nameAsc));
    });

    test('enforces defensive immutability on filter sets', () {
      final mutableSkills = {'Flutter', 'Dart'};
      final filters = LearningPartnerFilters(selectedSkills: mutableSkills);

      mutableSkills.add('Java');
      expect(filters.selectedSkills, equals({'Flutter', 'Dart'}));

      expect(() => filters.selectedSkills.add('Rust'), throwsUnsupportedError);
    });

    test('equality and hashCode are order-independent for sets', () {
      final f1 = LearningPartnerFilters(
        selectedSkills: const ['Flutter', 'Dart'],
        selectedLanguages: const ['English', 'Tamil'],
      );
      final f2 = LearningPartnerFilters(
        selectedSkills: const ['Dart', 'Flutter'],
        selectedLanguages: const ['Tamil', 'English'],
      );

      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
    });

    test('LearningPartnerSort provides user-friendly labels', () {
      expect(LearningPartnerSort.recommended.label, equals('Recommended'));
      expect(LearningPartnerSort.nameAsc.label, equals('Name: A to Z'));
      expect(LearningPartnerSort.nameDesc.label, equals('Name: Z to A'));
      expect(
          LearningPartnerSort.skillsCount.label, equals('Most Skills Offered'));
    });
  });
}
