import 'dart:async';

import 'package:flutter/foundation.dart';

enum SessionPhase { restoring, signedOut, signedIn, recovery, unavailable }

enum SessionEventKind {
  initial,
  signedIn,
  refreshed,
  signedOut,
  recovery,
  updated
}

/// Opaque source context is never exposed by SessionController to presentation.
class SessionEvent {
  const SessionEvent(this.kind, {this.subject, this.context});

  final SessionEventKind kind;
  final String? subject;
  final Object? context;

  @override
  String toString() => 'SessionEvent(${kind.name}, context redacted)';
}

class SessionResolution {
  const SessionResolution(this.subject, {required this.recovery});

  final String? subject;
  final bool recovery;
}

abstract interface class SessionSource {
  Stream<SessionEvent> get events;
  Future<SessionEvent> restore();

  /// Null recovery means restore only from a matching durable flow receipt.
  Future<SessionResolution> resolve(SessionEvent event, {bool? recovery});
}

/// Authentication state only: signedIn never authorizes an ANDRIL module.
class SessionController extends ChangeNotifier {
  SessionController(this._source, {Stream<void>? storageFailures}) {
    _storageSubscription = storageFailures?.listen((_) {
      _storageFailed = true;
      _fail();
    });
  }

  final SessionSource _source;
  StreamSubscription<SessionEvent>? _subscription;
  StreamSubscription<void>? _storageSubscription;
  final Set<VoidCallback> _privateStateClearers = {};
  Future<void>? _start;
  SessionPhase _phase = SessionPhase.restoring;
  String? _subject;
  String? _identity;
  String? _ordinaryIdentity;
  int _generation = 0;
  bool _recovery = false;
  bool _disposed = false;
  bool _storageFailed = false;
  bool _settled = false;

  SessionPhase get phase => _phase;
  String? get subject => _subject;
  int get generation => _generation;
  bool get moduleHomeAuthorized => false;
  bool isCurrent(int generation) => !_disposed && generation == _generation;

  VoidCallback registerPrivateStateClearer(VoidCallback clear) {
    _privateStateClearers.add(clear);
    return () => _privateStateClearers.remove(clear);
  }

  Future<void> start() => _start ??= _restore();

  Future<void> _restore() async {
    if (_disposed || _storageFailed) return;
    _subscription = _source.events.listen(
      (event) => unawaited(_handle(event)),
      onError: (Object _, StackTrace __) => _fail(),
      onDone: _fail,
    );
    final ticket = _generation;
    try {
      final event = await _source.restore();
      if (isCurrent(ticket)) await _handle(event);
    } catch (_) {
      if (isCurrent(ticket)) _fail();
    }
  }

  Future<void> _handle(SessionEvent event) async {
    if (_disposed || _storageFailed) return;
    final ordinarySessionActive =
        event.subject != null && event.subject == _ordinaryIdentity;
    final ticket = ++_generation;
    final signedOut = event.kind == SessionEventKind.signedOut;
    final changed = event.subject != _identity;
    if (changed || signedOut) _ordinaryIdentity = null;
    if (signedOut || changed || event.kind == SessionEventKind.recovery) {
      if (!_clearPrivateState()) {
        _fail();
        return;
      }
    }
    // Recovery is latched until an explicit signed-out boundary, even if the
    // SDK subsequently emits signedIn or tokenRefreshed for the same flow.
    if (signedOut) _recovery = false;
    if (event.kind == SessionEventKind.recovery) _recovery = true;
    _identity = event.subject;
    // Keep the mounted navigation tree during a refresh of the active account.
    // Resolution failures still transition to unavailable and clear private state.
    final refreshingActiveSession = event.kind == SessionEventKind.refreshed &&
        _phase == SessionPhase.signedIn &&
        _subject == event.subject &&
        ordinarySessionActive;
    if (!refreshingActiveSession) {
      _subject = null;
      _phase = SessionPhase.restoring;
    }
    notifyListeners();
    final bool? recovery;
    if (signedOut) {
      recovery = false;
    } else if (_recovery) {
      recovery = true;
    } else if (event.kind == SessionEventKind.signedIn && _settled) {
      recovery = false;
    } else if (ordinarySessionActive) {
      recovery = false;
    } else {
      recovery = null;
    }
    if (recovery == false && !signedOut) _ordinaryIdentity = event.subject;
    try {
      final resolved = await _source.resolve(event, recovery: recovery);
      if (!isCurrent(ticket)) return;
      if (resolved.subject != event.subject) {
        _fail();
        return;
      }
      _recovery = resolved.recovery;
      _settled = true;
      _ordinaryIdentity = resolved.recovery ? null : resolved.subject;
      _subject = resolved.subject;
      _phase = _subject == null
          ? SessionPhase.signedOut
          : _recovery
              ? SessionPhase.recovery
              : SessionPhase.signedIn;
      notifyListeners();
    } catch (_) {
      if (isCurrent(ticket)) _fail();
    }
  }

  bool _clearPrivateState() {
    var success = true;
    for (final clear in List<VoidCallback>.of(_privateStateClearers)) {
      try {
        clear();
      } catch (_) {
        success = false;
      }
    }
    return success;
  }

  void _fail() {
    if (_disposed) return;
    ++_generation;
    _clearPrivateState();
    _subject = null;
    _ordinaryIdentity = null;
    _settled = false;
    _phase = SessionPhase.unavailable;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    unawaited(_subscription?.cancel());
    unawaited(_storageSubscription?.cancel());
    _clearPrivateState();
    _privateStateClearers.clear();
    _subject = null;
    _identity = null;
    _ordinaryIdentity = null;
    super.dispose();
  }
}
