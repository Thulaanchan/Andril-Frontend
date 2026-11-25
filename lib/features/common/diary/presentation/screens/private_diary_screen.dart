import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/features/common/diary/domain/diary_models.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/andril_module_app_bar.dart';

/// Private Diary Screen for Learning Module (CF-13 / DIA-R01..R10).
///
/// Features:
/// 1. Interactive calendar navigation and explicit/implicit date resolution.
/// 2. Daily reflection creation, editing, and removal (up to 100 char title, 10,000 char body).
/// 3. Daily plans management with 20-plan boundary limit (up to 120 char title, 1,000 char desc).
/// 4. Strict owner-scoped access verification failing closed for mismatched profiles/modules.
/// 5. Draft state preservation without falsely claiming remote persistent saving.
/// 6. Fully responsive across 320dp, 360dp, 412dp viewports and 1.5x dynamic text scaling.
/// 7. Redacted confidentiality preventing diary body leakage into logs.
class PrivateDiaryScreen extends StatefulWidget {
  /// Current authenticated user ID used for owner access verification.
  final String currentUserId;

  /// The authorized owner module profile ID.
  final String ownerModuleProfileId;

  /// The active module (defaults to 'learning').
  final String module;

  /// Optional initial calendar date. If omitted, uses today or resolved date.
  final DateTime? initialDate;

  /// Optional selected IANA timezone string (e.g. 'Asia/Colombo').
  final String? ianaTimeZone;

  /// Optional callback invoked when the user saves the diary draft.
  final ValueChanged<ModuleDiaryEntry>? onSaveDraft;

  /// Optional callback invoked when the selected calendar date changes.
  final ValueChanged<DateTime>? onDateChanged;

  /// Whether the screen is currently in a loading state.
  final bool isLoading;

  /// Whether access to this diary has been explicitly revoked or denied.
  final bool isAccessDenied;

  /// Optional custom app bar. Defaults to [AndrilModuleAppBar] with Learning branding.
  final PreferredSizeWidget? appBar;

  const PrivateDiaryScreen({
    super.key,
    required this.currentUserId,
    required this.ownerModuleProfileId,
    this.module = 'learning',
    this.initialDate,
    this.ianaTimeZone = 'Asia/Colombo',
    this.onSaveDraft,
    this.onDateChanged,
    this.isLoading = false,
    this.isAccessDenied = false,
    this.appBar,
  });

  @override
  State<PrivateDiaryScreen> createState() => _PrivateDiaryScreenState();
}

class _PrivateDiaryScreenState extends State<PrivateDiaryScreen> {
  final DiaryCalendarResolver _calendarResolver = const DiaryCalendarResolver();

  late DateTime _selectedDate;
  final Map<String, ModuleDiaryEntry> _entriesByDateKey = {};

  // Form & Input Controllers
  final _reflectionTitleController = TextEditingController();
  final _reflectionBodyController = TextEditingController();

  // Plan editing state
  bool _isEditingPlan = false;
  String? _editingPlanId;
  final _planTitleController = TextEditingController();
  final _planDescController = TextEditingController();

  // Reflection active editor mode
  bool _isReflectionEditorOpen = false;

  // Banner status messages
  String? _statusBannerMessage;
  String? _errorBannerMessage;

  @override
  void initState() {
    super.initState();
    _initializeDateAndEntry();
  }

  void _initializeDateAndEntry() {
    final resolved = _calendarResolver.resolveDate(
          ianaTimeZone: widget.ianaTimeZone,
          explicitDate: widget.initialDate,
        ) ??
        DateTime.utc(2026, 11, 25);

    _selectedDate = DateTime.utc(resolved.year, resolved.month, resolved.day);
    _ensureEntryForDate(_selectedDate);
    _syncReflectionControllers();
  }

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  ModuleDiaryEntry _ensureEntryForDate(DateTime dt) {
    final key = _dateKey(dt);
    if (!_entriesByDateKey.containsKey(key)) {
      _entriesByDateKey[key] = ModuleDiaryEntry.create(
        ownerModuleProfileId: widget.ownerModuleProfileId,
        module: widget.module,
        date: dt,
      );
    }
    return _entriesByDateKey[key]!;
  }

