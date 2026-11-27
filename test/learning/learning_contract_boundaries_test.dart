import 'package:andril_mobile/features/learning/learning_contract_boundaries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearningContractBoundaries', () {
    test('contains all 7 required feature areas', () {
      expect(LearningContractBoundaries.all.length, 7);
    });

    test('ready features have approved endpoints documented', () {
      final ready = LearningContractBoundaries.all
          .where((b) => b.isBackendReady)
          .toList();

      expect(ready.length, 2);
      expect(ready.any((b) => b.featureArea.contains('Profile')), isTrue);
      expect(ready.any((b) => b.featureArea.contains('CV Project Import')),
          isTrue);

      for (final feature in ready) {
        expect(feature.approvedEndpoints, isNotNull);
        expect(feature.approvedEndpoints!.isNotEmpty, isTrue);
      }
    });

    test('blocked features have dependency owners and blockers recorded', () {
      final blocked = LearningContractBoundaries.all
          .where((b) => !b.isBackendReady)
          .toList();

      expect(blocked.length, 5);

      for (final feature in blocked) {
        expect(feature.dependencyOwner, isNotNull);
        expect(feature.dependencyOwner!.isNotEmpty, isTrue);
        expect(feature.blockerDetails, isNotNull);
        expect(feature.blockerDetails!.isNotEmpty, isTrue);
      }
    });

    test('AI Chat Box is explicitly identified as dormant and blocked', () {
      final ai = LearningContractBoundaries.aiChatBox;
      expect(ai.isBackendReady, isFalse);
      expect(ai.dependencyOwner, contains('AI Team'));
      expect(ai.blockerDetails, contains('[NonController]'));
    });
  });
}
