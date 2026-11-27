import 'package:flutter/foundation.dart';

import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../datasources/learning_remote_data_source.dart';
import '../models/learning_setup_snapshot_dto.dart';

/// Sealed result hierarchy representing deterministic outcomes of learning setup operations.
@immutable
sealed class SetupResult<T> {
  const SetupResult();
}

/// Operation succeeded with requested payload data.
final class SetupSuccess<T> extends SetupResult<T> {
  final T data;
  const SetupSuccess(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetupSuccess<T> && other.data == data);

  @override
  int get hashCode => data.hashCode;
}

/// Caller is unauthenticated or session is not active.
final class SetupUnauthorized<T> extends SetupResult<T> {
  final String message;
  const SetupUnauthorized([
    this.message = 'Caller must be authenticated to access learning setup',
  ]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetupUnauthorized<T> && other.message == message);

  @override
  int get hashCode => message.hashCode;
}

/// Optimistic concurrency conflict: revision mismatch.
final class SetupConflict<T> extends SetupResult<T> {
  final String message;
  const SetupConflict([
    this.message = 'Learning setup revision conflict: remote state has changed',
  ]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetupConflict<T> && other.message == message);

  @override
  int get hashCode => message.hashCode;
}

/// Client-side invalid argument or bad request (400).
final class SetupBadRequest<T> extends SetupResult<T> {
  final String message;
  const SetupBadRequest([
    this.message = 'Invalid learning setup request payload',
  ]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetupBadRequest<T> && other.message == message);

  @override
  int get hashCode => message.hashCode;
}

/// Underlying service is unavailable or rate limited.
final class SetupUnavailable<T> extends SetupResult<T> {
  final String message;
  const SetupUnavailable([
    this.message = 'Learning setup service is currently unavailable',
  ]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetupUnavailable<T> && other.message == message);

  @override
  int get hashCode => message.hashCode;
}

/// Generic failure with error context.
final class SetupFailure<T> extends SetupResult<T> {
  final String message;
  final Object? error;
  const SetupFailure(this.message, [this.error]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetupFailure<T> &&
          other.message == message &&
          other.error == error);

  @override
  int get hashCode => Object.hash(message, error);
}

/// Abstract contract for Learning Setup repository operations.
abstract interface class ILearningSetupRepository {
  /// Reads the authoritative setup snapshot.
  Future<SetupResult<LearningSetupSnapshotDto>> readSetup();

  /// Updates teaching and learning skill selections.
  Future<SetupResult<void>> updateSelections({
    required String expectedRevision,
    required List<String> teachingSkills,
    required List<String> learningSkills,
    required String idempotencyKey,
  });

  /// Creates a personal learning goal.
  Future<SetupResult<void>> createGoal({
    required String expectedRevision,
    required String text,
    required String idempotencyKey,
  });

  /// Edits an existing personal learning goal.
  Future<SetupResult<void>> editGoal({
    required String expectedRevision,
    required String goalId,
    required String text,
    required String idempotencyKey,
  });

  /// Removes an existing personal learning goal.
  Future<SetupResult<void>> removeGoal({
    required String expectedRevision,
    required String goalId,
    required String idempotencyKey,
  });
}

/// Concrete implementation of [ILearningSetupRepository] integrating with approved backend APIs.
class LearningSetupApiRepository implements ILearningSetupRepository {
  final SessionController _sessionController;
  final ILearningRemoteDataSource _remoteDataSource;

  const LearningSetupApiRepository({
    required SessionController sessionController,
    required ILearningRemoteDataSource remoteDataSource,
  })  : _sessionController = sessionController,
        _remoteDataSource = remoteDataSource;

  @override
  Future<SetupResult<LearningSetupSnapshotDto>> readSetup() async {
    final session = _validateSession();
    if (session == null) {
      return const SetupUnauthorized();
    }

    try {
      final snapshot = await _remoteDataSource.getLearningSetup(session);
      if (_sessionChanged(session)) {
        return const SetupUnauthorized('Session changed during request');
      }
      return SetupSuccess(snapshot);
    } on HandoffFailure catch (failure) {
      return _mapHandoffFailure(failure, session);
    } catch (e) {
      return SetupFailure('Failed to read learning setup', e);
    }
  }

