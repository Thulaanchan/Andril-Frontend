import 'dart:async';

import 'package:andril_mobile/core/security/session/interactive_session_admission.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/shared_core/authentication/domain/email_auth_controller.dart';
import 'package:andril_mobile/shared_core/authentication/domain/google_auth_controller.dart';
import 'package:andril_mobile/shared_core/authentication/domain/offline_current_device_logout.dart';
import 'package:andril_mobile/shared_core/authentication/domain/repositories/auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/repositories/google_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/domain/repositories/password_security_repository.dart';
import 'package:andril_mobile/shared_core/authentication/password_recovery/viewmodels/password_security_controller.dart';
import 'package:andril_mobile/shared_core/authentication/presentation/offline_auth_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_fakes.dart';

const _email = 'synthetic@example.invalid';
const _password = 'synthetic-password';
const _code = '001234';

class _EmailRepository implements AuthRepository {
  final registration = Completer<AuthRepositoryResult>();
  int signups = 0;
  int signIns = 0;
  String? code;

  @override
  Future<AuthRepositoryResult> register(String email, String password) {
    signups++;
    expect(email, _email);
    expect(password, _password);
    return registration.future;
  }

  @override
  Future<AuthRepositoryResult> signIn(String email, String password) async {
    signIns++;
    expect(email, _email);
    expect(password, _password);
    return const AuthRepositoryResult(issue: EmailAuthIssue.invalidCredentials);
  }

  @override
  Future<AuthRepositoryResult> verifySignupCode(
      String email, String code) async {
    expect(email, _email);
    this.code = code;
    return const AuthRepositoryResult(
        issue: EmailAuthIssue.invalidOrExpiredCode);
  }

  @override
  Future<AuthRepositoryResult> resendSignupCode(String email) async {
    expect(email, _email);
    return const AuthRepositoryResult(issue: EmailAuthIssue.rateLimited);
  }
}

class _PasswordRepository implements PasswordSecurityRepository {
  PasswordOutcome outcome = PasswordOutcome.passwordUpdated;
  final updates = <PasswordOperation>[];

  @override
  Future<PasswordOutcome> requestRecovery(String email) async {
    expect(email, _email);
    return PasswordOutcome.requestAccepted;
  }

  @override
  Future<PasswordOutcome> updatePassword(
      PasswordOperation operation, String password) async {
    expect(password, _password);
    updates.add(operation);
    return outcome;
  }
}

class _GoogleRepository implements GoogleAuthRepository {
  final response = Completer<GoogleAuthResult>();
  int calls = 0;

  @override
  Future<GoogleAuthResult> signIn({required bool Function() mayExchange}) {
    expect(mayExchange(), isTrue);
    calls++;
    return response.future;
  }
}

class _WidgetSource extends FakeSessionSource implements BackendSessionSource {
  @override
  BackendCredential? backendCredential;

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}

  void publish(SessionEventKind kind) {
    backendCredential = kind == SessionEventKind.signedIn
        ? const BackendCredential('subject', 'synthetic-token',
            emailConfirmed: true)
        : null;
    signals.add(SessionEvent(kind,
        subject: kind == SessionEventKind.signedOut ? null : 'subject'));
  }
}

class _LogoutBoundary implements OfflineLogoutBoundary {
  _LogoutBoundary(this.source);
  final _WidgetSource source;
  final cleanup = Completer<LogoutCleanup>();

  @override
  Future<LogoutCleanup> Function() revokeCurrentDevice() {
    source.publish(SessionEventKind.signedOut);
    return () => cleanup.future;
  }
}

Future<({_WidgetSource source, SessionController sessions})> _session() async {
  final source = _WidgetSource();
  final sessions = SessionController(source);
  await sessions.start();
  addTearDown(() async {
    sessions.dispose();
    await source.signals.close();
  });
  return (source: source, sessions: sessions);
}

Finder _field(AuthFormField field) => find.byKey(ValueKey(field));
Finder get _submit => find.byType(FilledButton);

Future<void> _mount(
  WidgetTester tester, {
  required Map<AuthFormField, String> fields,
  required Future<String> Function(Map<AuthFormField, String>) submit,
  bool enabled = true,
}) async {
  final status = ValueNotifier<String?>(null);
  addTearDown(status.dispose);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: ValueListenableBuilder(
            key: ObjectKey(status),
            valueListenable: status,
            builder: (context, message, _) => OfflineAuthForm(
              fields: fields,
              actionLabel: 'Synthetic action',
              busyLabel: 'Synthetic pending',
              failureLabel: 'Synthetic unavailable',
              passwordVisibilityLabels: (
                show: 'Synthetic show',
                hide: 'Synthetic hide'
              ),
              enabled: enabled,
              status: message,
              onSubmit: (input) async {
                final result = await submit(input);
                if (context.mounted) status.value = result;
              },
            ),
          ),
        ),
      ),
    ),
  ));
}

