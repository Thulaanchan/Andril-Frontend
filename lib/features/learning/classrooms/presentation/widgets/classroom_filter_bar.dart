import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';

/// Filter bar providing search input and category chips for classrooms discovery.
class ClassroomFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<String> categories;

  const ClassroomFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categories = const [
      'All',
      'Programming',
      'Design',
      'Languages',
      'Business',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search classrooms, topics, or educators...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20.0),
                      onPressed: onClearSearch,
                      tooltip: 'Clear search',
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide:
                    const BorderSide(color: LearningColors.primary, width: 1.5),
              ),
            ),
          ),
        ),

        // Horizontal Category Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: categories.map((cat) {
              final isSelected =
                  cat.toLowerCase() == selectedCategory.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onCategorySelected(cat);
                    }
                  },
                  selectedColor: LearningColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? LearningColors.primary
                        : const Color(0xFF475569),
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? LearningColors.primary
                        : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
