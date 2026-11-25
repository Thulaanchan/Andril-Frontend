import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';
import '../domain/entities/learning_preferences.dart';
import '../domain/entities/learning_profile.dart';

/// Complete presentation screen for Learning Profile & Preferences (CF-01 / CF-02, BRD v2.4-R1, p. 7).
///
/// Features:
/// 1. Learning Profile Owner View:
///    - Header card with avatar, display name, bio, module badge 'Learning'.
///    - Skills to Learn and Skills to Share chips.
///    - Learning Goals list.
///    - Approved Learning Preferences summary (communication languages, styles, availability, notifications).
/// 2. Authorized Profile Edit Mode:
///    - Edit display name with non-empty validation.
///    - Edit bio with character limit.
///    - Add / remove skills to learn and skills to share with suggestions.
///    - Add / remove learning goals with suggestions.
///    - Multi-select communication languages (Q07 approved: English, Tamil, Tanglish).
///    - Multi-select learning styles (Q07 approved).
///    - Single-select learning availability (Q07 approved).
///    - Toggle notification preferences (Q07 approved).
///    - Save and Cancel actions with discard confirmation dialog for unsaved changes.
/// 3. Comprehensive State Coverage:
///    - Loading state (`isLoading: true`).
///    - Empty state (no skills or goals added yet).
///    - Unavailable state (`isUnavailable: true`).
///    - Access-denied state (`isAccessDenied: true` or `currentUserId != profileId` or `module != 'learning'`).
///    - Error state with retry callback.
///    - Disconnected remote persistence notice (clear notice that remote persistence is pending).
/// 4. Security & Privacy:
///    - Fail-closed access control on profile ownership and module scope.
///    - Account ID never rendered or exposed.
///    - Private state cleared on identity switch (`currentUserId` change).
/// 5. Responsive down to 320dp and 1.5x dynamic text scaling without overflow.
class LearningProfileScreen extends StatefulWidget {
  /// Initial profile to display or edit. If null, a synthetic sample is loaded.
  final LearningProfile? initialProfile;

  /// Whether the screen opens initially in edit mode.
  final bool isEditMode;

  /// Current authenticated user's learning profile ID used for owner access verification.
  final String currentUserId;

  /// Whether the screen is in a loading state.
  final bool isLoading;

  /// Whether access to this profile is explicitly denied.
  final bool isAccessDenied;

  /// Whether upstream M2 authentication or profile services are unavailable.
  final bool isUnavailable;

  /// Optional error message to display in an error state.
  final String? errorMessage;

  /// Optional retry callback for error and unavailable states.
  final VoidCallback? onRetry;

  /// Optional callback invoked when the user saves profile modifications.
  final ValueChanged<LearningProfile>? onSaveProfile;

  /// Optional callback invoked when the user navigates back.
  final VoidCallback? onBack;

  /// Optional custom app bar. Defaults to [AndrilModuleAppBar] with Learning branding.
  final PreferredSizeWidget? appBar;

  const LearningProfileScreen({
    super.key,
    this.initialProfile,
    this.isEditMode = false,
    this.currentUserId = 'lp_current_user',
    this.isLoading = false,
    this.isAccessDenied = false,
    this.isUnavailable = false,
    this.errorMessage,
    this.onRetry,
    this.onSaveProfile,
    this.onBack,
    this.appBar,
  });

  @override
  State<LearningProfileScreen> createState() => _LearningProfileScreenState();
}

class _LearningProfileScreenState extends State<LearningProfileScreen> {
  static const Color _errorColor = Color(0xFFDC2626);

  final _formKey = GlobalKey<FormState>();

  late bool _isEditing;
  late LearningProfile _profile;

  // Edit form state
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  final TextEditingController _customSkillToLearnController =
      TextEditingController();
  final TextEditingController _customSkillToShareController =
      TextEditingController();
  final TextEditingController _customGoalController = TextEditingController();

  late List<String> _skillsToLearn;
  late List<String> _skillsToShare;
  late List<String> _learningGoals;