  ModuleDiaryEntry get _currentEntry => _ensureEntryForDate(_selectedDate);

  void _syncReflectionControllers() {
    final ref = _currentEntry.reflection;
    if (ref != null) {
      _reflectionTitleController.text = ref.title ?? '';
      _reflectionBodyController.text = ref.body;
      _isReflectionEditorOpen = true;
    } else {
      _reflectionTitleController.clear();
      _reflectionBodyController.clear();
      _isReflectionEditorOpen = false;
    }
  }

  @override
  void dispose() {
    _reflectionTitleController.dispose();
    _reflectionBodyController.dispose();
    _planTitleController.dispose();
    _planDescController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // DATE NAVIGATION ACTIONS
  // ===========================================================================

  void _changeDate(DateTime newDate) {
    final normalized = DateTime.utc(newDate.year, newDate.month, newDate.day);
    setState(() {
      _selectedDate = normalized;
      _isEditingPlan = false;
      _editingPlanId = null;
      _statusBannerMessage = null;
      _errorBannerMessage = null;
      _ensureEntryForDate(_selectedDate);
      _syncReflectionControllers();
    });
    widget.onDateChanged?.call(_selectedDate);
  }

  void _handlePrevDay() {
    _changeDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  void _handleNextDay() {
    _changeDate(_selectedDate.add(const Duration(days: 1)));
  }

  void _handleToday() {
    final today = _calendarResolver.resolveDate(
          ianaTimeZone: widget.ianaTimeZone,
          utcNow: DateTime.now().toUtc(),
        ) ??
        DateTime.utc(2026, 11, 25);
    _changeDate(today);
  }

  Future<void> _handleSelectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: LearningColors.primary,
              onPrimary: Colors.white,
              surface: LearningColors.cardSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _changeDate(picked);
    }
  }

  // ===========================================================================
  // REFLECTION ACTIONS
  // ===========================================================================

  void _handleOpenReflectionEditor() {
    setState(() {
      _isReflectionEditorOpen = true;
      _statusBannerMessage = null;
      _errorBannerMessage = null;
    });
  }

  void _handleSaveReflection() {
    final title = _reflectionTitleController.text.trim();
    final body = _reflectionBodyController.text.trim();

    final titleErr = DiaryReflection.validateTitle(title);
    if (titleErr != null) {
      setState(() => _errorBannerMessage = titleErr);
      return;
    }

    final bodyErr = DiaryReflection.validateBody(body);
    if (bodyErr != null) {
      setState(() => _errorBannerMessage = bodyErr);
      return;
    }

    setState(() {
      _errorBannerMessage = null;
      final updated = _currentEntry.setReflection(
        title.isEmpty ? null : title,
        body,
      );
      _entriesByDateKey[_dateKey(_selectedDate)] = updated;
      _statusBannerMessage = 'Daily reflection saved to local draft.';
    });
  }

  void _handleRemoveReflection() {
    setState(() {
      _errorBannerMessage = null;
      final updated = _currentEntry.removeReflection();
      _entriesByDateKey[_dateKey(_selectedDate)] = updated;
      _reflectionTitleController.clear();
      _reflectionBodyController.clear();
      _isReflectionEditorOpen = false;
      _statusBannerMessage = 'Daily reflection removed from draft.';
    });
  }

  // ===========================================================================
  // PLAN CRUD ACTIONS
  // ===========================================================================

  void _handleStartAddPlan() {
    if (_currentEntry.plans.length >= ModuleDiaryEntry.maxPlansCount) {
      setState(() {
        _errorBannerMessage =
            'A daily entry cannot contain more than ${ModuleDiaryEntry.maxPlansCount} plans.';
      });
      return;
    }

    setState(() {
      _isEditingPlan = true;
      _editingPlanId = null;
      _planTitleController.clear();
      _planDescController.clear();
      _errorBannerMessage = null;
    });
  }

  void _handleStartEditPlan(DiaryPlan plan) {
    setState(() {
      _isEditingPlan = true;
      _editingPlanId = plan.id;
      _planTitleController.text = plan.title;
      _planDescController.text = plan.description ?? '';
      _errorBannerMessage = null;
    });
  }

