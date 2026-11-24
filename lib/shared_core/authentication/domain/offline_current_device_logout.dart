import 'package:flutter/foundation.dart';

import '../../../core/security/session/session_controller.dart';

enum LogoutOutcome {
  idle,
  signedOut,
  busy,
  boundaryUnavailable,
  cleanupFailed,
  superseded,
}

enum LogoutCleanup { completed, failed }

/// Implementations are test doubles in Part B. They must revoke through the
/// existing session source synchronously. The returned cleanup owns only the
/// ended session; it must never use an unscoped SDK sign-out or storage delete.
abstract interface class OfflineLogoutBoundary {
  Future<LogoutCleanup> Function() revokeCurrentDevice();
}

/// A local-device candidate, not a decision about production sign-out scope.
class OfflineCurrentDeviceLogout extends ChangeNotifier {
  @visibleForTesting
  OfflineCurrentDeviceLogout.forContractTests(this._session, this._boundary)
      : _generation = _session.generation {
    _session.addListener(_observe);
  }

  final SessionController _session;
  final OfflineLogoutBoundary _boundary;
  bool _busy = false;
  bool _disposed = false;
  LogoutOutcome _outcome = LogoutOutcome.idle;
  int _generation;

  bool get busy => _busy;
  LogoutOutcome get outcome => _outcome;

  Future<LogoutOutcome> run() async {
    if (_disposed) return LogoutOutcome.superseded;
    if (_busy) return LogoutOutcome.busy;
    if (_outcome == LogoutOutcome.signedOut &&
        _session.phase == SessionPhase.signedOut) return _outcome;
    _busy = true;
    _outcome = LogoutOutcome.idle;
    notifyListeners();
    try {
      if (_disposed) return LogoutOutcome.superseded;
      final generation = _session.generation;
      final cleanup = _boundary.revokeCurrentDevice();
      final revoked = _session.generation;
      if (generation == revoked ||
          _session.phase == SessionPhase.signedIn ||
          _session.phase == SessionPhase.recovery ||
          _session.backendSession != null) {
        return _outcome = LogoutOutcome.boundaryUnavailable;
      }
      LogoutCleanup result;
      try {
        result = await cleanup();
      } catch (_) {
        result = LogoutCleanup.failed;
      }
      if (_disposed) return LogoutOutcome.superseded;
      if (!_session.isCurrent(revoked)) {
        // The authoritative storage-failure state can advance the generation.
        // Report this caller's cleanup failure without publishing stale state.
        return result == LogoutCleanup.failed &&
                _session.phase == SessionPhase.unavailable
            ? LogoutOutcome.cleanupFailed
            : LogoutOutcome.superseded;
      }
      return _outcome = result == LogoutCleanup.completed &&
              _session.phase == SessionPhase.signedOut
          ? LogoutOutcome.signedOut
          : LogoutOutcome.cleanupFailed;
    } catch (_) {
      return _outcome = LogoutOutcome.boundaryUnavailable;
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _observe() {
    if (_session.generation == _generation) return;
    _generation = _session.generation;
    _outcome = LogoutOutcome.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _session.removeListener(_observe);
    _disposed = true;
    super.dispose();
  }
}
