import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../../domain/entities/personality_questionnaire.dart';

/// Categorized failure reasons for Personality Questionnaire operations.
enum QuestionnaireFailureType {
  /// Session missing or caller not authorized (401/403).
  unauthorized,

  /// Target endpoint is dormant or service currently unavailable (503/404).
  serviceUnavailable,

  /// Client-side invalid argument or bad request (400).
  badRequest,

  /// Network timeout or unexpected connectivity breakdown.
  networkError,

  /// Unknown or unexpected exception sanitized for caller consumption.
  unknown,
}

/// Typed result container representing either a successful data payload or a sanitized failure.
@immutable
class QuestionnaireResult<T> {
  final T? data;
  final String? errorMessage;
  final QuestionnaireFailureType? failureType;
  final bool isSuccess;

  const QuestionnaireResult.success(this.data)
      : errorMessage = null,
        failureType = null,
        isSuccess = true;

  const QuestionnaireResult.failure({
    required this.errorMessage,
    required this.failureType,
  })  : data = null,
        isSuccess = false;

  bool get isFailure => !isSuccess;
}

/// Authoritative repository abstraction for Personality Questionnaire operations.
abstract class IPersonalityQuestionnaireRepository {
  /// Fetches the authoritative active personality questionnaire definition (GET /api/v1/social/questionnaires/active).
  Future<QuestionnaireResult<PersonalityQuestionnaire>>
      getActiveQuestionnaire();
}

/// Implementation of [IPersonalityQuestionnaireRepository] adhering to M5 API readiness & Task 151:
/// - Connects to active endpoint: `GET /api/v1/social/questionnaires/active` via authenticated [AndrilApiClient].
/// - Fails closed if session or configuration is missing or invalid.
/// - Does not use any hard-coded fallback hosts.
/// - Uses the configured API origin and active session's approved authenticated transport.
/// - Redirects do not forward bearer credentials (followRedirects: false, maxRedirects: 0).
/// - Discards responses if session changes or invalidates during the request.
/// - Keeps request and response handling private, safe, and no-store (Cache-Control: no-store).
/// - Redacts credentials, tokens, and raw response bodies from logs and diagnostics.
class PersonalityQuestionnaireRepository
    implements IPersonalityQuestionnaireRepository {
  final SessionController _sessionController;
  final AndrilApiClient? _apiClient;
  final bool _ownsApiClient;

  PersonalityQuestionnaireRepository({
    required SessionController sessionController,
    AndrilApiClient? apiClient,
    AppConfig? config,
    HttpClientAdapter? adapter,
  })  : _sessionController = sessionController,
        _apiClient =
            apiClient ?? _createApiClient(config, sessionController, adapter),
        _ownsApiClient = apiClient == null;

  static AndrilApiClient? _createApiClient(
    AppConfig? config,
    SessionController session,
    HttpClientAdapter? adapter,
  ) {
    if (config == null) return null;
    try {
      return AndrilApiClient(config, session, adapter: adapter);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<QuestionnaireResult<PersonalityQuestionnaire>>
      getActiveQuestionnaire() async {
    // 1. Verify caller session standing
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const QuestionnaireResult.failure(
        errorMessage: 'Caller must be signed in to access questionnaire.',
        failureType: QuestionnaireFailureType.unauthorized,
      );
    }

    final session = _sessionController.backendSession;
    if (session == null) {
      return const QuestionnaireResult.failure(
        errorMessage: 'Active backend session unavailable.',
        failureType: QuestionnaireFailureType.unauthorized,
      );
    }

    // 2. Verify API client configuration (fails closed if missing or invalid)
    final client = _apiClient;
    if (client == null) {
      return const QuestionnaireResult.failure(
        errorMessage:
            'Questionnaire API client is not configured or origin is invalid.',
        failureType: QuestionnaireFailureType.serviceUnavailable,
      );
    }

    try {
      final json = await client.requestSocial(
        SocialEndpoint.activeQuestionnaire,
        session,
      );

      // 3. Verify session did not change or invalidate during the request
      if (_sessionController.backendSession != session) {
        return const QuestionnaireResult.failure(
          errorMessage: 'Session changed during questionnaire request.',
          failureType: QuestionnaireFailureType.unauthorized,
        );
      }

      // 4. Decode payload into domain entity
      try {
        final questionnaire = PersonalityQuestionnaire.fromJson(json);
        return QuestionnaireResult.success(questionnaire);
      } catch (_) {
        return const QuestionnaireResult.failure(
          errorMessage: 'Malformed questionnaire definition format.',
          failureType: QuestionnaireFailureType.unknown,
        );
      }
    } on HandoffFailure catch (failure) {
      // Session change during dispatch
      if (_sessionController.backendSession != session) {
        return const QuestionnaireResult.failure(
          errorMessage: 'Session changed during questionnaire request.',
          failureType: QuestionnaireFailureType.unauthorized,
        );
      }
      return _mapHandoffFailure(failure);
    } catch (_) {
      return const QuestionnaireResult.failure(
        errorMessage:
            'An unexpected error occurred while loading questionnaire.',
        failureType: QuestionnaireFailureType.unknown,
      );
    }
  }

  QuestionnaireResult<PersonalityQuestionnaire> _mapHandoffFailure(
      HandoffFailure failure) {
    switch (failure.issue) {
      case HandoffIssue.reauthenticationRequired:
      case HandoffIssue.forbidden:
      case HandoffIssue.verificationRequired:
      case HandoffIssue.sessionChanged:
        return const QuestionnaireResult.failure(
          errorMessage: 'Access denied to personality questionnaire.',
          failureType: QuestionnaireFailureType.unauthorized,
        );
      case HandoffIssue.unavailable:
      case HandoffIssue.rateLimited:
      case HandoffIssue.accountNotInitialized:
        return const QuestionnaireResult.failure(
          errorMessage:
              'Personality questionnaire service is currently unavailable.',
          failureType: QuestionnaireFailureType.serviceUnavailable,
        );
      case HandoffIssue.invalidResponse:
        return const QuestionnaireResult.failure(
          errorMessage: 'Malformed questionnaire definition format.',
          failureType: QuestionnaireFailureType.unknown,
        );
      case HandoffIssue.badRequest:
        return const QuestionnaireResult.failure(
          errorMessage: 'Invalid questionnaire request.',
          failureType: QuestionnaireFailureType.badRequest,
        );
      case HandoffIssue.conflict:
        return const QuestionnaireResult.failure(
          errorMessage: 'Conflict encountered during questionnaire request.',
          failureType: QuestionnaireFailureType.unknown,
        );
    }
  }

  /// Closes owned resources if this repository created its own API client.
  void dispose() {
    if (_ownsApiClient) {
      _apiClient?.close();
    }
  }
}
