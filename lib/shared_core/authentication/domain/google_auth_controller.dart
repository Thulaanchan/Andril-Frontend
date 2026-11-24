import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/security/session/interactive_session_admission.dart';
import '../../../core/security/session/session_controller.dart';
import 'repositories/auth_repository.dart';
import 'repositories/google_auth_repository.dart';

/// Offline view state. The existing SessionController owns identity and
/// AUTH-03C observes it directly; this controller does not navigate or provision.
class GoogleAuthController extends ChangeNotifier {
  GoogleAuthController(this._repository, this._sessions, this._admission,
      {Duration admissionWait = const Duration(seconds: 8)})
      : _admissionWait = admissionWait {
    _sessions.addListener(_observe);
  }

  final GoogleAuthRepository _repository;
  final SessionController _sessions;
  final InteractiveSessionAdmission _admission;
  final Duration _admissionWait;

  GoogleAuthState _state = GoogleAuthState.idle;
  InteractiveSessionAttempt? _lease;
  BackendSession? _admittedOwner;
  int? _startingGeneration;
  bool _busy = false;
  bool _disposed = false;
  VoidCallback? _settle;

  GoogleAuthState get state => _state;
  bool get busy => _busy;

  Future<GoogleAuthState> signIn() async {
    if (_disposed) return GoogleAuthState.superseded;
    if (_busy) return GoogleAuthState.busy;
    if (_sessions.phase != SessionPhase.signedOut) {
      return _show(GoogleAuthState.blocked);
    }
    final lease = _admission.begin();
    if (lease == null) return GoogleAuthState.busy;
    final generation = _sessions.generation;
    _lease = lease;
    _startingGeneration = generation;
    _busy = true;
    _show(GoogleAuthState.loading);

    bool active() => !_disposed && identical(_lease, lease);
    bool mayExchange() =>
        active() &&
        _sessions.isCurrent(generation) &&
        _sessions.phase == SessionPhase.signedOut;

    try {
      if (!mayExchange()) return GoogleAuthState.superseded;
      final result = await _repository.signIn(mayExchange: mayExchange);
      if (!active()) return GoogleAuthState.superseded;
      final receipt = result.receipt;
      if (receipt == null) {
        return mayExchange()
            ? _show(result.state)
            : _show(GoogleAuthState.superseded);
      }
      _show(GoogleAuthState.pendingAdmission);
      if (!active()) return GoogleAuthState.superseded;
      lease.approve(receipt.recognizes);
      final owner = await _waitForAdmission(receipt, generation, active);
      if (!active()) return GoogleAuthState.superseded;
      if (owner == null || _matchingOwner(receipt, generation) != owner) {
        return _show(GoogleAuthState.superseded);
      }
      _admittedOwner = owner;
      return _show(GoogleAuthState.admitted);
    } catch (_) {
      return mayExchange()
          ? _show(GoogleAuthState.unavailable)
          : GoogleAuthState.superseded;
    } finally {
      lease.close();
      if (identical(_lease, lease)) _lease = null;
      _startingGeneration = null;
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  BackendSession? _matchingOwner(AuthSessionReceipt receipt, int generation) {
    final owner = _sessions.backendSession;
    if (owner == null || _sessions.generation == generation) return null;
    final credential = _sessions.credentialFor(owner);
    return credential != null && receipt.recognizes(credential) ? owner : null;
  }

  Future<BackendSession?> _waitForAdmission(AuthSessionReceipt receipt,
      int generation, bool Function() active) async {
    final result = Completer<BackendSession?>();
    void check() {
      if (result.isCompleted) return;
      if (!active()) {
        result.complete(null);
      } else if (_sessions.backendSession != null) {
        result.complete(_matchingOwner(receipt, generation));
      }
    }

    _settle = check;
    try {
      check();
      return await result.future.timeout(_admissionWait, onTimeout: () => null);
    } finally {
      _settle = null;
    }
  }

  void _observe() {
    final owner = _admittedOwner;
    final phase = _sessions.phase;
    if (phase == SessionPhase.recovery ||
        phase == SessionPhase.unavailable ||
        (phase == SessionPhase.signedOut &&
            _startingGeneration != null &&
            _sessions.generation != _startingGeneration) ||
        (owner != null &&
            phase != SessionPhase.restoring &&
            _sessions.backendSession != owner)) {
      _invalidate();
      if (!_disposed) _show(GoogleAuthState.superseded);
      return;
    }
    _settle?.call();
  }

  void _invalidate() {
    _lease?.close();
    _lease = null;
    _admittedOwner = null;
    _settle?.call();
  }

  GoogleAuthState _show(GoogleAuthState value) {
    _state = value;
    notifyListeners();
    return value;
  }

  @override
  void dispose() {
    _disposed = true;
    _sessions.removeListener(_observe);
    _invalidate();
    super.dispose();
  }
}
