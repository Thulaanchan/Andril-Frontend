import 'package:andril_mobile/core/storage/secure/supabase_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_fakes.dart';

void main() {
  late MemorySecureStore device;
  late SupabaseSecureStorage storage;
  setUp(() {
    device = MemorySecureStore();
    storage = SupabaseSecureStorage(store: device, namespace: 'synthetic');
  });
  tearDown(() => storage.dispose());

  test('SDK session interface reads writes and deletes secure session',
      () async {
    await storage.initialize();
    expect(await storage.hasAccessToken(), false);
    await storage.persistSession('SYNTHETIC_SESSION');
    expect(await storage.accessToken(), 'SYNTHETIC_SESSION');
    expect(await storage.hasAccessToken(), true);
    await storage.removePersistedSession();
    expect(await storage.accessToken(), null);
  });

  test('PKCE interface uses the same secure store with distinct keys',
      () async {
    final pkce = SecurePkceStorage(storage);
    await storage.persistSession('SESSION');
    await pkce.setItem(key: 'verifier', value: 'SYNTHETIC_VERIFIER');
    expect(await pkce.getItem(key: 'verifier'), 'SYNTHETIC_VERIFIER');
    await pkce.removeItem(key: 'verifier');
    expect(await pkce.getItem(key: 'verifier'), null);
    expect(await storage.accessToken(), 'SESSION');
  });

  for (final operation in ['read', 'write', 'delete']) {
    test('$operation failure is sanitized and latches storage closed',
        () async {
      var failures = 0;
      final sub = storage.failures.listen((_) => failures++);
      device.fail = true;
      final task = switch (operation) {
        'read' => storage.accessToken(),
        'write' => storage.persistSession('PRIVATE'),
        _ => storage.removePersistedSession(),
      };
      await expectLater(
          task,
          throwsA(isA<SecureStorageException>().having((e) => e.toString(),
              'safe message', isNot(contains('PRIVATE')))));
      device.fail = false;
      await expectLater(
          storage.accessToken(), throwsA(isA<SecureStorageException>()));
      expect(device.operations, [operation]);
      expect(failures, 1);
      await sub.cancel();
    });
  }

  test('concurrent persistence then deletion cannot resurrect a session',
      () async {
    final write = storage.persistSession('SESSION');
    final deletion = storage.removePersistedSession();
    await Future.wait([write, deletion]);
    expect(await storage.accessToken(), null);
  });

  test('different namespaces cannot read each other', () async {
    final other = SupabaseSecureStorage(store: device, namespace: 'other');
    await storage.persistSession('PRIVATE');
    expect(await other.accessToken(), null);
    await other.dispose();
  });
}
