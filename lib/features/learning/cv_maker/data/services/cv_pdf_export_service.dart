import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import 'package:andril_mobile/features/learning/cv_maker/data/services/cv_pdf_generator.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/entities/cv_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/entities/cv_pdf_export_result.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/services/i_cv_pdf_export_service.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';

/// Concrete implementation of [ICvPdfExportService] for private, owner-scoped CV export.
///
/// Features:
/// 1. Enforces private, owner-scoped export authorization (CV-01).
/// 2. Validates session status; fails closed if revoked or expired.
/// 3. Generates genuine multi-page PDF documents across Modern, Professional, and Creative templates.
/// 4. Manages secure local temporary files and provides automated cleanup.
class CvPdfExportService implements ICvPdfExportService {
  final CvPdfGenerator _generator;

  /// Optional injector for temporary directory resolution (useful for tests).
  final Future<String> Function()? _tempDirProvider;

  const CvPdfExportService({
    CvPdfGenerator generator = const CvPdfGenerator(),
    Future<String> Function()? tempDirProvider,
  })  : _generator = generator,
        _tempDirProvider = tempDirProvider;

  @override
  Future<CvPdfExportResult> exportCvToPdf(
    CvDraftData draft, {
    CvPdfExportOptions? options,
    String? currentUserId,
  }) async {
    final opts = options ?? CvPdfExportOptions.fromDraft(draft);

    // 1. Session revocation & activity check
    if (!opts.isSessionActive) {
      throw const CvPdfExportAccessDeniedException(
        'Session is revoked or expired. Please re-authenticate to export your CV.',
      );
    }

    // 2. Owner-scoped authorization check
    if (opts.ownerUserId != null &&
        currentUserId != null &&
        opts.ownerUserId != currentUserId) {
      throw const CvPdfExportAccessDeniedException(
        'Access denied: You can only export CV documents that you own.',
      );
    }

    // 3. Draft data validation
    if (draft.fullName.trim().isEmpty) {
      throw const CvPdfExportException(
        'Cannot export CV: Candidate full name is required.',
      );
    }

    // 4. Generate PDF bytes and page count
    final metadata =
        await _generator.generateWithMetadata(draft, options: opts);
    final bytes = metadata.bytes;
    final pageCount = metadata.pageCount;

    // 5. Secure temporary file persistence
    final tempDirPath = await _resolveTempDirPath();
    final baseName =
        opts.customFileName ?? CvPdfExportOptions.sanitizeFileName(draft.title);
    final fileName = '${baseName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final targetPath = '$tempDirPath${Platform.pathSeparator}$fileName';

    String? savedFilePath;
    try {
      final file = File(targetPath);
      await file.writeAsBytes(bytes, flush: true);
      savedFilePath = file.path;
    } catch (_) {
      // In constrained environments where disk writing fails, fall back to memory-only
      savedFilePath = null;
    }

    return CvPdfExportResult(
      pdfBytes: bytes,
      fileName: fileName,
      pageCount: pageCount,
      fileSizeBytes: bytes.lengthInBytes,
      filePath: savedFilePath,
      generatedAt: DateTime.now(),
      templateUsed: opts.template,
      contactInfoIncluded: opts.includeContactInfo,
    );
  }

  @override
  Future<Uint8List> generatePdfBytes(
    CvDraftData draft, {
    CvPdfExportOptions? options,
  }) async {
    return _generator.generate(draft, options: options);
  }

  @override
  Future<int> cleanupTempFiles() async {
    try {
      final tempDirPath = await _resolveTempDirPath();
      final dir = Directory(tempDirPath);
      if (!await dir.exists()) return 0;

      int deletedCount = 0;
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          // Check if file is an exported CV
          final name = entity.uri.pathSegments.last;
          if (name.contains('_') && name.endsWith('.pdf')) {
            try {
              entity.deleteSync();
              deletedCount++;
            } catch (_) {}
          }
        }
      }
      return deletedCount;
    } catch (_) {
      return 0;
    }
  }

  Future<String> _resolveTempDirPath() async {
    if (_tempDirProvider != null) {
      return await _tempDirProvider();
    }
    try {
      final dir = await getTemporaryDirectory();
      return dir.path;
    } catch (_) {
      // Fallback for headless tests and desktop environments
      return Directory.systemTemp.path;
    }
  }
}
