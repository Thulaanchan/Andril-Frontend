import 'dart:async';

import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/shared_core/authentication/data/repositories/native_google_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/repositories/google_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'google_contract_fakes.dart';

class _Auth extends Mock implements GoTrueClient {}

void main() {
  late _Auth auth;
  setUp(() {
    auth = _Auth();
    when(() => auth.currentSession).thenReturn(null);
  });

  Future<GoogleAuthResult> attempt(MockGoogle google,
          {String? client = googleClientId}) =>
      NativeGoogleAuthRepository.forContractTests(google, auth,
              syntheticServerClientId: client)
          .signIn(mayExchange: () => true);

  const cancelled = GoogleSignInException(
      code: GoogleSignInExceptionCode.canceled, description: googleId);
  const misconfigured = GoogleSignInException(
      code: GoogleSignInExceptionCode.clientConfigurationError);
  final failures = <String, (MockGoogle Function(), GoogleAuthState)>{
    'cancelled': (
      () => syntheticGoogle(error: cancelled),
      GoogleAuthState.cancelled
    ),
    'unsupported': (
      () => syntheticGoogle(supported: false),
      GoogleAuthState.unavailable
    ),
    'provider configuration error': (
      () => syntheticGoogle(error: misconfigured),
      GoogleAuthState.configurationPending
    ),
    'provider failure': (
      () => syntheticGoogle(error: StateError(googleAccess)),
      GoogleAuthState.googleRejected
    ),
    'missing identity token': (
      () => syntheticGoogle(id: null),
      GoogleAuthState.credentialMissing
    ),
    'missing access token': (
      () => syntheticGoogle(access: null),
      GoogleAuthState.providerTokenMissing
    ),
    'provider timeout': (
      () => syntheticGoogle(error: TimeoutException('synthetic')),
      GoogleAuthState.unavailable
    ),
  };

  for (final MapEntry(key: name, value: (google, expected))
      in failures.entries) {
    test('$name fails safely before token exchange', () async {
      final result = await attempt(google());
      expect(result.state, expected);
      expect(result.receipt, isNull);
      verifyNever(() => auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleId,
          accessToken: googleAccess));
    });
  }

  test('missing configuration never invokes the native SDK', () async {
    final google = syntheticGoogle();
    expect((await attempt(google, client: ' ')).state,
        GoogleAuthState.configurationPending);
    verifyZeroInteractions(google);
  });

  test('lost lifecycle while provider is pending prevents any exchange',
      () async {
    final pending = Completer<void>();
    final google = syntheticGoogle(beforeResult: pending.future);
    final repo = NativeGoogleAuthRepository.forContractTests(google, auth,
        syntheticServerClientId: googleClientId);
    var current = true;
    final attempt = repo.signIn(mayExchange: () => current);
    await Future<void>.delayed(Duration.zero);
    current = false;
    pending.complete();
    expect((await attempt).state, GoogleAuthState.superseded);
    verifyNever(() => auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleId,
        accessToken: googleAccess));
  });

  test('initialization occurs once per inactive adapter', () async {
    final google = syntheticGoogle(error: cancelled);
    final repo = NativeGoogleAuthRepository.forContractTests(google, auth,
        syntheticServerClientId: googleClientId);
    await repo.signIn(mayExchange: () => true);
    await repo.signIn(mayExchange: () => true);
    verify(() => google.initialize(serverClientId: googleClientId)).called(1);
  });

  void respond(AuthResponse response) {
    when(() => auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleId,
        accessToken: googleAccess)).thenAnswer((_) async => response);
  }

  const confirmed = User(
      id: 'owner',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
      emailConfirmedAt: '2026-01-01T00:00:00Z');
  Session session(User user, {String token = 'synthetic-session'}) =>
      Session(accessToken: token, tokenType: 'bearer', user: user);

  test('sessionless exchange cannot produce a receipt', () async {
    respond(AuthResponse(user: confirmed));
    expect((await attempt(syntheticGoogle())).state,
        GoogleAuthState.sessionMissing);
  });

  test('exchange cannot admit a session without a verified subject', () async {
    respond(AuthResponse(
        session: session(const User(
            id: ' ',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: '2026-01-01'))));
    expect((await attempt(syntheticGoogle())).state,
        GoogleAuthState.sessionMissing);
  });

  test('exchange timeout is safely mapped', () async {
    when(() => auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleId,
        accessToken: googleAccess)).thenThrow(TimeoutException(googleId));
    expect(
        (await attempt(syntheticGoogle())).state, GoogleAuthState.unavailable);
  });

  test('receipt binds both Supabase subject and the exact credential',
      () async {
    final candidate = session(confirmed);
    when(() => auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleId,
        accessToken: googleAccess)).thenAnswer((_) async {
      when(() => auth.currentSession).thenReturn(candidate);
      return AuthResponse(session: candidate);
    });
    final result = await attempt(syntheticGoogle());
    expect(result.state, GoogleAuthState.pendingAdmission);
    BackendCredential credential(String subject, String token) =>
        BackendCredential(subject, token, emailConfirmed: true);
    final receipt = result.receipt!;
    expect(receipt.recognizes(credential('other', candidate.accessToken)),
        isFalse);
    expect(receipt.recognizes(credential(confirmed.id, 'old-token')), isFalse);
    expect(receipt.recognizes(credential(confirmed.id, candidate.accessToken)),
        isTrue);
  });

  test('an exchange whose SDK owner has changed is superseded', () async {
    final candidate = session(confirmed);
    const other = User(
        id: 'new-owner',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        emailConfirmedAt: '2026-01-01T00:00:00Z');
    when(() => auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleId,
        accessToken: googleAccess)).thenAnswer((_) async {
      when(() => auth.currentSession)
          .thenReturn(session(other, token: 'new-token'));
      return AuthResponse(session: candidate);
    });
    expect(
        (await attempt(syntheticGoogle())).state, GoogleAuthState.superseded);
  });
}
