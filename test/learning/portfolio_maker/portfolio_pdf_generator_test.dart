import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/features/learning/portfolio_maker/data/services/portfolio_pdf_generator.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/services/i_portfolio_pdf_export_service.dart';

void main() {
  group('PortfolioPdfGenerator Unit Tests (LRN-06 & PORT-01..05)', () {
    late PortfolioPdfGenerator generator;
    late LearningPortfolio samplePortfolio;

    setUp(() {
      generator = const PortfolioPdfGenerator();
      samplePortfolio = LearningPortfolio.syntheticSample();
    });

    // Helper to check standard PDF header (%PDF-)
    bool isPdf(Uint8List bytes) {
      if (bytes.length < 5) return false;
      return bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46 &&
          bytes[4] == 0x2D;
    }

    test(
        'TEST-PORT-GEN-01: Developer template produces valid non-empty PDF bytes',
        () async {
      final bytes = await generator.generate(
        samplePortfolio,
        options: const PortfolioPdfExportOptions(
            template: PortfolioTemplate.developer),
      );

      expect(bytes, isNotEmpty);
      expect(isPdf(bytes), isTrue);
      expect(bytes.length, greaterThan(1000));
    });

    test(
        'TEST-PORT-GEN-02: Creative template produces valid non-empty PDF bytes',
        () async {
      final bytes = await generator.generate(
        samplePortfolio,
        options: const PortfolioPdfExportOptions(
            template: PortfolioTemplate.creative),
      );

      expect(bytes, isNotEmpty);
      expect(isPdf(bytes), isTrue);
      expect(bytes.length, greaterThan(1000));
    });

    test(
        'TEST-PORT-GEN-03: Professional template produces valid non-empty PDF bytes',
        () async {
      final bytes = await generator.generate(
        samplePortfolio,
        options: const PortfolioPdfExportOptions(
            template: PortfolioTemplate.professional),
      );

      expect(bytes, isNotEmpty);
      expect(isPdf(bytes), isTrue);
      expect(bytes.length, greaterThan(1000));
    });

    test(
        'TEST-PORT-GEN-04: Throws PortfolioPdfExportException when title is empty',
        () async {
      final emptyTitlePortfolio = samplePortfolio.copyWith(title: '   ');

      expect(
        () => generator.generate(emptyTitlePortfolio),
        throwsA(isA<PortfolioPdfExportException>()),
      );
    });

    test(
        'TEST-PORT-GEN-05: Handles empty projects list gracefully without crashing',
        () async {
      final emptyProjectsPortfolio =
          samplePortfolio.copyWith(projects: const []);

      for (final tmpl in PortfolioTemplate.values) {
        final bytes = await generator.generate(
          emptyProjectsPortfolio,
          options: PortfolioPdfExportOptions(template: tmpl),
        );
        expect(isPdf(bytes), isTrue);
      }
    });

    test('TEST-PORT-GEN-06: Sanitizes Unicode characters without failing',
        () async {
      final unicodePortfolio = samplePortfolio.copyWith(
        title: 'Portfolio • Engineering — “2026” – ‘Advanced’',
        projects: const [
          PortfolioProject(
            id: 'proj_unicode',
            title: 'Title • with — dashes – and “quotes”',
            description:
                'Unicode description • bullet — emdash – endash ‘curly’ “double”',
          ),
        ],
      );

      final bytes = await generator.generate(unicodePortfolio);
      expect(isPdf(bytes), isTrue);
    });

    test(
        'TEST-PORT-GEN-07: Respects includeMediaReferences and includeExternalLinks flags',
        () async {
      final bytesWithoutLinksOrMedia = await generator.generate(
        samplePortfolio,
        options: const PortfolioPdfExportOptions(
          includeMediaReferences: false,
          includeExternalLinks: false,
        ),
      );

      final bytesWithAll = await generator.generate(
        samplePortfolio,
        options: const PortfolioPdfExportOptions(
          includeMediaReferences: true,
          includeExternalLinks: true,
        ),
      );

      expect(isPdf(bytesWithoutLinksOrMedia), isTrue);
      expect(isPdf(bytesWithAll), isTrue);
    });

    test(
        'TEST-PORT-GEN-08: generateWithMetadata returns valid bytes and page count',
        () async {
      final metadata = await generator.generateWithMetadata(samplePortfolio);
      expect(isPdf(metadata.bytes), isTrue);
      expect(metadata.pageCount, greaterThanOrEqualTo(1));
    });
  });
}
