import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../constants/app_config.dart';
import '../../security/session/session_controller.dart';

enum AccountEndpoint {
  me('GET', '/api/v1/account/me'),
  initialize('POST', '/api/v1/account/initialize'),
  onboarding('GET', '/api/v1/onboarding/status');

  const AccountEndpoint(this.method, this.path);
  final String method;
  final String path;
}

enum HandoffIssue {
  reauthenticationRequired,
  verificationRequired,
  forbidden,
  accountNotInitialized,
  rateLimited,
  unavailable,
  invalidResponse,
  sessionChanged,
}

/// Exposes only allowlisted error information, never a Dio error or body.
class HandoffFailure implements Exception {
  const HandoffFailure(this.issue, {this.retryAfter});
  final HandoffIssue issue;
  final Duration? retryAfter;

  @override
  String toString() => 'HandoffFailure(' + issue.name + ')';
}

class AndrilApiClient {
  AndrilApiClient(AppConfig config, this._session, {HttpClientAdapter? adapter})
      : _origin = _validateOrigin(config.apiBaseUrl),
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
        )) {
    _dio.httpClientAdapter = _DispatchAdapter(
      adapter ?? _dio.httpClientAdapter,
      _credential,
    );
  }

  final Uri _origin;
  final Dio _dio;
  final SessionController _session;
  ({BackendSession session, String token, Future<void> done})? _refresh;
  bool _closed = false;

  static Uri _validateOrigin(Uri uri) {
    // The contract uses root paths. Browser transports may follow redirects
    // even when Dio's native followRedirects flag is false.
    if (kIsWeb ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.authority.contains('@') ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const ConfigurationException();
    }
    return Uri.parse(uri.origin);
  }

  BackendCredential _credential(BackendSession session) {
    if (_closed || _session.backendSession != session) {
      throw const HandoffFailure(HandoffIssue.sessionChanged);
    }
    final credential = _session.credentialFor(session);
    if (credential == null ||
        RegExp(r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$')
                .stringMatch(credential.accessToken) !=
            credential.accessToken) {
      throw const HandoffFailure(HandoffIssue.reauthenticationRequired);
    }
    if (!credential.emailConfirmed) {
      throw const HandoffFailure(HandoffIssue.verificationRequired);
    }
    return credential;
  }

  Future<Map<String, Object?>> request(
      AccountEndpoint endpoint, BackendSession session) async {
    final initial = await _send(endpoint, session);
    final dispatched = initial.credential;
    var response = initial.response;
    // Automatic replay is limited to reads. An uncertain initialize can be
    // recovered by starting from the authoritative GET.
    if (response.statusCode == 401 && endpoint.method == 'GET') {
      final current = _credential(session);
      if (current.accessToken == dispatched.accessToken) {
        await _refreshOnce(session, current);
      }
      final replacement = _credential(session);
      if (replacement.accessToken != dispatched.accessToken) {
        response = (await _send(endpoint, session)).response;
      }
    }
    return _interpret(endpoint, response);
  }

  Future<void> _refreshOnce(
      BackendSession session, BackendCredential rejected) {
    final active = _refresh;
    if (active != null &&
        active.session == session &&
        active.token == rejected.accessToken) {
      return active.done;
    }
    final done = _session
        .refreshBackendCredential(session, rejected)
        .timeout(const Duration(seconds: 12))
        .then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _refresh = (session: session, token: rejected.accessToken, done: done);
    return done;
  }

  Future<({Response<String> response, BackendCredential credential})> _send(
      AccountEndpoint endpoint, BackendSession session) async {
    _credential(session);
    final dispatch = _Dispatch(session);
    Response<String> response;
    try {
      response = await _dio.requestUri<String>(
        _origin.replace(path: endpoint.path),
        options: Options(
          method: endpoint.method,
          headers: {'Accept': 'application/json, application/problem+json'},
          extra: {_Dispatch.key: dispatch},
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
          followRedirects: false,
          maxRedirects: 0,
        ),
      );
    } catch (_) {
      _credential(session);
      throw const HandoffFailure(HandoffIssue.unavailable);
    }
    _credential(session);
    return (response: response, credential: dispatch.credential!);
  }

  Map<String, Object?> _interpret(
      AccountEndpoint endpoint, Response<String> response) {
    final status = response.statusCode;
    final contentTypes = response.headers['content-type'];
    final mediaType = contentTypes?.length == 1
        ? contentTypes!.single.split(';').first.trim().toLowerCase()
        : null;
    final json = _object(response.data);
    if (status == 200 && mediaType == 'application/json' && json != null) {
      return json;
    }
    final problem =
        mediaType == 'application/problem+json' && json?['status'] == status;
    switch (status) {
      case 401:
        throw const HandoffFailure(HandoffIssue.reauthenticationRequired);
      case 403:
        throw HandoffFailure(
            problem && json?['title'] == 'Email confirmation required'
                ? HandoffIssue.verificationRequired
                : HandoffIssue.forbidden);
      case 404:
        if (endpoint == AccountEndpoint.me &&
            problem &&
            json?['title'] == 'Account not initialized') {
          throw const HandoffFailure(HandoffIssue.accountNotInitialized);
        }
        throw const HandoffFailure(HandoffIssue.unavailable);
      case 429:
        final values = response.headers['retry-after'];
        final value = values?.length == 1 ? values!.single.trim() : null;
        final seconds = value != null && RegExp(r'^[0-9]{1,9}$').hasMatch(value)
            ? int.tryParse(value)
            : null;
        throw HandoffFailure(HandoffIssue.rateLimited,
            retryAfter: seconds == null ? null : Duration(seconds: seconds));
      case 200:
        throw const HandoffFailure(HandoffIssue.invalidResponse);
      default:
        throw const HandoffFailure(HandoffIssue.unavailable);
    }
  }

  static Map<String, Object?>? _object(String? body) {
    try {
      final decoded = body == null ? null : jsonDecode(body);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  void clearSession() => _refresh = null;

  void close() {
    _closed = true;
    clearSession();
    _dio.close(force: true);
  }
}

class _Dispatch {
  _Dispatch(this.session);

  static const key = 'andril.backend.dispatch';
  final BackendSession session;
  BackendCredential? credential;
}

class _DispatchAdapter implements HttpClientAdapter {
  _DispatchAdapter(this._delegate, this._credentialFor);

  final HttpClientAdapter _delegate;
  final BackendCredential Function(BackendSession) _credentialFor;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    final dispatch = options.extra.remove(_Dispatch.key) as _Dispatch;
    final credential = _credentialFor(dispatch.session);
    dispatch.credential = credential;
    options.headers['Authorization'] = 'Bearer ' + credential.accessToken;
    return _delegate.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) => _delegate.close(force: force);
}
