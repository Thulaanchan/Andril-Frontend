import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/security/session/session_controller.dart';
import 'repositories/auth_repository.dart';

/// Holds only transient flow state. The existing session controller classifies
/// provider events and the existing account handoff observes that controller.
class EmailAuthController extends ChangeNotifier {
  EmailAuthController(this._repository, this._session,
      {Duration sessionWait = const Duration(seconds: 8)})
      : _sessionWait = sessionWait {
    _session.addListener(_observe);
  }

  final AuthRepository _repository;
  final SessionController _session;
  final Duration _sessionWait;
  String? _verificationEmail;
  BackendSession? _authenticatedOwner;
  bool _busy = false;
  bool _disposed = false;
  int _attempt = 0;
  int? _startingGeneration;
  VoidCallback? _settle;
  EmailAuthOutcome _outcome = const EmailAuthOutcome(EmailAuthState.idle);

  bool get busy => _busy;
  bool get awaitingVerification => _verificationEmail != null;
  EmailAuthOutcome get outcome => _outcome;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)+$');
  static final _otpPattern = RegExp(r'^[0-9]{6}$');

  Future<EmailAuthOutcome> register(String email, String password,
          {String? passwordConfirmation}) =>
      _credentials(email, password,
          registration: true, passwordConfirmation: passwordConfirmation);

  Future<EmailAuthOutcome> signIn(String email, String password) =>
      _credentials(email, password, registration: false);

  Future<EmailAuthOutcome> _credentials(String email, String password,
      {required bool registration, String? passwordConfirmation}) {
    final blocked = _blocked();
    if (blocked != null) return Future.value(blocked);
    final address = email.trim();
    if (address.isEmpty || _emailPattern.stringMatch(address) != address) {
      return Future.value(_reject(EmailAuthIssue.invalidEmail));
    }
    if (password.isEmpty) {
      return Future.value(_reject(EmailAuthIssue.passwordRequired));
    }
    if (passwordConfirmation != null && password != passwordConfirmation) {
      return Future.value(_reject(EmailAuthIssue.passwordMismatch));
    }
    _verificationEmail = null;
    return _run(
      () => registration
          ? _repository.register(address, password)
          : _repository.signIn(address, password),
      address: address,
      pendingWithoutSession: registration,
    );
  }

  Future<EmailAuthOutcome> verifyCode(String code) {
    final blocked = _blocked();
    if (blocked != null) return Future.value(blocked);
    final email = _verificationEmail;
    if (email == null) return Future.value(_reject(EmailAuthIssue.invalidFlow));
    if (_otpPattern.stringMatch(code) != code) {
      return Future.value(_reject(EmailAuthIssue.invalidOrExpiredCode));
    }
    return _run(() => _repository.verifySignupCode(email, code),
        address: email);
  }

  Future<EmailAuthOutcome> resendCode() {
    final blocked = _blocked();
    if (blocked != null) return Future.value(blocked);
    final email = _verificationEmail;
    if (email == null) return Future.value(_reject(EmailAuthIssue.invalidFlow));
    return _run(() => _repository.resendSignupCode(email),
        address: email, pendingWithoutSession: true, expectsSession: false);
  }

  EmailAuthOutcome? _blocked() {
    if (_disposed) return _failure(EmailAuthIssue.sessionChanged);
    if (_busy) return _failure(EmailAuthIssue.busy);
    return _session.phase == SessionPhase.signedOut
        ? null
        : _reject(EmailAuthIssue.invalidFlow);
  }

  static EmailAuthOutcome _failure(EmailAuthIssue issue) =>
      EmailAuthOutcome(EmailAuthState.failed, issue: issue);

  EmailAuthOutcome _reject(EmailAuthIssue issue) {
    _outcome = _failure(issue);
    notifyListeners();
    return _outcome;
  }

  Future<EmailAuthOutcome> _run(Future<AuthRepositoryResult> Function() submit,
      {required String address,
      bool pendingWithoutSession = false,
      bool expectsSession = true}) async {
    final attempt = ++_attempt;
    _startingGeneration = _session.generation;
    _busy = true;
    notifyListeners();
    const pending = EmailAuthOutcome(EmailAuthState.verificationPending);
    final changed = _failure(EmailAuthIssue.sessionChanged);
    try {
      if (!_active(attempt)) return changed;
      final result = await submit();
      if (!_active(attempt)) return changed;
      final issue = result.issue;
      final receipt = result.session;
      if (receipt != null && expectsSession && issue == null) {
        final confirmed = await _waitForSession(attempt, receipt);
        if (!_active(attempt)) return changed;
        if (!confirmed) {
          return _outcome = _failure(EmailAuthIssue.confirmationRequired);
        }
        _verificationEmail = null;
        _authenticatedOwner = _session.backendSession;
        return _outcome = const EmailAuthOutcome(EmailAuthState.authenticated);
      }
      if (_session.phase != SessionPhase.signedOut) return changed;
      if (issue == EmailAuthIssue.confirmationRequired ||
          (issue == null && receipt == null && pendingWithoutSession)) {
        _verificationEmail = address;
        return _outcome = pending;
      }
      return _outcome = _failure(issue ?? EmailAuthIssue.confirmationRequired);
    } catch (_) {
      if (!_active(attempt)) return changed;
      return _outcome = _failure(EmailAuthIssue.unavailable);
    } finally {
      _busy = false;
      _startingGeneration = null;
      if (!_disposed) notifyListeners();
    }
  }

  bool _active(int attempt) => !_disposed && attempt == _attempt;

  Future<bool> _waitForSession(int attempt, AuthSessionReceipt receipt) async {
    final result = Completer<bool>();
    void check() {
      if (result.isCompleted) return;
      if (!_active(attempt)) {
        result.complete(false);
        return;
      }
      final owner = _session.backendSession;
      if (owner == null) return;
      final credential = _session.credentialFor(owner);
      result.complete(_session.generation != _startingGeneration &&
          credential != null &&
          receipt.recognizes(owner, credential));
    }

    _settle = check;
    try {
      check();
      return await result.future.timeout(_sessionWait, onTimeout: () => false);
    } finally {
      _settle = null;
    }
  }

  void _observe() {
    final start = _startingGeneration;
    final phase = _session.phase;
    if (phase == SessionPhase.recovery ||
        phase == SessionPhase.unavailable ||
        (phase == SessionPhase.signedOut &&
            start != null &&
            _session.generation != start)) {
      cancel();
      return;
    }
    final owner = _authenticatedOwner;
    if (owner != null &&
        (phase == SessionPhase.signedOut ||
            (phase == SessionPhase.signedIn &&
                _session.backendSession != owner))) {
      cancel();
      return;
    }
    if (phase == SessionPhase.signedIn && !_busy && awaitingVerification) {
      cancel();
      return;
    }
    _settle?.call();
  }

  /// Scrubs the pending verification destination and invalidates results.
  /// Keeps the submission lock until any outstanding provider call settles.
  void cancel() {
    if (_disposed) return;
    ++_attempt;
    _startingGeneration = null;
    _verificationEmail = null;
    _authenticatedOwner = null;
    _outcome = const EmailAuthOutcome(EmailAuthState.idle);
    _settle?.call();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _verificationEmail = null;
    _session.removeListener(_observe);
    _settle?.call();
    super.dispose();
  }
}
