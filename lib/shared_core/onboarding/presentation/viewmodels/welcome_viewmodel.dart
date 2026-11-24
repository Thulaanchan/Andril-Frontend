import 'package:flutter/foundation.dart';

/// ViewModel managing interactions on Screen 03 (Welcome to Andril).
class WelcomeViewModel extends ChangeNotifier {
  WelcomeViewModel({
    VoidCallback? onNavigateToRegister,
    VoidCallback? onNavigateToLogin,
  })  : _onNavigateToRegister = onNavigateToRegister,
        _onNavigateToLogin = onNavigateToLogin;

  final VoidCallback? _onNavigateToRegister;
  final VoidCallback? _onNavigateToLogin;

  void createAccount() {
    _onNavigateToRegister?.call();
  }

  void logIn() {
    _onNavigateToLogin?.call();
  }
}
