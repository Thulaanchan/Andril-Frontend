import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/google_auth_repository.dart';

/// Test composition only. GoTrue can install a session during the token
/// exchange before the caller resumes, and the SDK writer is independent.
class NativeGoogleAuthRepository implements GoogleAuthRepository {
  @visibleForTesting
  NativeGoogleAuthRepository.forContractTests(
    this._google,
    this._auth, {
    required String? syntheticServerClientId,
  }) : _serverClientId = syntheticServerClientId;

  final GoogleSignIn _google;
  final GoTrueClient _auth;
  final String? _serverClientId;
  Future<void>? _initialization;
  static const _identityScopes = ['email'];

  @override
  Future<GoogleAuthResult> signIn(
      {required bool Function() mayExchange}) async {
    final clientId = _serverClientId;
    if (clientId == null || clientId.trim().isEmpty) {
      return const GoogleAuthResult(GoogleAuthState.configurationPending);
    }
    if (!mayExchange() || _auth.currentSession != null) {
      return const GoogleAuthResult(GoogleAuthState.superseded);
    }

    final String idToken;
    final String accessToken;
    try {
      _initialization ??= _google.initialize(serverClientId: clientId);
      await _initialization;
      if (!mayExchange() || _auth.currentSession != null) {
        return const GoogleAuthResult(GoogleAuthState.superseded);
      }
      if (!_google.supportsAuthenticate()) {
        return const GoogleAuthResult(GoogleAuthState.unavailable);
      }
      final account = await _google.authenticate(scopeHint: _identityScopes);
      if (!mayExchange() || _auth.currentSession != null) {
        return const GoogleAuthResult(GoogleAuthState.superseded);
      }
      final id = account.authentication.idToken;
      if (id == null || id.trim().isEmpty) {
        return const GoogleAuthResult(GoogleAuthState.credentialMissing);
      }
      // Inspect an existing identity-scope grant. This candidate does not
      // request extra authorization or open a separate consent prompt.
      final grant = await account.authorizationClient
          .authorizationForScopes(_identityScopes);
      final access = grant?.accessToken;
      if (access == null || access.trim().isEmpty) {
        return const GoogleAuthResult(GoogleAuthState.providerTokenMissing);
      }
      idToken = id;
      accessToken = access;
    } on GoogleSignInException catch (error) {
      return GoogleAuthResult(switch (error.code) {
        GoogleSignInExceptionCode.canceled => GoogleAuthState.cancelled,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          GoogleAuthState.configurationPending,
        GoogleSignInExceptionCode.interrupted ||
        GoogleSignInExceptionCode.uiUnavailable =>
          GoogleAuthState.unavailable,
        _ => GoogleAuthState.googleRejected,
      });
    } on TimeoutException {
      return const GoogleAuthResult(GoogleAuthState.unavailable);
    } on MissingPluginException {
      return const GoogleAuthResult(GoogleAuthState.unavailable);
    } catch (_) {
      return const GoogleAuthResult(GoogleAuthState.googleRejected);
    }

    // No await between the ownership check and dispatch to GoTrue.
    if (!mayExchange() || _auth.currentSession != null) {
      return const GoogleAuthResult(GoogleAuthState.superseded);
    }
    try {
      final response = await _auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken);
      final candidate = response.session;
      if (candidate == null ||
          candidate.user.id.trim().isEmpty ||
          candidate.accessToken.isEmpty ||
          candidate.isExpired) {
        return const GoogleAuthResult(GoogleAuthState.sessionMissing);
      }
      final user = candidate.user;
      if (user.isAnonymous == true ||
          DateTime.tryParse(user.emailConfirmedAt ?? '') == null) {
        return const GoogleAuthResult(GoogleAuthState.confirmationRequired);
      }
      final subject = user.id;
      final token = candidate.accessToken;
      if (_auth.currentSession?.accessToken != token ||
          _auth.currentSession?.user.id != subject) {
        return const GoogleAuthResult(GoogleAuthState.superseded);
      }
      return GoogleAuthResult.candidate(AuthSessionReceipt((credential) =>
          credential.subject == subject && credential.accessToken == token));
    } on AuthRetryableFetchException {
      return const GoogleAuthResult(GoogleAuthState.unavailable);
    } on TimeoutException {
      return const GoogleAuthResult(GoogleAuthState.unavailable);
    } catch (_) {
      return const GoogleAuthResult(GoogleAuthState.exchangeRejected);
    }
  }
}
