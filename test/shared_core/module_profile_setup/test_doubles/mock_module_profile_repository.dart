import 'package:andril_mobile/shared_core/module_profile_setup/domain/models/module_profile_draft.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/domain/repositories/module_profile_repository.dart';

/// Test double implementing [ModuleProfileRepository] for automated unit and widget tests.
class MockModuleProfileRepository implements ModuleProfileRepository {
  MockModuleProfileRepository({
    this.shouldSucceed = true,
    this.shouldVerifyFace = true,
    this.delay = Duration.zero,
  });

  bool shouldSucceed;
  bool shouldVerifyFace;
  final Duration delay;
  final List<ModuleProfileDraft> savedDrafts = [];
  int saveCount = 0;
  int faceVerificationCount = 0;

  @override
  Future<bool> saveProfile(ModuleProfileDraft draft) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    saveCount++;
    if (shouldSucceed) {
      savedDrafts.add(draft);
      return true;
    }
    return false;
  }

  @override
  Future<bool> verifyFace(String photoPath) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    faceVerificationCount++;
    return shouldVerifyFace;
  }

  @override
  Future<ModuleProfileDraft?> getProfile(String moduleId) async {
    return savedDrafts.cast<ModuleProfileDraft?>().firstWhere(
      (d) => d?.moduleId == moduleId,
      orElse: () => null,
    );
  }
}
