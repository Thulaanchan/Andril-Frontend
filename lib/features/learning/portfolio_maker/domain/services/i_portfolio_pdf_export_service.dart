import 'dart:typed_data';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_pdf_export_result.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';

/// Exception thrown when Portfolio PDF export is denied due to authentication, authorization,
/// ownership mismatch, or session revocation failure.
class PortfolioPdfExportAccessDeniedException implements Exception {
  final String message;
  const PortfolioPdfExportAccessDeniedException([
    this.message =
        'Access denied: You are not authorized to export this private Portfolio document.',
  ]);

  @override
  String toString() => 'PortfolioPdfExportAccessDeniedException: $message';
}

/// Generic exception thrown when Portfolio PDF export fails during generation or file persistence.
class PortfolioPdfExportException implements Exception {
  final String message;
  final Object? cause;
  const PortfolioPdfExportException(this.message, [this.cause]);

  @override
  String toString() =>
      'PortfolioPdfExportException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Contract for private, owner-scoped Portfolio PDF export services
/// per ANDRIL LRN-06 & PORT-01..05.
abstract class IPortfolioPdfExportService {
  /// Exports the given [portfolio] into a full [PortfolioPdfExportResult],
  /// enforcing owner-scoped authorization and session validity.
  Future<PortfolioPdfExportResult> exportPortfolioToPdf(
    LearningPortfolio portfolio, {
    PortfolioPdfExportOptions? options,
    String? currentUserId,
  });

  /// Generates pure PDF bytes in memory for the given [portfolio].
  Future<Uint8List> generatePdfBytes(
    LearningPortfolio portfolio, {
    PortfolioPdfExportOptions? options,
  });

  /// Deletes temporary exported PDF files created during previous export sessions.
  Future<int> cleanupTempFiles();
}
