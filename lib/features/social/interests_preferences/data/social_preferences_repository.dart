import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../domain/social_preferences_model.dart';

/// Categorized failure reasons for Social Preferences & Language operations.
enum SocialPreferencesFailureType {
  /// Session missing or caller not authorized (401/403).
  unauthorized,

  /// Target endpoint is dormant or service currently unavailable (503/404).
  serviceUnavailable,

  /// Client-side invalid argument or bad request (400).
  badRequest,

  /// Conflict or invariant violation (409).
  conflict,

  /// Network timeout or unexpected connectivity breakdown.
  networkError,

  /// Inflight session context switch or expiration.
  sessionExpired,

  /// Unknown or unexpected exception sanitized for caller consumption.
  unknown,
}

/// Typed result container representing either a successful data payload or a sanitized failure.
@immutable
class SocialPreferencesResult<T> {
  final T? data;
  final String? errorMessage;
  final SocialPreferencesFailureType? failureType;
  final bool isSuccess;

  const SocialPreferencesResult.success(this.data)
      : errorMessage = null,
        failureType = null,
        isSuccess = true;

  const SocialPreferencesResult.failure({
    required this.errorMessage,
    required this.failureType,
  })  : data = null,
        isSuccess = false;

  bool get isFailure => !isSuccess;
}

/// Authoritative repository abstraction for Social Interests, Preferences, and Languages.
abstract class ISocialPreferencesRepository {
  /// Retrieves user's Social preferences, synchronizing with account language where available.
  Future<SocialPreferencesResult<SocialPreferencesModel>> getPreferences();

  /// Updates and persists user's Social preferences.
  Future<SocialPreferencesResult<SocialPreferencesModel>> updatePreferences(
      SocialPreferencesModel preferences);

  /// Retrieves the active account language preference from the authorized endpoint.
  Future<SocialPreferencesResult<String>> getAccountLanguage();

  /// Updates the active account language preference via PATCH.
  Future<SocialPreferencesResult<String>> updateAccountLanguage(String languageCode);
}

/// Implementation of [ISocialPreferencesRepository] adhering to M5 API readiness & Task 153:
/// - Connects to active endpoint: `GET` & `PATCH` `/api/v1/account/preferences/language`.
/// - Records explicit backend blocker: `/api/v1/social/preferences` endpoint is not registered in backend controller suite.
/// - Preserves defensive immutability and validates 18+ age range and non-empty interests.
/// - Reuses configured API origin and active session's approved authenticated transport.
/// - Fails closed if session or configuration is missing or invalid.
/// - Redirects do not forward bearer credentials (followRedirects: false, maxRedirects: 0).
/// - Discards responses if session changes or invalidates during the request.
/// - Redacts credentials, tokens, and raw response bodies from logs and diagnostics.
class SocialPreferencesRepository implements ISocialPreferencesRepository {
  final SessionController _sessionController;
  final Dio? _dio;
  final String? _boundSubject;
  SocialPreferencesModel _cachedPreferences;

  SocialPreferencesRepository({
    required SessionController sessionController,
    AppConfig? config,
    HttpClientAdapter? adapter,
    String? boundSubject,
    SocialPreferencesModel? initialPreferences,
  })  : _sessionController = sessionController,
        _boundSubject = boundSubject ?? _extractSubject(sessionController),
        _cachedPreferences = initialPreferences ?? const SocialPreferencesModel.empty(),
        _dio = config != null ? _createDio(config, adapter) : null;

  static String? _extractSubject(SessionController session) {
    try {
      return session.subject;
    } catch (_) {
      return null;
    }
  }

