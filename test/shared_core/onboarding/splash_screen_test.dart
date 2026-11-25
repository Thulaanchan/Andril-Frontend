import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/splash_screen.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/viewmodels/splash_viewmodel.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/widgets/animated_dots_indicator.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/widgets/brand_logo_header.dart';

void main() {
  group('SplashViewModel', () {
    test('triggers onComplete when timer completes', () async {
      final viewModel = SplashViewModel(
        splashDuration: const Duration(milliseconds: 50),
      );

      var completed = false;
      viewModel.startSplashTimer(onComplete: () {
        completed = true;
      });

      expect(viewModel.isComplete, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(completed, isTrue);
      expect(viewModel.isComplete, isTrue);
      viewModel.dispose();
    });
  });

  group('SplashScreen Widget Tests', () {
    testWidgets('renders brand emblem, wordmark, tagline and pulsing dots',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
            duration: Duration(seconds: 10),
          ),
        ),
      );

      expect(find.byType(BrandLogoHeader), findsOneWidget);
      expect(find.text('ANDRIL'), findsOneWidget);
      expect(find.text('Every Path Begins Here'), findsOneWidget);
      expect(find.byType(AnimatedDotsIndicator), findsOneWidget);
    });

    testWidgets('triggers onSplashComplete callback after duration',
        (tester) async {
      var callbackFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(milliseconds: 500),
            onSplashComplete: () {
              callbackFired = true;
            },
          ),
        ),
      );

      expect(callbackFired, isFalse);
      await tester.pump(const Duration(milliseconds: 600));
      expect(callbackFired, isTrue);
    });
  });
}
