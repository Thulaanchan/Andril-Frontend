import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/discovery/data/repositories/learning_discovery_repository.dart';
import 'package:andril_mobile/features/learning/discovery/domain/repositories/i_learning_discovery_repository.dart';

void main() {
  group('LearningDiscoveryRepository Architectural Invariant Tests', () {
    test('fails closed when backend contract is not activated', () async {
      const repository = LearningDiscoveryRepository(isBackendActivated: false);

      final result = await repository.getCandidates();

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.data, isNull);
      expect(result.failureType,
          equals(LearningDiscoveryFailureType.serviceUnavailable));
      expect(
        result.errorMessage,
        contains('Remote discovery backend contract pending in OpenAPI v1'),
      );
    });

    test(
        'validates pagination bounds and returns badRequest for negative offset',
        () async {
      const repository = LearningDiscoveryRepository(isBackendActivated: true);

      final result = await repository.getCandidates(offset: -1);

      expect(result.isFailure, isTrue);
      expect(
          result.failureType, equals(LearningDiscoveryFailureType.badRequest));
      expect(result.errorMessage, contains('Invalid pagination arguments'));
    });

    test(
        'validates pagination bounds and returns badRequest for zero or negative limit',
        () async {
      const repository = LearningDiscoveryRepository(isBackendActivated: true);

      final result = await repository.getCandidates(limit: 0);

      expect(result.isFailure, isTrue);
      expect(
          result.failureType, equals(LearningDiscoveryFailureType.badRequest));
    });

    test(
        'returns serviceUnavailable when activated but backend endpoint is not yet live',
        () async {
      const repository = LearningDiscoveryRepository(isBackendActivated: true);

      final result = await repository.getCandidates();

      expect(result.isFailure, isTrue);
      expect(result.failureType,
          equals(LearningDiscoveryFailureType.serviceUnavailable));
      expect(result.errorMessage, contains('currently unavailable'));
    });
  });
}
