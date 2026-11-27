import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';
import '../../interests_preferences/domain/social_preferences_model.dart';

/// Screen S14: Discovery Filters & Preference Settings (SOC-02).
///
/// Follows M5-FE-S14-UI-01 requirements:
/// - Allows adjusting local discovery criteria: Show Me, Age Range, Maximum Distance,
///   Relationship Goals, and Languages.
/// - Operates on an immutable local draft of [SocialPreferencesModel].
/// - Fails closed: Uses only approved defaults and catalogs from [SocialPreferencesModel].
/// - Enforces adult age boundaries (minAge strictly >= 18).
/// - Provides Apply, Reset, and Cancel actions without claiming server persistence.
/// - Responsive layout down to 320dp and under accessibility text scaling (1.3).
class SocialDiscoveryFiltersScreen extends StatefulWidget {
  final SocialPreferencesModel? initialFilters;
  final ValueChanged<SocialPreferencesModel>? onApply;
  final VoidCallback? onCancel;

  const SocialDiscoveryFiltersScreen({
    super.key,
    this.initialFilters,
    this.onApply,
    this.onCancel,
  });

  @override
  State<SocialDiscoveryFiltersScreen> createState() =>
      _SocialDiscoveryFiltersScreenState();
}

class _SocialDiscoveryFiltersScreenState
    extends State<SocialDiscoveryFiltersScreen> {
  late String _showMe;
  late RangeValues _ageRange;
  late double _distanceKm;
  late Set<String> _selectedGoals;
  late Set<String> _selectedLanguages;

  @override
  void initState() {
    super.initState();
    _initializeFromModel(widget.initialFilters ?? const SocialPreferencesModel.empty());
  }

  void _initializeFromModel(SocialPreferencesModel model) {
    _showMe = model.showMe;
    _ageRange = RangeValues(
      model.minAge.toDouble().clamp(18.0, 80.0),
      model.maxAge.toDouble().clamp(18.0, 80.0),
    );
    _distanceKm = model.maxDistanceKm.toDouble().clamp(5.0, 100.0);
    _selectedGoals = Set<String>.of(model.relationshipGoals);
    _selectedLanguages = Set<String>.of(model.languages);
  }

  void _resetToDefaults() {
    setState(() {
      _initializeFromModel(const SocialPreferencesModel.empty());
    });
  }

  SocialPreferencesModel _buildCurrentDraft() {
    return SocialPreferencesModel(
      showMe: _showMe,
      minAge: _ageRange.start.round().clamp(18, 99),
      maxAge: _ageRange.end.round().clamp(18, 99),
      maxDistanceKm: _distanceKm.round().clamp(5, 100),
      relationshipGoals: _selectedGoals,
      languages: _selectedLanguages,
      selectedInterests: widget.initialFilters?.selectedInterests,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AndrilSocialColors.cream,
      appBar: AppBar(
        backgroundColor: AndrilSocialColors.cream,
        foregroundColor: AndrilSocialColors.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: widget.onCancel ?? () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Discovery Filters',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AndrilSocialColors.ink,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetToDefaults,
            style: TextButton.styleFrom(
              foregroundColor: AndrilSocialColors.royalPurple,
            ),
            child: const Text(
              'Reset',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show Me Scope Section
                    _buildSectionHeader('Show Me'),
                    const SizedBox(height: 10),
                    _buildShowMeSelector(),
                    const SizedBox(height: 24),

                    // Age Range Slider Section
                    _buildSectionHeader(
                      'Age Range',
                      trailing: '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                    ),
                    const SizedBox(height: 8),
                    _buildAgeRangeSlider(),
                    const SizedBox(height: 24),

                    // Maximum Distance Slider Section
                    _buildSectionHeader(
                      'Maximum Distance',
                      trailing: '${_distanceKm.round()} km',
                    ),
                    const SizedBox(height: 8),
                    _buildDistanceSlider(),
                    const SizedBox(height: 24),

                    // Relationship Goals Section
                    _buildSectionHeader('Looking For'),
                    const SizedBox(height: 10),
                    _buildRelationshipGoals(),
                    const SizedBox(height: 24),

                    // Languages Section
                    _buildSectionHeader('Languages'),
                    const SizedBox(height: 10),
                    _buildLanguages(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom Sticky Apply Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final draft = _buildCurrentDraft();
                    widget.onApply?.call(draft);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AndrilSocialColors.royalPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AndrilSocialColors.ink,
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AndrilSocialColors.royalPurple,
            ),
          ),
      ],
    );
  }

  Widget _buildShowMeSelector() {
    return Row(
      children: SocialPreferencesModel.defaultShowMeOptions.map((option) {
        final isSelected = _showMe == option;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Center(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AndrilSocialColors.ink,
                  ),
                ),
              ),
              selected: isSelected,
              selectedColor: AndrilSocialColors.royalPurple,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected
                      ? AndrilSocialColors.royalPurple
                      : AndrilSocialColors.border,
                ),
              ),
              onSelected: (_) {
                setState(() {
                  _showMe = option;
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAgeRangeSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AndrilSocialColors.border),
      ),
      child: RangeSlider(
        values: _ageRange,
        min: 18.0,
        max: 80.0,
        divisions: 62,
        activeColor: AndrilSocialColors.royalPurple,
        inactiveColor: AndrilSocialColors.border,
        labels: RangeLabels(
          '${_ageRange.start.round()}',
          '${_ageRange.end.round()}',
        ),
        onChanged: (values) {
          setState(() {
            _ageRange = values;
          });
        },
      ),
    );
  }

  Widget _buildDistanceSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AndrilSocialColors.border),
      ),
      child: Slider(
        value: _distanceKm,
        min: 5.0,
        max: 100.0,
        divisions: 19,
        activeColor: AndrilSocialColors.royalPurple,
        inactiveColor: AndrilSocialColors.border,
        label: '${_distanceKm.round()} km',
        onChanged: (value) {
          setState(() {
            _distanceKm = value;
          });
        },
      ),
    );
  }

  Widget _buildRelationshipGoals() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SocialPreferencesModel.defaultRelationshipGoals.map((goal) {
        final isSelected = _selectedGoals.contains(goal);
        return FilterChip(
          label: Text(
            goal,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AndrilSocialColors.ink,
            ),
          ),
          selected: isSelected,
          selectedColor: AndrilSocialColors.royalPurple,
          backgroundColor: Colors.white,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? AndrilSocialColors.royalPurple
                  : AndrilSocialColors.border,
            ),
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedGoals.add(goal);
              } else {
                _selectedGoals.remove(goal);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildLanguages() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SocialPreferencesModel.defaultLanguages.map((language) {
        final isSelected = _selectedLanguages.contains(language);
        return FilterChip(
          label: Text(
            language,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AndrilSocialColors.ink,
            ),
          ),
          selected: isSelected,
          selectedColor: AndrilSocialColors.royalPurple,
          backgroundColor: Colors.white,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? AndrilSocialColors.royalPurple
                  : AndrilSocialColors.border,
            ),
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedLanguages.add(language);
              } else {
                _selectedLanguages.remove(language);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
