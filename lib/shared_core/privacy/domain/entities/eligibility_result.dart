/// Result of eligibility and policy verification.
class EligibilityResult {
  const EligibilityResult({
    required this.isEligible,
    required this.isSocialEligible,
    this.nextStep = 'starter_selection',
    this.isServiceUnavailable = false,
    this.errorMessage,
  });

  /// Whether the user meets the baseline age (16+) for module participation (Rule 02).
  final bool isEligible;

  /// Whether the user meets the 18+ requirement for the Social module.
  final bool isSocialEligible;

  /// The next onboarding step returned by the backend authority.
  final String nextStep;

  /// True when policy documents cannot be loaded (HTTP 503 per Rule 04).
  final bool isServiceUnavailable;

  final String? errorMessage;

  static const serviceUnavailable = EligibilityResult(
    isEligible: false,
    isSocialEligible: false,
    isServiceUnavailable: true,
    errorMessage:
        'Policy and eligibility services are currently unavailable (HTTP 503). Please retry.',
  );
}
