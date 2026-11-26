import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/circles/domain/entities/learning_circle.dart';

void main() {
  group('LearningCircle Domain Entity Tests (LRN-02 / CF-07)', () {
    test('creates valid LearningCircle with default values and invariants', () {
      final circle = LearningCircle.create(
        id: 'circle_001',
        name: 'Flutter Architecture Circle',
        description: 'Collaborative peer group studying clean architecture.',
        category: 'Programming',
        facilitatorProfileId: 'prof_fac_1',
        facilitatorDisplayName: 'Kavitha Dev',
        goals: [
          CircleSharedGoal(
            id: 'g_01',
            circleId: 'circle_001',
            text: 'Finish MVVM refactor',
            progressPercent: 50,
          ),
        ],
      );

      expect(circle.id, equals('circle_001'));
      expect(circle.name, equals('Flutter Architecture Circle'));
      expect(circle.module, equals('learning'));
      expect(circle.category, equals('Programming'));
      expect(circle.facilitatorProfileId, equals('prof_fac_1'));
      expect(circle.facilitatorDisplayName, equals('Kavitha Dev'));
      expect(circle.memberCount, equals(1));
      expect(circle.membershipRole, equals(CircleMembershipRole.none));
      expect(circle.canJoin, isTrue);
      expect(circle.isMember, isFalse);
      expect(circle.isFacilitator, isFalse);
      expect(circle.goals.length, equals(1));
      expect(circle.averageGoalProgress, equals(50.0));
      expect(circle.isDiscoverable, isTrue);
    });

    test('rejects empty or whitespace-only required parameters', () {
      expect(
        () => LearningCircle.create(
          id: '   ',
          name: 'Name',
          description: 'Desc',
          category: 'Cat',
          facilitatorProfileId: 'f_01',
          facilitatorDisplayName: 'F Name',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningCircle.create(
          id: 'c_01',
          name: '  ',
          description: 'Desc',
          category: 'Cat',
          facilitatorProfileId: 'f_01',
          facilitatorDisplayName: 'F Name',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningCircle.create(
          id: 'c_01',
          name: 'Name',
          description: '   ',
          category: 'Cat',
          facilitatorProfileId: 'f_01',
          facilitatorDisplayName: 'F Name',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningCircle.create(
          id: 'c_01',
          name: 'Name',
          description: 'Desc',
          category: 'Cat',
          facilitatorProfileId: '   ',
          facilitatorDisplayName: 'F Name',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningCircle.create(
          id: 'c_01',
          name: 'Name',
          description: 'Desc',
          category: 'Cat',
          facilitatorProfileId: 'f_01',
          facilitatorDisplayName: '   ',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningCircle.create(
          id: 'c_01',
          name: 'Name',
          description: 'Desc',
          category: 'Cat',
          facilitatorProfileId: 'f_01',
          facilitatorDisplayName: 'F Name',
          memberCount: -1,
        ),
        throwsArgumentError,
      );
    });

    test('CircleSharedGoal enforces 0..100 self-reported progress range', () {
      final validGoal = CircleSharedGoal(
        id: 'g_01',
        circleId: 'c_01',
        text: 'Valid Goal',
        progressPercent: 75,
      );
      expect(validGoal.progressPercent, equals(75));
      expect(validGoal.isCompleted, isFalse);

      final completedGoal = CircleSharedGoal(
        id: 'g_02',
        circleId: 'c_01',
        text: 'Completed Goal',
        progressPercent: 100,
      );
      expect(completedGoal.isCompleted, isTrue);

      expect(
        () => CircleSharedGoal(
          id: 'g_err',
          circleId: 'c_01',
          text: 'Negative',
          progressPercent: -5,
        ),
        throwsA(isA<ArgumentOutOfRangeException>()),
      );

      expect(
        () => CircleSharedGoal(
          id: 'g_err2',
          circleId: 'c_01',
          text: 'Over 100',
          progressPercent: 101,
        ),
        throwsA(isA<ArgumentOutOfRangeException>()),
      );
    });

    test('CircleMembershipRole.parse safely parses strings and defaults', () {
      expect(CircleMembershipRole.parse('member'),
          equals(CircleMembershipRole.member));
      expect(CircleMembershipRole.parse('facilitator'),
          equals(CircleMembershipRole.facilitator));
      expect(CircleMembershipRole.parse('host'),
          equals(CircleMembershipRole.facilitator));
      expect(CircleMembershipRole.parse('creator'),
          equals(CircleMembershipRole.facilitator));
      expect(CircleMembershipRole.parse('none'),
          equals(CircleMembershipRole.none));
      expect(
          CircleMembershipRole.parse(null), equals(CircleMembershipRole.none));
      expect(CircleMembershipRole.parse('unknown'),
          equals(CircleMembershipRole.none));
    });

    test('toJson and fromJson serialize and deserialize symmetrically', () {
      final now = DateTime.utc(2026, 11, 26, 11, 0, 0);
      final circle = LearningCircle.create(
        id: 'circle_json_01',
        name: 'Algorithms Study Group',
        description: 'Mastering graph traversal and dynamic programming.',
        category: 'Algorithms',
        facilitatorProfileId: 'prof_fac_10',
        facilitatorDisplayName: 'Rohan Sharma',
        memberCount: 6,
        membershipRole: CircleMembershipRole.member,
        goals: [
          CircleSharedGoal(
            id: 'g_json_01',
            circleId: 'circle_json_01',
            text: 'Solve 15 Tree challenges',
            progressPercent: 80,
          ),
        ],
        createdAt: now,
      );

      final json = circle.toJson();
      expect(json['id'], equals('circle_json_01'));
      expect(json['module'], equals('learning'));
      expect(json['name'], equals('Algorithms Study Group'));
      expect(json['category'], equals('Algorithms'));
      expect(json['facilitatorProfileId'], equals('prof_fac_10'));
      expect(json['facilitatorDisplayName'], equals('Rohan Sharma'));
      expect(json['memberCount'], equals(6));
      expect(json['membershipRole'], equals('member'));
      expect((json['goals'] as List).length, equals(1));
      expect(json['createdAt'], equals(now.toIso8601String()));

      final deserialized = LearningCircle.fromJson(json);
      expect(deserialized, equals(circle));
      expect(deserialized.createdAt.isAtSameMomentAs(now), isTrue);
    });

    test('copyWith updates properties preserving others', () {
      final circle = LearningCircle.create(
        id: 'c_copy',
        name: 'Initial Name',
        description: 'Initial Desc',
        category: 'Design',
        facilitatorProfileId: 'f_01',
        facilitatorDisplayName: 'Facil',
      );

      final updated = circle.copyWith(
        name: 'Updated Name',
        membershipRole: CircleMembershipRole.member,
        memberCount: 5,
      );

      expect(updated.id, equals('c_copy'));
      expect(updated.name, equals('Updated Name'));
      expect(updated.description, equals('Initial Desc'));
      expect(updated.membershipRole, equals(CircleMembershipRole.member));
      expect(updated.memberCount, equals(5));
    });

    test('redacted toString prevents leaking confidential data', () {
      final circle = LearningCircle.create(
        id: 'c_sec_01',
        name: 'Confidential Circle Name',
        description: 'Secret mission details',
        category: 'General',
        facilitatorProfileId: 'f_sec',
        facilitatorDisplayName: 'Secret Host',
      );

      final str = circle.toString();
      expect(str, isNot(contains('Confidential Circle Name')));
      expect(str, isNot(contains('Secret mission details')));
      expect(str, isNot(contains('Secret Host')));
    });
  });
}
