import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/module_activation/domain/entities/starter_selection_result.dart';
import 'package:andril_mobile/shared_core/module_activation/presentation/screens/starter_module_selection_screen.dart';
import 'package:andril_mobile/shared_core/module_activation/presentation/viewmodels/starter_module_viewmodel.dart';
import 'test_doubles/mock_starter_module_repository.dart';

void main() {
  group('StarterModuleViewModel Unit Tests', () {
    late MockStarterModuleRepository repo;
    late StarterModuleViewModel vm;

    setUp(() {
      repo = MockStarterModuleRepository(isSocialAuthorized: true);
      vm = StarterModuleViewModel(
        repository: repo,
        isSocialAuthorizedByServer: true,
      );
    });

    tearDown(() {
      vm.dispose();
    });

    test('Initial selection defaults to Learning (Module 01)', () {
      expect(vm.modules.length, equals(3));
      expect(vm.selectedModule.id, equals('learning'));
      expect(vm.selectedModule.title, equals('Learning'));
      expect(vm.isTourMode, isFalse);
    });

    test('Selecting Hobbies card directly updates selection without modal', () {
      vm.selectModuleIndex(1); // Hobbies

      expect(vm.selectedModuleIndex, equals(1));
      expect(vm.selectedModule.id, equals('hobbies'));
      expect(vm.isSocialModalOpen, isFalse);
    });

    test('Selecting Social triggers 18+ verification modal requirement', () {
      vm.selectModuleIndex(2); // Social

      expect(vm.isSocialModalOpen, isTrue);
      expect(vm.socialConsentChecked, isFalse);

      // Confirming without checkbox fails
      vm.confirmSocialSelection();
      expect(vm.errorMessage, contains('confirm the 18+ agreement'));
      expect(vm.selectedModuleIndex, isNot(equals(2)));

      // Checking consent and confirming succeeds
      vm.setSocialConsentChecked(true);
      vm.confirmSocialSelection();
      expect(vm.isSocialModalOpen, isFalse);
      expect(vm.selectedModuleIndex, equals(2));
      expect(vm.selectedModule.id, equals('social'));
    });

    test('Rejects Social selection when server flags user as under 18', () {
      final underageVm = StarterModuleViewModel(
        repository: repo,
        isSocialAuthorizedByServer: false,
      );

      underageVm.selectModuleIndex(2); // Social
      expect(underageVm.errorMessage, contains('restricted to members aged 18'));
      expect(underageVm.isSocialModalOpen, isFalse);
      expect(underageVm.selectedModuleIndex, equals(0)); // Stays Learning

      underageVm.dispose();
    });

    test('Submitting starter selection completes without lifecycle activation (Rule 05 & 06)',
        () async {
      vm.selectModuleIndex(1); // Hobbies

      StarterSelectionResult? result;
      await vm.submitStarterSelection(
        onCompleted: (r) => result = r,
      );

      expect(result, isNotNull);
      expect(result!.isSuccess, isTrue);
      expect(result!.selectedModuleId, equals('hobbies'));
      // Returns next onboarding step ('profile_setup') rather than full activation
      expect(result!.nextStep, equals('profile_setup'));
      expect(repo.lastSelectedModuleId, equals('hobbies'));
    });
  });

  group('StarterModuleSelectionScreen Widget Tests', () {
    late MockStarterModuleRepository repo;

    setUp(() {
      repo = MockStarterModuleRepository();
    });

    testWidgets('Renders all finalized visual elements on Screen 10',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StarterModuleSelectionScreen(repository: repo),
        ),
      );
      await tester.pump();

      // Header Badge & Headings
      expect(find.text('CHOOSE YOUR MODULES'), findsOneWidget);
      expect(find.text('Choose Your Path'), findsOneWidget);
      expect(
        find.text('Choose one module to start your ANDRIL experience.'),
        findsOneWidget,
      );

      // Tour Mode Pill
      expect(find.text('Preview Tour'), findsOneWidget);

      // Carousel Arrows
      expect(find.byTooltip('Previous Module'), findsOneWidget);
      expect(find.byTooltip('Next Module'), findsOneWidget);

      // Initial card is Learning
      expect(find.text('Learning'), findsOneWidget);
      expect(find.textContaining('Selected:'), findsOneWidget);
      expect(find.text('MODULE 01'), findsOneWidget);
      expect(find.text('Skill Paths & Mentorship'), findsOneWidget);

      // Bottom info banner & button
      expect(find.text('Choose one module to get started.'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('Cycling cards using carousel arrows navigates modules',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StarterModuleSelectionScreen(repository: repo),
        ),
      );
      await tester.pump();

      // Tap Next Module
      await tester.tap(find.byTooltip('Next Module'));
      await tester.pump();

      // Shows Hobbies (Module 02)
      expect(find.text('MODULE 02'), findsOneWidget);
      expect(find.text('Creative & Sports'), findsOneWidget);

      // Tap Next Module again
      await tester.tap(find.byTooltip('Next Module'));
      await tester.pump();

      // Shows Social (Module 03)
      expect(find.text('MODULE 03'), findsOneWidget);
      expect(find.text('18+ ONLY'), findsOneWidget);
    });
  });
}
