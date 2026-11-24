import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/onboarding_auth_repository.dart';

/// ViewModel managing state and operations for Screen 04 (Email Registration).
class RegistrationViewModel extends ChangeNotifier {
  RegistrationViewModel({
    required OnboardingAuthRepository repository,
  }) : _repository = repository;

  final OnboardingAuthRepository _repository;

  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _termsAgreed = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool get termsAgreed => _termsAgreed;
  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  String? get errorMessage => _errorMessage;

  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;

  bool get canSubmit =>
      !_isLoading &&
      !_isGoogleLoading &&
      _email.trim().isNotEmpty &&
      _password.isNotEmpty &&
      _confirmPassword.isNotEmpty &&
      _termsAgreed;

  void setTermsAgreed(bool value) {
    _termsAgreed = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    _emailError = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    _passwordError = null;
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
    final trimmedEmail = _email.trim();

    if (trimmedEmail.isEmpty) {
      _emailError = 'Email address is required.';
      valid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedEmail)) {
      _emailError = 'Please enter a valid email address.';
      valid = false;
    } else {
      _emailError = null;
    }

    if (_password.isEmpty) {
      _passwordError = 'Password is required.';
      valid = false;
    } else {
      _passwordError = null;
    }

    if (_confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please confirm your password.';
      valid = false;
    } else if (_password != _confirmPassword) {
      _confirmPasswordError = 'Passwords do not match.';
      valid = false;
    } else {
      _confirmPasswordError = null;
    }

    if (!_termsAgreed) {
      _errorMessage =
          'Please agree to the Terms of Service and Privacy Policy.';
      valid = false;
    }

    notifyListeners();
    return valid;
  }

  Future<void> register({
    void Function(String email)? onVerificationRequired,
    void Function(AuthUser user)? onSuccess,
  }) async {
    if (_isLoading || _isGoogleLoading) return; // Prevent duplicate submission
    if (!_validateInputs()) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.registerWithEmail(
        email: _email.trim(),
        password: _password,
      );

      switch (result) {
        case AuthSuccess(:final user):
          onSuccess?.call(user);
        case AuthVerificationRequired(:final email):
          onVerificationRequired?.call(email);
        case AuthFailureResult(:final failure):
          _errorMessage = failure.message;
      }
    } catch (_) {
      _errorMessage = 'An unexpected error occurred. Please check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> continueWithGoogle({
    void Function(AuthUser user)? onSuccess,
  }) async {
    if (_isLoading || _isGoogleLoading) return;

    _isGoogleLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.logInWithGoogle();
      switch (result) {
        case AuthSuccess(:final user):
          onSuccess?.call(user);
        case AuthVerificationRequired():
          // Handled if google requires verification
          break;
        case AuthFailureResult(:final failure):
          if (failure.type != AuthFailureType.googleSignInCancelled) {
            _errorMessage = failure.message;
          }
      }
    } catch (_) {
      _errorMessage = 'Google Sign-In failed. Please try again.';
    } finally {
      _isGoogleLoading = false;
      notifyListeners();
    }
  }
}
