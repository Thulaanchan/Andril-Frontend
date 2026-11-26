import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_partner_filters.dart';

/// Modal bottom sheet for configuring Learning Partner Explorer filters (CF-04).
///
/// Features:
/// - Skills multi-select filter chips.
/// - Goals multi-select filter chips.
/// - Proficiency level selector.
/// - Communication languages multi-select (Q07 approved: English, Tamil, Tanglish).
/// - Availability window multi-select (Q07 approved).
/// - Apply and Reset controls.
/// - Responsive layout wrapped in SingleChildScrollView.
class LearningPartnerFilterSheet extends StatefulWidget {
  final LearningPartnerFilters initialFilters;
  final ValueChanged<LearningPartnerFilters> onApply;
  final VoidCallback onReset;

  const LearningPartnerFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
    required this.onReset,
  });

  /// Shows the filter bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required LearningPartnerFilters initialFilters,
    required ValueChanged<LearningPartnerFilters> onApply,
    required VoidCallback onReset,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LearningPartnerFilterSheet(
        initialFilters: initialFilters,
        onApply: onApply,
        onReset: onReset,
      ),
    );
  }

  @override
  State<LearningPartnerFilterSheet> createState() =>
      _LearningPartnerFilterSheetState();
}

class _LearningPartnerFilterSheetState
    extends State<LearningPartnerFilterSheet> {
  late Set<String> _skills;
  late Set<String> _goals;
  late Set<String> _proficiencies;
  late Set<String> _languages;
  late Set<String> _availabilities;

  @override
  void initState() {
    super.initState();
    _skills = Set<String>.of(widget.initialFilters.selectedSkills);
    _goals = Set<String>.of(widget.initialFilters.selectedGoals);
    _proficiencies =
        Set<String>.of(widget.initialFilters.selectedProficiencies);
    _languages = Set<String>.of(widget.initialFilters.selectedLanguages);
    _availabilities =
        Set<String>.of(widget.initialFilters.selectedAvailabilities);
  }

  void _handleReset() {
    setState(() {
      _skills.clear();
      _goals.clear();
      _proficiencies.clear();
      _languages.clear();
      _availabilities.clear();
    });
    widget.onReset();
  }

  void _handleApply() {
    final updated = widget.initialFilters.copyWith(
      selectedSkills: _skills,
      selectedGoals: _goals,
      selectedProficiencies: _proficiencies,
      selectedLanguages: _languages,
      selectedAvailabilities: _availabilities,
    );
    widget.onApply(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header handle and title
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Learning Partners',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
                TextButton(
                  key: const ValueKey('btn_sheet_reset'),
                  onPressed: _handleReset,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Filter Sections
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Proficiency Level
                  _buildSectionTitle('Proficiency Level'),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children:
                        LearningPartnerFilters.defaultProficiencies.map((prof) {
                      final selected = _proficiencies.contains(prof);
                      return FilterChip(
                        key: ValueKey('filter_proficiency_$prof'),
                        label: Text(prof),
                        selected: selected,
                        selectedColor:
                            LearningColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: LearningColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w500,
                          color: selected
                              ? LearningColors.primary
                              : LearningColors.heading,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _proficiencies.add(prof);
                            } else {
                              _proficiencies.remove(prof);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16.0),

                  // 2. Communication Languages (Q07 approved)
                  _buildSectionTitle('Communication Language (Q07)'),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children:
                        LearningPartnerFilters.defaultLanguages.map((lang) {
                      final selected = _languages.contains(lang);
                      return FilterChip(
                        key: ValueKey('filter_language_$lang'),
                        label: Text(lang),
                        selected: selected,
                        selectedColor:
                            LearningColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: LearningColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w500,
                          color: selected
                              ? LearningColors.primary
                              : LearningColors.heading,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _languages.add(lang);
                            } else {
                              _languages.remove(lang);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16.0),

                  // 3. Availability Windows (Q07 approved)
                  _buildSectionTitle('Availability Window (Q07)'),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: LearningPartnerFilters.defaultAvailabilities
                        .map((avail) {
                      final selected = _availabilities.contains(avail);
                      return FilterChip(
                        key: ValueKey('filter_availability_$avail'),
                        label: Text(avail),
                        selected: selected,
                        selectedColor:
                            LearningColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: LearningColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w500,
                          color: selected
                              ? LearningColors.primary
                              : LearningColors.heading,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _availabilities.add(avail);
                            } else {
                              _availabilities.remove(avail);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16.0),

                  // 4. Skills
                  _buildSectionTitle('Approved Skills'),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: LearningPartnerFilters.popularSkills.map((skill) {
                      final selected = _skills.contains(skill);
                      return FilterChip(
                        key: ValueKey('filter_skill_$skill'),
                        label: Text(skill),
                        selected: selected,
                        selectedColor:
                            LearningColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: LearningColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w500,
                          color: selected
                              ? LearningColors.primary
                              : LearningColors.heading,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _skills.add(skill);
                            } else {
                              _skills.remove(skill);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16.0),

                  // 5. Goals
                  _buildSectionTitle('Learning Goals'),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: LearningPartnerFilters.popularGoals.map((goal) {
                      final selected = _goals.contains(goal);
                      return FilterChip(
                        key: ValueKey('filter_goal_$goal'),
                        label: Text(goal),
                        selected: selected,
                        selectedColor:
                            LearningColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: LearningColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w500,
                          color: selected
                              ? LearningColors.primary
                              : LearningColors.heading,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _goals.add(goal);
                            } else {
                              _goals.remove(goal);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: LearningColors.cardSurface,
              border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                key: const ValueKey('btn_sheet_apply'),
                onPressed: _handleApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  minimumSize: const Size(44, 48),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: LearningColors.heading,
        ),
      ),
    );
  }
}
