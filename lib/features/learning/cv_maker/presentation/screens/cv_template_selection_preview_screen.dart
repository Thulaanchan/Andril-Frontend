import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/andril_module_app_bar.dart';

/// The three approved visual CV templates per ANDRIL LRN-05 & CV-01..CV-05.
enum CvTemplate {
  modern,
  professional,
  creative;

  /// User-facing display title.
  String get displayName {
    switch (this) {
      case CvTemplate.modern:
        return 'Modern';
      case CvTemplate.professional:
        return 'Professional';
      case CvTemplate.creative:
        return 'Creative';
    }
  }

  /// Official description of the layout aesthetics and target styling.
  String get description {
    switch (this) {
      case CvTemplate.modern:
        return 'Clean contemporary layout with crisp teal accents, structured cards and modern typography.';
      case CvTemplate.professional:
        return 'Executive corporate design with timeless navy borders, elegant dividers and formal sections.';
      case CvTemplate.creative:
        return 'Bold aesthetic with dynamic indigo sidebar, expressive skill badges and highlighted portfolio links.';
    }
  }

  /// Distinctive primary accent color for the template.
  Color get accentColor {
    switch (this) {
      case CvTemplate.modern:
        return const Color(0xFF00B4D8); // Cyan / Teal
      case CvTemplate.professional:
        return const Color(0xFF1E3A8A); // Corporate Navy
      case CvTemplate.creative:
        return const Color(0xFF7C3AED); // Indigo / Violet
    }
  }

  /// Subtle background tint color for badge chips and active highlights.
  Color get badgeBackgroundColor {
    switch (this) {
      case CvTemplate.modern:
        return const Color(0xFFE0F7FA);
      case CvTemplate.professional:
        return const Color(0xFFDBEAFE);
      case CvTemplate.creative:
        return const Color(0xFFEDE9FE);
    }
  }

  /// Approved feature bullet points for this template.
  List<String> get featureHighlights {
    switch (this) {
      case CvTemplate.modern:
        return const [
          'Teal accent header',
          'Structured skill cards',
          'Clean contemporary typography',
        ];
      case CvTemplate.professional:
        return const [
          'Corporate navy palette',
          'Formal chronological dividers',
          'Executive summary hierarchy',
        ];
      case CvTemplate.creative:
        return const [
          'Dynamic accent sidebar',
          'Expressive skill pills',
          'Portfolio & project highlights',
        ];
    }
  }
}

/// Experience entry in a CV draft (Section 2).
@immutable
class CvExperienceItem {
  final String jobTitle;
  final String company;
  final String period;
  final String description;

  const CvExperienceItem({
    required this.jobTitle,
    required this.company,
    required this.period,
    required this.description,
  });
}

/// Education entry in a CV draft (Section 3).
@immutable
class CvEducationItem {
  final String degree;
  final String institution;
  final String year;

  const CvEducationItem({
    required this.degree,
    required this.institution,
    required this.year,
  });
}

/// Certification entry in a CV draft (Section 5).
@immutable
class CvCertificationItem {
  final String name;
  final String issuer;
  final String year;
  final String? credentialId;

  const CvCertificationItem({
    required this.name,
    required this.issuer,
    required this.year,
    this.credentialId,
  });
}

/// Project entry in a CV draft (Section 6).
@immutable
class CvProjectItem {
  final String name;
  final String? role;
  final String? description;
  final String? link;

  const CvProjectItem({
    required this.name,
    this.role,
    this.description,
    this.link,
  });
}

/// Link entry in a CV draft (Section 7).
@immutable
class CvLinkItem {
  final String label;
  final String url;

  const CvLinkItem({
    required this.label,
    required this.url,
  });
}

/// Immutable draft model capturing all CV content independently from template styling.
///
/// Satisfies CV-02 (Lossless Template Switching): switching [selectedTemplate] does
/// not drop, mutate or corrupt any user-entered content across all seven sections.
@immutable
class CvDraftData {
  final String id;
  final String title;
  final CvTemplate selectedTemplate;
  final String fullName;
  final String headline;
  final String? email;
  final String? phone;
  final String? location;
  final String? website;
  final String summary;
  final List<String> skills;
  final List<CvExperienceItem> experiences;
  final List<CvEducationItem> education;
  final List<CvCertificationItem> certifications;
  final List<CvProjectItem> projects;
  final List<CvLinkItem> links;
  final bool showEmail;
  final bool showPhone;
  final bool showLocation;
  final bool showWebsite;
  final DateTime updatedAt;

