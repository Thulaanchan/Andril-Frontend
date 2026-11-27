import 'package:flutter/foundation.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';

/// Exception thrown when CV project import is denied due to authentication,
/// ownership validation, module boundary violations, or session revocation.
class PortfolioCvImportAccessDeniedException implements Exception {
  final String message;
  const PortfolioCvImportAccessDeniedException([
    this.message =
        'Access denied: You are not authorized to import projects into this CV.',
  ]);

  @override
  String toString() => 'PortfolioCvImportAccessDeniedException: $message';
}

/// Generic exception thrown when CV project import fails.
class PortfolioCvImportException implements Exception {
  final String message;
  final Object? cause;
  const PortfolioCvImportException(this.message, [this.cause]);

  @override
  String toString() =>
      'PortfolioCvImportException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Encapsulates the verified result of importing selected portfolio projects into a CV draft.
@immutable
class PortfolioCvImportResult {
  /// The updated CV draft data with imported projects appended.
  final CvDraftData updatedCv;

  /// The count of newly imported projects.
  final int importedCount;

  /// The list of project titles that were successfully imported.
  final List<String> importedProjectTitles;

  /// The total project count in the CV after import.
  final int totalCvProjects;

  /// Timestamp of the import operation.
  final DateTime importedAt;

  const PortfolioCvImportResult({
    required this.updatedCv,
    required this.importedCount,
    required this.importedProjectTitles,
    required this.totalCvProjects,
    required this.importedAt,
  });
}
