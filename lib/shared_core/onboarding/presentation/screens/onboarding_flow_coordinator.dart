import 'package:flutter/material.dart';
import '../../../authentication/data/repositories/unconfigured_auth_repository.dart';
import '../../../authentication/domain/entities/auth_user.dart';
import '../../../authentication/domain/repositories/onboarding_auth_repository.dart';
import '../../../authentication/login/screens/login_screen.dart';
import '../../../authentication/password_recovery/screens/password_recovery_screen.dart';
import '../../../authentication/password_recovery/screens/password_reset_screen.dart';
import '../../../authentication/registration/screens/registration_screen.dart';
import '../../../authentication/verification/screens/account_verification_screen.dart';
import '../../../language_selection/data/repositories/shared_prefs_language_preference_repository.dart';
import '../../../language_selection/domain/models/app_language.dart';
import '../../../language_selection/domain/repositories/language_preference_repository.dart';
import '../../../language_selection/screens/choose_language_screen.dart';
import '../../../module_activation/data/repositories/unconfigured_starter_module_repository.dart';
import '../../../module_activation/domain/entities/starter_selection_result.dart';
import '../../../module_activation/domain/repositories/starter_module_repository.dart';
import '../../../module_activation/presentation/screens/starter_module_selection_screen.dart';
import '../../../privacy/data/repositories/unconfigured_eligibility_repository.dart';
import '../../../privacy/domain/entities/eligibility_result.dart';
import '../../../privacy/domain/repositories/eligibility_repository.dart';
import '../../../privacy/screens/eligibility_policies_screen.dart';
import '../../../module_profile_setup/data/repositories/unconfigured_module_profile_repository.dart';
import '../../../module_profile_setup/domain/models/profile_creation_config.dart';
import '../../../module_profile_setup/domain/repositories/module_profile_repository.dart';
import '../../../module_profile_setup/presentation/screens/hobbies_profile_screen.dart';
import '../../../module_profile_setup/presentation/screens/hobbies_welcome_screen.dart';
import '../../../module_profile_setup/presentation/screens/learning_profile_screen.dart';
import '../../../module_profile_setup/presentation/screens/learning_welcome_screen.dart';
import '../../../module_profile_setup/presentation/screens/social_profile_screen.dart';
import '../../../module_profile_setup/presentation/screens/social_welcome_screen.dart';
import '../../../module_profile_setup/presentation/viewmodels/module_profile_viewmodel.dart';
import '../../domain/onboarding_status_repository.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

/// Central navigation coordinator for all ten finalized onboarding screens (Screens 01 through 10),
/// post-selection module welcome screens (Screens 11, 13, and 15),
/// and module profile creation screens (Screens 12, 14, and 16).
///
/// Steps:
/// - 0: Screen 01 – Splash Screen
/// - 1: Screen 02 – Choose Language Screen
/// - 2: Screen 03 – Welcome Screen
/// - 3: Screen 04 – Email Registration Screen
/// - 4: Screen 05 – Account Verification Screen
/// - 5: Screen 06 – Login and Google Sign-In Screen
/// - 6: Screen 07 – Password Recovery Request Screen
/// - 7: Screen 08 – Password Reset Screen (Create New Password)
/// - 8: Screen 09 – Eligibility & Policies Screen
/// - 9: Screen 10 – Starter Module Selection Screen (Choose Your Modules)
/// - 10: Screen 11 – Learning Welcome Screen
/// - 11: Screen 13 – Hobbies Welcome Screen
/// - 12: Screen 15 – Social Welcome Screen
/// - 13: Screen 12 – Create Your Learning Profile Screen
/// - 14: Screen 14 – Create Your Hobbies Profile Screen
/// - 15: Screen 16 – Create Your Social Profile Screen
///
/// Flow Intelligence:
/// - First-time unauthenticated: Splash -> Language -> Welcome.
/// - Returning unauthenticated (saved language): Splash -> Welcome.
/// - Welcome -> "Create Account" (3) or "Log In" (5).
/// - Registration -> Account Verification (4) -> Eligibility & Policies (8).
/// - Login -> Eligibility & Policies (8), or Account Verification (4) if unverified.
/// - Password Recovery Request (6) -> Password Reset (7) -> Login (5).
/// - Eligibility & Policies (8) -> Starter Module Selection (9).
/// - Starter Module Selection (9) -> Welcome screen (10, 11, 12).
/// - Module Welcome -> Profile Creation (13, 14, 15).
/// - Profile Creation -> Handoff via [onProfileCreationCompleted].
///
/// Preserves production security:
/// - Default application uses unconfigured repositories that report service unavailable.
/// - Test doubles can be injected explicitly for unit and integration tests.
class OnboardingFlowCoordinator extends StatefulWidget {
  const OnboardingFlowCoordinator({
    super.key,
    this.initialStep,
    this.onRegister,
    this.onLogin,
    this.onAuthSuccess,
    this.onOnboardingCompleted,
    this.onNavigateToProfileSetup,
    this.onProfileCreationCompleted,
    this.splashDuration = const Duration(milliseconds: 2400),
    this.languageRepository,
    this.authRepository,
    this.eligibilityRepository,
    this.starterModuleRepository,
    this.moduleProfileRepository,
    this.initialVerificationEmail,
    this.recoveryToken,
    this.isSocialAuthorizedByServer = true,
    this.initialStatus,
    this.isRecoveryOnlySession = false,
  });

