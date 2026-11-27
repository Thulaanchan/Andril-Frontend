import 'package:andril_mobile/core/security/session/interactive_session_admission.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/shared_core/authentication/data/repositories/supabase_onboarding_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/email_auth_controller.dart';
import 'package:andril_mobile/shared_core/authentication/domain/entities/auth_result.dart';
import 'package:andril_mobile/shared_core/authentication/domain/entities/auth_user.dart';
import 'package:andril_mobile/shared_core/authentication/domain/google_auth_controller.dart';
import 'package:andril_mobile/shared_core/authentication/domain/repositories/auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/repositories/google_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/repositories/password_security_repository.dart';
import 'package:andril_mobile/shared_core/authentication/login/viewmodels/login_viewmodel.dart';
import 'package:andril_mobile/shared_core/authentication/password_recovery/viewmodels/password_recovery_viewmodel.dart';
import 'package:andril_mobile/shared_core/authentication/password_recovery/viewmodels/password_reset_viewmodel.dart';
import 'package:andril_mobile/shared_core/authentication/registration/viewmodels/registration_viewmodel.dart';
import 'package:andril_mobile/shared_core/authentication/verification/viewmodels/verification_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_fakes.dart';

class _FakeSessionSource extends FakeSessionSource
    implements BackendSessionSource {
  _FakeSessionSource({SessionEvent? restored}) : super(restored: restored);

  @override
  BackendCredential? backendCredential;

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}

  void publish(String subject, String token, {bool confirmed = true}) {
    backendCredential = BackendCredential(
      subject,
      token,
      emailConfirmed: confirmed,
    );
    signals.add(SessionEvent(SessionEventKind.signedIn, subject: subject));
  }
}

class _FakeAuthRepository implements AuthRepository {
  AuthRepositoryResult nextRegisterResult = const AuthRepositoryResult();
  AuthRepositoryResult nextVerifyResult = const AuthRepositoryResult();
  AuthRepositoryResult nextResendResult = const AuthRepositoryResult();
  AuthRepositoryResult nextSignInResult = const AuthRepositoryResult();

  int registerCallCount = 0;
  int verifyCallCount = 0;
  int resendCallCount = 0;
  int signInCallCount = 0;

  String? lastRegisterEmail;
  String? lastRegisterPassword;
  String? lastVerifyEmail;
  String? lastVerifyCode;
  String? lastResendEmail;
  String? lastSignInEmail;
  String? lastSignInPassword;

  @override
  Future<AuthRepositoryResult> register(String email, String password) async {
    registerCallCount++;
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    return nextRegisterResult;
  }

  @override
  Future<AuthRepositoryResult> resendSignupCode(String email) async {
    resendCallCount++;
    lastResendEmail = email;
    return nextResendResult;
  }

  @override
  Future<AuthRepositoryResult> signIn(String email, String password) async {
    signInCallCount++;
    lastSignInEmail = email;
    lastSignInPassword = password;
    return nextSignInResult;
  }

  @override
  Future<AuthRepositoryResult> verifySignupCode(
    String email,
    String code,
  ) async {
    verifyCallCount++;
    lastVerifyEmail = email;
    lastVerifyCode = code;
    return nextVerifyResult;
  }
}

class _FakeGoogleAuthRepository implements GoogleAuthRepository {
  GoogleAuthResult nextResult = const GoogleAuthResult(GoogleAuthState.idle);
  int signInCallCount = 0;

  @override
  Future<GoogleAuthResult> signIn({required bool Function() mayExchange}) async {
    signInCallCount++;
    return nextResult;
  }
}

class _FakePasswordSecurityRepository implements PasswordSecurityRepository {
  PasswordOutcome nextRecoveryOutcome = PasswordOutcome.requestAccepted;
  PasswordOutcome nextUpdateOutcome = PasswordOutcome.passwordUpdated;
  int requestRecoveryCallCount = 0;
  int updatePasswordCallCount = 0;
  String? lastRecoveryEmail;
  String? lastUpdatedPassword;
  PasswordOperation? lastOperation;

  @override
  Future<PasswordOutcome> requestRecovery(String email) async {
    requestRecoveryCallCount++;
    lastRecoveryEmail = email;
    return nextRecoveryOutcome;
  }

  @override
  Future<PasswordOutcome> updatePassword(
      PasswordOperation operation, String password) async {
    updatePasswordCallCount++;
    lastOperation = operation;
    lastUpdatedPassword = password;
    return nextUpdateOutcome;
  }
}

