import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/data/services/portfolio_cv_import_service.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_cv_import_result.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/services/i_portfolio_cv_import_service.dart';

/// Modal bottom sheet allowing users to select projects from their portfolio
/// and import them into an owned CV draft after explicit user review and confirmation.
///
/// Implements LRN-06 / PORT-01..05 & CV-01..05.
class PortfolioCvImportSheet extends StatefulWidget {
  final LearningPortfolio portfolio;
  final CvDraftData? targetCv;
  final IPortfolioCvImportService importService;
  final String currentUserId;
  final ValueChanged<PortfolioCvImportResult>? onImportSuccess;

  const PortfolioCvImportSheet({
    super.key,
    required this.portfolio,
    this.targetCv,
    this.importService = const PortfolioCvImportService(),
    this.currentUserId = 'current_user_default',
    this.onImportSuccess,
  });

  /// Displays the CV import sheet as a modal bottom sheet.
  static Future<PortfolioCvImportResult?> show(
    BuildContext context, {
    required LearningPortfolio portfolio,
    CvDraftData? targetCv,
    IPortfolioCvImportService importService = const PortfolioCvImportService(),
    String currentUserId = 'current_user_default',
    ValueChanged<PortfolioCvImportResult>? onImportSuccess,
  }) {
    return showModalBottomSheet<PortfolioCvImportResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PortfolioCvImportSheet(
        portfolio: portfolio,
        targetCv: targetCv,
        importService: importService,
        currentUserId: currentUserId,
        onImportSuccess: onImportSuccess,
      ),
    );
  }

  @override
  State<PortfolioCvImportSheet> createState() => _PortfolioCvImportSheetState();
}

class _PortfolioCvImportSheetState extends State<PortfolioCvImportSheet> {
  late final Set<String> _selectedProjectIds;
  late final CvDraftData _targetCv;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAccessDenied = false;
  PortfolioCvImportResult? _importResult;

  @override
  void initState() {
    super.initState();
    // Default to selecting all projects initially for user convenience
    _selectedProjectIds = widget.portfolio.projects.map((p) => p.id).toSet();
    _targetCv = widget.targetCv ??
        CvDraftData.syntheticSample(
          title: 'My Professional CV',
        );
  }

