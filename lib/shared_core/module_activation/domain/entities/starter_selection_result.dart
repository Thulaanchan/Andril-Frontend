/// Result of starter module selection.
///
/// Complies with Mandatory Rule 05: Starter module selection is NOT lifecycle activation.
/// Does not grant unrestricted access or mark full onboarding complete.
class StarterSelectionResult {
  const StarterSelectionResult({
    required this.selectedModuleId,
    required this.isSuccess,
    this.nextStep = 'profile_setup',
    this.isSocialAgeRestricted = false,
    this.errorMessage,
  });

  final String selectedModuleId;
  final bool isSuccess;

  /// The next onboarding step returned by the backend authority (e.g. 'profile_setup').
  final String nextStep;

  final bool isSocialAgeRestricted;
  final String? errorMessage;

  static const serviceUnavailable = StarterSelectionResult(
    selectedModuleId: '',
    isSuccess: false,
    errorMessage:
        'Starter module service is unconfigured. Live backend integration is required.',
  );
}
