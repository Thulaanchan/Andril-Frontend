import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../models/learning_setup_snapshot_dto.dart';

/// Contract for remote Learning backend API operations.
///
/// Encapsulates all approved HTTP routes per backend contracts:
/// - GET /api/v1/learning/setup
/// - PUT /api/v1/learning/setup/selections
/// - POST /api/v1/learning/setup/goals
/// - PUT /api/v1/learning/setup/goals/{goalId}
/// - DELETE /api/v1/learning/setup/goals/{goalId}
/// - PUT /api/v1/account/profiles/learning
/// - GET /api/v1/account/profiles/learning
/// - GET /api/v1/account/profiles/learning/photos/current
abstract class ILearningRemoteDataSource {
  /// Reads the authoritative learning setup snapshot (selections, goals, revision).
  Future<LearningSetupSnapshotDto> getLearningSetup(BackendSession session);

  /// Updates skill selections (teaching and learning) under optimistic revision control.
  Future<void> updateLearningSelections({
    required BackendSession session,
    required String expectedRevision,
    required List<String> teachingSkills,
    required List<String> learningSkills,
    required String idempotencyKey,
  });

  /// Creates a personal learning goal under optimistic revision control.
  Future<void> createLearningGoal({
    required BackendSession session,
    required String expectedRevision,
    required String text,
    required String idempotencyKey,
  });

  /// Edits an existing personal learning goal under optimistic revision control.
  Future<void> editLearningGoal({
    required BackendSession session,
    required String expectedRevision,
    required String goalId,
    required String text,
    required String idempotencyKey,
  });

  /// Removes an existing personal learning goal under optimistic revision control.
  Future<void> removeLearningGoal({
    required BackendSession session,
    required String expectedRevision,
    required String goalId,
    required String idempotencyKey,
  });

  /// Updates the caller's private learning profile draft.
  Future<Map<String, Object?>> updateProfileDraft({
    required BackendSession session,
    required String displayName,
    String? bio,
    String visibility = 'private',
  });

  /// Reads the caller's private learning profile draft.
  Future<Map<String, Object?>> getProfileDraft(BackendSession session);

  /// Reads the caller's current learning profile photo status.
  Future<Map<String, Object?>> getCurrentPhotoStatus(BackendSession session);
}

/// Concrete implementation of [ILearningRemoteDataSource] backed by [AndrilApiClient].
class LearningRemoteDataSource implements ILearningRemoteDataSource {
  final AndrilApiClient _apiClient;

  const LearningRemoteDataSource(this._apiClient);

  @override
  Future<LearningSetupSnapshotDto> getLearningSetup(
      BackendSession session) async {
    final response = await _apiClient.requestLearning(
      LearningEndpoint.setup,
      session,
    );
    return LearningSetupSnapshotDto.fromJson(response);
  }

  @override
  Future<void> updateLearningSelections({
    required BackendSession session,
    required String expectedRevision,
    required List<String> teachingSkills,
    required List<String> learningSkills,
    required String idempotencyKey,
  }) async {
    _validateIdempotencyKey(idempotencyKey);
    await _apiClient.requestLearning(
      LearningEndpoint.setupSelections,
      session,
      headers: {'Idempotency-Key': idempotencyKey},
      body: {
        'expectedRevision': expectedRevision,
        'teachingSkills': teachingSkills,
        'learningSkills': learningSkills,
      },
    );
  }

  @override
  Future<void> createLearningGoal({
    required BackendSession session,
    required String expectedRevision,
    required String text,
    required String idempotencyKey,
  }) async {
    _validateIdempotencyKey(idempotencyKey);
    await _apiClient.requestLearning(
      LearningEndpoint.setupGoalCreate,
      session,
      headers: {'Idempotency-Key': idempotencyKey},
      body: {
        'expectedRevision': expectedRevision,
        'text': text,
      },
    );
  }

  @override
  Future<void> editLearningGoal({
    required BackendSession session,
    required String expectedRevision,
    required String goalId,
    required String text,
    required String idempotencyKey,
  }) async {
    _validateIdempotencyKey(idempotencyKey);
    _validateGuid(goalId, 'goalId');
    await _apiClient.requestLearningPath(
      'PUT',
      '/api/v1/learning/setup/goals/$goalId',
      session,
      headers: {'Idempotency-Key': idempotencyKey},
      body: {
        'expectedRevision': expectedRevision,
        'text': text,
      },
    );
  }

  @override
  Future<void> removeLearningGoal({
    required BackendSession session,
    required String expectedRevision,
    required String goalId,
    required String idempotencyKey,
  }) async {
    _validateIdempotencyKey(idempotencyKey);
    _validateGuid(goalId, 'goalId');
    await _apiClient.requestLearningPath(
      'DELETE',
      '/api/v1/learning/setup/goals/$goalId',
      session,
      headers: {'Idempotency-Key': idempotencyKey},
      body: {
        'expectedRevision': expectedRevision,
      },
    );
  }

  @override
  Future<Map<String, Object?>> updateProfileDraft({
    required BackendSession session,
    required String displayName,
    String? bio,
    String visibility = 'private',
  }) async {
    return _apiClient.requestLearning(
      LearningEndpoint.profileDraft,
      session,
      body: {
        'displayName': displayName,
        'bio': bio,
        'visibility': visibility,
      },
    );
  }

  @override
  Future<Map<String, Object?>> getProfileDraft(BackendSession session) =>
      _apiClient.requestLearning(LearningEndpoint.profileGet, session);

  @override
  Future<Map<String, Object?>> getCurrentPhotoStatus(BackendSession session) =>
      _apiClient.requestLearning(LearningEndpoint.currentPhoto, session);

  static void _validateIdempotencyKey(String key) {
    if (key.trim().isEmpty) {
      throw ArgumentError('Idempotency key must not be empty.');
    }
  }

  static void _validateGuid(String value, String field) {
    final trimmed = value.trim();
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(trimmed)) {
      throw ArgumentError('Invalid UUID format for $field: $value');
    }
  }
}
