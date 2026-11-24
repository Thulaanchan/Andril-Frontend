import 'dart:async';

import 'package:andril_mobile/app/andril_app.dart';
import 'package:andril_mobile/app/bootstrap/scaffold_home.dart';
import 'package:andril_mobile/app/router/learning_router.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/profile/screens/learning_welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../shared_core/authentication/foundation_fakes.dart';

void main() {
  testWidgets(
      'starter mode keeps its theme and provides one session controller',
      (tester) async {
    final source = FakeSessionSource();
    final controller = SessionController(source);
    var calls = 0;
    await tester.pumpWidget(AndrilApp.starterShell(initialize: () async {
      calls++;
      await controller.start();
      return controller;
    }));
    await tester.pumpAndSettle();

    final scaffold = tester.element(find.byType(ScaffoldHome));
    expect(scaffold.read<SessionController>(), same(controller));
    expect(Theme.of(scaffold).colorScheme,
        ColorScheme.fromSeed(seedColor: const Color(0xFF364B66)));
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'A'));
    await tester.pumpAndSettle();
    expect(find.byType(ScaffoldHome), findsOneWidget);
    expect(calls, 1);
    expect(source.listens, 1);
    await tester.pumpWidget(const SizedBox());
    expect(source.cancellations, 1);
    await source.signals.close();
  });

  testWidgets('routed startup keeps one bootstrap, Provider and Learning theme',
      (
    tester,
  ) async {
    final source = FakeSessionSource();
    final controller = SessionController(source);
    final router = createLearningRouter(initialLocation: '/learning/home');
    final bootstrap = Completer<SessionController>();
    var calls = 0;
    Future<SessionController> initialize() {
      calls++;
      return bootstrap.future;
    }

    await tester
        .pumpWidget(AndrilApp(routerConfig: router, initialize: initialize));
    expect(find.bySemanticsLabel('Restoring authentication'), findsOneWidget);
    expect(find.byType(Navigator), findsNothing);

    await controller.start();
    bootstrap.complete(controller);
    await tester.pumpAndSettle();
    final welcome = find.byType(LearningWelcomeScreen);
    expect(welcome, findsOneWidget);
    expect(controller.phase, SessionPhase.signedOut);
    expect(tester.element(welcome).read<SessionController>(), same(controller));
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig,
        same(router));
    expect(Theme.of(tester.element(welcome)).colorScheme.primary,
        LearningTheme.theme.colorScheme.primary);

    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'A'));
    await tester.pumpAndSettle();
    expect(controller.phase, SessionPhase.signedIn);
    expect(controller.moduleHomeAuthorized, isFalse);
    router.go('/learning/home');
    await tester.pumpAndSettle();
    expect(welcome, findsOneWidget);
    expect(find.text('Learning Home'), findsNothing);

    router.go('/learning/access-denied');
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    final refresh = Completer<SessionResolution>();
    source.pending['A'] = refresh;
    source.signals
        .add(const SessionEvent(SessionEventKind.refreshed, subject: 'A'));
    await tester.pump();
    expect(
        tester.state<NavigatorState>(find.byType(Navigator)), same(navigator));
    refresh.complete(const SessionResolution('A', recovery: false));
    await tester.pumpAndSettle();
    expect(
        tester.state<NavigatorState>(find.byType(Navigator)), same(navigator));
    expect(router.routeInformationProvider.value.uri.path,
        '/learning/access-denied');

    var privateStateClears = 0;
    controller.registerPrivateStateClearer(() => privateStateClears++);
    source.signals.add(const SessionEvent(SessionEventKind.signedOut));
    await tester.pumpAndSettle();
    expect(privateStateClears, 1);
    expect(controller.subject, isNull);
    expect(controller.phase, SessionPhase.signedOut);
    expect(calls, 1);
    expect(source.listens, 1);
    await tester.pumpWidget(const SizedBox());
    expect(source.cancellations, 1);
    router.dispose();
    await source.signals.close();
  });

  testWidgets('recovery and auth stream failure remove routed content',
      (tester) async {
    final source = FakeSessionSource();
    final controller = SessionController(source);
    final router = createLearningRouter();
    await controller.start();
    await tester.pumpWidget(
        AndrilApp(routerConfig: router, initialize: () async => controller));
    await tester.pumpAndSettle();
    expect(find.byType(LearningWelcomeScreen), findsOneWidget);

    source.signals
        .add(const SessionEvent(SessionEventKind.recovery, subject: 'A'));
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'A'));
    await tester.pumpAndSettle();
    expect(controller.phase, SessionPhase.recovery);
    expect(find.text('Password recovery requires the approved recovery flow.'),
        findsOneWidget);
    expect(find.byType(Navigator), findsNothing);

    source.signals.addError(StateError('synthetic private detail'));
    await tester.pumpAndSettle();
    expect(find.text('Authentication session unavailable.'), findsOneWidget);
    expect(find.textContaining('synthetic private detail'), findsNothing);
    expect(find.byType(Navigator), findsNothing);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await source.signals.close();
  });

  testWidgets('configuration and bootstrap errors block the supplied router',
      (tester) async {
    final router = createLearningRouter();
    for (final (error, message) in [
      (
        const ConfigurationException(),
        'Authentication configuration required.'
      ),
      (
        StateError('synthetic private detail'),
        'Authentication setup unavailable.'
      ),
    ]) {
      await tester.pumpWidget(AndrilApp(
        key: ValueKey(message),
        routerConfig: router,
        initialize: () async => throw error,
      ));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(find.byType(Navigator), findsNothing);
    }
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });

  testWidgets('account switch removes navigation and ignores a late refresh',
      (tester) async {
    final source = FakeSessionSource(
      restored: const SessionEvent(SessionEventKind.initial, subject: 'A'),
    );
    final controller = SessionController(source);
    final router = createLearningRouter();
    await controller.start();
    await tester.pumpWidget(
        AndrilApp(routerConfig: router, initialize: () async => controller));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    var privateData = 'account A';
    controller.registerPrivateStateClearer(() => privateData = '');
    final oldRefresh = Completer<SessionResolution>();
    final nextAccount = Completer<SessionResolution>();
    source.pending['A'] = oldRefresh;
    source.pending['B'] = nextAccount;
    source.signals
        .add(const SessionEvent(SessionEventKind.refreshed, subject: 'A'));
    final oldGeneration = controller.generation;
    source.signals
        .add(const SessionEvent(SessionEventKind.signedIn, subject: 'B'));
    await tester.pump();
    expect(privateData, isEmpty);
    expect(controller.isCurrent(oldGeneration), isFalse);
    expect(find.byType(Navigator), findsNothing);
    expect(find.bySemanticsLabel('Restoring authentication'), findsOneWidget);

    nextAccount.complete(const SessionResolution('B', recovery: false));
    await tester.pumpAndSettle();
    oldRefresh.complete(const SessionResolution('A', recovery: false));
    await tester.pumpAndSettle();
    expect(controller.subject, 'B');
    expect(controller.moduleHomeAuthorized, isFalse);
    expect(tester.state<NavigatorState>(find.byType(Navigator)),
        isNot(same(navigator)));
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await source.signals.close();
  });
}
