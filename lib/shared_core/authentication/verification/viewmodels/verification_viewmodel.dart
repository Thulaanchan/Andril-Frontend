import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_config.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/onboarding_auth_repository.dart';

/// ViewModel managing state and operations for Screen 05 (Account Verification).
class VerificationViewModel extends ChangeNotifier {
  VerificationViewModel({
    required OnboardingAuthRepository repository,
    required String email,
    AuthConfig config = const AuthConfig(),
  })  : _repository = repository,
        _email = email,
        _config = config;

  final OnboardingAuthRepository _repository;
  final String _email;
  final AuthConfig _config;

  String _otp = '';
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCooldown = 0;
  Timer? _countdownTimer;

  String get email => _email;
  String get otp => _otp;
  bool get isLoading => _isLoading;
  bool get isResending => _isResending;
  String? get errorMessage => _errorMessage;
  int get resendCooldown => _resendCooldown;
  int get resendCooldownSeconds => _resendCooldown;
  bool get isResendCooldownActive => _resendCooldown > 0;
  bool get canResend => _resendCooldown == 0 && !_isResending && !_isLoading;
  bool get canSubmit =>
      !_isLoading && _otp.length == (_config.otpLength ?? 6);

  /// Returns masked email (e.g. `yo***@example.com`) for privacy preservation.
  String get maskedEmail {
    final parts = _email.split('@');
    if (parts.length != 2) return _email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) {
      return '$name***@$domain';
    }
    return '${name.substring(0, 2)}***@$domain';
  }

  void updateOtp(String value) {
    _otp = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setCode(String value) => updateOtp(value);

  Future<void> resendCode() => resendOtp();

  Future<void> verifyCode({
    required void Function(AuthUser user) onSuccess,
  }) =>
      verify(onSuccess: onSuccess);

  Future<void> verify({
    required void Function(AuthUser user) onSuccess,
  }) async {
    if (_isLoading || _isResending) return; // Prevent duplicate requests

    final requiredLength = _config.otpLength ?? 6;
    if (_otp.length < requiredLength) {
      _errorMessage = 'Please enter all $requiredLength digits of the verification code.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.verifyEmailOtp(
        email: _email,
        token: _otp,
      );

      switch (result) {
        case AuthSuccess(:final user):
          onSuccess(user);
        case AuthVerificationRequired():
          _errorMessage = 'Verification still required.';
        case AuthFailureResult(:final failure):
          _errorMessage = failure.message;
      }
    } catch (_) {
      _errorMessage = 'Verification request failed. Please check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendOtp() async {
    if (!canResend) return;

    _isResending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.resendVerificationOtp(email: _email);
      switch (result) {
        case AuthSuccess():
        case AuthVerificationRequired():
          _startCooldown();
        case AuthFailureResult(:final failure):
          _errorMessage = failure.message;
      }
    } catch (_) {
      _errorMessage = 'Could not resend verification code. Please try again.';
    } finally {
      _isResending = false;
      notifyListeners();
    }
  }

  void _startCooldown([int? seconds]) {
    final cooldown = seconds ?? _config.resendCooldownSeconds;
    if (cooldown == null || cooldown <= 0) {
      _resendCooldown = 0;
      notifyListeners();
      return;
    }
    _resendCooldown = cooldown;
    notifyListeners();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        _resendCooldown--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