  /// Optional manual step override (0..15).
  final int? initialStep;
  final VoidCallback? onRegister;
  final VoidCallback? onLogin;
  final ValueChanged<AuthUser>? onAuthSuccess;
  final ValueChanged<String>? onOnboardingCompleted;
  final ValueChanged<String>? onNavigateToProfileSetup;
  final ValueChanged<String>? onProfileCreationCompleted;
  final Duration splashDuration;
  final LanguagePreferenceRepository? languageRepository;
  final OnboardingAuthRepository? authRepository;
  final EligibilityRepository? eligibilityRepository;
  final StarterModuleRepository? starterModuleRepository;
  final ModuleProfileRepository? moduleProfileRepository;
  final String? initialVerificationEmail;
  final String? recoveryToken;
  final bool isSocialAuthorizedByServer;

  /// Optional server-reported onboarding status for resuming an in-progress flow.
  final OnboardingStatus? initialStatus;

  /// True when the user is arriving via a password recovery deep link.
  /// Strictly isolates the user to Screen 08 (Password Reset) without general onboarding access.
  final bool isRecoveryOnlySession;

  /// Maps server [OnboardingStatus] to one of the coordinator's steps (0..15).
  ///
  /// Supports all 20 server resume / recovery scenarios:
  /// - Recovery session: strictly Step 7 (Screen 08 – Password Reset).
  /// - 'initialize_account', 'complete_demographics', 'age_ineligible', 'review_policies': Step 8 (Screen 09).
  /// - 'select_starter': Step 9 (Screen 10).
  /// - 'profile_setup':
  ///     - 'learning': Step 13 if profile complete, else Step 10
  ///     - 'hobbies': Step 14 if profile complete, else Step 11
  ///     - 'social': Step 15 if profile complete, else Step 12
  /// - Unknown/fallback: Step 8.
  static int stepFromOnboardingStatus(
    OnboardingStatus status, {
    bool isRecoveryOnlySession = false,
  }) {
    if (isRecoveryOnlySession) {
      return 7;
    }

    switch (status.nextStep) {
      case 'initialize_account':
      case 'complete_demographics':
      case 'age_ineligible':
      case 'review_policies':
        return 8;
      case 'select_starter':
        return 9;
      case 'profile_setup':
        final mod = status.selectedModule?.toLowerCase();
        if (status.progress.privateProfileComplete) {
          switch (mod) {
            case 'hobbies':
              return 14;
            case 'social':
              return 15;
            case 'learning':
            default:
              return 13;
          }
        } else {
          switch (mod) {
            case 'hobbies':
              return 11;
            case 'social':
              return 12;
            case 'learning':
            default:
              return 10;
          }
        }
      default:
        return 8;
    }
  }

