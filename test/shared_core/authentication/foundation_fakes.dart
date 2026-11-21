import 'dart:async';

import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/core/storage/secure/supabase_secure_storage.dart';

class MemorySecureStore implements SecureKeyValueStore {
  final values = <String, String>{};
  final operations = <String>[];
  bool fail = false;

  void _check(String operation) {
    operations.add(operation);
    if (fail) throw StateError('SYNTHETIC_PRIVATE_VALUE');
  }

  @override
  Future<String?> read(String key) async {
    _check('read');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _check('write');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _check('delete');
    values.remove(key);
  }
}

class FakeSessionSource implements SessionSource {
  FakeSessionSource({SessionEvent? restored})
      : restored = restored ?? const SessionEvent(SessionEventKind.initial) {
    signals = StreamController<SessionEvent>.broadcast(
      sync: true,
      onListen: () => listens++,
      onCancel: () => cancellations++,
    );
  }

  late final StreamController<SessionEvent> signals;
  SessionEvent restored;
  int listens = 0;
  int cancellations = 0;
  bool restoredRecovery = false;
  Future<SessionEvent>? pendingRestore;
  final Map<String, Completer<SessionResolution>> pending = {};
  final List<bool?> modes = [];
  bool failResolution = false;

  @override
  Stream<SessionEvent> get events => signals.stream;

  @override
  Future<SessionEvent> restore() async => pendingRestore ?? restored;

  @override
  Future<SessionResolution> resolve(SessionEvent event,
      {bool? recovery}) async {
    modes.add(recovery);
    if (failResolution) throw StateError('SYNTHETIC_PRIVATE_VALUE');
    final delayed = pending[event.subject];
    if (delayed != null) return delayed.future;
    return SessionResolution(event.subject,
        recovery: recovery ?? restoredRecovery);
  }
}

Future<void> flushSessionWork() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
