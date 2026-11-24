import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/repositories/onboarding_auth_repository.dart';

/// ViewModel managing state and validation for Screen 08 (Create New Password).
class PasswordResetViewModel extends ChangeNotifier {
  PasswordResetViewModel({
    required OnboardingAuthRepository repository,
    String? recoveryToken,
  })  : _repository = repository,
        _recoveryToken = recoveryToken;

  final OnboardingAuthRepository _repository;
  final String? _recoveryToken;

  String _newPassword = '';
  String _confirmPassword = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  String? _newPasswordError;
  String? _confirmPasswordError;

  String get newPassword => _newPassword;
  String get confirmPassword => _confirmPassword;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;
  String? get newPasswordError => _newPasswordError;
  String? get confirmPasswordError => _confirmPasswordError;

  bool get canSubmit =>
      !_isLoading &&
      _newPassword.isNotEmpty &&
      _confirmPassword.isNotEmpty;

  void setNewPassword(String value) {
    _newPassword = value;
    _newPasswordError = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    _confirmPasswordError = null;
    _errorMessage = null;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  bool _validateInputs() {
    var valid = true;

    if (_newPassword.isEmpty) {
      _newPasswordError = 'Please enter a new password.';
      valid = false;
    } else {
      _newPasswordError = null;
    }

    if (_confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please re-enter your new password.';
      valid = false;
    } else if (_newPassword != _confirmPassword) {
      _confirmPasswordError = 'Passwords do not match.';
      valid = false;
    } else {
      _confirmPasswordError = null;
    }

    notifyListeners();
    return valid;
  }

  Future<void> submitPasswordReset({VoidCallback? onSuccess}) async {
    if (_isLoading) return;
    _errorMessage = null;

    if (!_validateInputs()) return;

    // Check for active recovery context before attempting submission
    final hasValidContext = await _repository.hasValidRecoveryContext(
      recoveryToken: _recoveryToken,
    );

    if (!hasValidContext) {
      _errorMessage =
          'Password recovery session has expired or is invalid. Please request a new reset link.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.resetPasswordWithRecovery(
        newPassword: _newPassword,
        recoveryToken: _recoveryToken,
      );

      _isLoading = false;

      switch (result) {
        case AuthSuccess():
          _isSuccess = true;
          notifyListeners();
          onSuccess?.call();
        case AuthVerificationRequired():
          _isSuccess = true;
          notifyListeners();
          onSuccess?.call();
        case AuthFailureResult(:final failure):
          _errorMessage = failure.message;
          notifyListeners();
      }
    } catch (_) {
      _isLoading = false;
      _errorMessage =
          'Unable to update password. Please check your connection and try again.';
      notifyListeners();
    }
  }
}