void main() {
  group('SupabaseOnboardingAuthRepository (Phase 01: T04, T05, T06)', () {
    late _FakeAuthRepository fakeAuthRepo;
    late _FakeSessionSource fakeSessionSource;
    late SessionController sessionController;
    late InteractiveSessionAdmission interactiveAdmission;
    late EmailAuthController emailAuthController;
    late SupabaseOnboardingAuthRepository onboardingAuthRepo;

    setUp(() async {
      fakeAuthRepo = _FakeAuthRepository();
      fakeSessionSource = _FakeSessionSource(
        restored: const SessionEvent(SessionEventKind.signedOut),
      );
      sessionController = SessionController(fakeSessionSource);
      interactiveAdmission = InteractiveSessionAdmission();
      await sessionController.start();
      await flushSessionWork();

      emailAuthController = EmailAuthController(
        fakeAuthRepo,
        sessionController,
        interactiveAdmission: interactiveAdmission,
        sessionWait: const Duration(milliseconds: 500),
      );

      onboardingAuthRepo = SupabaseOnboardingAuthRepository(
        emailAuthController: emailAuthController,
        sessionController: sessionController,
      );
    });

    tearDown(() {
      sessionController.dispose();
      emailAuthController.dispose();
    });

    group('T04 Registration & Corrections', () {
      test('delegates registration and returns safe neutral verificationRequired',
          () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();

        final result = await onboardingAuthRepo.registerWithEmail(
          email: 'newuser@andril.app',
          password: 'SecurePassword123!',
        );

        expect(fakeAuthRepo.registerCallCount, equals(1));
        expect(fakeAuthRepo.lastRegisterEmail, equals('newuser@andril.app'));
        expect(fakeAuthRepo.lastRegisterPassword, equals('SecurePassword123!'));

        expect(result, isA<AuthVerificationRequired>());
        final verification = result as AuthVerificationRequired;
        expect(verification.email, equals('newuser@andril.app'));
        expect(verification.message, isNotNull);
        expect(
          verification.message!,
          contains('If the account is eligible, verification instructions have been dispatched'),
        );
        expect(verification.message!.contains('6-digit'), isFalse);
        expect(verification.message!.contains('six-digit'), isFalse);

        expect(onboardingAuthRepo.pendingVerificationEmail, equals('newuser@andril.app'));
      });

      test('maps invalid email format rejection without calling repo', () async {
        final result = await onboardingAuthRepo.registerWithEmail(
          email: 'invalid-email',
          password: 'SecurePassword123!',
        );

        expect(fakeAuthRepo.registerCallCount, equals(0));
        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.invalidEmailFormat));
      });

      test('distinguishes provider password rejection from password mismatch', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.passwordRejected,
        );

        final result = await onboardingAuthRepo.registerWithEmail(
          email: 'user@andril.app',
          password: '123',
        );

        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.invalidCredentials));
        expect(failure.message, contains('security requirements'));
      });

      test('maps rate limiting correctly', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.rateLimited,
        );

        final result = await onboardingAuthRepo.registerWithEmail(
          email: 'user@andril.app',
          password: 'ValidPassword123!',
        );

        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.rateLimitExceeded));
        expect(failure.message, contains('Too many registration requests'));
      });

      test('maps provider service unavailable correctly', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.unavailable,
        );

        final result = await onboardingAuthRepo.registerWithEmail(
          email: 'user@andril.app',
          password: 'ValidPassword123!',
        );

        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.serviceUnavailable));
      });

      test('safely handles existing account without disclosing user existence', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();

        final result = await onboardingAuthRepo.registerWithEmail(
          email: 'existing@andril.app',
          password: 'ValidPassword123!',
        );

        expect(result, isA<AuthVerificationRequired>());
        final verification = result as AuthVerificationRequired;
        expect(verification.email, equals('existing@andril.app'));
        expect(verification.message, contains('If the account is eligible'));
      });

      test('RegistrationViewModel integrates cleanly with the live adapter', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();

        final viewModel = RegistrationViewModel(repository: onboardingAuthRepo);
        viewModel.setEmail('test@andril.app');
        viewModel.setPassword('ValidPass123!');
        viewModel.setConfirmPassword('ValidPass123!');
        viewModel.setTermsAgreed(true);

        String? verifiedEmail;
        await viewModel.register(
          onVerificationRequired: (email) => verifiedEmail = email,
        );

        expect(verifiedEmail, equals('test@andril.app'));
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.isLoading, isFalse);
      });
    });

    group('T05 OTP Verification', () {
      test('rejects verification when no pending verification context exists', () async {
        final result = await onboardingAuthRepo.verifyEmailOtp(
          email: 'random@andril.app',
          token: '123456',
        );

        expect(fakeAuthRepo.verifyCallCount, equals(0));
        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.message, contains('No pending verification context'));
      });

      test('rejects verification when email does not match pending context', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();
        await onboardingAuthRepo.registerWithEmail(
          email: 'target@andril.app',
          password: 'ValidPass123!',
        );

        final result = await onboardingAuthRepo.verifyEmailOtp(
          email: 'different@andril.app',
          token: '123456',
        );

        expect(fakeAuthRepo.verifyCallCount, equals(0));
        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.message, contains('does not match the active verification context'));
      });

      test('successful verification delegates to controller and completes session admission',
          () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();
        await onboardingAuthRepo.registerWithEmail(
          email: 'target@andril.app',
          password: 'ValidPass123!',
        );
        expect(onboardingAuthRepo.pendingVerificationEmail, equals('target@andril.app'));

        final receipt = AuthSessionReceipt((cred) => cred.accessToken == 'jwt-verified-token');
        fakeAuthRepo.nextVerifyResult = AuthRepositoryResult(session: receipt);

        final verifyFuture = onboardingAuthRepo.verifyEmailOtp(
          email: 'target@andril.app',
          token: '654321',
        );

        await flushSessionWork();
        expect(fakeAuthRepo.verifyCallCount, equals(1));
        expect(fakeAuthRepo.lastVerifyEmail, equals('target@andril.app'));
        expect(fakeAuthRepo.lastVerifyCode, equals('654321'));

        fakeSessionSource.publish('user-123', 'jwt-verified-token', confirmed: true);
        await flushSessionWork();

        final result = await verifyFuture;

        expect(result, isA<AuthSuccess>());
        final user = (result as AuthSuccess).user;
        expect(user.id, equals('user-123'));
        expect(user.email, equals('target@andril.app'));
        expect(user.isEmailVerified, isTrue);

        expect(onboardingAuthRepo.pendingVerificationEmail, isNull);
      });

      test('verification with unconfirmed credential does not fabricate isEmailVerified',
          () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();
        await onboardingAuthRepo.registerWithEmail(
          email: 'target@andril.app',
          password: 'ValidPass123!',
        );

        final receipt = AuthSessionReceipt((cred) => cred.accessToken == 'jwt-unconfirmed-token');
        fakeAuthRepo.nextVerifyResult = AuthRepositoryResult(session: receipt);

        final verifyFuture = onboardingAuthRepo.verifyEmailOtp(
          email: 'target@andril.app',
          token: '654321',
        );

        await flushSessionWork();

        fakeSessionSource.publish('user-unconfirmed', 'jwt-unconfirmed-token', confirmed: false);
        await flushSessionWork();

        final result = await verifyFuture;
        expect(result, isA<AuthFailureResult>());
      });

      test('maps invalid or expired verification code rejection', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();
        await onboardingAuthRepo.registerWithEmail(
          email: 'target@andril.app',
          password: 'ValidPass123!',
        );

        fakeAuthRepo.nextVerifyResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.invalidOrExpiredCode,
        );

        final result = await onboardingAuthRepo.verifyEmailOtp(
          email: 'target@andril.app',
          token: '000000',
        );

        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.verificationCodeInvalid));
        expect(failure.message, contains('invalid or expired'));
      });

      test('maps verification rate limiting rejection', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();
        await onboardingAuthRepo.registerWithEmail(
          email: 'target@andril.app',
          password: 'ValidPass123!',
        );

        fakeAuthRepo.nextVerifyResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.rateLimited,
        );

        final result = await onboardingAuthRepo.verifyEmailOtp(
          email: 'target@andril.app',
          token: '123456',
        );

        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.rateLimitExceeded));
      });

      test('maps verification service unavailable rejection', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();
        await onboardingAuthRepo.registerWithEmail(
          email: 'target@andril.app',
          password: 'ValidPass123!',
        );

        fakeAuthRepo.nextVerifyResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.unavailable,
        );

        final result = await onboardingAuthRepo.verifyEmailOtp(
          email: 'target@andril.app',
          token: '123456',
        );

        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.serviceUnavailable));
      });
    });

    group('T05 OTP Resend', () {
      test('rejects resend when no pending verification context exists', () async {
        final result = await onboardingAuthRepo.resendVerificationOtp(
          email: 'random@andril.app',
        );

        expect(fakeAuthRepo.resendCallCount, equals(0));
        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.message, contains('No pending verification context'));
      });

      test('rejects resend when email does not match pending context', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();
        await onboardingAuthRepo.registerWithEmail(
          email: 'target@andril.app',
          password: 'ValidPass123!',
        );

        final result = await onboardingAuthRepo.resendVerificationOtp(
          email: 'different@andril.app',
        );

        expect(fakeAuthRepo.resendCallCount, equals(0));
        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.message, contains('does not match the active verification context'));
      });

      test('successful resend delegates to controller and returns safe neutral verificationRequired',
          () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();
        await onboardingAuthRepo.registerWithEmail(
          email: 'target@andril.app',
          password: 'ValidPass123!',
        );

        fakeAuthRepo.nextResendResult = const AuthRepositoryResult();

        final result = await onboardingAuthRepo.resendVerificationOtp(
          email: 'target@andril.app',
        );

        expect(fakeAuthRepo.resendCallCount, equals(1));
        expect(fakeAuthRepo.lastResendEmail, equals('target@andril.app'));

        expect(result, isA<AuthVerificationRequired>());
        final verification = result as AuthVerificationRequired;
        expect(verification.email, equals('target@andril.app'));
        expect(verification.message, contains('A new verification code has been requested'));
      });

      test('maps resend rate limiting correctly', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();
        await onboardingAuthRepo.registerWithEmail(
          email: 'target@andril.app',
          password: 'ValidPass123!',
        );

        fakeAuthRepo.nextResendResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.rateLimited,
        );

        final result = await onboardingAuthRepo.resendVerificationOtp(
          email: 'target@andril.app',
        );

        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.rateLimitExceeded));
      });

      test('maps resend service unavailable correctly', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();
        await onboardingAuthRepo.registerWithEmail(
          email: 'target@andril.app',
          password: 'ValidPass123!',
        );

        fakeAuthRepo.nextResendResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.unavailable,
        );

        final result = await onboardingAuthRepo.resendVerificationOtp(
          email: 'target@andril.app',
        );

        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.serviceUnavailable));
      });

      test('VerificationViewModel integrates cleanly with the live adapter', () async {
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();
        await onboardingAuthRepo.registerWithEmail(
          email: 'test@andril.app',
          password: 'ValidPass123!',
        );

        final viewModel = VerificationViewModel(
          repository: onboardingAuthRepo,
          email: 'test@andril.app',
        );

        viewModel.setCode('123456');

        final receipt = AuthSessionReceipt((cred) => cred.accessToken == 'tok-vm');
        fakeAuthRepo.nextVerifyResult = AuthRepositoryResult(session: receipt);

        AuthUser? verifiedUser;
        final verifyFuture = viewModel.verify(
          onSuccess: (user) => verifiedUser = user,
        );

        await flushSessionWork();
        fakeSessionSource.publish('vm-user', 'tok-vm', confirmed: true);
        await flushSessionWork();
        await verifyFuture;

        expect(verifiedUser, isNotNull);
        expect(verifiedUser!.id, equals('vm-user'));
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.isLoading, isFalse);
      });
    });

    group('Task A01 – Email/Password Login (T06)', () {
      test('valid login delegates to EmailAuthController and returns AuthSuccess on session admission',
          () async {
        final receipt = AuthSessionReceipt((cred) => cred.accessToken == 'login-token-123');
        fakeAuthRepo.nextSignInResult = AuthRepositoryResult(session: receipt);

        final loginFuture = onboardingAuthRepo.logInWithEmail(
          email: 'returning@andril.app',
          password: 'ValidPassword123!',
        );

        await flushSessionWork();
        expect(fakeAuthRepo.signInCallCount, equals(1));
        expect(fakeAuthRepo.lastSignInEmail, equals('returning@andril.app'));
        expect(fakeAuthRepo.lastSignInPassword, equals('ValidPassword123!'));

        fakeSessionSource.publish('user-login-1', 'login-token-123', confirmed: true);
        await flushSessionWork();

        final result = await loginFuture;

        expect(result, isA<AuthSuccess>());
        final user = (result as AuthSuccess).user;
        expect(user.id, equals('user-login-1'));
        expect(user.email, equals('returning@andril.app'));
        expect(user.isEmailVerified, isTrue);
        expect(onboardingAuthRepo.pendingVerificationEmail, isNull);
      });

      test('unconfirmed email login returns verificationRequired and establishes pending context',
          () async {
        fakeAuthRepo.nextSignInResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.confirmationRequired,
        );

        final result = await onboardingAuthRepo.logInWithEmail(
          email: 'unconfirmed@andril.app',
          password: 'ValidPassword123!',
        );

        expect(fakeAuthRepo.signInCallCount, equals(1));
        expect(result, isA<AuthVerificationRequired>());
        final verification = result as AuthVerificationRequired;
        expect(verification.email, equals('unconfirmed@andril.app'));
        expect(verification.message, contains('Email confirmation is required before logging in'));

        // Confirms pending context is established for subsequent OTP entry or resend
        expect(onboardingAuthRepo.pendingVerificationEmail, equals('unconfirmed@andril.app'));
      });

      test('maps invalid email format rejection without calling repo', () async {
        final result = await onboardingAuthRepo.logInWithEmail(
          email: 'invalid-email-address',
          password: 'ValidPassword123!',
        );

        expect(fakeAuthRepo.signInCallCount, equals(0));
        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.invalidEmailFormat));
      });

      test('maps missing password rejection without calling repo', () async {
        final result = await onboardingAuthRepo.logInWithEmail(
          email: 'user@andril.app',
          password: '',
        );

        expect(fakeAuthRepo.signInCallCount, equals(0));
        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.invalidCredentials));
        expect(failure.message, contains('Password is required'));
      });

      test('maps incorrect credentials rejection', () async {
        fakeAuthRepo.nextSignInResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.invalidCredentials,
        );

        final result = await onboardingAuthRepo.logInWithEmail(
          email: 'user@andril.app',
          password: 'WrongPassword',
        );

        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.invalidCredentials));
        expect(failure.message, contains('Invalid email or password'));
      });

      test('maps rate limiting during login', () async {
        fakeAuthRepo.nextSignInResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.rateLimited,
        );

        final result = await onboardingAuthRepo.logInWithEmail(
          email: 'user@andril.app',
          password: 'Password123!',
        );

        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.rateLimitExceeded));
        expect(failure.message, contains('Too many login attempts'));
      });

      test('maps provider unavailable during login', () async {
        fakeAuthRepo.nextSignInResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.unavailable,
        );

        final result = await onboardingAuthRepo.logInWithEmail(
          email: 'user@andril.app',
          password: 'Password123!',
        );

        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.serviceUnavailable));
      });

      test('LoginViewModel integrates cleanly with live adapter for successful login', () async {
        final receipt = AuthSessionReceipt((cred) => cred.accessToken == 'vm-login-token');
        fakeAuthRepo.nextSignInResult = AuthRepositoryResult(session: receipt);

        final viewModel = LoginViewModel(repository: onboardingAuthRepo);
        viewModel.setEmail('vmuser@andril.app');
        viewModel.setPassword('ValidPass123!');

        AuthUser? loggedInUser;
        String? verificationRequiredEmail;

        final loginFuture = viewModel.logIn(
          onSuccess: (user) => loggedInUser = user,
          onVerificationRequired: (email) => verificationRequiredEmail = email,
        );

        await flushSessionWork();
        fakeSessionSource.publish('vm-subject', 'vm-login-token', confirmed: true);
        await flushSessionWork();
        await loginFuture;

        expect(loggedInUser, isNotNull);
        expect(loggedInUser!.id, equals('vm-subject'));
        expect(verificationRequiredEmail, isNull);
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.isLoading, isFalse);
      });

      test('LoginViewModel routes to verificationRequired when email is unconfirmed', () async {
        fakeAuthRepo.nextSignInResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.confirmationRequired,
        );

        final viewModel = LoginViewModel(repository: onboardingAuthRepo);
        viewModel.setEmail('unconfirmed@andril.app');
        viewModel.setPassword('ValidPass123!');

        AuthUser? loggedInUser;
        String? verificationRequiredEmail;

        await viewModel.logIn(
          onSuccess: (user) => loggedInUser = user,
          onVerificationRequired: (email) => verificationRequiredEmail = email,
        );

        expect(loggedInUser, isNull);
        expect(verificationRequiredEmail, equals('unconfirmed@andril.app'));
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.isLoading, isFalse);
        expect(onboardingAuthRepo.pendingVerificationEmail, equals('unconfirmed@andril.app'));
      });
    });

    group('Task A02 – Combined Authentication Journeys', () {
      test('Journey 1: Registration -> Verification -> Authenticated Session', () async {
        // Step 1: User registers
        fakeAuthRepo.nextRegisterResult = const AuthRepositoryResult();
        final regResult = await onboardingAuthRepo.registerWithEmail(
          email: 'journey1@andril.app',
          password: 'SecurePassword123!',
        );
        expect(regResult, isA<AuthVerificationRequired>());
        expect(onboardingAuthRepo.pendingVerificationEmail, equals('journey1@andril.app'));

        // Step 2: User verifies OTP
        final receipt = AuthSessionReceipt((cred) => cred.accessToken == 'journey1-token');
        fakeAuthRepo.nextVerifyResult = AuthRepositoryResult(session: receipt);

        final verifyFuture = onboardingAuthRepo.verifyEmailOtp(
          email: 'journey1@andril.app',
          token: '123456',
        );

        await flushSessionWork();
        fakeSessionSource.publish('journey1-user', 'journey1-token', confirmed: true);
        await flushSessionWork();
        final verifyResult = await verifyFuture;

        expect(verifyResult, isA<AuthSuccess>());
        expect((verifyResult as AuthSuccess).user.id, equals('journey1-user'));
        expect(onboardingAuthRepo.pendingVerificationEmail, isNull);
      });

      test('Journey 2: Unconfirmed Login -> Verification Required -> OTP Verification -> Authenticated Session',
          () async {
        // Step 1: User attempts login on unconfirmed account
        fakeAuthRepo.nextSignInResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.confirmationRequired,
        );
        final loginResult = await onboardingAuthRepo.logInWithEmail(
          email: 'journey2@andril.app',
          password: 'ValidPassword123!',
        );
        expect(loginResult, isA<AuthVerificationRequired>());
        expect(onboardingAuthRepo.pendingVerificationEmail, equals('journey2@andril.app'));

        // Step 2: User receives code and verifies from Screen 05
        final receipt = AuthSessionReceipt((cred) => cred.accessToken == 'journey2-token');
        fakeAuthRepo.nextVerifyResult = AuthRepositoryResult(session: receipt);

        final verifyFuture = onboardingAuthRepo.verifyEmailOtp(
          email: 'journey2@andril.app',
          token: '654321',
        );

        await flushSessionWork();
        fakeSessionSource.publish('journey2-user', 'journey2-token', confirmed: true);
        await flushSessionWork();
        final verifyResult = await verifyFuture;

        expect(verifyResult, isA<AuthSuccess>());
        expect((verifyResult as AuthSuccess).user.id, equals('journey2-user'));
        expect(onboardingAuthRepo.pendingVerificationEmail, isNull);
      });

      test('Journey 3: Unconfirmed Login -> Resend OTP -> Safe Acknowledgment', () async {
        fakeAuthRepo.nextSignInResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.confirmationRequired,
        );
        await onboardingAuthRepo.logInWithEmail(
          email: 'journey3@andril.app',
          password: 'ValidPassword123!',
        );

        fakeAuthRepo.nextResendResult = const AuthRepositoryResult();
        final resendResult = await onboardingAuthRepo.resendVerificationOtp(
          email: 'journey3@andril.app',
        );

        expect(resendResult, isA<AuthVerificationRequired>());
        expect(fakeAuthRepo.resendCallCount, equals(1));
        expect(fakeAuthRepo.lastResendEmail, equals('journey3@andril.app'));
      });

      test('Journey 4: Cross-context isolation rejects verification for unrelated email', () async {
        fakeAuthRepo.nextSignInResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.confirmationRequired,
        );
        await onboardingAuthRepo.logInWithEmail(
          email: 'account_a@andril.app',
          password: 'ValidPassword123!',
        );

        // Attempting to verify account_b when context is account_a must be rejected
        final result = await onboardingAuthRepo.verifyEmailOtp(
          email: 'account_b@andril.app',
          token: '123456',
        );

        expect(result, isA<AuthFailureResult>());
        expect(fakeAuthRepo.verifyCallCount, equals(0));
      });
    });

    group('Task A03 – Session & Identity Security', () {
      test('InteractiveSessionAdmission lease prevents concurrent unauthorized session install',
          () async {
        final receipt = AuthSessionReceipt((cred) => cred.accessToken == 'secure-tok');
        fakeAuthRepo.nextSignInResult = AuthRepositoryResult(session: receipt);

        // Acquire lease manually to simulate concurrent active session lease
        final lease = interactiveAdmission.begin();
        expect(lease, isNotNull);

        // Attempt login while admission lease is held
        final result = await onboardingAuthRepo.logInWithEmail(
          email: 'locked@andril.app',
          password: 'Password123!',
        );

        expect(result, isA<AuthFailureResult>());
        final failure = (result as AuthFailureResult).failure;
        expect(failure.type, equals(AuthFailureType.rateLimitExceeded));
        expect(failure.message, contains('already in progress'));

        lease?.close();
      });

      test('clearPendingVerificationEmail clears context on demand', () async {
        fakeAuthRepo.nextSignInResult = const AuthRepositoryResult(
          issue: EmailAuthIssue.confirmationRequired,
        );
        await onboardingAuthRepo.logInWithEmail(
          email: 'cleared@andril.app',
          password: 'Password123!',
        );
        expect(onboardingAuthRepo.pendingVerificationEmail, equals('cleared@andril.app'));

        onboardingAuthRepo.clearPendingVerificationEmail();
        expect(onboardingAuthRepo.pendingVerificationEmail, isNull);

        final result = await onboardingAuthRepo.verifyEmailOtp(
          email: 'cleared@andril.app',
          token: '123456',
        );
        expect(result, isA<AuthFailureResult>());
      });
    });

    group('Task 01.01 – Google Sign-In Integration (T07)', () {
      late _FakeGoogleAuthRepository fakeGoogleRepo;
      late GoogleAuthController googleAuthController;

      setUp(() {
        fakeGoogleRepo = _FakeGoogleAuthRepository();
        googleAuthController = GoogleAuthController(
          fakeGoogleRepo,
          sessionController,
          interactiveAdmission,
          admissionWait: const Duration(milliseconds: 500),
        );
      });

      tearDown(() {
        googleAuthController.dispose();
      });

      test('logInWithGoogle returns serviceUnavailable when controller is not configured', () async {
        final unconfiguredRepo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
        );
        final result = await unconfiguredRepo.logInWithGoogle();
        expect(result, isA<AuthFailureResult>());
        expect((result as AuthFailureResult).failure.type, equals(AuthFailureType.serviceUnavailable));
      });

      test('logInWithGoogle succeeds and returns AuthSuccess when session is admitted', () async {
        final repoWithGoogle = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          googleAuthController: googleAuthController,
        );

        final receipt = AuthSessionReceipt((cred) => cred.accessToken == 'google-tok');
        fakeGoogleRepo.nextResult = GoogleAuthResult.candidate(receipt);

        final googleFuture = repoWithGoogle.logInWithGoogle();
        await flushSessionWork();
        fakeSessionSource.publish('google-user-123', 'google-tok', confirmed: true);
        await flushSessionWork();

        final result = await googleFuture;
        expect(result, isA<AuthSuccess>());
        final user = (result as AuthSuccess).user;
        expect(user.id, equals('google-user-123'));
        expect(user.isEmailVerified, isTrue);
      });

      test('logInWithGoogle maps cancellation, rejection, and errors accurately', () async {
        final repoWithGoogle = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          googleAuthController: googleAuthController,
        );

        // Cancelled
        fakeGoogleRepo.nextResult = const GoogleAuthResult(GoogleAuthState.cancelled);
        var result = await repoWithGoogle.logInWithGoogle();
        expect(result, isA<AuthFailureResult>());
        expect((result as AuthFailureResult).failure.message, contains('cancelled'));

        // Unavailable
        fakeGoogleRepo.nextResult = const GoogleAuthResult(GoogleAuthState.unavailable);
        result = await repoWithGoogle.logInWithGoogle();
        expect(result, isA<AuthFailureResult>());
        expect((result as AuthFailureResult).failure.type, equals(AuthFailureType.serviceUnavailable));

        // Rejected
        fakeGoogleRepo.nextResult = const GoogleAuthResult(GoogleAuthState.googleRejected);
        result = await repoWithGoogle.logInWithGoogle();
        expect(result, isA<AuthFailureResult>());
        expect((result as AuthFailureResult).failure.type, equals(AuthFailureType.invalidCredentials));
      });
    });

    group('Task 01.02 – Forgot Password Functionality (Screen 07)', () {
      late _FakePasswordSecurityRepository fakePasswordRepo;

      setUp(() {
        fakePasswordRepo = _FakePasswordSecurityRepository();
      });

      test('rejects empty or malformed email without contacting repository', () async {
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          passwordSecurityRepository: fakePasswordRepo,
        );

        final emptyResult = await repo.sendPasswordResetEmail(email: '');
        expect(emptyResult, isA<AuthFailureResult>());
        expect((emptyResult as AuthFailureResult).failure.type, equals(AuthFailureType.invalidEmailFormat));

        final badResult = await repo.sendPasswordResetEmail(email: 'not-an-email');
        expect(badResult, isA<AuthFailureResult>());
        expect((badResult as AuthFailureResult).failure.type, equals(AuthFailureType.invalidEmailFormat));
        expect(fakePasswordRepo.requestRecoveryCallCount, equals(0));
      });

      test('delegates recovery request and returns neutral verificationRequired response', () async {
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          passwordSecurityRepository: fakePasswordRepo,
        );

        fakePasswordRepo.nextRecoveryOutcome = PasswordOutcome.requestAccepted;
        final result = await repo.sendPasswordResetEmail(email: 'reset@andril.app');

        expect(fakePasswordRepo.requestRecoveryCallCount, equals(1));
        expect(fakePasswordRepo.lastRecoveryEmail, equals('reset@andril.app'));
        expect(result, isA<AuthVerificationRequired>());
        expect((result as AuthVerificationRequired).email, equals('reset@andril.app'));
        expect(result.message, contains('password reset instructions have been dispatched'));
      });

      test('maps rate limiting and unavailability correctly', () async {
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          passwordSecurityRepository: fakePasswordRepo,
        );

        fakePasswordRepo.nextRecoveryOutcome = PasswordOutcome.rateLimited;
        var result = await repo.sendPasswordResetEmail(email: 'reset@andril.app');
        expect(result, isA<AuthFailureResult>());
        expect((result as AuthFailureResult).failure.type, equals(AuthFailureType.rateLimitExceeded));

        fakePasswordRepo.nextRecoveryOutcome = PasswordOutcome.unavailable;
        result = await repo.sendPasswordResetEmail(email: 'reset@andril.app');
        expect(result, isA<AuthFailureResult>());
        expect((result as AuthFailureResult).failure.type, equals(AuthFailureType.serviceUnavailable));
      });
    });

    group('Task 01.03 & 01.04 – Password Reset & Recovery Context (Screen 08)', () {
      late _FakePasswordSecurityRepository fakePasswordRepo;

      setUp(() {
        fakePasswordRepo = _FakePasswordSecurityRepository();
      });

      test('hasValidRecoveryContext validates session phase and recovery tokens', () async {
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          passwordSecurityRepository: fakePasswordRepo,
        );

        // Signed out with no token -> false
        expect(await repo.hasValidRecoveryContext(), isFalse);
        expect(await repo.hasValidRecoveryContext(recoveryToken: ''), isFalse);

        // Valid recovery token passed -> true
        expect(await repo.hasValidRecoveryContext(recoveryToken: 'valid-recovery-token'), isTrue);

        // Session phase in recovery -> true
        fakeSessionSource.signals.add(const SessionEvent(SessionEventKind.recovery, subject: 'rec-user'));
        await flushSessionWork();
        expect(await repo.hasValidRecoveryContext(), isTrue);
      });

      test('resetPasswordWithRecovery rejects empty password or missing recovery context', () async {
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          passwordSecurityRepository: fakePasswordRepo,
        );

        // Empty password rejected
        final emptyPwResult = await repo.resetPasswordWithRecovery(newPassword: '');
        expect(emptyPwResult, isA<AuthFailureResult>());
        expect((emptyPwResult as AuthFailureResult).failure.type, equals(AuthFailureType.invalidCredentials));

        // Missing recovery context rejected
        final noContextResult = await repo.resetPasswordWithRecovery(newPassword: 'NewSecurePassword123!');
        expect(noContextResult, isA<AuthFailureResult>());
        expect((noContextResult as AuthFailureResult).failure.message, contains('invalid or has expired'));
        expect(fakePasswordRepo.updatePasswordCallCount, equals(0));
      });

      test('resetPasswordWithRecovery succeeds when recovery context is active', () async {
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          passwordSecurityRepository: fakePasswordRepo,
        );

        fakePasswordRepo.nextUpdateOutcome = PasswordOutcome.passwordUpdated;
        final result = await repo.resetPasswordWithRecovery(
          newPassword: 'BrandNewPassword123!',
          recoveryToken: 'active-recovery-token',
        );

        expect(fakePasswordRepo.updatePasswordCallCount, equals(1));
        expect(fakePasswordRepo.lastOperation, equals(PasswordOperation.reset));
        expect(fakePasswordRepo.lastUpdatedPassword, equals('BrandNewPassword123!'));
        expect(result, isA<AuthSuccess>());
      });

      test('resetPasswordWithRecovery maps password rejection and mismatches correctly', () async {
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          passwordSecurityRepository: fakePasswordRepo,
        );

        fakePasswordRepo.nextUpdateOutcome = PasswordOutcome.passwordRejected;
        final result = await repo.resetPasswordWithRecovery(
          newPassword: 'weak',
          recoveryToken: 'active-recovery-token',
        );

        expect(result, isA<AuthFailureResult>());
        expect((result as AuthFailureResult).failure.message, contains('security requirements'));
      });
    });

    group('Task 01.05 & 01.06 – Session Restoration & Lifecycle', () {
      test('getCurrentUser returns null when not authenticated', () async {
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
        );

        final user = await repo.getCurrentUser();
        expect(user, isNull);
      });

      test('getCurrentUser returns authenticated AuthUser when session is active', () async {
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
        );

        fakeSessionSource.publish('active-session-subject', 'valid-active-tok', confirmed: true);
        await flushSessionWork();

        final user = await repo.getCurrentUser();
        expect(user, isNotNull);
        expect(user!.id, equals('active-session-subject'));
        expect(user.isEmailVerified, isTrue);
      });
    });

    group('Task 01.07 & 01.08 – Logout & Context Cleanup', () {
      test('logOut clears pending email and invokes onSignOut callback', () async {
        var signOutInvoked = false;
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          initialVerificationEmail: 'pending@andril.app',
          onSignOut: () async {
            signOutInvoked = true;
          },
        );

        expect(repo.pendingVerificationEmail, equals('pending@andril.app'));
        await repo.logOut();
        expect(repo.pendingVerificationEmail, isNull);
        expect(signOutInvoked, isTrue);
      });

      test('logInWithGoogle clears pendingVerificationEmail context', () async {
        final fakeGoogleRepo = _FakeGoogleAuthRepository();
        final googleController = GoogleAuthController(
          fakeGoogleRepo,
          sessionController,
          interactiveAdmission,
        );

        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          googleAuthController: googleController,
          initialVerificationEmail: 'stale@andril.app',
        );

        expect(repo.pendingVerificationEmail, equals('stale@andril.app'));
        fakeGoogleRepo.nextResult = const GoogleAuthResult(GoogleAuthState.cancelled);
        await repo.logInWithGoogle();
        expect(repo.pendingVerificationEmail, isNull);

        googleController.dispose();
      });
    });

    group('Task 01.09 – ViewModels End-to-End Integration', () {
      test('LoginViewModel continueWithGoogle executes successfully with live adapter', () async {
        final fakeGoogleRepo = _FakeGoogleAuthRepository();
        final googleController = GoogleAuthController(
          fakeGoogleRepo,
          sessionController,
          interactiveAdmission,
        );
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          googleAuthController: googleController,
        );

        final loginVm = LoginViewModel(repository: repo);
        AuthUser? successUser;

        final receipt = AuthSessionReceipt((cred) => cred.accessToken == 'google-login-tok');
        fakeGoogleRepo.nextResult = GoogleAuthResult.candidate(receipt);

        final future = loginVm.continueWithGoogle(
          onSuccess: (user) {
            successUser = user;
          },
        );

        await flushSessionWork();
        fakeSessionSource.publish('vm-google-user', 'google-login-tok', confirmed: true);
        await flushSessionWork();
        await future;

        expect(loginVm.isGoogleLoading, isFalse);
        expect(loginVm.errorMessage, isNull);
        expect(successUser, isNotNull);
        expect(successUser!.id, equals('vm-google-user'));

        loginVm.dispose();
        googleController.dispose();
      });

      test('PasswordRecoveryViewModel sends reset link through live adapter', () async {
        final fakePasswordRepo = _FakePasswordSecurityRepository();
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          passwordSecurityRepository: fakePasswordRepo,
        );

        final recoveryVm = PasswordRecoveryViewModel(repository: repo);
        recoveryVm.setEmail('recover@andril.app');

        var successCallbackCalled = false;
        await recoveryVm.sendResetLink(
          onSuccess: () {
            successCallbackCalled = true;
          },
        );

        expect(recoveryVm.isLoading, isFalse);
        expect(recoveryVm.isSubmitted, isTrue);
        expect(recoveryVm.errorMessage, isNull);
        expect(successCallbackCalled, isTrue);

        recoveryVm.dispose();
      });

      test('PasswordResetViewModel submits password reset through live adapter', () async {
        final fakePasswordRepo = _FakePasswordSecurityRepository();
        final repo = SupabaseOnboardingAuthRepository(
          emailAuthController: emailAuthController,
          sessionController: sessionController,
          passwordSecurityRepository: fakePasswordRepo,
        );

        final resetVm = PasswordResetViewModel(
          repository: repo,
          recoveryToken: 'active-flow-token',
        );

        resetVm.setNewPassword('BrandNewPass123!');
        resetVm.setConfirmPassword('BrandNewPass123!');

        var successCallbackCalled = false;
        await resetVm.submitPasswordReset(
          onSuccess: () {
            successCallbackCalled = true;
          },
        );

        expect(resetVm.isLoading, isFalse);
        expect(resetVm.isSuccess, isTrue);
        expect(resetVm.errorMessage, isNull);
        expect(successCallbackCalled, isTrue);

        resetVm.dispose();
      });
    });
  });
}