  @override
  State<OnboardingFlowCoordinator> createState() =>
      _OnboardingFlowCoordinatorState();
}

class _OnboardingFlowCoordinatorState extends State<OnboardingFlowCoordinator> {
  late int _currentStep;
  late final LanguagePreferenceRepository _languageRepository;
  late final OnboardingAuthRepository _authRepository;
  late final EligibilityRepository _eligibilityRepository;
  late final StarterModuleRepository _starterModuleRepository;
  late final ModuleProfileRepository _moduleProfileRepository;
  late final ModuleProfileViewModel _learningProfileViewModel;
  late final ModuleProfileViewModel _hobbiesProfileViewModel;
  late final ModuleProfileViewModel _socialProfileViewModel;

  bool _hasValidSavedLanguage = false;
  bool _hasNavigatedFromSplash = false;
  String _activeVerificationEmail = '';
  String? _activeRecoveryToken;
  String _selectedLanguageCode = 'en';

  @override
  void initState() {
    super.initState();
    _languageRepository =
        widget.languageRepository ?? SharedPrefsLanguagePreferenceRepository();
    _authRepository =
        widget.authRepository ?? const UnconfiguredAuthRepository();
    _eligibilityRepository =
        widget.eligibilityRepository ?? const UnconfiguredEligibilityRepository();
    _starterModuleRepository = widget.starterModuleRepository ??
        const UnconfiguredStarterModuleRepository();
    _moduleProfileRepository = widget.moduleProfileRepository ??
        const UnconfiguredModuleProfileRepository();

    _learningProfileViewModel = ModuleProfileViewModel(
      config: ProfileCreationConfig.learning(),
      repository: _moduleProfileRepository,
    );
    _hobbiesProfileViewModel = ModuleProfileViewModel(
      config: ProfileCreationConfig.hobbies(),
      repository: _moduleProfileRepository,
    );
    _socialProfileViewModel = ModuleProfileViewModel(
      config: ProfileCreationConfig.social(),
      repository: _moduleProfileRepository,
      isSocialAuthorizedByServer: widget.isSocialAuthorizedByServer,
    );

    if (widget.isRecoveryOnlySession) {
      _currentStep = 7;
    } else if (widget.initialStatus != null) {
      _currentStep = OnboardingFlowCoordinator.stepFromOnboardingStatus(
        widget.initialStatus!,
        isRecoveryOnlySession: widget.isRecoveryOnlySession,
      );
    } else {
      _currentStep = widget.initialStep ?? 0;
    }

    _activeVerificationEmail =
        widget.initialVerificationEmail ?? 'user@andril.app';
    _activeRecoveryToken = widget.recoveryToken;

    if (_currentStep == 0) {
      _checkSavedLanguage();
    }
  }

  @override
  void dispose() {
    _learningProfileViewModel.dispose();
    _hobbiesProfileViewModel.dispose();
    _socialProfileViewModel.dispose();
    super.dispose();
  }

  Future<void> _checkSavedLanguage() async {
    try {
      final savedCode = await _languageRepository.getSavedLanguage();
      if (AppLanguage.isValidCode(savedCode)) {
        _hasValidSavedLanguage = true;
        _selectedLanguageCode = savedCode!;
      } else {
        _hasValidSavedLanguage = false;
      }
    } catch (_) {
      _hasValidSavedLanguage = false;
    }
  }

  void _onSplashFinished() {
    if (!mounted || _hasNavigatedFromSplash) return;
    _hasNavigatedFromSplash = true;

    setState(() {
      if (_hasValidSavedLanguage) {
        _currentStep = 2; // Welcome
      } else {
        _currentStep = 1; // Language
      }
    });
  }

