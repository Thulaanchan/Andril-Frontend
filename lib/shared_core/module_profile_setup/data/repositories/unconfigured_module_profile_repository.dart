import '../../domain/models/module_profile_draft.dart';
import '../../domain/repositories/module_profile_repository.dart';

/// Default runtime implementation when the backend module profile service is unconfigured.
///
/// Follows fail-closed security:
/// - Rejects all save requests safely
/// - Never fabricates face verification or persistence success
/// - Prevents unauthorized module lifecycle progression
class UnconfiguredModuleProfileRepository implements ModuleProfileRepository {
  const UnconfiguredModuleProfileRepository();

  @override
  Future<bool> saveProfile(ModuleProfileDraft draft) async {
    // Fail-closed: unconfigured backend cannot persist profile drafts
    return false;
  }

  @override
  Future<bool> verifyFace(String photoPath) async {
    // Fail-closed: unconfigured facial detection engine cannot verify faces
    return false;
  }

  @override
  Future<ModuleProfileDraft?> getProfile(String moduleId) async {
    return null;
  }
}
