import '../../../core/network/api_client/andril_api_client.dart';
import '../../../core/security/session/session_controller.dart';

enum StarterModule { learning, hobbies, social }

enum SetupEvidence { incomplete, completeEntryUnavailable, unknown }

class OnboardingProgress {
  const OnboardingProgress._({
    required this.identityVerified,
    required this.accountInitialized,
    required this.demographicsComplete,
    required this.currentPoliciesAccepted,
    required this.starterModuleSelected,
    required this.privateProfileComplete,
  });

  final bool identityVerified;
  final bool accountInitialized;
  final bool demographicsComplete;
  final bool currentPoliciesAccepted;
  final bool starterModuleSelected;
  final bool privateProfileComplete;
}

class OnboardingStatus {
  const OnboardingStatus._(this.nextStep, this.progress, this.selectedModule,
      this.blockingDependency, this.onboardingComplete);

  final String nextStep;
  final OnboardingProgress progress;
  final String? selectedModule;
  final String? blockingDependency;
  final bool onboardingComplete;
  bool get moduleHomeAuthorized => false;

  StarterModule? get starterModule => switch (selectedModule) {
        'learning' => StarterModule.learning,
        'hobbies' => StarterModule.hobbies,
        'social' => StarterModule.social,
        _ => null,
      };

  SetupEvidence get setupEvidence {
    if (!const {
          'initialize_account',
          'complete_demographics',
          'age_ineligible',
          'review_policies',
          'select_starter',
          'profile_setup',
        }.contains(nextStep) ||
        (selectedModule != null && starterModule == null) ||
        !const {
          null,
          'private_profile_infrastructure',
          'private_profile_missing',
          'social_display_name',
          'approved_profile_contract',
        }.contains(blockingDependency)) {
      return SetupEvidence.unknown;
    }
    if (!onboardingComplete) return SetupEvidence.incomplete;
    return starterModule == StarterModule.social &&
            nextStep == 'profile_setup' &&
            blockingDependency == null &&
            progress.identityVerified &&
            progress.accountInitialized &&
            progress.demographicsComplete &&
            progress.currentPoliciesAccepted &&
            progress.starterModuleSelected &&
            progress.privateProfileComplete
        ? SetupEvidence.completeEntryUnavailable
        : SetupEvidence.unknown;
  }

  factory OnboardingStatus.fromJson(Map<String, Object?> json) {
    const invalid = HandoffFailure(HandoffIssue.invalidResponse);
    final next = json['nextStep'];
    final evidence = json['progress'];
    final module = json['selectedModule'];
    final blocker = json['blockingDependency'];
    final complete = json['onboardingComplete'];
    if (next is! String ||
        next.isEmpty ||
        evidence is! Map<String, Object?> ||
        !json.containsKey('selectedModule') ||
        !json.containsKey('blockingDependency') ||
        (module != null && module is! String) ||
        (blocker != null && blocker is! String) ||
        complete is! bool ||
        json['moduleHomeAuthorized'] != false ||
        evidence['identityVerified'] != true) {
      throw invalid;
    }
    bool flag(String key) {
      final value = evidence[key];
      if (value is! bool) throw invalid;
      return value;
    }

    return OnboardingStatus._(
        next,
        OnboardingProgress._(
          identityVerified: flag('identityVerified'),
          accountInitialized: flag('accountInitialized'),
          demographicsComplete: flag('demographicsComplete'),
          currentPoliciesAccepted: flag('currentPoliciesAccepted'),
          starterModuleSelected: flag('starterModuleSelected'),
          privateProfileComplete: flag('privateProfileComplete'),
        ),
        module as String?,
        blocker as String?,
        complete);
  }
}

class OnboardingStatusRepository {
  const OnboardingStatusRepository(this._api);
  final AndrilApiClient _api;

  Future<OnboardingStatus> read(BackendSession session) async =>
      OnboardingStatus.fromJson(
          await _api.request(AccountEndpoint.onboarding, session));
}
