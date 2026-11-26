import '../models/module_profile_draft.dart';

/// Abstract repository defining the contract for module profile creation and persistence.
///
/// Ensures compliance with backend rules:
/// - Does not invent live HTTP endpoints or fake DTOs
/// - Strictly encapsulates human face verification boundary
/// - Ensures per-module state isolation
abstract class ModuleProfileRepository {
  /// Persists the module profile draft.
  ///
  /// Throws [Exception] or returns `false` if backend service is unavailable,
  /// display name conflicts, or validation fails.
  Future<bool> saveProfile(ModuleProfileDraft draft);

  /// Performs face verification for Social module.
  ///
  /// Returns `true` only if verified by the authorized facial detection engine.
  /// Image selection alone does NOT constitute verification.
  Future<bool> verifyFace(String photoPath);

  /// Retrieves the saved profile for the given module ID, if one exists.
  Future<ModuleProfileDraft?> getProfile(String moduleId);
}
