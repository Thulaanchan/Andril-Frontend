import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// ViewModel managing state and operations for the Login screen (Screen 06).
class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  LoginViewModel({required AuthRepository repository})
      : _repository = repository;

  String _email = '';
  String _password = '';
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  String? _emailError;
  String? _passwordError;

  String get email => _email;
  String get password => _password;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  String? get errorMessage => _errorMessage;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;

  bool get canSubmit =>
      !_isLoading &&
      !_isGoogleLoading &&
      _email.trim().isNotEmpty &&
      _password.isNotEmpty;

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

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  bool _validateInputs() {
    bool isValid = true;
    final trimmedEmail = _email.trim();

    if (trimmedEmail.isEmpty) {
      _emailError = 'Please enter your email address.';
      isValid = false;
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmedEmail)) {
      _emailError = 'Please enter a valid email address.';
      isValid = false;
    } else {
      _emailError = null;
    }

    if (_password.isEmpty) {
      _passwordError = 'Please enter your password.';
      isValid = false;
    } else {
      _passwordError = null;
    }

    notifyListeners();
    return isValid;
  }

  Future<void> logIn({
    required void Function(AuthUser user) onSuccess,
    required void Function(String email) onVerificationRequired,
  }) async {
    if (_isLoading || _isGoogleLoading) return;
    _errorMessage = null;

    if (!_validateInputs()) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.logInWithEmail(
        email: _email.trim(),
        password: _password,
      );

      _isLoading = false;

      switch (result) {
        case AuthSuccess(:final user):
          notifyListeners();
          onSuccess(user);
        case AuthVerificationRequired(:final email):
          notifyListeners();
          onVerificationRequired(email);
        case AuthFailureResult(:final failure):
          _errorMessage = failure.message;
          notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
    }
  }

  Future<void> continueWithGoogle({
    required void Function(AuthUser user) onSuccess,
  }) async {
    if (_isLoading || _isGoogleLoading) return;
    _errorMessage = null;

    _isGoogleLoading = true;
    notifyListeners();

    try {
      final result = await _repository.logInWithGoogle();
      _isGoogleLoading = false;

      switch (result) {
        case AuthSuccess(:final user):
          notifyListeners();
          onSuccess(user);
        case AuthVerificationRequired(:final email):
          _errorMessage =
              'Verification is required for $email before logging in.';
          notifyListeners();
        case AuthFailureResult(:final failure):
          _errorMessage = failure.message;
          notifyListeners();
      }
    } catch (e) {
      _isGoogleLoading = false;
      _errorMessage =
          'Google Sign-In failed unexpectedly. Please try again.';
      notifyListeners();
    }
  }
}
