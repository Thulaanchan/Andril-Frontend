import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../storage/secure/supabase_secure_storage.dart';
import 'session_controller.dart';

class SessionUnavailableException implements Exception {
  const SessionUnavailableException();

  @override
  String toString() => 'Authentication session unavailable.';
}

class _SessionContext {
  const _SessionContext(this.session);
  final Session session;

  @override
  String toString() => 'Session context redacted';
}

/// Keeps SDK sessions/tokens outside presentation state. It makes no backend
/// authorization or email-verification claim.
class SupabaseSessionSource implements SessionSource, BackendSessionSource {
  SupabaseSessionSource(this._auth, this._storage);

  final GoTrueClient _auth;
  final SupabaseSecureStorage _storage;
  String? _ordinaryAccessToken;

  @override
  BackendCredential? get backendCredential {
    final session = _auth.currentSession;
    // The SDK may replace currentSession before publishing its auth event.
    // A new token is ineligible until its flow has been classified.
    if (session == null || session.accessToken != _ordinaryAccessToken) {
      return null;
    }
    final confirmedAt = session.user.emailConfirmedAt;
    return BackendCredential(session.user.id, session.accessToken,
        emailConfirmed: confirmedAt != null &&
            DateTime.tryParse(confirmedAt) != null &&
            session.user.isAnonymous != true);
  }

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {
    final current = _auth.currentSession;
    if (current?.user.id != rejected.subject ||
        current?.accessToken != rejected.accessToken ||
        current?.accessToken != _ordinaryAccessToken) {
      return;
    }
    // The SDK coordinates refreshes and discards results after a session change.
    await _auth.refreshSession();
  }

  SessionEvent _event(SessionEventKind kind, Session? session) => SessionEvent(
        kind,
        subject: session?.user.id,
        context: session == null ? null : _SessionContext(session),
      );

  @override
  Stream<SessionEvent> get events => _auth.onAuthStateChange.map((state) {
        final kind = switch (state.event) {
          AuthChangeEvent.initialSession => SessionEventKind.initial,
          AuthChangeEvent.signedIn => SessionEventKind.signedIn,
          AuthChangeEvent.signedOut => SessionEventKind.signedOut,
          AuthChangeEvent.passwordRecovery => SessionEventKind.recovery,
          AuthChangeEvent.tokenRefreshed => SessionEventKind.refreshed,
          _ => SessionEventKind.updated,
        };
        return _event(
            kind, kind == SessionEventKind.signedOut ? null : state.session);
      });

  @override
  Future<SessionEvent> restore() async =>
      _event(SessionEventKind.initial, _auth.currentSession);

  @override
  Future<SessionResolution> resolve(SessionEvent event,
      {bool? recovery}) async {
    if (event.kind == SessionEventKind.signedOut) {
      _ordinaryAccessToken = null;
      await _storage.deleteValue('flow');
      return const SessionResolution(null, recovery: false);
    }
    final context = event.context;
    if (context == null && event.subject == null) {
      return const SessionResolution(null, recovery: false);
    }
    if (context is! _SessionContext ||
        context.session.user.id != event.subject ||
        context.session.expiresAt == null ||
        context.session.isExpired ||
        context.session.accessToken.isEmpty) {
      throw const SessionUnavailableException();
    }
    final session = context.session;
    if (session.accessToken == _auth.currentSession?.accessToken) {
      // An already classified ordinary refresh can service queued reads.
      // SessionController still closes the boundary if receipt storage fails.
      _ordinaryAccessToken =
          event.kind == SessionEventKind.refreshed && recovery == false
              ? session.accessToken
              : null;
    }
    if (recovery == null) {
      // A receipt matches this exact token, never just an email or user UUID.
      // Missing/stale receipts fail closed rather than promote recovery after
      // a restart. SDK refresh events can be classified only after restoration.
      try {
        final raw = await _storage.readValue('flow');
        final receipt = raw == null ? null : jsonDecode(raw);
        if (receipt is! Map ||
            receipt['token'] != session.accessToken ||
            receipt['recovery'] is! bool) {
          throw const SessionUnavailableException();
        }
        recovery = receipt['recovery'] as bool;
      } catch (_) {
        throw const SessionUnavailableException();
      }
    } else {
      await _storage.writeValue(
          'flow',
          jsonEncode({
            'token': session.accessToken,
            'recovery': recovery,
          }));
    }
    if (session.accessToken == _auth.currentSession?.accessToken) {
      _ordinaryAccessToken = recovery ? null : session.accessToken;
    }
    return SessionResolution(event.subject, recovery: recovery);
  }
}
