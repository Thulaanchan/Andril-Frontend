import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/profile/data/datasources/learning_remote_data_source.dart';
import 'package:andril_mobile/features/learning/profile/data/models/learning_setup_snapshot_dto.dart';
import 'package:andril_mobile/features/learning/profile/data/repositories/learning_profile_api_repository.dart';
import 'package:andril_mobile/features/learning/profile/data/repositories/learning_setup_api_repository.dart';
import 'package:andril_mobile/features/learning/profile/domain/entities/learning_preferences.dart';
import 'package:andril_mobile/features/learning/profile/domain/entities/learning_profile.dart';
import 'package:andril_mobile/features/learning/profile/domain/repositories/profile_repository.dart';
import '../../shared_core/authentication/foundation_fakes.dart';

class _FakeRemoteDataSource implements ILearningRemoteDataSource {
  Map<String, Object?> draftToReturn = {
    'displayName': 'Alex Learner',
    'bio': 'Passionate about mobile apps',
    'visibility': 'private',
    'accountId': 'acc_user_42',
    'profileId': 'lp_user_42',
    'isActivated': false,
  };
  Map<String, Object?> photoStatusToReturn = {
    'status': 'active',
    'photoUrl': 'https://cdn.andril.com/photos/avatar1.jpg',
  };
  LearningSetupSnapshotDto setupToReturn = const LearningSetupSnapshotDto(
    revision: 'rev-01',
    teachingSkills: ['Flutter', 'Clean Architecture'],
    learningSkills: ['Dart Concurrency', 'GraphQL'],
    goals: [
      LearningGoalItemDto(goalId: 'g-1', text: 'Master state management')
    ],
  );

  Object? errorToThrow;
  Map<String, Object?>? lastUpdatedDraft;
  bool updateSelectionsCalled = false;
  String? lastExpectedRevision;
  String? lastIdempotencyKey;
  Object? setupUpdateErrorToThrow;

  @override
  Future<Map<String, Object?>> getProfileDraft(BackendSession session) async {
    if (errorToThrow != null) throw errorToThrow!;
    return draftToReturn;
  }

  @override
  Future<Map<String, Object?>> getCurrentPhotoStatus(
      BackendSession session) async {
    if (errorToThrow != null) throw errorToThrow!;
    return photoStatusToReturn;
  }

  @override
  Future<LearningSetupSnapshotDto> getLearningSetup(
      BackendSession session) async {
    if (errorToThrow != null) throw errorToThrow!;
    return setupToReturn;
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
    lastUpdatedDraft = {
      'displayName': displayName,
      'bio': bio,
      'visibility': visibility,
      if (preferences != null) 'preferences': preferences,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
    return lastUpdatedDraft!;
  }

  @override
  Future<void> updateLearningSelections({
    required BackendSession session,
    required String expectedRevision,
    required List<String> teachingSkills,
    required List<String> learningSkills,
    required String idempotencyKey,
  }) async {
    if (setupUpdateErrorToThrow != null) throw setupUpdateErrorToThrow!;
    updateSelectionsCalled = true;
    lastExpectedRevision = expectedRevision;
    lastIdempotencyKey = idempotencyKey;
  }

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
}

class _Source extends FakeSessionSource implements BackendSessionSource {
  _Source({String subject = 'user-42'})
      : super(
          restored: SessionEvent(SessionEventKind.initial, subject: subject),
        );

  @override
  BackendCredential? backendCredential = const BackendCredential(
    'user-42',
    'fake.token.jwt',
    emailConfirmed: true,
  );

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}
}