  Future<void> _goToWelcome() async {
    try {
      final savedCode = await _languageRepository.getSavedLanguage();
      if (AppLanguage.isValidCode(savedCode)) {
        _selectedLanguageCode = savedCode!;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _currentStep = 2);
  }

  void _handleWelcomeCreateAccount() {
    if (widget.onRegister != null) {
      widget.onRegister!();
      return;
    }
    _goToRegistration();
  }

  void _handleWelcomeLogIn() {
    if (widget.onLogin != null) {
      widget.onLogin!();
      return;
    }
    _goToLogin();
  }

  void _goToRegistration() {
    if (!mounted) return;
    setState(() => _currentStep = 3);
  }

  void _goToVerification(String email) {
    if (!mounted) return;
    setState(() {
      _activeVerificationEmail = email;
      _currentStep = 4;
    });
  }

  void _goToLogin() {
    if (!mounted) return;
    setState(() => _currentStep = 5);
  }

  void _goToPasswordRecovery() {
    if (!mounted) return;
    setState(() => _currentStep = 6);
  }

  void _goToPasswordReset({String? token}) {
    if (!mounted) return;
    setState(() {
      if (token != null) _activeRecoveryToken = token;
      _currentStep = 7;
    });
  }

  void _goToEligibility() {
    if (!mounted) return;
    setState(() => _currentStep = 8);
  }

  void _goToStarterModuleSelection() {
    if (!mounted) return;
    setState(() => _currentStep = 9);
  }

  void _onAuthenticationCompleted(AuthUser user) {
    widget.onAuthSuccess?.call(user);
    _goToEligibility();
  }

  void _onEligibilityConfirmed(EligibilityResult result) {
    if (result.nextStep == 'starter_selection') {
      _goToStarterModuleSelection();
    } else {
      widget.onOnboardingCompleted?.call(result.nextStep);
    }
  }

  void _onStarterSelectionCompleted(StarterSelectionResult result) {
    widget.onOnboardingCompleted?.call(result.nextStep);
    if (!mounted) return;
    setState(() {
      switch (result.selectedModuleId.toLowerCase()) {
        case 'hobbies':
          _currentStep = 11;
        case 'social':
          _currentStep = 12;
        case 'learning':
        default:
          _currentStep = 10;
      }
    });
  }

  void _backToModuleSelection() {
    if (!mounted) return;
    setState(() => _currentStep = 9);
  }

  void _handleModuleWelcomeGetStarted(String moduleId) {
    widget.onNavigateToProfileSetup?.call(moduleId);
    if (!mounted) return;
    setState(() {
      switch (moduleId.toLowerCase()) {
        case 'hobbies':
          _currentStep = 14;
          break;
        case 'social':
          _currentStep = 15;
          break;
        case 'learning':
        default:
          _currentStep = 13;
          break;
      }
    });
  }

  void _backToLearningWelcome() {
    if (!mounted) return;
    setState(() => _currentStep = 10);
  }

  void _backToHobbiesWelcome() {
    if (!mounted) return;
    setState(() => _currentStep = 11);
  }

  void _backToSocialWelcome() {
    if (!mounted) return;
    setState(() => _currentStep = 12);
  }

  void _handleProfileCreationCompleted(String moduleId) {
    widget.onProfileCreationCompleted?.call(moduleId);
    widget.onOnboardingCompleted?.call('preferences_$moduleId');
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: Locale(_selectedLanguageCode),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentStep) {
      case 0:
        return SplashScreen(
          key: const ValueKey('splash_screen'),
          duration: widget.splashDuration,
          onSplashComplete: _onSplashFinished,
        );
      case 1:
        return ChooseLanguageScreen(
          key: const ValueKey('choose_language_screen'),
          onContinue: _goToWelcome,
        );
      case 2:
        return WelcomeScreen(
          key: const ValueKey('welcome_screen'),
          onCreateAccount: _handleWelcomeCreateAccount,
          onLogIn: _handleWelcomeLogIn,
        );
      case 3:
        return RegistrationScreen(
          key: const ValueKey('registration_screen'),
          authRepository: _authRepository,
          onBack: _goToWelcome,
          onNavigateToLogin: _goToLogin,
          onVerificationRequired: _goToVerification,
          onRegistrationSuccess: _onAuthenticationCompleted,
        );
      case 4:
        return AccountVerificationScreen(
          key: const ValueKey('verification_screen'),
          email: _activeVerificationEmail,
          authRepository: _authRepository,
          onBack: _goToRegistration,
          onVerificationSuccess: _onAuthenticationCompleted,
        );
      case 5:
        return LoginScreen(
          key: const ValueKey('login_screen'),
          authRepository: _authRepository,
          onBack: _goToWelcome,
          onNavigateToRegister: _goToRegistration,
          onNavigateToForgotPassword: _goToPasswordRecovery,
          onVerificationRequired: _goToVerification,
          onLoginSuccess: _onAuthenticationCompleted,
        );
      case 6:
        return PasswordRecoveryScreen(
          key: const ValueKey('password_recovery_screen'),
          authRepository: _authRepository,
          onBackToLogin: _goToLogin,
          onRecoverySubmitted: () {
            // Can transition to password reset if test token is present
            if (_activeRecoveryToken != null) {
              _goToPasswordReset(token: _activeRecoveryToken);
            }
          },
        );
      case 7:
        return PasswordResetScreen(
          key: const ValueKey('password_reset_screen'),
          authRepository: _authRepository,
          recoveryToken: _activeRecoveryToken,
          onBackToLogin: _goToLogin,
          onPasswordResetSuccess: () {},
        );
      case 8:
        return EligibilityPoliciesScreen(
          key: const ValueKey('eligibility_screen'),
          repository: _eligibilityRepository,
          onBack: _goToWelcome,
          onEligibilityConfirmed: _onEligibilityConfirmed,
        );
      case 9:
        return StarterModuleSelectionScreen(
          key: const ValueKey('starter_selection_screen'),
          repository: _starterModuleRepository,
          isSocialAuthorizedByServer: widget.isSocialAuthorizedByServer,
          onBack: _goToEligibility,
          onStarterSelectionCompleted: _onStarterSelectionCompleted,
        );
      case 10:
        return LearningWelcomeScreen(
          key: const ValueKey('learning_welcome_screen'),
          onGetStarted: () => _handleModuleWelcomeGetStarted('learning'),
          onBackToModuleSelection: _backToModuleSelection,
        );
      case 11:
        return HobbiesWelcomeScreen(
          key: const ValueKey('hobbies_welcome_screen'),
          onGetStarted: () => _handleModuleWelcomeGetStarted('hobbies'),
          onBackToModuleSelection: _backToModuleSelection,
        );
      case 12:
        return SocialWelcomeScreen(
          key: const ValueKey('social_welcome_screen'),
          isSocialAuthorizedByServer: widget.isSocialAuthorizedByServer,
          onGetStarted: () => _handleModuleWelcomeGetStarted('social'),
          onBackToModuleSelection: _backToModuleSelection,
        );
      case 13:
        return LearningProfileScreen(
          key: const ValueKey('learning_profile_screen'),
          viewModel: _learningProfileViewModel,
          onBack: _backToLearningWelcome,
          onContinue: () => _handleProfileCreationCompleted('learning'),
        );
      case 14:
        return HobbiesProfileScreen(
          key: const ValueKey('hobbies_profile_screen'),
          viewModel: _hobbiesProfileViewModel,
          onBack: _backToHobbiesWelcome,
          onContinue: () => _handleProfileCreationCompleted('hobbies'),
        );
      case 15:
        return SocialProfileScreen(
          key: const ValueKey('social_profile_screen'),
          viewModel: _socialProfileViewModel,
          isSocialAuthorizedByServer: widget.isSocialAuthorizedByServer,
          onBack: _backToSocialWelcome,
          onContinue: () => _handleProfileCreationCompleted('social'),
        );
      default:
        return WelcomeScreen(
          key: const ValueKey('welcome_screen_fallback'),
          onCreateAccount: _handleWelcomeCreateAccount,
          onLogIn: _handleWelcomeLogIn,
        );
    }
  }
}
