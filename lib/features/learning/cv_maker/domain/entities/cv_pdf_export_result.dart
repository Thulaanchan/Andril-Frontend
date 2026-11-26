import 'package:flutter/foundation.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';

/// Encapsulates the verified result of a CV PDF export operation per ANDRIL LRN-05 & CV-01..05.
@immutable
class CvPdfExportResult {
  /// The raw generated PDF byte buffer.
  final Uint8List pdfBytes;

  /// The generated safe file name (including `.pdf` extension).
  final String fileName;

  /// The total page count of the generated document.
  final int pageCount;

  /// File size in bytes.
  final int fileSizeBytes;

  /// The local absolute file path if saved locally in temporary storage, or null if memory-only.
  final String? filePath;

  /// Timestamp when the document was generated.
  final DateTime generatedAt;

  /// The template layout applied during rendering.
  final CvTemplate templateUsed;

  /// Whether contact information was included based on explicit user consent.
  final bool contactInfoIncluded;

  const CvPdfExportResult({
    required this.pdfBytes,
    required this.fileName,
    required this.pageCount,
    required this.fileSizeBytes,
    this.filePath,
    required this.generatedAt,
    required this.templateUsed,
    required this.contactInfoIncluded,
  });

  /// Validates whether the raw bytes start with standard PDF magic number (`%PDF-`).
  bool get isValidPdf {
    if (pdfBytes.length < 5) return false;
    // %PDF- magic bytes: [0x25, 0x50, 0x44, 0x46, 0x2D]
    return pdfBytes[0] == 0x25 &&
        pdfBytes[1] == 0x50 &&
        pdfBytes[2] == 0x44 &&
        pdfBytes[3] == 0x46 &&
        pdfBytes[4] == 0x2D;
  }

  /// Formatted human-readable file size string (e.g. `124 KB`).
  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