void main() {
  late _Source source;
  late SessionController sessionController;
  late _FakeRemoteDataSource remote;
  late LearningSetupApiRepository setupRepository;
  late LearningProfileApiRepository profileRepository;

  setUp(() async {
    source = _Source();
    sessionController = SessionController(source);
    remote = _FakeRemoteDataSource();
    setupRepository = LearningSetupApiRepository(
      sessionController: sessionController,
      remoteDataSource: remote,
    );
    profileRepository = LearningProfileApiRepository(
      sessionController: sessionController,
      remoteDataSource: remote,
      setupRepository: setupRepository,
    );
    await sessionController.start();
  });

  tearDown(() async {
    profileRepository.dispose();
    sessionController.dispose();
    await source.signals.close();
  });

  group('Task 06-01: Learning Admission, Profile & Preferences Tests', () {
    test('1. Distinguishes Account ID from Learning Profile ID', () async {
      final result = await profileRepository.getProfile();

      expect(result, isA<ProfileSuccess<LearningProfile>>());
      final profile = (result as ProfileSuccess<LearningProfile>).data;

      // Invariant: accountId and profileId are separate identifiers
      expect(profile.accountId, 'acc_user_42');
      expect(profile.profileId, 'lp_user_42');
      expect(profile.accountId, isNot(equals(profile.profileId)));
    });

    test('2. Enforces M2 admission control: activation is false by default',
        () async {
      // By default M2 admission has not authorized module home
      expect(sessionController.moduleHomeAuthorized, isFalse);

      final result = await profileRepository.getProfile();
      final profile = (result as ProfileSuccess<LearningProfile>).data;

      // Must never locally assume or fabricate activation
      expect(profile.isActivated, isFalse);
    });

    test('3. Enriches profile with authorized photo status and avatar URL',
        () async {
      final result = await profileRepository.getProfile();
      final profile = (result as ProfileSuccess<LearningProfile>).data;

      expect(profile.avatarUrl, 'https://cdn.andril.com/photos/avatar1.jpg');
    });

    test(
        '4. Display name validation: rejects empty, whitespace, and short names',
        () async {
      final base = LearningProfile(
        profileId: 'lp_user-42',
        accountId: 'user-42',
        displayName: 'Alex Learner',
      );

      // Empty name
      final emptyResult = await profileRepository.updateProfile(
        base.copyWith(displayName: '   '),
      );
      expect(emptyResult, isA<ProfileFailure<LearningProfile>>());

      // Too short (< 2 characters)
      final shortResult = await profileRepository.updateProfile(
        base.copyWith(displayName: 'A'),
      );
      expect(shortResult, isA<ProfileFailure<LearningProfile>>());

      // Valid name succeeds
      final validResult = await profileRepository.updateProfile(
        base.copyWith(displayName: 'Alexander'),
      );
      expect(validResult, isA<ProfileSuccess<LearningProfile>>());
      expect(remote.lastUpdatedDraft?['displayName'], 'Alexander');
    });

    test('5. Module isolation: rejects non-learning module profile updates',
        () async {
      // Creating with wrong module throws ArgumentError at entity invariant level
      expect(
        () => LearningProfile(
          profileId: 'lp_user-42',
          accountId: 'user-42',
          module: 'hobbies',
          displayName: 'Alex',
        ),
        throwsArgumentError,
      );
    });

    test('6. Ownership verification: caller cannot update another user profile',
        () async {
      final otherUserProfile = LearningProfile(
        profileId: 'lp_other_user',
        accountId: 'other_user_account',
        displayName: 'Attacker Name',
      );

      final result = await profileRepository.updateProfile(otherUserProfile);
      expect(result, isA<ProfileAccessDenied<LearningProfile>>());
    });

    test(
        '7. Skill updates under optimistic revision control with idempotency key',
        () async {
      final profile = LearningProfile(
        profileId: 'lp_user-42',
        accountId: 'user-42',
        displayName: 'Alex Learner',
        skillsToShare: [
          'Flutter',
          'Dart',
          'Kotlin'
        ], // Modified from 'Clean Architecture'
        skillsToLearn: ['Dart Concurrency', 'GraphQL'],
      );

      final result = await profileRepository.updateProfile(profile);
      expect(result, isA<ProfileSuccess<LearningProfile>>());
      expect(remote.updateSelectionsCalled, isTrue);
      expect(remote.lastExpectedRevision, 'rev-01');
      expect(remote.lastIdempotencyKey, contains('idemp_sync_'));
    });

    test('8. Handles revision conflict during skill sync gracefully', () async {
      remote.setupUpdateErrorToThrow = const HandoffFailure(
        HandoffIssue.conflict,
      );

      final profile = LearningProfile(
        profileId: 'lp_user-42',
        accountId: 'user-42',
        displayName: 'Alex Learner',
        skillsToShare: ['New Skill'],
        skillsToLearn: ['Another Skill'],
      );

      final result = await profileRepository.updateProfile(profile);
      expect(result, isA<ProfileFailure<LearningProfile>>());
      final failure = result as ProfileFailure<LearningProfile>;
      expect(failure.message, contains('Revision conflict'));
    });

    test('9. Session revocation purges private cached state', () async {
      // First, populate cache
      await profileRepository.getProfile();

      // Revoke session
      source.signals.add(const SessionEvent(SessionEventKind.signedOut));
      await Future<void>.delayed(Duration.zero);

      // Private cache should be wiped
      final resultAfterRevocation = await profileRepository.getProfile();
      expect(
          resultAfterRevocation, isA<ProfileAccessDenied<LearningProfile>>());
    });

    test('10. Offline resilience: returns cached draft when service is down',
        () async {
      // Populate cache on successful load
      final initial = await profileRepository.getProfile();
      expect(initial, isA<ProfileSuccess<LearningProfile>>());

      // Simulate remote outage
      remote.errorToThrow = const HandoffFailure(HandoffIssue.unavailable);

      // Should return cached draft
      final offlineResult = await profileRepository.getProfile();
      expect(offlineResult, isA<ProfileSuccess<LearningProfile>>());
      final cachedProfile =
          (offlineResult as ProfileSuccess<LearningProfile>).data;
      expect(cachedProfile.displayName, 'Alex Learner');
    });

    test('11. Preferences persistence and serialization', () async {
      const preferences = LearningPreferences(
        languages: ['English', 'Tamil'],
        learningStyles: ['Hands-on Practice', 'Video Learning'],
        availability: 'Evening (6 PM – 10 PM)',
        notifications: {
          'Connection requests': true,
          'Classroom & circle updates': false,
        },
      );

      final json = preferences.toJson();
      final roundtrip = LearningPreferences.fromJson(json);

      expect(roundtrip.languages, ['English', 'Tamil']);
      expect(roundtrip.learningStyles, ['Hands-on Practice', 'Video Learning']);
      expect(roundtrip.availability, 'Evening (6 PM – 10 PM)');
      expect(roundtrip.notifications['Connection requests'], isTrue);
      expect(roundtrip.notifications['Classroom & circle updates'], isFalse);
    });
  });
}
