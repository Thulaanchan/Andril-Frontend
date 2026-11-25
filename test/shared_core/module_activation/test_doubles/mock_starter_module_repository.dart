import 'package:andril_mobile/shared_core/module_activation/domain/entities/starter_module.dart';
import 'package:andril_mobile/shared_core/module_activation/domain/entities/starter_selection_result.dart';
import 'package:andril_mobile/shared_core/module_activation/domain/repositories/starter_module_repository.dart';

/// Test double for [StarterModuleRepository] enforcing Rules 05 and 06.
class MockStarterModuleRepository implements StarterModuleRepository {
  MockStarterModuleRepository({
    this.isSocialAuthorized = true,
  });

  bool isSocialAuthorized;
  StarterSelectionResult? forcedResult;
  String? lastSelectedModuleId;
  bool lastSocialConsentConfirmed = false;

  @override
  Future<StarterSelectionResult> selectStarterModule({
    required String moduleId,
    bool socialConsentConfirmed = false,
  }) async {
    lastSelectedModuleId = moduleId;
    lastSocialConsentConfirmed = socialConsentConfirmed;

    if (forcedResult != null) return forcedResult!;

    if (moduleId == 'social' && !isSocialAuthorized) {
      return const StarterSelectionResult(
        selectedModuleId: 'social',
        isSuccess: false,
        isSocialAgeRestricted: true,
        errorMessage: 'Social module is restricted to members aged 18 and older.',
      );
    }

    // Rule 05: Starter selection completes and returns nextStep ('profile_setup')
    // Does NOT perform full lifecycle activation
    return StarterSelectionResult(
      selectedModuleId: moduleId,
      isSuccess: true,
      nextStep: 'profile_setup',
    );
  }

  @override
  Future<List<StarterModule>> getAvailableModules() async =>
      StarterModule.defaults;
}