  late Set<String> _selectedLanguages;
  late Set<String> _selectedLearningStyles;
  String? _selectedAvailability;
  late Map<String, bool> _notificationPreferences;

  String? _statusBannerMessage;
  String? _errorBannerMessage;

  // Suggested catalogue chips for quick addition
  static const List<String> _suggestedSkillsToLearn = [
    'Flutter',
    'Clean Architecture',
    'Dart Concurrency',
    'State Management',
    'GraphQL',
    'DevOps',
  ];

  static const List<String> _suggestedSkillsToShare = [
    'UI Design',
    'Figma',
    'Mobile Prototyping',
    'Mentorship',
    'Python',
    'Web Accessibility',
  ];

  static const List<String> _suggestedGoals = [
    'Build practical portfolio projects',
    'Collaborate with study partners',
    'Master mobile architecture',
    'Prepare for technical interviews',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isEditMode;
    _initProfileState();
  }

  void _initProfileState() {
    _profile = widget.initialProfile ??
        LearningProfile.syntheticSample(
          ownerLearningProfileId: widget.currentUserId,
        );

    _displayNameController = TextEditingController(text: _profile.displayName);
    _bioController = TextEditingController(text: _profile.bio ?? '');

    _skillsToLearn = List<String>.from(_profile.skillsToLearn);
    _skillsToShare = List<String>.from(_profile.skillsToShare);
    _learningGoals = List<String>.from(_profile.learningGoals);

    _selectedLanguages = Set<String>.from(_profile.preferences.languages);
    _selectedLearningStyles =
        Set<String>.from(_profile.preferences.learningStyles);
    _selectedAvailability = _profile.preferences.availability;
    _notificationPreferences =
        Map<String, bool>.from(_profile.preferences.notifications);
  }

