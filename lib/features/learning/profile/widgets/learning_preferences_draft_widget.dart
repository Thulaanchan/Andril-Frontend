import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';

/// Standalone presentation draft widget for Learning Preferences inspired by Q07.
///
/// Follows approved visual specifications (Q07_LUC-03_Learning Preferences Setup):
/// 1. Communication Languages (English, Tamil, Tanglish)
/// 2. Learning Styles (Video Learning, Reading / Articles, Discussion, Hands-on, Audio, Mini Projects)
/// 3. Learning Availability (Morning, Afternoon, Evening, Late Night, Flexible)
/// 4. Learning Notifications (Connection requests, Classroom updates, Learning tips)
///
/// Boundaries & Governance:
/// - Purely presentational draft component managed via caller-injected callbacks.
/// - Does NOT connect to M4 notification subscriptions or register push tokens.
/// - Does NOT mutate M2 account identity or grant module activation.
/// - Does NOT write to Supabase, SharedPreferences, or local databases.
/// - Does NOT expose private account identity, tokens, or other module profiles.
/// - Standalone component pending product decision on Q07 journey integration.
class LearningPreferencesDraftWidget extends StatefulWidget {
  /// Initial selected language options.
  final List<String>? initialLanguages;

  /// Initial selected learning style options.
  final List<String>? initialLearningStyles;

  /// Initial selected availability choice.
  final String? initialAvailability;

  /// Initial notification preferences map.
  final Map<String, bool>? initialNotifications;

  /// Injected catalogue of available languages. When null, uses [defaultLanguages].
  final List<String>? availableLanguages;

  /// Injected catalogue of available learning styles. When null, uses [defaultLearningStyles].
  final List<String>? availableLearningStyles;

  /// Injected catalogue of available availability choices. When null, uses [defaultAvailabilityOptions].
  final List<String>? availableAvailabilities;

  /// Injected catalogue of available notification choices. When null, uses [defaultNotificationOptions].
  final List<String>? availableNotifications;

  /// Callback when selected languages are modified.
  final ValueChanged<List<String>>? onLanguagesChanged;

  /// Callback when selected learning styles are modified.
  final ValueChanged<List<String>>? onLearningStylesChanged;

  /// Callback when availability choice is modified.
  final ValueChanged<String?>? onAvailabilityChanged;

  /// Callback when notification preferences are modified.
  final ValueChanged<Map<String, bool>>? onNotificationsChanged;

  /// Optional completion callback.
  final VoidCallback? onComplete;

  /// Optional back callback.
  final VoidCallback? onBack;

  /// Creates a [LearningPreferencesDraftWidget].
  const LearningPreferencesDraftWidget({
    super.key,
    this.initialLanguages,
    this.initialLearningStyles,
    this.initialAvailability,
    this.initialNotifications,
    this.availableLanguages,
    this.availableLearningStyles,
    this.availableAvailabilities,
    this.availableNotifications,
    this.onLanguagesChanged,
    this.onLearningStylesChanged,
    this.onAvailabilityChanged,
    this.onNotificationsChanged,
    this.onComplete,
    this.onBack,
  });

  /// Default suggested languages from Q07 design reference.
  static const List<String> defaultLanguages = [
    'English',
    'Tamil',
    'Tanglish',
  ];

  /// Default suggested learning styles from Q07 design reference.
  static const List<String> defaultLearningStyles = [
    'Video Learning',
    'Reading / Articles',
    'Discussion & Collaboration',
    'Hands-on Practice',
    'Audio / Podcasts',
    'Mini Projects',
  ];

  /// Default suggested availability periods from Q07 design reference.
  static const List<String> defaultAvailabilityOptions = [
    'Morning (6 AM – 12 PM)',
    'Afternoon (12 PM – 6 PM)',
    'Evening (6 PM – 10 PM)',
    'Late Night (10 PM – 2 AM)',
    'Flexible (Any time)',
  ];

  /// Default suggested notification preferences from Q07 design reference.
  static const List<String> defaultNotificationOptions = [
    'Connection requests',
    'Classroom & circle updates',
    'Learning tips & reminders',
  ];

  @override
  State<LearningPreferencesDraftWidget> createState() =>
      _LearningPreferencesDraftWidgetState();
}

