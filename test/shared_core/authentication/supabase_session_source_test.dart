import 'dart:async';
import 'dart:convert';

import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/core/security/session/supabase_session_source.dart';
import 'package:andril_mobile/core/storage/secure/supabase_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'foundation_fakes.dart';

class MockAuth extends Mock implements GoTrueClient {}

Session syntheticSession({String subject = 'A', int revision = 1}) {
  final exp =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
  final payload = base64Url.encode(utf8.encode(jsonEncode({
    'sub': subject,
    'exp': exp,
    'revision': revision,
  })));
  return Session(
    accessToken: 'synthetic.$payload.signature',
    refreshToken: 'SYNTHETIC_REFRESH',
    tokenType: 'bearer',
    user: User(
      id: subject,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    ),
  );
}

void main() {
  late MockAuth auth;
  late StreamController<AuthState> events;
  late SupabaseSecureStorage storage;
  late SupabaseSessionSource source;
  late Session? current;
  setUp(() {
    auth = MockAuth();
    events = StreamController<AuthState>.broadcast(sync: true);
    current = syntheticSession();
    when(() => auth.currentSession).thenAnswer((_) => current);
    when(() => auth.onAuthStateChange).thenAnswer((_) => events.stream);
    storage = SupabaseSecureStorage(
        store: MemorySecureStore(), namespace: 'synthetic');
    source = SupabaseSessionSource(auth, storage);
  });
  tearDown(() async {
    await events.close();
    await storage.dispose();
  });

  test('ordinary flow receipt restores only its exact synthetic session',
      () async {
    final initial = await source.restore();
    await source.resolve(initial, recovery: false);
    final restored = await source.resolve(await source.restore());
    expect(restored.subject, 'A');
    expect(restored.recovery, false);
    current = syntheticSession(revision: 2);
    await expectLater(source.resolve(await source.restore()),
        throwsA(isA<SessionUnavailableException>()));
  });

  test('missing or malformed receipt fails closed', () async {
    await expectLater(source.resolve(await source.restore()),
        throwsA(isA<SessionUnavailableException>()));
    await storage.writeValue('flow', 'malformed');
    await expectLater(source.resolve(await source.restore()),
        throwsA(isA<SessionUnavailableException>()));
  });

  test('recovery disposition survives source recreation', () async {
    await source.resolve(await source.restore(), recovery: true);
    final recreated = SupabaseSessionSource(auth, storage);
    expect((await recreated.resolve(await recreated.restore())).recovery, true);
  });

  test('ordinary receipt for a different account is rejected', () async {
    await source.resolve(await source.restore(), recovery: false);
    current = syntheticSession(subject: 'B');
    await expectLater(source.resolve(await source.restore()),
        throwsA(isA<SessionUnavailableException>()));
  });

  test('expired or unparseable expiration cannot restore a signed-in state',
      () async {
    current!.expiresAt = 1;
    await expectLater(source.resolve(await source.restore(), recovery: false),
        throwsA(isA<SessionUnavailableException>()));
    current = syntheticSession()..expiresAt = null;
    await expectLater(source.resolve(await source.restore(), recovery: false),
        throwsA(isA<SessionUnavailableException>()));
  });

  test('SDK events map recovery and sign-out without exposing session text',
      () async {
    final received = <SessionEvent>[];
    final sub = source.events.listen(received.add);
    events.add(AuthState(AuthChangeEvent.passwordRecovery, current));
    events.add(AuthState(AuthChangeEvent.tokenRefreshed, current));
    events.add(AuthState(AuthChangeEvent.signedOut, current));
    expect(received.map((e) => e.kind), [
      SessionEventKind.recovery,
      SessionEventKind.refreshed,
      SessionEventKind.signedOut,
    ]);
    expect(received.last.subject, null);
    expect(received.first.toString(), isNot(contains(current!.accessToken)));
    expect(received.first.context.toString(),
        isNot(contains(current!.accessToken)));
    await sub.cancel();
  });

  test('sign out deletes the flow receipt', () async {
    await source.resolve(await source.restore(), recovery: false);
    await source.resolve(const SessionEvent(SessionEventKind.signedOut),
        recovery: false);
    expect(await storage.readValue('flow'), null);
  });

  test('real SDK events plus controller preserve recovery through refresh',
      () async {
    current = null;
    final controller = SessionController(source);
    await controller.start();
    current = syntheticSession();
    events.add(AuthState(AuthChangeEvent.passwordRecovery, current));
    await flushSessionWork();
    current = syntheticSession(revision: 2);
    events.add(AuthState(AuthChangeEvent.tokenRefreshed, current));
    await flushSessionWork();
    expect(controller.phase, SessionPhase.recovery);
    expect((await source.resolve(await source.restore())).recovery, true);
    controller.dispose();
  });

  test('real SDK events plus controller persist an ordinary refreshed token',
      () async {
    current = null;
    final controller = SessionController(source);
    await controller.start();
    current = syntheticSession();
    events.add(AuthState(AuthChangeEvent.signedIn, current));
    await flushSessionWork();
    current = syntheticSession(revision: 2);
    events.add(AuthState(AuthChangeEvent.tokenRefreshed, current));
    await flushSessionWork();
    expect(controller.phase, SessionPhase.signedIn);
    expect((await source.resolve(await source.restore())).recovery, false);
    controller.dispose();
  });
}
