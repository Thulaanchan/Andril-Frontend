import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:andril_mobile/shared_core/onboarding/domain/onboarding_status_repository.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/onboarding_flow_coordinator.dart';

OnboardingStatus _buildStatus({
  required String nextStep,
  String? selectedModule,
  String? blockingDependency,
  bool identityVerified = true,
  bool accountInitialized = true,
  bool demographicsComplete = true,
  bool currentPoliciesAccepted = true,
  bool starterModuleSelected = true,
  bool privateProfileComplete = false,
  bool onboardingComplete = false,
}) {
  return OnboardingStatus.fromJson({
    'nextStep': nextStep,
    'selectedModule': selectedModule,
    'blockingDependency': blockingDependency,
    'onboardingComplete': onboardingComplete,
    'moduleHomeAuthorized': false,
    'progress': {
      'identityVerified': identityVerified,
      'accountInitialized': accountInitialized,
      'demographicsComplete': demographicsComplete,
      'currentPoliciesAccepted': currentPoliciesAccepted,
      'starterModuleSelected': starterModuleSelected,
      'privateProfileComplete': privateProfileComplete,
    },
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Task 02.11: Onboarding Resume Comprehensive Tests (20 Scenarios)', () {
    // Scenario 1: initialize_account -> Step 8 (Screen 09: Eligibility & Policies)
    test('Scenario 01: nextStep initialize_account maps to Step 8', () {
      final status = _buildStatus(
        nextStep: 'initialize_account',
        accountInitialized: false,
        demographicsComplete: false,
        currentPoliciesAccepted: false,
        starterModuleSelected: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(8));
    });

    // Scenario 2: complete_demographics (accountInitialized: true) -> Step 8
    test('Scenario 02: nextStep complete_demographics with account initialized maps to Step 8', () {
      final status = _buildStatus(
        nextStep: 'complete_demographics',
        accountInitialized: true,
        demographicsComplete: false,
        currentPoliciesAccepted: false,
        starterModuleSelected: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(8));
    });

    // Scenario 3: complete_demographics with demographicsComplete: false -> Step 8
    test('Scenario 03: nextStep complete_demographics pending demographics maps to Step 8', () {
      final status = _buildStatus(
        nextStep: 'complete_demographics',
        accountInitialized: true,
        demographicsComplete: false,
        currentPoliciesAccepted: false,
        starterModuleSelected: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(8));
    });

    // Scenario 4: age_ineligible -> Step 8 (halts on Screen 09 with advisory)
    test('Scenario 04: nextStep age_ineligible maps to Step 8', () {
      final status = _buildStatus(
        nextStep: 'age_ineligible',
        accountInitialized: true,
        demographicsComplete: true,
        currentPoliciesAccepted: false,
        starterModuleSelected: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(8));
    });

    // Scenario 5: review_policies (demographics complete, policies pending) -> Step 8
    test('Scenario 05: nextStep review_policies maps to Step 8', () {
      final status = _buildStatus(
        nextStep: 'review_policies',
        accountInitialized: true,
        demographicsComplete: true,
        currentPoliciesAccepted: false,
        starterModuleSelected: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(8));
    });

    // Scenario 6: select_starter (policies accepted, starter pending) -> Step 9
    test('Scenario 06: nextStep select_starter maps to Step 9', () {
      final status = _buildStatus(
        nextStep: 'select_starter',
        accountInitialized: true,
        demographicsComplete: true,
        currentPoliciesAccepted: true,
        starterModuleSelected: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(9));
    });

    // Scenario 7: select_starter with selectedModule null -> Step 9
    test('Scenario 07: nextStep select_starter with null module maps to Step 9', () {
      final status = _buildStatus(
        nextStep: 'select_starter',
        selectedModule: null,
        accountInitialized: true,
        demographicsComplete: true,
        currentPoliciesAccepted: true,
        starterModuleSelected: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(9));
    });

    // Scenario 8: profile_setup with learning, welcome pending -> Step 10
    test('Scenario 08: profile_setup for Learning (welcome pending) maps to Step 10', () {
      final status = _buildStatus(
        nextStep: 'profile_setup',
        selectedModule: 'learning',
        privateProfileComplete: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(10));
    });

    // Scenario 9: profile_setup with learning, privateProfileComplete -> Step 13
    test('Scenario 09: profile_setup for Learning (profile complete) maps to Step 13', () {
      final status = _buildStatus(
        nextStep: 'profile_setup',
        selectedModule: 'learning',
        privateProfileComplete: true,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(13));
    });

    // Scenario 10: profile_setup with hobbies, welcome pending -> Step 11
    test('Scenario 10: profile_setup for Hobbies (welcome pending) maps to Step 11', () {
      final status = _buildStatus(
        nextStep: 'profile_setup',
        selectedModule: 'hobbies',
        privateProfileComplete: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(11));
    });

    // Scenario 11: profile_setup with hobbies, privateProfileComplete -> Step 14
    test('Scenario 11: profile_setup for Hobbies (profile complete) maps to Step 14', () {
      final status = _buildStatus(
        nextStep: 'profile_setup',
        selectedModule: 'hobbies',
        privateProfileComplete: true,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(14));
    });

    // Scenario 12: profile_setup with social, welcome pending -> Step 12
    test('Scenario 12: profile_setup for Social (welcome pending) maps to Step 12', () {
      final status = _buildStatus(
        nextStep: 'profile_setup',
        selectedModule: 'social',
        privateProfileComplete: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(12));
    });

    // Scenario 13: profile_setup with social, privateProfileComplete -> Step 15
    test('Scenario 13: profile_setup for Social (profile complete) maps to Step 15', () {
      final status = _buildStatus(
        nextStep: 'profile_setup',
        selectedModule: 'social',
        privateProfileComplete: true,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(15));
    });

    // Scenario 14: profile_setup with blockingDependency: social_display_name -> Step 12
    test('Scenario 14: profile_setup with social_display_name blocker maps to Step 12', () {
      final status = _buildStatus(
        nextStep: 'profile_setup',
        selectedModule: 'social',
        blockingDependency: 'social_display_name',
        privateProfileComplete: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(12));
    });

    // Scenario 15: profile_setup with blockingDependency: private_profile_infrastructure -> Step 10
    test('Scenario 15: profile_setup with private_profile_infrastructure blocker maps to Step 10', () {
      final status = _buildStatus(
        nextStep: 'profile_setup',
        selectedModule: 'learning',
        blockingDependency: 'private_profile_infrastructure',
        privateProfileComplete: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(10));
    });

    // Scenario 16: profile_setup with blockingDependency: approved_profile_contract -> Step 11
    test('Scenario 16: profile_setup with approved_profile_contract blocker maps to Step 11', () {
      final status = _buildStatus(
        nextStep: 'profile_setup',
        selectedModule: 'hobbies',
        blockingDependency: 'approved_profile_contract',
        privateProfileComplete: false,
      );
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(11));
    });

    // Scenario 17: Recovery session with initialize_account -> strictly Step 7 (Screen 08)
    test('Scenario 17: Recovery session with initialize_account status strictly routes to Step 7', () {
      final status = _buildStatus(nextStep: 'initialize_account');
      expect(
        OnboardingFlowCoordinator.stepFromOnboardingStatus(
          status,
          isRecoveryOnlySession: true,
        ),
        equals(7),
      );
    });

    // Scenario 18: Recovery session with select_starter -> strictly Step 7 (Screen 08)
    test('Scenario 18: Recovery session with select_starter status strictly routes to Step 7', () {
      final status = _buildStatus(nextStep: 'select_starter');
      expect(
        OnboardingFlowCoordinator.stepFromOnboardingStatus(
          status,
          isRecoveryOnlySession: true,
        ),
        equals(7),
      );
    });

    // Scenario 19: Recovery session with profile_setup -> strictly Step 7 (Screen 08)
    test('Scenario 19: Recovery session with profile_setup status strictly routes to Step 7', () {
      final status = _buildStatus(nextStep: 'profile_setup', selectedModule: 'social');
      expect(
        OnboardingFlowCoordinator.stepFromOnboardingStatus(
          status,
          isRecoveryOnlySession: true,
        ),
        equals(7),
      );
    });

    // Scenario 20: Unknown nextStep falls back safely to Step 8
    test('Scenario 20: Unknown or unexpected nextStep falls back safely to Step 8', () {
      final status = _buildStatus(nextStep: 'unknown_future_step');
      expect(OnboardingFlowCoordinator.stepFromOnboardingStatus(status), equals(8));
    });

    testWidgets('Widget rendering: Coordinator resumes on Screen 10 when initialStatus is select_starter',
        (tester) async {
      final status = _buildStatus(
        nextStep: 'select_starter',
        currentPoliciesAccepted: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            initialStatus: status,
          ),
        ),
      );
      await tester.pump();

      // Immediately lands on Screen 10 (Starter Module Selection)
      expect(find.text('CHOOSE YOUR MODULES'), findsOneWidget);
    });

    testWidgets('Widget rendering: Recovery-only session strictly lands on Screen 08 (Password Reset)',
        (tester) async {
      final status = _buildStatus(
        nextStep: 'select_starter',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlowCoordinator(
            initialStatus: status,
            isRecoveryOnlySession: true,
            recoveryToken: 'test_recovery_token',
          ),
        ),
      );
      await tester.pump();

      // Must be on Screen 08 (Create New Password)
      expect(find.text('Create New Password'), findsOneWidget);
      expect(find.text('CHOOSE YOUR MODULES'), findsNothing);
    });
  });
}
