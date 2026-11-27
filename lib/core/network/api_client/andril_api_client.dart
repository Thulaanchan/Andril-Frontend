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

enum SocialEndpoint {
  activeQuestionnaire('GET', '/api/v1/social/questionnaires/active'),
  profile('GET', '/api/v1/account/profiles/social'),
  updateProfile('PUT', '/api/v1/account/profiles/social');

  const SocialEndpoint(this.method, this.path);
  final String method;
  final String path;
}

enum LearningEndpoint {
  setup('GET', '/api/v1/learning/setup'),
  setupSelections('PUT', '/api/v1/learning/setup/selections'),
  setupGoalCreate('POST', '/api/v1/learning/setup/goals'),
  profileDraft('PUT', '/api/v1/account/profiles/learning'),
  profileGet('GET', '/api/v1/account/profiles/learning'),
  currentPhoto('GET', '/api/v1/account/profiles/learning/photos/current'),
  cvImportReviews('POST', '/api/v1/learning/cv-imports/reviews');

  const LearningEndpoint(this.method, this.path);
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
  badRequest,
  conflict,
}

/// Exposes only allowlisted error information, never a Dio error or body.
class HandoffFailure implements Exception {
  const HandoffFailure(this.issue, {this.retryAfter, this.statusCode});
  final HandoffIssue issue;
  final Duration? retryAfter;
  final int? statusCode;

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
          AccountEndpoint endpoint, BackendSession session) =>
      _sendAndInterpret(endpoint.method, endpoint.path, session,
          isMeEndpoint: endpoint == AccountEndpoint.me);

  Future<Map<String, Object?>> requestSocial(
          SocialEndpoint endpoint, BackendSession session,
          {Object? body}) =>
      _sendAndInterpret(endpoint.method, endpoint.path, session,
          isMeEndpoint: false, body: body);

  Future<Map<String, Object?>> requestLearning(
          LearningEndpoint endpoint, BackendSession session,
          {Object? body, Map<String, String>? headers}) =>
      _sendAndInterpret(endpoint.method, endpoint.path, session,
          isMeEndpoint: false, body: body, headers: headers);

  Future<Map<String, Object?>> requestLearningPath(
      String method, String path, BackendSession session,
      {Object? body, Map<String, String>? headers}) {
    if (!path.startsWith('/api/v1/learning/') &&
        !path.startsWith('/api/v1/account/profiles/learning')) {
      throw ArgumentError('Path must be an approved learning path: ' + path);
    }
    return _sendAndInterpret(method, path, session,
        isMeEndpoint: false, body: body, headers: headers);
  }

  Future<Map<String, Object?>> _sendAndInterpret(
      String method, String path, BackendSession session,
      {required bool isMeEndpoint,
      Object? body,
      Map<String, String>? headers}) async {
    final initial =
        await _send(method, path, session, body: body, headers: headers);
    final dispatched = initial.credential;
    var response = initial.response;
    // Automatic replay is limited to reads. An uncertain initialize can be
    // recovered by starting from the authoritative GET.
    if (response.statusCode == 401 && method == 'GET') {
      final current = _credential(session);
      if (current.accessToken == dispatched.accessToken) {
        await _refreshOnce(session, current);
      }
      final replacement = _credential(session);
      if (replacement.accessToken != dispatched.accessToken) {
        response =
            (await _send(method, path, session, body: body, headers: headers))
                .response;
      }
    }
    return _interpret(path, response, isMeEndpoint: isMeEndpoint);
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
      String method, String path, BackendSession session,
      {Object? body, Map<String, String>? headers}) async {
    _credential(session);
    final dispatch = _Dispatch(session);
    Response<String> response;
    try {
      final requestHeaders = <String, String>{
        'Accept': 'application/json, application/problem+json',
        if (headers != null) ...headers,
      };
      String? data;
      if (body != null) {
        data = jsonEncode(body);
        requestHeaders['Content-Type'] = 'application/json';
      }
      response = await _dio.requestUri<String>(
        _origin.replace(path: path),
        data: data,
        options: Options(
          method: method,
          headers: requestHeaders,
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

  Map<String, Object?> _interpret(String path, Response<String> response,
      {required bool isMeEndpoint}) {
    final status = response.statusCode;
    final contentTypes = response.headers['content-type'];
    final mediaType = contentTypes?.length == 1
        ? contentTypes!.single.split(';').first.trim().toLowerCase()
        : null;
    final json = _object(response.data);
    if (status == 200 && mediaType == 'application/json' && json != null) {
      return json;
    }
    if (status == 204) {
      return const <String, Object?>{};
    }
    final problem =
        mediaType == 'application/problem+json' && json?['status'] == status;
    switch (status) {
      case 400:
        throw HandoffFailure(HandoffIssue.badRequest, statusCode: status);
      case 401:
        throw HandoffFailure(HandoffIssue.reauthenticationRequired, statusCode: status);
      case 403:
        throw HandoffFailure(
            problem && json?['title'] == 'Email confirmation required'
                ? HandoffIssue.verificationRequired
                : HandoffIssue.forbidden,
            statusCode: status);
      case 404:
        if (isMeEndpoint &&
            problem &&
            json?['title'] == 'Account not initialized') {
          throw HandoffFailure(HandoffIssue.accountNotInitialized, statusCode: status);
        }
        throw HandoffFailure(HandoffIssue.unavailable, statusCode: status);
      case 409:
        throw HandoffFailure(HandoffIssue.conflict, statusCode: status);
      case 429:
        final values = response.headers['retry-after'];
        final value = values?.length == 1 ? values!.single.trim() : null;
        final seconds = value != null && RegExp(r'^[0-9]{1,9}$').hasMatch(value)
            ? int.tryParse(value)
            : null;
        throw HandoffFailure(HandoffIssue.rateLimited,
            retryAfter: seconds == null ? null : Duration(seconds: seconds),
            statusCode: status);
      case 200:
        throw HandoffFailure(HandoffIssue.invalidResponse, statusCode: status);
      default:
        throw HandoffFailure(HandoffIssue.unavailable, statusCode: status);
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
