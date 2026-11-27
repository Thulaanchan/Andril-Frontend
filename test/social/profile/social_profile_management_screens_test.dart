import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/profile/screens/social_edit_profile_screen.dart';
import 'package:andril_mobile/features/social/profile/screens/social_my_profile_screen.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_draft.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_management_repository.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_management_viewmodel.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_repository.dart';
import 'package:andril_mobile/features/social/profile/widgets/social_profile_photo_section.dart';

class MockSocialProfileManagementRepository implements ISocialProfileManagementRepository {
  SocialProfileResult getResult = const SocialProfileResult.success(SocialProfileDraft(
    displayName: 'Elena Rostova',
    bio: 'Photographer and weekend explorer.',
    visibility: 'private',
  ));

  SocialProfileResult updateResult = const SocialProfileResult.success(SocialProfileDraft(
    displayName: 'Elena Updated',
    bio: 'Updated bio information.',
    visibility: 'private',
  ));

  @override
  Future<SocialProfileResult> getProfile() async => getResult;

  @override
  Future<SocialProfileResult> updateProfile(SocialProfileDraft draft) async => updateResult;
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  @override
  SessionPhase get phase => SessionPhase.signedIn;

  @override
  String? get subject => 'test_user_01';

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) => () {};

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

  Widget buildTestHost(Widget child, {Size size = const Size(400, 800)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('SocialMyProfileScreen (S20)', () {
    testWidgets('renders profile details and triggers edit, quiz, and settings callbacks', (tester) async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      bool editTriggered = false;
      bool quizTriggered = false;
      bool settingsTriggered = false;

      await tester.pumpWidget(buildTestHost(SocialMyProfileScreen(
        viewModel: vm,
        onEditProfile: () => editTriggered = true,
        onTakePersonalityQuiz: () => quizTriggered = true,
        onSettings: () => settingsTriggered = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Elena Rostova'), findsOneWidget);
      expect(find.text('Photographer and weekend explorer.'), findsOneWidget);
      expect(find.text('Private Profile'), findsOneWidget);
      expect(find.text('Personality Quiz'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit_profile_button')));
      expect(editTriggered, isTrue);

      await tester.tap(find.text('Personality Quiz'));
      expect(quizTriggered, isTrue);

      await tester.tap(find.byTooltip('Settings'));
      expect(settingsTriggered, isTrue);
    });

    testWidgets('renders default Social Member and empty bio when profile has no name', (tester) async {
      mockRepo.getResult = const SocialProfileResult.success(SocialProfileDraft(
        displayName: '',
        bio: null,
        visibility: 'private',
      ));
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await tester.pumpWidget(buildTestHost(SocialMyProfileScreen(
        viewModel: vm,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Social Member'), findsOneWidget);
      expect(find.text('No bio added yet. Tell other members about yourself!'), findsOneWidget);
    });

    testWidgets('displays access denied when user is not opted-in', (tester) async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );

      await tester.pumpWidget(buildTestHost(SocialMyProfileScreen(
        viewModel: vm,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('Adult eligibility verification and Social opt-in are required.'), findsOneWidget);
    });

    testWidgets('displays error state and retry button on repository error', (tester) async {
      mockRepo.getResult = const SocialProfileResult.failure(SocialProfileFailure(
        type: SocialProfileFailureType.dependencyFailure,
        message: 'Server error',
      ));
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await tester.pumpWidget(buildTestHost(SocialMyProfileScreen(
        viewModel: vm,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Failed to Load Profile'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      mockRepo.getResult = const SocialProfileResult.success(SocialProfileDraft(
        displayName: 'Recovered User',
        visibility: 'private',
      ));

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered User'), findsOneWidget);
    });
  });

  group('SocialEditProfileScreen (S32)', () {
    testWidgets('allows editing fields, enables save button, and handles save', (tester) async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      await vm.loadProfile();

      bool saved = false;
      await tester.pumpWidget(buildTestHost(SocialEditProfileScreen(
        viewModel: vm,
        onSaved: () => saved = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byKey(const Key('display_name_field')), findsOneWidget);
      expect(find.byKey(const Key('bio_field')), findsOneWidget);

      // Save button is initially disabled (no unsaved changes)
      final saveBtn = find.byKey(const Key('save_profile_button'));
      expect(tester.widget<FilledButton>(saveBtn).onPressed, isNull);

      // Enter new name
      await tester.enterText(find.byKey(const Key('display_name_field')), 'Elena Updated');
      await tester.pumpAndSettle();

      // Save button now enabled
      expect(tester.widget<FilledButton>(saveBtn).onPressed, isNotNull);

      // Tap save
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(saved, isTrue);
    });

    testWidgets('shows discard dialog on cancel with unsaved changes', (tester) async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      await vm.loadProfile();

      bool cancelled = false;
      await tester.pumpWidget(buildTestHost(SocialEditProfileScreen(
        viewModel: vm,
        onCancel: () => cancelled = true,
      )));
      await tester.pumpAndSettle();

      // Modify field to trigger unsaved changes
      await tester.enterText(find.byKey(const Key('display_name_field')), 'New Draft Name');
      await tester.pumpAndSettle();

      // Tap close button in app bar
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();

      // Alert dialog shown
      expect(find.text('Discard Changes?'), findsOneWidget);

      // Tap Discard
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(cancelled, isTrue);
      expect(vm.hasUnsavedChanges, isFalse);
    });

    testWidgets('displays error banner and preserves user input on save failure', (tester) async {
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

      await tester.pumpWidget(buildTestHost(SocialEditProfileScreen(
        viewModel: vm,
      )));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('display_name_field')), 'TakenName');
      await tester.enterText(find.byKey(const Key('bio_field')), 'My preserved bio');
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('save_profile_button'));
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('The display name is already taken.'), findsOneWidget);
      expect(find.text('TakenName'), findsOneWidget);
      expect(find.text('My preserved bio'), findsOneWidget);
    });
  });

  group('SocialProfilePhotoSection', () {
    testWidgets('renders add/change and remove buttons correctly', (tester) async {
      bool selected = false;
      bool removed = false;

      // Without photo
      await tester.pumpWidget(buildTestHost(Scaffold(
        body: SocialProfilePhotoSection(
          onSelectPhoto: () => selected = true,
          onRemovePhoto: () => removed = true,
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.byKey(const Key('remove_photo_button')), findsNothing);

      await tester.tap(find.byKey(const Key('upload_photo_button')));
      expect(selected, isTrue);

      // With photo
      selected = false;
      await tester.pumpWidget(buildTestHost(Scaffold(
        body: SocialProfilePhotoSection(
          photoPath: '/local/path/photo.jpg',
          onSelectPhoto: () => selected = true,
          onRemovePhoto: () => removed = true,
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Change Photo'), findsOneWidget);
      expect(find.byKey(const Key('remove_photo_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('remove_photo_button')));
      expect(removed, isTrue);
    });

    testWidgets('renders loading spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(buildTestHost(const Scaffold(
        body: SocialProfilePhotoSection(
          isLoading: true,
        ),
      )));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Responsive Viewport Tests', () {
    testWidgets('renders across 320dp, 400dp, 800dp viewports without overflow', (tester) async {
      final vm = SocialProfileManagementViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      await vm.loadProfile();

      for (final size in [
        const Size(320, 640),
        const Size(400, 800),
        const Size(800, 1200),
      ]) {
        // My Profile
        await tester.pumpWidget(buildTestHost(SocialMyProfileScreen(viewModel: vm), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Edit Profile
        await tester.pumpWidget(buildTestHost(SocialEditProfileScreen(viewModel: vm), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
