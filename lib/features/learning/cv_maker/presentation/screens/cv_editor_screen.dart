import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/andril_module_app_bar.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';

/// The seven approved CV editor sections per ANDRIL LRN-05, CV-01..05 & BRD v2.4-R1.
enum CvEditorSection {
  profile('Profile', Icons.person_outline),
  experience('Experience', Icons.work_outline),
  education('Education', Icons.school_outlined),
  skills('Skills', Icons.psychology_outlined),
  certifications('Certifications', Icons.verified_outlined),
  projects('Projects', Icons.folder_outlined),
  links('Links', Icons.link);

  final String title;
  final IconData icon;

  const CvEditorSection(this.title, this.icon);
}

/// CV Creation & Editing Screen (ANDRIL LRN-05, CV-01..05, LUC-33).
///
/// Features:
/// 1. Seven-section structured editor (Profile, Experience, Education, Skills,
///    Certifications, Projects, Links).
/// 2. Clear Create Mode vs. Edit Mode support.
/// 3. Step progress indicator and direct section jumping via navigation tabs.
/// 4. Independent, default-off contact privacy export consent (CV-03).
/// 5. Document title editing with 60-character limit validation.
/// 6. Lossless draft preservation and handoff to Template Selection and Preview.
/// 7. Manual draft saving with explicit confirmation banner.
/// 8. Full responsiveness down to 320dp and 1.5x dynamic text scaling.
class CvEditorScreen extends StatefulWidget {
  /// Initial draft data to edit. If omitted, initialized based on [isCreateMode].
  final CvDraftData? initialDraft;

  /// Whether the editor is in create mode (new draft) or edit mode (modifying existing).
  final bool isCreateMode;

  /// Optional callback invoked when the user saves the draft manually.
  final ValueChanged<CvDraftData>? onSaveDraft;

  /// Optional callback invoked when the user proceeds to template selection / preview.
  final ValueChanged<CvDraftData>? onPreview;

  /// Optional custom app bar. Defaults to [AndrilModuleAppBar] with CV Maker branding.
  final PreferredSizeWidget? appBar;

  const CvEditorScreen({
    super.key,
    this.initialDraft,
    this.isCreateMode = false,
    this.onSaveDraft,
    this.onPreview,
    this.appBar,
  });

  @override
  State<CvEditorScreen> createState() => _CvEditorScreenState();
}

