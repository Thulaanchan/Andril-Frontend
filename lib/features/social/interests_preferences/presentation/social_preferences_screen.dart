import 'package:andril_mobile/app/themes/social/social_theme.dart';
import 'package:andril_mobile/features/social/interests_preferences/domain/social_preferences_model.dart';
import 'package:flutter/material.dart';

/// Screen S03: Social Interests & Preferences.
///
/// Follows M5-FE-S03-SEC-03 and approved Social UI specifications:
/// - Social theme with [SocialWaveBackground] and approved palette tokens:
///   Royal Purple (#330099), Copper (#C47A44), Cream (#FAF7F2).
/// - Interests selection from approved catalog with duplicate prevention.
/// - Discovery criteria: age range (18–99), maximum distance, relationship goals, languages, and showMe.
/// - Defensively immutable preference state updates.
/// - Guards against repeated or stale asynchronous submissions.
/// - Distinguishes local draft progression from verified persistence.
/// - Excludes Personality Test controls.
class SocialPreferencesScreen extends StatefulWidget {
  final SocialPreferencesModel? initialPreferences;
  final List<SocialInterestItem>? interestCatalog;
  final VoidCallback? onBack;
  final ValueChanged<SocialPreferencesModel>? onContinue;
  final Future<bool> Function(SocialPreferencesModel preferences)? onSave;

  const SocialPreferencesScreen({
    super.key,
    this.initialPreferences,
    this.interestCatalog,
    this.onBack,
    this.onContinue,
    this.onSave,
  });

  /// Default approved Social interests catalog items.
  static const List<SocialInterestItem> defaultSocialInterests = [
    SocialInterestItem(id: 'music', label: 'Music & Concerts'),
    SocialInterestItem(id: 'coffee', label: 'Coffee & Cafes'),
    SocialInterestItem(id: 'travel', label: 'Travel & Exploring'),
    SocialInterestItem(id: 'fitness', label: 'Fitness & Wellness'),
    SocialInterestItem(id: 'photography', label: 'Photography'),
    SocialInterestItem(id: 'reading', label: 'Books & Literature'),
    SocialInterestItem(id: 'art', label: 'Art & Design'),
    SocialInterestItem(id: 'tech', label: 'Tech & Startups'),
    SocialInterestItem(id: 'gaming', label: 'Board Games & Gaming'),
    SocialInterestItem(id: 'food', label: 'Food & Cooking'),
  ];

  @override
  State<SocialPreferencesScreen> createState() =>
      _SocialPreferencesScreenState();
}

