import 'dart:async';

import 'session_controller.dart';

/// Opt-in application admission for interactive SDK sign-in events. This does
/// not prevent the SDK from installing or persisting a session internally.
class InteractiveSessionAdmission {
  InteractiveSessionAttempt? _active;
  bool _signingOut = false;

  Future<void> duringSignOut(Future<void> Function() action) async {
    if (_signingOut) throw StateError('Sign-out already in progress.');
    _signingOut = true;
    invalidate();
    try {
      await action();
    } finally {
      _signingOut = false;
    }
  }

  InteractiveSessionAttempt? begin() {
    if (_signingOut || _active != null) return null;
    return _active = InteractiveSessionAttempt._(this);
  }

  /// Events can arrive before the SDK call returns its receipt. Wait without
  /// blocking logout, recovery, or stream disposal on that receipt.
  Future<bool> admit(BackendCredential candidate) async {
    final owner = _active;
    if (owner == null) return false;
    final matches = await owner._decision.future;
    if (_active != owner || owner._used || matches?.call(candidate) != true) {
      return false;
    }
    owner._used = true;
    return true;
  }

  void invalidate() => _active?.close();
}

class InteractiveSessionAttempt {
  InteractiveSessionAttempt._(this._admission);

  final InteractiveSessionAdmission _admission;
  final _decision = Completer<bool Function(BackendCredential)?>();
  bool _used = false;

  void approve(bool Function(BackendCredential) matches) {
    if (_admission._active == this && !_decision.isCompleted) {
      _decision.complete(matches);
    }
  }

  void close() {
    if (!_decision.isCompleted) _decision.complete(null);
    if (_admission._active == this) _admission._active = null;
  }
}
