import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/eligibility_result.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/gender_type.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/policy_document.dart';
import 'package:andril_mobile/shared_core/privacy/domain/repositories/eligibility_repository.dart';
import 'package:andril_mobile/shared_core/privacy/screens/eligibility_policies_screen.dart';

class StubEligibilityRepository implements EligibilityRepository {
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
  Future<bool> checkPolicyAvailability() async => true;
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
  group('Tasks 02.05, 02.06, 02.07: Policy Document Display Tests', () {
    test('PolicyDocument entity generates valid Terms of Service in EN, TA, and SI', () {
      final en = PolicyDocument.termsOfService(languageCode: 'en');
      expect(en.id, equals('terms_of_service'));
      expect(en.title, equals('Terms of Service'));
      expect(en.version, equals('2.1'));
      expect(en.url, equals('https://andril.app/policies/terms'));
      expect(en.content, isNotEmpty);

      final ta = PolicyDocument.termsOfService(languageCode: 'ta');
      expect(ta.title, equals('சேவை விதிமுறைகள்'));
      expect(ta.languageCode, equals('ta'));

      final si = PolicyDocument.termsOfService(languageCode: 'si');
      expect(si.title, equals('සේවා නියමයන්'));
      expect(si.languageCode, equals('si'));
    });

    test('PolicyDocument entity generates valid Privacy Policy in EN, TA, and SI', () {
      final en = PolicyDocument.privacyPolicy(languageCode: 'en');
      expect(en.id, equals('privacy_policy'));
      expect(en.title, equals('Privacy Policy'));
      expect(en.version, equals('2.1'));
      expect(en.url, equals('https://andril.app/policies/privacy'));

      final ta = PolicyDocument.privacyPolicy(languageCode: 'ta');
      expect(ta.title, equals('தனியுரிமைக் கொள்கை'));

      final si = PolicyDocument.privacyPolicy(languageCode: 'si');
      expect(si.title, equals('පෞද්ගලිකත්ව ප්‍රතිපත්තිය'));
    });

    test('PolicyDocument entity generates valid Community Guidelines in EN, TA, and SI', () {
      final en = PolicyDocument.communityGuidelines(languageCode: 'en');
      expect(en.id, equals('community_guidelines'));
      expect(en.title, equals('Community Guidelines'));
      expect(en.version, equals('2.1'));
      expect(en.url, equals('https://andril.app/policies/community-guidelines'));

      final ta = PolicyDocument.communityGuidelines(languageCode: 'ta');
      expect(ta.title, equals('சமூக வழிகாட்டுதல்கள்'));

      final si = PolicyDocument.communityGuidelines(languageCode: 'si');
      expect(si.title, equals('ප්‍රජා මාර්ගෝපදේශ'));
    });

    testWidgets('Tapping Community Guidelines opens modal bottom sheet with version and URL',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EligibilityPoliciesScreen(
            repository: StubEligibilityRepository(),
          ),
        ),
      );

      expect(find.text('Eligibility & Policies'), findsOneWidget);

      _tapRichTextSpan(tester, 'Community Guidelines');
      await tester.pumpAndSettle();

      expect(find.text('Version 2.1 • Effective November 2026'), findsOneWidget);
      expect(find.text('https://andril.app/policies/community-guidelines'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('https://andril.app/policies/community-guidelines'), findsNothing);
    });

    testWidgets('Tapping Terms of Service opens modal viewer without auto-checking checkbox',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EligibilityPoliciesScreen(
            repository: StubEligibilityRepository(),
          ),
        ),
      );

      final initialCheckboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(initialCheckboxes[0].value, isFalse);
      expect(initialCheckboxes[1].value, isFalse);

      _tapRichTextSpan(tester, 'Terms of Service');
      await tester.pumpAndSettle();

      expect(find.text('https://andril.app/policies/terms'), findsOneWidget);
      expect(find.textContaining('Acceptance of Terms'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      final afterCheckboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(afterCheckboxes[0].value, isFalse);
    });

    testWidgets('Tapping Privacy Policy opens modal viewer without auto-checking checkbox',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EligibilityPoliciesScreen(
            repository: StubEligibilityRepository(),
          ),
        ),
      );

      _tapRichTextSpan(tester, 'Privacy Policy');
      await tester.pumpAndSettle();

      expect(find.text('https://andril.app/policies/privacy'), findsOneWidget);
      expect(find.textContaining('Information We Collect'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      final afterCheckboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(afterCheckboxes[1].value, isFalse);
    });
  });
}
