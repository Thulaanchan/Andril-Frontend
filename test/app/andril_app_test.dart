import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/andril_app.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';

import '../shared_core/authentication/foundation_fakes.dart';

void main() {
  testWidgets('starter shell identifies all three product modules',
      (tester) async {
    final source = FakeSessionSource();
    final controller = SessionController(source);
    await controller.start();
    await tester.pumpWidget(AndrilApp(initialize: () async => controller));
    await tester.pumpAndSettle();
    expect(find.text('Learning  •  Hobbies  •  Social'), findsOneWidget);
    expect(find.text('ANDRIL'), findsOneWidget);
    expect(find.text('Flutter folder structure scaffold'), findsOneWidget);
    expect(controller.moduleHomeAuthorized, false);
    await tester.pumpWidget(const SizedBox());
    await source.signals.close();
  });

  testWidgets('missing configuration shows a safe state without starting SDK',
      (tester) async {
    await tester.pumpWidget(const AndrilApp());
    await tester.pumpAndSettle();
    expect(find.text('Authentication configuration required.'), findsOneWidget);
    expect(find.text('Flutter folder structure scaffold'), findsNothing);
  });

  testWidgets('bootstrap shows loading until initialization completes',
      (tester) async {
    final pending = Completer<SessionController>();
    await tester.pumpWidget(AndrilApp(initialize: () => pending.future));
    expect(find.bySemanticsLabel('Restoring authentication'), findsOneWidget);
    final source = FakeSessionSource();
    final controller = SessionController(source);
    await controller.start();
    pending.complete(controller);
    await tester.pumpAndSettle();
    expect(find.text('Flutter folder structure scaffold'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await source.signals.close();
  });

  testWidgets('private exception data never appears in UI or debug output',
      (tester) async {
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      logs.add(message ?? '');
    };
    try {
      await tester.pumpWidget(AndrilApp(initialize: () async {
        throw StateError('SYNTHETIC_PRIVATE_TOKEN');
      }));
      await tester.pumpAndSettle();
      expect(find.text('Authentication setup unavailable.'), findsOneWidget);
      expect(find.textContaining('SYNTHETIC_PRIVATE_TOKEN'), findsNothing);
      expect(logs.join(), isNot(contains('SYNTHETIC_PRIVATE_TOKEN')));
    } finally {
      debugPrint = original;
    }
  });

  testWidgets('recovery is gated and never displays the ordinary scaffold',
      (tester) async {
    final source = FakeSessionSource(
        restored: const SessionEvent(SessionEventKind.initial, subject: 'A'))
      ..restoredRecovery = true;
    final controller = SessionController(source);
    await controller.start();
    await tester.pumpWidget(AndrilApp(initialize: () async => controller));
    await tester.pumpAndSettle();
    expect(find.text('Password recovery requires the approved recovery flow.'),
        findsOneWidget);
    expect(find.text('Flutter folder structure scaffold'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await source.signals.close();
  });

  testWidgets('late bootstrap after app disposal releases its subscription',
      (tester) async {
    final pending = Completer<SessionController>();
    await tester.pumpWidget(AndrilApp(initialize: () => pending.future));
    await tester.pumpWidget(const SizedBox());
    final source = FakeSessionSource();
    final controller = SessionController(source);
    await controller.start();
    final oldGeneration = controller.generation;
    pending.complete(controller);
    await tester.pump();
    expect(controller.isCurrent(oldGeneration), false);
    expect(source.cancellations, 1);
    await source.signals.close();
  });
}