  void _handleCancelPlanEdit() {
    setState(() {
      _isEditingPlan = false;
      _editingPlanId = null;
      _planTitleController.clear();
      _planDescController.clear();
    });
  }

  void _handleSavePlan() {
    final title = _planTitleController.text.trim();
    final desc = _planDescController.text.trim();

    final titleErr = DiaryPlan.validateTitle(title);
    if (titleErr != null) {
      setState(() => _errorBannerMessage = titleErr);
      return;
    }

    final descErr = DiaryPlan.validateDescription(desc);
    if (descErr != null) {
      setState(() => _errorBannerMessage = descErr);
      return;
    }

    setState(() {
      _errorBannerMessage = null;
      if (_editingPlanId == null) {
        // Adding new plan
        final newPlan = DiaryPlan.validated(
          id: const Uuid().v4(),
          title: title,
          description: desc.isEmpty ? null : desc,
        );
        final updated = _currentEntry.addPlan(newPlan);
        _entriesByDateKey[_dateKey(_selectedDate)] = updated;
        _statusBannerMessage = 'Daily plan added to local draft.';
      } else {
        // Updating existing plan
        final updated = _currentEntry.editPlan(
          _editingPlanId!,
          title,
          description: desc.isEmpty ? null : desc,
        );
        _entriesByDateKey[_dateKey(_selectedDate)] = updated;
        _statusBannerMessage = 'Daily plan updated.';
      }

      _isEditingPlan = false;
      _editingPlanId = null;
      _planTitleController.clear();
      _planDescController.clear();
    });
  }

  void _handleTogglePlan(String planId) {
    setState(() {
      final updated = _currentEntry.togglePlan(planId);
      _entriesByDateKey[_dateKey(_selectedDate)] = updated;
    });
  }

  void _handleRemovePlan(String planId) {
    setState(() {
      final updated = _currentEntry.removePlan(planId);
      _entriesByDateKey[_dateKey(_selectedDate)] = updated;
      _statusBannerMessage = 'Daily plan removed.';
    });
  }

  // ===========================================================================
  // DRAFT PRESERVATION
  // ===========================================================================

  void _handleSaveDraft() {
    final entry = _currentEntry;
    setState(() {
      _statusBannerMessage =
          'Diary entry saved locally. Remote repository persistence contract pending.';
      _errorBannerMessage = null;
    });
    widget.onSaveDraft?.call(entry);
  }

  // ===========================================================================
  // ACCESS VALIDATION
  // ===========================================================================

