import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/profile/data/datasources/learning_remote_data_source.dart';
import 'package:andril_mobile/features/learning/profile/data/models/learning_setup_snapshot_dto.dart';
import 'package:andril_mobile/features/learning/profile/data/repositories/learning_profile_api_repository.dart';
import 'package:andril_mobile/features/learning/profile/domain/entities/learning_profile.dart';
import 'package:andril_mobile/features/learning/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared_core/authentication/foundation_fakes.dart';

class _FakeRemoteDataSource implements ILearningRemoteDataSource {
  Map<String, Object?> draftToReturn = {
    'displayName': 'Alex Learner',
    'bio': 'Passionate about mobile apps',
    'visibility': 'private',
  };
  Object? errorToThrow;
  bool updateProfileDraftCalled = false;

  @override
  Future<Map<String, Object?>> getProfileDraft(BackendSession session) async {
    if (errorToThrow != null) throw errorToThrow!;
    return draftToReturn;
  }

  @override
  Future<LearningSetupSnapshotDto> getLearningSetup(
      BackendSession session) async {
    return const LearningSetupSnapshotDto(
      revision: 'rev-01',
      teachingSkills: ['Flutter'],
      learningSkills: ['Rust'],
      goals: [LearningGoalItemDto(goalId: 'g-1', text: 'Build mobile client')],
    );
  }

  @override
  Future<Map<String, Object?>> updateProfileDraft({
    required BackendSession session,
    required String displayName,
    String? bio,
    String visibility = 'private',
    Map<String, Object?>? preferences,
    String? avatarUrl,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    updateProfileDraftCalled = true;
    return {
      'displayName': displayName,
      'bio': bio,
      'visibility': visibility,
      if (preferences != null) 'preferences': preferences,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

  @override
  Future<void> updateLearningSelections({
    required BackendSession session,
    required String expectedRevision,
    required List<String> teachingSkills,
    required List<String> learningSkills,
    required String idempotencyKey,
  }) async {}

  @override
  Future<void> createLearningGoal({
    required BackendSession session,
    required String expectedRevision,
    required String text,
    required String idempotencyKey,
  }) async {}

  @override
  Future<void> editLearningGoal({
    required BackendSession session,
    required String expectedRevision,
    required String goalId,
    required String text,
    required String idempotencyKey,
  }) async {}

  @override
  Future<void> removeLearningGoal({
    required BackendSession session,
    required String expectedRevision,
    required String goalId,
    required String idempotencyKey,
  }) async {}

  @override
  Future<Map<String, Object?>> getCurrentPhotoStatus(
          BackendSession session) async =>
      {'status': 'active'};
}

class _Source extends FakeSessionSource implements BackendSessionSource {
  _Source()
      : super(
            restored: const SessionEvent(SessionEventKind.initial,
                subject: 'user-42'));

  @override
  BackendCredential? backendCredential = const BackendCredential(
      'user-42', 'fake.token.jwt',
      emailConfirmed: true);

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}
}

void main() {
  late _Source source;
  late SessionController session;
  late _FakeRemoteDataSource remote;
  late LearningProfileApiRepository repository;

  setUp(() async {
    source = _Source();
    session = SessionController(source);
    remote = _FakeRemoteDataSource();
    repository = LearningProfileApiRepository(
      sessionController: session,
      remoteDataSource: remote,
    );
    await session.start();
  });

  tearDown(() async {
    session.dispose();
    await source.signals.close();
  });

  group('LearningProfileApiRepository', () {
    test('getProfile returns ProfileSuccess with merged profile and setup data',
        () async {
      final result = await repository.getProfile();

      expect(result, isA<ProfileSuccess<LearningProfile>>());
      final success = result as ProfileSuccess<LearningProfile>;
      expect(success.data.displayName, 'Alex Learner');
      expect(success.data.bio, 'Passionate about mobile apps');
      expect(success.data.skillsToShare, ['Flutter']);
      expect(success.data.skillsToLearn, ['Rust']);
      expect(success.data.learningGoals, ['Build mobile client']);
      expect(success.data.module, 'learning');
    });

    test('updateProfile succeeds when caller owns profile', () async {
      final profile = LearningProfile(
        profileId: 'user-42',
        accountId: 'user-42',
        displayName: 'Alex Updated',
        bio: 'Updated bio',
      );

      final result = await repository.updateProfile(profile);

      expect(result, isA<ProfileSuccess<LearningProfile>>());
      expect(remote.updateProfileDraftCalled, isTrue);
    });

    test(
        'updateProfile denies access when caller attempts to update another user profile',
        () async {
      final profile = LearningProfile(
        profileId: 'another-user',
        accountId: 'another-user',
        displayName: 'Impersonator',
      );

      final result = await repository.updateProfile(profile);

      expect(result, isA<ProfileAccessDenied<LearningProfile>>());
    });

    test('saveDraftProfile caches locally and updates draft', () async {
      final result = await repository.saveDraftProfile(
        displayName: 'Draft Name',
        skillsToLearn: ['Skill A'],
        learningGoals: ['Goal A'],
      );

      expect(result, isA<ProfileSuccess<LearningProfile>>());
      final success = result as ProfileSuccess<LearningProfile>;
      expect(success.data.displayName, 'Draft Name');
      expect(success.data.skillsToLearn, ['Skill A']);
    });

    test('maps HandoffFailure(reauthenticationRequired) to ProfileAccessDenied',
        () async {
      remote.errorToThrow =
          const HandoffFailure(HandoffIssue.reauthenticationRequired);

      final result = await repository.getProfile();

      expect(result, isA<ProfileAccessDenied<LearningProfile>>());
    });

    test('maps HandoffFailure(unavailable) to ProfileDependencyUnavailable',
        () async {
      remote.errorToThrow = const HandoffFailure(HandoffIssue.unavailable);

      final result = await repository.getProfile();

      expect(result, isA<ProfileDependencyUnavailable<LearningProfile>>());
    });
  });
}