class _SocialPreferencesScreenState extends State<SocialPreferencesScreen> {
  late SocialPreferencesModel _preferences;
  bool _isLoading = false;
  int _submitGeneration = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _preferences =
        widget.initialPreferences ?? SocialPreferencesModel();
  }

  List<SocialInterestItem> get _catalog =>
      widget.interestCatalog ?? SocialPreferencesScreen.defaultSocialInterests;

  void _toggleInterest(String id) {
    if (_isLoading) return;
    setState(() {
      _preferences = _preferences.toggleInterest(id);
      _errorMessage = null;
    });
  }

  void _toggleGoal(String goal) {
    if (_isLoading) return;
    setState(() {
      _preferences = _preferences.toggleRelationshipGoal(goal);
    });
  }

  void _toggleLanguage(String lang) {
    if (_isLoading) return;
    setState(() {
      _preferences = _preferences.toggleLanguage(lang);
    });
  }

  void _updateAgeRange(RangeValues values) {
    if (_isLoading) return;
    setState(() {
      _preferences = _preferences.copyWith(
        minAge: values.start.round(),
        maxAge: values.end.round(),
      );
    });
  }

  void _updateDistance(double distance) {
    if (_isLoading) return;
    setState(() {
      _preferences = _preferences.copyWith(
        maxDistanceKm: distance.round(),
      );
    });
  }

  void _updateShowMe(String value) {
    if (_isLoading) return;
    setState(() {
      _preferences = _preferences.copyWith(showMe: value);
    });
  }

  Future<void> _handleContinue() async {
    if (!_preferences.isValid || _isLoading) return;

    if (widget.onSave != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final currentGen = ++_submitGeneration;
      try {
        final success = await widget.onSave!(_preferences);
        if (!mounted || currentGen != _submitGeneration) return;
        if (success) {
          setState(() {
            _isLoading = false;
          });
          widget.onContinue?.call(_preferences);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to save preferences. Please try again.';
          });
        }
      } catch (_) {
        if (!mounted || currentGen != _submitGeneration) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred.';
        });
      }
    } else {
      widget.onContinue?.call(_preferences);
    }
  }

  @override
  void dispose() {
    _submitGeneration++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _preferences.isValid && !_isLoading;

    return Scaffold(
      backgroundColor: AndrilSocialColors.cream,
      body: Stack(
        children: [
          const SocialWaveBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null)
                          _buildErrorBanner(_errorMessage!),
                        _buildInterestsSection(),
                        const SizedBox(height: 24.0),
                        _buildAgeSection(),
                        const SizedBox(height: 24.0),
                        _buildDistanceSection(),
                        const SizedBox(height: 24.0),
                        _buildRelationshipGoalsSection(),
                        const SizedBox(height: 24.0),
                        _buildLanguagesSection(),
                        const SizedBox(height: 24.0),
                        _buildShowMeSection(),
                        const SizedBox(height: 32.0),
                        _buildContinueButton(canSubmit),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Semantics(
            label: 'Back',
            button: true,
            child: IconButton(
              key: const Key('backButton'),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AndrilSocialColors.ink,
                size: 22.0,
              ),
              tooltip: 'Back',
              onPressed: widget.onBack,
            ),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Interests & Preferences',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                    color: AndrilSocialColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2.0),
                Text(
                  'Step 2 of 2 • Discovery Criteria',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: AndrilSocialColors.copper,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48.0),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.shade400),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    final catalog = _catalog;
    final selectedCount = _preferences.selectedInterests.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Social Interests *',
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w800,
                color: AndrilSocialColors.ink,
              ),
            ),
            Text(
              '$selectedCount selected',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: selectedCount > 0
                    ? AndrilSocialColors.royalPurple
                    : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        const Text(
          'Choose what you enjoy to find like-minded people on Social.',
          style: TextStyle(fontSize: 12.0, color: Colors.black54),
        ),
        const SizedBox(height: 12.0),
        if (catalog.isEmpty)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AndrilSocialColors.canvasCream,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AndrilSocialColors.border),
            ),
            child: const Center(
              child: Text(
                'No interests available currently.',
                style: TextStyle(fontSize: 13.0, color: Colors.black54),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: catalog.map((item) {
              final isSelected = _preferences.isInterestSelected(item.id);
              return FilterChip(
                key: Key('interestChip_${item.id}'),
                label: Text(item.label),
                selected: isSelected,
                onSelected: (_) => _toggleInterest(item.id),
                selectedColor: AndrilSocialColors.royalPurple,
                backgroundColor: AndrilSocialColors.canvasCream,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: 13.0,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AndrilSocialColors.ink,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: BorderSide(
                    color: isSelected
                        ? AndrilSocialColors.royalPurple
                        : AndrilSocialColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Preferred Age Range',
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w800,
                color: AndrilSocialColors.ink,
              ),
            ),
            Text(
              '${_preferences.minAge} – ${_preferences.maxAge} years',
              style: const TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: AndrilSocialColors.royalPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        RangeSlider(
          values: RangeValues(
            _preferences.minAge.toDouble(),
            _preferences.maxAge.toDouble(),
          ),
          min: 18.0,
          max: 99.0,
          divisions: 81,
          activeColor: AndrilSocialColors.royalPurple,
          inactiveColor: AndrilSocialColors.border,
          onChanged: _isLoading ? null : _updateAgeRange,
        ),
      ],
    );
  }

  Widget _buildDistanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Maximum Distance',
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w800,
                color: AndrilSocialColors.ink,
              ),
            ),
            Text(
              'Up to ${_preferences.maxDistanceKm} km',
              style: const TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: AndrilSocialColors.royalPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Slider(
          value: _preferences.maxDistanceKm.toDouble(),
          min: 5.0,
          max: 200.0,
          divisions: 39,
          activeColor: AndrilSocialColors.royalPurple,
          inactiveColor: AndrilSocialColors.border,
          onChanged: _isLoading ? null : _updateDistance,
        ),
      ],
    );
  }

  Widget _buildRelationshipGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Relationship Goals',
          style: TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.w800,
            color: AndrilSocialColors.ink,
          ),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: SocialPreferencesModel.defaultRelationshipGoals.map((goal) {
            final isSelected = _preferences.relationshipGoals.contains(goal);
            return FilterChip(
              key: Key('goalChip_$goal'),
              label: Text(goal),
              selected: isSelected,
              onSelected: (_) => _toggleGoal(goal),
              selectedColor: AndrilSocialColors.royalPurple,
              backgroundColor: AndrilSocialColors.canvasCream,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 13.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AndrilSocialColors.ink,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(
                  color: isSelected
                      ? AndrilSocialColors.royalPurple
                      : AndrilSocialColors.border,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferred Languages',
          style: TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.w800,
            color: AndrilSocialColors.ink,
          ),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: SocialPreferencesModel.defaultLanguages.map((lang) {
            final isSelected = _preferences.languages.contains(lang);
            return FilterChip(
              key: Key('langChip_$lang'),
              label: Text(lang),
              selected: isSelected,
              onSelected: (_) => _toggleLanguage(lang),
              selectedColor: AndrilSocialColors.royalPurple,
              backgroundColor: AndrilSocialColors.canvasCream,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 13.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AndrilSocialColors.ink,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(
                  color: isSelected
                      ? AndrilSocialColors.royalPurple
                      : AndrilSocialColors.border,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildShowMeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Show Me',
          style: TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.w800,
            color: AndrilSocialColors.ink,
          ),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          children: SocialPreferencesModel.defaultShowMeOptions.map((option) {
            final isSelected = _preferences.showMe == option;
            return ChoiceChip(
              key: Key('showMeChip_$option'),
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => _updateShowMe(option),
              selectedColor: AndrilSocialColors.royalPurple,
              backgroundColor: AndrilSocialColors.canvasCream,
              labelStyle: TextStyle(
                fontSize: 13.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AndrilSocialColors.ink,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(
                  color: isSelected
                      ? AndrilSocialColors.royalPurple
                      : AndrilSocialColors.border,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContinueButton(bool canSubmit) {
    return ElevatedButton(
      key: const Key('continueButton'),
      onPressed: canSubmit ? _handleContinue : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AndrilSocialColors.royalPurple,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AndrilSocialColors.border,
        disabledForegroundColor: Colors.black26,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20.0,
              height: 20.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: Colors.white,
              ),
            )
          : const Text(
              'Save & Continue',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
