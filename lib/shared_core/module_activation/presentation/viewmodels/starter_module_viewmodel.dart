import 'package:flutter/foundation.dart';
import '../../domain/entities/starter_module.dart';
import '../../domain/entities/starter_selection_result.dart';
import '../../domain/repositories/starter_module_repository.dart';

/// ViewModel managing state, tour cycling, 18+ modal, and submission for Screen 10.
class StarterModuleViewModel extends ChangeNotifier {
  StarterModuleViewModel({
    required StarterModuleRepository repository,
    this.isSocialAuthorizedByServer = true,
  }) : _repository = repository;

  final StarterModuleRepository _repository;
  final bool isSocialAuthorizedByServer;

  final List<StarterModule> modules = StarterModule.defaults;
  int _currentIndex = 0;
  int _selectedModuleIndex = 0;
  bool _isTourMode = false;
  bool _isSocialModalOpen = false;
  bool _socialConsentChecked = false;
  bool _isLoading = false;
  String? _errorMessage;

  int get currentIndex => _currentIndex;
  int get selectedModuleIndex => _selectedModuleIndex;
  StarterModule get currentModule => modules[_currentIndex];
  StarterModule get selectedModule => modules[_selectedModuleIndex];
  bool get isTourMode => _isTourMode;
  bool get isSocialModalOpen => _isSocialModalOpen;
  bool get socialConsentChecked => _socialConsentChecked;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void selectModuleIndex(int index) {
    if (index < 0 || index >= modules.length) return;
    final target = modules[index];

    if (target.id == 'social') {
      if (!isSocialAuthorizedByServer) {
        _errorMessage =
            'The Social module is restricted to members aged 18 and older. You can explore Learning or Hobbies.';
        notifyListeners();
        return;
      }
      // If user selected Social, open 18+ Social confirmation modal
      _currentIndex = index;
      _isSocialModalOpen = true;
      _socialConsentChecked = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _currentIndex = index;
    _selectedModuleIndex = index;
    _errorMessage = null;
    notifyListeners();
  }

  void toggleTourMode() {
    _isTourMode = !_isTourMode;
    notifyListeners();
  }

  void nextCard() {
    _currentIndex = (_currentIndex + 1) % modules.length;
    notifyListeners();
  }

  void prevCard() {
    _currentIndex = (_currentIndex - 1 + modules.length) % modules.length;
    notifyListeners();
  }

  void goToCard(int index) {
    if (index >= 0 && index < modules.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void setSocialConsentChecked(bool val) {
    _socialConsentChecked = val;
    notifyListeners();
  }

  void confirmSocialSelection() {
    if (!_socialConsentChecked) {
      _errorMessage = 'Please confirm the 18+ agreement to select Social.';
      notifyListeners();
      return;
    }
    _selectedModuleIndex = 2; // Social
    _isSocialModalOpen = false;
    _errorMessage = null;
    notifyListeners();
  }

  void closeSocialModal() {
    _isSocialModalOpen = false;
    _socialConsentChecked = false;
    notifyListeners();
  }

  Future<void> submitStarterSelection({
    required ValueChanged<StarterSelectionResult> onCompleted,
  }) async {
    if (_isLoading) return;
    _errorMessage = null;

    final chosen = selectedModule;
    if (chosen.id == 'social' && !isSocialAuthorizedByServer) {
      _errorMessage = 'Social module is not authorized for your account.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.selectStarterModule(
        moduleId: chosen.id,
        socialConsentConfirmed: chosen.id == 'social' && _socialConsentChecked,
      );

      _isLoading = false;

      if (!result.isSuccess) {
        _errorMessage = result.errorMessage ?? 'Starter selection was rejected.';
        notifyListeners();
        return;
      }

      notifyListeners();
      onCompleted(result);
    } catch (_) {
      _isLoading = false;
      _errorMessage =
          'Unable to save starter module selection. Please check your connection.';
      notifyListeners();
    }
  }
}
