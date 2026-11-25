import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:andril_mobile/app/andril_app.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/onboarding_flow_coordinator.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/splash_screen.dart';

import '../authentication/foundation_fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AndrilApp Default Integration Tests', () {
    testWidgets('default AndrilApp launches into OnboardingFlowCoordinator',
        (tester) async {
      final source = FakeSessionSource();
      final controller = SessionController(source);
      await controller.start();
      await tester.pumpWidget(AndrilApp(initialize: () async => controller));
      await tester.pump();

      // Verify the onboarding flow coordinator is present as the root home
      expect(find.byType(OnboardingFlowCoordinator), findsOneWidget);

      // Verify initial landing on SplashScreen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Every Path Begins Here'), findsOneWidget);
      expect(find.text('ANDRIL'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await source.signals.close();
    });
  });
}
