import 'dart:async';
import 'package:flutter/foundation.dart';

/// ViewModel managing Splash screen presentation state and transition timing.
class SplashViewModel extends ChangeNotifier {
  SplashViewModel({
    this.splashDuration = const Duration(milliseconds: 2400),
  });

  final Duration splashDuration;
  Timer? _timer;
  bool _isComplete = false;
  bool _isDisposed = false;

  bool get isComplete => _isComplete;

  void startSplashTimer({VoidCallback? onComplete}) {
    if (_isDisposed) return;
    _timer?.cancel();
    _timer = Timer(splashDuration, () {
      if (_isDisposed) return;
      _isComplete = true;
      notifyListeners();
      onComplete?.call();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
