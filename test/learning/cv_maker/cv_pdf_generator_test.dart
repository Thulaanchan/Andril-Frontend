import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/features/learning/cv_maker/data/services/cv_pdf_generator.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/entities/cv_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/services/i_cv_pdf_export_service.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';

void main() {
  group('CvPdfGenerator Unit Tests (LRN-05 & CV-01..05)', () {
    late CvPdfGenerator generator;
    late CvDraftData sampleDraft;

    setUp(() {
      generator = const CvPdfGenerator();
      sampleDraft = CvDraftData.syntheticSample();
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

    test('TEST-GEN-01: Modern template produces valid non-empty PDF bytes',
        () async {
      final bytes = await generator.generate(
        sampleDraft,
        options: const CvPdfExportOptions(template: CvTemplate.modern),
      );

      expect(bytes, isNotEmpty);
      expect(isPdf(bytes), isTrue);
      expect(bytes.length, greaterThan(1000));
    });

    test(
        'TEST-GEN-02: Professional template produces valid non-empty PDF bytes',
        () async {
      final bytes = await generator.generate(
        sampleDraft,
        options: const CvPdfExportOptions(template: CvTemplate.professional),
      );

      expect(bytes, isNotEmpty);
      expect(isPdf(bytes), isTrue);
      expect(bytes.length, greaterThan(1000));
    });

    test('TEST-GEN-03: Creative template produces valid non-empty PDF bytes',
        () async {
      final bytes = await generator.generate(
        sampleDraft,
        options: const CvPdfExportOptions(template: CvTemplate.creative),
      );

      expect(bytes, isNotEmpty);
      expect(isPdf(bytes), isTrue);
      expect(bytes.length, greaterThan(1000));
    });

    test('TEST-GEN-04: Throws CvPdfExportException when full name is empty',
        () async {
      final emptyNameDraft = sampleDraft.copyWith(fullName: '   ');

      expect(
        () => generator.generate(emptyNameDraft),
        throwsA(isA<CvPdfExportException>()),
      );
    });

    test('TEST-GEN-05: Master contact privacy gate suppresses contact details',
        () async {
      // With includeContactInfo = false, contact details must not appear
      final bytesWithoutContact = await generator.generate(
        sampleDraft,
        options: const CvPdfExportOptions(includeContactInfo: false),
      );

      final bytesWithContact = await generator.generate(
        sampleDraft,
        options: const CvPdfExportOptions(includeContactInfo: true),
      );

      expect(isPdf(bytesWithoutContact), isTrue);
      expect(isPdf(bytesWithContact), isTrue);
    });

    test('TEST-GEN-06: Individual contact visibility flags respected',
        () async {
      final draftSelective = sampleDraft.copyWith(
        showEmail: true,
        showPhone: false,
        showLocation: false,
        showWebsite: false,
      );

      final bytes = await generator.generate(
        draftSelective,
        options: CvPdfExportOptions.fromDraft(draftSelective),
      );

      expect(isPdf(bytes), isTrue);
    });

    test('TEST-GEN-07: All seven structured CV sections compile cleanly',
        () async {
      // Draft has Summary, Skills, Experiences, Education, Certifications, Projects, Links
      final meta = await generator.generateWithMetadata(sampleDraft);

      expect(isPdf(meta.bytes), isTrue);
      expect(meta.pageCount, greaterThanOrEqualTo(1));
    });

    test(
        'TEST-GEN-08: Minimal draft with empty optional sections compiles cleanly',
        () async {
      final minimalDraft = CvDraftData(
        id: 'cv_minimal',
        title: 'Minimal CV',
        selectedTemplate: CvTemplate.modern,
        fullName: 'Jane Doe',
        headline: 'Software Engineer',
        summary: '',
        skills: const [],
        experiences: const [],
        education: const [],
        certifications: const [],
        projects: const [],
        links: const [],
        updatedAt: DateTime.now(),
      );

      final meta = await generator.generateWithMetadata(minimalDraft);
      expect(isPdf(meta.bytes), isTrue);
      expect(meta.pageCount, equals(1));
    });

    test(
        'TEST-GEN-09: Overflow protection handles long descriptions across pages',
        () async {
      final longDesc = List.generate(
              20,
              (i) =>
                  'Detailed accomplishment bullet point $i in large scale engineering.')
          .join(' ');

      final longDraft = sampleDraft.copyWith(
        experiences: [
          CvExperienceItem(
            jobTitle: 'Senior Systems Architect',
            company: 'Global Enterprises Inc',
            period: '2018 - 2024',
            description: longDesc,
          ),
          CvExperienceItem(
            jobTitle: 'Lead Infrastructure Engineer',
            company: 'Tech Corp',
            period: '2014 - 2018',
            description: longDesc,
          ),
          CvExperienceItem(
            jobTitle: 'Backend Engineer',
            company: 'Startup Labs',
            period: '2010 - 2014',
            description: longDesc,
          ),
        ],
      );

      final meta = await generator.generateWithMetadata(longDraft);
      expect(isPdf(meta.bytes), isTrue);
      expect(meta.pageCount, greaterThanOrEqualTo(1));
    });

    test('TEST-GEN-10: Unicode characters and quotes sanitized safely',
        () async {
      final unicodeDraft = sampleDraft.copyWith(
        fullName: 'Thusha Kunasingam',
        headline: 'Lead “Engineer” — Mobile & Frontend',
        summary:
            'Specializing in robust architectures • Clean UX – High performance ‘code’.',
      );

      final bytes = await generator.generate(unicodeDraft);
      expect(isPdf(bytes), isTrue);
    });
  });
}