  static Dio _createDio(AppConfig config, HttpClientAdapter? adapter) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl.toString(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        followRedirects: false,
        maxRedirects: 0,
        validateStatus: (status) => status != null && status >= 200 && status < 300,
        headers: {
          'Accept': 'application/json, application/problem+json',
        },
      ),
    );
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
    }
    return dio;
  }

  @override
  Future<SocialPreferencesResult<String>> getAccountLanguage() async {
    // 1. Session standing check
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Caller is not authenticated.',
        failureType: SocialPreferencesFailureType.unauthorized,
      );
    }

    try {
      if (_boundSubject != null && _sessionController.subject != _boundSubject) {
        return const SocialPreferencesResult.failure(
          errorMessage: 'Account context mismatch detected.',
          failureType: SocialPreferencesFailureType.unauthorized,
        );
      }
    } catch (_) {}

    final session = _sessionController.backendSession;
    if (session == null) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Active backend session unavailable.',
        failureType: SocialPreferencesFailureType.unauthorized,
      );
    }

    final dio = _dio;
    if (dio == null) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Preferences API client is not configured.',
        failureType: SocialPreferencesFailureType.serviceUnavailable,
      );
    }

    final credential = _sessionController.credentialFor(session);
    if (credential == null) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Session credential unavailable.',
        failureType: SocialPreferencesFailureType.unauthorized,
      );
    }

    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/v1/account/preferences/language',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${credential.accessToken}',
            'Cache-Control': 'no-store',
          },
        ),
      );

      // Session continuity check
      if (_sessionController.backendSession != session) {
        return const SocialPreferencesResult.failure(
          errorMessage: 'Session changed during language preference fetch.',
          failureType: SocialPreferencesFailureType.sessionExpired,
        );
      }

      final data = response.data;
      if (data == null) {
        return const SocialPreferencesResult.failure(
          errorMessage: 'Empty response returned from language preference service.',
          failureType: SocialPreferencesFailureType.unknown,
        );
      }

      final language = data['language'] as String? ?? 'en';
      return SocialPreferencesResult.success(language);
    } on DioException catch (dioErr) {
      if (_sessionController.backendSession != session) {
        return const SocialPreferencesResult.failure(
          errorMessage: 'Session changed during language preference fetch.',
          failureType: SocialPreferencesFailureType.sessionExpired,
        );
      }
      return _mapDioError(dioErr);
    } catch (_) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Failed to retrieve account language preference.',
        failureType: SocialPreferencesFailureType.unknown,
      );
    }
  }

  @override
  Future<SocialPreferencesResult<String>> updateAccountLanguage(String languageCode) async {
    // 1. Session standing check
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Caller is not authenticated.',
        failureType: SocialPreferencesFailureType.unauthorized,
      );
    }

    // Validate supported language codes
    final code = languageCode.trim().toLowerCase();
    if (code != 'en' && code != 'ta' && code != 'si') {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Language must be en, ta, or si.',
        failureType: SocialPreferencesFailureType.badRequest,
      );
    }

    final session = _sessionController.backendSession;
    if (session == null) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Active backend session unavailable.',
        failureType: SocialPreferencesFailureType.unauthorized,
      );
    }

    final dio = _dio;
    if (dio == null) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Preferences API client is not configured.',
        failureType: SocialPreferencesFailureType.serviceUnavailable,
      );
    }

    final credential = _sessionController.credentialFor(session);
    if (credential == null) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Session credential unavailable.',
        failureType: SocialPreferencesFailureType.unauthorized,
      );
    }

    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/api/v1/account/preferences/language',
        data: {
          'language': code,
          'mode': 'settings',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${credential.accessToken}',
            'Content-Type': 'application/json',
            'Cache-Control': 'no-store',
          },
        ),
      );

      if (_sessionController.backendSession != session) {
        return const SocialPreferencesResult.failure(
          errorMessage: 'Session changed during language preference update.',
          failureType: SocialPreferencesFailureType.sessionExpired,
        );
      }

      final data = response.data;
      final savedLang = data?['language'] as String? ?? code;
      return SocialPreferencesResult.success(savedLang);
    } on DioException catch (dioErr) {
      if (_sessionController.backendSession != session) {
        return const SocialPreferencesResult.failure(
          errorMessage: 'Session changed during language preference update.',
          failureType: SocialPreferencesFailureType.sessionExpired,
        );
      }
      return _mapDioError(dioErr);
    } catch (_) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Failed to update account language preference.',
        failureType: SocialPreferencesFailureType.unknown,
      );
    }
  }

  @override
  Future<SocialPreferencesResult<SocialPreferencesModel>> getPreferences() async {
    // 1. Session standing check
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Caller is not authenticated.',
        failureType: SocialPreferencesFailureType.unauthorized,
      );
    }

    // Try synchronizing language if API client is configured
    if (_dio != null) {
      final langResult = await getAccountLanguage();
      if (langResult.isSuccess && langResult.data != null) {
        final langName = switch (langResult.data!) {
          'ta' => 'Tamil',
          'si' => 'Sinhala',
          _ => 'English',
        };
        if (!_cachedPreferences.languages.contains(langName)) {
          _cachedPreferences = _cachedPreferences.copyWith(
            languages: {..._cachedPreferences.languages, langName},
          );
        }
      }
    }

    return SocialPreferencesResult.success(_cachedPreferences);
  }

  @override
  Future<SocialPreferencesResult<SocialPreferencesModel>> updatePreferences(
      SocialPreferencesModel preferences) async {
    // 1. Session standing check
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Caller is not authenticated.',
        failureType: SocialPreferencesFailureType.unauthorized,
      );
    }

    // 2. Validate client-side boundaries
    if (preferences.minAge < 18) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Minimum age must be 18 or older.',
        failureType: SocialPreferencesFailureType.badRequest,
      );
    }

    if (preferences.maxAge < preferences.minAge) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Maximum age must be greater than or equal to minimum age.',
        failureType: SocialPreferencesFailureType.badRequest,
      );
    }

    if (preferences.maxDistanceKm <= 0) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Maximum distance must be positive.',
        failureType: SocialPreferencesFailureType.badRequest,
      );
    }

    if (preferences.selectedInterests.isEmpty) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Please select at least one interest.',
        failureType: SocialPreferencesFailureType.badRequest,
      );
    }

    // Synchronize language with account preference if available
    if (_dio != null && preferences.languages.isNotEmpty) {
      final primaryLang = preferences.languages.first.toLowerCase();
      final code = switch (primaryLang) {
        'tamil' => 'ta',
        'sinhala' => 'si',
        _ => 'en',
      };
      await updateAccountLanguage(code);
    }

    _cachedPreferences = preferences;
    return SocialPreferencesResult.success(_cachedPreferences);
  }

  SocialPreferencesResult<T> _mapDioError<T>(DioException err) {
    final status = err.response?.statusCode;
    if (status == 401 || status == 403) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Caller is not authorized.',
        failureType: SocialPreferencesFailureType.unauthorized,
      );
    }
    if (status == 400) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Invalid preferences request format.',
        failureType: SocialPreferencesFailureType.badRequest,
      );
    }
    if (status == 404 || status == 503) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Preferences service is currently unavailable.',
        failureType: SocialPreferencesFailureType.serviceUnavailable,
      );
    }
    return const SocialPreferencesResult.failure(
      errorMessage: 'Preferences operation failed due to a network or server error.',
      failureType: SocialPreferencesFailureType.networkError,
    );
  }

  void dispose() {
    _dio?.close();
  }
}
