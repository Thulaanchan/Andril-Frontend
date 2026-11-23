import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class DeviceSecureStore implements SecureKeyValueStore {
  DeviceSecureStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: false),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SecureStorageException implements Exception {
  const SecureStorageException();

  @override
  String toString() => 'Secure authentication storage unavailable.';
}

/// Serializes session, flow-receipt and PKCE operations in one secure namespace.
/// A storage failure latches this instance closed; no insecure fallback exists.
class SupabaseSecureStorage extends LocalStorage {
  SupabaseSecureStorage({
    required SecureKeyValueStore store,
    required String namespace,
  })  : _store = store,
        _namespace = namespace;

  final SecureKeyValueStore _store;
  final String _namespace;
  final _failures = StreamController<void>.broadcast(sync: true);
  Future<void> _tail = Future<void>.value();
  bool _failed = false;

  Stream<void> get failures => _failures.stream;
  bool get hasFailed => _failed;
  String _key(String suffix) => '$_namespace.$suffix';

  Future<T> _run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) async {
      if (_failed) throw const SecureStorageException();
      try {
        return await operation();
      } catch (_) {
        _failed = true;
        if (!_failures.isClosed) _failures.add(null);
        throw const SecureStorageException();
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<String?> readValue(String suffix) =>
      _run(() => _store.read(_key(suffix)));

  Future<void> writeValue(String suffix, String value) =>
      _run(() => _store.write(_key(suffix), value));

  Future<void> deleteValue(String suffix) =>
      _run(() => _store.delete(_key(suffix)));

  @override
  Future<void> initialize() async {
    await readValue('session');
  }

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  // The SDK interface calls the serialized session an "accessToken".
  @override
  Future<String?> accessToken() => readValue('session');

  @override
  Future<void> persistSession(String persistSessionString) =>
      writeValue('session', persistSessionString);

  @override
  Future<void> removePersistedSession() => deleteValue('session');

  Future<void> dispose() => _failures.close();
}

class SecurePkceStorage extends GotrueAsyncStorage {
  const SecurePkceStorage(this._storage);

  final SupabaseSecureStorage _storage;

  @override
  Future<String?> getItem({required String key}) =>
      _storage.readValue('pkce.$key');

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.writeValue('pkce.$key', value);

  @override
  Future<void> removeItem({required String key}) =>
      _storage.deleteValue('pkce.$key');
}
