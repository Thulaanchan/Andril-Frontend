import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/features/learning/portfolio_maker/data/services/portfolio_pdf_export_service.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/data/services/portfolio_pdf_generator.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/services/i_portfolio_pdf_export_service.dart';

void main() {
  group('PortfolioPdfExportService Unit Tests (LRN-06 & PORT-01..05)', () {
    late PortfolioPdfExportService service;
    late LearningPortfolio samplePortfolio;
    late Directory tempTestDir;

    setUp(() async {
      tempTestDir =
          await Directory.systemTemp.createTemp('andril_portfolio_test_');
      service = PortfolioPdfExportService(
        generator: const PortfolioPdfGenerator(),
        tempDirProvider: () async => tempTestDir.path,
      );
      samplePortfolio = LearningPortfolio.syntheticSample(
        ownerLearningProfileId: 'owner_user_123',
      );
    });

    tearDown(() async {
      if (await tempTestDir.exists()) {
        await tempTestDir.delete(recursive: true);
      }
    });

    test(
        'TEST-PORT-SVC-01: Successful export generates valid result with file on disk',
        () async {
      final result = await service.exportPortfolioToPdf(
        samplePortfolio,
        currentUserId: 'owner_user_123',
        options: const PortfolioPdfExportOptions(
          ownerUserId: 'owner_user_123',
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
      expect(result.projectCount, equals(samplePortfolio.projects.length));
    });

    test(
        'TEST-PORT-SVC-02: Throws PortfolioPdfExportAccessDeniedException when session is inactive',
        () async {
      expect(
        () => service.exportPortfolioToPdf(
          samplePortfolio,
          currentUserId: 'owner_user_123',
          options: const PortfolioPdfExportOptions(isSessionActive: false),
        ),
        throwsA(isA<PortfolioPdfExportAccessDeniedException>()),
      );
    });

    test(
        'TEST-PORT-SVC-03: Throws PortfolioPdfExportAccessDeniedException when ownerUserId mismatches currentUserId',
        () async {
      expect(
        () => service.exportPortfolioToPdf(
          samplePortfolio,
          currentUserId: 'impostor_user_999',
          options: const PortfolioPdfExportOptions(
            ownerUserId: 'owner_user_123',
            isSessionActive: true,
          ),
        ),
        throwsA(isA<PortfolioPdfExportAccessDeniedException>()),
      );
    });

    test(
        'TEST-PORT-SVC-04: Throws PortfolioPdfExportAccessDeniedException when module is not learning',
        () async {
      final invalidModulePortfolio = samplePortfolio.copyWith(module: 'career');

      expect(
        () => service.exportPortfolioToPdf(
          invalidModulePortfolio,
          currentUserId: 'owner_user_123',
        ),
        throwsA(isA<PortfolioPdfExportAccessDeniedException>()),
      );
    });

    test(
        'TEST-PORT-SVC-05: Throws PortfolioPdfExportException when title is empty',
        () async {
      final invalidPortfolio = samplePortfolio.copyWith(title: '');

      expect(
        () => service.exportPortfolioToPdf(
          invalidPortfolio,
          currentUserId: 'owner_user_123',
        ),
        throwsA(isA<PortfolioPdfExportException>()),
      );
    });

    test('TEST-PORT-SVC-06: Deletes temporary PDF files on cleanupTempFiles',
        () async {
      // Create a temporary file in the test dir
      final testFile = File(
          '${tempTestDir.path}${Platform.pathSeparator}test_temp_12345.pdf');
      await testFile.writeAsString('test');
      expect(testFile.existsSync(), isTrue);

      final deleted = await service.cleanupTempFiles();
      expect(deleted, greaterThanOrEqualTo(1));
    });
  });
}
