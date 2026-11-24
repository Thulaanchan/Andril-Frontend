import '../entities/starter_module.dart';
import '../entities/starter_selection_result.dart';

/// Domain contract for starter module selection (Screen 10).
///
/// Rule 05: Starter module selection is NOT lifecycle activation.
/// Rule 06: Never calls test-host-only lifecycle endpoints.
abstract interface class StarterModuleRepository {
  /// Records the user's initial chosen module with the backend authority.
  Future<StarterSelectionResult> selectStarterModule({
    required String moduleId,
    bool socialConsentConfirmed = false,
  });

  /// Retrieves available starter modules and eligibility status.
  Future<List<StarterModule>> getAvailableModules();
}
