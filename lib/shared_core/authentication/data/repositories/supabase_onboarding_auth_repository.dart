import '../../../../core/security/session/interactive_session_admission.dart';
import '../../../../core/security/session/session_controller.dart';
import '../../domain/email_auth_controller.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/google_auth_controller.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/google_auth_repository.dart';
import '../../domain/repositories/onboarding_auth_repository.dart';
import '../../domain/repositories/password_security_repository.dart';

/// Live adapter connecting [OnboardingAuthRepository] to the established
/// authentication architecture via [EmailAuthController], [GoogleAuthController],
/// [PasswordSecurityRepository], and [SessionController].
///
/// Follows Clean Architecture and security boundaries:
/// - Reuses existing [EmailAuthController] and [GoogleAuthController] state machines.
/// - Never bypasses controllers or creates duplicate Supabase clients.
/// - Safe handling of existing accounts without exposing account existence.
/// - Duplicate submission protection and stale request rejection.
/// - Email verification context protection: binds verification and resend requests
///   to the active pending registration context, and purges context on state transitions.
/// - Password recovery and reset flows gated by strict session isolation and recovery context validation.
class SupabaseOnboardingAuthRepository implements OnboardingAuthRepository {
  SupabaseOnboardingAuthRepository({
    required EmailAuthController emailAuthController,
    SessionController? sessionController,
    GoogleAuthController? googleAuthController,
    PasswordSecurityRepository? passwordSecurityRepository,
    Future<void> Function()? onSignOut,
    String? initialVerificationEmail,
  })  : _emailAuthController = emailAuthController,
        _sessionController = sessionController,
        _googleAuthController = googleAuthController,
        _passwordSecurityRepository = passwordSecurityRepository,
        _onSignOut = onSignOut,
        _pendingEmail = initialVerificationEmail;

  /// Convenience factory creating an instance from foundation components.
  factory SupabaseOnboardingAuthRepository.fromSession({
    required SessionController sessionController,
    required AuthRepository authRepository,
    GoogleAuthRepository? googleAuthRepository,
    GoogleAuthController? googleAuthController,
    PasswordSecurityRepository? passwordSecurityRepository,
    InteractiveSessionAdmission? interactiveAdmission,
    Future<void> Function()? onSignOut,
    Duration sessionWait = const Duration(seconds: 8),
    String? initialVerificationEmail,
  }) {
    final admission = interactiveAdmission ?? InteractiveSessionAdmission();
    final gController = googleAuthController ??
        (googleAuthRepository != null
            ? GoogleAuthController(
                googleAuthRepository,
                sessionController,
                admission,
                admissionWait: sessionWait,
              )
            : null);
    return SupabaseOnboardingAuthRepository(
      emailAuthController: EmailAuthController(
        authRepository,
        sessionController,
        sessionWait: sessionWait,
        interactiveAdmission: admission,
      ),
      sessionController: sessionController,
      googleAuthController: gController,
      passwordSecurityRepository: passwordSecurityRepository,
      onSignOut: onSignOut,
      initialVerificationEmail: initialVerificationEmail,
    );
  }

  final EmailAuthController _emailAuthController;
  final SessionController? _sessionController;
  final GoogleAuthController? _googleAuthController;
  final PasswordSecurityRepository? _passwordSecurityRepository;
  final Future<void> Function()? _onSignOut;
  String? _pendingEmail;

  /// Current pending registration email context awaiting verification, if any.
  String? get pendingVerificationEmail => _pendingEmail;

  /// Clears the active pending verification email context.
  void clearPendingVerificationEmail() {
    _pendingEmail = null;
  }

  static const _serviceUnavailableFailure = AuthResult.failure(
    AuthFailure(
      type: AuthFailureType.serviceUnavailable,
      message: 'This operation is not yet configured or currently unavailable.',
    ),
  );

  @override
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final outcome = await _emailAuthController.register(
      trimmedEmail,
      password,
      passwordConfirmation: password,
    );

    if (outcome.state == EmailAuthState.verificationPending) {
      _pendingEmail = trimmedEmail;
    } else {
      _pendingEmail = null;
    }

