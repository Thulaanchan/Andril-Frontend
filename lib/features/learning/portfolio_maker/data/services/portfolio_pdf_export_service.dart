import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import 'package:andril_mobile/features/learning/portfolio_maker/data/services/portfolio_pdf_generator.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_pdf_export_result.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/services/i_portfolio_pdf_export_service.dart';

/// Concrete implementation of [IPortfolioPdfExportService] for private, owner-scoped Portfolio export.
///
/// Features:
/// 1. Enforces private, owner-scoped export authorization (PORT-01..05).
/// 2. Validates session status; fails closed if revoked or expired.
/// 3. Validates module isolation strictly to 'learning'.
/// 4. Generates genuine multi-page PDF documents across Developer, Creative, and Professional templates.
/// 5. Manages secure local temporary files and provides automated cleanup.
class PortfolioPdfExportService implements IPortfolioPdfExportService {
  final PortfolioPdfGenerator _generator;

  /// Optional injector for temporary directory resolution (useful for tests).
  final Future<String> Function()? _tempDirProvider;

  const PortfolioPdfExportService({
    PortfolioPdfGenerator generator = const PortfolioPdfGenerator(),
    Future<String> Function()? tempDirProvider,
  })  : _generator = generator,
        _tempDirProvider = tempDirProvider;

  @override
  Future<PortfolioPdfExportResult> exportPortfolioToPdf(
    LearningPortfolio portfolio, {
    PortfolioPdfExportOptions? options,
    String? currentUserId,
  }) async {
    final opts = options ?? PortfolioPdfExportOptions.fromPortfolio(portfolio);

    // 1. Session revocation & activity check
    if (!opts.isSessionActive) {
      throw const PortfolioPdfExportAccessDeniedException(
        'Session is revoked or expired. Please re-authenticate to export your Portfolio.',
      );
    }

    // 2. Module isolation check
    if (portfolio.module != 'learning') {
      throw const PortfolioPdfExportAccessDeniedException(
        'Access denied: Portfolio must belong to the learning module.',
      );
    }

    // 3. Owner-scoped authorization check
    final effectiveUserId = currentUserId ?? opts.ownerUserId;
    if (effectiveUserId != null &&
        portfolio.ownerLearningProfileId.isNotEmpty &&
        portfolio.ownerLearningProfileId != effectiveUserId) {
      throw const PortfolioPdfExportAccessDeniedException(
        'Access denied: You can only export portfolio documents that you own.',
      );
    }

    if (opts.ownerUserId != null &&
        currentUserId != null &&
        opts.ownerUserId != currentUserId) {
      throw const PortfolioPdfExportAccessDeniedException(
        'Access denied: You can only export portfolio documents that you own.',
      );
    }

    // 4. Portfolio title validation
    if (portfolio.title.trim().isEmpty) {
      throw const PortfolioPdfExportException(
        'Cannot export Portfolio: Document title is required.',
      );
    }

    // 5. Generate PDF bytes and page count
    final metadata =
        await _generator.generateWithMetadata(portfolio, options: opts);
    final bytes = metadata.bytes;
    final pageCount = metadata.pageCount;

    // 6. Secure temporary file persistence
    final tempDirPath = await _resolveTempDirPath();
    final baseName = opts.customFileName ??
        PortfolioPdfExportOptions.sanitizeFileName(portfolio.title);
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

    return PortfolioPdfExportResult(
      pdfBytes: bytes,
      fileName: fileName,
      pageCount: pageCount,
      fileSizeBytes: bytes.lengthInBytes,
      filePath: savedFilePath,
      generatedAt: DateTime.now(),
      templateUsed: opts.template,
      projectCount: portfolio.projects.length,
    );
  }

  @override
  Future<Uint8List> generatePdfBytes(
    LearningPortfolio portfolio, {
    PortfolioPdfExportOptions? options,
  }) async {
    return _generator.generate(portfolio, options: options);
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
