import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/welcome_screen.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/widgets/brand_logo_header.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/widgets/module_showcase_widget.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/widgets/value_proposition_bar.dart';

void main() {
  group('WelcomeScreen Widget Tests', () {
    testWidgets('renders all visual elements according to finalized design',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify brand header
      expect(find.byType(BrandLogoHeader), findsOneWidget);
      expect(find.text('ANDRIL'), findsOneWidget);

      // Verify hero headlines
      expect(find.text('Welcome to Andril'), findsOneWidget);
      expect(
        find.textContaining('three independent spaces for your'),
        findsOneWidget,
      );

      // Verify three modules showcase
      expect(find.byType(ModuleShowcaseWidget), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('Hobbies'), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);

      // Verify value propositions
      expect(find.byType(ValuePropositionBar), findsOneWidget);
      expect(find.text('Real people'), findsOneWidget);
      expect(find.text('Safe & private'), findsOneWidget);
      expect(find.text('Multiple ways'), findsOneWidget);

      // Verify primary and secondary action buttons
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('triggers onCreateAccount and onLogIn callbacks on tap',
        (tester) async {
      var createAccountTriggered = false;
      var logInTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(
            onCreateAccount: () => createAccountTriggered = true,
            onLogIn: () => logInTriggered = true,
          ),
        ),
      );

      // Tap Create Account
      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      expect(createAccountTriggered, isTrue);

      // Tap Log In
      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      expect(logInTriggered, isTrue);
    });
  });
}
