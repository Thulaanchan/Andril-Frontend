import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/privacy/data/repositories/unconfigured_eligibility_repository.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/eligibility_result.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/gender_type.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/policy_document.dart';
import 'package:andril_mobile/shared_core/privacy/domain/repositories/eligibility_repository.dart';
import 'package:andril_mobile/shared_core/privacy/screens/eligibility_policies_screen.dart';
import 'fixtures/synthetic_policy_fixtures.dart';

class StubEligibilityRepository implements EligibilityRepository {
  StubEligibilityRepository({
    this.policies = const [],
    this.failClosed = false,
  });

  final List<PolicyDocument> policies;
  final bool failClosed;

  @override
  Future<EligibilityResult> submitEligibility({
    required DateTime dateOfBirth,
    required GenderType gender,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    return const EligibilityResult(isEligible: true, isSocialEligible: true);
  }

  @override
  Future<bool> checkPolicyAvailability() async => !failClosed;

  @override
  Future<List<PolicyDocument>> getPolicyDocuments() async {
    if (failClosed) return const [];
    return policies;
  }
}

void _tapRichTextSpan(WidgetTester tester, String targetText) {
  final richTexts = tester.widgetList<RichText>(
    find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains(targetText),
    ),
  );

  for (final richText in richTexts) {
    bool found = false;
    void searchSpan(InlineSpan span) {
      if (found) return;
      if (span is TextSpan) {
        if (span.text == targetText && span.recognizer is TapGestureRecognizer) {
          (span.recognizer as TapGestureRecognizer).onTap?.call();
          found = true;
          return;
        }
        span.children?.forEach(searchSpan);
      }
    }

    searchSpan(richText.text);
    if (found) return;
  }
}

void main() {
  group('R01.02: Authoritative Policy Document Display & Security Tests', () {
    test('PolicyDocument entity enforces strict HTTPS URL validation', () {
      const validDoc = PolicyDocument(
        id: 'terms_of_service',
        title: 'Terms of Service',
        version: '1.0.0',
        languageCode: 'en',
        url: 'https://andril.app/policies/terms',
      );
      expect(validDoc.hasValidHttpsUrl, isTrue);

      const insecureDoc = PolicyDocument(
        id: 'terms_of_service',
        title: 'Terms of Service',
        version: '1.0.0',
        languageCode: 'en',
        url: 'http://andril.app/policies/terms',
      );
      expect(insecureDoc.hasValidHttpsUrl, isFalse);

      const emptyDoc = PolicyDocument(
        id: 'terms_of_service',
        title: 'Terms of Service',
        version: '1.0.0',
        languageCode: 'en',
        url: '',
      );
      expect(emptyDoc.hasValidHttpsUrl, isFalse);
    });

    test('SyntheticPolicyFixtures are strictly marked isSynthetic=true for test isolation', () {
      final fixtures = SyntheticPolicyFixtures.defaultFixtures();
      expect(fixtures.length, equals(3));
      for (final doc in fixtures) {
        expect(doc.isSynthetic, isTrue);
        expect(doc.version, equals('1.0.0'));
        expect(doc.hasValidHttpsUrl, isTrue);
      }
    });

    test('UnconfiguredEligibilityRepository returns empty documents and fails closed', () async {
      const unconfigured = UnconfiguredEligibilityRepository();
      final docs = await unconfigured.getPolicyDocuments();
      expect(docs, isEmpty);
      final available = await unconfigured.checkPolicyAvailability();
      expect(available, isFalse);
    });

    testWidgets('Configured authoritative documents display verified metadata in modal sheet',
        (tester) async {
      final repo = StubEligibilityRepository(
        policies: SyntheticPolicyFixtures.defaultFixtures(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EligibilityPoliciesScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Eligibility & Policies'), findsOneWidget);

      // Tap Community Guidelines
      _tapRichTextSpan(tester, 'Community Guidelines');
      await tester.pumpAndSettle();

      // Verify authoritative metadata
      expect(find.text('Community Guidelines'), findsWidgets);
      expect(find.text('Version 1.0.0'), findsOneWidget);
      expect(find.text('TEST FIXTURE'), findsOneWidget);
      expect(find.text('https://andril.app/policies/community-guidelines'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('https://andril.app/policies/community-guidelines'), findsNothing);
    });

    testWidgets('Tapping policy document does NOT auto-check acceptance checkbox',
        (tester) async {
      final repo = StubEligibilityRepository(
        policies: SyntheticPolicyFixtures.defaultFixtures(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EligibilityPoliciesScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      final initialCheckboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(initialCheckboxes[0].value, isFalse);
      expect(initialCheckboxes[1].value, isFalse);

      // Open Terms of Service
      _tapRichTextSpan(tester, 'Terms of Service');
      await tester.pumpAndSettle();

      expect(find.text('https://andril.app/policies/terms'), findsOneWidget);
      expect(find.textContaining('Viewing this document does not constitute agreement'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Checkboxes must still be unchecked
      final afterCheckboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(afterCheckboxes[0].value, isFalse);
      expect(afterCheckboxes[1].value, isFalse);
    });

    testWidgets('Unconfigured or missing policy documents trigger HTTP 503 fail-closed sheet with Retry',
        (tester) async {
      // Unconfigured repository (empty documents)
      const repo = UnconfiguredEligibilityRepository();

      await tester.pumpWidget(
        const MaterialApp(
          home: EligibilityPoliciesScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Terms of Service when documents unavailable
      _tapRichTextSpan(tester, 'Terms of Service');
      await tester.pumpAndSettle();

      // Must display 503 unavailable sheet
      expect(find.text('Policies Temporarily Unavailable'), findsOneWidget);
      expect(find.textContaining('HTTP 503'), findsAtLeastNWidgets(1));
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Policies Temporarily Unavailable'), findsNothing);
    });

    testWidgets('Policy viewer presents English legal document with Tamil and Sinhala UI advisory',
        (tester) async {
      final repo = StubEligibilityRepository(
        policies: SyntheticPolicyFixtures.defaultFixtures(),
      );

      // Render with Tamil locale
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ta'),
            Locale('si'),
          ],
          locale: const Locale('ta'),
          home: EligibilityPoliciesScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('தகுதி மற்றும் கொள்கைகள்'), findsOneWidget);

      _tapRichTextSpan(tester, 'சமூக வழிகாட்டுதல்கள்');
      await tester.pumpAndSettle();

      // Legal document metadata is shown, with Tamil advisory
      expect(find.text('Version 1.0.0'), findsOneWidget);
      expect(find.textContaining('அதிகாரப்பூர்வ கொள்கை ஆவணங்கள்'), findsOneWidget);
      expect(find.text('மூடு'), findsOneWidget);

      await tester.tap(find.text('மூடு'));
      await tester.pumpAndSettle();
    });
  });
}
