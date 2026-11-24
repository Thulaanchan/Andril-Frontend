import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/api_client/andril_api_client.dart';
import '../../core/security/session/session_controller.dart';
import '../onboarding/domain/onboarding_status_repository.dart';
import 'data/account_repository.dart';

/// In-memory handoff for the current ordinary session. The router has its own
/// authorization policy and never consumes this state as an entry grant.
class AccountHandoffController extends ChangeNotifier {
  AccountHandoffController(this._session, this._api)
      : _accounts = AccountRepository(_api),
        _onboarding = OnboardingStatusRepository(_api) {
    _unregister = _session.registerPrivateStateClearer(_clear);
    _session.addListener(_observe);
    _observe();
  }

  final SessionController _session;
  final AndrilApiClient _api;
  final AccountRepository _accounts;
  final OnboardingStatusRepository _onboarding;
  late final VoidCallback _unregister;
  BackendSession? _owner;
  Account? _account;
  OnboardingStatus? _status;
  HandoffFailure? _failure;
  Future<void>? _pending;
  final Stopwatch _retryClock = Stopwatch();
  bool _disposed = false;

  bool get loading => _pending != null;
  Account? get account => _account;
  OnboardingStatus? get status => _status;
  HandoffFailure? get failure => _failure;

  void _observe() {
    final owner = _session.backendSession;
    if (owner == null || owner == _owner) return;
    _owner = owner;
    unawaited(retry());
  }

  /// An explicit retry starts with GET, even after an uncertain initialize.
  Future<void> retry() {
    if (_disposed) return Future<void>.value();
    final pending = _pending;
    if (pending != null) return pending;
    final owner = _owner;
    final delay = _failure?.retryAfter;
    if (owner == null ||
        _session.backendSession != owner ||
        (delay != null && _retryClock.elapsed < delay)) {
      return Future<void>.value();
    }
    _failure = null;
    _account = null;
    _status = null;
    final work = _load(owner);
    _pending = work;
    notifyListeners();
    return work;
  }

  bool _isCurrent(BackendSession owner) =>
      !_disposed && _owner == owner && _session.backendSession == owner;

  Future<void> _load(BackendSession owner) async {
    try {
      final account = await _accounts.loadOrInitialize(owner);
      if (!_isCurrent(owner)) return;
      final status = await _onboarding.read(owner);
      if (!_isCurrent(owner)) return;
      _account = account;
      _status = status;
    } on HandoffFailure catch (error) {
      if (!_isCurrent(owner)) return;
      _failure = error;
      _retryClock
        ..reset()
        ..start();
    } finally {
      if (!_disposed && _owner == owner) {
        _pending = null;
        notifyListeners();
      }
    }
  }

  void _clear() {
    _owner = null;
    _account = null;
    _status = null;
    _failure = null;
    _pending = null;
    _retryClock
      ..stop()
      ..reset();
    _api.clearSession();
    // SessionController clears private state before it publishes its new phase.
    // Notify our listeners after that transition.
    scheduleMicrotask(() {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _unregister();
    _session.removeListener(_observe);
    _clear();
    _api.close();
    super.dispose();
  }
}
