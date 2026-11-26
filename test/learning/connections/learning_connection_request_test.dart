import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/connections/domain/entities/learning_connection_request.dart';

void main() {
  group('LearningConnectionRequest Domain Entity Tests', () {
    test('instantiates with valid required fields and defensive defaults', () {
      final req = LearningConnectionRequest(
        id: 'req_01',
        senderProfileId: 'prof_sender_10',
        senderDisplayName: 'David Miller',
        receiverProfileId: 'prof_receiver_20',
        receiverDisplayName: 'Eve Adams',
        senderSkills: ['Kotlin', 'Java'],
        note: 'Let us collaborate on Android development!',
        isIncoming: true,
      );

      expect(req.id, equals('req_01'));
      expect(req.senderProfileId, equals('prof_sender_10'));
      expect(req.senderDisplayName, equals('David Miller'));
      expect(req.receiverProfileId, equals('prof_receiver_20'));
      expect(req.receiverDisplayName, equals('Eve Adams'));
      expect(req.senderSkills, equals(['Kotlin', 'Java']));
      expect(req.note, equals('Let us collaborate on Android development!'));
      expect(req.status, equals(LearningRequestStatus.pending));
      expect(req.isPending, isTrue);
      expect(req.isIncoming, isTrue);
      expect(req.module, equals('learning'));
    });

    test('enforces immutability: senderSkills is unmodifiable', () {
      final skills = ['Python', 'Django'];
      final req = LearningConnectionRequest(
        id: 'req_02',
        senderProfileId: 'prof_sender_20',
        senderDisplayName: 'Grace Hopper',
        receiverProfileId: 'prof_receiver_30',
        receiverDisplayName: 'Alan Turing',
        senderSkills: skills,
      );

      skills.add('Security');
      expect(req.senderSkills, equals(['Python', 'Django']));
      expect(() => req.senderSkills.add('C++'), throwsUnsupportedError);
    });

    test('rejects empty or whitespace-only required fields', () {
      expect(
        () => LearningConnectionRequest(
          id: '   ',
          senderProfileId: 's_01',
          senderDisplayName: 'Sender',
          receiverProfileId: 'r_01',
          receiverDisplayName: 'Receiver',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningConnectionRequest(
          id: 'req_01',
          senderProfileId: '   ',
          senderDisplayName: 'Sender',
          receiverProfileId: 'r_01',
          receiverDisplayName: 'Receiver',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningConnectionRequest(
          id: 'req_01',
          senderProfileId: 's_01',
          senderDisplayName: '   ',
          receiverProfileId: 'r_01',
          receiverDisplayName: 'Receiver',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningConnectionRequest(
          id: 'req_01',
          senderProfileId: 's_01',
          senderDisplayName: 'Sender',
          receiverProfileId: '   ',
          receiverDisplayName: 'Receiver',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningConnectionRequest(
          id: 'req_01',
          senderProfileId: 's_01',
          senderDisplayName: 'Sender',
          receiverProfileId: 'r_01',
          receiverDisplayName: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('rejects cross-module assignment, strictly enforcing moduleScope', () {
      expect(
        () => LearningConnectionRequest(
          id: 'req_01',
          senderProfileId: 's_01',
          senderDisplayName: 'Sender',
          receiverProfileId: 'r_01',
          receiverDisplayName: 'Receiver',
          module: 'social',
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningConnectionRequest(
          id: 'req_01',
          senderProfileId: 's_01',
          senderDisplayName: 'Sender',
          receiverProfileId: 'r_01',
          receiverDisplayName: 'Receiver',
          module: 'hobbies',
        ),
        throwsArgumentError,
      );
    });

    test(
        'LearningRequestStatus.parse safely handles string variants and defaults',
        () {
      expect(LearningRequestStatus.parse('pending'),
          equals(LearningRequestStatus.pending));
      expect(LearningRequestStatus.parse('accepted'),
          equals(LearningRequestStatus.accepted));
      expect(LearningRequestStatus.parse('declined'),
          equals(LearningRequestStatus.declined));
      expect(LearningRequestStatus.parse('rejected'),
          equals(LearningRequestStatus.declined));
      expect(LearningRequestStatus.parse('cancelled'),
          equals(LearningRequestStatus.cancelled));
      expect(LearningRequestStatus.parse('canceled'),
          equals(LearningRequestStatus.cancelled));
      expect(LearningRequestStatus.parse(null),
          equals(LearningRequestStatus.pending));
      expect(LearningRequestStatus.parse('unknown'),
          equals(LearningRequestStatus.pending));
    });

    test('toJson and fromJson serialize and deserialize symmetrically', () {
      final now = DateTime.utc(2026, 11, 26, 11, 0, 0);
      final req = LearningConnectionRequest(
        id: 'req_json_01',
        senderProfileId: 'prof_s_50',
        senderDisplayName: 'Ada Lovelace',
        senderAvatarUrl: 'https://example.com/ada.png',
        senderSkills: ['Algorithms', 'Mathematics'],
        receiverProfileId: 'prof_r_60',
        receiverDisplayName: 'Charles Babbage',
        note: 'Let us build something incredible.',
        createdAt: now,
        status: LearningRequestStatus.pending,
        isIncoming: false,
      );

      final json = req.toJson();
      expect(json['id'], equals('req_json_01'));
      expect(json['senderProfileId'], equals('prof_s_50'));
      expect(json['senderDisplayName'], equals('Ada Lovelace'));
      expect(json['senderAvatarUrl'], equals('https://example.com/ada.png'));
      expect(json['senderSkills'], equals(['Algorithms', 'Mathematics']));
      expect(json['receiverProfileId'], equals('prof_r_60'));
      expect(json['receiverDisplayName'], equals('Charles Babbage'));
      expect(json['note'], equals('Let us build something incredible.'));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['status'], equals('pending'));
      expect(json['isIncoming'], isFalse);
      expect(json['module'], equals('learning'));

      final deserialized = LearningConnectionRequest.fromJson(json);
      expect(deserialized, equals(req));
      expect(deserialized.createdAt.isAtSameMomentAs(now), isTrue);
    });

    test('value equality and hashCode behave correctly', () {
      final now = DateTime(2026, 1, 1);
      final req1 = LearningConnectionRequest(
        id: 'req_eq',
        senderProfileId: 's_1',
        senderDisplayName: 'Sender 1',
        receiverProfileId: 'r_1',
        receiverDisplayName: 'Receiver 1',
        createdAt: now,
      );

      final req2 = LearningConnectionRequest(
        id: 'req_eq',
        senderProfileId: 's_1',
        senderDisplayName: 'Sender 1',
        receiverProfileId: 'r_1',
        receiverDisplayName: 'Receiver 1',
        createdAt: now,
      );

      final req3 = LearningConnectionRequest(
        id: 'req_diff',
        senderProfileId: 's_2',
        senderDisplayName: 'Sender 2',
        receiverProfileId: 'r_2',
        receiverDisplayName: 'Receiver 2',
        createdAt: now,
      );

      expect(req1, equals(req2));
      expect(req1.hashCode, equals(req2.hashCode));
      expect(req1, isNot(equals(req3)));
    });

    test('redacted toString prevents leaking personal note and display names',
        () {
      final req = LearningConnectionRequest(
        id: 'req_sec_01',
        senderProfileId: 'sender_id_01',
        senderDisplayName: 'Confidential Sender',
        receiverProfileId: 'receiver_id_01',
        receiverDisplayName: 'Confidential Receiver',
        note: 'Super secret private message note',
      );

      final str = req.toString();
      expect(str, contains('req_sec_01'));
      expect(str, isNot(contains('Confidential Sender')));
      expect(str, isNot(contains('Super secret private message note')));
    });
  });
}
