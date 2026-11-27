import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';
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
  Future<SocialProfileResult> Function()? onGetProfile;
  Future<SocialProfileResult> Function(SocialProfileDraft draft)? onUpdateProfile;

  @override
  Future<SocialProfileResult> getProfile() async {
    getCallCount++;
    if (onGetProfile != null) {
      return onGetProfile!();
    }
    return getResult;
  }

  @override
  Future<SocialProfileResult> updateProfile(SocialProfileDraft draft) async {
    updateCallCount++;
    if (onUpdateProfile != null) {
      return onUpdateProfile!(draft);
    }
    return updateResult;
  }
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject = 'test_user_01';
  final List<VoidCallback> _clearers = [];

  @override
  SessionPhase get phase => _phase;

  @override
  String? get subject => _subject;

  set subject(String? value) {
    _subject = value;
    notifyListeners();
  }

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

    test('allows profile editing during onboarding before social opt-in', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isOnboarding: true,
        isSocialOptedIn: false,
      );

      await vm.loadProfile();
      expect(vm.isAuthorized, isTrue);
      expect(vm.status, SocialProfileManagementStatus.ready);
      expect(vm.profile.displayName, 'ElenaR');
    });

    test('denies access and fails closed when default constructor is called without opt-in', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
      );

      await vm.loadProfile();
      expect(vm.isAuthorized, isFalse);
      expect(vm.status, SocialProfileManagementStatus.accessDenied);
    });

    test('authorizes via SocialAccessEvidence when provided', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'test_user_01'),
      );

      await vm.loadProfile();
      expect(vm.isAuthorized, isTrue);
      expect(vm.status, SocialProfileManagementStatus.ready);
    });

    test('denies access and clears profile upon account switch', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadProfile();
      expect(vm.profile.displayName, 'ElenaR');

      fakeSession.subject = 'switched_user_02';
      expect(vm.status, SocialProfileManagementStatus.accessDenied);
      expect(vm.profile.displayName, isEmpty);
    });

    test('session switch during inflight loadProfile discards response and sets accessDenied', () async {
      final completer = Completer<SocialProfileResult>();
      mockRepo.onGetProfile = () => completer.future;

      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      final futureLoad = vm.loadProfile();
      expect(vm.isLoading, isTrue);

      fakeSession.subject = 'switched_user_02';
      completer.complete(const SocialProfileResult.success(SocialProfileDraft(
        displayName: 'LateProfile',
        bio: 'Late bio',
      )));

      await futureLoad;

      expect(vm.status, SocialProfileManagementStatus.accessDenied);
      expect(vm.profile.displayName, isEmpty);
      expect(vm.draft.displayName, isEmpty);
    });

    test('session switch during inflight saveProfile discards response and sets accessDenied', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadProfile();
      vm.updateDisplayName('ElenaUpdated');

      final completer = Completer<SocialProfileResult>();
      mockRepo.onUpdateProfile = (_) => completer.future;

      final futureSave = vm.saveProfile();
      expect(vm.isSaving, isTrue);

      fakeSession.subject = 'switched_user_02';
      completer.complete(const SocialProfileResult.success(SocialProfileDraft(
        displayName: 'ElenaUpdated',
        bio: 'Photographer and traveler',
      )));

      final saved = await futureSave;

      expect(saved, isFalse);
      expect(vm.isSaving, isFalse);
      expect(vm.status, SocialProfileManagementStatus.accessDenied);
      expect(vm.profile.displayName, isEmpty);
    });

    test('sign out during inflight saveProfile discards response and resets isSaving', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadProfile();
      vm.updateDisplayName('ElenaUpdated');

      final completer = Completer<SocialProfileResult>();
      mockRepo.onUpdateProfile = (_) => completer.future;

      final futureSave = vm.saveProfile();
      expect(vm.isSaving, isTrue);

      fakeSession.setPhase(SessionPhase.signedOut);
      completer.complete(const SocialProfileResult.success(SocialProfileDraft(
        displayName: 'ElenaUpdated',
      )));

      final saved = await futureSave;

      expect(saved, isFalse);
      expect(vm.isSaving, isFalse);
      expect(vm.status, SocialProfileManagementStatus.accessDenied);
    });

    test('prevents concurrent duplicate saveProfile calls', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadProfile();
      vm.updateDisplayName('ElenaUpdated');

      final completer = Completer<SocialProfileResult>();
      mockRepo.onUpdateProfile = (_) => completer.future;

      final firstSave = vm.saveProfile();
      expect(vm.isSaving, isTrue);
      expect(vm.canSave, isFalse);

      final secondSave = vm.saveProfile();
      expect(await secondSave, isFalse);

      completer.complete(const SocialProfileResult.success(SocialProfileDraft(
        displayName: 'ElenaUpdated',
        bio: 'Photographer and traveler',
      )));

      expect(await firstSave, isTrue);
      expect(mockRepo.updateCallCount, 1);
      expect(vm.status, SocialProfileManagementStatus.ready);
    });

    test('preserves unsaved edits in draft after recoverable save failure', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadProfile();
      vm.updateDisplayName('TakenName');
      vm.updateBio('My draft bio');

      mockRepo.updateResult = const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.displayNameUnavailable,
        message: 'The display name is already taken.',
      ));

      final saved = await vm.saveProfile();
      expect(saved, isFalse);
      expect(vm.status, SocialProfileManagementStatus.error);
      expect(vm.errorMessage, 'The display name is already taken.');

      // Unsaved edits are preserved in editing draft
      expect(vm.draft.displayName, 'TakenName');
      expect(vm.draft.bio, 'My draft bio');
      expect(vm.hasUnsavedChanges, isTrue);

      // User fixes display name -> transient error clears, canSave is true again
      vm.updateDisplayName('UniqueName');
      expect(vm.status, SocialProfileManagementStatus.ready);
      expect(vm.errorMessage, isNull);
      expect(vm.canSave, isTrue);
    });

    test('maps missing profile and dependency failures to error status', () async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      mockRepo.getResult = const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.dependencyFailure,
        message: 'Private Social profile not found.',
      ));

      await vm.loadProfile();
      expect(vm.status, SocialProfileManagementStatus.error);
      expect(vm.errorMessage, 'Private Social profile not found.');
    });
  });
}
