import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/profile/data/datasources/learning_remote_data_source.dart';
import 'package:andril_mobile/features/learning/profile/data/models/learning_setup_snapshot_dto.dart';
import 'package:andril_mobile/features/learning/profile/data/repositories/learning_setup_api_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared_core/authentication/foundation_fakes.dart';

class _FakeRemoteDataSource implements ILearningRemoteDataSource {
  LearningSetupSnapshotDto? snapshotToReturn;
  Object? errorToThrow;
  bool updateSelectionsCalled = false;
  bool createGoalCalled = false;
  bool editGoalCalled = false;
  bool removeGoalCalled = false;

  @override
  Future<LearningSetupSnapshotDto> getLearningSetup(
      BackendSession session) async {
    if (errorToThrow != null) throw errorToThrow!;
    return snapshotToReturn ??
        const LearningSetupSnapshotDto(
          revision: 'rev-01',
          teachingSkills: ['skill-1'],
          learningSkills: ['skill-2'],
          goals: [LearningGoalItemDto(goalId: 'g-1', text: 'Master Dart')],
        );
  }

  @override
  Future<void> updateLearningSelections({
    required BackendSession session,
    required String expectedRevision,
    required List<String> teachingSkills,
    required List<String> learningSkills,
    required String idempotencyKey,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    updateSelectionsCalled = true;
  }

  @override
  Future<void> createLearningGoal({
    required BackendSession session,
    required String expectedRevision,
    required String text,
    required String idempotencyKey,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    createGoalCalled = true;
  }

  @override
  Future<void> editLearningGoal({
    required BackendSession session,
    required String expectedRevision,
    required String goalId,
    required String text,
    required String idempotencyKey,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    editGoalCalled = true;
  }

  @override
  Future<void> removeLearningGoal({
    required BackendSession session,
    required String expectedRevision,
    required String goalId,
    required String idempotencyKey,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    removeGoalCalled = true;
  }

  @override
  Future<Map<String, Object?>> updateProfileDraft({
    required BackendSession session,
    required String displayName,
    String? bio,
    String visibility = 'private',
  }) async =>
      {'displayName': displayName, 'bio': bio, 'visibility': visibility};

  @override
  Future<Map<String, Object?>> getProfileDraft(BackendSession session) async =>
      {'displayName': 'Test Learner', 'bio': 'Bio', 'visibility': 'private'};

  @override
  Future<Map<String, Object?>> getCurrentPhotoStatus(
          BackendSession session) async =>
      {'status': 'none'};
}

class _Source extends FakeSessionSource implements BackendSessionSource {
  _Source()
      : super(
            restored: const SessionEvent(SessionEventKind.initial,
                subject: 'user-1'));

  @override
  BackendCredential? backendCredential =
      const BackendCredential('user-1', 'fake.token.jwt', emailConfirmed: true);

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}
}

void main() {
  late _Source source;
  late SessionController session;
  late _FakeRemoteDataSource remote;
  late LearningSetupApiRepository repository;

  setUp(() async {
    source = _Source();
    session = SessionController(source);
    remote = _FakeRemoteDataSource();
    repository = LearningSetupApiRepository(
      sessionController: session,
      remoteDataSource: remote,
    );
    await session.start();
  });

  tearDown(() async {
    session.dispose();
    await source.signals.close();
  });

  group('LearningSetupApiRepository', () {
    test('readSetup returns SetupSuccess when remote succeeds', () async {
      final result = await repository.readSetup();

      expect(result, isA<SetupSuccess<LearningSetupSnapshotDto>>());
      final success = result as SetupSuccess<LearningSetupSnapshotDto>;
      expect(success.data.revision, 'rev-01');
      expect(success.data.teachingSkills, ['skill-1']);
      expect(success.data.goals.first.text, 'Master Dart');
    });

    test('updateSelections succeeds and passes parameters', () async {
      final result = await repository.updateSelections(
        expectedRevision: 'rev-01',
        teachingSkills: ['t-1'],
        learningSkills: ['l-1'],
        idempotencyKey: 'key-1',
      );

      expect(result, isA<SetupSuccess<void>>());
      expect(remote.updateSelectionsCalled, isTrue);
    });

    test('createGoal, editGoal, removeGoal succeed', () async {
      final createRes = await repository.createGoal(
        expectedRevision: 'rev-01',
        text: 'New goal',
        idempotencyKey: 'key-1',
      );
      expect(createRes, isA<SetupSuccess<void>>());
      expect(remote.createGoalCalled, isTrue);

      final editRes = await repository.editGoal(
        expectedRevision: 'rev-01',
        goalId: '00000000-0000-0000-0000-000000000001',
        text: 'Updated goal',
        idempotencyKey: 'key-2',
      );
      expect(editRes, isA<SetupSuccess<void>>());
      expect(remote.editGoalCalled, isTrue);

      final removeRes = await repository.removeGoal(
        expectedRevision: 'rev-01',
        goalId: '00000000-0000-0000-0000-000000000001',
        idempotencyKey: 'key-3',
      );
      expect(removeRes, isA<SetupSuccess<void>>());
      expect(remote.removeGoalCalled, isTrue);
    });

    test('maps HandoffIssue.conflict to SetupConflict', () async {
      remote.errorToThrow = const HandoffFailure(HandoffIssue.conflict);

      final result = await repository.updateSelections(
        expectedRevision: 'stale-rev',
        teachingSkills: [],
        learningSkills: [],
        idempotencyKey: 'key-1',
      );

      expect(result, isA<SetupConflict<void>>());
    });

    test('maps HandoffIssue.badRequest to SetupBadRequest', () async {
      remote.errorToThrow = const HandoffFailure(HandoffIssue.badRequest);

      final result = await repository.createGoal(
        expectedRevision: 'rev-01',
        text: 'Goal',
        idempotencyKey: 'key-1',
      );

      expect(result, isA<SetupBadRequest<void>>());
    });

    test('maps HandoffIssue.unavailable to SetupUnavailable', () async {
      remote.errorToThrow = const HandoffFailure(HandoffIssue.unavailable);

      final result = await repository.readSetup();

      expect(result, isA<SetupUnavailable<LearningSetupSnapshotDto>>());
    });

    test('returns SetupUnauthorized if session is signed out', () async {
      source.backendCredential = null;
      source.signals.add(const SessionEvent(SessionEventKind.signedOut));
      await Future<void>.delayed(Duration.zero);

      final result = await repository.readSetup();

      expect(result, isA<SetupUnauthorized<LearningSetupSnapshotDto>>());
    });
  });
}
