import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/repositories/onboarding_auth_repository.dart';

/// ViewModel managing state and operations for the Password Recovery screen (Screen 07).
class PasswordRecoveryViewModel extends ChangeNotifier {
  final OnboardingAuthRepository _repository;

  PasswordRecoveryViewModel({required OnboardingAuthRepository repository})
      : _repository = repository;

  String _email = '';
  bool _isLoading = false;
  bool _isSubmitted = false;
  String? _errorMessage;
  String? _emailError;

  String get email => _email;
  bool get isLoading => _isLoading;
  bool get isSubmitted => _isSubmitted;
  String? get errorMessage => _errorMessage;
  String? get emailError => _emailError;

  bool get canSubmit => !_isLoading && _email.trim().isNotEmpty;

  void setEmail(String value) {
    _email = value;
    _emailError = null;
    _errorMessage = null;
    notifyListeners();
  }

  bool _validateInput() {
    final trimmedEmail = _email.trim();
    if (trimmedEmail.isEmpty) {
      _emailError = 'Please enter your email address.';
      notifyListeners();
      return false;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmedEmail)) {
      _emailError = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }
    _emailError = null;
    notifyListeners();
    return true;
  }

  Future<void> sendResetLink({VoidCallback? onSuccess}) async {
    if (_isLoading) return;
    _errorMessage = null;

    if (!_validateInput()) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.sendPasswordResetEmail(
        email: _email.trim(),
      );

      _isLoading = false;

      switch (result) {
        case AuthSuccess():
          _isSubmitted = true;
          notifyListeners();
          onSuccess?.call();
        case AuthVerificationRequired():
          // Should not typically happen on password recovery, but handled safely
          _isSubmitted = true;
          notifyListeners();
          onSuccess?.call();
        case AuthFailureResult(:final failure):
          _errorMessage = failure.message;
          notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage =
          'Unable to send reset link right now. Please check your connection and try again.';
      notifyListeners();
    }
  }
}
