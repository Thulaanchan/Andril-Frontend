import '../../domain/entities/eligibility_result.dart';
import '../../domain/entities/gender_type.dart';
import '../../domain/entities/policy_document.dart';
import '../../domain/repositories/eligibility_repository.dart';

/// Default runtime implementation when backend eligibility service is unconfigured.
class UnconfiguredEligibilityRepository implements EligibilityRepository {
  const UnconfiguredEligibilityRepository();

  @override
  Future<EligibilityResult> submitEligibility({
    required DateTime dateOfBirth,
    required GenderType gender,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async =>
      EligibilityResult.serviceUnavailable;

  @override
  Future<bool> checkPolicyAvailability() async => false;

  @override
  Future<List<PolicyDocument>> getPolicyDocuments() async => const [];
}
