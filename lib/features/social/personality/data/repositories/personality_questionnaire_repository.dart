import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/constants/app_config.dart';
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
  Future<QuestionnaireResult<PersonalityQuestionnaire>> getActiveQuestionnaire();
}

/// Implementation of [IPersonalityQuestionnaireRepository] adhering to M5 API readiness:
/// - Connects to active endpoint: `GET /api/v1/social/questionnaires/active`
/// - Respects `Cache-Control: no-store` behavior (never caches answers persistently).
/// - Dormant submission operations are strictly blocked from production dispatch.
/// - Redacts raw answers in diagnostics.
class PersonalityQuestionnaireRepository implements IPersonalityQuestionnaireRepository {
  final SessionController _sessionController;
  final Dio _dio;
  final Uri _baseUrl;

  PersonalityQuestionnaireRepository({
    required SessionController sessionController,
    Dio? dio,
    AppConfig? config,
  })  : _sessionController = sessionController,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
              headers: {
                'Cache-Control': 'no-store, no-cache, max-age=0',
                'Accept': 'application/json',
              },
            )),
        _baseUrl = config?.apiBaseUrl ?? Uri.parse('https://api.andril.internal');

  @override
  Future<QuestionnaireResult<PersonalityQuestionnaire>> getActiveQuestionnaire() async {
    // Verify caller session standing
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const QuestionnaireResult.failure(
        errorMessage: 'Caller must be signed in to access questionnaire.',
        failureType: QuestionnaireFailureType.unauthorized,
      );
    }

    try {
      final endpointUri = _baseUrl.replace(path: '/api/v1/social/questionnaires/active');
      final response = await _dio.getUri<String>(
        endpointUri,
        options: Options(
          headers: {
            'Cache-Control': 'no-store, no-cache, max-age=0',
          },
          responseType: ResponseType.plain,
          validateStatus: (status) => true,
        ),
      );

      final statusCode = response.statusCode ?? 500;

      if (statusCode == 200) {
        final body = response.data;
        if (body == null || body.trim().isEmpty) {
          return const QuestionnaireResult.failure(
            errorMessage: 'Empty questionnaire definition returned by server.',
            failureType: QuestionnaireFailureType.unknown,
          );
        }

        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          return const QuestionnaireResult.failure(
            errorMessage: 'Malformed questionnaire definition format.',
            failureType: QuestionnaireFailureType.unknown,
          );
        }

        final questionnaire = PersonalityQuestionnaire.fromJson(decoded);
        return QuestionnaireResult.success(questionnaire);
      }

      if (statusCode == 401 || statusCode == 403) {
        return const QuestionnaireResult.failure(
          errorMessage: 'Access denied to personality questionnaire.',
          failureType: QuestionnaireFailureType.unauthorized,
        );
      }

      if (statusCode == 404 || statusCode == 503) {
        return const QuestionnaireResult.failure(
          errorMessage: 'Personality questionnaire service is currently preparing or unavailable.',
          failureType: QuestionnaireFailureType.serviceUnavailable,
        );
      }

      return QuestionnaireResult.failure(
        errorMessage: 'Server returned unexpected status: $statusCode',
        failureType: QuestionnaireFailureType.unknown,
      );
    } on DioException catch (dioErr) {
      if (dioErr.type == DioExceptionType.connectionTimeout ||
          dioErr.type == DioExceptionType.receiveTimeout ||
          dioErr.type == DioExceptionType.connectionError) {
        return const QuestionnaireResult.failure(
          errorMessage: 'Network connection error while loading questionnaire.',
          failureType: QuestionnaireFailureType.networkError,
        );
      }
      return const QuestionnaireResult.failure(
        errorMessage: 'Service unavailable.',
        failureType: QuestionnaireFailureType.serviceUnavailable,
      );
    } catch (_) {
      return const QuestionnaireResult.failure(
        errorMessage: 'An unexpected error occurred while loading questionnaire.',
        failureType: QuestionnaireFailureType.unknown,
      );
    }
  }
}
