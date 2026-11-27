import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_cv_import_result.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';

/// Contract for private, owner-scoped CV project import service
/// per ANDRIL LRN-06, PORT-01..05 & CV-01..05.
abstract class IPortfolioCvImportService {
  /// Imports the specified [selectedProjectIds] from [portfolio] into [targetCv].
  ///
  /// Enforces:
  /// 1. Owner authorization: [currentUserId] must match [portfolio.ownerLearningProfileId].
  /// 2. Module isolation: [portfolio.module] must be 'learning'.
  /// 3. Active session verification: [isSessionActive] must be true.
  /// 4. Lossless conversion: converts [PortfolioProject] to [CvProjectItem] without dropping fields.
  /// 5. Existing CV projects are preserved without mutation or corruption.
  Future<PortfolioCvImportResult> importProjectsIntoCv({
    required LearningPortfolio portfolio,
    required List<String> selectedProjectIds,
    required CvDraftData targetCv,
    required String currentUserId,
    bool isSessionActive = true,
  });
}