  void _toggleProject(String id) {
    setState(() {
      if (_selectedProjectIds.contains(id)) {
        _selectedProjectIds.remove(id);
      } else {
        _selectedProjectIds.add(id);
      }
      _errorMessage = null;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedProjectIds.length == widget.portfolio.projects.length) {
        _selectedProjectIds.clear();
      } else {
        _selectedProjectIds.addAll(widget.portfolio.projects.map((p) => p.id));
      }
      _errorMessage = null;
    });
  }

  Future<void> _handleConfirmImport() async {
    if (_selectedProjectIds.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one project to import.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isAccessDenied = false;
    });

    try {
      final result = await widget.importService.importProjectsIntoCv(
        portfolio: widget.portfolio,
        selectedProjectIds: _selectedProjectIds.toList(),
        targetCv: _targetCv,
        currentUserId: widget.currentUserId,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _importResult = result;
      });

      widget.onImportSuccess?.call(result);
    } on PortfolioCvImportAccessDeniedException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isAccessDenied = true;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            e is PortfolioCvImportException ? e.message : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LearningColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      padding: EdgeInsets.only(
        top: 20.0,
        left: 20.0,
        right: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Header Title
            Row(
              children: [
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: LearningColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Icons.import_contacts_outlined,
                    color: LearningColors.primary,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Projects into CV',
                        style: TextStyle(
                          color: LearningColors.heading,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Select portfolio projects to feature in your CV draft',
                        style: TextStyle(
                          color: LearningColors.secondaryText,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('btn_close_import_sheet'),
                  icon: const Icon(Icons.close_rounded),
                  color: LearningColors.secondaryText,
                  onPressed: () => Navigator.of(context).pop(_importResult),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // State Banners
            if (_isLoading) ...[
              _buildLoadingState(),
              const SizedBox(height: 16.0),
            ] else if (_isAccessDenied) ...[
              _buildAccessDeniedBanner(),
              const SizedBox(height: 16.0),
            ] else if (_errorMessage != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: 16.0),
            ] else if (_importResult != null) ...[
              _buildSuccessBanner(),
              const SizedBox(height: 16.0),
            ],

            // Project Selection & Review (only show if not finished)
            if (_importResult == null && !_isLoading) ...[
              _buildTargetCvReviewCard(),
              const SizedBox(height: 16.0),
              _buildProjectSelectionList(),
              const SizedBox(height: 20.0),
            ],

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      key: const Key('import_loading_indicator'),
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      alignment: Alignment.center,
      child: const Column(
        children: [
          CircularProgressIndicator(
            color: LearningColors.primary,
          ),
          SizedBox(height: 14.0),
          Text(
            'Importing Selected Projects...',
            style: TextStyle(
              color: LearningColors.heading,
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.0),
          Text(
            'Converting portfolio projects to CV entries and preserving existing content',
            style: TextStyle(
              color: LearningColors.secondaryText,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDeniedBanner() {
    return Container(
      key: const Key('import_denied_banner'),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFFDC2626),
            size: 20.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Import Access Denied',
                  style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  _errorMessage ??
                      'You do not have authorization to import from this private Portfolio.',
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      key: const Key('import_error_banner'),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 20.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Import Failed',
                  style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  _errorMessage ??
                      'An unexpected error occurred during project import.',
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    final result = _importResult!;
    return Container(
      key: const Key('import_success_banner'),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 22.0,
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Projects Successfully Imported!',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          _buildInfoRow('Target CV', result.updatedCv.title),
          _buildInfoRow('Imported', '${result.importedCount} project(s) added'),
          _buildInfoRow('Total CV Projects',
              '${result.totalCvProjects} projects now in CV'),
          _buildInfoRow(
            'Titles',
            result.importedProjectTitles.join(', '),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105.0,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF047857),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF065F46),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCvReviewCard() {
    final willHaveTotal =
        _targetCv.projects.length + _selectedProjectIds.length;
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: LearningColors.secondaryText.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Target CV Draft Review',
                style: TextStyle(
                  color: LearningColors.heading,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: const Text(
                  'OWNED DRAFT',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 9.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          _buildReviewRow(
              Icons.description_outlined, 'Target CV', _targetCv.title),
          _buildReviewRow(Icons.folder_open_outlined, 'Existing CV Projects',
              '${_targetCv.projects.length}'),
          _buildReviewRow(Icons.add_circle_outline, 'Projects to Import',
              '${_selectedProjectIds.length}'),
          _buildReviewRow(Icons.all_inbox_outlined, 'Resulting Total Projects',
              '$willHaveTotal'),
        ],
      ),
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 14.0, color: LearningColors.secondaryText),
          const SizedBox(width: 8.0),
          Text(
            '$label: ',
            style: const TextStyle(
              color: LearningColors.secondaryText,
              fontSize: 11.5,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: LearningColors.heading,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSelectionList() {
    final allCount = widget.portfolio.projects.length;
    final selectedCount = _selectedProjectIds.length;
    final allSelected = allCount > 0 && selectedCount == allCount;

    return Material(
      color: LearningColors.cardSurface,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: LearningColors.secondaryText.withValues(alpha: 0.12),
          ),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Projects ($selectedCount / $allCount)',
                  style: const TextStyle(
                    color: LearningColors.heading,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  key: const Key('btn_toggle_select_all'),
                  onPressed: _toggleSelectAll,
                  child: Text(
                    allSelected ? 'Deselect All' : 'Select All',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
              ],
            ),
            const Divider(height: 1.0),
            if (widget.portfolio.projects.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'This portfolio contains no projects to import.',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: LearningColors.secondaryText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ...widget.portfolio.projects.map((proj) {
                final isSelected = _selectedProjectIds.contains(proj.id);
                return CheckboxListTile(
                  key: Key('checkbox_project_${proj.id}'),
                  title: Text(
                    proj.title ?? 'Untitled Project',
                    style: const TextStyle(
                      color: LearningColors.heading,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: proj.description != null
                      ? Text(
                          proj.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: LearningColors.secondaryText,
                            fontSize: 11.0,
                          ),
                        )
                      : null,
                  value: isSelected,
                  activeColor: LearningColors.primary,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (_) => _toggleProject(proj.id),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_importResult != null) {
      return SizedBox(
        width: double.infinity,
        height: 48.0,
        child: ElevatedButton.icon(
          key: const Key('btn_done_cv_import'),
          onPressed: () => Navigator.of(context).pop(_importResult),
          icon: const Icon(Icons.check_rounded, size: 18.0),
          label: const Text(
            'Done',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('btn_cancel_cv_import'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            key: const Key('btn_confirm_cv_import'),
            onPressed: _isLoading || _selectedProjectIds.isEmpty
                ? null
                : _handleConfirmImport,
            icon: const Icon(Icons.check_circle_outline, size: 18.0),
            label: Text(
              'Import (${_selectedProjectIds.length}) Projects',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: LearningColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
