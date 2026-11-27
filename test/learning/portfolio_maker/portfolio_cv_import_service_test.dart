import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/data/services/portfolio_cv_import_service.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_cv_import_result.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';

void main() {
  group('PortfolioCvImportService Unit Tests (LRN-06 & CV-01..05)', () {
    late PortfolioCvImportService service;
    late LearningPortfolio samplePortfolio;
    late CvDraftData targetCv;

    setUp(() {
      service = const PortfolioCvImportService();
      samplePortfolio = LearningPortfolio.syntheticSample(
        ownerLearningProfileId: 'owner_test_user',
      );
      targetCv = CvDraftData.syntheticSample(
        title: 'Target Engineering CV',
      );
    });

    test(
        'TEST-CV-IMP-01: Successfully imports selected projects into target CV',
        () async {
      final initialCvProjectCount = targetCv.projects.length;
      final selectedIds = [samplePortfolio.projects.first.id];

      final result = await service.importProjectsIntoCv(
        portfolio: samplePortfolio,
        selectedProjectIds: selectedIds,
        targetCv: targetCv,
        currentUserId: 'owner_test_user',
      );

      expect(result.importedCount, equals(1));
      expect(result.totalCvProjects, equals(initialCvProjectCount + 1));
      expect(result.importedProjectTitles.first,
          equals(samplePortfolio.projects.first.title));
      expect(result.updatedCv.projects.last.name,
          equals(samplePortfolio.projects.first.title));
      expect(result.updatedCv.projects.last.description,
          equals(samplePortfolio.projects.first.description));
      expect(result.updatedCv.projects.last.link,
          equals(samplePortfolio.projects.first.externalLinks.first));
    });

    test(
        'TEST-CV-IMP-02: Preserves existing target CV projects without mutation',
        () async {
      final selectedIds = samplePortfolio.projects.map((p) => p.id).toList();

      final result = await service.importProjectsIntoCv(
        portfolio: samplePortfolio,
        selectedProjectIds: selectedIds,
        targetCv: targetCv,
        currentUserId: 'owner_test_user',
      );

      // Verify original projects are still present at their original positions
      for (var i = 0; i < targetCv.projects.length; i++) {
        expect(result.updatedCv.projects[i].name,
            equals(targetCv.projects[i].name));
        expect(result.updatedCv.projects[i].description,
            equals(targetCv.projects[i].description));
      }

      expect(result.importedCount, equals(samplePortfolio.projects.length));
      expect(result.totalCvProjects,
          equals(targetCv.projects.length + samplePortfolio.projects.length));
    });

    test(
        'TEST-CV-IMP-03: Throws PortfolioCvImportAccessDeniedException when session is inactive',
        () async {
      expect(
        () => service.importProjectsIntoCv(
          portfolio: samplePortfolio,
          selectedProjectIds: ['proj_01'],
          targetCv: targetCv,
          currentUserId: 'owner_test_user',
          isSessionActive: false,
        ),
        throwsA(isA<PortfolioCvImportAccessDeniedException>()),
      );
    });

    test(
        'TEST-CV-IMP-04: Throws PortfolioCvImportAccessDeniedException when user is not owner',
        () async {
      expect(
        () => service.importProjectsIntoCv(
          portfolio: samplePortfolio,
          selectedProjectIds: ['proj_01'],
          targetCv: targetCv,
          currentUserId: 'impostor_user_999',
        ),
        throwsA(isA<PortfolioCvImportAccessDeniedException>()),
      );
    });

    test(
        'TEST-CV-IMP-05: Throws PortfolioCvImportAccessDeniedException when module is not learning',
        () async {
      final invalidPortfolio = samplePortfolio.copyWith(module: 'career');

      expect(
        () => service.importProjectsIntoCv(
          portfolio: invalidPortfolio,
          selectedProjectIds: ['proj_01'],
          targetCv: targetCv,
          currentUserId: 'owner_test_user',
        ),
        throwsA(isA<PortfolioCvImportAccessDeniedException>()),
      );
    });

    test(
        'TEST-CV-IMP-06: Throws PortfolioCvImportException when selectedProjectIds is empty',
        () async {
      expect(
        () => service.importProjectsIntoCv(
          portfolio: samplePortfolio,
          selectedProjectIds: const [],
          targetCv: targetCv,
          currentUserId: 'owner_test_user',
        ),
        throwsA(isA<PortfolioCvImportException>()),
      );
    });

    test(
        'TEST-CV-IMP-07: Uses mediaReference as fallback link if externalLinks is empty',
        () async {
      final mediaOnlyProject = const PortfolioProject(
        id: 'proj_media_only',
        title: 'Design Showcase',
        description: 'Visual UI mockup',
        mediaReferences: ['https://andril.dev/media/showcase.png'],
        externalLinks: [],
      );

      final customPortfolio = samplePortfolio.copyWith(
        projects: [mediaOnlyProject],
      );

      final result = await service.importProjectsIntoCv(
        portfolio: customPortfolio,
        selectedProjectIds: ['proj_media_only'],
        targetCv: targetCv,
        currentUserId: 'owner_test_user',
      );

      expect(result.updatedCv.projects.last.link,
          equals('https://andril.dev/media/showcase.png'));
    });
  });
}
