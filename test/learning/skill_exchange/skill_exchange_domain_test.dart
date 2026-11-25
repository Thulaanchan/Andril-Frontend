import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/skill_exchange/domain/entities/skill_exchange.dart';
import 'package:andril_mobile/features/learning/skill_exchange/domain/entities/skill_exchange_participant.dart';
import 'package:andril_mobile/features/learning/skill_exchange/domain/entities/skill_partner.dart';

void main() {
  group('SkillExchangeParticipant Domain Entity', () {
    test('Constructs with valid non-empty account and profile IDs', () {
      final participant = SkillExchangeParticipant(
        accountId: 'acc_01',
        learningProfileId: 'prof_01',
      );
      expect(participant.accountId, equals('acc_01'));
      expect(participant.learningProfileId, equals('prof_01'));
    });

    test(
        'Throws ArgumentError on empty or whitespace accountId or learningProfileId',
        () {
      expect(
        () => SkillExchangeParticipant(
          accountId: '   ',
          learningProfileId: 'prof_01',
        ),
        throwsArgumentError,
      );
      expect(
        () => SkillExchangeParticipant(
          accountId: 'acc_01',
          learningProfileId: '',
        ),
        throwsArgumentError,
      );
    });

    test('Implements structural value equality and hash code', () {
      final p1 = SkillExchangeParticipant(
        accountId: 'acc_01',
        learningProfileId: 'prof_01',
      );
      final p2 = SkillExchangeParticipant(
        accountId: 'acc_01',
        learningProfileId: 'prof_01',
      );
      final p3 = SkillExchangeParticipant(
        accountId: 'acc_02',
        learningProfileId: 'prof_01',
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });

    test('Redacts confidential internal references in toString()', () {
      final participant = SkillExchangeParticipant(
        accountId: 'confidential_acc_123',
        learningProfileId: 'private_prof_456',
      );
      final text = participant.toString();
      expect(text, contains('[private references omitted]'));
      expect(text, isNot(contains('confidential_acc_123')));
      expect(text, isNot(contains('private_prof_456')));
    });
  });

  group('SkillExchange Domain Entity', () {
    late SkillExchangeParticipant sender;
    late SkillExchangeParticipant recipient;

    setUp(() {
      sender = SkillExchangeParticipant(
        accountId: 'acc_sender',
        learningProfileId: 'prof_sender',
      );
      recipient = SkillExchangeParticipant(
        accountId: 'acc_recipient',
        learningProfileId: 'prof_recipient',
      );
    });

    test('Propose creates proposal with Pending status and module learning',
        () {
      final exchange = SkillExchange.propose(
        id: 'ex_001',
        sender: sender,
        recipient: recipient,
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
        note: 'Happy to exchange',
      );

      expect(exchange.id, equals('ex_001'));
      expect(exchange.module, equals('learning'));
      expect(exchange.sender, equals(sender));
      expect(exchange.recipient, equals(recipient));
      expect(exchange.offeredSkill, equals('Flutter'));
      expect(exchange.wantedSkill, equals('Figma'));
      expect(exchange.status, equals(SkillExchangeStatus.pending));
      expect(exchange.note, equals('Happy to exchange'));
    });

    test('Propose rejects empty ID, empty offeredSkill, or empty wantedSkill',
        () {
      expect(
        () => SkillExchange.propose(
          id: '',
          sender: sender,
          recipient: recipient,
          offeredSkill: 'Flutter',
          wantedSkill: 'Figma',
        ),
        throwsArgumentError,
      );
      expect(
        () => SkillExchange.propose(
          id: 'ex_01',
          sender: sender,
          recipient: recipient,
          offeredSkill: '',
          wantedSkill: 'Figma',
        ),
        throwsArgumentError,
      );
      expect(
        () => SkillExchange.propose(
          id: 'ex_01',
          sender: sender,
          recipient: recipient,
          offeredSkill: 'Flutter',
          wantedSkill: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('Propose rejects self-exchange across account or profile', () {
      final sameAccountRecipient = SkillExchangeParticipant(
        accountId: sender.accountId,
        learningProfileId: 'prof_other',
      );
      final sameProfileRecipient = SkillExchangeParticipant(
        accountId: 'acc_other',
        learningProfileId: sender.learningProfileId,
      );

      expect(
        () => SkillExchange.propose(
          id: 'ex_01',
          sender: sender,
          recipient: sameAccountRecipient,
          offeredSkill: 'Flutter',
          wantedSkill: 'Figma',
        ),
        throwsArgumentError,
      );
      expect(
        () => SkillExchange.propose(
          id: 'ex_01',
          sender: sender,
          recipient: sameProfileRecipient,
          offeredSkill: 'Flutter',
          wantedSkill: 'Figma',
        ),
        throwsArgumentError,
      );
    });

    test(
        'Propose throws UnsupportedError when offered and wanted skills are identical',
        () {
      expect(
        () => SkillExchange.propose(
          id: 'ex_01',
          sender: sender,
          recipient: recipient,
          offeredSkill: 'Flutter',
          wantedSkill: 'flutter',
        ),
        throwsUnsupportedError,
      );
    });

    test(
        'Accept transitions from Pending to Accepted when called by designated recipient',
        () {
      final exchange = SkillExchange.propose(
        id: 'ex_01',
        sender: sender,
        recipient: recipient,
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
      );

      final accepted = exchange.accept(recipient);
      expect(accepted.status, equals(SkillExchangeStatus.accepted));
      expect(accepted.id, equals(exchange.id));
    });

    test(
        'Decline transitions from Pending to Declined when called by designated recipient',
        () {
      final exchange = SkillExchange.propose(
        id: 'ex_01',
        sender: sender,
        recipient: recipient,
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
      );

      final declined = exchange.decline(recipient);
      expect(declined.status, equals(SkillExchangeStatus.declined));
    });

    test(
        'Cancel transitions from Pending to Cancelled when called by designated sender',
        () {
      final exchange = SkillExchange.propose(
        id: 'ex_01',
        sender: sender,
        recipient: recipient,
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
      );

      final cancelled = exchange.cancel(sender);
      expect(cancelled.status, equals(SkillExchangeStatus.cancelled));
    });

    test(
        'Transition throws ArgumentError when actor is not designated participant',
        () {
      final exchange = SkillExchange.propose(
        id: 'ex_01',
        sender: sender,
        recipient: recipient,
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
      );

      final outsider = SkillExchangeParticipant(
        accountId: 'acc_other',
        learningProfileId: 'prof_other',
      );

      // Sender cannot accept or decline
      expect(() => exchange.accept(sender), throwsArgumentError);
      expect(() => exchange.decline(sender), throwsArgumentError);

      // Recipient cannot cancel
      expect(() => exchange.cancel(recipient), throwsArgumentError);

      // Outsider cannot do any action
      expect(() => exchange.accept(outsider), throwsArgumentError);
      expect(() => exchange.cancel(outsider), throwsArgumentError);
    });

    test('Terminal proposal rejects subsequent transitions', () {
      final exchange = SkillExchange.propose(
        id: 'ex_01',
        sender: sender,
        recipient: recipient,
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
      );

      final accepted = exchange.accept(recipient);
      expect(() => accepted.accept(recipient), throwsStateError);
      expect(() => accepted.decline(recipient), throwsStateError);
      expect(() => accepted.cancel(sender), throwsStateError);
    });

    test(
        'ComparePendingProposal recognizes exactDuplicate, pendingPairConflict, differentPair',
        () {
      final p1 = SkillExchange.propose(
        id: 'ex_01',
        sender: sender,
        recipient: recipient,
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
      );

      final exactCopy = SkillExchange.propose(
        id: 'ex_02',
        sender: sender,
        recipient: recipient,
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
      );

      final reverseDifferentSkills = SkillExchange.propose(
        id: 'ex_03',
        sender: recipient,
        recipient: sender,
        offeredSkill: 'Python',
        wantedSkill: 'Dart',
      );

      final differentRecipient = SkillExchange.propose(
        id: 'ex_04',
        sender: sender,
        recipient: SkillExchangeParticipant(
          accountId: 'acc_third',
          learningProfileId: 'prof_third',
        ),
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
      );

      expect(
        p1.comparePendingProposal(exactCopy),
        equals(PendingProposalComparison.exactDuplicate),
      );
      expect(
        p1.comparePendingProposal(reverseDifferentSkills),
        equals(PendingProposalComparison.pendingPairConflict),
      );
      expect(
        p1.comparePendingProposal(differentRecipient),
        equals(PendingProposalComparison.differentPair),
      );
    });

    test('Pair guard in Propose constructor rejects pending conflict', () {
      final existing = SkillExchange.propose(
        id: 'ex_01',
        sender: sender,
        recipient: recipient,
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
      );

      expect(
        () => SkillExchange.propose(
          id: 'ex_02',
          sender: recipient,
          recipient: sender,
          offeredSkill: 'Python',
          wantedSkill: 'Dart',
          existingProposals: [existing],
        ),
        throwsStateError,
      );
    });

    test('Terminal history permits fresh proposal for the same pair', () {
      final existing = SkillExchange.propose(
        id: 'ex_01',
        sender: sender,
        recipient: recipient,
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
      );
      final cancelled = existing.cancel(sender);

      final fresh = SkillExchange.propose(
        id: 'ex_02',
        sender: sender,
        recipient: recipient,
        offeredSkill: 'Dart',
        wantedSkill: 'Python',
        existingProposals: [cancelled],
      );

      expect(fresh.id, equals('ex_02'));
      expect(fresh.status, equals(SkillExchangeStatus.pending));
    });

    test('Diagnostics and toString() redact private identities', () {
      final exchange = SkillExchange.propose(
        id: 'sensitive_id_999',
        sender: SkillExchangeParticipant(
          accountId: 'acc_private_111',
          learningProfileId: 'prof_private_222',
        ),
        recipient: SkillExchangeParticipant(
          accountId: 'acc_private_333',
          learningProfileId: 'prof_private_444',
        ),
        offeredSkill: 'Flutter',
        wantedSkill: 'Figma',
      );

      final text = exchange.toString();
      expect(text, contains('[private references omitted]'));
      expect(text, isNot(contains('sensitive_id_999')));
      expect(text, isNot(contains('acc_private_111')));
      expect(text, isNot(contains('prof_private_222')));
    });
  });

  group('SkillPartner Model', () {
    test('Constructs correctly with defensive collections', () {
      final partner = SkillPartner(
        profileId: 'partner_01',
        accountId: 'acc_01',
        displayName: 'Ananya Sharma',
        category: 'Technology',
        skillsOffered: const ['Flutter', 'Dart'],
        skillsWanted: const ['Figma'],
      );

      expect(partner.displayName, equals('Ananya Sharma'));
      expect(partner.category, equals('Technology'));
      expect(partner.skillsOffered, equals(['Flutter', 'Dart']));
      expect(partner.skillsWanted, equals(['Figma']));

      // Defensive unmodifiable check
      expect(() => partner.skillsOffered.add('Java'), throwsUnsupportedError);
    });

    test('toParticipant converts partner into SkillExchangeParticipant', () {
      final partner = SkillPartner(
        profileId: 'partner_01',
        accountId: 'acc_01',
        displayName: 'Ananya Sharma',
        category: 'Technology',
      );

      final participant = partner.toParticipant();
      expect(participant.accountId, equals('acc_01'));
      expect(participant.learningProfileId, equals('partner_01'));
    });

    test('samplePartners returns verified non-empty list of partners', () {
      final partners = SkillPartner.samplePartners;
      expect(partners, isNotEmpty);
      expect(partners.length, greaterThanOrEqualTo(5));
      for (final p in partners) {
        expect(p.displayName, isNotEmpty);
        expect(p.category, isNotEmpty);
      }
    });

    test('toString redacts accountId and profileId', () {
      final partner = SkillPartner(
        profileId: 'secret_partner_id',
        accountId: 'secret_acc_id',
        displayName: 'Visible Name',
        category: 'Design',
      );

      final text = partner.toString();
      expect(text, contains('[private references omitted]'));
      expect(text, isNot(contains('secret_partner_id')));
      expect(text, isNot(contains('secret_acc_id')));
    });
  });
}
