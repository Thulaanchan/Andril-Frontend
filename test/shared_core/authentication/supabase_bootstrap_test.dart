import 'package:andril_mobile/app/dependencies/supabase_bootstrap.dart';
import 'package:andril_mobile/core/storage/secure/supabase_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_config_test.dart' as fixture;
import 'foundation_fakes.dart';

void main() {
  test('concurrent and repeated bootstrap calls initialize exactly once',
      () async {
    final source = FakeSessionSource();
    final storage = SupabaseSecureStorage(
        store: MemorySecureStore(), namespace: 'synthetic');
    var calls = 0;
    final bootstrap = SupabaseBootstrap(
      config: fixture.config(),
      storage: storage,
      initialize: (config, secure) async {
        calls++;
        expect(identical(secure, storage), true);
        return source;
      },
    );
    final first = bootstrap.start();
    final second = bootstrap.start();
    expect(identical(first, second), true);
    final controller = await first;
    expect(identical(controller, await bootstrap.start()), true);
    expect(calls, 1);
    expect(source.listens, 1);
    controller.dispose();
    await source.signals.close();
    await storage.dispose();
  });

  test('failed storage prevents SDK initialization without retry/fallback',
      () async {
    final device = MemorySecureStore()..fail = true;
    final storage =
        SupabaseSecureStorage(store: device, namespace: 'synthetic');
    var calls = 0;
    final bootstrap = SupabaseBootstrap(
      config: fixture.config(),
      storage: storage,
      initialize: (_, __) async {
        calls++;
        return FakeSessionSource();
      },
    );
    await expectLater(
        bootstrap.start(), throwsA(isA<SecureStorageException>()));
    await expectLater(
        bootstrap.start(), throwsA(isA<SecureStorageException>()));
    expect(calls, 0);
    await storage.dispose();
  });
}
