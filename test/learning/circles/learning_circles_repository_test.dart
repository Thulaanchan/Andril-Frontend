import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/circles/data/repositories/learning_circles_repository.dart';
import 'package:andril_mobile/features/learning/circles/domain/repositories/i_learning_circles_repository.dart';

void main() {
  group('LearningCirclesRepository Tests (Fail-Closed Governance)', () {
    test(
        'returns serviceUnavailable with disconnectedNotice by default (dormant backend)',
        () async {
      const repo = LearningCirclesRepository(isBackendActivated: false);

      final discoverResult = await repo.getCircles();
      expect(discoverResult.isFailure, isTrue);
      expect(discoverResult.failureType,
          equals(LearningCirclesFailureType.serviceUnavailable));
      expect(
          discoverResult.errorMessage,
          equals(
              'Remote Groups backend contract pending in OpenAPI v1. Circles operate in local presentation mode.'));

      final myResult = await repo.getMyCircles();
      expect(myResult.isFailure, isTrue);
      expect(myResult.failureType,
          equals(LearningCirclesFailureType.serviceUnavailable));
    });

    test('validates parameters on createCircle', () async {
      const repo = LearningCirclesRepository(isBackendActivated: false);

      final result = await repo.createCircle(
        name: '   ',
        description: 'Valid Desc',
        category: 'Programming',
      );
      expect(result.isFailure, isTrue);
      expect(result.failureType, equals(LearningCirclesFailureType.badRequest));
      expect(result.errorMessage,
          equals('Circle name and description are required.'));
    });

    test('validates circleId on joinCircle and leaveCircle', () async {
      const repo = LearningCirclesRepository(isBackendActivated: false);

      final joinRes = await repo.joinCircle('');
      expect(
          joinRes.failureType, equals(LearningCirclesFailureType.badRequest));

      final leaveRes = await repo.leaveCircle('   ');
      expect(
          leaveRes.failureType, equals(LearningCirclesFailureType.badRequest));
    });

    test('validates parameters on addSharedGoal', () async {
      const repo = LearningCirclesRepository(isBackendActivated: false);

      final emptyIdRes = await repo.addSharedGoal(
        circleId: '',
        goalText: 'Valid Goal',
      );
      expect(emptyIdRes.failureType,
          equals(LearningCirclesFailureType.badRequest));

      final emptyTextRes = await repo.addSharedGoal(
        circleId: 'circle_01',
        goalText: '   ',
      );
      expect(emptyTextRes.failureType,
          equals(LearningCirclesFailureType.badRequest));
    });

    test('validates progress percent range on updateGoalProgress', () async {
      const repo = LearningCirclesRepository(isBackendActivated: false);

      final negRes = await repo.updateGoalProgress(
        circleId: 'c_01',
        goalId: 'g_01',
        progressPercent: -1,
      );
      expect(negRes.failureType, equals(LearningCirclesFailureType.badRequest));
      expect(negRes.errorMessage,
          equals('Progress percent must be between 0 and 100.'));

      final overRes = await repo.updateGoalProgress(
        circleId: 'c_01',
        goalId: 'g_01',
        progressPercent: 105,
      );
      expect(
          overRes.failureType, equals(LearningCirclesFailureType.badRequest));
    });

    test('returns serviceUnavailable when live endpoints are not activated',
        () async {
      const repo = LearningCirclesRepository(isBackendActivated: true);

      final connsResult = await repo.getCircles();
      expect(connsResult.isFailure, isTrue);
      expect(connsResult.failureType,
          equals(LearningCirclesFailureType.serviceUnavailable));
    });
  });
}
