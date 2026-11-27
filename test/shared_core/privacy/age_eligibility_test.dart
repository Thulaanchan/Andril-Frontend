import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/eligibility_result.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/gender_type.dart';
import 'package:andril_mobile/shared_core/privacy/domain/repositories/eligibility_repository.dart';
import 'package:andril_mobile/shared_core/privacy/viewmodels/eligibility_viewmodel.dart';

class MockAgeEligibilityRepository implements EligibilityRepository {
  bool submitCalled = false;

  @override
  Future<EligibilityResult> submitEligibility({
    required DateTime dateOfBirth,
    required GenderType gender,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    submitCalled = true;
    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }

    if (age < 16) {
      return const EligibilityResult(
        isEligible: false,
        isSocialEligible: false,
        errorMessage: 'ANDRIL requires members to be at least 16 years of age.',
      );
    }

    return EligibilityResult(
      isEligible: true,
      isSocialEligible: age >= 18,
    );
  }

  @override
  Future<bool> checkPolicyAvailability() async => true;
}

void main() {
  group('Task 02.04: Age Eligibility Handling Tests', () {
    late MockAgeEligibilityRepository repo;
    late EligibilityViewModel vm;

    setUp(() {
      repo = MockAgeEligibilityRepository();
      vm = EligibilityViewModel(repository: repo);
    });

    tearDown(() {
      vm.dispose();
    });

    test('User under 16 is flagged isUnder16 and blocked from submitting', () {
      final now = DateTime.now();
      // Age 14
      vm.setDateOfBirth(DateTime(now.year - 14, now.month, now.day));

      expect(vm.calculatedAge, equals(14));
      expect(vm.isUnder16, isTrue);
      expect(vm.isUnder18, isTrue);
      expect(vm.errorMessage, contains('at least 16 years old'));
      expect(vm.canSubmit, isFalse);
    });

    test('Under 16 submission attempt halts locally without backend call', () async {
      final now = DateTime.now();
      vm.setDateOfBirth(DateTime(now.year - 15, now.month, now.day));
      vm.setGender(GenderType.male);
      vm.setTermsAccepted(true);
      vm.setPrivacyAccepted(true);

      bool successCalled = false;
      await vm.submitEligibility(onSuccess: (_) => successCalled = true);

      expect(successCalled, isFalse);
      expect(repo.submitCalled, isFalse);
      expect(vm.errorMessage, contains('at least 16 years of age'));
    });

    test('User aged 16–17 is eligible for modules but flagged isUnder18 (Social restricted)', () {
      final now = DateTime.now();
      // Age 16
      vm.setDateOfBirth(DateTime(now.year - 16, now.month, now.day));

      expect(vm.calculatedAge, equals(16));
      expect(vm.isUnder16, isFalse);
      expect(vm.isUnder18, isTrue);
      expect(vm.errorMessage, isNull);

      vm.setGender(GenderType.female);
      vm.setTermsAccepted(true);
      vm.setPrivacyAccepted(true);
      expect(vm.canSubmit, isTrue);
    });

    test('User aged 18+ is eligible for all modules including Social', () {
      final now = DateTime.now();
      // Age 22
      vm.setDateOfBirth(DateTime(now.year - 22, now.month, now.day));

      expect(vm.calculatedAge, equals(22));
      expect(vm.isUnder16, isFalse);
      expect(vm.isUnder18, isFalse);
      expect(vm.errorMessage, isNull);

      vm.setGender(GenderType.other);
      vm.setTermsAccepted(true);
      vm.setPrivacyAccepted(true);
      expect(vm.canSubmit, isTrue);
    });

    test('Submitting valid 18+ demographics succeeds and returns social eligible result', () async {
      final now = DateTime.now();
      vm.setDateOfBirth(DateTime(now.year - 20, now.month, now.day));
      vm.setGender(GenderType.male);
      vm.setTermsAccepted(true);
      vm.setPrivacyAccepted(true);

      EligibilityResult? result;
      await vm.submitEligibility(onSuccess: (r) => result = r);

      expect(repo.submitCalled, isTrue);
      expect(result, isNotNull);
      expect(result!.isEligible, isTrue);
      expect(result!.isSocialEligible, isTrue);
    });
  });
}