class _LearningPreferencesDraftWidgetState
    extends State<LearningPreferencesDraftWidget> {
  late final Set<String> _selectedLanguages;
  late final Set<String> _selectedLearningStyles;
  String? _selectedAvailability;
  late final Map<String, bool> _notificationPreferences;

  @override
  void initState() {
    super.initState();
    _selectedLanguages = Set<String>.from(widget.initialLanguages ?? []);
    _selectedLearningStyles =
        Set<String>.from(widget.initialLearningStyles ?? []);
    _selectedAvailability = widget.initialAvailability;
    _notificationPreferences = Map<String, bool>.from(
      widget.initialNotifications ??
          {
            for (final opt in (widget.availableNotifications ??
                LearningPreferencesDraftWidget.defaultNotificationOptions))
              opt: false,
          },
    );
  }

  void _toggleLanguage(String lang) {
    setState(() {
      if (_selectedLanguages.contains(lang)) {
        _selectedLanguages.remove(lang);
      } else {
        _selectedLanguages.add(lang);
      }
    });
    widget.onLanguagesChanged?.call(_selectedLanguages.toList());
  }

  void _toggleLearningStyle(String style) {
    setState(() {
      if (_selectedLearningStyles.contains(style)) {
        _selectedLearningStyles.remove(style);
      } else {
        _selectedLearningStyles.add(style);
      }
    });
    widget.onLearningStylesChanged?.call(_selectedLearningStyles.toList());
  }

  void _selectAvailability(String option) {
    setState(() {
      if (_selectedAvailability == option) {
        _selectedAvailability = null;
      } else {
        _selectedAvailability = option;
      }
    });
    widget.onAvailabilityChanged?.call(_selectedAvailability);
  }

  void _toggleNotification(String option, bool value) {
    setState(() {
      _notificationPreferences[option] = value;
    });
    widget.onNotificationsChanged
        ?.call(Map.unmodifiable(_notificationPreferences));
  }

  IconData _iconForLearningStyle(String style) {
    switch (style.toLowerCase()) {
      case 'video learning':
        return Icons.play_circle_outline_rounded;
      case 'reading / articles':
        return Icons.article_outlined;
      case 'discussion & collaboration':
        return Icons.people_outline_rounded;
      case 'hands-on practice':
        return Icons.science_outlined;
      case 'audio / podcasts':
        return Icons.headphones_outlined;
      case 'mini projects':
        return Icons.grid_view_rounded;
      default:
        return Icons.school_outlined;
    }
  }

  IconData _iconForAvailability(String option) {
    final lower = option.toLowerCase();
    if (lower.contains('morning')) return Icons.wb_sunny_outlined;
    if (lower.contains('afternoon')) return Icons.wb_twilight_rounded;
    if (lower.contains('evening')) return Icons.nightlight_outlined;
    if (lower.contains('late night')) return Icons.bedtime_outlined;
    return Icons.calendar_today_outlined;
  }

  IconData _iconForNotification(String option) {
    final lower = option.toLowerCase();
    if (lower.contains('connection')) return Icons.person_add_alt_1_outlined;
    if (lower.contains('classroom')) return Icons.groups_outlined;
    return Icons.star_border_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final languages = widget.availableLanguages ??
        LearningPreferencesDraftWidget.defaultLanguages;
    final learningStyles = widget.availableLearningStyles ??
        LearningPreferencesDraftWidget.defaultLearningStyles;
    final availabilities = widget.availableAvailabilities ??
        LearningPreferencesDraftWidget.defaultAvailabilityOptions;
    final notifications = widget.availableNotifications ??
        LearningPreferencesDraftWidget.defaultNotificationOptions;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Draft notice disclaimer
          _buildDisclaimer(),
          const SizedBox(height: 24),

          // Section 1: Communication Language
          _buildLanguageSection(languages),
          const SizedBox(height: 28),

          // Section 2: Learning Style
          _buildLearningStyleSection(learningStyles),
          const SizedBox(height: 28),

          // Section 3: Learning Availability
          _buildAvailabilitySection(availabilities),
          const SizedBox(height: 28),

          // Section 4: Learning Notifications
          _buildNotificationsSection(notifications),
          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: LearningColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: LearningColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Your Learning Preferences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Help us personalise your learning experience and connections.',
                style: TextStyle(
                  fontSize: 13,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      key: const Key('preferences_draft_disclaimer'),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: LearningColors.primary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Draft Preferences: These options are temporary local drafts and do not modify M4 notification subscriptions, M2 account settings, or grant module activation.',
              style: TextStyle(
                fontSize: 12,
                color: LearningColors.secondaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(List<String> languages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.translate_rounded,
              size: 20,
              color: LearningColors.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Communication Language',
                key: Key('preferences_language_section_title'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Learning',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Select the language(s) you are comfortable using for learning and collaboration.',
          style: TextStyle(
            fontSize: 12,
            color: LearningColors.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        if (languages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No language options available.',
              style:
                  TextStyle(fontSize: 12, color: LearningColors.secondaryText),
            ),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: languages.map((lang) {
              final isSelected = _selectedLanguages.contains(lang);
              return Semantics(
                label:
                    'Language option: $lang, ${isSelected ? "selected" : "not selected"}',
                selected: isSelected,
                button: true,
                child: FilterChip(
                  key: Key('language_chip_$lang'),
                  selected: isSelected,
                  label: Text(
                    lang,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? LearningColors.primary
                          : LearningColors.heading,
                    ),
                  ),
                  avatar: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: LearningColors.primary,
                        )
                      : null,
                  backgroundColor: LearningColors.cardSurface,
                  selectedColor: LearningColors.primary.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: isSelected
                        ? LearningColors.primary
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) => _toggleLanguage(lang),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 10),
        // Information note box
        Container(
          key: const Key('language_info_box'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.language_rounded,
                size: 16,
                color: LearningColors.secondaryText,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This will be used for learning connections, discussions and classroom interactions.',
                  style: TextStyle(
                    fontSize: 11,
                    color: LearningColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLearningStyleSection(List<String> styles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 20,
              color: LearningColors.primary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Learning Style (Optional)',
                key: Key('preferences_style_section_title'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose the ways you prefer to learn.',
          style: TextStyle(
            fontSize: 12,
            color: LearningColors.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        if (styles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No learning styles available.',
              style:
                  TextStyle(fontSize: 12, color: LearningColors.secondaryText),
            ),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: styles.map((style) {
              final isSelected = _selectedLearningStyles.contains(style);
              return Semantics(
                label:
                    'Learning style: $style, ${isSelected ? "selected" : "not selected"}',
                selected: isSelected,
                button: true,
                child: FilterChip(
                  key: Key('learning_style_card_$style'),
                  selected: isSelected,
                  avatar: Icon(
                    _iconForLearningStyle(style),
                    size: 16,
                    color: isSelected
                        ? LearningColors.primary
                        : LearningColors.secondaryText,
                  ),
                  label: Text(
                    style,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? LearningColors.primary
                          : LearningColors.heading,
                    ),
                  ),
                  backgroundColor: LearningColors.cardSurface,
                  selectedColor: LearningColors.primary.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: isSelected
                        ? LearningColors.primary
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onSelected: (_) => _toggleLearningStyle(style),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAvailabilitySection(List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 20,
              color: LearningColors.primary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Learning Availability (Optional)',
                key: Key('preferences_availability_section_title'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Let others know when you are usually available to learn together.',
          style: TextStyle(
            fontSize: 12,
            color: LearningColors.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        if (options.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No availability options available.',
              style:
                  TextStyle(fontSize: 12, color: LearningColors.secondaryText),
            ),
          )
        else
          Column(
            children: options.map((opt) {
              final isSelected = _selectedAvailability == opt;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Semantics(
                  label:
                      'Availability option: $opt, ${isSelected ? "selected" : "not selected"}',
                  selected: isSelected,
                  button: true,
                  child: InkWell(
                    key: Key('availability_card_$opt'),
                    onTap: () => _selectAvailability(opt),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? LearningColors.primary.withValues(alpha: 0.08)
                            : LearningColors.cardSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? LearningColors.primary
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _iconForAvailability(opt),
                            size: 18,
                            color: isSelected
                                ? LearningColors.primary
                                : LearningColors.secondaryText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? LearningColors.primary
                                    : LearningColors.heading,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: LearningColors.primary,
                            )
                          else
                            const Icon(
                              Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: Color(0xFFCBD5E1),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildNotificationsSection(List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: LearningColors.primary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Learning Notifications (Optional)',
                key: Key('preferences_notifications_section_title'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose what draft updates you would like to receive. (Does not update live push notification channels).',
          style: TextStyle(
            fontSize: 12,
            color: LearningColors.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        if (options.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No notification options available.',
              style:
                  TextStyle(fontSize: 12, color: LearningColors.secondaryText),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: LearningColors.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: options.asMap().entries.map((entry) {
                final idx = entry.key;
                final opt = entry.value;
                final isEnabled = _notificationPreferences[opt] ?? false;
                return Column(
                  children: [
                    if (idx > 0)
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            _iconForNotification(opt),
                            size: 18,
                            color: LearningColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              opt,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: LearningColors.heading,
                              ),
                            ),
                          ),
                          Semantics(
                            label:
                                'Notification: $opt, ${isEnabled ? "enabled" : "disabled"}',
                            child: Switch.adaptive(
                              key: Key('notification_switch_$opt'),
                              value: isEnabled,
                              activeTrackColor: LearningColors.primary,
                              onChanged: (val) => _toggleNotification(opt, val),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 10),
        Container(
          key: const Key('notification_info_box'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 16,
                color: LearningColors.secondaryText,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You can change these preferences anytime in Learning Settings.',
                  style: TextStyle(
                    fontSize: 11,
                    color: LearningColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.onComplete != null)
          ElevatedButton(
            key: const Key('preferences_complete_button'),
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: LearningColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Complete Learning Setup',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        if (widget.onBack != null) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            key: const Key('preferences_back_button'),
            onPressed: widget.onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: LearningColors.secondaryText,
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Back',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
