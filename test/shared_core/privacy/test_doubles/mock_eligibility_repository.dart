import 'package:andril_mobile/shared_core/privacy/domain/entities/eligibility_result.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/gender_type.dart';
import 'package:andril_mobile/shared_core/privacy/domain/entities/policy_document.dart';
import 'package:andril_mobile/shared_core/privacy/domain/repositories/eligibility_repository.dart';

/// Test double for [EligibilityRepository] enforcing Rules 01, 02, and 04.
class MockEligibilityRepository implements EligibilityRepository {
  MockEligibilityRepository({
    this.isServiceUnavailable = false,
    List<PolicyDocument>? initialPolicies,
  }) : policyDocuments = initialPolicies ?? [];

  bool isServiceUnavailable;
  EligibilityResult? forcedResult;
  bool lastTermsAccepted = false;
  bool lastPrivacyAccepted = false;
  List<PolicyDocument> policyDocuments;

  @override
  Future<List<PolicyDocument>> getPolicyDocuments() async {
    if (isServiceUnavailable) return const [];
    return policyDocuments;
  }

  @override
  Future<EligibilityResult> submitEligibility({
    required DateTime dateOfBirth,
    required GenderType gender,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    lastTermsAccepted = termsAccepted;
    lastPrivacyAccepted = privacyAccepted;

    if (forcedResult != null) return forcedResult!;

    // Rule 04: Missing policy documents causes HTTP 503
    if (isServiceUnavailable) {
      return EligibilityResult.serviceUnavailable;
    }

    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }

    // Rule 02: Users below 16 cannot complete module eligibility
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
      nextStep: 'starter_selection',
    );
  }

  @override
  Future<bool> checkPolicyAvailability() async => !isServiceUnavailable;
}