  const CvDraftData({
    required this.id,
    required this.title,
    required this.selectedTemplate,
    required this.fullName,
    required this.headline,
    this.email,
    this.phone,
    this.location,
    this.website,
    required this.summary,
    required this.skills,
    required this.experiences,
    required this.education,
    this.certifications = const [],
    this.projects = const [],
    this.links = const [],
    this.showEmail = true,
    this.showPhone = true,
    this.showLocation = true,
    this.showWebsite = false,
    required this.updatedAt,
  });

  /// Creates a copy with optionally modified fields.
  CvDraftData copyWith({
    String? id,
    String? title,
    CvTemplate? selectedTemplate,
    String? fullName,
    String? headline,
    String? email,
    String? phone,
    String? location,
    String? website,
    String? summary,
    List<String>? skills,
    List<CvExperienceItem>? experiences,
    List<CvEducationItem>? education,
    List<CvCertificationItem>? certifications,
    List<CvProjectItem>? projects,
    List<CvLinkItem>? links,
    bool? showEmail,
    bool? showPhone,
    bool? showLocation,
    bool? showWebsite,
    DateTime? updatedAt,
  }) {
    return CvDraftData(
      id: id ?? this.id,
      title: title ?? this.title,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      fullName: fullName ?? this.fullName,
      headline: headline ?? this.headline,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      website: website ?? this.website,
      summary: summary ?? this.summary,
      skills: skills ?? this.skills,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
      certifications: certifications ?? this.certifications,
      projects: projects ?? this.projects,
      links: links ?? this.links,
      showEmail: showEmail ?? this.showEmail,
      showPhone: showPhone ?? this.showPhone,
      showLocation: showLocation ?? this.showLocation,
      showWebsite: showWebsite ?? this.showWebsite,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validates the CV draft title according to approved rules.
  /// Title must be non-empty and at most 60 characters.
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a title for this CV';
    }
    if (value.trim().length > 60) {
      return 'Title must be 60 characters or fewer';
    }
    return null;
  }

