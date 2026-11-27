import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/interests_preferences/data/social_preferences_repository.dart';
import 'package:andril_mobile/features/social/interests_preferences/domain/social_preferences_model.dart';
import 'package:andril_mobile/features/social/interests_preferences/presentation/social_preferences_viewmodel.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';

import '../../shared_core/authentication/foundation_fakes.dart';

class _FakePreferencesRepo implements ISocialPreferencesRepository {
  SocialPreferencesModel model = SocialPreferencesModel(
    selectedInterests: const {'music'},
    minAge: 20,
    maxAge: 40,
    maxDistanceKm: 30,
    relationshipGoals: const ['Friendship'],
    languages: const ['English'],
  );
  int updateCallCount = 0;
  bool shouldFail = false;

  @override
  Future<SocialPreferencesResult<SocialPreferencesModel>> getPreferences() async {
    if (shouldFail) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Simulated load failure',
        failureType: SocialPreferencesFailureType.unknown,
      );
    }
    return SocialPreferencesResult.success(model);
  }

  @override
  Future<SocialPreferencesResult<SocialPreferencesModel>> updatePreferences(
      SocialPreferencesModel preferences) async {
    updateCallCount++;
    if (shouldFail) {
      return const SocialPreferencesResult.failure(
        errorMessage: 'Simulated update failure',
        failureType: SocialPreferencesFailureType.serviceUnavailable,
      );
    }
    model = preferences;
    return SocialPreferencesResult.success(model);
  }

  @override
  Future<SocialPreferencesResult<String>> getAccountLanguage() async =>
      const SocialPreferencesResult.success('en');

  @override
  Future<SocialPreferencesResult<String>> updateAccountLanguage(String languageCode) async =>
      SocialPreferencesResult.success(languageCode);
}

class _FakeVmSource extends FakeSessionSource implements BackendSessionSource {
  _FakeVmSource()
      : super(
          restored: const SessionEvent(SessionEventKind.initial, subject: 'user-vm'),
        );

  @override
  BackendCredential? backendCredential =
      const BackendCredential('user-vm', 'fake.token.vm', emailConfirmed: true);

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}
}

void main() {
  group('SocialPreferencesViewModel (Task 153)', () {
    late _FakePreferencesRepo repo;
    late SessionController session;
    late SocialAccessEvidence evidence;

    setUp(() async {
      repo = _FakePreferencesRepo();
      final source = _FakeVmSource();
      session = SessionController(source);
      await session.start();
      evidence = SocialAccessEvidence.authorized(userId: 'user-vm');
    });

    tearDown(() {
      session.dispose();
    });

    test('initial state has empty preferences and initial status', () {
      final vm = SocialPreferencesViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );

      expect(vm.status, SocialPreferencesStatus.initial);
      expect(vm.preferences.selectedInterests, isEmpty);
      expect(vm.isAuthorized, isTrue);
    });

    test('loadPreferences fails closed when caller is not authorized', () async {
      final vm = SocialPreferencesViewModel(
        repository: repo,
        sessionController: null,
        accessEvidence: null,
        isSocialOptedIn: false,
      );

      await vm.loadPreferences();

      expect(vm.status, SocialPreferencesStatus.failure);
      expect(vm.errorMessage, contains('not authorized'));
    });

    test('loadPreferences successfully loads preferences from repository', () async {
      final vm = SocialPreferencesViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );

      await vm.loadPreferences();

      expect(vm.status, SocialPreferencesStatus.ready);
      expect(vm.preferences.selectedInterests, contains('music'));
      expect(vm.preferences.minAge, 20);
    });

    test('savePreferences rejects invalid model without calling repository', () async {
      final vm = SocialPreferencesViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );

      final invalid = SocialPreferencesModel(minAge: 16);
      final success = await vm.savePreferences(invalid);

      expect(success, isFalse);
      expect(vm.status, SocialPreferencesStatus.failure);
      expect(repo.updateCallCount, 0);
      expect(vm.errorMessage, contains('Invalid preferences'));
    });

    test('savePreferences succeeds and updates model on valid input', () async {
      final vm = SocialPreferencesViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );

      final valid = SocialPreferencesModel(
        minAge: 25,
        maxAge: 40,
        maxDistanceKm: 50,
        selectedInterests: const {'art', 'tech'},
      );
      final success = await vm.savePreferences(valid);

      expect(success, isTrue);
      expect(vm.status, SocialPreferencesStatus.success);
      expect(repo.updateCallCount, 1);
      expect(vm.preferences.selectedInterests, containsAll(['art', 'tech']));
    });

    test('toggles interest and goals mutating state immutably', () {
      final vm = SocialPreferencesViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );

      vm.toggleInterest('gaming');
      expect(vm.preferences.selectedInterests, contains('gaming'));

      vm.toggleInterest('gaming');
      expect(vm.preferences.selectedInterests, isNot(contains('gaming')));

      vm.toggleRelationshipGoal('Networking');
      expect(vm.preferences.relationshipGoals, isNot(contains('Networking')));

      vm.toggleRelationshipGoal('Networking');
      expect(vm.preferences.relationshipGoals, contains('Networking'));
    });
  });
}
