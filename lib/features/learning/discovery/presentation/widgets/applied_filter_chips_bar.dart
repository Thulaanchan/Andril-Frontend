import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_partner_filters.dart';
import '../../domain/entities/learning_partner_sort.dart';

/// Applied filter chips bar and sort selector for Learning Partner Explorer (CF-04).
///
/// Features:
/// - Verified result count display.
/// - Sort dropdown selector supporting all approved sort options.
/// - Wrapping/scrolling chips for active categorical filters with individual removal ('X').
/// - "Clear all" button when one or more filters are applied.
/// - Responsive layout supporting 320dp viewports and 1.5x font scaling.
class AppliedFilterChipsBar extends StatelessWidget {
  final LearningPartnerFilters filters;
  final int resultCount;
  final ValueChanged<LearningPartnerSort> onSortChanged;
  final void Function(String category, String value) onRemoveFilter;
  final VoidCallback onClearAll;

  const AppliedFilterChipsBar({
    super.key,
    required this.filters,
    required this.resultCount,
    required this.onSortChanged,
    required this.onRemoveFilter,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final activeChips = filters.activeFilterChips;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Result count and Sort dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  key: const ValueKey('text_result_count'),
                  resultCount == 1
                      ? '1 partner found'
                      : '$resultCount partners found',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LearningColors.heading,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              // Sort dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: LearningColors.cardSurface,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LearningPartnerSort>(
                    key: const ValueKey('dropdown_sort_options'),
                    value: filters.sortOption,
                    isDense: true,
                    icon: const Icon(
                      Icons.sort_rounded,
                      size: 18,
                      color: LearningColors.primary,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: LearningColors.heading,
                    ),
                    onChanged: (newSort) {
                      if (newSort != null) {
                        onSortChanged(newSort);
                      }
                    },
                    items: LearningPartnerSort.values.map((sort) {
                      return DropdownMenuItem<LearningPartnerSort>(
                        value: sort,
                        child: Text(sort.label),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          // Row 2: Applied filter chips (if any active)
          if (activeChips.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...activeChips.map((chip) {
                  return Chip(
                    key: ValueKey('chip_filter_${chip.category}_${chip.value}'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor:
                        LearningColors.primary.withValues(alpha: 0.1),
                    deleteIcon: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: LearningColors.primary,
                    ),
                    onDeleted: () => onRemoveFilter(chip.category, chip.value),
                    label: Text(
                      '${chip.category}: ${chip.value}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LearningColors.primary,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    visualDensity: VisualDensity.compact,
                  );
                }),
                TextButton(
                  key: const ValueKey('btn_clear_all_filters'),
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    minimumSize: const Size(44, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
