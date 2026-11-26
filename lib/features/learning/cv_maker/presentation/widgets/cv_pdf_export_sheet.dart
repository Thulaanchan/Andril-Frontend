import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/features/learning/cv_maker/data/services/cv_pdf_export_service.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/entities/cv_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/entities/cv_pdf_export_result.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/services/i_cv_pdf_export_service.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';

/// Modal bottom sheet for configuring and executing private, owner-scoped CV PDF export.
///
/// Features:
/// 1. Explicit contact information privacy consent toggle (CV-03).
/// 2. Clear state handling: idle, loading, success, access denied, and error.
/// 3. Display of template, file size, page count, and export timestamp.
/// 4. Integration with [ICvPdfExportService].
class CvPdfExportSheet extends StatefulWidget {
  final CvDraftData draft;
  final ICvPdfExportService exportService;
  final String? currentUserId;
  final ValueChanged<CvPdfExportResult>? onExportSuccess;

  const CvPdfExportSheet({
    super.key,
    required this.draft,
    this.exportService = const CvPdfExportService(),
    this.currentUserId,
    this.onExportSuccess,
  });

  /// Displays the export sheet as a modal bottom sheet.
  static Future<CvPdfExportResult?> show(
    BuildContext context, {
    required CvDraftData draft,
    ICvPdfExportService exportService = const CvPdfExportService(),
    String? currentUserId,
    ValueChanged<CvPdfExportResult>? onExportSuccess,
  }) {
    return showModalBottomSheet<CvPdfExportResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CvPdfExportSheet(
        draft: draft,
        exportService: exportService,
        currentUserId: currentUserId,
        onExportSuccess: onExportSuccess,
      ),
    );
  }

  @override
  State<CvPdfExportSheet> createState() => _CvPdfExportSheetState();
}

class _CvPdfExportSheetState extends State<CvPdfExportSheet> {
  late bool _includeContactInfo;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAccessDenied = false;
  CvPdfExportResult? _exportResult;

  @override
  void initState() {
    super.initState();
    // Default to true if user has enabled any contact visibility, else false
    _includeContactInfo = widget.draft.showEmail ||
        widget.draft.showPhone ||
        widget.draft.showLocation ||
        widget.draft.showWebsite;
  }

  Future<void> _handleExport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isAccessDenied = false;
    });

    try {
      final options = CvPdfExportOptions.fromDraft(
        widget.draft,
        includeContactInfo: _includeContactInfo,
        ownerUserId: widget.currentUserId,
      );

      final result = await widget.exportService.exportCvToPdf(
        widget.draft,
        options: options,
        currentUserId: widget.currentUserId,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _exportResult = result;
      });

      widget.onExportSuccess?.call(result);
    } on CvPdfExportAccessDeniedException catch (e) {
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
        _errorMessage = e is CvPdfExportException ? e.message : e.toString();
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
                    color: widget.draft.selectedTemplate.badgeBackgroundColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: widget.draft.selectedTemplate.accentColor,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Export CV as PDF',
                        style: TextStyle(
                          color: LearningColors.heading,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Template: ${widget.draft.selectedTemplate.displayName} • Private Document',
                        style: TextStyle(
                          color: widget.draft.selectedTemplate.accentColor,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('btn_close_sheet'),
                  icon: const Icon(Icons.close_rounded),
                  color: LearningColors.secondaryText,
                  onPressed: () => Navigator.of(context).pop(_exportResult),
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
            ] else if (_exportResult != null) ...[
              _buildSuccessBanner(),
              const SizedBox(height: 16.0),
            ],

            // Export Options Card (only show if not in success state)
            if (_exportResult == null && !_isLoading) ...[
              _buildPrivacyConsentCard(),
              const SizedBox(height: 16.0),
              _buildDocumentSummaryCard(),
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
      key: const Key('export_loading_indicator'),
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          CircularProgressIndicator(
            color: widget.draft.selectedTemplate.accentColor,
          ),
          const SizedBox(height: 14.0),
          const Text(
            'Generating PDF Document...',
            style: TextStyle(
              color: LearningColors.heading,
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4.0),
          const Text(
            'Rendering structured sections and calculating page pagination',
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
      key: const Key('export_denied_banner'),
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
                  'Export Access Denied',
                  style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  _errorMessage ??
                      'You do not have authorization to export this private CV.',
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
      key: const Key('export_error_banner'),
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
                  'Export Failed',
                  style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  _errorMessage ??
                      'An unexpected error occurred during export.',
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
    final result = _exportResult!;
    return Container(
      key: const Key('export_success_banner'),
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
                  'PDF Export Successful!',
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
          _buildInfoRow('File Name', result.fileName),
          _buildInfoRow('Pages', '${result.pageCount} page(s)'),
          _buildInfoRow('Size', result.formattedFileSize),
          _buildInfoRow('Template', result.templateUsed.displayName),
          _buildInfoRow(
            'Contact Info',
            result.contactInfoIncluded
                ? 'Included (Consent Given)'
                : 'Omitted (Privacy Protected)',
          ),
          if (result.filePath != null)
            _buildInfoRow(
                'Location', 'Saved locally to secure temporary storage'),
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
            width: 90.0,
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

  Widget _buildPrivacyConsentCard() {
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
        child: SwitchListTile(
          key: const Key('consent_contact_toggle'),
          title: const Text(
            'Include Contact Information',
            style: TextStyle(
              color: LearningColors.heading,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: const Text(
            'Includes email, phone, location & website per your privacy settings. Turn off for anonymous / blind review submissions.',
            style: TextStyle(
              color: LearningColors.secondaryText,
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
          value: _includeContactInfo,
          activeThumbColor: widget.draft.selectedTemplate.accentColor,
          onChanged: (val) => setState(() => _includeContactInfo = val),
        ),
      ),
    );
  }

  Widget _buildDocumentSummaryCard() {
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
          const Text(
            'Document Summary',
            style: TextStyle(
              color: LearningColors.heading,
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8.0),
          _buildSummaryItem(
              Icons.person_outline, 'Candidate', widget.draft.fullName),
          _buildSummaryItem(Icons.work_outline, 'Experiences',
              '${widget.draft.experiences.length} positions'),
          _buildSummaryItem(Icons.school_outlined, 'Education',
              '${widget.draft.education.length} entries'),
          _buildSummaryItem(Icons.psychology_outlined, 'Skills',
              '${widget.draft.skills.length} competencies'),
          _buildSummaryItem(Icons.verified_outlined, 'Certifications',
              '${widget.draft.certifications.length} credentials'),
          _buildSummaryItem(Icons.folder_outlined, 'Projects',
              '${widget.draft.projects.length} featured'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
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

  Widget _buildActionButtons() {
    if (_exportResult != null) {
      return SizedBox(
        width: double.infinity,
        height: 48.0,
        child: ElevatedButton.icon(
          key: const Key('btn_close_export'),
          onPressed: () => Navigator.of(context).pop(_exportResult),
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

    if (_errorMessage != null || _isAccessDenied) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('btn_cancel_export'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: ElevatedButton.icon(
              key: const Key('btn_retry_export'),
              onPressed: _handleExport,
              icon: const Icon(Icons.refresh_rounded, size: 18.0),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.draft.selectedTemplate.accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: ElevatedButton.icon(
        key: const Key('btn_confirm_export'),
        onPressed: _isLoading ? null : _handleExport,
        icon: const Icon(Icons.download_rounded, size: 20.0),
        label: const Text(
          'Generate & Export PDF',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.draft.selectedTemplate.accentColor,
          foregroundColor: Colors.white,
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }
}
