import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';

/// Filter and search bar component for the Skill Exchange Hub.
///
/// Features:
/// - Skill search query input.
/// - Quick action toggles: "Offer a Skill" and "Learn a Skill".
/// - Category selector chips (All, Technology, Design, Languages, Business).
class SkillFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedCategory;
  final bool filterOfferOnly;
  final bool filterLearnOnly;
  final List<String> categories;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onToggleOfferFilter;
  final VoidCallback onToggleLearnFilter;

  const SkillFilterBar({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.filterOfferOnly,
    required this.filterLearnOnly,
    this.categories = const [
      'All',
      'Technology',
      'Design',
      'Languages',
      'Business',
    ],
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onCategorySelected,
    required this.onToggleOfferFilter,
    required this.onToggleLearnFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            key: const ValueKey('input_skill_search'),
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search skills, topics or partners...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: LearningColors.secondaryText,
                size: 20,
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      key: const ValueKey('btn_clear_search'),
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: LearningColors.cardSurface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(
                  color: LearningColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10.0),

        // Action Quick Toggles: "Offer a Skill" & "Learn a Skill"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: FilterChip(
                  key: const ValueKey('btn_filter_offer'),
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_rounded, size: 14),
                      const SizedBox(width: 4.0),
                      Flexible(
                        child: Text(
                          'Offer a Skill',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  selected: filterOfferOnly,
                  selectedColor: LearningColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: LearningColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        filterOfferOnly ? FontWeight.bold : FontWeight.w500,
                    color: filterOfferOnly
                        ? LearningColors.primary
                        : LearningColors.heading,
                  ),
                  onSelected: (_) => onToggleOfferFilter(),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: FilterChip(
                  key: const ValueKey('btn_filter_learn'),
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 14),
                      const SizedBox(width: 4.0),
                      Flexible(
                        child: Text(
                          'Learn a Skill',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  selected: filterLearnOnly,
                  selectedColor: Colors.amber.shade100,
                  checkmarkColor: Colors.amber.shade900,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        filterLearnOnly ? FontWeight.bold : FontWeight.w500,
                    color: filterLearnOnly
                        ? Colors.amber.shade900
                        : LearningColors.heading,
                  ),
                  onSelected: (_) => onToggleLearnFilter(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8.0),

        // Category Filter Chips (Horizontal scrollable)
        SizedBox(
          height: 38,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    key: ValueKey('chip_category_$cat'),
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: LearningColors.primary,
                    backgroundColor: LearningColors.cardSurface,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : LearningColors.secondaryText,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(
                        color: isSelected
                            ? LearningColors.primary
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        onCategorySelected(cat);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