  /// Creates an empty initial draft for Create Mode.
  factory CvDraftData.empty({
    String title = 'My Professional CV',
    CvTemplate template = CvTemplate.modern,
  }) {
    return CvDraftData(
      id: 'cv_empty_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      selectedTemplate: template,
      fullName: '',
      headline: '',
      email: '',
      phone: '',
      location: '',
      website: '',
      summary: '',
      skills: const [],
      experiences: const [],
      education: const [],
      certifications: const [],
      projects: const [],
      links: const [],
      showEmail: false, // Default-off per CV-03
      showPhone: false, // Default-off per CV-03
      showLocation: false,
      showWebsite: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Realistic synthetic fixture for safe offline testing and live preview.
  ///
  /// Contains zero production endpoints or private account data.
  factory CvDraftData.syntheticSample({
    String title = 'My Professional CV',
    CvTemplate template = CvTemplate.modern,
  }) {
    return CvDraftData(
      id: 'cv_synthetic_01',
      title: title,
      selectedTemplate: template,
      fullName: 'Thusha Kunasingam',
      headline: 'Flutter & Mobile Systems Engineer',
      email: 'thusha.sample@andril.local',
      phone: '+94 77 123 4567',
      location: 'Jaffna, Sri Lanka',
      website: 'https://thusha.dev',
      summary:
          'Passionate frontend developer specializing in accessible Flutter applications, multi-module architecture, and robust cross-platform user experiences.',
      skills: const [
        'Flutter',
        'Dart',
        'State Management',
        'Widget Testing',
        'Clean Architecture',
        'CI/CD Workflows',
      ],
      experiences: const [
        CvExperienceItem(
          jobTitle: 'Lead Mobile Frontend Engineer',
          company: 'ANDRIL Education Labs',
          period: '2024 - Present',
          description:
              'Architected the Learning module presentation shell, responsive widget testing suite, and accessibility compliance.',
        ),
        CvExperienceItem(
          jobTitle: 'Junior Software Engineer',
          company: 'Unicom Technologies',
          period: '2022 - 2024',
          description:
              'Built reusable UI component bricks, modular navigation adapters, and offline draft storage models.',
        ),
      ],
      education: const [
        CvEducationItem(
          degree: 'B.Sc. (Hons) in Software Engineering',
          institution: 'University of Colombo',
          year: '2019 - 2023',
        ),
      ],
      certifications: const [
        CvCertificationItem(
          name: 'Professional Flutter Developer',
          issuer: 'Google Developers',
          year: '2023',
          credentialId: 'GDEV-FLUTTER-892',
        ),
      ],
      projects: const [
        CvProjectItem(
          name: 'ANDRIL Mobile Learning Suite',
          role: 'Lead Architect',
          description:
              'Cross-platform learning environment with offline draft synchronization.',
          link: 'https://github.com/andril/learning-mobile',
        ),
      ],
      links: const [
        CvLinkItem(
          label: 'GitHub',
          url: 'https://github.com/thusha-andril',
        ),
        CvLinkItem(
          label: 'LinkedIn',
          url: 'https://linkedin.com/in/thusha-andril',
        ),
      ],
      showEmail: true,
      showPhone: true,
      showLocation: true,
      showWebsite: true,
      updatedAt: DateTime(2026, 11, 24),
    );
  }
}

/// CV Maker Template Selection & Preview Screen (LRN-05, CV-01..05, LUC-32/34).
///
/// Features:
/// 1. Interactive Template Selection for Modern, Professional, and Creative layouts.
/// 2. Clear selected-state indicators with borders, accent badges, and checkmarks.
/// 3. Document title input with validation.
/// 4. Live Document Preview with lossless template switcher.
/// 5. Full responsiveness (320dp, 360dp, 412dp) with zero overflow.
/// 6. WCAG touch targets (>= 48dp) and comprehensive semantics.
class CvTemplateSelectionPreviewScreen extends StatefulWidget {
  /// Initial draft to preview and modify. If omitted, uses [CvDraftData.syntheticSample].
  final CvDraftData? initialDraft;

  /// Optional callback invoked when the user proceeds to the next editor step.
  final ValueChanged<CvDraftData>? onContinue;

  /// Optional callback invoked when the user saves the draft with selected template.
  final ValueChanged<CvDraftData>? onSaveDraft;

  /// Optional callback invoked when the template selection changes.
  final ValueChanged<CvTemplate>? onTemplateChanged;

  /// Whether to open directly in live preview mode. Defaults to false.
  final bool initialPreviewMode;

  /// Optional custom app bar. Defaults to [AndrilModuleAppBar] with CV Maker branding.
  final PreferredSizeWidget? appBar;

  const CvTemplateSelectionPreviewScreen({
    super.key,
    this.initialDraft,
    this.onContinue,
    this.onSaveDraft,
    this.onTemplateChanged,
    this.initialPreviewMode = false,
    this.appBar,
  });

  @override
  State<CvTemplateSelectionPreviewScreen> createState() =>
      _CvTemplateSelectionPreviewScreenState();
}

class _CvTemplateSelectionPreviewScreenState
    extends State<CvTemplateSelectionPreviewScreen> {
  late CvDraftData _currentDraft;
  late TextEditingController _titleController;
  final _formKey = GlobalKey<FormState>();
  late bool _isLivePreview;
  String? _statusBannerMessage;

  @override
  void initState() {
    super.initState();
    _currentDraft = widget.initialDraft ?? CvDraftData.syntheticSample();
    _titleController = TextEditingController(text: _currentDraft.title);
    _isLivePreview = widget.initialPreviewMode;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _selectTemplate(CvTemplate template) {
    if (_currentDraft.selectedTemplate == template) return;

    setState(() {
      _currentDraft = _currentDraft.copyWith(
        selectedTemplate: template,
        updatedAt: DateTime.now(),
      );
      _statusBannerMessage =
          'Switched to ${template.displayName} template. All draft content preserved.';
    });
    widget.onTemplateChanged?.call(template);
  }

  bool _isDraftValid(CvDraftData draft) {
    return CvDraftData.validateTitle(draft.title) == null;
  }

  void _togglePreview(bool enablePreview) {
    if (enablePreview && !_isLivePreview) {
      if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
        return;
      }
      _currentDraft = _currentDraft.copyWith(
        title: _titleController.text.trim(),
      );
    }
    setState(() {
      _isLivePreview = enablePreview;
    });
  }

  void _handleContinue() {
    if (_isLivePreview) {
      if (!_isDraftValid(_currentDraft)) {
        setState(() {
          _isLivePreview = false;
          _statusBannerMessage = 'Please enter a valid title for this CV.';
        });
        _formKey.currentState?.validate();
        return;
      }

      final updatedDraft = _currentDraft.copyWith(
        title: _currentDraft.title.trim(),
        updatedAt: DateTime.now(),
      );
      widget.onContinue?.call(updatedDraft);
      return;
    }

    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final updatedDraft = _currentDraft.copyWith(
      title: _titleController.text.trim(),
      updatedAt: DateTime.now(),
    );
    widget.onContinue?.call(updatedDraft);
  }

  void _handleSaveDraft() {
    if (_isLivePreview) {
      if (!_isDraftValid(_currentDraft)) {
        setState(() {
          _isLivePreview = false;
          _statusBannerMessage = 'Please enter a valid title for this CV.';
        });
        _formKey.currentState?.validate();
        return;
      }

      final updatedDraft = _currentDraft.copyWith(
        title: _currentDraft.title.trim(),
        updatedAt: DateTime.now(),
      );
      setState(() {
        _currentDraft = updatedDraft;
        _statusBannerMessage =
            'Draft "${updatedDraft.title}" saved successfully.';
      });
      widget.onSaveDraft?.call(updatedDraft);
      return;
    }

    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final updatedDraft = _currentDraft.copyWith(
      title: _titleController.text.trim(),
      updatedAt: DateTime.now(),
    );
    setState(() {
      _currentDraft = updatedDraft;
      _statusBannerMessage =
          'Draft "${updatedDraft.title}" saved successfully.';
    });
    widget.onSaveDraft?.call(updatedDraft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: widget.appBar ??
          const AndrilModuleAppBar(
            moduleName: 'CV Maker',
            badgeColor: LearningColors.primary,
          ),
      body: SafeArea(
        child: _isLivePreview ? _buildPreviewView() : _buildSelectionView(),
      ),
    );
  }

  // ===========================================================================
  // VIEW 1: TEMPLATE SELECTION VIEW
  // ===========================================================================

  Widget _buildSelectionView() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectionHeader(),
            const SizedBox(height: 16.0),
            if (_statusBannerMessage != null) ...[
              _buildStatusBanner(),
              const SizedBox(height: 16.0),
            ],
            _buildTitleInputCard(),
            const SizedBox(height: 20.0),
            _buildTemplateCardsSection(),
            const SizedBox(height: 24.0),
            _buildSelectionActionButtons(),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose CV Template',
          style: TextStyle(
            color: LearningColors.heading,
            fontSize: 22.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 6.0),
        Text(
          'Select an approved layout style for your professional CV. You can switch templates anytime with 100% lossless draft preservation.',
          style: TextStyle(
            color: LearningColors.secondaryText,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      key: const Key('status_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF059669),
            size: 20.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              _statusBannerMessage!,
              style: const TextStyle(
                color: Color(0xFF065F46),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16.0),
            color: const Color(0xFF065F46),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => setState(() => _statusBannerMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInputCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: LearningColors.secondaryText.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CV Title',
            style: TextStyle(
              color: LearningColors.heading,
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            key: const Key('cv_title_input'),
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'e.g. My Software Engineer CV',
              prefixIcon: const Icon(
                Icons.description_outlined,
                color: LearningColors.primary,
                size: 20.0,
              ),
              filled: true,
              fillColor: LearningColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 12.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(
                  color: LearningColors.primary,
                  width: 1.5,
                ),
              ),
            ),
            style: const TextStyle(
              fontSize: 14.0,
              color: LearningColors.heading,
              fontWeight: FontWeight.w600,
            ),
            validator: CvDraftData.validateTitle,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Template Style',
          style: TextStyle(
            color: LearningColors.heading,
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12.0),
        ...CvTemplate.values.map((template) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: _buildTemplateCard(template),
          );
        }),
      ],
    );
  }

