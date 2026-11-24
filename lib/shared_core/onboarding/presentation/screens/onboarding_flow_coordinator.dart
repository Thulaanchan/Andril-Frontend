import 'package:flutter/material.dart';
import '../../../authentication/data/repositories/unconfigured_auth_repository.dart';
import '../../../authentication/domain/entities/auth_user.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';
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
import 'splash_screen.dart';
import 'welcome_screen.dart';

/// Central navigation coordinator for all ten finalized onboarding screens (Screens 01 through 10).
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
///
/// Flow Intelligence:
/// - First-time unauthenticated: Splash -> Language -> Welcome.
/// - Returning unauthenticated (saved language): Splash -> Welcome.
/// - Welcome -> "Create Account" (3) or "Log In" (5).
/// - Registration -> Account Verification (4) -> Eligibility & Policies (8).
/// - Login -> Eligibility & Policies (8), or Account Verification (4) if unverified.
/// - Password Recovery Request (6) -> Password Reset (7) -> Login (5).
/// - Eligibility & Policies (8) -> Starter Module Selection (9).
/// - Starter Module Selection (9) -> invokes [onOnboardingCompleted] with next step (e.g. 'profile_setup').
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
    this.splashDuration = const Duration(milliseconds: 2400),
    this.languageRepository,
    this.authRepository,
    this.eligibilityRepository,
    this.starterModuleRepository,
    this.initialVerificationEmail,
    this.recoveryToken,
    this.isSocialAuthorizedByServer = true,
  });

  /// Optional manual step override (0..9).
  final int? initialStep;
  final VoidCallback? onRegister;
  final VoidCallback? onLogin;
  final ValueChanged<AuthUser>? onAuthSuccess;
  final ValueChanged<String>? onOnboardingCompleted;
  final Duration splashDuration;
  final LanguagePreferenceRepository? languageRepository;
  final AuthRepository? authRepository;
  final EligibilityRepository? eligibilityRepository;
  final StarterModuleRepository? starterModuleRepository;
  final String? initialVerificationEmail;
  final String? recoveryToken;
  final bool isSocialAuthorizedByServer;

  @override
  State<OnboardingFlowCoordinator> createState() =>
      _OnboardingFlowCoordinatorState();
}

class _OnboardingFlowCoordinatorState extends State<OnboardingFlowCoordinator> {
  late int _currentStep;
  late final LanguagePreferenceRepository _languageRepository;
  late final AuthRepository _authRepository;
  late final EligibilityRepository _eligibilityRepository;
  late final StarterModuleRepository _starterModuleRepository;

  bool _hasValidSavedLanguage = false;
  bool _hasNavigatedFromSplash = false;
  String _activeVerificationEmail = '';
  String? _activeRecoveryToken;

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

    _currentStep = widget.initialStep ?? 0;
    _activeVerificationEmail =
        widget.initialVerificationEmail ?? 'user@andril.app';
    _activeRecoveryToken = widget.recoveryToken;

    if (_currentStep == 0) {
      _checkSavedLanguage();
    }
  }

  Future<void> _checkSavedLanguage() async {
    try {
      final savedCode = await _languageRepository.getSavedLanguage();
      if (AppLanguage.isValidCode(savedCode)) {
        _hasValidSavedLanguage = true;
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

  void _goToWelcome() {
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
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _buildCurrentScreen(),
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
      default:
        return WelcomeScreen(
          key: const ValueKey('welcome_screen_fallback'),
          onCreateAccount: _handleWelcomeCreateAccount,
          onLogIn: _handleWelcomeLogIn,
        );
    }
  }
}
