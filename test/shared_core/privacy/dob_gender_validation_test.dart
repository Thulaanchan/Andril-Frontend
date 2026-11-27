import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/eligibility_result.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/gender_type.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/policy_document.dart';
import 'package:andril_mobile/shared_core/privacy/domain/repositories/eligibility_repository.dart';
import 'package:andril_mobile/shared_core/privacy/viewmodels/eligibility_viewmodel.dart';

class FakeEligibilityRepo implements EligibilityRepository {
  DateTime? lastSubmittedDob;
  GenderType? lastSubmittedGender;

  @override
  Future<List<PolicyDocument>> getPolicyDocuments() async => const [];

  @override
  Future<EligibilityResult> submitEligibility({
    required DateTime dateOfBirth,
    required GenderType gender,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    lastSubmittedDob = dateOfBirth;
    lastSubmittedGender = gender;
    return const EligibilityResult(isEligible: true, isSocialEligible: true);
  }

  @override
  Future<bool> checkPolicyAvailability() async => true;
}

void main() {
  group('Task 02.03: DOB and Gender Validation Tests', () {
    late FakeEligibilityRepo repo;
    late EligibilityViewModel vm;

    setUp(() {
      repo = FakeEligibilityRepo();
      vm = EligibilityViewModel(repository: repo);
    });

    tearDown(() {
      vm.dispose();
    });

    test('Formats valid date of birth into strict ISO YYYY-MM-DD string', () {
      vm.setDateOfBirth(DateTime(1998, 5, 14));
      expect(vm.dateOfBirthIso, equals('1998-05-14'));
    });

    test('Pads single-digit months and days with leading zeros', () {
      vm.setDateOfBirth(DateTime(2002, 3, 7));
      expect(vm.dateOfBirthIso, equals('2002-03-07'));
    });

    test('Rejects future date of birth with error message', () {
      final futureDate = DateTime.now().add(const Duration(days: 365));
      vm.setDateOfBirth(futureDate);

      expect(vm.dateOfBirth, isNull);
      expect(vm.errorMessage, contains('cannot be in the future'));
    });

    test('Correctly handles leap year valid date (e.g. 2000-02-29)', () {
      vm.setDateOfBirthFromIso('2000-02-29');
      expect(vm.dateOfBirth, equals(DateTime(2000, 2, 29)));
      expect(vm.dateOfBirthIso, equals('2000-02-29'));
      expect(vm.errorMessage, isNull);
    });

    test('Rejects non-leap year February 29 rollover (e.g. 2001-02-29)', () {
      vm.setDateOfBirthFromIso('2001-02-29');
      expect(vm.dateOfBirth, isNull);
      expect(vm.errorMessage, contains('Invalid calendar date'));
    });

    test('Rejects malformed date strings', () {
      vm.setDateOfBirthFromIso('invalid-date');
      expect(vm.dateOfBirth, isNull);
      expect(vm.errorMessage, contains('Expected YYYY-MM-DD'));

      vm.setDateOfBirthFromIso('2000/01/01');
      expect(vm.dateOfBirth, isNull);
      expect(vm.errorMessage, contains('Expected YYYY-MM-DD'));
    });

    test('GenderType enum matches backend serialized values and labels', () {
      expect(GenderType.male.backendValue, equals('male'));
      expect(GenderType.male.displayLabel, equals('Male'));

      expect(GenderType.female.backendValue, equals('female'));
      expect(GenderType.female.displayLabel, equals('Female'));

      expect(GenderType.other.backendValue, equals('other'));
      expect(GenderType.other.displayLabel, equals('Other'));

      expect(GenderType.preferNotToSay.backendValue, equals('prefer_not_to_say'));
      expect(GenderType.preferNotToSay.displayLabel, equals('Prefer not to say'));
    });

    test('GenderType fromBackendValue correctly parses all valid backend representations', () {
      expect(GenderType.fromBackendValue('male'), equals(GenderType.male));
      expect(GenderType.fromBackendValue('female'), equals(GenderType.female));
      expect(GenderType.fromBackendValue('other'), equals(GenderType.other));
      expect(GenderType.fromBackendValue('prefer_not_to_say'), equals(GenderType.preferNotToSay));
      expect(GenderType.fromBackendValue('unknown'), isNull);
      expect(GenderType.fromBackendValue(null), isNull);
    });

    test('Setting gender updates state and clears previous error', () {
      vm.setGender(GenderType.female);
      expect(vm.gender, equals(GenderType.female));
      expect(vm.errorMessage, isNull);
    });
  });
}
