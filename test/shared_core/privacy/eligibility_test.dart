import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/eligibility_result.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/gender_type.dart';
import 'package:andril_mobile/shared_core/privacy/screens/eligibility_policies_screen.dart';
import 'package:andril_mobile/shared_core/privacy/viewmodels/eligibility_viewmodel.dart';
import 'test_doubles/mock_eligibility_repository.dart';

void main() {
  group('EligibilityViewModel Unit Tests', () {
    late MockEligibilityRepository repo;
    late EligibilityViewModel vm;

    setUp(() {
      repo = MockEligibilityRepository();
      vm = EligibilityViewModel(repository: repo);
    });

    tearDown(() {
      vm.dispose();
    });

    test('Initial state is unpopulated and cannot submit', () {
      expect(vm.dateOfBirth, isNull);
      expect(vm.gender, isNull);
      expect(vm.termsAccepted, isFalse);
      expect(vm.privacyAccepted, isFalse);
      expect(vm.canSubmit, isFalse);
      expect(vm.isLoading, isFalse);
    });

    test('Rejects future dates for Date of Birth', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      vm.setDateOfBirth(tomorrow);

      expect(vm.errorMessage, contains('cannot be in the future'));
      expect(vm.dateOfBirth, isNull);
    });

    test('Identifies and restricts users under 16 years of age (Rule 02)',
        () async {
      // 14 years old
      final fourteenYearsAgo =
          DateTime.now().subtract(const Duration(days: 14 * 365));
      vm.setDateOfBirth(fourteenYearsAgo);
      vm.setGender(GenderType.other);
      vm.setTermsAccepted(true);
      vm.setPrivacyAccepted(true);

      expect(vm.isUnder16, isTrue);
      expect(vm.canSubmit, isFalse);

      await vm.submitEligibility(onSuccess: (_) {});
      expect(vm.errorMessage, contains('at least 16'));
    });

    test('Distinguishes 16-17 users from 18+ users for Social restriction', () {
      // 17 years old
      final seventeenYearsAgo =
          DateTime.now().subtract(const Duration(days: 17 * 365 + 100));
      vm.setDateOfBirth(seventeenYearsAgo);

      expect(vm.isUnder16, isFalse);
      expect(vm.isUnder18, isTrue);

      // 22 years old
      final twentyTwoYearsAgo =
          DateTime.now().subtract(const Duration(days: 22 * 365));
      vm.setDateOfBirth(twentyTwoYearsAgo);

      expect(vm.isUnder16, isFalse);
      expect(vm.isUnder18, isFalse);
    });

    test('Handles missing policy documents and HTTP 503 gracefully (Rule 04)',
        () async {
      repo.isServiceUnavailable = true;

      final validDob = DateTime(2000, 1, 1);
      vm.setDateOfBirth(validDob);
      vm.setGender(GenderType.female);
      vm.setTermsAccepted(true);
      vm.setPrivacyAccepted(true);

      EligibilityResult? result;
      await vm.submitEligibility(onSuccess: (r) => result = r);

      expect(result, isNull);
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.errorMessage, contains('503'));
    });

    test('Requires both Terms of Service and Privacy Policy agreements',
        () async {
      final validDob = DateTime(2000, 1, 1);
      vm.setDateOfBirth(validDob);
      vm.setGender(GenderType.male);
      vm.setTermsAccepted(true);
      vm.setPrivacyAccepted(false);

      expect(vm.canSubmit, isFalse);

      vm.setPrivacyAccepted(true);
      expect(vm.canSubmit, isTrue);
    });

    test('Successfully confirms eligibility without expecting raw DOB in response (Rule 01)',
        () async {
      final validDob = DateTime(2000, 5, 20);
      vm.setDateOfBirth(validDob);
      vm.setGender(GenderType.male);
      vm.setTermsAccepted(true);
      vm.setPrivacyAccepted(true);

      EligibilityResult? confirmedResult;
      await vm.submitEligibility(onSuccess: (r) => confirmedResult = r);

      expect(confirmedResult, isNotNull);
      expect(confirmedResult!.isEligible, isTrue);
      expect(confirmedResult!.isSocialEligible, isTrue);
      expect(confirmedResult!.nextStep, equals('starter_selection'));
      expect(vm.errorMessage, isNull);
    });
  });

  group('EligibilityPoliciesScreen Widget Tests', () {
    late MockEligibilityRepository repo;

    setUp(() {
      repo = MockEligibilityRepository();
    });

    testWidgets('Renders all finalized visual elements on Screen 09',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EligibilityPoliciesScreen(repository: repo),
        ),
      );
      await tester.pump();

      // Heading and Subtitle
      expect(find.text('Eligibility & Policies'), findsOneWidget);
      expect(find.text('Before You Continue'), findsOneWidget);
      expect(
        find.text('A few important details to keep you safe and welcoming.'),
        findsOneWidget,
      );

      // Social 18+ Callout
      expect(find.text('Social is 18+ only'), findsOneWidget);
      expect(
        find.text('Under 18? You can still explore Learning and Hobbies.'),
        findsOneWidget,
      );

      // Community guidelines card
      expect(find.textContaining('Community Guidelines'), findsOneWidget);

      // Form Labels
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);

      // Checkboxes
      expect(find.textContaining('Terms of Service'), findsOneWidget);
      expect(find.textContaining('Privacy Policy'), findsOneWidget);

      // Action Button
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('Tapping checkboxes updates agreement status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EligibilityPoliciesScreen(repository: repo),
        ),
      );
      await tester.pump();

      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(2));

      // Scroll and tap Terms checkbox
      await tester.ensureVisible(checkboxes.first);
      await tester.tap(checkboxes.first);
      await tester.pump();

      // Scroll and tap Privacy checkbox
      await tester.ensureVisible(checkboxes.last);
      await tester.tap(checkboxes.last);
      await tester.pump();

      expect(tester.widget<Checkbox>(checkboxes.first).value, isTrue);
      expect(tester.widget<Checkbox>(checkboxes.last).value, isTrue);
    });
  });
}
