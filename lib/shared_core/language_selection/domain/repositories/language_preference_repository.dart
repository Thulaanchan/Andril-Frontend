/// Contract for persisting and retrieving user's selected language.
abstract interface class LanguagePreferenceRepository {
  /// Retrieves the persisted language code (e.g. 'en', 'ta', 'si') or null if not yet set.
  Future<String?> getSavedLanguage();

  /// Persists the selected language code.
  Future<void> saveLanguage(String languageCode);
}