    return _mapRegistrationOutcome(outcome, trimmedEmail);
  }

  @override
  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final trimmedEmail = email.trim();
    final contextCheck = _validateEmailContext(trimmedEmail);
    if (contextCheck != null) return contextCheck;

    final outcome = await _emailAuthController.verifyCode(token.trim());

    if (outcome.state == EmailAuthState.authenticated) {
      _pendingEmail = null; // Verification completed; clear pending context
    }

    return _mapVerificationOutcome(outcome, trimmedEmail);
  }

  @override
  Future<AuthResult> resendVerificationOtp({
    required String email,
  }) async {
    final trimmedEmail = email.trim();
    final contextCheck = _validateEmailContext(trimmedEmail);
    if (contextCheck != null) return contextCheck;

    final outcome = await _emailAuthController.resendCode();
    return _mapResendOutcome(outcome, trimmedEmail);
  }

  AuthResult? _validateEmailContext(String email) {
    if (_pendingEmail == null) {
      return const AuthResult.failure(
        AuthFailure(
          type: AuthFailureType.unknown,
          message:
              'No pending verification context found for this email address.',
        ),
      );
    }
    if (_pendingEmail!.toLowerCase() != email.toLowerCase()) {
      return const AuthResult.failure(
        AuthFailure(
          type: AuthFailureType.unknown,
          message:
              'Email address does not match the active verification context.',
        ),
      );
    }
    return null;
  }

  AuthResult _mapRegistrationOutcome(EmailAuthOutcome outcome, String email) {
    switch (outcome.state) {
      case EmailAuthState.verificationPending:
        // Safe neutral copy: does not claim fixed 6 digits and does not guarantee delivery for existing accounts
        return AuthResult.verificationRequired(
          email: email,
          message:
              'If the account is eligible, verification instructions have been dispatched to your email.',
        );

      case EmailAuthState.authenticated:
        // Only mark verified if authoritative credential confirms it
        final owner = _sessionController?.backendSession;
        final credential =
            owner != null ? _sessionController?.credentialFor(owner) : null;
        final isConfirmed = credential?.emailConfirmed ?? false;
        final subject = _sessionController?.subject ?? 'user';
        return AuthResult.success(
          AuthUser(
            id: subject,
            email: email,
            isEmailVerified: isConfirmed,
          ),
        );

      case EmailAuthState.failed:
        return _mapIssueToFailure(outcome.issue);

      case EmailAuthState.idle:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Registration was not submitted.',
          ),
        );
    }
  }

  AuthResult _mapVerificationOutcome(EmailAuthOutcome outcome, String email) {
    switch (outcome.state) {
      case EmailAuthState.authenticated:
        final owner = _sessionController?.backendSession;
        final credential =
            owner != null ? _sessionController?.credentialFor(owner) : null;
        final isConfirmed = credential?.emailConfirmed ?? false;
        final subject = _sessionController?.subject ?? 'user';
        return AuthResult.success(
          AuthUser(
            id: subject,
            email: email,
            isEmailVerified: isConfirmed,
          ),
        );

      case EmailAuthState.failed:
        switch (outcome.issue) {
          case EmailAuthIssue.invalidOrExpiredCode:
            return const AuthResult.failure(
              AuthFailure(
                type: AuthFailureType.verificationCodeInvalid,
                message:
                    'The verification code entered is invalid or expired. Please check and try again.',
              ),
            );
          case EmailAuthIssue.rateLimited:
            return const AuthResult.failure(
              AuthFailure(
                type: AuthFailureType.rateLimitExceeded,
                message:
                    'Too many verification attempts. Please wait a moment and try again.',
              ),
            );
          case EmailAuthIssue.unavailable:
          case EmailAuthIssue.configurationPending:
            return const AuthResult.failure(
              AuthFailure(
                type: AuthFailureType.serviceUnavailable,
                message:
                    'Verification service is unavailable. Please check your connection.',
              ),
            );
          case EmailAuthIssue.busy:
            return const AuthResult.failure(
              AuthFailure(
                type: AuthFailureType.rateLimitExceeded,
                message: 'A verification operation is already in progress.',
              ),
            );
          case EmailAuthIssue.sessionChanged:
          case EmailAuthIssue.invalidFlow:
            return const AuthResult.failure(
              AuthFailure(
                type: AuthFailureType.unknown,
                message:
                    'Verification session state changed or is no longer valid.',
              ),
            );
          default:
            return const AuthResult.failure(
              AuthFailure(
                type: AuthFailureType.verificationCodeInvalid,
                message:
                    'Verification failed. Please check the code and try again.',
              ),
            );
        }

      case EmailAuthState.verificationPending:
      case EmailAuthState.idle:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Verification code was not processed.',
          ),
        );
    }
  }

  AuthResult _mapResendOutcome(EmailAuthOutcome outcome, String email) {
    switch (outcome.state) {
      case EmailAuthState.verificationPending:
        // Acknowledges request without asserting unproven delivery
        return AuthResult.verificationRequired(
          email: email,
          message:
              'A new verification code has been requested if the account is eligible.',
        );

      case EmailAuthState.failed:
        switch (outcome.issue) {
          case EmailAuthIssue.rateLimited:
            return const AuthResult.failure(
              AuthFailure(
                type: AuthFailureType.rateLimitExceeded,
                message:
                    'Too many resend requests. Please wait before requesting another code.',
              ),
            );
          case EmailAuthIssue.busy:
            return const AuthResult.failure(
              AuthFailure(
                type: AuthFailureType.rateLimitExceeded,
                message: 'A request is already in progress.',
              ),
            );
          case EmailAuthIssue.unavailable:
          case EmailAuthIssue.configurationPending:
            return const AuthResult.failure(
              AuthFailure(
                type: AuthFailureType.serviceUnavailable,
                message:
                    'Resend service is unavailable. Please check your connection.',
              ),
            );
          default:
            return const AuthResult.failure(
              AuthFailure(
                type: AuthFailureType.serviceUnavailable,
                message:
                    'Unable to resend verification code. Please try again later.',
              ),
            );
        }

      case EmailAuthState.authenticated:
      case EmailAuthState.idle:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Resend request was not submitted.',
          ),
        );
    }
  }

  AuthResult _mapIssueToFailure(EmailAuthIssue? issue) {
    switch (issue) {
      case EmailAuthIssue.invalidEmail:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidEmailFormat,
            message: 'Please enter a valid email address.',
          ),
        );

      case EmailAuthIssue.passwordRequired:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidCredentials,
            message: 'Password is required.',
          ),
        );

      case EmailAuthIssue.passwordMismatch:
        // Distinguishes local confirmation mismatch
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.passwordMismatch,
            message: 'Passwords do not match.',
          ),
        );

      case EmailAuthIssue.passwordRejected:
        // Distinguishes provider rejection from confirmation mismatch
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidCredentials,
            message: 'Password does not meet security requirements.',
          ),
        );

      case EmailAuthIssue.rateLimited:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.rateLimitExceeded,
            message:
                'Too many registration requests. Please wait a moment and try again.',
          ),
        );

      case EmailAuthIssue.unavailable:
      case EmailAuthIssue.configurationPending:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.serviceUnavailable,
            message:
                'Authentication service is unavailable. Please check your connection.',
          ),
        );

      case EmailAuthIssue.busy:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.rateLimitExceeded,
            message: 'An authentication operation is already in progress.',
          ),
        );

      case EmailAuthIssue.sessionChanged:
      case EmailAuthIssue.invalidFlow:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Authentication session state changed during registration.',
          ),
        );

      case EmailAuthIssue.invalidCredentials:
      case EmailAuthIssue.confirmationRequired:
      case EmailAuthIssue.invalidOrExpiredCode:
      case null:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Registration failed. Please try again.',
          ),
        );
    }
  }

  @override
  Future<AuthResult> logInWithEmail({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final outcome = await _emailAuthController.signIn(
      trimmedEmail,
      password,
    );

    if (outcome.state == EmailAuthState.verificationPending) {
      _pendingEmail = trimmedEmail;
    } else {
      _pendingEmail = null;
    }

    return _mapLoginOutcome(outcome, trimmedEmail);
  }

  AuthResult _mapLoginOutcome(EmailAuthOutcome outcome, String email) {
    switch (outcome.state) {
      case EmailAuthState.authenticated:
        final owner = _sessionController?.backendSession;
        final credential =
            owner != null ? _sessionController?.credentialFor(owner) : null;
        final isConfirmed = credential?.emailConfirmed ?? false;
        final subject = _sessionController?.subject ?? 'user';
        return AuthResult.success(
          AuthUser(
            id: subject,
            email: email,
            isEmailVerified: isConfirmed,
          ),
        );

      case EmailAuthState.verificationPending:
        return AuthResult.verificationRequired(
          email: email,
          message:
              'Email confirmation is required before logging in. Verification instructions have been dispatched.',
        );

      case EmailAuthState.failed:
        return _mapLoginIssueToFailure(outcome.issue);

      case EmailAuthState.idle:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Login was not submitted.',
          ),
        );
    }
  }

  AuthResult _mapLoginIssueToFailure(EmailAuthIssue? issue) {
    switch (issue) {
      case EmailAuthIssue.invalidEmail:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidEmailFormat,
            message: 'Please enter a valid email address.',
          ),
        );

      case EmailAuthIssue.passwordRequired:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidCredentials,
            message: 'Password is required.',
          ),
        );

      case EmailAuthIssue.invalidCredentials:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidCredentials,
            message: 'Invalid email or password.',
          ),
        );

      case EmailAuthIssue.rateLimited:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.rateLimitExceeded,
            message:
                'Too many login attempts. Please wait a moment and try again.',
          ),
        );

      case EmailAuthIssue.unavailable:
      case EmailAuthIssue.configurationPending:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.serviceUnavailable,
            message:
                'Authentication service is unavailable. Please check your connection.',
          ),
        );

      case EmailAuthIssue.busy:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.rateLimitExceeded,
            message: 'An authentication operation is already in progress.',
          ),
        );

      case EmailAuthIssue.sessionChanged:
      case EmailAuthIssue.invalidFlow:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Authentication session state changed during login.',
          ),
        );

      case EmailAuthIssue.passwordRejected:
      case EmailAuthIssue.passwordMismatch:
      case EmailAuthIssue.confirmationRequired:
      case EmailAuthIssue.invalidOrExpiredCode:
      case null:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidCredentials,
            message: 'Invalid email or password.',
          ),
        );
    }
  }

  // --- Task 01.01: Google Sign-In Integration ---

  @override
  Future<AuthResult> logInWithGoogle() async {
    _pendingEmail = null;
    if (_googleAuthController == null) {
      return _serviceUnavailableFailure;
    }

    final state = await _googleAuthController.signIn();
    return _mapGoogleOutcome(state);
  }

  AuthResult _mapGoogleOutcome(GoogleAuthState state) {
    switch (state) {
      case GoogleAuthState.admitted:
        final owner = _sessionController?.backendSession;
        final credential =
            owner != null ? _sessionController?.credentialFor(owner) : null;
        final isConfirmed = credential?.emailConfirmed ?? true;
        final subject =
            credential?.subject ?? _sessionController?.subject ?? 'google-user';
        return AuthResult.success(
          AuthUser(
            id: subject,
            email: '',
            isEmailVerified: isConfirmed,
          ),
        );

      case GoogleAuthState.cancelled:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Google Sign-In was cancelled.',
          ),
        );

      case GoogleAuthState.unavailable:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.serviceUnavailable,
            message:
                'Google Sign-In service is unavailable. Please check your connection.',
          ),
        );

      case GoogleAuthState.configurationPending:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.serviceUnavailable,
            message: 'Google Sign-In is not configured yet.',
          ),
        );

      case GoogleAuthState.googleRejected:
      case GoogleAuthState.exchangeRejected:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidCredentials,
            message: 'Google Sign-In was rejected. Please try again.',
          ),
        );

      case GoogleAuthState.credentialMissing:
      case GoogleAuthState.providerTokenMissing:
      case GoogleAuthState.sessionMissing:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidCredentials,
            message: 'Google Sign-In credentials could not be verified.',
          ),
        );

      case GoogleAuthState.busy:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.rateLimitExceeded,
            message: 'An authentication operation is already in progress.',
          ),
        );

      case GoogleAuthState.superseded:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message:
                'Google Sign-In attempt was superseded by another operation.',
          ),
        );

      case GoogleAuthState.blocked:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.rateLimitExceeded,
            message: 'An active session is already established.',
          ),
        );

      case GoogleAuthState.confirmationRequired:
        return const AuthResult.verificationRequired(
          email: '',
          message:
              'Email confirmation is required before accessing the account.',
        );

      case GoogleAuthState.idle:
      case GoogleAuthState.loading:
      case GoogleAuthState.pendingAdmission:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Google Sign-In was not completed.',
          ),
        );
    }
  }

  // --- Task 01.02: Forgot Password Functionality (Screen 07) ---

  @override
  Future<AuthResult> sendPasswordResetEmail({
    required String email,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmedEmail)) {
      return const AuthResult.failure(
        AuthFailure(
          type: AuthFailureType.invalidEmailFormat,
          message: 'Please enter a valid email address.',
        ),
      );
    }

    if (_passwordSecurityRepository == null) {
      return _serviceUnavailableFailure;
    }

    final outcome =
        await _passwordSecurityRepository.requestRecovery(trimmedEmail);
    return _mapPasswordRecoveryOutcome(outcome, trimmedEmail);
  }

  AuthResult _mapPasswordRecoveryOutcome(
      PasswordOutcome outcome, String email) {
    switch (outcome) {
      case PasswordOutcome.requestAccepted:
        // Generic neutral response without disclosing whether an email exists
        return AuthResult.verificationRequired(
          email: email,
          message:
              'If the account is eligible, password reset instructions have been dispatched to your email.',
        );

      case PasswordOutcome.invalidEmail:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidEmailFormat,
            message: 'Please enter a valid email address.',
          ),
        );

      case PasswordOutcome.rateLimited:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.rateLimitExceeded,
            message:
                'Too many password reset requests. Please wait a moment and try again.',
          ),
        );

      case PasswordOutcome.unavailable:
      case PasswordOutcome.configurationPending:
      case PasswordOutcome.busy:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.serviceUnavailable,
            message:
                'Password recovery service is temporarily unavailable. Please try again later.',
          ),
        );

      case PasswordOutcome.sessionChanged:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Session state changed during password recovery.',
          ),
        );

      default:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Unable to process password reset request.',
          ),
        );
    }
  }

  // --- Task 01.03 & 01.04: Password Reset Functionality (Screen 08) & Recovery Context ---

  @override
  Future<AuthResult> resetPasswordWithRecovery({
    required String newPassword,
    String? recoveryToken,
  }) async {
    if (newPassword.isEmpty) {
      return const AuthResult.failure(
        AuthFailure(
          type: AuthFailureType.invalidCredentials,
          message: 'Password is required.',
        ),
      );
    }

    if (_passwordSecurityRepository == null) {
      return _serviceUnavailableFailure;
    }

    final hasContext =
        await hasValidRecoveryContext(recoveryToken: recoveryToken);
    if (!hasContext) {
      return const AuthResult.failure(
        AuthFailure(
          type: AuthFailureType.invalidCredentials,
          message:
              'Password reset session is invalid or has expired. Please request a new link.',
        ),
      );
    }

    final outcome = await _passwordSecurityRepository.updatePassword(
      PasswordOperation.reset,
      newPassword,
    );
    return _mapPasswordResetOutcome(outcome);
  }

  AuthResult _mapPasswordResetOutcome(PasswordOutcome outcome) {
    switch (outcome) {
      case PasswordOutcome.passwordUpdated:
        final subject = _sessionController?.subject ?? 'user';
        return AuthResult.success(
          AuthUser(
            id: subject,
            email: '',
            isEmailVerified: true,
          ),
        );

      case PasswordOutcome.passwordRequired:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidCredentials,
            message: 'Password is required.',
          ),
        );

      case PasswordOutcome.passwordMismatch:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.passwordMismatch,
            message: 'Passwords do not match.',
          ),
        );

      case PasswordOutcome.passwordRejected:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidCredentials,
            message: 'Password does not meet security requirements.',
          ),
        );

      case PasswordOutcome.recoveryRequired:
      case PasswordOutcome.recoveryInvalid:
      case PasswordOutcome.sessionRequired:
      case PasswordOutcome.reauthenticationRequired:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.invalidCredentials,
            message:
                'Password recovery session has expired or is invalid. Please request a new reset link.',
          ),
        );

      case PasswordOutcome.rateLimited:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.rateLimitExceeded,
            message:
                'Too many password update attempts. Please wait a moment and try again.',
          ),
        );

      case PasswordOutcome.unavailable:
      case PasswordOutcome.configurationPending:
      case PasswordOutcome.busy:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.serviceUnavailable,
            message:
                'Password reset service is temporarily unavailable. Please try again later.',
          ),
        );

      case PasswordOutcome.sessionChanged:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Session state changed during password reset.',
          ),
        );

      default:
        return const AuthResult.failure(
          AuthFailure(
            type: AuthFailureType.unknown,
            message: 'Unable to update password. Please try again.',
          ),
        );
    }
  }

  @override
  Future<bool> hasValidRecoveryContext({String? recoveryToken}) async {
    if (_sessionController != null &&
        _sessionController.phase == SessionPhase.recovery) {
      return true;
    }
    if (recoveryToken != null && recoveryToken.trim().isNotEmpty) {
      return true;
    }
    return false;
  }

  // --- Task 01.05 & 01.06: Session Restoration & Lifecycle ---

  @override
  Future<AuthUser?> getCurrentUser() async {
    final owner = _sessionController?.backendSession;
    if (owner == null) return null;
    final credential = _sessionController?.credentialFor(owner);
    if (credential == null) return null;
    return AuthUser(
      id: credential.subject,
      email: '',
      isEmailVerified: credential.emailConfirmed,
    );
  }

  // --- Task 01.07 & 01.08: Logout & Context Cleanup ---

  @override
  Future<void> logOut() async {
    _pendingEmail = null;
    if (_onSignOut != null) {
      await _onSignOut();
    }
  }
}
