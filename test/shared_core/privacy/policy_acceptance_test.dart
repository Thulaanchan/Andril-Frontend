import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/eligibility_result.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/gender_type.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/policy_document.dart';
import 'package:andril_mobile/shared_core/privacy/domain/repositories/eligibility_repository.dart';
import 'package:andril_mobile/shared_core/privacy/viewmodels/eligibility_viewmodel.dart';

class PolicyAcceptanceMockRepo implements EligibilityRepository {
  bool return503 = false;
  bool termsAgreedRecorded = false;
  bool privacyAcknowledgedRecorded = false;

  @override
  Future<List<PolicyDocument>> getPolicyDocuments() async => const [];

  @override
  Future<EligibilityResult> submitEligibility({
    required DateTime dateOfBirth,
    required GenderType gender,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    termsAgreedRecorded = termsAccepted;
    privacyAcknowledgedRecorded = privacyAccepted;

    if (return503) {
      return EligibilityResult.serviceUnavailable;
    }

    return const EligibilityResult(
      isEligible: true,
      isSocialEligible: true,
      nextStep: 'starter_selection',
    );
  }

  @override
  Future<bool> checkPolicyAvailability() async => !return503;
}

void main() {
  group('Task 02.08: Policy Acceptance and 503 Fail-Closed Tests', () {
    late PolicyAcceptanceMockRepo repo;
    late EligibilityViewModel vm;

    setUp(() {
      repo = PolicyAcceptanceMockRepo();
      vm = EligibilityViewModel(repository: repo);
    });

    tearDown(() {
      vm.dispose();
    });

    test('Submission is blocked if Terms of Service is not accepted', () async {
      vm.setDateOfBirth(DateTime(2000, 1, 1));
      vm.setGender(GenderType.female);
      vm.setTermsAccepted(false);
      vm.setPrivacyAccepted(true);

      expect(vm.canSubmit, isFalse);

      bool completed = false;
      await vm.submitEligibility(onSuccess: (_) => completed = true);

      expect(completed, isFalse);
      expect(vm.errorMessage, contains('agree to the Terms of Service and Privacy Policy'));
    });

    test('Submission is blocked if Privacy Policy is not accepted', () async {
      vm.setDateOfBirth(DateTime(2000, 1, 1));
      vm.setGender(GenderType.male);
      vm.setTermsAccepted(true);
      vm.setPrivacyAccepted(false);

      expect(vm.canSubmit, isFalse);

      bool completed = false;
      await vm.submitEligibility(onSuccess: (_) => completed = true);

      expect(completed, isFalse);
      expect(vm.errorMessage, contains('agree to the Terms of Service and Privacy Policy'));
    });

    test('Accepting both policies enables submission and records true values', () async {
      vm.setDateOfBirth(DateTime(1995, 6, 15));
      vm.setGender(GenderType.other);
      vm.setTermsAccepted(true);
      vm.setPrivacyAccepted(true);

      expect(vm.canSubmit, isTrue);

      EligibilityResult? result;
      await vm.submitEligibility(onSuccess: (r) => result = r);

      expect(result, isNotNull);
      expect(result!.isEligible, isTrue);
      expect(repo.termsAgreedRecorded, isTrue);
      expect(repo.privacyAcknowledgedRecorded, isTrue);
    });

    test('HTTP 503 service unavailable triggers fail-closed error and pauses progression', () async {
      repo.return503 = true;

      vm.setDateOfBirth(DateTime(1995, 6, 15));
      vm.setGender(GenderType.male);
      vm.setTermsAccepted(true);
      vm.setPrivacyAccepted(true);

      bool completed = false;
      await vm.submitEligibility(onSuccess: (_) => completed = true);

      expect(completed, isFalse);
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.errorMessage, contains('503'));

      // Retrying when service recovers succeeds
      repo.return503 = false;
      await vm.submitEligibility(onSuccess: (_) => completed = true);

      expect(completed, isTrue);
      expect(vm.isServiceUnavailable, isFalse);
    });
  });
}
