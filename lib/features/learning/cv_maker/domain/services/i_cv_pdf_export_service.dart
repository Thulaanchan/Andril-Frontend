import 'dart:typed_data';
import 'package:andril_mobile/features/learning/cv_maker/domain/entities/cv_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/entities/cv_pdf_export_result.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';

/// Exception thrown when CV PDF export is denied due to authentication, authorization,
/// or session revocation failure.
class CvPdfExportAccessDeniedException implements Exception {
  final String message;
  const CvPdfExportAccessDeniedException([
    this.message =
        'Access denied: You are not authorized to export this private CV document.',
  ]);

  @override
  String toString() => 'CvPdfExportAccessDeniedException: $message';
}

/// Generic exception thrown when CV PDF export fails during generation or file persistence.
class CvPdfExportException implements Exception {
  final String message;
  final Object? cause;
  const CvPdfExportException(this.message, [this.cause]);

  @override
  String toString() =>
      'CvPdfExportException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Contract for private, owner-scoped CV PDF export services per ANDRIL LRN-05 & CV-01..05.
abstract class ICvPdfExportService {
  /// Exports the given [draft] into a full [CvPdfExportResult], respecting privacy consent
  /// and owner authorization.
  Future<CvPdfExportResult> exportCvToPdf(
    CvDraftData draft, {
    CvPdfExportOptions? options,
    String? currentUserId,
  });

  /// Generates pure PDF bytes in memory for the given [draft].
  Future<Uint8List> generatePdfBytes(
    CvDraftData draft, {
    CvPdfExportOptions? options,
  });

  /// Deletes temporary exported PDF files created during previous export sessions.
  Future<int> cleanupTempFiles();
}
