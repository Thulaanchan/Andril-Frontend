import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:andril_mobile/shared_core/language_selection/domain/repositories/language_preference_repository.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/onboarding_flow_coordinator.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/welcome_screen.dart';

class MockFailingLanguageRepository implements LanguagePreferenceRepository {
  @override
  Future<String?> getSavedLanguage() async {
    throw Exception('Simulated disk I/O error');
  }

  @override
  Future<void> saveLanguage(String languageCode) async {
    throw Exception('Simulated disk write failure');
  }
}

class FakePreconfiguredLanguageRepository implements LanguagePreferenceRepository {
  FakePreconfiguredLanguageRepository(this.code);
  String? code;

  @override
  Future<String?> getSavedLanguage() async => code;

  @override
  Future<void> saveLanguage(String languageCode) async {
    code = languageCode;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingFlowCoordinator - Startup Routing', () {
    testWidgets(
        'First-time unauthenticated user routes Splash -> Choose Language -> Welcome',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingFlowCoordinator(
            splashDuration: Duration(milliseconds: 100),
          ),
        ),
      );

      // Initially on Splash
      expect(find.text('Every Path Begins Here'), findsOneWidget);
      expect(find.text('Choose Your Language'), findsNothing);

      // Splash finishes
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Navigates to Choose Language
      expect(find.text('Choose Your Language'), findsNWidgets(2));
      expect(find.text('Welcome to Andril'), findsNothing);

      // Continues to Welcome
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Andril'), findsOneWidget);
    });

    testWidgets(
        'Returning unauthenticated user with valid saved language routes Splash -> Welcome directly',
        (tester) async {
      final repo = FakePreconfiguredLanguageRepository('ta');

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            splashDuration: const Duration(milliseconds: 100),
            languageRepository: repo,
          ),
        ),
      );

      expect(find.text('Every Path Begins Here'), findsOneWidget);

      // Let repository check finish and splash timer elapse
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Should bypass Choose Language and arrive directly at Welcome
      expect(find.text('Choose Your Language'), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('அன்றிலுக்கு நல்வரவு'), findsOneWidget);
    });

    testWidgets(
        'Invalid or unsupported saved language gracefully falls back to Choose Language',
        (tester) async {
      final repo = FakePreconfiguredLanguageRepository('invalid_code_xyz');

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            splashDuration: const Duration(milliseconds: 100),
            languageRepository: repo,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Falls back to language selection
      expect(find.text('Choose Your Language'), findsNWidgets(2));
      expect(find.text('Welcome to Andril'), findsNothing);
    });

    testWidgets(
        'Storage failure on retrieval gracefully falls back to Choose Language without crash',
        (tester) async {
      final repo = MockFailingLanguageRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            splashDuration: const Duration(milliseconds: 100),
            languageRepository: repo,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Graceful fallback to Choose Language
      expect(find.text('Choose Your Language'), findsNWidgets(2));
    });

    testWidgets('Prevents duplicate navigation callbacks and handles disposal cleanly',
        (tester) async {
      var registerCount = 0;
      var loginCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            splashDuration: const Duration(milliseconds: 100),
            initialStep: 2, // Start directly at Welcome screen
            onRegister: () => registerCount++,
            onLogin: () => loginCount++,
          ),
        ),
      );

      // Verify callbacks trigger once per tap
      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      expect(registerCount, equals(1));

      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      expect(loginCount, equals(1));

      // Dispose widget cleanly
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });

  group('Responsive Layout Verification', () {
    const testViewports = [
      Size(360, 640), // Compact Phone
      Size(393, 852), // Modern Standard Phone
      Size(412, 915), // Large Aspect Phone (Pixel 7 Pro)
      Size(768, 1024), // Tablet
    ];

    for (final size in testViewports) {
      testWidgets('Renders onboarding screens without overflow on ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: OnboardingFlowCoordinator(
              initialStep: 2, // WelcomeScreen contains scrollable and complex layouts
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Welcome to Andril'), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }
  });
}
