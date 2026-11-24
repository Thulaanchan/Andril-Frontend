import 'dart:convert';

/// Public build configuration only. Never include privileged provider keys.
class AppConfig {
  AppConfig._(
      this.environment, this.supabaseUrl, this.publicKey, this.apiBaseUrl);

  final String environment;
  final Uri supabaseUrl;
  final String publicKey;
  final Uri apiBaseUrl;

  String get storageNamespace =>
      'andril.auth.v1.$environment.${supabaseUrl.host}';

  factory AppConfig.fromEnvironment() => AppConfig.fromValues(
        environment: const String.fromEnvironment('ANDRIL_ENV',
            defaultValue: 'development'),
        supabaseUrl: const String.fromEnvironment('ANDRIL_SUPABASE_URL'),
        publicKey: const String.fromEnvironment('ANDRIL_SUPABASE_PUBLIC_KEY'),
        apiBaseUrl: const String.fromEnvironment('ANDRIL_API_BASE_URL'),
      );

  factory AppConfig.fromValues({
    required String environment,
    required String supabaseUrl,
    required String publicKey,
    required String apiBaseUrl,
  }) {
    if (!const {'development', 'staging', 'production'}.contains(environment)) {
      throw const ConfigurationException();
    }
    final supabase = _httpsUrl(supabaseUrl);
    final backend = _httpsUrl(apiBaseUrl);
    if (!supabase.host.endsWith('.supabase.co') ||
        supabase.host == '.supabase.co' ||
        (supabase.path.isNotEmpty && supabase.path != '/') ||
        !_isPublicKey(publicKey)) {
      throw const ConfigurationException();
    }
    return AppConfig._(environment, supabase, publicKey, backend);
  }

  static Uri _httpsUrl(String value) {
    final uri = Uri.tryParse(value);
    if (value.isEmpty ||
        value.trim() != value ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const ConfigurationException();
    }
    return uri;
  }

  static bool _isPublicKey(String value) {
    if (RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$').hasMatch(value)) return true;
    // This checks key type, not signature validity or deployment readiness.
    try {
      final parts = value.split('.');
      if (parts.length != 3 || parts.any((part) => part.isEmpty)) return false;
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      return payload is Map && payload['role'] == 'anon';
    } catch (_) {
      return false;
    }
  }

  @override
  String toString() => 'AppConfig(public values redacted)';
}

class ConfigurationException implements Exception {
  const ConfigurationException();

  @override
  String toString() => 'Authentication configuration is missing or invalid.';
}
