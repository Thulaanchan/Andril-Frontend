import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/data/repositories/unconfigured_module_profile_repository.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/domain/models/module_profile_draft.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/domain/models/profile_creation_config.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/screens/hobbies_profile_screen.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/screens/learning_profile_screen.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/screens/module_profile_screen.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/screens/social_profile_screen.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/viewmodels/module_profile_viewmodel.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/widgets/profile_about_me_field.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/widgets/profile_gallery_uploader.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/widgets/profile_location_selector.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/widgets/profile_photo_uploader.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/widgets/profile_text_field.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/onboarding_flow_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../authentication/test_doubles/mock_auth_repository.dart';
import '../module_activation/test_doubles/mock_starter_module_repository.dart';
import '../privacy/test_doubles/mock_eligibility_repository.dart';
import 'test_doubles/mock_module_profile_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Screen 12 – Create Your Learning Profile Tests', () {
    testWidgets('renders all finalized visual elements for Learning Profile',
        (tester) async {
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      final mockRepo = MockModuleProfileRepository();
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
        repository: mockRepo,
      );

      var backTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LearningProfileScreen(
            viewModel: vm,
            onBack: () => backTapped = true,
            onContinue: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Branding & badges
      expect(find.text('ANDRIL'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('02 / 03'), findsOneWidget);

      // Heading & Subtitle
      expect(find.text('Create Your Learning Profile'), findsOneWidget);
      expect(
        find.text('Let others get to know your learning side.'),
        findsOneWidget,
      );

      // Profile photo (optional)
      expect(find.byType(ProfilePhotoUploader), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);

      // Display name field
      expect(find.byType(ProfileTextField), findsOneWidget);
      expect(find.text('Display Name *'), findsOneWidget);
      expect(find.text('Enter your Learning display name'), findsOneWidget);
      expect(
        find.text(
          'Unique within Learning; different from your other identities.',
        ),
        findsOneWidget,
      );

      // About Me field & live counter
      expect(find.byType(ProfileAboutMeField), findsOneWidget);
      expect(find.text('About Me (Optional)'), findsOneWidget);
      expect(find.text('0/100'), findsOneWidget);

      // Location selector
      expect(find.byType(ProfileLocationSelector), findsOneWidget);
      expect(find.text('Location (Optional)'), findsOneWidget);
      expect(find.text('Select your city or region'), findsOneWidget);

      // Additional photos gallery
      expect(find.byType(ProfileGalleryUploader), findsOneWidget);
      expect(find.text('My Learning Photos (Optional)'), findsOneWidget);
      expect(
        find.text('Add photos that show your learning journey or projects.'),
        findsOneWidget,
      );

      // Primary Button
      final continueBtn = find.text('Continue to Preferences');
      expect(continueBtn, findsOneWidget);

      // Test Back button
      await tester.tap(find.byTooltip('Back'));
      expect(backTapped, isTrue);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('requires display name validation before submitting',
        (tester) async {
      final mockRepo = MockModuleProfileRepository();
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
        repository: mockRepo,
      );

      var continueTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LearningProfileScreen(
            viewModel: vm,
            onBack: () {},
            onContinue: () => continueTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Submit with empty name
      final continueBtn = find.text('Continue to Preferences');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(continueTapped, isFalse);
      expect(find.text('Display name is required.'), findsOneWidget);
      expect(mockRepo.saveCount, equals(0));

      // Enter valid name
      vm.setDisplayName('Alex Lerner');
      await tester.pumpAndSettle();
      expect(find.text('Display name is required.'), findsNothing);

      // Resubmit
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(continueTapped, isTrue);
      expect(mockRepo.saveCount, equals(1));
      expect(mockRepo.savedDrafts.first.displayName, equals('Alex Lerner'));
      expect(mockRepo.savedDrafts.first.moduleId, equals('learning'));
    });
  });

  group('Screen 14 – Create Your Hobbies Profile Tests', () {
    testWidgets('renders all finalized visual elements for Hobbies Profile',
        (tester) async {
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      final mockRepo = MockModuleProfileRepository();
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.hobbies(),
        repository: mockRepo,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesProfileScreen(
            viewModel: vm,
            onBack: () {},
            onContinue: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hobbies'), findsOneWidget);
      expect(find.text('02 / 03'), findsOneWidget);
      expect(find.text('Create Your Hobbies Profile'), findsOneWidget);
      expect(
        find.text('Let others get to know your creative side.'),
        findsOneWidget,
      );
      expect(find.text('Enter your Hobbies display name'), findsOneWidget);
      expect(
        find.text('Unique within Hobbies; different from your other identities.'),
        findsOneWidget,
      );
      expect(find.text('My Hobby Photos (Optional)'), findsOneWidget);
      expect(
        find.text('Add photos that show your hobbies or creations.'),
        findsOneWidget,
      );
      expect(find.text('Continue to Preferences'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 16 – Create Your Social Profile Tests', () {
    testWidgets('renders all finalized visual elements and enforces photo requirement',
        (tester) async {
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      final mockRepo = MockModuleProfileRepository(shouldVerifyFace: false);
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.social(),
        repository: mockRepo,
        isSocialAuthorizedByServer: true,
      );

      var continueTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialProfileScreen(
            viewModel: vm,
            onBack: () {},
            onContinue: () => continueTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Social'), findsOneWidget);
      expect(find.text('02 / 03'), findsOneWidget);
      expect(find.text('Create Your Social Profile'), findsOneWidget);
      expect(find.text('Let others get to know the real you.'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
      expect(
        find.text(
          'Add a clear photo of yourself. This helps build trust and meaningful connections.',
        ),
        findsOneWidget,
      );
      expect(find.text('Save & Continue'), findsOneWidget);

      // Attempt to submit without photo or display name
      final saveBtn = find.text('Save & Continue');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(continueTapped, isFalse);
      expect(find.text('Display name is required.'), findsOneWidget);

      // Add display name, but no photo
      vm.setDisplayName('Jordan River');
      await tester.pumpAndSettle();

      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(continueTapped, isFalse);
      expect(
        find.text('Profile photo is required for Social.'),
        findsOneWidget,
      );

      // Add clear profile photo — no face verification operation is invoked
      await vm.setProfilePhoto('path/to/clear_photo.jpg');
      await tester.pumpAndSettle();

      // Verify that no face verification was triggered
      expect(mockRepo.faceVerificationCount, equals(0));

      // Resubmit — succeeds without automated face verification
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(continueTapped, isTrue);
      expect(mockRepo.saveCount, equals(1));
      expect(mockRepo.savedDrafts.first.displayName, equals('Jordan River'));
      expect(mockRepo.savedDrafts.first.profilePhotoPath, equals('path/to/clear_photo.jpg'));
      expect(mockRepo.faceVerificationCount, equals(0));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('rejects Social profile submission when user is under 18',
        (tester) async {
      final mockRepo = MockModuleProfileRepository();
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.social(),
        repository: mockRepo,
        isSocialAuthorizedByServer: false, // Ineligible under 18
      );

      var continueTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialProfileScreen(
            viewModel: vm,
            isSocialAuthorizedByServer: false,
            onBack: () {},
            onContinue: () => continueTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      vm.setDisplayName('Minor User');
      await vm.setProfilePhoto('path/to/photo.jpg');

      final saveBtn = find.text('Save & Continue');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(continueTapped, isFalse);
      expect(
        find.textContaining('Social is restricted to members aged 18 and older'),
        findsOneWidget,
      );
      expect(mockRepo.saveCount, equals(0));
    });
  });

  group('ModuleProfileViewModel Unit & Isolation Tests', () {
    test('enforces 100-character presentation limit on About Me', () {
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
      );

      final longBio = 'A' * 150;
      vm.setAboutMe(longBio);

      expect(vm.aboutMe.length, equals(100));
      expect(vm.aboutMeCharCount, equals(100));
    });

    test('prevents adding more than 3 gallery photos', () {
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.hobbies(),
      );

      expect(vm.addAdditionalPhoto('photo1.jpg'), isTrue);
      expect(vm.addAdditionalPhoto('photo2.jpg'), isTrue);
      expect(vm.addAdditionalPhoto('photo3.jpg'), isTrue);
      expect(vm.addAdditionalPhoto('photo4.jpg'), isFalse); // Max 3
      expect(vm.additionalPhotoPaths.length, equals(3));

      vm.removeAdditionalPhoto(1);
      expect(vm.additionalPhotoPaths.length, equals(2));
      expect(vm.additionalPhotoPaths, equals(['photo1.jpg', 'photo3.jpg']));

      vm.replaceAdditionalPhoto(0, 'photo1_new.jpg');
      expect(vm.additionalPhotoPaths.first, equals('photo1_new.jpg'));
    });

    test('prevents duplicate save while submission is in-flight', () async {
      final mockRepo = MockModuleProfileRepository(
        delay: const Duration(milliseconds: 100),
      );
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
        repository: mockRepo,
      );

      vm.setDisplayName('Speedy Learner');

      final future1 = vm.saveProfile();
      final future2 = vm.saveProfile(); // Should be rejected while loading

      final results = await Future.wait([future1, future2]);
      expect(results[0], isTrue);
      expect(results[1], isFalse);
      expect(mockRepo.saveCount, equals(1));
    });

    test('handles repository failure gracefully', () async {
      final mockRepo = MockModuleProfileRepository(shouldSucceed: false);
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
        repository: mockRepo,
      );

      vm.setDisplayName('Failed Learner');
      final result = await vm.saveProfile();

      expect(result, isFalse);
      expect(vm.generalError, contains('Unable to save profile'));
    });

    test('enforces strict cross-module profile state isolation', () {
      final vmLearning = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
      );
      final vmHobbies = ModuleProfileViewModel(
        config: ProfileCreationConfig.hobbies(),
      );

      vmLearning.setDisplayName('Learner Name');
      vmLearning.setAboutMe('Learning bio');
      vmLearning.addAdditionalPhoto('learning_art.png');

      expect(vmHobbies.displayName, isEmpty);
      expect(vmHobbies.aboutMe, isEmpty);
      expect(vmHobbies.additionalPhotoPaths, isEmpty);
    });

    test('reset clears draft on logout or account switching', () {
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
      );

      vm.setDisplayName('User');
      vm.setAboutMe('Bio');
      vm.setLocation('Colombo');
      vm.addAdditionalPhoto('pic.jpg');

      vm.reset();

      expect(vm.displayName, isEmpty);
      expect(vm.aboutMe, isEmpty);
      expect(vm.location, isEmpty);
      expect(vm.additionalPhotoPaths, isEmpty);
      expect(vm.profilePhotoPath, isNull);
    });

    test('default runtime uses UnconfiguredModuleProfileRepository and fails closed', () async {
      const unconfigured = UnconfiguredModuleProfileRepository();
      const draft = ModuleProfileDraft(
        moduleId: 'learning',
        displayName: 'Test',
      );

      final saveResult = await unconfigured.saveProfile(draft);
      final verifyResult = await unconfigured.verifyFace('test.png');
      final profile = await unconfigured.getProfile('learning');

      expect(saveResult, isFalse);
      expect(verifyResult, isFalse);
      expect(profile, isNull);
    });
  });

  group('Onboarding Navigation Flow: Welcome to Profile Creation', () {
    late MockAuthRepository authRepo;
    late MockEligibilityRepository eligRepo;
    late MockStarterModuleRepository moduleRepo;
    late MockModuleProfileRepository profileRepo;

    setUp(() {
      authRepo = MockAuthRepository();
      eligRepo = MockEligibilityRepository();
      moduleRepo = MockStarterModuleRepository(isSocialAuthorized: true);
      profileRepo = MockModuleProfileRepository();
    });

    testWidgets('navigates from Learning Welcome (Screen 11) to Learning Profile (Screen 12) and supports Back',
        (tester) async {
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      String? completedModule;
      var onboardingFinished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            initialStep: 10, // Screen 11 – Learning Welcome
            authRepository: authRepo,
            eligibilityRepository: eligRepo,
            starterModuleRepository: moduleRepo,
            moduleProfileRepository: profileRepo,
            onProfileCreationCompleted: (mod) => completedModule = mod,
            onOnboardingCompleted: (_) => onboardingFinished = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Learning Journey'), findsOneWidget);

      // Tap Get Started on Screen 11
      final getStartedBtn = find.text('Get Started');
      await tester.ensureVisible(getStartedBtn);
      await tester.tap(getStartedBtn);
      await tester.pumpAndSettle();

      // Arrives at Screen 12 – Learning Profile
      expect(find.byType(LearningProfileScreen), findsOneWidget);
      expect(find.text('Create Your Learning Profile'), findsOneWidget);

      // Tap Back button on Screen 12
      final backBtn = find.byTooltip('Back');
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Returns to Screen 11 – Learning Welcome
      expect(find.textContaining('Learning Journey'), findsOneWidget);

      // Re-advance to Screen 12
      final reGetStarted = find.text('Get Started');
      await tester.ensureVisible(reGetStarted);
      await tester.tap(reGetStarted);
      await tester.pumpAndSettle();

      // Enter display name and submit
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Jane Learner');
      await tester.pumpAndSettle();

      final continueBtn = find.text('Continue to Preferences');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(completedModule, equals('learning'));
      expect(onboardingFinished, isTrue);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('ModuleProfileScreen factory creates correct screen for module id',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModuleProfileScreen.fromModuleId(
            moduleId: 'hobbies',
            onBack: () {},
            onContinue: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HobbiesProfileScreen), findsOneWidget);
    });
  });

  group('Responsive Layout Verification for Module Profile Screens', () {
    const viewports = [
      Size(360.0, 640.0), // Compact standard
      Size(393.0, 852.0), // Modern reference
      Size(412.0, 915.0), // Large phone
      Size(768.0, 1024.0), // Tablet
    ];

    for (final size in viewports) {
      testWidgets(
          'Renders Screen 12, 14, 16 without overflow on ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = Size(size.width * 2.0, size.height * 2.0);
        tester.view.devicePixelRatio = 2.0;

        // Screen 12
        await tester.pumpWidget(
          MaterialApp(
            home: LearningProfileScreen(
              onBack: () {},
              onContinue: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Screen 14
        await tester.pumpWidget(
          MaterialApp(
            home: HobbiesProfileScreen(
              onBack: () {},
              onContinue: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Screen 16
        await tester.pumpWidget(
          MaterialApp(
            home: SocialProfileScreen(
              onBack: () {},
              onContinue: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }
  });

  group('Visual Review Screenshot Captures for Module Profile Screens', () {
    Future<void> captureWidgetScreenshot({
      required WidgetTester tester,
      required Widget widget,
      required String fileName,
    }) async {
      final repaintKey = GlobalKey();
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        RepaintBoundary(
          key: repaintKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: widget,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final boundary = repaintKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final outputDirPath = Platform.environment['VISUAL_REVIEW_DIR'] ??
              r'C:\Users\UT011618\.gemini\antigravity\brain\de91d71c-7ce1-49c6-87ac-8cd74422ed98\visual_review';
          final dir = Directory(outputDirPath);
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          File('${dir.path}/$fileName')
              .writeAsBytesSync(byteData.buffer.asUint8List());
        }
      });

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }

    testWidgets('captures rendered Screen 12 Learning Profile Screen',
        (tester) async {
      await captureWidgetScreenshot(
        tester: tester,
        widget: LearningProfileScreen(
          onBack: () {},
          onContinue: () {},
        ),
        fileName: 'rendered_screen_12_learning_profile.png',
      );
    });

    testWidgets('captures rendered Screen 14 Hobbies Profile Screen',
        (tester) async {
      await captureWidgetScreenshot(
        tester: tester,
        widget: HobbiesProfileScreen(
          onBack: () {},
          onContinue: () {},
        ),
        fileName: 'rendered_screen_14_hobbies_profile.png',
      );
    });

    testWidgets('captures rendered Screen 16 Social Profile Screen',
        (tester) async {
      await captureWidgetScreenshot(
        tester: tester,
        widget: SocialProfileScreen(
          onBack: () {},
          onContinue: () {},
        ),
        fileName: 'rendered_screen_16_social_profile.png',
      );
    });
  });
}
