import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/features/learning/classrooms/domain/entities/classroom_join_request.dart';
import 'package:andril_mobile/features/learning/classrooms/domain/entities/learning_classroom.dart';
import 'package:andril_mobile/features/learning/classrooms/group_contracts/learning_group_contract.dart';

void main() {
  group('LearningClassroom Domain Entity Tests', () {
    test('creates valid LearningClassroom with default values', () {
      final classroom = LearningClassroom.create(
        id: 'cls_001',
        name: 'Mobile DevOps',
        description: 'CI/CD and test automation for Flutter apps.',
        category: 'Programming',
        hostProfileId: 'prof_host_1',
        hostDisplayName: 'Alex Mentor',
        tags: ['DevOps', 'Flutter'],
      );

      expect(classroom.id, equals('cls_001'));
      expect(classroom.name, equals('Mobile DevOps'));
      expect(classroom.module, equals(LearningClassroom.moduleScope));
      expect(classroom.category, equals('Programming'));
      expect(classroom.privacy, equals(ClassroomPrivacy.public));
      expect(classroom.memberCount, equals(0));
      expect(classroom.capacity, isNull);
      expect(classroom.hostProfileId, equals('prof_host_1'));
      expect(classroom.hostDisplayName, equals('Alex Mentor'));
      expect(
          classroom.membershipStatus, equals(ClassroomMembershipStatus.none));
      expect(classroom.tags, equals(['DevOps', 'Flutter']));
      expect(classroom.isDiscoverable, isTrue);
      expect(classroom.canJoinDirectly, isTrue);
      expect(classroom.canRequestToJoin, isFalse);
      expect(classroom.isEnrolled, isFalse);
      expect(classroom.isPending, isFalse);
    });

    test('validates privacy and admission flags correctly', () {
      final requestClassroom = LearningClassroom.create(
        id: 'cls_002',
        name: 'Design Systems',
        description: 'Advanced UI systems.',
        category: 'Design',
        privacy: ClassroomPrivacy.requestToJoin,
        hostProfileId: 'prof_host_2',
        hostDisplayName: 'Sara Designer',
      );

      expect(requestClassroom.canJoinDirectly, isFalse);
      expect(requestClassroom.canRequestToJoin, isTrue);
      expect(requestClassroom.isEnrolled, isFalse);

      final closedClassroom = LearningClassroom.create(
        id: 'cls_003',
        name: 'Executive Leadership',
        description: 'Private cohort.',
        category: 'Business',
        privacy: ClassroomPrivacy.closed,
        hostProfileId: 'prof_host_3',
        hostDisplayName: 'CEO Mentor',
      );

      expect(closedClassroom.canJoinDirectly, isFalse);
      expect(closedClassroom.canRequestToJoin, isFalse);

      final enrolledMember = requestClassroom.copyWith(
        membershipStatus: ClassroomMembershipStatus.member,
      );
      expect(enrolledMember.isEnrolled, isTrue);
      expect(enrolledMember.canRequestToJoin, isFalse);

      final hostMember = requestClassroom.copyWith(
        membershipStatus: ClassroomMembershipStatus.host,
      );
      expect(hostMember.isEnrolled, isTrue);

      final pendingMember = requestClassroom.copyWith(
        membershipStatus: ClassroomMembershipStatus.pending,
      );
      expect(pendingMember.isPending, isTrue);
      expect(pendingMember.isEnrolled, isFalse);
    });

    test('enforces structural invariants and rejects empty or invalid fields',
        () {
      expect(
        () => LearningClassroom.create(
          id: '',
          name: 'Class',
          description: 'Desc',
          category: 'Tech',
          hostProfileId: 'h1',
          hostDisplayName: 'Host',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningClassroom.create(
          id: 'cls_1',
          name: '  ',
          description: 'Desc',
          category: 'Tech',
          hostProfileId: 'h1',
          hostDisplayName: 'Host',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningClassroom.create(
          id: 'cls_1',
          name: 'Class',
          description: '',
          category: 'Tech',
          hostProfileId: 'h1',
          hostDisplayName: 'Host',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningClassroom.create(
          id: 'cls_1',
          name: 'Class',
          description: 'Desc',
          category: 'Tech',
          hostProfileId: '',
          hostDisplayName: 'Host',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningClassroom.create(
          id: 'cls_1',
          name: 'Class',
          description: 'Desc',
          category: 'Tech',
          hostProfileId: 'h1',
          hostDisplayName: '',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningClassroom.create(
          id: 'cls_1',
          name: 'Class',
          description: 'Desc',
          category: 'Tech',
          hostProfileId: 'h1',
          hostDisplayName: 'Host',
          memberCount: -1,
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningClassroom.create(
          id: 'cls_1',
          name: 'Class',
          description: 'Desc',
          category: 'Tech',
          hostProfileId: 'h1',
          hostDisplayName: 'Host',
          capacity: 0,
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningClassroom.create(
          id: 'cls_1',
          name: 'Class',
          description: 'Desc',
          category: 'Tech',
          hostProfileId: 'h1',
          hostDisplayName: 'Host',
          memberCount: 50,
          capacity: 20,
        ),
        throwsArgumentError,
      );
    });

    test('supports copyWith for status transitions and count increments', () {
      final original = LearningClassroom.create(
        id: 'cls_10',
        name: 'Algorithms',
        description: 'Data structures.',
        category: 'Programming',
        hostProfileId: 'h1',
        hostDisplayName: 'Prof Alg',
        memberCount: 10,
        capacity: 20,
      );

      final updated = original.copyWith(
        memberCount: 11,
        membershipStatus: ClassroomMembershipStatus.member,
      );

      expect(updated.id, equals(original.id));
      expect(updated.memberCount, equals(11));
      expect(
          updated.membershipStatus, equals(ClassroomMembershipStatus.member));
      expect(updated.isEnrolled, isTrue);
    });

    test('redacts private identifiers in diagnostic toString', () {
      final classroom = LearningClassroom.create(
        id: 'secret_guid_123',
        name: 'Security Workshop',
        description: 'Secure coding.',
        category: 'Security',
        hostProfileId: 'secret_host_profile_456',
        hostDisplayName: 'Security Expert',
      );

      final diagnostic = classroom.toString();
      expect(diagnostic, isNot(contains('secret_guid_123')));
      expect(diagnostic, isNot(contains('secret_host_profile_456')));
      expect(diagnostic, contains('Security Workshop'));
    });

    test('provides realistic sample classrooms with disconnected notice', () {
      final samples = LearningClassroom.sampleClassrooms;
      expect(samples, isNotEmpty);
      expect(samples.length, greaterThanOrEqualTo(5));
      expect(LearningClassroom.disconnectedNotice, isNotEmpty);
      expect(LearningClassroom.disconnectedNotice,
          contains('Remote Groups backend contract pending'));
    });
  });

  group('ClassroomJoinRequest Domain Entity Tests', () {
    test('creates valid ClassroomJoinRequest', () {
      final req = ClassroomJoinRequest.create(
        requestId: 'req_001',
        classroomId: 'cls_001',
        applicantProfileId: 'prof_applicant_1',
        note: 'Excited to learn Flutter!',
      );

      expect(req.requestId, equals('req_001'));
      expect(req.classroomId, equals('cls_001'));
      expect(req.applicantProfileId, equals('prof_applicant_1'));
      expect(req.note, equals('Excited to learn Flutter!'));
      expect(req.status, equals(ClassroomJoinRequestStatus.pending));
    });

    test('cancels pending join request', () {
      final req = ClassroomJoinRequest.create(
        requestId: 'req_002',
        classroomId: 'cls_002',
        applicantProfileId: 'prof_applicant_2',
      );

      final cancelled = req.cancel();
      expect(cancelled.status, equals(ClassroomJoinRequestStatus.cancelled));

      expect(() => cancelled.cancel(), throwsStateError);
    });

    test('validates non-empty fields', () {
      expect(
        () => ClassroomJoinRequest.create(
          requestId: '',
          classroomId: 'c1',
          applicantProfileId: 'a1',
        ),
        throwsArgumentError,
      );

      expect(
        () => ClassroomJoinRequest.create(
          requestId: 'r1',
          classroomId: '',
          applicantProfileId: 'a1',
        ),
        throwsArgumentError,
      );

      expect(
        () => ClassroomJoinRequest.create(
          requestId: 'r1',
          classroomId: 'c1',
          applicantProfileId: '',
        ),
        throwsArgumentError,
      );
    });
  });

  group('LearningGroupContract Integration Boundary Tests', () {
    test('enforces module isolation and group kind compatibility', () {
      expect(LearningGroupContract.module, equals('learning'));
      expect(LearningGroupContract.groupKind, equals(GroupKind.classroom));
      expect(
        LearningGroupContract.isCompatible('learning', GroupKind.classroom),
        isTrue,
      );
      expect(
        LearningGroupContract.isCompatible('hobbies', GroupKind.classroom),
        isFalse,
      );
      expect(
        LearningGroupContract.isCompatible('learning', GroupKind.club),
        isFalse,
      );
      expect(
        LearningGroupContract.isCompatible('social', GroupKind.zone),
        isFalse,
      );
    });

    test('defines valid endpoint templates', () {
      expect(LearningGroupContract.creationEndpoint,
          equals('/api/v1/learning/groups'));
      expect(LearningGroupContract.discoveryEndpoint,
          equals('/api/v1/learning/groups'));
      expect(
        LearningGroupContract.joinRequestEndpoint('cls_100'),
        equals('/api/v1/learning/groups/cls_100/join-requests'),
      );
    });
  });
}
