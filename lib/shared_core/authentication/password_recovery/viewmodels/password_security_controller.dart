import 'package:flutter/foundation.dart';

import '../../../../core/security/session/session_controller.dart';

import '../../domain/repositories/password_security_repository.dart';

/// Offline view state. Observes the existing session controller and never
/// performs navigation, promotion of a recovery session, or backend handoff.
class PasswordSecurityController extends ChangeNotifier {
  PasswordSecurityController(this._sessions, this._repository)
      : _generation = _sessions.generation {
    _sessions.addListener(_observe);
  }

  final SessionController _sessions;
  final PasswordSecurityRepository _repository;
  static final _email = RegExp(r'^[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)+$');
  PasswordOutcome _outcome = PasswordOutcome.idle;
  int _generation;
  bool _busy = false;
  bool _disposed = false;

  bool get busy => _busy;
  PasswordOutcome get outcome => _outcome;

  Future<PasswordOutcome> forgotPassword(String email) {
    if (_disposed) return Future.value(PasswordOutcome.sessionChanged);
    if (_busy) return Future.value(PasswordOutcome.busy);
    if (_sessions.phase != SessionPhase.signedOut) {
      return Future.value(_show(PasswordOutcome.sessionChanged));
    }
    final address = email.trim();
    if (_email.stringMatch(address) != address) {
      return Future.value(_show(PasswordOutcome.invalidEmail));
    }
    return _run(() => _repository.requestRecovery(address));
  }

  Future<PasswordOutcome> resetPassword(String password, String confirmation) =>
      _update(PasswordOperation.reset, password, confirmation);

  Future<PasswordOutcome> changePassword(String password,
          {String? confirmation}) =>
      _update(PasswordOperation.change, password, confirmation);

  Future<PasswordOutcome> _update(
      PasswordOperation operation, String password, String? confirmation) {
    if (_disposed) return Future.value(PasswordOutcome.sessionChanged);
    if (_busy) return Future.value(PasswordOutcome.busy);
    if (operation == PasswordOperation.reset &&
        _sessions.phase != SessionPhase.recovery) {
      return Future.value(_show(PasswordOutcome.recoveryRequired));
    }
    if (operation == PasswordOperation.change &&
        _sessions.backendSession == null) {
      return Future.value(_show(PasswordOutcome.sessionRequired));
    }
    if (password.isEmpty) {
      return Future.value(_show(PasswordOutcome.passwordRequired));
    }
    if (confirmation != null && password != confirmation) {
      return Future.value(_show(PasswordOutcome.passwordMismatch));
    }
    return _run(() => _repository.updatePassword(operation, password));
  }

  Future<PasswordOutcome> _run(
      Future<PasswordOutcome> Function() submit) async {
    final generation = _sessions.generation;
    _busy = true;
    _outcome = PasswordOutcome.idle;
    notifyListeners();
    bool current() => !_disposed && _sessions.isCurrent(generation);
    try {
      if (!current()) return PasswordOutcome.sessionChanged;
      final result = await submit();
      if (!current()) return PasswordOutcome.sessionChanged;
      return _outcome = result;
    } catch (_) {
      if (!current()) return PasswordOutcome.sessionChanged;
      return _outcome = PasswordOutcome.unavailable;
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  PasswordOutcome _show(PasswordOutcome result) {
    _outcome = result;
    notifyListeners();
    return result;
  }

  void _observe() {
    final generation = _sessions.generation;
    if (generation == _generation) return;
    _generation = generation;
    _show(PasswordOutcome.idle);
  }

  @override
  void dispose() {
    _disposed = true;
    _sessions.removeListener(_observe);
    super.dispose();
  }
}
