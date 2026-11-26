import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/connections/domain/entities/learning_connection.dart';

void main() {
  group('LearningConnection Domain Entity Tests', () {
    test('instantiates with valid required fields and defensive defaults', () {
      final conn = LearningConnection(
        id: 'conn_01',
        peerProfileId: 'peer_prof_10',
        peerDisplayName: 'Alice Johnson',
        sharedSkills: ['Flutter', 'Dart'],
        learningGoals: ['State Management'],
      );

      expect(conn.id, equals('conn_01'));
      expect(conn.peerProfileId, equals('peer_prof_10'));
      expect(conn.peerDisplayName, equals('Alice Johnson'));
      expect(conn.sharedSkills, equals(['Flutter', 'Dart']));
      expect(conn.learningGoals, equals(['State Management']));
      expect(conn.status, equals(LearningConnectionStatus.active));
      expect(conn.isActive, isTrue);
      expect(conn.module, equals('learning'));
    });

    test(
        'enforces immutability: sharedSkills and learningGoals are unmodifiable',
        () {
      final skills = ['Flutter', 'Dart'];
      final goals = ['Clean Architecture'];

      final conn = LearningConnection(
        id: 'conn_02',
        peerProfileId: 'peer_prof_20',
        peerDisplayName: 'Bob Smith',
        sharedSkills: skills,
        learningGoals: goals,
      );

      // Mutating original lists should not affect entity
      skills.add('Rust');
      goals.add('DevOps');

      expect(conn.sharedSkills, equals(['Flutter', 'Dart']));
      expect(conn.learningGoals, equals(['Clean Architecture']));

      // Attempting to mutate returned unmodifiable lists must throw
      expect(() => conn.sharedSkills.add('Kotlin'), throwsUnsupportedError);
      expect(() => conn.learningGoals.add('Testing'), throwsUnsupportedError);
    });

    test('rejects empty or whitespace-only required fields', () {
      expect(
        () => LearningConnection(
          id: '   ',
          peerProfileId: 'peer_prof_01',
          peerDisplayName: 'Valid Name',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningConnection(
          id: 'conn_01',
          peerProfileId: '',
          peerDisplayName: 'Valid Name',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningConnection(
          id: 'conn_01',
          peerProfileId: 'peer_prof_01',
          peerDisplayName: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('rejects cross-module assignment, strictly enforcing moduleScope', () {
      expect(
        () => LearningConnection(
          id: 'conn_01',
          peerProfileId: 'peer_prof_01',
          peerDisplayName: 'Valid Name',
          module: 'social',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningConnection(
          id: 'conn_01',
          peerProfileId: 'peer_prof_01',
          peerDisplayName: 'Valid Name',
          module: 'hobbies',
        ),
        throwsArgumentError,
      );
    });

    test(
        'LearningConnectionStatus.parse safely handles string variants and defaults',
        () {
      expect(LearningConnectionStatus.parse('active'),
          equals(LearningConnectionStatus.active));
      expect(LearningConnectionStatus.parse('connected'),
          equals(LearningConnectionStatus.active));
      expect(LearningConnectionStatus.parse('removed'),
          equals(LearningConnectionStatus.removed));
      expect(LearningConnectionStatus.parse('disconnected'),
          equals(LearningConnectionStatus.removed));
      expect(LearningConnectionStatus.parse(null),
          equals(LearningConnectionStatus.active));
      expect(LearningConnectionStatus.parse('invalid_string'),
          equals(LearningConnectionStatus.active));
    });

    test('toJson and fromJson serialize and deserialize symmetrically', () {
      final now = DateTime.utc(2026, 11, 26, 10, 0, 0);
      final conn = LearningConnection(
        id: 'conn_json_01',
        peerProfileId: 'peer_prof_30',
        peerDisplayName: 'Charlie Brown',
        peerAvatarUrl: 'https://example.com/avatar.png',
        sharedSkills: ['UI/UX', 'Figma'],
        learningGoals: ['Mobile Design'],
        connectedAt: now,
        status: LearningConnectionStatus.active,
      );

      final json = conn.toJson();
      expect(json['id'], equals('conn_json_01'));
      expect(json['peerProfileId'], equals('peer_prof_30'));
      expect(json['peerDisplayName'], equals('Charlie Brown'));
      expect(json['peerAvatarUrl'], equals('https://example.com/avatar.png'));
      expect(json['sharedSkills'], equals(['UI/UX', 'Figma']));
      expect(json['learningGoals'], equals(['Mobile Design']));
      expect(json['connectedAt'], equals(now.toIso8601String()));
      expect(json['status'], equals('active'));
      expect(json['module'], equals('learning'));

      final deserialized = LearningConnection.fromJson(json);
      expect(deserialized, equals(conn));
      expect(deserialized.connectedAt.isAtSameMomentAs(now), isTrue);
    });

    test('value equality and hashCode behave correctly', () {
      final now = DateTime(2026, 1, 1);
      final conn1 = LearningConnection(
        id: 'conn_eq',
        peerProfileId: 'peer_1',
        peerDisplayName: 'Peer One',
        sharedSkills: ['Flutter'],
        connectedAt: now,
      );

      final conn2 = LearningConnection(
        id: 'conn_eq',
        peerProfileId: 'peer_1',
        peerDisplayName: 'Peer One',
        sharedSkills: ['Flutter'],
        connectedAt: now,
      );

      final conn3 = LearningConnection(
        id: 'conn_diff',
        peerProfileId: 'peer_2',
        peerDisplayName: 'Peer Two',
        sharedSkills: ['Flutter'],
        connectedAt: now,
      );

      expect(conn1, equals(conn2));
      expect(conn1.hashCode, equals(conn2.hashCode));
      expect(conn1, isNot(equals(conn3)));
    });

    test('redacted toString prevents leaking sensitive user data', () {
      final conn = LearningConnection(
        id: 'conn_sec_01',
        peerProfileId: 'peer_secret_id',
        peerDisplayName: 'Confidential Name',
        sharedSkills: ['Skill1', 'Skill2'],
      );

      final str = conn.toString();
      expect(str, contains('conn_sec_01'));
      expect(str, contains('peer_secret_id'));
      expect(str, isNot(contains('Confidential Name')));
    });

    test('copyWith produces updated instances without modifying originals', () {
      final conn = LearningConnection(
        id: 'conn_copy',
        peerProfileId: 'peer_copy_1',
        peerDisplayName: 'Original Name',
        sharedSkills: ['Dart'],
      );

      final updated = conn.copyWith(
        peerDisplayName: 'Updated Name',
        status: LearningConnectionStatus.removed,
      );

      expect(updated.id, equals('conn_copy'));
      expect(updated.peerDisplayName, equals('Updated Name'));
      expect(updated.status, equals(LearningConnectionStatus.removed));
      expect(conn.peerDisplayName, equals('Original Name'));
      expect(conn.status, equals(LearningConnectionStatus.active));
    });
  });
}
