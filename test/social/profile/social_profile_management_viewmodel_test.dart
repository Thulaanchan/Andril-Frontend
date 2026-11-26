import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_draft.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_management_repository.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_management_viewmodel.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_repository.dart';

class MockSocialProfileManagementRepository implements ISocialProfileManagementRepository {
  SocialProfileResult getResult = const SocialProfileResult.success(SocialProfileDraft(
    displayName: 'ElenaR',
    bio: 'Photographer and traveler',
    visibility: 'private',
  ));

  SocialProfileResult updateResult = const SocialProfileResult.success(SocialProfileDraft(
    displayName: 'ElenaUpdated',
    bio: 'Updated bio description',
    visibility: 'private',
  ));

  int getCallCount = 0;
  int updateCallCount = 0;

  @override
  Future<SocialProfileResult> getProfile() async {
    getCallCount++;
    return getResult;
  }

  @override
  Future<SocialProfileResult> updateProfile(SocialProfileDraft draft) async {
    updateCallCount++;
    return updateResult;
  }
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  final List<VoidCallback> _clearers = [];

  @override
  SessionPhase get phase => _phase;

  void setPhase(SessionPhase phase) {
    _phase = phase;
    notifyListeners();
  }

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) {
    _clearers.add(clearer);
    return () => _clearers.remove(clearer);
  }

  void invokeClearers() {
    for (final c in List.of(_clearers)) {
      c();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockSocialProfileManagementRepository mockRepo;
  late FakeSessionController fakeSession;

  setUp(() {
    mockRepo = MockSocialProfileManagementRepository();
    fakeSession = FakeSessionController();
  });

  group('SocialProfileManagementViewModel', () {
    test('initializes with initial status and empty drafts', () {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.status, SocialProfileManagementStatus.initial);
      expect(vm.hasUnsavedChanges, isFalse);
      expect(vm.canSave, isFalse);
      expect(vm.profile.displayName, isEmpty);
    });

    test('denies access if caller is not opted in or session is not signed in', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );

      await vm.loadProfile();

      expect(vm.status, SocialProfileManagementStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      expect(mockRepo.getCallCount, 0);
    });

    test('loads profile successfully and tracks server state', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadProfile();

      expect(vm.status, SocialProfileManagementStatus.ready);
      expect(vm.isReady, isTrue);
      expect(vm.profile.displayName, 'ElenaR');
      expect(vm.draft.displayName, 'ElenaR');
      expect(vm.hasUnsavedChanges, isFalse);
    });

    test('tracks edits and allows saving when valid and modified', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadProfile();

      vm.updateDisplayName('ElenaUpdated');
      expect(vm.hasUnsavedChanges, isTrue);
      expect(vm.canSave, isTrue);

      final success = await vm.saveProfile();
      expect(success, isTrue);
      expect(vm.status, SocialProfileManagementStatus.ready);
      expect(vm.profile.displayName, 'ElenaUpdated');
      expect(vm.hasUnsavedChanges, isFalse);
    });

    test('discards unsaved edits when discardEdits is called', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadProfile();

      vm.updateDisplayName('UnsavedName');
      vm.updateBio('UnsavedBio');
      expect(vm.hasUnsavedChanges, isTrue);

      vm.discardEdits();
      expect(vm.hasUnsavedChanges, isFalse);
      expect(vm.draft.displayName, 'ElenaR');
      expect(vm.draft.bio, 'Photographer and traveler');
    });

    test('handles server-side display name conflict error', () async {
      mockRepo.updateResult = const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.displayNameUnavailable,
        message: 'The display name is already taken.',
      ));

      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadProfile();
      vm.updateDisplayName('TakenName');

      final success = await vm.saveProfile();
      expect(success, isFalse);
      expect(vm.status, SocialProfileManagementStatus.error);
      expect(vm.errorMessage, 'The display name is already taken.');
    });

    test('clears private profile on session invalidation', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadProfile();
      expect(vm.profile.displayName, 'ElenaR');

      fakeSession.setPhase(SessionPhase.signedOut);
      expect(vm.status, SocialProfileManagementStatus.accessDenied);
      expect(vm.profile.displayName, isEmpty);
    });

    test('private state clearer resets private profile drafts', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadProfile();
      expect(vm.profile.displayName, 'ElenaR');

      fakeSession.invokeClearers();
      expect(vm.profile.displayName, isEmpty);
    });
  });
}
