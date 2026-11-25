import 'dart:async';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_draft.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_repository.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-local repository double simulating backend responses and delays.
class FakeSocialProfileRepository implements SocialProfileRepository {
  SocialProfileResult? nextResult;
  Completer<SocialProfileResult>? pendingCompleter;
  int saveCallCount = 0;
  SocialProfileDraft? lastSavedDraft;

  @override
  Future<SocialProfileResult> getProfileDraft() async {
    return nextResult ??
        const SocialProfileResult.success(SocialProfileDraft());
  }

  @override
  Future<SocialProfileResult> createProfileDraft() async {
    return nextResult ??
        const SocialProfileResult.success(SocialProfileDraft());
  }

  @override
  Future<SocialProfileResult> saveProfileDraft(SocialProfileDraft draft) async {
    saveCallCount++;
    lastSavedDraft = draft;
    if (pendingCompleter != null) {
      return pendingCompleter!.future;
    }
    return nextResult ?? SocialProfileResult.success(draft);
  }
}

void main() {
  late FakeSocialProfileRepository repository;
  late SocialProfileViewModel viewModel;

  setUp(() {
    repository = FakeSocialProfileRepository();
    viewModel = SocialProfileViewModel(repository: repository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('SocialProfileViewModel State & Security Tests (M5-FE-S02-SEC-02)', () {
    test('initial state has default empty draft and initial status', () {
      expect(viewModel.status, SocialProfileStatus.initial);
      expect(viewModel.draft.displayName, '');
      expect(viewModel.draft.bio, isNull);
      expect(viewModel.draft.visibility, 'private');
      expect(viewModel.canSubmit, isFalse);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.isSuccess, isFalse);
      expect(viewModel.isConflict, isFalse);
      expect(viewModel.isDenied, isFalse);
      expect(viewModel.isError, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('field updates update draft and enable submission when valid', () {
      bool notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.updateDisplayName('Thulaan');
      expect(notified, isTrue);
      expect(viewModel.draft.displayName, 'Thulaan');
      expect(viewModel.canSubmit, isTrue);

      viewModel.updateBio('Exploring ANDRIL Social');
      expect(viewModel.draft.bio, 'Exploring ANDRIL Social');

      viewModel.updateProfilePhoto('/local/path/photo.png');
      expect(viewModel.draft.profilePhotoPath, '/local/path/photo.png');
      expect(viewModel.canSubmit, isTrue);
    });

    test('successful draft save transitions to success state without completion flag', () async {
      viewModel.updateDisplayName('ValidUser');
      viewModel.updateBio('Valid Bio');

      repository.nextResult = SocialProfileResult.success(
        viewModel.draft.copyWith(displayName: 'ValidUser'),
      );

      final success = await viewModel.saveDraft();

      expect(success, isTrue);
      expect(viewModel.status, SocialProfileStatus.success);
      expect(viewModel.isSuccess, isTrue);
      expect(viewModel.errorMessage, isNull);
      expect(repository.saveCallCount, 1);
      expect(repository.lastSavedDraft?.displayName, 'ValidUser');
      expect(viewModel.draft.visibility, 'private');
    });

    test('prevents invalid submission without contacting repository', () async {
      viewModel.updateDisplayName('Ab'); // Too short (minimum 3)
      expect(viewModel.canSubmit, isFalse);

      final success = await viewModel.saveDraft();

      expect(success, isFalse);
      expect(viewModel.status, SocialProfileStatus.error);
      expect(viewModel.errorMessage, contains('at least 3 characters'));
      expect(repository.saveCallCount, 0);
    });

    test('prevents duplicate concurrent submissions while loading', () async {
      viewModel.updateDisplayName('ConcurrentTest');
      final completer = Completer<SocialProfileResult>();
      repository.pendingCompleter = completer;

      // Start first save
      final future1 = viewModel.saveDraft();
      expect(viewModel.isLoading, isTrue);
      expect(viewModel.canSubmit, isFalse);

      // Attempt second save concurrently
      final future2 = viewModel.saveDraft();

      // Complete the pending backend operation
      completer.complete(SocialProfileResult.success(viewModel.draft));

      final result1 = await future1;
      final result2 = await future2;

      expect(result1, isTrue);
      expect(result2, isFalse); // Second call rejected immediately
      expect(repository.saveCallCount, 1); // Repository invoked exactly once
    });

    test('resetStatus cannot permit duplicate requests while in-flight', () async {
      viewModel.updateDisplayName('InFlightUser');
      final completer = Completer<SocialProfileResult>();
      repository.pendingCompleter = completer;

      final saveFuture = viewModel.saveDraft();
      expect(viewModel.isLoading, isTrue);

      // Attempt resetStatus while save is actively in flight
      viewModel.resetStatus();
      expect(viewModel.isLoading, isTrue); // Must remain loading!

      // Second save attempt must still be rejected
      final duplicateAttempt = viewModel.saveDraft();
      expect(duplicateAttempt, completion(isFalse));

      completer.complete(SocialProfileResult.success(viewModel.draft));
      await saveFuture;
      expect(repository.saveCallCount, 1);
    });

    test('handles display-name conflict by transitioning to conflict state', () async {
      viewModel.updateDisplayName('ReservedName');

      repository.nextResult = const SocialProfileResult.failure(
        SocialProfileFailure(
          type: SocialProfileFailureType.displayNameUnavailable,
          message: 'The display name is already taken.',
        ),
      );

      final success = await viewModel.saveDraft();

      expect(success, isFalse);
      expect(viewModel.status, SocialProfileStatus.conflict);
      expect(viewModel.isConflict, isTrue);
      expect(viewModel.errorMessage, contains('already taken'));

      // Modifying display name resets conflict status
      viewModel.updateDisplayName('NewAvailableName');
      expect(viewModel.status, SocialProfileStatus.initial);
      expect(viewModel.errorMessage, isNull);
    });

    test('handles authorization denial safely and wipes sensitive draft', () async {
      viewModel.updateDisplayName('ValidName');
      viewModel.updateBio('Private Bio');

      repository.nextResult = const SocialProfileResult.failure(
        SocialProfileFailure(
          type: SocialProfileFailureType.authorizationDenied,
          message: 'Adult eligibility confirmation is required to access Social.',
        ),
      );

      final success = await viewModel.saveDraft();

      expect(success, isFalse);
      expect(viewModel.status, SocialProfileStatus.denied);
      expect(viewModel.isDenied, isTrue);
      expect(viewModel.errorMessage, contains('Adult eligibility'));
      // Sensitive content wiped
      expect(viewModel.draft.displayName, '');
      expect(viewModel.draft.bio, isNull);
    });

    test('handles backend dependency and network failure with sanitized error', () async {
      viewModel.updateDisplayName('ValidName');

      repository.nextResult = const SocialProfileResult.failure(
        SocialProfileFailure(
          type: SocialProfileFailureType.dependencyFailure,
          message: 'Social service temporarily unavailable.',
        ),
      );

      final success = await viewModel.saveDraft();

      expect(success, isFalse);
      expect(viewModel.status, SocialProfileStatus.error);
      expect(viewModel.isError, isTrue);
      expect(viewModel.errorMessage, contains('unavailable'));
    });

    test('sessionExpired failure clears draft content and marks denied', () async {
      viewModel.updateDisplayName('SensitiveName');
      viewModel.updateBio('Sensitive Bio');

      repository.nextResult = const SocialProfileResult.failure(
        SocialProfileFailure(
          type: SocialProfileFailureType.sessionExpired,
          message: 'Session expired. Please log in again.',
        ),
      );

      final success = await viewModel.saveDraft();

      expect(success, isFalse);
      expect(viewModel.status, SocialProfileStatus.denied);
      expect(viewModel.draft.displayName, '');
      expect(viewModel.draft.bio, isNull);
    });

    test('discards stale async response after invalidateSession is called', () async {
      viewModel.updateDisplayName('OldUser');
      final completer = Completer<SocialProfileResult>();
      repository.pendingCompleter = completer;

      final saveFuture = viewModel.saveDraft();
      expect(viewModel.isLoading, isTrue);

      viewModel.invalidateSession();
      expect(viewModel.draft.displayName, '');
      expect(viewModel.status, SocialProfileStatus.initial);

      completer.complete(
        const SocialProfileResult.success(
          SocialProfileDraft(displayName: 'OldUser'),
        ),
      );

      final result = await saveFuture;
      expect(result, isFalse);
      expect(viewModel.draft.displayName, '');
      expect(viewModel.status, SocialProfileStatus.initial);
    });

    test('safely handles disposal during pending async save', () async {
      final localVm = SocialProfileViewModel(repository: repository);
      localVm.updateDisplayName('DisposalTest');
      final completer = Completer<SocialProfileResult>();
      repository.pendingCompleter = completer;

      final saveFuture = localVm.saveDraft();
      expect(localVm.isLoading, isTrue);

      localVm.dispose();

      completer.complete(SocialProfileResult.success(localVm.draft));

      final result = await saveFuture;
      expect(result, isFalse);
    });

    test('resetStatus clears error without losing draft input', () {
      viewModel.updateDisplayName('DraftText');
      viewModel.updateBio('DraftBio');

      viewModel.updateDisplayName('A'); // Invalid length
      viewModel.saveDraft();
      expect(viewModel.status, SocialProfileStatus.error);

      viewModel.resetStatus();
      expect(viewModel.status, SocialProfileStatus.initial);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.draft.displayName, 'A');
      expect(viewModel.draft.bio, 'DraftBio');
    });
  });
}
