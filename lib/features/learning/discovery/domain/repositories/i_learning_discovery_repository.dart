import 'package:flutter/foundation.dart';

import '../entities/learning_partner_candidate.dart';
import '../entities/learning_partner_filters.dart';

/// Categorized failure kinds for Learning People Discovery operations.
enum LearningDiscoveryFailureType {
  /// Session missing or caller not authorized (401/403).
  unauthorized,

  /// Target endpoint is dormant or service currently unavailable (503/404).
  serviceUnavailable,

  /// Client-side invalid argument or bad request (400).
  badRequest,

  /// Network timeout or connectivity breakdown.
  networkError,

  /// Unknown or unexpected exception.
  unknown,
}

/// Typed result container representing a data payload or a sanitized failure.
@immutable
class LearningDiscoveryResult<T> {
  final T? data;
  final String? errorMessage;
  final LearningDiscoveryFailureType? failureType;
  final bool isSuccess;

  const LearningDiscoveryResult.success(this.data)
      : errorMessage = null,
        failureType = null,
        isSuccess = true;

  const LearningDiscoveryResult.failure({
    required this.errorMessage,
    required this.failureType,
  })  : data = null,
        isSuccess = false;

  bool get isFailure => !isSuccess;
}

/// Authoritative repository interface for Learning People Discovery (CF-04).
abstract class ILearningDiscoveryRepository {
  /// Fetches an authorized list of eligible learning partner candidates.
  Future<LearningDiscoveryResult<List<LearningPartnerCandidate>>>
      getCandidates({
    LearningPartnerFilters? filters,
    int offset = 0,
    int limit = 20,
  });
}
