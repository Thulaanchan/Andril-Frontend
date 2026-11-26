import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/pacts/data/repositories/learning_pacts_repository.dart';
import 'package:andril_mobile/features/learning/pacts/domain/repositories/i_learning_pacts_repository.dart';

void main() {
  group('LearningPactsRepository', () {
    test('defaults to isBackendActivated = false (pending OpenAPI contract)',
        () {
      const repo = LearningPactsRepository();
      expect(repo.isBackendActivated, isFalse);
    });

    test('getPacts returns serviceUnavailable failure when backend is inactive',
        () async {
      const repo = LearningPactsRepository(isBackendActivated: false);
      final result = await repo.getPacts();

      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.failureType, LearningPactsFailureType.serviceUnavailable);
      expect(result.errorMessage,
          contains('Remote Pacts backend contract pending'));
    });

    test('getPactById returns serviceUnavailable when backend is inactive',
        () async {
      const repo = LearningPactsRepository(isBackendActivated: false);
      final result = await repo.getPactById('pact_1');

      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningPactsFailureType.serviceUnavailable);
    });

    test('getPactById returns validationError when pactId is empty', () async {
      const repo = LearningPactsRepository(isBackendActivated: true);
      final result = await repo.getPactById('   ');

      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningPactsFailureType.validationError);
    });

    test('proposePact returns serviceUnavailable when backend is inactive',
        () async {
      const repo = LearningPactsRepository(isBackendActivated: false);
      final result = await repo.proposePact(
        title: 'Algorithms study',
        sharedGoal: 'Solve 50 problems',
        partnerProfileId: 'partner_123',
        partnerDisplayName: 'Partner Learner',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningPactsFailureType.serviceUnavailable);
    });

    test(
        'proposePact returns validationError failure when required parameters are empty',
        () async {
      const repo = LearningPactsRepository(isBackendActivated: true);
      final result = await repo.proposePact(
        title: '   ',
        sharedGoal: 'Solve problems',
        partnerProfileId: 'p1',
        partnerDisplayName: 'Name',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningPactsFailureType.validationError);
    });

    test('acceptPact returns serviceUnavailable when backend is inactive',
        () async {
      const repo = LearningPactsRepository(isBackendActivated: false);
      final result = await repo.acceptPact('pact_1');

      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningPactsFailureType.serviceUnavailable);
    });

    test('acceptPact returns validationError when pactId is empty', () async {
      const repo = LearningPactsRepository(isBackendActivated: true);
      final result = await repo.acceptPact('  ');

      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningPactsFailureType.validationError);
    });

    test('declinePact returns serviceUnavailable when backend is inactive',
        () async {
      const repo = LearningPactsRepository(isBackendActivated: false);
      final result = await repo.declinePact('pact_1');

      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningPactsFailureType.serviceUnavailable);
    });

    test('cancelPact returns serviceUnavailable when backend is inactive',
        () async {
      const repo = LearningPactsRepository(isBackendActivated: false);
      final result = await repo.cancelPact('pact_1');

      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningPactsFailureType.serviceUnavailable);
    });

    test('withdrawPact returns serviceUnavailable when backend is inactive',
        () async {
      const repo = LearningPactsRepository(isBackendActivated: false);
      final result = await repo.withdrawPact('pact_1');

      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningPactsFailureType.serviceUnavailable);
    });

    test(
        'confirmCompletion returns serviceUnavailable when backend is inactive',
        () async {
      const repo = LearningPactsRepository(isBackendActivated: false);
      final result = await repo.confirmCompletion('pact_1');

      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningPactsFailureType.serviceUnavailable);
    });

    test(
        'updateCommitmentProgress returns serviceUnavailable when backend is inactive',
        () async {
      const repo = LearningPactsRepository(isBackendActivated: false);
      final result = await repo.updateCommitmentProgress(
        pactId: 'pact_1',
        commitmentId: 'c1',
        isCompleted: true,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningPactsFailureType.serviceUnavailable);
    });
  });
}
