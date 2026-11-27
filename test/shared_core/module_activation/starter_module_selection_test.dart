import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/module_activation/presentation/screens/starter_module_selection_screen.dart';
import 'test_doubles/mock_starter_module_repository.dart';

void main() {
  group('Task 02.10: Starter Module Selection Tests (Screen 10)', () {
    late MockStarterModuleRepository repo;

    setUp(() {
      repo = MockStarterModuleRepository(isSocialAuthorized: true);
    });

    testWidgets('Renders all 3 starter module cards (Learning, Hobbies, Social) in carousel',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StarterModuleSelectionScreen(
            repository: repo,
            isSocialAuthorizedByServer: true,
          ),
        ),
      );
      await tester.pump();

      // Header and title
      expect(find.text('CHOOSE YOUR MODULES'), findsOneWidget);
      expect(find.text('Choose Your Path'), findsOneWidget);

      // Initial card is Learning
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('MODULE 01'), findsOneWidget);

      // Cycle to Hobbies
      await tester.tap(find.byTooltip('Next Module'));
      await tester.pump();
      expect(find.text('Hobbies'), findsOneWidget);
      expect(find.text('MODULE 02'), findsOneWidget);

      // Cycle to Social
      await tester.tap(find.byTooltip('Next Module'));
      await tester.pump();
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('MODULE 03'), findsOneWidget);
      expect(find.text('18+ ONLY'), findsOneWidget);
    });

    testWidgets('Cycling to Hobbies card and selecting updates submitted module', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: StarterModuleSelectionScreen(
            repository: repo,
            isSocialAuthorizedByServer: true,
          ),
        ),
      );
      await tester.pump();

      // Cycle to Hobbies
      await tester.tap(find.byTooltip('Next Module'));
      await tester.pump();

      // Tap Hobbies card to select
      await tester.tap(find.text('Hobbies'));
      await tester.pump();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(repo.lastSelectedModuleId, equals('hobbies'));
    });

    testWidgets('Under-18 user cycling to Social sees age advisory',
        (tester) async {
      final underageRepo = MockStarterModuleRepository(isSocialAuthorized: false);

      await tester.pumpWidget(
        MaterialApp(
          home: StarterModuleSelectionScreen(
            repository: underageRepo,
            isSocialAuthorizedByServer: false,
          ),
        ),
      );
      await tester.pump();

      // Cycle to Social
      await tester.tap(find.byTooltip('Next Module'));
      await tester.pump();
      await tester.tap(find.byTooltip('Next Module'));
      await tester.pump();

      expect(find.text('Social'), findsOneWidget);
      expect(find.text('18+ ONLY'), findsOneWidget);
    });
  });
}
