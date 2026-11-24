import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/language_preference_repository.dart';

/// Local implementation of [LanguagePreferenceRepository] using [SharedPreferences].
class SharedPrefsLanguagePreferenceRepository implements LanguagePreferenceRepository {
  SharedPrefsLanguagePreferenceRepository({SharedPreferences? preferences})
      : _preferences = preferences;

  static const String prefKey = 'andril_m2_selected_language';
  SharedPreferences? _preferences;

  Future<SharedPreferences> _getPrefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> getSavedLanguage() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(prefKey);
    } catch (_) {
      // Gracefully handle storage failure by returning null
      return null;
    }
  }

  @override
  Future<void> saveLanguage(String languageCode) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(prefKey, languageCode);
    } catch (_) {
      // Gracefully handle write failures
    }
  }
}
