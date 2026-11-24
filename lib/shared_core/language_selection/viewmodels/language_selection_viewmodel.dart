import 'package:flutter/foundation.dart';
import '../domain/models/app_language.dart';
import '../domain/repositories/language_preference_repository.dart';

/// ViewModel managing Language Selection presentation state and persistence.
class LanguageSelectionViewModel extends ChangeNotifier {
  LanguageSelectionViewModel({
    required LanguagePreferenceRepository repository,
    AppLanguage initialLanguage = AppLanguage.english,
  })  : _repository = repository,
        _selectedLanguage = initialLanguage;

  final LanguagePreferenceRepository _repository;
  AppLanguage _selectedLanguage;
  bool _isLoading = false;
  bool _isSaving = false;

  AppLanguage get selectedLanguage => _selectedLanguage;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  List<AppLanguage> get availableLanguages => AppLanguage.values;

  Future<void> loadSavedLanguage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedCode = await _repository.getSavedLanguage();
      if (savedCode != null) {
        _selectedLanguage = AppLanguage.fromCode(savedCode);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectLanguage(AppLanguage language) {
    if (_selectedLanguage == language) return;
    _selectedLanguage = language;
    notifyListeners();
  }

  Future<void> saveAndContinue({VoidCallback? onSuccess}) async {
    _isSaving = true;
    notifyListeners();

    try {
      await _repository.saveLanguage(_selectedLanguage.code);
      onSuccess?.call();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
