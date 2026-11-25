import '../../domain/entities/starter_module.dart';
import '../../domain/entities/starter_selection_result.dart';
import '../../domain/repositories/starter_module_repository.dart';

/// Default runtime repository when backend starter module API is unconfigured.
class UnconfiguredStarterModuleRepository implements StarterModuleRepository {
  const UnconfiguredStarterModuleRepository();

  @override
  Future<StarterSelectionResult> selectStarterModule({
    required String moduleId,
    bool socialConsentConfirmed = false,
  }) async =>
      StarterSelectionResult.serviceUnavailable;

  @override
  Future<List<StarterModule>> getAvailableModules() async =>
      StarterModule.defaults;
}