  @override
  Future<SetupResult<void>> updateSelections({
    required String expectedRevision,
    required List<String> teachingSkills,
    required List<String> learningSkills,
    required String idempotencyKey,
  }) async {
    final session = _validateSession();
    if (session == null) {
      return const SetupUnauthorized();
    }

    try {
      await _remoteDataSource.updateLearningSelections(
        session: session,
        expectedRevision: expectedRevision,
        teachingSkills: teachingSkills,
        learningSkills: learningSkills,
        idempotencyKey: idempotencyKey,
      );
      if (_sessionChanged(session)) {
        return const SetupUnauthorized('Session changed during request');
      }
      return const SetupSuccess(null);
    } on HandoffFailure catch (failure) {
      return _mapHandoffFailure(failure, session);
    } catch (e) {
      return SetupFailure('Failed to update learning selections', e);
    }
  }

  @override
  Future<SetupResult<void>> createGoal({
    required String expectedRevision,
    required String text,
    required String idempotencyKey,
  }) async {
    final session = _validateSession();
    if (session == null) {
      return const SetupUnauthorized();
    }

    try {
      await _remoteDataSource.createLearningGoal(
        session: session,
        expectedRevision: expectedRevision,
        text: text,
        idempotencyKey: idempotencyKey,
      );
      if (_sessionChanged(session)) {
        return const SetupUnauthorized('Session changed during request');
      }
      return const SetupSuccess(null);
    } on HandoffFailure catch (failure) {
      return _mapHandoffFailure(failure, session);
    } catch (e) {
      return SetupFailure('Failed to create learning goal', e);
    }
  }

  @override
  Future<SetupResult<void>> editGoal({
    required String expectedRevision,
    required String goalId,
    required String text,
    required String idempotencyKey,
  }) async {
    final session = _validateSession();
    if (session == null) {
      return const SetupUnauthorized();
    }

    try {
      await _remoteDataSource.editLearningGoal(
        session: session,
        expectedRevision: expectedRevision,
        goalId: goalId,
        text: text,
        idempotencyKey: idempotencyKey,
      );
      if (_sessionChanged(session)) {
        return const SetupUnauthorized('Session changed during request');
      }
      return const SetupSuccess(null);
    } on HandoffFailure catch (failure) {
      return _mapHandoffFailure(failure, session);
    } catch (e) {
      return SetupFailure('Failed to edit learning goal', e);
    }
  }

  @override
  Future<SetupResult<void>> removeGoal({
    required String expectedRevision,
    required String goalId,
    required String idempotencyKey,
  }) async {
    final session = _validateSession();
    if (session == null) {
      return const SetupUnauthorized();
    }

    try {
      await _remoteDataSource.removeLearningGoal(
        session: session,
        expectedRevision: expectedRevision,
        goalId: goalId,
        idempotencyKey: idempotencyKey,
      );
      if (_sessionChanged(session)) {
        return const SetupUnauthorized('Session changed during request');
      }
      return const SetupSuccess(null);
    } on HandoffFailure catch (failure) {
      return _mapHandoffFailure(failure, session);
    } catch (e) {
      return SetupFailure('Failed to remove learning goal', e);
    }
  }

  BackendSession? _validateSession() {
    if (_sessionController.phase != SessionPhase.signedIn) return null;
    return _sessionController.backendSession;
  }

  bool _sessionChanged(BackendSession session) =>
      _sessionController.backendSession != session;

  SetupResult<T> _mapHandoffFailure<T>(
      HandoffFailure failure, BackendSession session) {
    if (_sessionChanged(session)) {
      return const SetupUnauthorized('Session changed during request');
    }
    switch (failure.issue) {
      case HandoffIssue.reauthenticationRequired:
      case HandoffIssue.forbidden:
      case HandoffIssue.verificationRequired:
      case HandoffIssue.sessionChanged:
        return const SetupUnauthorized();
      case HandoffIssue.conflict:
        return const SetupConflict();
      case HandoffIssue.badRequest:
        return const SetupBadRequest();
      case HandoffIssue.unavailable:
      case HandoffIssue.rateLimited:
      case HandoffIssue.accountNotInitialized:
        return const SetupUnavailable();
      case HandoffIssue.invalidResponse:
        return const SetupFailure('Invalid server response');
    }
  }
}
