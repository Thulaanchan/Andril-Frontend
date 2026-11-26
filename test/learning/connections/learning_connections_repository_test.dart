import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/connections/data/repositories/learning_connections_repository.dart';
import 'package:andril_mobile/features/learning/connections/domain/repositories/i_learning_connections_repository.dart';

void main() {
  group('LearningConnectionsRepository Tests (Fail-Closed Governance)', () {
    test(
        'returns serviceUnavailable with disconnectedNotice by default (dormant backend)',
        () async {
      const repo = LearningConnectionsRepository(isBackendActivated: false);

      final connsResult = await repo.getConnections();
      expect(connsResult.isFailure, isTrue);
      expect(connsResult.failureType,
          equals(LearningConnectionsFailureType.serviceUnavailable));
      expect(
          connsResult.errorMessage,
          equals(
              'Remote connections backend contract pending in OpenAPI v1. Operating in local presentation mode.'));

      final incomingResult = await repo.getIncomingRequests();
      expect(incomingResult.isFailure, isTrue);
      expect(incomingResult.failureType,
          equals(LearningConnectionsFailureType.serviceUnavailable));

      final outgoingResult = await repo.getOutgoingRequests();
      expect(outgoingResult.isFailure, isTrue);
      expect(outgoingResult.failureType,
          equals(LearningConnectionsFailureType.serviceUnavailable));
    });

    test('validates recipientProfileId on sendRequest', () async {
      const repo = LearningConnectionsRepository(isBackendActivated: false);

      final result = await repo.sendRequest(
        recipientProfileId: '   ',
        recipientDisplayName: 'Valid Name',
      );
      expect(result.isFailure, isTrue);
      expect(result.failureType,
          equals(LearningConnectionsFailureType.badRequest));
      expect(result.errorMessage, equals('Invalid recipient profile ID.'));
    });

    test('validates requestId on accept, decline, and cancel', () async {
      const repo = LearningConnectionsRepository(isBackendActivated: false);

      final acceptRes = await repo.acceptRequest('');
      expect(acceptRes.failureType,
          equals(LearningConnectionsFailureType.badRequest));

      final declineRes = await repo.declineRequest('   ');
      expect(declineRes.failureType,
          equals(LearningConnectionsFailureType.badRequest));

      final cancelRes = await repo.cancelRequest('   ');
      expect(cancelRes.failureType,
          equals(LearningConnectionsFailureType.badRequest));
    });

    test('validates connectionId on removeConnection', () async {
      const repo = LearningConnectionsRepository(isBackendActivated: false);

      final result = await repo.removeConnection('  ');
      expect(result.failureType,
          equals(LearningConnectionsFailureType.badRequest));
      expect(result.errorMessage, equals('Invalid connection ID.'));
    });

    test('returns serviceUnavailable when live endpoints are not activated',
        () async {
      const repo = LearningConnectionsRepository(isBackendActivated: true);

      final connsResult = await repo.getConnections();
      expect(connsResult.isFailure, isTrue);
      expect(connsResult.failureType,
          equals(LearningConnectionsFailureType.serviceUnavailable));
    });
  });
}
