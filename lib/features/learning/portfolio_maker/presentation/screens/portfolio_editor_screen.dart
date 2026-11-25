import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/andril_module_app_bar.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/presentation/screens/portfolio_template_selection_preview_screen.dart';

/// Learning Portfolio Creation & Editing Screen.
///
/// Implements LRN-06 / PORT-01..05 & DEC-20261120-LRN06-01:
/// - Private create/edit modes for Learning Portfolios.
/// - Structured project editing with title, description, media, and external links.
/// - Inert HTTP/HTTPS URL reference management for media and links.
/// - Project reordering and lossless draft preservation across all interactions.
/// - Loading, empty, error, confirmation, and access-denied states.
/// - Manual saving distinguishing local in-memory draft retention from persistent saving.
/// - Responsive down to 320dp and 1.5x dynamic text scaling without overflow.
class PortfolioEditorScreen extends StatefulWidget {
  /// Initial portfolio to edit. If null, initializes in Create Mode.
  final LearningPortfolio? initialPortfolio;

  /// Whether the editor is in create mode (new portfolio) or edit mode (existing).
  final bool isCreateMode;

  /// Current user's learning profile ID used for owner access verification.
  final String currentUserId;

  /// Whether the screen is in a loading state.
  final bool isLoading;

  /// Whether access to this portfolio has been explicitly denied.
  final bool isAccessDenied;

  /// Optional callback invoked when the user saves the portfolio draft.
  final ValueChanged<LearningPortfolio>? onSavePortfolio;

  /// Optional callback invoked when user navigates to choose template and preview.
  final ValueChanged<LearningPortfolio>? onPreviewPortfolio;

  /// Optional custom app bar. Defaults to [AndrilModuleAppBar] with Portfolio Maker branding.
  final PreferredSizeWidget? appBar;

  const PortfolioEditorScreen({
    super.key,
    this.initialPortfolio,
    this.isCreateMode = false,
    this.currentUserId = 'current_user_default',
    this.isLoading = false,
    this.isAccessDenied = false,
    this.onSavePortfolio,
    this.onPreviewPortfolio,
    this.appBar,
  });

  @override
  State<PortfolioEditorScreen> createState() => _PortfolioEditorScreenState();
}

