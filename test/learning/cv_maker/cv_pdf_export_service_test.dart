import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/features/learning/cv_maker/data/services/cv_pdf_export_service.dart';
import 'package:andril_mobile/features/learning/cv_maker/data/services/cv_pdf_generator.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/entities/cv_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/services/i_cv_pdf_export_service.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';

void main() {
  group('CvPdfExportService Unit Tests (LRN-05 & CV-01..05)', () {
    late CvPdfExportService service;
    late CvDraftData sampleDraft;
    late Directory tempTestDir;

    setUp(() async {
      tempTestDir = await Directory.systemTemp.createTemp('andril_cv_test_');
      service = CvPdfExportService(
        generator: const CvPdfGenerator(),
        tempDirProvider: () async => tempTestDir.path,
      );
      sampleDraft = CvDraftData.syntheticSample();
    });

    tearDown(() async {
      if (await tempTestDir.exists()) {
        await tempTestDir.delete(recursive: true);
      }
    });

    test(
        'TEST-SVC-01: Successful export generates valid result with file on disk',
        () async {
      final result = await service.exportCvToPdf(
        sampleDraft,
        currentUserId: 'user_123',
        options: const CvPdfExportOptions(
          ownerUserId: 'user_123',
          isSessionActive: true,
        ),
      );

      expect(result.isValidPdf, isTrue);
      expect(result.pageCount, greaterThanOrEqualTo(1));
      expect(result.fileSizeBytes, greaterThan(0));
      expect(result.fileName, endsWith('.pdf'));
      expect(result.filePath, isNotNull);
      expect(File(result.filePath!).existsSync(), isTrue);
      expect(result.formattedFileSize, isNotEmpty);
    });

    test(
        'TEST-SVC-02: Throws CvPdfExportAccessDeniedException when session is inactive',
        () async {
      expect(
        () => service.exportCvToPdf(
          sampleDraft,
          options: const CvPdfExportOptions(isSessionActive: false),
        ),
        throwsA(isA<CvPdfExportAccessDeniedException>()),
      );
    });

    test(
        'TEST-SVC-03: Throws CvPdfExportAccessDeniedException when ownerUserId mismatches currentUserId',
        () async {
      expect(
        () => service.exportCvToPdf(
          sampleDraft,
          currentUserId: 'impostor_user_999',
          options: const CvPdfExportOptions(
            ownerUserId: 'legitimate_owner_123',
            isSessionActive: true,
          ),
        ),
        throwsA(isA<CvPdfExportAccessDeniedException>()),
      );
    });

    test(
        'TEST-SVC-04: Authorizes export when ownerUserId matches currentUserId',
        () async {
      final result = await service.exportCvToPdf(
        sampleDraft,
        currentUserId: 'owner_user_456',
        options: const CvPdfExportOptions(
          ownerUserId: 'owner_user_456',
          isSessionActive: true,
        ),
      );

      expect(result.isValidPdf, isTrue);
    });

    test(
        'TEST-SVC-05: Throws CvPdfExportException when draft full name is empty',
        () async {
      final invalidDraft = sampleDraft.copyWith(fullName: '');

      expect(
        () => service.exportCvToPdf(invalidDraft),
        throwsA(isA<CvPdfExportException>()),
      );
    });

    test(
        'TEST-SVC-06: cleanupTempFiles deletes exported PDF files and returns count',
        () async {
      // Export 2 files
      await service.exportCvToPdf(sampleDraft);
      await service.exportCvToPdf(sampleDraft);

      final filesBefore = tempTestDir.listSync().whereType<File>().length;
      expect(filesBefore, equals(2));

      final deleted = await service.cleanupTempFiles();
      expect(deleted, equals(2));

      final filesAfter = tempTestDir.listSync().whereType<File>().length;
      expect(filesAfter, equals(0));
    });

    test(
        'TEST-SVC-07: generatePdfBytes returns raw PDF bytes directly in memory',
        () async {
      final bytes = await service.generatePdfBytes(sampleDraft);
      expect(bytes, isNotEmpty);
      expect(bytes[0], equals(0x25)); // '%'
      expect(bytes[1], equals(0x50)); // 'P'
      expect(bytes[2], equals(0x44)); // 'D'
      expect(bytes[3], equals(0x46)); // 'F'
    });
  });
}
