import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/screens/hobbies_welcome_screen.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/screens/learning_profile_screen.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/screens/learning_welcome_screen.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/screens/social_welcome_screen.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/widgets/module_feature_card.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/widgets/module_welcome_hero_header.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/widgets/module_welcome_wave_divider.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/onboarding_flow_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../authentication/test_doubles/mock_auth_repository.dart';
import '../module_activation/test_doubles/mock_starter_module_repository.dart';
import '../privacy/test_doubles/mock_eligibility_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Screen 11 – Learning Welcome Screen Tests', () {
    testWidgets('renders all finalized visual elements for Learning Welcome',
        (tester) async {
      var started = false;
      var back = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LearningWelcomeScreen(
            onGetStarted: () => started = true,
            onBackToModuleSelection: () => back = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Branding & badges
      expect(find.byType(ModuleWelcomeHeroHeader), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('01 / 03'), findsOneWidget);

      // Headline and tagline
      expect(find.textContaining('Learning Journey'), findsOneWidget);
      expect(find.text('Learn • Share • Grow'), findsOneWidget);

      // Decorative wave divider
      expect(find.byType(ModuleWelcomeWaveDivider), findsOneWidget);

      // Feature highlights
      expect(find.byType(ModuleFeatureCard), findsNWidgets(3));
      expect(find.text('Learn New Skills'), findsOneWidget);
      expect(find.text('Share Your Knowledge'), findsOneWidget);
      expect(find.text('Connect with Learners'), findsOneWidget);

      // Buttons
      final getStartedBtn = find.text('Get Started');
      expect(getStartedBtn, findsOneWidget);
      final backBtn = find.text('Back to Module Selection');
      expect(backBtn, findsOneWidget);
      expect(find.text('Learn more'), findsOneWidget);

      // Privacy notice
      expect(
        find.text('Your Learning identity stays separate and private.'),
        findsOneWidget,
      );

      // Callbacks
      await tester.ensureVisible(getStartedBtn);
      await tester.tap(getStartedBtn);
      expect(started, isTrue);

      await tester.ensureVisible(backBtn);
      await tester.tap(backBtn);
      expect(back, isTrue);
    });

    testWidgets('Learn more shows modal sheet with module information',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LearningWelcomeScreen(
            onGetStarted: () {},
            onBackToModuleSelection: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final learnMoreBtn = find.text('Learn more');
      await tester.ensureVisible(learnMoreBtn);
      await tester.tap(learnMoreBtn);
      await tester.pumpAndSettle();

      expect(find.text('About Learning'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('About Learning'), findsNothing);
    });
  });

  group('Screen 13 – Hobbies Welcome Screen Tests', () {
    testWidgets('renders all finalized visual elements for Hobbies Welcome',
        (tester) async {
      var started = false;
      var back = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HobbiesWelcomeScreen(
            onGetStarted: () => started = true,
            onBackToModuleSelection: () => back = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Branding & badges
      expect(find.byType(ModuleWelcomeHeroHeader), findsOneWidget);
      expect(find.text('Hobbies'), findsOneWidget);
      expect(find.text('01 / 03'), findsOneWidget);

      // Headline and tagline
      expect(find.textContaining('Hobbies'), findsWidgets);
      expect(find.text('Explore • Create • Connect'), findsOneWidget);

      // Wave divider
      expect(find.byType(ModuleWelcomeWaveDivider), findsOneWidget);

      // Feature highlights
      expect(find.text('Find Hobby Friends'), findsOneWidget);

      // Buttons
      final getStartedBtn = find.text('Get Started');
      expect(getStartedBtn, findsOneWidget);
      final backBtn = find.text('Back to Module Selection');
      expect(backBtn, findsOneWidget);

      // Privacy notice
      expect(
        find.text('Your Hobbies identity stays separate and private.'),
        findsOneWidget,
      );

      // Callbacks
      await tester.ensureVisible(getStartedBtn);
      await tester.tap(getStartedBtn);
      expect(started, isTrue);

      await tester.ensureVisible(backBtn);
      await tester.tap(backBtn);
      expect(back, isTrue);
    });
  });

  group('Screen 15 – Social Welcome Screen Tests', () {
    testWidgets(
        'renders Social Welcome and omits progress indicator per design reference',
        (tester) async {
      var started = false;
      var back = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialWelcomeScreen(
            onGetStarted: () => started = true,
            onBackToModuleSelection: () => back = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Badge present, but progress indicator '01 / 03' is intentionally omitted
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('01 / 03'), findsNothing);

      // Headline (no tagline pill for Social)
      expect(find.textContaining('Find your people.'), findsOneWidget);

      // Feature highlights
      expect(find.text('Smart Matching'), findsOneWidget);

      // Safety message & privacy notice
      expect(
        find.text('Social is available for users aged 18+ only.'),
        findsOneWidget,
      );
      expect(
        find.text(
            'Your information is private and not shared with other modules.'),
        findsOneWidget,
      );

      // Eligible user can tap Get Started
      final getStartedBtn = find.text('Get Started');
      await tester.ensureVisible(getStartedBtn);
      await tester.tap(getStartedBtn);
      expect(started, isTrue);

      final backBtn = find.text('Back to Module Selection');
      await tester.ensureVisible(backBtn);
      await tester.tap(backBtn);
      expect(back, isTrue);
    });

    testWidgets(
        'Social restricts Get Started when user is ineligible (under 18)',
        (tester) async {
      var started = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialWelcomeScreen(
              isSocialAuthorizedByServer: false,
              onGetStarted: () => started = true,
              onBackToModuleSelection: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final getStartedBtn = find.text('Get Started');
      await tester.ensureVisible(getStartedBtn);
      await tester.tap(getStartedBtn);
      await tester.pumpAndSettle();

      // Callback blocked
      expect(started, isFalse);
      // SnackBar restriction shown
      expect(
        find.text(
          'Social is restricted to members aged 18 and older. Module eligibility required.',
        ),
        findsOneWidget,
      );
    });
  });

  group('Onboarding Navigation Flow to Module Welcome Screens', () {
    late MockAuthRepository authRepo;
    late MockEligibilityRepository eligRepo;
    late MockStarterModuleRepository moduleRepo;

    setUp(() {
      authRepo = MockAuthRepository();
      eligRepo = MockEligibilityRepository();
      moduleRepo = MockStarterModuleRepository(isSocialAuthorized: true);
    });

    testWidgets(
        'Screen 10 selection transitions to Screen 11 (Learning Welcome) and supports Back navigation',
        (tester) async {
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      String? profileSetupModule;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            initialStep: 9, // Screen 10 – Starter Selection
            authRepository: authRepo,
            eligibilityRepository: eligRepo,
            starterModuleRepository: moduleRepo,
            onNavigateToProfileSetup: (mod) => profileSetupModule = mod,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Path'), findsOneWidget);

      // Tap Continue with default Learning selection
      final continueBtn = find.text('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Arrives at Screen 11 – Learning Welcome
      expect(find.byType(LearningWelcomeScreen), findsOneWidget);
      expect(find.textContaining('Learning Journey'), findsOneWidget);

      // Tap Back to Module Selection returns to Screen 10
      final backBtn = find.text('Back to Module Selection');
      await tester.ensureVisible(backBtn);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Path'), findsOneWidget);

      // Re-advance and tap Get Started
      final reContinueBtn = find.text('Continue');
      await tester.ensureVisible(reContinueBtn);
      await tester.tap(reContinueBtn);
      await tester.pumpAndSettle();

      final getStartedBtn = find.text('Get Started');
      await tester.ensureVisible(getStartedBtn);
      await tester.tap(getStartedBtn);
      await tester.pumpAndSettle();

      expect(profileSetupModule, equals('learning'));
      expect(find.byType(LearningProfileScreen), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets(
        'Screen 10 selection transitions to Screen 13 (Hobbies Welcome)',
        (tester) async {
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      final hobbiesRepo = MockStarterModuleRepository(
        isSocialAuthorized: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            initialStep: 9,
            authRepository: authRepo,
            eligibilityRepository: eligRepo,
            starterModuleRepository: hobbiesRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate carousel to Hobbies (index 1)
      await tester.tap(find.byTooltip('Next Module'));
      await tester.pumpAndSettle();

      // Select Hobbies
      await tester.tap(find.text('Hobbies'));
      await tester.pumpAndSettle();

      final continueBtn = find.text('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.byType(HobbiesWelcomeScreen), findsOneWidget);
      expect(find.text('Explore • Create • Connect'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets(
        'Screen 10 selection transitions to Screen 15 (Social Welcome)',
        (tester) async {
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      final socialRepo = MockStarterModuleRepository(
        isSocialAuthorized: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            initialStep: 9,
            authRepository: authRepo,
            eligibilityRepository: eligRepo,
            starterModuleRepository: socialRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate carousel to Social (index 2)
      await tester.tap(find.byTooltip('Next Module'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next Module'));
      await tester.pumpAndSettle();

      // Select Social
      await tester.tap(find.text('Social'));
      await tester.pumpAndSettle();

      // Accept 18+ modal
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & Select'));
      await tester.pumpAndSettle();

      final continueBtn = find.text('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SocialWelcomeScreen), findsOneWidget);
      expect(find.textContaining('Find your people.'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Responsive Layout Verification for Module Welcome Screens', () {
    const viewports = [
      Size(360.0, 640.0), // Compact standard
      Size(393.0, 852.0), // Modern reference
      Size(412.0, 915.0), // Large phone
      Size(768.0, 1024.0), // Tablet
    ];

    for (final size in viewports) {
      testWidgets(
          'Renders Learning, Hobbies, Social without overflow on ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = Size(size.width * 2.0, size.height * 2.0);
        tester.view.devicePixelRatio = 2.0;

        // Screen 11
        await tester.pumpWidget(
          MaterialApp(
            home: LearningWelcomeScreen(
              onGetStarted: () {},
              onBackToModuleSelection: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Screen 13
        await tester.pumpWidget(
          MaterialApp(
            home: HobbiesWelcomeScreen(
              onGetStarted: () {},
              onBackToModuleSelection: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Screen 15
        await tester.pumpWidget(
          MaterialApp(
            home: SocialWelcomeScreen(
              onGetStarted: () {},
              onBackToModuleSelection: () {},
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

  group('Visual Review Screenshot Captures for Module Welcome Screens', () {
    Future<void> captureWidgetScreenshot({
      required WidgetTester tester,
      required Widget widget,
      required String fileName,
    }) async {
      final repaintKey = GlobalKey();
      tester.view.physicalSize = const Size(412 * 2.0, 892 * 2.0);
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

    testWidgets('captures rendered Screen 11 Learning Welcome Screen',
        (tester) async {
      await captureWidgetScreenshot(
        tester: tester,
        widget: LearningWelcomeScreen(
          onGetStarted: () {},
          onBackToModuleSelection: () {},
        ),
        fileName: 'rendered_screen_11_learning_welcome.png',
      );
    });

    testWidgets('captures rendered Screen 13 Hobbies Welcome Screen',
        (tester) async {
      await captureWidgetScreenshot(
        tester: tester,
        widget: HobbiesWelcomeScreen(
          onGetStarted: () {},
          onBackToModuleSelection: () {},
        ),
        fileName: 'rendered_screen_13_hobbies_welcome.png',
      );
    });

    testWidgets('captures rendered Screen 15 Social Welcome Screen',
        (tester) async {
      await captureWidgetScreenshot(
        tester: tester,
        widget: SocialWelcomeScreen(
          onGetStarted: () {},
          onBackToModuleSelection: () {},
        ),
        fileName: 'rendered_screen_15_social_welcome.png',
      );
    });
  });
}