class _PortfolioEditorScreenState extends State<PortfolioEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late LearningPortfolio _currentPortfolio;
  late final TextEditingController _titleController;
  late List<PortfolioProject> _projects;

  String? _statusBannerMessage;
  String? _errorBannerMessage;

  // Project Editor Form State
  bool _isEditingProject = false;
  int? _editingProjectIndex;
  final _projectTitleController = TextEditingController();
  final _projectDescController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  final _linkUrlController = TextEditingController();
  List<String> _currentMediaUrls = [];
  List<String> _currentLinkUrls = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPortfolio != null) {
      _currentPortfolio = widget.initialPortfolio!;
    } else if (widget.isCreateMode) {
      _currentPortfolio = LearningPortfolio.empty(
        ownerLearningProfileId: widget.currentUserId,
      );
    } else {
      _currentPortfolio = LearningPortfolio.syntheticSample(
        ownerLearningProfileId: widget.currentUserId,
      );
    }

    _titleController = TextEditingController(text: _currentPortfolio.title);
    _projects = List<PortfolioProject>.from(_currentPortfolio.projects);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _projectTitleController.dispose();
    _projectDescController.dispose();
    _mediaUrlController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  /// Builds the current immutable [LearningPortfolio] from live editor state.
  LearningPortfolio _buildCurrentPortfolio() {
    return _currentPortfolio.copyWith(
      title: _titleController.text.trim(),
      projects: List.unmodifiable(_projects),
      updatedAt: DateTime.now(),
    );
  }

  /// Validates portfolio document title.
  bool _validatePortfolioTitle() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _errorBannerMessage = 'Portfolio document title is required.';
        _statusBannerMessage = null;
      });
      return false;
    }
    return true;
  }

  void _handleSavePortfolio() {
    if (!_validatePortfolioTitle()) return;

    final updated = _buildCurrentPortfolio();
    setState(() {
      _currentPortfolio = updated;
      _errorBannerMessage = null;
      _statusBannerMessage = widget.onSavePortfolio != null
          ? 'Portfolio "${updated.title}" saved.'
          : 'Portfolio "${updated.title}" saved locally. Remote repository persistence contract pending.';
    });

    widget.onSavePortfolio?.call(updated);
  }

  void _handlePreview() {
    if (!_validatePortfolioTitle()) return;

    final updated = _buildCurrentPortfolio();
    if (widget.onPreviewPortfolio != null) {
      widget.onPreviewPortfolio!(updated);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PortfolioTemplateSelectionPreviewScreen(
            initialPortfolio: updated,
            currentUserId: widget.currentUserId,
          ),
        ),
      );
    }
  }

  // Project CRUD Actions
  void _startAddProject() {
    setState(() {
      _isEditingProject = true;
      _editingProjectIndex = null;
      _projectTitleController.clear();
      _projectDescController.clear();
      _mediaUrlController.clear();
      _linkUrlController.clear();
      _currentMediaUrls = [];
      _currentLinkUrls = [];
      _errorBannerMessage = null;
    });
  }

  void _startEditProject(int index) {
    if (index < 0 || index >= _projects.length) return;
    final proj = _projects[index];
    setState(() {
      _isEditingProject = true;
      _editingProjectIndex = index;
      _projectTitleController.text = proj.title ?? '';
      _projectDescController.text = proj.description ?? '';
      _mediaUrlController.clear();
      _linkUrlController.clear();
      _currentMediaUrls = List<String>.from(proj.mediaReferences);
      _currentLinkUrls = List<String>.from(proj.externalLinks);
      _errorBannerMessage = null;
    });
  }

  void _cancelProjectEdit() {
    setState(() {
      _isEditingProject = false;
      _editingProjectIndex = null;
      _projectTitleController.clear();
      _projectDescController.clear();
      _mediaUrlController.clear();
      _linkUrlController.clear();
      _currentMediaUrls = [];
      _currentLinkUrls = [];
    });
  }

  void _saveProjectEntry() {
    final title = _projectTitleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _errorBannerMessage = 'Project title is required.';
      });
      return;
    }

    final desc = _projectDescController.text.trim();
    final newProject = PortfolioProject(
      id: _editingProjectIndex != null
          ? _projects[_editingProjectIndex!].id
          : 'proj_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: desc.isEmpty ? null : desc,
      mediaReferences: List.unmodifiable(_currentMediaUrls),
      externalLinks: List.unmodifiable(_currentLinkUrls),
    );

    setState(() {
      if (_editingProjectIndex != null) {
        _projects[_editingProjectIndex!] = newProject;
        _statusBannerMessage = 'Project "$title" updated.';
      } else {
        _projects.add(newProject);
        _statusBannerMessage = 'Project "$title" added to portfolio.';
      }
      _isEditingProject = false;
      _editingProjectIndex = null;
      _errorBannerMessage = null;
    });
  }

  void _deleteProject(int index) {
    if (index < 0 || index >= _projects.length) return;
    final removed = _projects[index];
    setState(() {
      _projects.removeAt(index);
      _statusBannerMessage = 'Project "${removed.title ?? "Entry"}" removed.';
      _errorBannerMessage = null;
    });
  }

  void _moveProjectUp(int index) {
    if (index <= 0 || index >= _projects.length) return;
    setState(() {
      final item = _projects.removeAt(index);
      _projects.insert(index - 1, item);
      _statusBannerMessage = 'Project moved up.';
    });
  }

  void _moveProjectDown(int index) {
    if (index < 0 || index >= _projects.length - 1) return;
    setState(() {
      final item = _projects.removeAt(index);
      _projects.insert(index + 1, item);
      _statusBannerMessage = 'Project moved down.';
    });
  }

  // Media & Link Reference Actions
  void _addMediaUrl() {
    final url = _mediaUrlController.text.trim();
    if (url.isEmpty) return;

    if (!PortfolioProject.isValidUrl(url)) {
      setState(() {
        _errorBannerMessage =
            'Media reference must be an absolute HTTP or HTTPS URL.';
      });
      return;
    }

    setState(() {
      _currentMediaUrls.add(url);
      _mediaUrlController.clear();
      _errorBannerMessage = null;
    });
  }

  void _removeMediaUrl(int index) {
    if (index < 0 || index >= _currentMediaUrls.length) return;
    setState(() {
      _currentMediaUrls.removeAt(index);
    });
  }

  void _addLinkUrl() {
    final url = _linkUrlController.text.trim();
    if (url.isEmpty) return;

    if (!PortfolioProject.isValidUrl(url)) {
      setState(() {
        _errorBannerMessage =
            'External link must be an absolute HTTP or HTTPS URL.';
      });
      return;
    }

    setState(() {
      _currentLinkUrls.add(url);
      _linkUrlController.clear();
      _errorBannerMessage = null;
    });
  }

  void _removeLinkUrl(int index) {
    if (index < 0 || index >= _currentLinkUrls.length) return;
    setState(() {
      _currentLinkUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    if (widget.isLoading) {
      return Scaffold(
        backgroundColor: LearningColors.background,
        appBar: widget.appBar ??
            const AndrilModuleAppBar(
              moduleName: 'Portfolio Maker',
              badgeColor: LearningColors.primary,
            ),
        body: const Center(
          child: CircularProgressIndicator(
            key: Key('loading_indicator'),
            color: LearningColors.primary,
          ),
        ),
      );
    }

    // 2. Access Denied State (Owner-scoped privacy)
    final bool isUnauthorized = widget.isAccessDenied ||
        (widget.currentUserId.isNotEmpty &&
            _currentPortfolio.ownerLearningProfileId.isNotEmpty &&
            widget.currentUserId != _currentPortfolio.ownerLearningProfileId);

    if (isUnauthorized) {
      return Scaffold(
        backgroundColor: LearningColors.background,
        appBar: widget.appBar ??
            const AndrilModuleAppBar(
              moduleName: 'Portfolio Maker',
              badgeColor: LearningColors.primary,
            ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              key: const Key('access_denied_card'),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: LearningColors.cardSurface,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_person_outlined,
                    color: Color(0xFFEF4444),
                    size: 48.0,
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: LearningColors.heading,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'This Learning Portfolio is private and can only be accessed by its owner.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: LearningColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. Main Editor Interface
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: widget.appBar ??
          const AndrilModuleAppBar(
            moduleName: 'Portfolio Maker',
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
                if (_errorBannerMessage != null) ...[
                  _buildErrorBanner(),
                  const SizedBox(height: 16.0),
                ],
                if (_isEditingProject)
                  _buildProjectForm()
                else
                  _buildProjectListSection(),
                const SizedBox(height: 24.0),
                _buildActionButtons(),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                widget.isCreateMode ? 'Create Portfolio' : 'Edit Portfolio',
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: [
                  Container(
                    key: Key(widget.isCreateMode
                        ? 'mode_badge_create'
                        : 'mode_badge_edit'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 4.0),
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
                  Container(
                    key: const Key('privacy_badge_private'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 13.0, color: LearningColors.secondaryText),
                        SizedBox(width: 4.0),
                        Text(
                          'PRIVATE',
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            color: LearningColors.secondaryText,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          TextFormField(
            key: const Key('portfolio_title_input'),
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Portfolio Title *',
              hintText: 'e.g. Mobile Systems Engineering Portfolio',
              prefixIcon: Icon(Icons.folder_special_outlined),
              border: OutlineInputBorder(),
              helperText: 'Required. Identifies your portfolio showcase.',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Portfolio document title is required.';
              }
              return null;
            },
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
          color: const Color(0xFF059669).withValues(alpha: 0.3),
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
            onPressed: () => setState(() => _statusBannerMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      key: const Key('error_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 20.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              _errorBannerMessage!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18.0),
            color: const Color(0xFF991B1B),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _errorBannerMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              Wrap(
                spacing: 8.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Portfolio Projects',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: LearningColors.heading,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: LearningColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      '${_projects.length}',
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                key: const Key('add_project_button'),
                icon: const Icon(Icons.add, size: 18.0),
                label: const Text('Add Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _startAddProject,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
        if (_projects.isEmpty)
          Container(
            key: const Key('empty_projects_placeholder'),
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: LearningColors.cardSurface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 40.0,
                  color: LearningColors.secondaryText,
                ),
                SizedBox(height: 10.0),
                Text(
                  'No projects added yet.',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Tap "+ Add Project" above to showcase your learning achievements.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: LearningColors.secondaryText,
                  ),
                ),
              ],
            ),
          )
        else
          ..._projects.asMap().entries.map((entry) {
            final index = entry.key;
            final project = entry.value;
            return _buildProjectCard(index, project);
          }),
      ],
    );
  }

  Widget _buildProjectCard(int index, PortfolioProject project) {
    return Container(
      key: Key('project_card_$index'),
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28.0,
                height: 28.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title ?? 'Untitled Project',
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                      ),
                    ),
                    if (project.description != null &&
                        project.description!.isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        project.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: LearningColors.secondaryText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          // References count badges
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              if (project.mediaReferences.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_outlined,
                          size: 13.0, color: Color(0xFF7E22CE)),
                      const SizedBox(width: 4.0),
                      Text(
                        '${project.mediaReferences.length} Media',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7E22CE),
                        ),
                      ),
                    ],
                  ),
                ),
              if (project.externalLinks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link,
                          size: 13.0, color: Color(0xFF1D4ED8)),
                      const SizedBox(width: 4.0),
                      Text(
                        '${project.externalLinks.length} Links',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 18.0),
          // Reorder and card actions
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Reorder buttons
                Wrap(
                  spacing: 4.0,
                  children: [
                    IconButton(
                      key: Key('move_up_project_$index'),
                      icon: const Icon(Icons.arrow_upward, size: 18.0),
                      tooltip: 'Move Up',
                      onPressed: index > 0 ? () => _moveProjectUp(index) : null,
                    ),
                    IconButton(
                      key: Key('move_down_project_$index'),
                      icon: const Icon(Icons.arrow_downward, size: 18.0),
                      tooltip: 'Move Down',
                      onPressed: index < _projects.length - 1
                          ? () => _moveProjectDown(index)
                          : null,
                    ),
                  ],
                ),
                // Edit and delete actions
                Wrap(
                  spacing: 8.0,
                  children: [
                    OutlinedButton.icon(
                      key: Key('edit_project_$index'),
                      icon: const Icon(Icons.edit_outlined, size: 16.0),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 6.0),
                        minimumSize: const Size(60, 32),
                      ),
                      onPressed: () => _startEditProject(index),
                    ),
                    IconButton(
                      key: Key('delete_project_$index'),
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFEF4444), size: 20.0),
                      tooltip: 'Remove',
                      onPressed: () => _deleteProject(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Structured Project Form (Add/Edit)
  Widget _buildProjectForm() {
    final bool isEditing = _editingProjectIndex != null;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border:
            Border.all(color: LearningColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isEditing ? 'Edit Project Entry' : 'Add New Project',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
              ),
              IconButton(
                key: const Key('cancel_project_entry_button'),
                icon: const Icon(Icons.close),
                onPressed: _cancelProjectEdit,
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          TextFormField(
            key: const Key('project_title_input'),
            controller: _projectTitleController,
            decoration: const InputDecoration(
              labelText: 'Project Title *',
              hintText: 'e.g. ANDRIL Mobile Learning Suite',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12.0),
          TextFormField(
            key: const Key('project_description_input'),
            controller: _projectDescController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Project Description',
              hintText: 'Brief summary of objectives and deliverables...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16.0),
          // Media References Section
          const Text(
            'Media References (Screenshots / Demos)',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 6.0),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('media_url_input'),
                  controller: _mediaUrlController,
                  decoration: const InputDecoration(
                    hintText: 'https://andril.dev/screenshot.png',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  ),
                  onFieldSubmitted: (_) => _addMediaUrl(),
                ),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton(
                key: const Key('add_media_button'),
                onPressed: _addMediaUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 44),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          if (_currentMediaUrls.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: _currentMediaUrls.asMap().entries.map((entry) {
                final idx = entry.key;
                final url = entry.value;
                return Chip(
                  key: Key('media_chip_$idx'),
                  avatar: const Icon(Icons.image, size: 14.0),
                  label: Text(
                    url,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14.0),
                  onDeleted: () => _removeMediaUrl(idx),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16.0),
          // External Links Section
          const Text(
            'External Links (GitHub / Documentation)',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 6.0),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('link_url_input'),
                  controller: _linkUrlController,
                  decoration: const InputDecoration(
                    hintText: 'https://github.com/andril/project',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  ),
                  onFieldSubmitted: (_) => _addLinkUrl(),
                ),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton(
                key: const Key('add_link_button'),
                onPressed: _addLinkUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 44),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          if (_currentLinkUrls.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: _currentLinkUrls.asMap().entries.map((entry) {
                final idx = entry.key;
                final url = entry.value;
                return Chip(
                  key: Key('link_chip_$idx'),
                  avatar: const Icon(Icons.link, size: 14.0),
                  label: Text(
                    url,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14.0),
                  onDeleted: () => _removeLinkUrl(idx),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 18.0),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              TextButton(
                key: const Key('cancel_project_button'),
                onPressed: _cancelProjectEdit,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                key: const Key('save_project_entry_button'),
                onPressed: _saveProjectEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(isEditing ? 'Save Changes' : 'Add Project Entry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
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
              backgroundColor: LearningColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: _handlePreview,
          ),
        ),
        const SizedBox(height: 10.0),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('save_portfolio_button'),
            icon: const Icon(Icons.save_outlined),
            label: const Text(
              'Save Portfolio Draft',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: _handleSavePortfolio,
          ),
        ),
      ],
    );
  }
}
