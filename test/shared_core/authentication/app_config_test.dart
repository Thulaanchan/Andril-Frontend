import 'dart:convert';

import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

AppConfig config({
  String environment = 'development',
  String url = 'https://synthetic.supabase.co',
  String key = 'sb_publishable_SYNTHETIC_ONLY',
  String backend = 'https://backend.invalid',
}) =>
    AppConfig.fromValues(
      environment: environment,
      supabaseUrl: url,
      publicKey: key,
      apiBaseUrl: backend,
    );

void main() {
  test('accepts public HTTPS configuration and isolates environments', () {
    final value = config();
    expect(value.apiBaseUrl.scheme, 'https');
    expect(value.storageNamespace,
        isNot(config(environment: 'staging').storageNamespace));
    expect(value.toString(), isNot(contains(value.publicKey)));
  });

  for (final url in [
    '',
    'http://synthetic.supabase.co',
    'https://user:password@synthetic.supabase.co',
    'https://synthetic.supabase.co?token=private',
    'https://synthetic.supabase.co#private',
    'https://synthetic.supabase.co/auth',
    'https://supabase.co.attacker.invalid',
  ]) {
    test('rejects unsafe Supabase URL case ${url.hashCode}', () {
      expect(() => config(url: url), throwsA(isA<ConfigurationException>()));
    });
  }

  test('rejects missing, secret and service-role keys without echoing values',
      () {
    final payload = base64Url.encode(utf8.encode('{"role":"service_role"}'));
    for (final key in ['', 'sb_secret_PRIVATE', 'header.$payload.signature']) {
      try {
        config(key: key);
        fail('Invalid key accepted');
      } on ConfigurationException catch (error) {
        expect(error.toString(), isNot(contains('PRIVATE')));
      }
    }
  });

  test('accepts anon key shape without claiming signature verification', () {
    final payload = base64Url.encode(utf8.encode('{"role":"anon"}'));
    expect(config(key: 'header.$payload.signature'), isA<AppConfig>());
  });

  test('rejects unknown environment and unsafe backend URLs', () {
    expect(() => config(environment: 'unknown'),
        throwsA(isA<ConfigurationException>()));
    for (final backend in [
      '',
      'http://localhost',
      'https://host.invalid?key=x'
    ]) {
      expect(() => config(backend: backend),
          throwsA(isA<ConfigurationException>()));
    }
  });
}