class _CvEditorScreenState extends State<CvEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late CvDraftData _currentDraft;
  int _activeSectionIndex = 0;
  String? _statusBannerMessage;

  // Document Title
  late final TextEditingController _titleController;

  // Section 1: Profile controllers
  late final TextEditingController _fullNameController;
  late final TextEditingController _headlineController;
  late final TextEditingController _summaryController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _websiteController;

  // Contact privacy export consent (CV-03: default-off in create mode)
  late bool _showEmail;
  late bool _showPhone;
  late bool _showLocation;
  late bool _showWebsite;

  // Section 2: Experience state
  late List<CvExperienceItem> _experiences;
  bool _isAddingExperience = false;
  final _expJobTitleController = TextEditingController();
  final _expCompanyController = TextEditingController();
  final _expPeriodController = TextEditingController();
  final _expDescriptionController = TextEditingController();

  // Section 3: Education state
  late List<CvEducationItem> _education;
  bool _isAddingEducation = false;
  final _eduDegreeController = TextEditingController();
  final _eduInstitutionController = TextEditingController();
  final _eduYearController = TextEditingController();

  // Section 4: Skills state
  late List<String> _skills;
  final _skillInputController = TextEditingController();

  // Section 5: Certifications state
  late List<CvCertificationItem> _certifications;
  bool _isAddingCertification = false;
  final _certNameController = TextEditingController();
  final _certIssuerController = TextEditingController();
  final _certYearController = TextEditingController();
  final _certCredentialController = TextEditingController();

  // Section 6: Projects state
  late List<CvProjectItem> _projects;
  bool _isAddingProject = false;
  final _projNameController = TextEditingController();
  final _projRoleController = TextEditingController();
  final _projDescriptionController = TextEditingController();
  final _projLinkController = TextEditingController();

  // Section 7: Links state
  late List<CvLinkItem> _links;
  bool _isAddingLink = false;
  final _linkLabelController = TextEditingController();
  final _linkUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft != null) {
      _currentDraft = widget.initialDraft!;
    } else if (widget.isCreateMode) {
      _currentDraft = CvDraftData.empty();
    } else {
      _currentDraft = CvDraftData.syntheticSample();
    }

    _titleController = TextEditingController(text: _currentDraft.title);
    _fullNameController = TextEditingController(text: _currentDraft.fullName);
    _headlineController = TextEditingController(text: _currentDraft.headline);
    _summaryController = TextEditingController(text: _currentDraft.summary);
    _emailController = TextEditingController(text: _currentDraft.email ?? '');
    _phoneController = TextEditingController(text: _currentDraft.phone ?? '');
    _locationController =
        TextEditingController(text: _currentDraft.location ?? '');
    _websiteController =
        TextEditingController(text: _currentDraft.website ?? '');

    // Independent default-off consent in create mode per CV-03
    if (widget.isCreateMode && widget.initialDraft == null) {
      _showEmail = false;
      _showPhone = false;
      _showLocation = false;
      _showWebsite = false;
    } else {
      _showEmail = _currentDraft.showEmail;
      _showPhone = _currentDraft.showPhone;
      _showLocation = _currentDraft.showLocation;
      _showWebsite = _currentDraft.showWebsite;
    }

    _experiences = List<CvExperienceItem>.from(_currentDraft.experiences);
    _education = List<CvEducationItem>.from(_currentDraft.education);
    _skills = List<String>.from(_currentDraft.skills);
    _certifications =
        List<CvCertificationItem>.from(_currentDraft.certifications);
    _projects = List<CvProjectItem>.from(_currentDraft.projects);
    _links = List<CvLinkItem>.from(_currentDraft.links);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fullNameController.dispose();
    _headlineController.dispose();
    _summaryController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _websiteController.dispose();

    _expJobTitleController.dispose();
    _expCompanyController.dispose();
    _expPeriodController.dispose();
    _expDescriptionController.dispose();

    _eduDegreeController.dispose();
    _eduInstitutionController.dispose();
    _eduYearController.dispose();

    _skillInputController.dispose();

    _certNameController.dispose();
    _certIssuerController.dispose();
    _certYearController.dispose();
    _certCredentialController.dispose();

    _projNameController.dispose();
    _projRoleController.dispose();
    _projDescriptionController.dispose();
    _projLinkController.dispose();

    _linkLabelController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  /// Assembles the current form state into an immutable [CvDraftData] entity.
  CvDraftData _buildCurrentDraft() {
    return _currentDraft.copyWith(
      title: _titleController.text.trim(),
      fullName: _fullNameController.text.trim(),
      headline: _headlineController.text.trim(),
      summary: _summaryController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      showEmail: _showEmail,
      showPhone: _showPhone,
      showLocation: _showLocation,
      showWebsite: _showWebsite,
      experiences: List.unmodifiable(_experiences),
      education: List.unmodifiable(_education),
      skills: List.unmodifiable(_skills),
      certifications: List.unmodifiable(_certifications),
      projects: List.unmodifiable(_projects),
      links: List.unmodifiable(_links),
      updatedAt: DateTime.now(),
    );
  }

  /// Validates both the document title and the mandatory profile full name.
  bool _validateDraftInputs() {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return false;

    final title = _titleController.text.trim();
    if (title.isEmpty || title.length > 60) return false;

    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) return false;

    return true;
  }

  void _handleSaveDraft() {
    if (!_validateDraftInputs()) {
      setState(() {
        _statusBannerMessage =
            'Please resolve validation errors before saving draft.';
      });
      return;
    }

    final updated = _buildCurrentDraft();
    setState(() {
      _currentDraft = updated;
      _statusBannerMessage = widget.onSaveDraft != null
          ? 'Draft "${updated.title}" saved.'
          : 'Draft "${updated.title}" saved locally. Remote repository persistence contract pending.';
    });

    widget.onSaveDraft?.call(updated);
  }

  void _handlePreview() {
    if (!_validateDraftInputs()) {
      setState(() {
        _statusBannerMessage =
            'Please resolve validation errors before previewing.';
      });
      return;
    }

    final updated = _buildCurrentDraft();
    if (widget.onPreview != null) {
      widget.onPreview!(updated);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CvTemplateSelectionPreviewScreen(
            initialDraft: updated,
            initialPreviewMode: true,
          ),
        ),
      );
    }
  }

  void _goToSection(int index) {
    if (index < 0 || index >= CvEditorSection.values.length) return;
    setState(() {
      _activeSectionIndex = index;
    });
  }

  void _nextSection() {
    if (_activeSectionIndex < CvEditorSection.values.length - 1) {
      _goToSection(_activeSectionIndex + 1);
    }
  }

  void _prevSection() {
    if (_activeSectionIndex > 0) {
      _goToSection(_activeSectionIndex - 1);
    }
  }

  // Experience actions
  void _saveNewExperience() {
    final title = _expJobTitleController.text.trim();
    final company = _expCompanyController.text.trim();
    final period = _expPeriodController.text.trim();
    final desc = _expDescriptionController.text.trim();

    if (title.isEmpty || company.isEmpty) return;

    setState(() {
      _experiences.add(CvExperienceItem(
        jobTitle: title,
        company: company,
        period: period.isEmpty ? 'Present' : period,
        description: desc,
      ));
      _expJobTitleController.clear();
      _expCompanyController.clear();
      _expPeriodController.clear();
      _expDescriptionController.clear();
      _isAddingExperience = false;
    });
  }

  // Education actions
  void _saveNewEducation() {
    final degree = _eduDegreeController.text.trim();
    final inst = _eduInstitutionController.text.trim();
    final year = _eduYearController.text.trim();

    if (degree.isEmpty || inst.isEmpty) return;

    setState(() {
      _education.add(CvEducationItem(
        degree: degree,
        institution: inst,
        year: year.isEmpty ? 'Present' : year,
      ));
      _eduDegreeController.clear();
      _eduInstitutionController.clear();
      _eduYearController.clear();
      _isAddingEducation = false;
    });
  }

  // Skills actions
  void _addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty || _skills.contains(trimmed)) return;
    setState(() {
      _skills.add(trimmed);
      _skillInputController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  // Certification actions
  void _saveNewCertification() {
    final name = _certNameController.text.trim();
    final issuer = _certIssuerController.text.trim();
    final year = _certYearController.text.trim();
    final credId = _certCredentialController.text.trim();

    if (name.isEmpty || issuer.isEmpty) return;

    setState(() {
      _certifications.add(CvCertificationItem(
        name: name,
        issuer: issuer,
        year: year.isEmpty ? '2024' : year,
        credentialId: credId.isEmpty ? null : credId,
      ));
      _certNameController.clear();
      _certIssuerController.clear();
      _certYearController.clear();
      _certCredentialController.clear();
      _isAddingCertification = false;
    });
  }

  // Project actions
  void _saveNewProject() {
    final name = _projNameController.text.trim();
    final role = _projRoleController.text.trim();
    final desc = _projDescriptionController.text.trim();
    final link = _projLinkController.text.trim();

    if (name.isEmpty) return;

    setState(() {
      _projects.add(CvProjectItem(
        name: name,
        role: role.isEmpty ? null : role,
        description: desc.isEmpty ? null : desc,
        link: link.isEmpty ? null : link,
      ));
      _projNameController.clear();
      _projRoleController.clear();
      _projDescriptionController.clear();
      _projLinkController.clear();
      _isAddingProject = false;
    });
  }

  // Link actions
  void _saveNewLink() {
    final label = _linkLabelController.text.trim();
    final url = _linkUrlController.text.trim();

    if (label.isEmpty || url.isEmpty) return;

    setState(() {
      _links.add(CvLinkItem(
        label: label,
        url: url,
      ));
      _linkLabelController.clear();
      _linkUrlController.clear();
      _isAddingLink = false;
    });
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16.0),
                if (_statusBannerMessage != null) ...[
                  _buildStatusBanner(),
                  const SizedBox(height: 16.0),
                ],
                _buildProgressAndStepper(),
                const SizedBox(height: 20.0),
                _buildActiveSectionContent(),
                const SizedBox(height: 24.0),
                _buildNavigationAndActions(),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 6.0,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                widget.isCreateMode ? 'Create CV' : 'Edit CV',
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: widget.isCreateMode
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: widget.isCreateMode
                        ? LearningColors.primary.withValues(alpha: 0.3)
                        : const Color(0xFF16A34A).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  widget.isCreateMode ? 'CREATE MODE' : 'EDIT MODE',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: widget.isCreateMode
                        ? LearningColors.primary
                        : const Color(0xFF16A34A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          TextFormField(
            key: const Key('cv_title_input'),
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'CV Document Title',
              hintText: 'e.g. Senior Mobile Architect CV',
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
              helperText: 'Required. Maximum 60 characters.',
            ),
            validator: CvDraftData.validateTitle,
          ),
        ],
      ),
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
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18.0),
            color: const Color(0xFF065F46),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _statusBannerMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressAndStepper() {
    final currentSection = CvEditorSection.values[_activeSectionIndex];
    final progress = (_activeSectionIndex + 1) / CvEditorSection.values.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              Text(
                'Section ${_activeSectionIndex + 1} of 7 • ${currentSection.title}',
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: LearningColors.heading,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6.0,
              backgroundColor: const Color(0xFFF1F5F9),
              color: LearningColors.primary,
            ),
          ),
          const SizedBox(height: 14.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CvEditorSection.values.map((section) {
                final isSelected = section.index == _activeSectionIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    key: Key('section_tab_${section.name}'),
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Icon(
                      section.icon,
                      size: 16.0,
                      color: isSelected ? Colors.white : LearningColors.primary,
                    ),
                    label: Text(
                      '${section.index + 1}. ${section.title}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : LearningColors.heading,
                      ),
                    ),
                    selectedColor: LearningColors.primary,
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: BorderSide(
                      color: isSelected
                          ? LearningColors.primary
                          : const Color(0xFFE2E8F0),
                    ),
                    onSelected: (_) => _goToSection(section.index),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSectionContent() {
    switch (CvEditorSection.values[_activeSectionIndex]) {
      case CvEditorSection.profile:
        return _buildProfileSection();
      case CvEditorSection.experience:
        return _buildExperienceSection();
      case CvEditorSection.education:
        return _buildEducationSection();
      case CvEditorSection.skills:
        return _buildSkillsSection();
      case CvEditorSection.certifications:
        return _buildCertificationsSection();
      case CvEditorSection.projects:
        return _buildProjectsSection();
      case CvEditorSection.links:
        return _buildLinksSection();
    }
  }

  // ===========================================================================
  // SECTION 1: PROFILE
  // ===========================================================================
  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: LearningColors.cardSurface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                key: const Key('profile_full_name_input'),
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'e.g. Thusha Kunasingam',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                key: const Key('profile_headline_input'),
                controller: _headlineController,
                decoration: const InputDecoration(
                  labelText: 'Professional Headline',
                  hintText: 'e.g. Lead Mobile Frontend Engineer',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                key: const Key('profile_summary_input'),
                controller: _summaryController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Professional Summary',
                  hintText:
                      'Highlight your technical expertise and career goals...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                key: const Key('profile_email_input'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'e.g. user@andril.local',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                key: const Key('profile_phone_input'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. +94 77 123 4567',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                key: const Key('profile_location_input'),
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location / City',
                  hintText: 'e.g. Jaffna, Sri Lanka',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                key: const Key('profile_website_input'),
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Personal Website / Portfolio URL',
                  hintText: 'e.g. https://thusha.dev',
                  prefixIcon: Icon(Icons.language_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        // Contact Privacy Controls (CV-03)
        Material(
          color: const Color(0xFFF0FDF4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(
              color: const Color(0xFF16A34A).withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: Color(0xFF16A34A),
                      size: 20.0,
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Contact Privacy Controls (CV-03)',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                const Text(
                  'Personal information is kept private. Check items below to include them on your exported CV document.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF14532D),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10.0),
                SwitchListTile.adaptive(
                  key: const Key('consent_email_switch'),
                  title: const Text('Include Email in CV export',
                      style: TextStyle(fontSize: 13.5)),
                  value: _showEmail,
                  activeThumbColor: const Color(0xFF16A34A),
                  activeTrackColor: const Color(0xFF86EFAC),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _showEmail = val),
                ),
                SwitchListTile.adaptive(
                  key: const Key('consent_phone_switch'),
                  title: const Text('Include Phone in CV export',
                      style: TextStyle(fontSize: 13.5)),
                  value: _showPhone,
                  activeThumbColor: const Color(0xFF16A34A),
                  activeTrackColor: const Color(0xFF86EFAC),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _showPhone = val),
                ),
                SwitchListTile.adaptive(
                  key: const Key('consent_location_switch'),
                  title: const Text('Include Location in CV export',
                      style: TextStyle(fontSize: 13.5)),
                  value: _showLocation,
                  activeThumbColor: const Color(0xFF16A34A),
                  activeTrackColor: const Color(0xFF86EFAC),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _showLocation = val),
                ),
                SwitchListTile.adaptive(
                  key: const Key('consent_website_switch'),
                  title: const Text('Include Website in CV export',
                      style: TextStyle(fontSize: 13.5)),
                  value: _showWebsite,
                  activeThumbColor: const Color(0xFF16A34A),
                  activeTrackColor: const Color(0xFF86EFAC),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _showWebsite = val),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 2: EXPERIENCE
  // ===========================================================================
  Widget _buildExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeaderWithAdd(
          title: 'Work Experience',
          subtitle: 'Add employment and professional career history.',
          buttonKey: const Key('add_experience_button'),
          buttonText: '+ Add Experience',
          onAdd: () => setState(() => _isAddingExperience = true),
        ),
        const SizedBox(height: 12.0),
        if (_isAddingExperience) _buildExperienceFormCard(),
        if (_experiences.isEmpty && !_isAddingExperience)
          _buildEmptyPlaceholder(
            'No experience entries yet. Tap "+ Add Experience" above to list your career achievements.',
          ),
        ..._experiences.asMap().entries.map((entry) {
          final index = entry.key;
          final exp = entry.value;
          return _buildItemCard(
            title: exp.jobTitle,
            subtitle: '${exp.company} • ${exp.period}',
            body: exp.description,
            deleteKey: Key('delete_experience_$index'),
            onDelete: () => setState(() => _experiences.removeAt(index)),
          );
        }),
      ],
    );
  }

  Widget _buildExperienceFormCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16.0),
        border:
            Border.all(color: LearningColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Experience Entry',
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: LearningColors.primary,
            ),
          ),
          const SizedBox(height: 12.0),
          TextFormField(
            key: const Key('exp_job_title_input'),
            controller: _expJobTitleController,
            decoration: const InputDecoration(
              labelText: 'Job Title *',
              hintText: 'e.g. Lead Mobile Frontend Engineer',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('exp_company_input'),
            controller: _expCompanyController,
            decoration: const InputDecoration(
              labelText: 'Company / Organization *',
              hintText: 'e.g. ANDRIL Education Labs',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('exp_period_input'),
            controller: _expPeriodController,
            decoration: const InputDecoration(
              labelText: 'Period',
              hintText: 'e.g. 2024 - Present',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('exp_description_input'),
            controller: _expDescriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description / Key Achievements',
              hintText: 'Summary of roles and accomplishments...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14.0),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              TextButton(
                key: const Key('cancel_experience_button'),
                onPressed: () => setState(() => _isAddingExperience = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton(
                key: const Key('save_experience_button'),
                onPressed: _saveNewExperience,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Entry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 3: EDUCATION
  // ===========================================================================
  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeaderWithAdd(
          title: 'Education & Credentials',
          subtitle: 'Academic qualifications and institutions attended.',
          buttonKey: const Key('add_education_button'),
          buttonText: '+ Add Education',
          onAdd: () => setState(() => _isAddingEducation = true),
        ),
        const SizedBox(height: 12.0),
        if (_isAddingEducation) _buildEducationFormCard(),
        if (_education.isEmpty && !_isAddingEducation)
          _buildEmptyPlaceholder(
            'No education credentials added yet. Tap "+ Add Education" to add your academic degrees.',
          ),
        ..._education.asMap().entries.map((entry) {
          final index = entry.key;
          final edu = entry.value;
          return _buildItemCard(
            title: edu.degree,
            subtitle: '${edu.institution} • ${edu.year}',
            deleteKey: Key('delete_education_$index'),
            onDelete: () => setState(() => _education.removeAt(index)),
          );
        }),
      ],
    );
  }

  Widget _buildEducationFormCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16.0),
        border:
            Border.all(color: LearningColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Education Entry',
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: LearningColors.primary,
            ),
          ),
          const SizedBox(height: 12.0),
          TextFormField(
            key: const Key('edu_degree_input'),
            controller: _eduDegreeController,
            decoration: const InputDecoration(
              labelText: 'Degree / Certificate *',
              hintText: 'e.g. B.Sc. in Software Engineering',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('edu_institution_input'),
            controller: _eduInstitutionController,
            decoration: const InputDecoration(
              labelText: 'Institution / University *',
              hintText: 'e.g. University of Colombo',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('edu_year_input'),
            controller: _eduYearController,
            decoration: const InputDecoration(
              labelText: 'Graduation Year / Period',
              hintText: 'e.g. 2019 - 2023',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14.0),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              TextButton(
                key: const Key('cancel_education_button'),
                onPressed: () => setState(() => _isAddingEducation = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton(
                key: const Key('save_education_button'),
                onPressed: _saveNewEducation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Entry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 4: SKILLS
  // ===========================================================================
  Widget _buildSkillsSection() {
    const presets = [
      'Flutter',
      'Dart',
      'Clean Architecture',
      'Widget Testing',
      'State Management',
      'REST APIs',
      'Git Workflows',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Core Competencies & Skills',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 6.0),
          const Text(
            'Add technical proficiencies and domain competencies to your CV.',
            style: TextStyle(
              fontSize: 13.0,
              color: LearningColors.secondaryText,
            ),
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('add_skill_input'),
                  controller: _skillInputController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Firebase, Docker',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  ),
                  onFieldSubmitted: _addSkill,
                ),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton(
                key: const Key('add_skill_button'),
                onPressed: () => _addSkill(_skillInputController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 48),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          if (_skills.isNotEmpty) ...[
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _skills.map((skill) {
                return Chip(
                  key: Key('skill_chip_$skill'),
                  label: Text(skill),
                  deleteIcon: const Icon(Icons.close, size: 16.0),
                  onDeleted: () => _removeSkill(skill),
                  backgroundColor: const Color(0xFFEFF6FF),
                  side: BorderSide(
                    color: LearningColors.primary.withValues(alpha: 0.2),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14.0),
          ],
          const Text(
            'Suggested Skills:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: LearningColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: presets.map((preset) {
              final alreadyAdded = _skills.contains(preset);
              return ActionChip(
                key: Key('preset_skill_$preset'),
                label: Text(alreadyAdded ? '✓ $preset' : '+ $preset'),
                backgroundColor: alreadyAdded
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFFF8FAFC),
                onPressed: alreadyAdded ? null : () => _addSkill(preset),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 5: CERTIFICATIONS
  // ===========================================================================
  Widget _buildCertificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeaderWithAdd(
          title: 'Certifications',
          subtitle: 'Verified credentials and licenses.',
          buttonKey: const Key('add_certification_button'),
          buttonText: '+ Add Certificate',
          onAdd: () => setState(() => _isAddingCertification = true),
        ),
        const SizedBox(height: 12.0),
        if (_isAddingCertification) _buildCertificationFormCard(),
        if (_certifications.isEmpty && !_isAddingCertification)
          _buildEmptyPlaceholder(
            'No certifications added yet. Tap "+ Add Certificate" to list your professional badges.',
          ),
        ..._certifications.asMap().entries.map((entry) {
          final index = entry.key;
          final cert = entry.value;
          return _buildItemCard(
            title: cert.name,
            subtitle: '${cert.issuer} • ${cert.year}',
            body: cert.credentialId != null ? 'ID: ${cert.credentialId}' : null,
            deleteKey: Key('delete_certification_$index'),
            onDelete: () => setState(() => _certifications.removeAt(index)),
          );
        }),
      ],
    );
  }

  Widget _buildCertificationFormCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16.0),
        border:
            Border.all(color: LearningColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Certification',
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: LearningColors.primary,
            ),
          ),
          const SizedBox(height: 12.0),
          TextFormField(
            key: const Key('cert_name_input'),
            controller: _certNameController,
            decoration: const InputDecoration(
              labelText: 'Certificate Name *',
              hintText: 'e.g. Professional Flutter Developer',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('cert_issuer_input'),
            controller: _certIssuerController,
            decoration: const InputDecoration(
              labelText: 'Issuing Organization *',
              hintText: 'e.g. Google Developers',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('cert_year_input'),
            controller: _certYearController,
            decoration: const InputDecoration(
              labelText: 'Year / Date',
              hintText: 'e.g. 2024',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('cert_credential_input'),
            controller: _certCredentialController,
            decoration: const InputDecoration(
              labelText: 'Credential ID / URL',
              hintText: 'e.g. GDEV-FLUTTER-892',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14.0),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              TextButton(
                key: const Key('cancel_certification_button'),
                onPressed: () => setState(() => _isAddingCertification = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton(
                key: const Key('save_certification_button'),
                onPressed: _saveNewCertification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Entry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 6: PROJECTS
  // ===========================================================================
  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeaderWithAdd(
          title: 'Projects & Highlights',
          subtitle: 'Notable portfolio and engineering projects.',
          buttonKey: const Key('add_project_button'),
          buttonText: '+ Add Project',
          onAdd: () => setState(() => _isAddingProject = true),
        ),
        const SizedBox(height: 12.0),
        if (_isAddingProject) _buildProjectFormCard(),
        if (_projects.isEmpty && !_isAddingProject)
          _buildEmptyPlaceholder(
            'No projects listed yet. Tap "+ Add Project" to highlight your work.',
          ),
        ..._projects.asMap().entries.map((entry) {
          final index = entry.key;
          final proj = entry.value;
          return _buildItemCard(
            title: proj.name,
            subtitle: proj.role,
            body: proj.description,
            deleteKey: Key('delete_project_$index'),
            onDelete: () => setState(() => _projects.removeAt(index)),
          );
        }),
      ],
    );
  }

  Widget _buildProjectFormCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16.0),
        border:
            Border.all(color: LearningColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Project Entry',
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: LearningColors.primary,
            ),
          ),
          const SizedBox(height: 12.0),
          TextFormField(
            key: const Key('proj_name_input'),
            controller: _projNameController,
            decoration: const InputDecoration(
              labelText: 'Project Name *',
              hintText: 'e.g. ANDRIL Mobile App',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('proj_role_input'),
            controller: _projRoleController,
            decoration: const InputDecoration(
              labelText: 'Role / Tech Stack',
              hintText: 'e.g. Lead Developer (Flutter & Dart)',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('proj_description_input'),
            controller: _projDescriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Key deliverables, metrics and features...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('proj_link_input'),
            controller: _projLinkController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Project Link / Repository',
              hintText: 'e.g. https://github.com/...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14.0),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              TextButton(
                key: const Key('cancel_project_button'),
                onPressed: () => setState(() => _isAddingProject = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton(
                key: const Key('save_project_button'),
                onPressed: _saveNewProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Entry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 7: LINKS
  // ===========================================================================
  Widget _buildLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeaderWithAdd(
          title: 'Custom Links & Profiles',
          subtitle: 'GitHub, LinkedIn, Portfolio and social URLs.',
          buttonKey: const Key('add_link_button'),
          buttonText: '+ Add Link',
          onAdd: () => setState(() => _isAddingLink = true),
        ),
        const SizedBox(height: 12.0),
        if (_isAddingLink) _buildLinkFormCard(),
        if (_links.isEmpty && !_isAddingLink)
          _buildEmptyPlaceholder(
            'No external links added yet. Tap "+ Add Link" to share your profile links.',
          ),
        ..._links.asMap().entries.map((entry) {
          final index = entry.key;
          final link = entry.value;
          return _buildItemCard(
            title: link.label,
            subtitle: link.url,
            deleteKey: Key('delete_link_$index'),
            onDelete: () => setState(() => _links.removeAt(index)),
          );
        }),
      ],
    );
  }

  Widget _buildLinkFormCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16.0),
        border:
            Border.all(color: LearningColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Link Entry',
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: LearningColors.primary,
            ),
          ),
          const SizedBox(height: 12.0),
          TextFormField(
            key: const Key('link_label_input'),
            controller: _linkLabelController,
            decoration: const InputDecoration(
              labelText: 'Label *',
              hintText: 'e.g. GitHub, LinkedIn, Portfolio',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('link_url_input'),
            controller: _linkUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL Address *',
              hintText: 'e.g. https://github.com/myname',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14.0),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              TextButton(
                key: const Key('cancel_link_button'),
                onPressed: () => setState(() => _isAddingLink = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton(
                key: const Key('save_link_button'),
                onPressed: _saveNewLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Entry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================
  Widget _buildSectionHeaderWithAdd({
    required String title,
    required String subtitle,
    required Key buttonKey,
    required String buttonText,
    required VoidCallback onAdd,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
          ),
          ElevatedButton(
            key: buttonKey,
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: LearningColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 48),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.0,
            color: LearningColors.secondaryText,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard({
    required String title,
    String? subtitle,
    String? body,
    required Key deleteKey,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3.0),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: LearningColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (body != null && body.isNotEmpty) ...[
                  const SizedBox(height: 6.0),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: LearningColors.secondaryText,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            key: deleteKey,
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            tooltip: 'Remove',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION & ACTION BAR
  // ===========================================================================
  Widget _buildNavigationAndActions() {
    return Column(
      children: [
        // Stepper Navigation Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('prev_section_button'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _activeSectionIndex > 0 ? _prevSection : null,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('next_section_button'),
                icon: const Icon(Icons.arrow_forward),
                label: Text(
                  _activeSectionIndex == CvEditorSection.values.length - 1
                      ? 'Done Editing'
                      : 'Next Section',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed:
                    _activeSectionIndex < CvEditorSection.values.length - 1
                        ? _nextSection
                        : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        // Primary Actions Row
        Wrap(
          spacing: 12.0,
          runSpacing: 10.0,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('preview_template_button'),
                icon: const Icon(Icons.palette_outlined),
                label: const Text(
                  'Choose Template & Preview',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488), // Teal accent
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: _handlePreview,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('save_draft_button'),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save CV Draft'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: LearningColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: _handleSaveDraft,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