  bool get _hasAccess {
    if (widget.isAccessDenied) return false;
    if (widget.currentUserId.trim().isEmpty) return false;
    if (widget.currentUserId != widget.ownerModuleProfileId) return false;
    if (widget.module != 'learning') return false;
    return true;
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: widget.appBar ??
          const AndrilModuleAppBar(
            moduleName: 'Private Diary',
            badgeColor: LearningColors.primary,
          ),
      body: SafeArea(
        child: widget.isLoading
            ? _buildLoadingState()
            : !_hasAccess
                ? _buildAccessDeniedState()
                : _buildDiaryContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      key: Key('loading_indicator'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: LearningColors.primary),
          SizedBox(height: 16.0),
          Text(
            'Loading private diary...',
            style: TextStyle(
              color: LearningColors.secondaryText,
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          key: const Key('access_denied_card'),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: LearningColors.cardSurface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gpp_bad_outlined,
                  size: 48.0, color: Color(0xFFDC2626)),
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
                'You do not have permission to view or edit this private diary.',
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
    );
  }

  Widget _buildDiaryContent() {
    final entry = _currentEntry;
    final formattedDate = DateFormat('EEEE, MMMM d, y').format(_selectedDate);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with badges
          _buildHeaderRow(),
          const SizedBox(height: 14.0),

          // Date Navigation Bar
          _buildDateNavigationBar(formattedDate),
          const SizedBox(height: 14.0),

          // Status & Error Banners
          if (_errorBannerMessage != null) ...[
            _buildErrorBanner(),
            const SizedBox(height: 12.0),
          ],
          if (_statusBannerMessage != null) ...[
            _buildStatusBanner(),
            const SizedBox(height: 12.0),
          ],

          // Reflection Section
          _buildReflectionSection(entry),
          const SizedBox(height: 18.0),

          // Plans Section
          _buildPlansSection(entry),
          const SizedBox(height: 24.0),

          // Action Buttons
          _buildActionButtons(),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION WIDGETS
  // ===========================================================================

  Widget _buildHeaderRow() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8.0,
      runSpacing: 6.0,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: const Key('module_badge'),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: LearningColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                    color: LearningColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'LEARNING DIARY',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        Container(
          key: const Key('privacy_badge_private'),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline,
                  size: 11.5, color: LearningColors.secondaryText),
              SizedBox(width: 4.0),
              Text(
                'PRIVATE',
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.secondaryText,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateNavigationBar(String formattedDate) {
    return Container(
      key: const Key('calendar_navigation_bar'),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('prev_day_button'),
                icon: const Icon(Icons.chevron_left, size: 24.0),
                color: LearningColors.heading,
                tooltip: 'Previous Day',
                onPressed: _handlePrevDay,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _handleSelectDate,
                  child: Column(
                    children: [
                      Text(
                        formattedDate,
                        key: const Key('selected_date_display'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: LearningColors.heading,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Tap to change date',
                        style: TextStyle(
                          fontSize: 11.0,
                          color: LearningColors.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: const Key('next_day_button'),
                icon: const Icon(Icons.chevron_right, size: 24.0),
                color: LearningColors.heading,
                tooltip: 'Next Day',
                onPressed: _handleNextDay,
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12.0,
            runSpacing: 6.0,
            children: [
              TextButton.icon(
                key: const Key('today_button'),
                icon: const Icon(Icons.today, size: 16.0),
                label: const Text('Today'),
                style: TextButton.styleFrom(
                  foregroundColor: LearningColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _handleToday,
              ),
              OutlinedButton.icon(
                key: const Key('select_date_button'),
                icon: const Icon(Icons.calendar_month_outlined, size: 16.0),
                label: const Text('Pick Date'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                onPressed: _handleSelectDate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionSection(ModuleDiaryEntry entry) {
    return Container(
      key: const Key('reflection_section'),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note,
                      size: 20.0, color: LearningColors.primary),
                  SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      'Daily Reflection',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isReflectionEditorOpen && entry.reflection == null)
                TextButton.icon(
                  key: const Key('add_reflection_button'),
                  icon: const Icon(Icons.add, size: 16.0),
                  label: const Text('Add Reflection'),
                  onPressed: _handleOpenReflectionEditor,
                ),
            ],
          ),
          const SizedBox(height: 10.0),
          if (!_isReflectionEditorOpen && entry.reflection == null)
            Container(
              key: const Key('no_reflection_placeholder'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18.0),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.history_edu_outlined,
                      size: 32.0, color: Color(0xFF94A3B8)),
                  SizedBox(height: 6.0),
                  Text(
                    'No reflection recorded for this day.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: LearningColors.secondaryText,
                    ),
                  ),
                ],
              ),
            )
          else
            _buildReflectionCard(entry),
        ],
      ),
    );
  }

  Widget _buildReflectionCard(ModuleDiaryEntry entry) {
    return Container(
      key: const Key('reflection_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: const Key('diary_reflection_title_input'),
            controller: _reflectionTitleController,
            maxLength: DiaryReflection.maxTitleLength,
            decoration: const InputDecoration(
              labelText: 'Reflection Title (Optional)',
              hintText: 'e.g. Insights from System Design Study',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10.0),
          TextFormField(
            key: const Key('diary_reflection_body_input'),
            controller: _reflectionBodyController,
            maxLines: 5,
            maxLength: DiaryReflection.maxBodyLength,
            decoration: const InputDecoration(
              labelText: 'Reflection Body *',
              hintText: 'Write your thoughts and learnings for the day...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ElevatedButton.icon(
                key: const Key('save_reflection_button'),
                icon: const Icon(Icons.check, size: 16.0),
                label: const Text('Save Reflection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _handleSaveReflection,
              ),
              if (entry.reflection != null)
                OutlinedButton.icon(
                  key: const Key('remove_reflection_button'),
                  icon: const Icon(Icons.delete_outline, size: 16.0),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                  ),
                  onPressed: _handleRemoveReflection,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection(ModuleDiaryEntry entry) {
    final plans = entry.plans;

    return Container(
      key: const Key('plans_section'),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              Text(
                'Daily Plans (${plans.length}/${ModuleDiaryEntry.maxPlansCount})',
                key: const Key('plans_section_header'),
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              ElevatedButton.icon(
                key: const Key('add_plan_button'),
                icon: const Icon(Icons.add, size: 16.0),
                label: const Text('Add Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: plans.length >= ModuleDiaryEntry.maxPlansCount
                    ? null
                    : _handleStartAddPlan,
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Plan input form when active
          if (_isEditingPlan) ...[
            _buildPlanForm(),
            const SizedBox(height: 14.0),
          ],

          // Plans list or empty state
          if (plans.isEmpty && !_isEditingPlan)
            Container(
              key: const Key('empty_plans_card'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.checklist_outlined,
                      size: 32.0, color: Color(0xFF94A3B8)),
                  SizedBox(height: 6.0),
                  Text(
                    'No plans added for this day.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: LearningColors.secondaryText,
                    ),
                  ),
                ],
              ),
            )
          else
            ...plans.asMap().entries.map((e) {
              final idx = e.key;
              final plan = e.value;
              return _buildPlanCard(idx, plan);
            }),
        ],
      ),
    );
  }

  Widget _buildPlanForm() {
    return Container(
      key: const Key('plan_form_card'),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.0),
        border:
            Border.all(color: LearningColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editingPlanId == null ? 'New Daily Plan' : 'Edit Daily Plan',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            key: const Key('plan_title_input'),
            controller: _planTitleController,
            maxLength: DiaryPlan.maxTitleLength,
            decoration: const InputDecoration(
              labelText: 'Plan Title *',
              hintText: 'e.g. Complete Flutter CI integration',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            key: const Key('plan_desc_input'),
            controller: _planDescController,
            maxLength: DiaryPlan.maxDescriptionLength,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'e.g. Ensure all tests and classifier pass',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8.0,
            runSpacing: 6.0,
            children: [
              TextButton(
                key: const Key('cancel_plan_button'),
                onPressed: _handleCancelPlanEdit,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                key: const Key('save_plan_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _handleSavePlan,
                child: Text(_editingPlanId == null ? 'Add' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index, DiaryPlan plan) {
    return Container(
      key: Key('diary_plan_${plan.id}'),
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: plan.isCompleted
            ? const Color(0xFFF1F5F9)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            key: Key('plan_checkbox_${plan.id}'),
            value: plan.isCompleted,
            activeColor: LearningColors.primary,
            onChanged: (_) => _handleTogglePlan(plan.id),
          ),
          const SizedBox(width: 6.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  key: Key('plan_title_${plan.id}'),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: plan.isCompleted
                        ? LearningColors.secondaryText
                        : LearningColors.heading,
                    decoration:
                        plan.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (plan.description != null &&
                    plan.description!.isNotEmpty) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    plan.description!,
                    key: Key('plan_desc_${plan.id}'),
                    style: TextStyle(
                      fontSize: 12.0,
                      color: LearningColors.secondaryText,
                      decoration:
                          plan.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            key: Key('edit_plan_${plan.id}'),
            icon: const Icon(Icons.edit_outlined, size: 18.0),
            color: LearningColors.secondaryText,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _handleStartEditPlan(plan),
          ),
          IconButton(
            key: Key('delete_plan_${plan.id}'),
            icon: const Icon(Icons.delete_outline, size: 18.0),
            color: const Color(0xFFEF4444),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _handleRemovePlan(plan.id),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: const Key('save_diary_draft_button'),
        icon: const Icon(Icons.save_outlined),
        label: const Text(
          'Save Diary Draft',
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
        onPressed: _handleSaveDraft,
      ),
    );
  }

  // ===========================================================================
  // BANNERS
  // ===========================================================================

  Widget _buildStatusBanner() {
    return Container(
      key: const Key('status_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10.0),
        border:
            Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF059669), size: 20.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              _statusBannerMessage!,
              style: const TextStyle(
                color: Color(0xFF065F46),
                fontSize: 12.5,
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
        border:
            Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 20.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              _errorBannerMessage!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12.5,
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
}
