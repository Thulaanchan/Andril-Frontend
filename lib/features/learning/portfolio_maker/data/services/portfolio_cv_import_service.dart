import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_cv_import_result.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/services/i_portfolio_cv_import_service.dart';
import 'learning_cv_import_api_adapter.dart';

/// Concrete implementation of [IPortfolioCvImportService] for private, owner-scoped CV import
/// per ANDRIL LRN-06, PORT-01..05 & CV-01..05.
class PortfolioCvImportService implements IPortfolioCvImportService {
  final ILearningCvImportRemoteDataSource? remoteDataSource;

  const PortfolioCvImportService({this.remoteDataSource});

  @override
  Future<PortfolioCvImportResult> importProjectsIntoCv({
    required LearningPortfolio portfolio,
    required List<String> selectedProjectIds,
    required CvDraftData targetCv,
    required String currentUserId,
    bool isSessionActive = true,
  }) async {
    // 1. Session verification
    if (!isSessionActive) {
      throw const PortfolioCvImportAccessDeniedException(
        'Session is revoked or expired. Please re-authenticate before importing projects into CV.',
      );
    }

    // 2. Module isolation check
    if (portfolio.module != 'learning') {
      throw const PortfolioCvImportAccessDeniedException(
        'Access denied: Portfolio must belong to the learning module.',
      );
    }

    // 3. Owner authorization verification
    if (portfolio.ownerLearningProfileId.isNotEmpty &&
        currentUserId.isNotEmpty &&
        portfolio.ownerLearningProfileId != currentUserId) {
      throw const PortfolioCvImportAccessDeniedException(
        'Access denied: You can only import from portfolio documents that you own.',
      );
    }

    // 4. Project selection validation
    if (selectedProjectIds.isEmpty) {
      throw const PortfolioCvImportException(
        'Cannot import projects: At least one project must be explicitly selected.',
      );
    }

    // 5. Filter selected projects preserving portfolio ordering
    final selectedProjects = portfolio.projects
        .where((project) => selectedProjectIds.contains(project.id))
        .toList();

    if (selectedProjects.isEmpty) {
      throw const PortfolioCvImportException(
        'None of the selected project IDs match any project in this portfolio.',
      );
    }

    // 6. Lossless conversion from PortfolioProject to CvProjectItem
    final convertedProjects = selectedProjects.map((proj) {
      final title = proj.title?.trim().isNotEmpty == true
          ? proj.title!.trim()
          : 'Untitled Project';

      // Use the first external link or first media reference as the project link
      String? primaryLink;
      if (proj.externalLinks.isNotEmpty) {
        primaryLink = proj.externalLinks.first;
      } else if (proj.mediaReferences.isNotEmpty) {
        primaryLink = proj.mediaReferences.first;
      }

      return CvProjectItem(
        name: title,
        role: 'Featured Project',
        description: proj.description?.trim().isNotEmpty == true
            ? proj.description!.trim()
            : null,
        link: primaryLink,
      );
    }).toList();

    // 7. Append to target CV projects preserving existing CV entries
    final updatedProjects = [
      ...targetCv.projects,
      ...convertedProjects,
    ];

    final updatedCv = targetCv.copyWith(
      projects: List.unmodifiable(updatedProjects),
      updatedAt: DateTime.now(),
    );

    return PortfolioCvImportResult(
      updatedCv: updatedCv,
      importedCount: convertedProjects.length,
      importedProjectTitles: convertedProjects.map((p) => p.name).toList(),
      totalCvProjects: updatedProjects.length,
      importedAt: DateTime.now(),
    );
  }
}