const _credentials = {
  AuthFormField.email: 'Synthetic email',
  AuthFormField.password: 'Synthetic password',
};
const _passwords = {
  AuthFormField.password: 'Synthetic password',
  AuthFormField.passwordConfirmation: 'Synthetic confirmation',
};

Future<void> _fillCredentials(WidgetTester tester) async {
  await tester.enterText(_field(AuthFormField.email), _email);
  await tester.enterText(_field(AuthFormField.password), _password);
}

Future<void> _fillPasswordPair(WidgetTester tester,
    [String confirmation = _password]) async {
  await tester.enterText(_field(AuthFormField.password), _password);
  await tester.enterText(
      _field(AuthFormField.passwordConfirmation), confirmation);
}

void main() {
  testWidgets(
      'signup, verification and resend compose without authorizing a session',
      (tester) async {
    final fixture = await _session();
    final repo = _EmailRepository();
    final flow = EmailAuthController(repo, fixture.sessions);
    addTearDown(flow.dispose);

    await _mount(tester, fields: {
      ..._credentials,
      AuthFormField.passwordConfirmation: 'Synthetic confirm'
    }, submit: (input) async {
      final result = await flow.register(
          input[AuthFormField.email]!, input[AuthFormField.password]!,
          passwordConfirmation: input[AuthFormField.passwordConfirmation]);
      return result.issue?.name ?? result.state.name;
    });
    await _fillCredentials(tester);
    await tester.enterText(
        _field(AuthFormField.passwordConfirmation), _password);
    await tester.tap(_submit);
    await tester.tap(_submit);
    await tester.pump();
    expect(find.text('Synthetic pending'), findsOneWidget);
    expect(tester.widget<FilledButton>(_submit).onPressed, isNull);
    expect(repo.signups, 1);
    repo.registration.complete(const AuthRepositoryResult());
    await tester.pumpAndSettle();
    expect(find.text('verificationPending'), findsOneWidget);
    expect(
        tester
            .widget<TextField>(_field(AuthFormField.password))
            .controller!
            .text,
        isEmpty);

    await _mount(tester,
        fields: const {AuthFormField.verificationCode: 'Synthetic code'},
        submit: (input) async =>
            (await flow.verifyCode(input[AuthFormField.verificationCode]!))
                .issue!
                .name);
    await tester.enterText(_field(AuthFormField.verificationCode), _code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(repo.code, _code);
    expect(find.text('invalidOrExpiredCode'), findsOneWidget);
    expect(
        tester
            .widget<TextField>(_field(AuthFormField.verificationCode))
            .controller!
            .text,
        isEmpty);

    await _mount(tester,
        fields: const {},
        submit: (_) async => (await flow.resendCode()).issue!.name);
    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(find.text('rateLimited'), findsOneWidget);
    expect(fixture.sessions.phase, SessionPhase.signedOut);
    expect(fixture.sessions.backendSession, isNull);
  });

  testWidgets(
      'login uses obscured input, keyboard submit and neutral rejection',
      (tester) async {
    final fixture = await _session();
    final repo = _EmailRepository();
    final flow = EmailAuthController(repo, fixture.sessions);
    addTearDown(flow.dispose);
    await _mount(tester,
        fields: _credentials,
        submit: (input) async => (await flow.signIn(
                input[AuthFormField.email]!, input[AuthFormField.password]!))
            .issue!
            .name);
    final password = _field(AuthFormField.password);
    expect(tester.widget<TextField>(password).obscureText, isTrue);
    await tester.tap(find.byTooltip('Synthetic show'));
    await tester.pump();
    expect(tester.widget<TextField>(password).obscureText, isFalse);
    await _fillCredentials(tester);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(repo.signIns, 1);
    expect(tester.widget<TextField>(password).obscureText, isTrue);
    expect(tester.widget<TextField>(password).controller!.text, isEmpty);
    expect(find.text('invalidCredentials'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.liveRegion == true),
        findsWidgets);
    semantics.dispose();
    expect(fixture.sessions.phase, SessionPhase.signedOut);
  });

  testWidgets(
      'recovery requests stay neutral and reset requires recovery ownership',
      (tester) async {
    final fixture = await _session();
    final repo = _PasswordRepository();
    final flow = PasswordSecurityController(fixture.sessions, repo);
    addTearDown(flow.dispose);
    await _mount(tester,
        fields: const {AuthFormField.email: 'Synthetic email'},
        submit: (input) async =>
            (await flow.forgotPassword(input[AuthFormField.email]!)).name);
    await tester.enterText(_field(AuthFormField.email), _email);
    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(find.text('requestAccepted'), findsOneWidget);
    expect(fixture.sessions.phase, SessionPhase.signedOut);

    await _mount(tester,
        fields: _passwords,
        submit: (input) async => (await flow.resetPassword(
                input[AuthFormField.password]!,
                input[AuthFormField.passwordConfirmation]!))
            .name);
    await _fillPasswordPair(tester);
    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(find.text('recoveryRequired'), findsOneWidget);
    expect(repo.updates, isEmpty);

    fixture.source.publish(SessionEventKind.recovery);
    await tester.pumpAndSettle();
    await _fillPasswordPair(tester, 'synthetic-mismatch');
    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(find.text('passwordMismatch'), findsOneWidget);
    await _fillPasswordPair(tester);
    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(find.text('passwordUpdated'), findsOneWidget);
    expect(repo.updates, [PasswordOperation.reset]);
    expect(fixture.sessions.phase, SessionPhase.recovery);
    expect(fixture.sessions.backendSession, isNull);
  });

  testWidgets(
      'change-password surfaces reauthentication and clears password fields',
      (tester) async {
    final fixture = await _session();
    fixture.source.publish(SessionEventKind.signedIn);
    await tester.pump();
    final repo = _PasswordRepository()
      ..outcome = PasswordOutcome.reauthenticationRequired;
    final flow = PasswordSecurityController(fixture.sessions, repo);
    addTearDown(flow.dispose);
    await _mount(tester,
        fields: _passwords,
        submit: (input) async => (await flow.changePassword(
                input[AuthFormField.password]!,
                confirmation: input[AuthFormField.passwordConfirmation]))
            .name);
    await _fillPasswordPair(tester);
    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(find.text('reauthenticationRequired'), findsOneWidget);
    expect(repo.updates, [PasswordOperation.change]);
    expect(fixture.sessions.subject, 'subject');
    expect(
        tester
            .widget<TextField>(_field(AuthFormField.password))
            .controller!
            .text,
        isEmpty);
  });

  testWidgets('logout removes app access before cleanup and displays failure',
      (tester) async {
    final fixture = await _session();
    fixture.source.publish(SessionEventKind.signedIn);
    await tester.pump();
    final boundary = _LogoutBoundary(fixture.source);
    final flow =
        OfflineCurrentDeviceLogout.forContractTests(fixture.sessions, boundary);
    addTearDown(flow.dispose);
    await _mount(tester,
        fields: const {}, submit: (_) async => (await flow.run()).name);
    await tester.tap(_submit);
    await tester.pump();
    expect(fixture.sessions.backendSession, isNull);
    expect(find.text('Synthetic pending'), findsOneWidget);
    boundary.cleanup.complete(LogoutCleanup.failed);
    await tester.pumpAndSettle();
    expect(find.text('cleanupFailed'), findsOneWidget);
    expect(find.text('signedOut'), findsNothing);
  });

  testWidgets('mock Google action is single-flight and handles cancellation',
      (tester) async {
    final fixture = await _session();
    final repository = _GoogleRepository();
    final flow = GoogleAuthController(
        repository, fixture.sessions, InteractiveSessionAdmission());
    addTearDown(flow.dispose);
    await _mount(tester,
        fields: const {}, submit: (_) async => (await flow.signIn()).name);
    await tester.tap(_submit);
    await tester.tap(_submit);
    await tester.pump();
    expect(repository.calls, 1);
    expect(fixture.sessions.backendSession, isNull);
    repository.response
        .complete(const GoogleAuthResult(GoogleAuthState.cancelled));
    await tester.pumpAndSettle();
    expect(find.text('cancelled'), findsOneWidget);
    expect(fixture.sessions.phase, SessionPhase.signedOut);
  });

  testWidgets(
      'small host can scroll to action and unexpected errors are redacted',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 180);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var calls = 0;
    await _mount(tester,
        fields: {..._credentials, ..._passwords},
        enabled: false, submit: (_) async {
      calls++;
      return 'Unexpected';
    });
    expect(tester.widget<FilledButton>(_submit).onPressed, isNull);
    await _mount(tester, fields: {..._credentials, ..._passwords},
        submit: (_) async {
      calls++;
      throw StateError('SYNTHETIC_PRIVATE_VALUE');
    });
    await tester.ensureVisible(_submit);
    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Synthetic unavailable'), findsOneWidget);
    expect(find.textContaining('SYNTHETIC_PRIVATE_VALUE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending action can be disposed without a stale UI update',
      (tester) async {
    final result = Completer<String>();
    await _mount(tester, fields: const {}, submit: (_) => result.future);
    await tester.tap(_submit);
    await tester.pump();
    expect(find.text('Synthetic pending'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    result.complete('Stale outcome');
    await tester.pumpAndSettle();
    expect(find.text('Stale outcome'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
