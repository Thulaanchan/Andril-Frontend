import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/module_activation/presentation/viewmodels/starter_module_viewmodel.dart';
import 'test_doubles/mock_starter_module_repository.dart';

void main() {
  group('Task 02.09: Social Consent Handling Tests', () {
    late MockStarterModuleRepository repo;

    setUp(() {
      repo = MockStarterModuleRepository(isSocialAuthorized: true);
    });

    test('Selecting Social (index 2) opens 18+ consent modal and does not auto-commit', () {
      final vm = StarterModuleViewModel(
        repository: repo,
        isSocialAuthorizedByServer: true,
      );

      vm.selectModuleIndex(2); // Social

      expect(vm.isSocialModalOpen, isTrue);
      expect(vm.socialConsentChecked, isFalse);
      // Selected module is still previous selection (defaults to learning)
      expect(vm.selectedModule.id, equals('learning'));

      vm.dispose();
    });

    test('Attempting to confirm Social selection without checking consent checkbox fails', () {
      final vm = StarterModuleViewModel(
        repository: repo,
        isSocialAuthorizedByServer: true,
      );

      vm.selectModuleIndex(2);
      expect(vm.isSocialModalOpen, isTrue);

      vm.confirmSocialSelection();

      expect(vm.isSocialModalOpen, isTrue);
      expect(vm.errorMessage, contains('confirm the 18+ agreement'));
      expect(vm.selectedModule.id, equals('learning'));

      vm.dispose();
    });

    test('Explicitly checking consent allows Social selection confirmation', () {
      final vm = StarterModuleViewModel(
        repository: repo,
        isSocialAuthorizedByServer: true,
      );

      vm.selectModuleIndex(2);
      vm.setSocialConsentChecked(true);
      vm.confirmSocialSelection();

      expect(vm.isSocialModalOpen, isFalse);
      expect(vm.selectedModuleIndex, equals(2));
      expect(vm.selectedModule.id, equals('social'));
      expect(vm.errorMessage, isNull);

      vm.dispose();
    });

    test('Closing Social consent modal leaves selection at previous module', () {
      final vm = StarterModuleViewModel(
        repository: repo,
        isSocialAuthorizedByServer: true,
      );

      vm.selectModuleIndex(2);
      expect(vm.isSocialModalOpen, isTrue);

      vm.closeSocialModal();

      expect(vm.isSocialModalOpen, isFalse);
      expect(vm.selectedModuleIndex, equals(0));
      expect(vm.selectedModule.id, equals('learning'));

      vm.dispose();
    });

    test('Submitting Social transmits socialConsentConfirmed true', () async {
      final vm = StarterModuleViewModel(
        repository: repo,
        isSocialAuthorizedByServer: true,
      );

      vm.selectModuleIndex(2);
      vm.setSocialConsentChecked(true);
      vm.confirmSocialSelection();

      await vm.submitStarterSelection(onCompleted: (_) {});

      expect(repo.lastSelectedModuleId, equals('social'));
      expect(repo.lastSocialConsentConfirmed, isTrue);

      vm.dispose();
    });

    test('No consent leakage: Selecting Learning or Hobbies does not send social consent', () async {
      final vm = StarterModuleViewModel(
        repository: repo,
        isSocialAuthorizedByServer: true,
      );

      // Select Learning
      vm.selectModuleIndex(0);
      await vm.submitStarterSelection(onCompleted: (_) {});
      expect(repo.lastSelectedModuleId, equals('learning'));
      expect(repo.lastSocialConsentConfirmed, isFalse);

      // Select Hobbies
      vm.selectModuleIndex(1);
      await vm.submitStarterSelection(onCompleted: (_) {});
      expect(repo.lastSelectedModuleId, equals('hobbies'));
      expect(repo.lastSocialConsentConfirmed, isFalse);

      vm.dispose();
    });

    test('Server-restricted user (<18) is rejected immediately without showing modal', () {
      final vm = StarterModuleViewModel(
        repository: repo,
        isSocialAuthorizedByServer: false,
      );

      vm.selectModuleIndex(2);

      expect(vm.isSocialModalOpen, isFalse);
      expect(vm.selectedModuleIndex, equals(0));
      expect(vm.errorMessage, contains('restricted to members aged 18 and older'));

      vm.dispose();
    });
  });
}
