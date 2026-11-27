import '../entities/eligibility_result.dart';
import '../entities/gender_type.dart';
import '../entities/policy_document.dart';

/// Domain contract for eligibility verification and policy acknowledgment.
abstract interface class EligibilityRepository {
  /// Submits user demographics and policy agreements to the backend authority.
  ///
  /// Rule 01: Raw DOB and gender are NOT returned in responses.
  /// Rule 02: Under 16 users cannot complete module eligibility.
  /// Rule 04: Missing policy documents causes HTTP 503 service unavailable.
  Future<EligibilityResult> submitEligibility({
    required DateTime dateOfBirth,
    required GenderType gender,
    required bool termsAccepted,
    required bool privacyAccepted,
  });

  /// Checks if required policy documents are published and available.
  Future<bool> checkPolicyAvailability();

  /// Retrieves authoritative policy document metadata from the backend catalog
  /// (`GET /api/v1/account/policies/status`).
  Future<List<PolicyDocument>> getPolicyDocuments();
}