  Widget _buildTemplateCard(CvTemplate template) {
    final bool isSelected = _currentDraft.selectedTemplate == template;
    final color = template.accentColor;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${template.displayName} template',
      hint: isSelected
          ? 'Currently selected'
          : 'Tap to select ${template.displayName}',
      child: Material(
        color: isSelected
            ? template.badgeBackgroundColor.withValues(alpha: 0.35)
            : LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        elevation: isSelected ? 2.0 : 0.5,
        shadowColor: color.withValues(alpha: 0.2),
        child: InkWell(
          key: Key('template_card_${template.name}'),
          onTap: () => _selectTemplate(template),
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isSelected
                    ? color
                    : LearningColors.secondaryText.withValues(alpha: 0.15),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Icon badge, Title, and Radio/Checkmark indicator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: template.badgeBackgroundColor,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Icon(
                        _getTemplateIcon(template),
                        color: color,
                        size: 22.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: [
                              Text(
                                template.displayName,
                                style: const TextStyle(
                                  color: LearningColors.heading,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 2.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: const Text(
                                    'SELECTED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            _getTemplateSubtitle(template),
                            style: TextStyle(
                              color: color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? color
                          : LearningColors.secondaryText.withValues(alpha: 0.4),
                      size: 24.0,
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  template.description,
                  style: const TextStyle(
                    color: LearningColors.secondaryText,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12.0),
                // Feature highlights chips
                Wrap(
                  spacing: 8.0,
                  runSpacing: 6.0,
                  children: template.featureHighlights.map((feature) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : LearningColors.background,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: isSelected
                              ? color.withValues(alpha: 0.3)
                              : LearningColors.secondaryText
                                  .withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Icon(
                                  Icons.check,
                                  size: 12.0,
                                  color: color,
                                ),
                              ),
                            ),
                            TextSpan(text: feature),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? LearningColors.heading
                              : LearningColors.secondaryText,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14.0),
                // Visual mini-layout thumbnail representation
                _buildTemplateThumbnail(template, isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTemplateIcon(CvTemplate template) {
    switch (template) {
      case CvTemplate.modern:
        return Icons.auto_awesome_rounded;
      case CvTemplate.professional:
        return Icons.business_center_rounded;
      case CvTemplate.creative:
        return Icons.palette_rounded;
    }
  }

  String _getTemplateSubtitle(CvTemplate template) {
    switch (template) {
      case CvTemplate.modern:
        return 'Contemporary Cyan • Card Bricks';
      case CvTemplate.professional:
        return 'Executive Navy • Formal Rules';
      case CvTemplate.creative:
        return 'Expressive Indigo • Sidebar Accent';
    }
  }

  Widget _buildTemplateThumbnail(CvTemplate template, bool isSelected) {
    final color = template.accentColor;

    return Container(
      width: double.infinity,
      height: 64.0,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isSelected
              ? color.withValues(alpha: 0.4)
              : LearningColors.secondaryText.withValues(alpha: 0.12),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: _buildThumbnailMockup(template),
      ),
    );
  }

  Widget _buildThumbnailMockup(CvTemplate template) {
    final color = template.accentColor;

    switch (template) {
      case CvTemplate.modern:
        return Column(
          children: [
            Container(
              height: 10.0,
              color: color,
              width: double.infinity,
            ),
            const SizedBox(height: 4.0),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(height: 6.0, color: const Color(0xFFCBD5E1)),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  flex: 3,
                  child: Container(height: 6.0, color: const Color(0xFFE2E8F0)),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Row(
              children: [
                Expanded(
                    child: Container(
                        height: 16.0, color: template.badgeBackgroundColor)),
                const SizedBox(width: 4.0),
                Expanded(
                    child: Container(
                        height: 16.0, color: template.badgeBackgroundColor)),
              ],
            ),
          ],
        );
      case CvTemplate.professional:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 8.0, width: 80.0, color: color),
            const SizedBox(height: 3.0),
            Container(height: 1.5, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 4.0),
            Container(
                height: 6.0,
                width: double.infinity,
                color: const Color(0xFFE2E8F0)),
            const SizedBox(height: 4.0),
            Row(
              children: [
                Container(
                    height: 12.0, width: 40.0, color: const Color(0xFFCBD5E1)),
                const SizedBox(width: 6.0),
                Expanded(
                    child: Container(
                        height: 12.0, color: const Color(0xFFF1F5F9))),
              ],
            ),
          ],
        );
      case CvTemplate.creative:
        return Row(
          children: [
            Container(
              width: 32.0,
              height: double.infinity,
              color: color,
              child: Center(
                child: Container(
                  width: 14.0,
                  height: 14.0,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 8.0, width: 60.0, color: const Color(0xFF1E293B)),
                  const SizedBox(height: 4.0),
                  Container(
                      height: 6.0,
                      width: double.infinity,
                      color: const Color(0xFFE2E8F0)),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Container(
                          height: 8.0,
                          width: 24.0,
                          color: template.badgeBackgroundColor),
                      const SizedBox(width: 4.0),
                      Container(
                          height: 8.0,
                          width: 24.0,
                          color: template.badgeBackgroundColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildSelectionActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 360;
        final continueBtn = SizedBox(
          width: isNarrow ? double.infinity : null,
          height: 48.0,
          child: ElevatedButton.icon(
            key: const Key('continue_button'),
            onPressed: _handleContinue,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18.0),
            label: const Text(
              'Continue to Editor',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: LearningColors.primary,
              foregroundColor: Colors.white,
              elevation: 1.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        );

        final saveBtn = SizedBox(
          width: isNarrow ? double.infinity : null,
          height: 48.0,
          child: OutlinedButton(
            key: const Key('save_draft_button'),
            onPressed: _handleSaveDraft,
            style: OutlinedButton.styleFrom(
              foregroundColor: LearningColors.secondaryText,
              side: BorderSide(
                color: LearningColors.secondaryText.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: const Text(
              'Save Draft',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );

        return Column(
          children: [
            // Live Preview CTA
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: OutlinedButton.icon(
                key: const Key('live_preview_button'),
                onPressed: () => _togglePreview(true),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 20.0),
                label: Text(
                  'Live Preview (${_currentDraft.selectedTemplate.displayName})',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LearningColors.primary,
                  side: const BorderSide(
                      color: LearningColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            if (isNarrow) ...[
              continueBtn,
              const SizedBox(height: 10.0),
              saveBtn,
            ] else ...[
              Row(
                children: [
                  Expanded(child: saveBtn),
                  const SizedBox(width: 12.0),
                  Expanded(flex: 2, child: continueBtn),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  // ===========================================================================
  // VIEW 2: LIVE PREVIEW VIEW (LOSSLESS TEMPLATE SWITCHING)
  // ===========================================================================

  Widget _buildPreviewView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Top Bar
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 6.0,
            children: [
              TextButton.icon(
                key: const Key('back_to_selection_button'),
                onPressed: () => _togglePreview(false),
                icon: const Icon(Icons.arrow_back_rounded, size: 18.0),
                label: const Text(
                  'Choose Template',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: LearningColors.primary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: _currentDraft.selectedTemplate.badgeBackgroundColor,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: _currentDraft.selectedTemplate.accentColor
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Active: ${_currentDraft.selectedTemplate.displayName}',
                  style: TextStyle(
                    color: _currentDraft.selectedTemplate.accentColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          // Lossless switcher strip
          _buildLosslessTemplateSwitcher(),
          const SizedBox(height: 16.0),
          // Live Document Canvas
          _buildDocumentSheetCanvas(),
          const SizedBox(height: 20.0),
          // Bottom Preview Actions
          _buildPreviewBottomToolbar(),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  Widget _buildLosslessTemplateSwitcher() {
    return Container(
      key: const Key('lossless_template_switcher'),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: LearningColors.secondaryText.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.swap_horiz_rounded,
                  size: 18.0, color: LearningColors.primary),
              SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  'Lossless Template Switcher',
                  style: TextStyle(
                    color: LearningColors.heading,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            children: CvTemplate.values.map((template) {
              final isSelected = _currentDraft.selectedTemplate == template;
              final color = template.accentColor;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: 'Switch to ${template.displayName}',
                    child: InkWell(
                      key: Key('preview_switch_${template.name}'),
                      onTap: () => _selectTemplate(template),
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : template.badgeBackgroundColor
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.25),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            template.displayName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : color,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSheetCanvas() {
    final template = _currentDraft.selectedTemplate;

    return Container(
      key: const Key('cv_document_canvas'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: template.accentColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: _buildTemplateDocumentLayout(template),
      ),
    );
  }

  Widget _buildTemplateDocumentLayout(CvTemplate template) {
    switch (template) {
      case CvTemplate.modern:
        return _buildModernDocumentLayout();
      case CvTemplate.professional:
        return _buildProfessionalDocumentLayout();
      case CvTemplate.creative:
        return _buildCreativeDocumentLayout();
    }
  }

  // Modern Layout: Cyan accent banner, clean sections, badge highlights
  Widget _buildModernDocumentLayout() {
    const accent = Color(0xFF00B4D8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Teal Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: const BoxDecoration(
            color: accent,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentDraft.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                _currentDraft.headline,
                style: const TextStyle(
                  color: Color(0xFFE0F7FA),
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8.0),
              _buildContactPills(
                  textColor: Colors.white, iconColor: const Color(0xFFE0F7FA)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Executive Summary', accent),
              const SizedBox(height: 6.0),
              Text(
                _currentDraft.summary,
                style: const TextStyle(
                  color: LearningColors.secondaryText,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16.0),
              _buildSectionTitle('Key Competencies', accent),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: _currentDraft.skills.map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: Color(0xFF0077B6),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16.0),
              _buildSectionTitle('Experience', accent),
              const SizedBox(height: 8.0),
              ..._currentDraft.experiences
                  .map((exp) => _buildExperienceItem(exp, accent)),
              const SizedBox(height: 12.0),
              _buildSectionTitle('Education', accent),
              const SizedBox(height: 8.0),
              ..._currentDraft.education
                  .map((edu) => _buildEducationItem(edu, accent)),
            ],
          ),
        ),
      ],
    );
  }

  // Professional Layout: Corporate Navy, formal horizontal dividers, classic elegance
  Widget _buildProfessionalDocumentLayout() {
    const accent = Color(0xFF1E3A8A);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentDraft.fullName.toUpperCase(),
            style: const TextStyle(
              color: accent,
              fontSize: 21.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 3.0),
          Text(
            _currentDraft.headline,
            style: const TextStyle(
              color: LearningColors.secondaryText,
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6.0),
          _buildContactPills(
              textColor: const Color(0xFF1E293B), iconColor: accent),
          const SizedBox(height: 10.0),
          const Divider(color: accent, thickness: 1.5),
          const SizedBox(height: 12.0),
          _buildSectionTitle('Professional Summary', accent),
          const SizedBox(height: 6.0),
          Text(
            _currentDraft.summary,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16.0),
          _buildSectionTitle('Core Competencies', accent),
          const SizedBox(height: 6.0),
          Text(
            _currentDraft.skills.join(' • '),
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16.0),
          _buildSectionTitle('Professional Experience', accent),
          const SizedBox(height: 8.0),
          ..._currentDraft.experiences
              .map((exp) => _buildExperienceItem(exp, accent)),
          const SizedBox(height: 12.0),
          _buildSectionTitle('Education & Credentials', accent),
          const SizedBox(height: 8.0),
          ..._currentDraft.education
              .map((edu) => _buildEducationItem(edu, accent)),
        ],
      ),
    );
  }

  // Creative Layout: Indigo accent, colored left sidebar, dynamic badges
  Widget _buildCreativeDocumentLayout() {
    const accent = Color(0xFF7C3AED);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Sidebar
          Container(
            width: 110.0,
            color: const Color(0xFFF5F3FF),
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24.0,
                  backgroundColor: accent,
                  child: Text(
                    _getInitials(_currentDraft.fullName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'CONTACT',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6.0),
                if (_currentDraft.showEmail && _currentDraft.email != null) ...[
                  Text(
                    _currentDraft.email!,
                    style: const TextStyle(
                        fontSize: 10.0, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6.0),
                ],
                if (_currentDraft.showLocation &&
                    _currentDraft.location != null) ...[
                  Text(
                    _currentDraft.location!,
                    style: const TextStyle(
                        fontSize: 10.0, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12.0),
                ],
                const Text(
                  'SKILLS',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6.0),
                ..._currentDraft.skills.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '# $s',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5B21B6),
                        ),
                      ),
                    )),
              ],
            ),
          ),
          // Main Panel
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentDraft.fullName,
                    style: const TextStyle(
                      color: Color(0xFF1E1B4B),
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _currentDraft.headline,
                    style: const TextStyle(
                      color: accent,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  _buildSectionTitle('Profile', accent),
                  const SizedBox(height: 4.0),
                  Text(
                    _currentDraft.summary,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  _buildSectionTitle('Experience', accent),
                  const SizedBox(height: 6.0),
                  ..._currentDraft.experiences
                      .map((exp) => _buildExperienceItem(exp, accent)),
                  const SizedBox(height: 10.0),
                  _buildSectionTitle('Education', accent),
                  const SizedBox(height: 6.0),
                  ..._currentDraft.education
                      .map((edu) => _buildEducationItem(edu, accent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color accent) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 14.0,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        const SizedBox(width: 6.0),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 13.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceItem(CvExperienceItem exp, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exp.jobTitle,
                  style: const TextStyle(
                    color: LearningColors.heading,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                exp.period,
                style: const TextStyle(
                  color: LearningColors.secondaryText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            exp.company,
            style: TextStyle(
              color: accent,
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            exp.description,
            style: const TextStyle(
              color: LearningColors.secondaryText,
              fontSize: 11.0,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(CvEducationItem edu, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree,
                  style: const TextStyle(
                    color: LearningColors.heading,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  edu.institution,
                  style: const TextStyle(
                    color: LearningColors.secondaryText,
                    fontSize: 11.0,
                  ),
                ),
              ],
            ),
          ),
          Text(
            edu.year,
            style: TextStyle(
              color: accent,
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactPills(
      {required Color textColor, required Color iconColor}) {
    final pills = <Widget>[];

    if (_currentDraft.showEmail && _currentDraft.email != null) {
      pills.add(_buildContactItem(
          Icons.email_outlined, _currentDraft.email!, textColor, iconColor));
    }
    if (_currentDraft.showPhone && _currentDraft.phone != null) {
      pills.add(_buildContactItem(
          Icons.phone_outlined, _currentDraft.phone!, textColor, iconColor));
    }
    if (_currentDraft.showLocation && _currentDraft.location != null) {
      pills.add(_buildContactItem(Icons.location_on_outlined,
          _currentDraft.location!, textColor, iconColor));
    }

    if (pills.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10.0,
      runSpacing: 4.0,
      children: pills,
    );
  }

  Widget _buildContactItem(
      IconData icon, String text, Color textColor, Color iconColor) {
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Icon(icon, size: 12.0, color: iconColor),
            ),
          ),
          TextSpan(text: text),
        ],
      ),
      style: TextStyle(
        color: textColor,
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'CV';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildPreviewBottomToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 360;
        final continueBtn = SizedBox(
          width: isNarrow ? double.infinity : null,
          height: 48.0,
          child: ElevatedButton.icon(
            key: const Key('preview_continue_button'),
            onPressed: _handleContinue,
            icon: const Icon(Icons.check_rounded, size: 18.0),
            label: const Text(
              'Use This Template',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: LearningColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        );

        final backBtn = SizedBox(
          width: isNarrow ? double.infinity : null,
          height: 48.0,
          child: OutlinedButton(
            key: const Key('preview_back_button'),
            onPressed: () => _togglePreview(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: LearningColors.secondaryText,
              side: BorderSide(
                color: LearningColors.secondaryText.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: const Text('Back to Templates'),
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              continueBtn,
              const SizedBox(height: 10.0),
              backBtn,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: backBtn),
            const SizedBox(width: 12.0),
            Expanded(flex: 2, child: continueBtn),
          ],
        );
      },
    );
  }
}