  @override
  void didUpdateWidget(covariant LearningProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Security invariant: if authenticated caller changes, immediately purge private state
    if (oldWidget.currentUserId != widget.currentUserId) {
      _displayNameController.dispose();
      _bioController.dispose();
      _customSkillToLearnController.clear();
      _customSkillToShareController.clear();
      _customGoalController.clear();

      _isEditing = false;
      _statusBannerMessage = null;
      _errorBannerMessage = null;
      _initProfileState();
    } else if (oldWidget.initialProfile != widget.initialProfile &&
        widget.initialProfile != null) {
      if (!_isEditing) {
        _profile = widget.initialProfile!;
        _displayNameController.text = _profile.displayName;
        _bioController.text = _profile.bio ?? '';
        _skillsToLearn = List<String>.from(_profile.skillsToLearn);
        _skillsToShare = List<String>.from(_profile.skillsToShare);
        _learningGoals = List<String>.from(_profile.learningGoals);
        _selectedLanguages = Set<String>.from(_profile.preferences.languages);
        _selectedLearningStyles =
            Set<String>.from(_profile.preferences.learningStyles);
        _selectedAvailability = _profile.preferences.availability;
        _notificationPreferences =
            Map<String, bool>.from(_profile.preferences.notifications);
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _customSkillToLearnController.dispose();
    _customSkillToShareController.dispose();
    _customGoalController.dispose();
    super.dispose();
  }

  /// Whether any edits have been made in the form compared to the current [_profile].
  bool get _hasUnsavedChanges {
    if (_displayNameController.text.trim() != _profile.displayName) return true;
    if (_bioController.text.trim() != (_profile.bio ?? '')) return true;
    if (_skillsToLearn.length != _profile.skillsToLearn.length) return true;
    for (int i = 0; i < _skillsToLearn.length; i++) {
      if (_skillsToLearn[i] != _profile.skillsToLearn[i]) return true;
    }
    if (_skillsToShare.length != _profile.skillsToShare.length) return true;
    for (int i = 0; i < _skillsToShare.length; i++) {
      if (_skillsToShare[i] != _profile.skillsToShare[i]) return true;
    }
    if (_learningGoals.length != _profile.learningGoals.length) return true;
    for (int i = 0; i < _learningGoals.length; i++) {
      if (_learningGoals[i] != _profile.learningGoals[i]) return true;
    }
    if (_selectedLanguages.length != _profile.preferences.languages.length) {
      return true;
    }
    if (_selectedLearningStyles.length !=
        _profile.preferences.learningStyles.length) {
      return true;
    }
    if (_selectedAvailability != _profile.preferences.availability) return true;
    return false;
  }

  /// Builds a [LearningProfile] from the current editor form.
  LearningProfile _buildEditedProfile() {
    return _profile.copyWith(
      displayName: _displayNameController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      skillsToLearn: List.unmodifiable(_skillsToLearn),
      skillsToShare: List.unmodifiable(_skillsToShare),
      learningGoals: List.unmodifiable(_learningGoals),
      preferences: _profile.preferences.copyWith(
        languages: _selectedLanguages.toList(),
        learningStyles: _selectedLearningStyles.toList(),
        availability: _selectedAvailability,
        notifications: _notificationPreferences,
      ),
    );
  }

  void _handleSave() {
    if (_displayNameController.text.trim().isEmpty) {
      setState(() {
        _errorBannerMessage = 'Display name cannot be empty.';
        _statusBannerMessage = null;
      });
      return;
    }

    final updated = _buildEditedProfile();
    setState(() {
      _profile = updated;
      _isEditing = false;
      _errorBannerMessage = null;
      _statusBannerMessage = widget.onSaveProfile != null
          ? 'Profile updated successfully.'
          : 'Draft saved locally. Remote repository persistence contract pending.';
    });

    widget.onSaveProfile?.call(updated);
  }

  Future<void> _handleCancel() async {
    if (_hasUnsavedChanges) {
      final bool? discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('dialog_discard_changes'),
          title: const Text('Discard Unsaved Changes?'),
          content: const Text(
            'You have unsaved changes in your profile. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              key: const Key('btn_keep_editing'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              key: const Key('btn_confirm_discard'),
              style: FilledButton.styleFrom(
                backgroundColor: _errorColor,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );

      if (discard != true) return;
    }

    // Reset editor inputs to current profile
    setState(() {
      _displayNameController.text = _profile.displayName;
      _bioController.text = _profile.bio ?? '';
      _skillsToLearn = List<String>.from(_profile.skillsToLearn);
      _skillsToShare = List<String>.from(_profile.skillsToShare);
      _learningGoals = List<String>.from(_profile.learningGoals);
      _selectedLanguages = Set<String>.from(_profile.preferences.languages);
      _selectedLearningStyles =
          Set<String>.from(_profile.preferences.learningStyles);
      _selectedAvailability = _profile.preferences.availability;
      _notificationPreferences =
          Map<String, bool>.from(_profile.preferences.notifications);
      _errorBannerMessage = null;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Access Denied State (Fail-closed invariant)
    if (widget.isAccessDenied ||
        _profile.profileId != widget.currentUserId ||
        _profile.module != LearningProfile.moduleScope) {
      return Scaffold(
        backgroundColor: LearningColors.background,
        appBar: _buildDefaultAppBar(),
        body: _buildAccessDeniedState(),
      );
    }

    // 2. Loading State
    if (widget.isLoading) {
      return Scaffold(
        backgroundColor: LearningColors.background,
        appBar: _buildDefaultAppBar(),
        body: _buildLoadingState(),
      );
    }

    // 3. Unavailable State
    if (widget.isUnavailable) {
      return Scaffold(
        backgroundColor: LearningColors.background,
        appBar: _buildDefaultAppBar(),
        body: _buildUnavailableState(),
      );
    }

    // 4. Error State
    if (widget.errorMessage != null) {
      return Scaffold(
        backgroundColor: LearningColors.background,
        appBar: _buildDefaultAppBar(),
        body: _buildErrorState(widget.errorMessage!),
      );
    }

    // 5. Authorized Active State (View Mode or Edit Mode)
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: _buildDefaultAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banners
              if (_statusBannerMessage != null) ...[
                _buildStatusBanner(),
                const SizedBox(height: 12),
              ],
              if (_errorBannerMessage != null) ...[
                _buildErrorBanner(),
                const SizedBox(height: 12),
              ],

              // Disconnected persistence notice
              _buildPersistenceNotice(),
              const SizedBox(height: 16),

              // Content based on mode
              if (_isEditing) _buildEditModeForm() else _buildViewModeContent(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildDefaultAppBar() {
    if (widget.appBar != null) return widget.appBar!;

    return AppBar(
      backgroundColor: LearningColors.background,
      elevation: 0,
      title: Text(
        _isEditing ? 'Edit Learning Profile' : 'Learning Profile',
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: LearningColors.heading,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        key: const Key('learning_profile_back_button'),
        icon:
            const Icon(Icons.arrow_back_rounded, color: LearningColors.heading),
        onPressed: _isEditing ? _handleCancel : widget.onBack,
      ),
      actions: [
        if (!_isEditing) ...[
          IconButton(
            key: const Key('learning_profile_edit_action'),
            icon:
                const Icon(Icons.edit_outlined, color: LearningColors.heading),
            tooltip: 'Edit Profile',
            onPressed: () {
              setState(() {
                _isEditing = true;
                _statusBannerMessage = null;
                _errorBannerMessage = null;
              });
            },
          ),
        ] else ...[
          IconButton(
            key: const Key('learning_profile_save_action'),
            icon:
                const Icon(Icons.check_rounded, color: LearningColors.primary),
            tooltip: 'Save Profile',
            onPressed: _handleSave,
          ),
        ],
      ],
    );
  }

  // ==========================================
  // VIEW MODE
  // ==========================================

  Widget _buildViewModeContent() {
    final bool isEmpty = _skillsToLearn.isEmpty &&
        _skillsToShare.isEmpty &&
        _learningGoals.isEmpty;

    return Column(
      key: const Key('learning_profile_view_mode'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Profile Card
        _buildProfileHeaderCard(),
        const SizedBox(height: 16),

        // Empty state banner if no skills or goals
        if (isEmpty) ...[
          _buildEmptyStateCard(),
          const SizedBox(height: 16),
        ],

        // Skills to Learn Section
        _buildSkillsToLearnView(),
        const SizedBox(height: 16),

        // Skills to Share Section
        _buildSkillsToShareView(),
        const SizedBox(height: 16),

        // Learning Goals Section
        _buildGoalsView(),
        const SizedBox(height: 16),

        // Preferences Summary Section
        _buildPreferencesSummaryView(),
        const SizedBox(height: 24),

        // Edit Button CTA
        FilledButton.icon(
          key: const Key('btn_edit_profile_cta'),
          style: FilledButton.styleFrom(
            backgroundColor: LearningColors.primary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.edit_outlined, size: 20),
          label: const Text(
            'Edit Profile & Preferences',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            setState(() {
              _isEditing = true;
              _statusBannerMessage = null;
              _errorBannerMessage = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeaderCard() {
    final displayName = _profile.displayName;
    final initials = displayName.trim().isNotEmpty
        ? displayName
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'L';

    return Container(
      key: const Key('learning_profile_header'),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  key: const Key('learning_profile_avatar'),
                  radius: 32,
                  backgroundColor:
                      LearningColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: LearningColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name and module badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        key: const Key('learning_profile_display_name'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: LearningColors.heading,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            key: const Key('learning_profile_module_badge'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  LearningColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Learning',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: LearningColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            'ID: ${_profile.profileId}',
                            key: const Key('learning_profile_id_indicator'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: LearningColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_profile.bio != null && _profile.bio!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Text(
                _profile.bio!,
                key: const Key('learning_profile_bio'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF334155),
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      key: const Key('learning_profile_empty_state'),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: LearningColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No skills or goals added yet. Tap "Edit Profile & Preferences" to personalise your profile.',
              style: TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsToLearnView() {
    return _buildSectionContainer(
      key: const Key('learning_profile_skills_to_learn_section'),
      title: 'Skills to Learn',
      icon: Icons.school_outlined,
      children: [
        if (_skillsToLearn.isEmpty)
          const Text(
            'No skills to learn specified.',
            key: Key('empty_skills_to_learn_text'),
            style: TextStyle(fontSize: 13, color: LearningColors.secondaryText),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skillsToLearn.map((skill) {
              return Chip(
                key: Key('skill_to_learn_$skill'),
                label: Text(
                  skill,
                  style: const TextStyle(
                    fontSize: 13,
                    color: LearningColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: LearningColors.primary.withValues(alpha: 0.08),
                side: BorderSide(
                  color: LearningColors.primary.withValues(alpha: 0.25),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSkillsToShareView() {
    return _buildSectionContainer(
      key: const Key('learning_profile_skills_to_share_section'),
      title: 'Skills to Share',
      icon: Icons.share_outlined,
      children: [
        if (_skillsToShare.isEmpty)
          const Text(
            'No skills to share specified.',
            key: Key('empty_skills_to_share_text'),
            style: TextStyle(fontSize: 13, color: LearningColors.secondaryText),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skillsToShare.map((skill) {
              return Chip(
                key: Key('skill_to_share_$skill'),
                label: Text(
                  skill,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0D9488),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: const Color(0xFFCCFBF1),
                side: const BorderSide(color: Color(0xFF99F6E4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildGoalsView() {
    return _buildSectionContainer(
      key: const Key('learning_profile_goals_section'),
      title: 'Learning Goals',
      icon: Icons.flag_outlined,
      children: [
        if (_learningGoals.isEmpty)
          const Text(
            'No learning goals added.',
            key: Key('empty_goals_text'),
            style: TextStyle(fontSize: 13, color: LearningColors.secondaryText),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _learningGoals.asMap().entries.map((entry) {
              final idx = entry.key;
              final goal = entry.value;
              return Container(
                key: Key('learning_goal_item_$idx'),
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: LearningColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        goal,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: LearningColors.heading,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildPreferencesSummaryView() {
    final prefs = _profile.preferences;
    return _buildSectionContainer(
      key: const Key('learning_profile_preferences_section'),
      title: 'Learning Preferences',
      icon: Icons.tune_rounded,
      children: [
        // Languages
        const Text(
          'Communication Languages',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: LearningColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        if (prefs.languages.isEmpty)
          const Text(
            'None selected',
            style: TextStyle(fontSize: 13, color: LearningColors.secondaryText),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: prefs.languages.map((l) {
              return Container(
                key: Key('pref_lang_$l'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 14),

        // Learning Styles
        const Text(
          'Learning Styles',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: LearningColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        if (prefs.learningStyles.isEmpty)
          const Text(
            'None selected',
            style: TextStyle(fontSize: 13, color: LearningColors.secondaryText),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: prefs.learningStyles.map((s) {
              return Container(
                key: Key('pref_style_$s'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: LearningColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 14),

        // Availability
        const Text(
          'Availability',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: LearningColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.schedule_rounded,
                size: 16, color: LearningColors.secondaryText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                prefs.availability ?? 'Flexible (Any time)',
                key: const Key('pref_availability'),
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Notifications
        const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: LearningColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          key: const Key('pref_notifications'),
          spacing: 6,
          runSpacing: 6,
          children: prefs.notifications.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: entry.value
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${entry.key}: ${entry.value ? "On" : "Off"}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: entry.value
                      ? const Color(0xFF15803D)
                      : const Color(0xFF64748B),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==========================================
  // EDIT MODE
  // ==========================================

  Widget _buildEditModeForm() {
    return Form(
      key: _formKey,
      child: Column(
        key: const Key('learning_profile_edit_mode'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section: Basics
          _buildEditBasicsSection(),
          const SizedBox(height: 20),

          // Section: Skills to Learn
          _buildEditSkillsToLearnSection(),
          const SizedBox(height: 20),

          // Section: Skills to Share
          _buildEditSkillsToShareSection(),
          const SizedBox(height: 20),

          // Section: Goals
          _buildEditGoalsSection(),
          const SizedBox(height: 20),

          // Section: Preferences
          _buildEditPreferencesSection(),
          const SizedBox(height: 24),

          // Action Buttons: Save & Cancel
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('btn_cancel_edit'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('btn_save_profile'),
                  style: FilledButton.styleFrom(
                    backgroundColor: LearningColors.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleSave,
                  child: const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditBasicsSection() {
    return _buildSectionContainer(
      title: 'Profile Information',
      icon: Icons.person_outline_rounded,
      children: [
        // Display Name
        const Text(
          'Display Name *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LearningColors.heading,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: const Key('edit_display_name_input'),
          controller: _displayNameController,
          maxLength: 50,
          decoration: InputDecoration(
            hintText: 'Enter your display name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Display name cannot be empty';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Bio
        const Text(
          'Bio / Mission',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LearningColors.heading,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: const Key('edit_bio_input'),
          controller: _bioController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText:
                'Brief summary of what you are learning and passionate about',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildEditSkillsToLearnSection() {
    return _buildSectionContainer(
      key: const Key('edit_skills_to_learn_section'),
      title: 'Skills to Learn',
      icon: Icons.school_outlined,
      children: [
        // Custom add row
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('input_skill_to_learn'),
                controller: _customSkillToLearnController,
                decoration: InputDecoration(
                  hintText: 'Add a skill to learn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addSkillToLearn(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('btn_add_skill_to_learn'),
              style: IconButton.styleFrom(
                backgroundColor: LearningColors.primary,
                minimumSize: const Size(44, 44),
              ),
              icon: const Icon(Icons.add_rounded),
              onPressed: _addSkillToLearn,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Suggestions
        const Text(
          'Suggestions:',
          style: TextStyle(fontSize: 12, color: LearningColors.secondaryText),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _suggestedSkillsToLearn.map((s) {
            final isSelected = _skillsToLearn.contains(s);
            return ActionChip(
              key: Key('suggest_learn_$s'),
              label: Text(
                '+ $s',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? LearningColors.secondaryText
                      : LearningColors.primary,
                ),
              ),
              backgroundColor: isSelected
                  ? const Color(0xFFF1F5F9)
                  : LearningColors.primary.withValues(alpha: 0.08),
              onPressed: isSelected
                  ? null
                  : () {
                      setState(() {
                        _skillsToLearn.add(s);
                      });
                    },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Selected chips
        if (_skillsToLearn.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skillsToLearn.map((skill) {
              return Chip(
                key: Key('edit_skill_to_learn_$skill'),
                label: Text(skill),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () {
                  setState(() {
                    _skillsToLearn.remove(skill);
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  void _addSkillToLearn() {
    final text = _customSkillToLearnController.text.trim();
    if (text.isNotEmpty && !_skillsToLearn.contains(text)) {
      setState(() {
        _skillsToLearn.add(text);
        _customSkillToLearnController.clear();
      });
    }
  }

  Widget _buildEditSkillsToShareSection() {
    return _buildSectionContainer(
      key: const Key('edit_skills_to_share_section'),
      title: 'Skills to Share',
      icon: Icons.share_outlined,
      children: [
        // Custom add row
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('input_skill_to_share'),
                controller: _customSkillToShareController,
                decoration: InputDecoration(
                  hintText: 'Add a skill to share / teach...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addSkillToShare(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('btn_add_skill_to_share'),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                minimumSize: const Size(44, 44),
              ),
              icon: const Icon(Icons.add_rounded),
              onPressed: _addSkillToShare,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Suggestions
        const Text(
          'Suggestions:',
          style: TextStyle(fontSize: 12, color: LearningColors.secondaryText),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _suggestedSkillsToShare.map((s) {
            final isSelected = _skillsToShare.contains(s);
            return ActionChip(
              key: Key('suggest_share_$s'),
              label: Text(
                '+ $s',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? LearningColors.secondaryText
                      : const Color(0xFF0D9488),
                ),
              ),
              backgroundColor: isSelected
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFFCCFBF1),
              onPressed: isSelected
                  ? null
                  : () {
                      setState(() {
                        _skillsToShare.add(s);
                      });
                    },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Selected chips
        if (_skillsToShare.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skillsToShare.map((skill) {
              return Chip(
                key: Key('edit_skill_to_share_$skill'),
                label: Text(skill),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () {
                  setState(() {
                    _skillsToShare.remove(skill);
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  void _addSkillToShare() {
    final text = _customSkillToShareController.text.trim();
    if (text.isNotEmpty && !_skillsToShare.contains(text)) {
      setState(() {
        _skillsToShare.add(text);
        _customSkillToShareController.clear();
      });
    }
  }

  Widget _buildEditGoalsSection() {
    return _buildSectionContainer(
      key: const Key('edit_goals_section'),
      title: 'Learning Goals',
      icon: Icons.flag_outlined,
      children: [
        // Custom add row
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('input_goal'),
                controller: _customGoalController,
                decoration: InputDecoration(
                  hintText: 'Add a learning goal...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addGoal(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('btn_add_goal'),
              style: IconButton.styleFrom(
                backgroundColor: LearningColors.primary,
                minimumSize: const Size(44, 44),
              ),
              icon: const Icon(Icons.add_rounded),
              onPressed: _addGoal,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Suggestions
        const Text(
          'Suggestions:',
          style: TextStyle(fontSize: 12, color: LearningColors.secondaryText),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _suggestedGoals.map((g) {
            final isSelected = _learningGoals.contains(g);
            return ActionChip(
              key: Key('suggest_goal_$g'),
              label: Text(
                '+ $g',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? LearningColors.secondaryText
                      : LearningColors.primary,
                ),
              ),
              backgroundColor: isSelected
                  ? const Color(0xFFF1F5F9)
                  : LearningColors.primary.withValues(alpha: 0.08),
              onPressed: isSelected
                  ? null
                  : () {
                      setState(() {
                        _learningGoals.add(g);
                      });
                    },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Current goals list
        if (_learningGoals.isNotEmpty)
          Column(
            children: _learningGoals.asMap().entries.map((entry) {
              final idx = entry.key;
              final goal = entry.value;
              return Container(
                key: Key('edit_goal_item_$idx'),
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        size: 16, color: LearningColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    IconButton(
                      key: Key('delete_goal_$idx'),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: _errorColor,
                      onPressed: () {
                        setState(() {
                          _learningGoals.removeAt(idx);
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _addGoal() {
    final text = _customGoalController.text.trim();
    if (text.isNotEmpty && !_learningGoals.contains(text)) {
      setState(() {
        _learningGoals.add(text);
        _customGoalController.clear();
      });
    }
  }

  Widget _buildEditPreferencesSection() {
    return _buildSectionContainer(
      key: const Key('edit_preferences_section'),
      title: 'Preferences Setup (Q07 Approved)',
      icon: Icons.tune_rounded,
      children: [
        // 1. Languages
        const Text(
          'Communication Languages',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LearningColors.heading,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select the languages you are comfortable using for learning.',
          style: TextStyle(fontSize: 12, color: LearningColors.secondaryText),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LearningPreferences.defaultLanguages.map((lang) {
            final isSelected = _selectedLanguages.contains(lang);
            return FilterChip(
              key: Key('edit_lang_$lang'),
              label: Text(lang),
              selected: isSelected,
              selectedColor: LearningColors.primary.withValues(alpha: 0.15),
              checkmarkColor: LearningColors.primary,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedLanguages.add(lang);
                  } else {
                    _selectedLanguages.remove(lang);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // 2. Learning Styles
        const Text(
          'Preferred Learning Styles',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LearningColors.heading,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose the ways you learn best.',
          style: TextStyle(fontSize: 12, color: LearningColors.secondaryText),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LearningPreferences.defaultLearningStyles.map((style) {
            final isSelected = _selectedLearningStyles.contains(style);
            return FilterChip(
              key: Key('edit_style_$style'),
              label: Text(style),
              selected: isSelected,
              selectedColor: LearningColors.primary.withValues(alpha: 0.15),
              checkmarkColor: LearningColors.primary,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedLearningStyles.add(style);
                  } else {
                    _selectedLearningStyles.remove(style);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // 3. Availability
        const Text(
          'Learning Availability',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LearningColors.heading,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'When are you typically available to study or collaborate?',
          style: TextStyle(fontSize: 12, color: LearningColors.secondaryText),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LearningPreferences.defaultAvailabilityOptions
              .asMap()
              .entries
              .map((entry) {
            final idx = entry.key;
            final option = entry.value;
            final isSelected = _selectedAvailability == option;
            return ChoiceChip(
              key: Key('edit_availability_$idx'),
              label: Text(option),
              selected: isSelected,
              selectedColor: LearningColors.primary.withValues(alpha: 0.15),
              onSelected: (val) {
                setState(() {
                  _selectedAvailability = val ? option : null;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // 4. Notifications
        const Text(
          'Notification Preferences',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LearningColors.heading,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose which notifications you wish to receive locally.',
          style: TextStyle(fontSize: 12, color: LearningColors.secondaryText),
        ),
        const SizedBox(height: 8),
        Column(
          children: LearningPreferences.defaultNotificationOptions.map((opt) {
            final isEnabled = _notificationPreferences[opt] ?? false;
            return SwitchListTile(
              key: Key('edit_notif_$opt'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(opt, style: const TextStyle(fontSize: 13)),
              value: isEnabled,
              activeTrackColor: LearningColors.primary,
              onChanged: (val) {
                setState(() {
                  _notificationPreferences[opt] = val;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==========================================
  // SHARED CONTAINERS & BANNERS
  // ==========================================

  Widget _buildSectionContainer({
    Key? key,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: LearningColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: LearningColors.heading,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      key: const Key('learning_profile_status_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF15803D), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusBannerMessage!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF15803D)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 16, color: Color(0xFF15803D)),
            onPressed: () => setState(() => _statusBannerMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      key: const Key('learning_profile_error_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _errorColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorBannerMessage!,
              style: const TextStyle(fontSize: 13, color: _errorColor),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: _errorColor),
            onPressed: () => setState(() => _errorBannerMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildPersistenceNotice() {
    return Container(
      key: const Key('learning_profile_persistence_disclaimer'),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: LearningColors.secondaryText),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              LearningProfile.disconnectedNotice,
              style: TextStyle(
                fontSize: 11,
                color: LearningColors.secondaryText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ERROR & ACCESS CONTROL STATES
  // ==========================================

  Widget _buildAccessDeniedState() {
    return Center(
      key: const Key('learning_profile_access_denied'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gpp_bad_outlined,
                color: _errorColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Caller is not authorized to view or edit this Learning profile.\n'
              'Module profiles must be owned by the authenticated caller.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.onBack != null)
              OutlinedButton(
                onPressed: widget.onBack,
                child: const Text('Go Back'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      key: Key('learning_profile_loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: LearningColors.primary),
          SizedBox(height: 16),
          Text(
            'Loading Learning Profile...',
            style: TextStyle(
              fontSize: 14,
              color: LearningColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableState() {
    return Center(
      key: const Key('learning_profile_unavailable'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: LearningColors.secondaryText,
            ),
            const SizedBox(height: 16),
            const Text(
              'Service Unavailable',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Underlying M2 authentication or backend service is currently unavailable. '
              'Showing disconnected profile surface.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
                height: 1.4,
              ),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('btn_retry_unavailable'),
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      key: const Key('learning_profile_error'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: _errorColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
                height: 1.4,
              ),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('btn_retry_error'),
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
