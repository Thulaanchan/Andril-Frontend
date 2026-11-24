import 'dart:async';

import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_fakes.dart';

void main() {
  late FakeSessionSource source;
  late SessionController controller;
  setUp(() {
    source = FakeSessionSource();
    controller = SessionController(source);
  });
  tearDown(() async {
    controller.dispose();
    await source.signals.close();
  });

  test('initializing becomes signed out without granting module access',
      () async {
    expect(controller.phase, SessionPhase.restoring);
    await controller.start();
    expect(controller.phase, SessionPhase.signedOut);
    expect(controller.moduleHomeAuthorized, false);
  });

  test('valid ordinary session restoration', () async {
    source.restored =
        const SessionEvent(SessionEventKind.initial, subject: 'A');
    await controller.start();
    expect(controller.phase, SessionPhase.signedIn);
    expect(controller.subject, 'A');
    expect(controller.moduleHomeAuthorized, false);
  });

  test('restored recovery never becomes ordinary sign in', () async {
    source.restored =
        const SessionEvent(SessionEventKind.initial, subject: 'A');
    source.restoredRecovery = true;
    await controller.start();
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'A'));
    source.signals
        .add(const SessionEvent(SessionEventKind.refreshed, subject: 'A'));
    await flushSessionWork();
    expect(controller.phase, SessionPhase.recovery);
    expect(source.modes.last, true);
  });

  test('sign in then concurrent token refresh keeps the same ordinary identity',
      () async {
    await controller.start();
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'A'));
    source.signals
        .add(const SessionEvent(SessionEventKind.refreshed, subject: 'A'));
    source.signals
        .add(const SessionEvent(SessionEventKind.refreshed, subject: 'A'));
    await flushSessionWork();
    expect(controller.phase, SessionPhase.signedIn);
    expect(source.modes.skip(1), everyElement(false));
  });

  test('recovery event and subsequent signedIn remain recovery', () async {
    await controller.start();
    source.signals
        .add(const SessionEvent(SessionEventKind.recovery, subject: 'A'));
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'A'));
    await flushSessionWork();
    expect(controller.phase, SessionPhase.recovery);
    expect(controller.moduleHomeAuthorized, false);
  });

  test('sign out clears private state and invalidates stale generation',
      () async {
    source.restored =
        const SessionEvent(SessionEventKind.initial, subject: 'A');
    await controller.start();
    var privateValue = 'PRIVATE';
    controller.registerPrivateStateClearer(() => privateValue = '');
    final old = controller.generation;
    source.signals.add(const SessionEvent(SessionEventKind.signedOut));
    await flushSessionWork();
    expect(privateValue, isEmpty);
    expect(controller.isCurrent(old), false);
    expect(controller.subject, null);
    expect(controller.phase, SessionPhase.signedOut);
  });

  test('account switch clears state and ignores late previous-account result',
      () async {
    await controller.start();
    final delayed = Completer<SessionResolution>();
    source.pending['A'] = delayed;
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'A'));
    var cleared = 0;
    controller.registerPrivateStateClearer(() => cleared++);
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'B'));
    await flushSessionWork();
    delayed.complete(const SessionResolution('A', recovery: false));
    await flushSessionWork();
    expect(controller.subject, 'B');
    expect(cleared, 1);
  });

  test('late restoration cannot replace a newer sign in', () async {
    final delayed = Completer<SessionEvent>();
    source.pendingRestore = delayed.future;
    final start = controller.start();
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'B'));
    await flushSessionWork();
    delayed
        .complete(const SessionEvent(SessionEventKind.initial, subject: 'A'));
    await start;
    expect(controller.subject, 'B');
  });

  test('late sign in cannot undo logout', () async {
    await controller.start();
    final delayed = Completer<SessionResolution>();
    source.pending['A'] = delayed;
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'A'));
    source.signals.add(const SessionEvent(SessionEventKind.signedOut));
    await flushSessionWork();
    delayed.complete(const SessionResolution('A', recovery: false));
    await flushSessionWork();
    expect(controller.phase, SessionPhase.signedOut);
  });

  test('start subscribes once and disposal cancels subscription', () async {
    final first = controller.start();
    final second = controller.start();
    expect(identical(first, second), true);
    await first;
    expect(source.listens, 1);
    final generation = controller.generation;
    controller.dispose();
    expect(controller.isCurrent(generation), false);
    expect(source.cancellations, 1);
  });

  test('auth stream error clears state without exposing error contents',
      () async {
    await controller.start();
    source.signals.addError(StateError('SYNTHETIC_PRIVATE_VALUE'));
    expect(controller.phase, SessionPhase.unavailable);
    expect(controller.subject, null);
    expect(controller.toString(), isNot(contains('SYNTHETIC_PRIVATE_VALUE')));
  });

  test('resolution failure and cleanup failure both fail closed', () async {
    await controller.start();
    source.failResolution = true;
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'A'));
    await flushSessionWork();
    expect(controller.phase, SessionPhase.unavailable);
    controller.registerPrivateStateClearer(() => throw StateError('PRIVATE'));
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'B'));
    await flushSessionWork();
    expect(controller.phase, SessionPhase.unavailable);
  });

  test('storage failure invalidates pending resolution', () async {
    controller.dispose();
    final failures = StreamController<void>.broadcast(sync: true);
    controller = SessionController(source, storageFailures: failures.stream);
    await controller.start();
    final delayed = Completer<SessionResolution>();
    source.pending['A'] = delayed;
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'A'));
    failures.add(null);
    delayed.complete(const SessionResolution('A', recovery: false));
    await flushSessionWork();
    expect(controller.phase, SessionPhase.unavailable);
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'B'));
    await flushSessionWork();
    expect(controller.phase, SessionPhase.unavailable);
    await failures.close();
  });

  test('sign-in racing cold restoration cannot bypass persisted recovery',
      () async {
    final delayed = Completer<SessionEvent>();
    source.pendingRestore = delayed.future;
    source.restoredRecovery = true;
    final start = controller.start();
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'A'));
    await flushSessionWork();
    expect(source.modes.last, null);
    expect(controller.phase, SessionPhase.recovery);
    delayed
        .complete(const SessionEvent(SessionEventKind.initial, subject: 'A'));
    await start;
    expect(controller.phase, SessionPhase.recovery);
  });
}
