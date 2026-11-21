import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_config.dart';
import '../../core/security/session/session_controller.dart';
import '../../core/security/session/supabase_session_source.dart';
import '../../core/storage/secure/supabase_secure_storage.dart';

typedef SupabaseInitializer = Future<SessionSource> Function(
  AppConfig config,
  SupabaseSecureStorage storage,
);

class SupabaseBootstrap {
  SupabaseBootstrap({
    required AppConfig config,
    required SupabaseSecureStorage storage,
    SupabaseInitializer? initialize,
  })  : _config = config,
        _storage = storage,
        _initialize = initialize ?? _initializeSdk;

  final AppConfig _config;
  final SupabaseSecureStorage _storage;
  final SupabaseInitializer _initialize;
  Future<SessionController>? _initialization;

  /// Includes failures: retry requires a fresh application bootstrap, not a
  /// second SDK initialization over partially initialized storage/session state.
  Future<SessionController> start() => _initialization ??= _start();

  Future<SessionController> _start() async {
    await _storage.initialize();
    final source = await _initialize(_config, _storage);
    if (_storage.hasFailed) throw const SecureStorageException();
    final controller =
        SessionController(source, storageFailures: _storage.failures);
    await controller.start();
    return controller;
  }

  static Future<SessionSource> _initializeSdk(
      AppConfig config, SupabaseSecureStorage storage) async {
    final sdk = await Supabase.initialize(
      url: config.supabaseUrl.toString(),
      publishableKey: config.publicKey,
      debug: false,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
        localStorage: storage,
        pkceAsyncStorage: SecurePkceStorage(storage),
        // Callback URI approval and Android integration belong to AUTH-03C.
        detectSessionInUri: false,
      ),
    );
    return SupabaseSessionSource(sdk.client.auth, storage);
  }
}

Future<SessionController>? _foundation;

Future<SessionController> initializeAuthFoundation() =>
    _foundation ??= _createFoundation();

Future<SessionController> _createFoundation() async {
  final config = AppConfig.fromEnvironment();
  return SupabaseBootstrap(
    config: config,
    storage: SupabaseSecureStorage(
      store: DeviceSecureStore(),
      namespace: config.storageNamespace,
    ),
  ).start();
}
