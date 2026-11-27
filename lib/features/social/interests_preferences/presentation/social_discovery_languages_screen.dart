import 'package:flutter/material.dart';
import '../../../../app/themes/social/social_theme.dart';
import '../domain/social_preferences_model.dart';

/// Screen S81: Edit Discovery Languages.
///
/// Follows M5-FE-S81 Discovery Preferences Governance & BRD §15.2:
/// - Reuses approved language options from [SocialPreferencesModel.defaultLanguages].
/// - Displays current selections with search filtering and individual toggling.
/// - Defensively emits an unmodifiable Set<String> of selected languages upon save.
/// - Allows cancellation without applying changes.
/// - Does not invent language-based matching weights or confidential scoring algorithms.
/// - Does not fabricate server-confirmed preference persistence; clarifies local preference scope.
/// - Responsive layout supporting 320dp, 400dp, and 800dp viewports.
class SocialDiscoveryLanguagesScreen extends StatefulWidget {
  final Set<String>? initialSelectedLanguages;
  final List<String>? availableLanguages;
  final ValueChanged<Set<String>>? onSave;
  final VoidCallback? onCancel;
  final SocialPreferencesModel? preferencesContext;
  final ValueChanged<SocialPreferencesModel>? onApplyPreferences;

  const SocialDiscoveryLanguagesScreen({
    super.key,
    this.initialSelectedLanguages,
    this.availableLanguages,
    this.onSave,
    this.onCancel,
    this.preferencesContext,
    this.onApplyPreferences,
  });

  @override
  State<SocialDiscoveryLanguagesScreen> createState() =>
      _SocialDiscoveryLanguagesScreenState();
}

class _SocialDiscoveryLanguagesScreenState
    extends State<SocialDiscoveryLanguagesScreen> {
  late Set<String> _selectedLanguages;
  late TextEditingController _searchController;
  String _searchQuery = '';

  List<String> get _languages =>
      widget.availableLanguages ?? SocialPreferencesModel.defaultLanguages;

  List<String> get _filteredLanguages {
    if (_searchQuery.trim().isEmpty) return _languages;
    final query = _searchQuery.trim().toLowerCase();
    return _languages.where((lang) => lang.toLowerCase().contains(query)).toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedLanguages = Set<String>.from(
      widget.initialSelectedLanguages ??
          widget.preferencesContext?.languages ??
          const {},
    );
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleLanguage(String language) {
    setState(() {
      if (_selectedLanguages.contains(language)) {
        _selectedLanguages.remove(language);
      } else {
        _selectedLanguages.add(language);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedLanguages.clear();
    });
  }

  void _handleSave() {
    final unmodifiableSelection = Set<String>.unmodifiable(_selectedLanguages);
    widget.onSave?.call(unmodifiableSelection);

    if (widget.preferencesContext != null && widget.onApplyPreferences != null) {
      final updatedModel = widget.preferencesContext!.copyWith(
        languages: _selectedLanguages,
      );
      widget.onApplyPreferences!(updatedModel);
    }

    if (widget.onSave == null && widget.onApplyPreferences == null) {
      Navigator.of(context).maybePop(unmodifiableSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredLanguages;

    return Scaffold(
      backgroundColor: AndrilSocialColors.cream,
      appBar: AppBar(
        backgroundColor: AndrilSocialColors.cream,
        foregroundColor: AndrilSocialColors.ink,
        elevation: 0,
        leading: IconButton(
          key: const Key('cancel_languages_button'),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancel',
          onPressed: widget.onCancel ?? () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Edit Discovery Languages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AndrilSocialColors.ink,
          ),
        ),
        actions: [
          if (_selectedLanguages.isNotEmpty)
            TextButton(
              key: const Key('clear_all_languages_button'),
              onPressed: _clearAll,
              style: TextButton.styleFrom(
                foregroundColor: AndrilSocialColors.royalPurple,
              ),
              child: const Text(
                'Clear All',
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
            // Informational header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select the languages you prefer members in Discovery to speak.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Search bar
                  TextField(
                    key: const Key('language_search_field'),
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search languages...',
                      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AndrilSocialColors.cream,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AndrilSocialColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AndrilSocialColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selected (${_selectedLanguages.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AndrilSocialColors.royalPurple,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AndrilSocialColors.border),

            // Languages list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No languages found matching "$_searchQuery".',
                          style: const TextStyle(color: Color(0xFF6B7280)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 16, endIndent: 16, color: AndrilSocialColors.border),
                      itemBuilder: (context, index) {
                        final language = filtered[index];
                        final isSelected = _selectedLanguages.contains(language);

                        return CheckboxListTile(
                          key: Key('language_tile_$language'),
                          title: Text(
                            language,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: AndrilSocialColors.ink,
                            ),
                          ),
                          value: isSelected,
                          activeColor: AndrilSocialColors.royalPurple,
                          checkColor: Colors.white,
                          onChanged: (_) => _toggleLanguage(language),
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      },
                    ),
            ),

            // Bottom Sticky Save Button
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
                  key: const Key('save_languages_button'),
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AndrilSocialColors.royalPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Languages',
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
}
