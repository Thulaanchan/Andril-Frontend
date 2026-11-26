import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/pacts/domain/entities/learning_pact.dart';

void main() {
  group('LearningPact Domain Entities', () {
    group('LearningPactStatus', () {
      test('correctly reports isActive, isPending, isCancelled, isCompleted',
          () {
        expect(LearningPactStatus.active.isActive, isTrue);
        expect(LearningPactStatus.active.isPending, isFalse);
        expect(LearningPactStatus.pending.isPending, isTrue);
        expect(LearningPactStatus.pending.isActive, isFalse);
        expect(LearningPactStatus.cancelled.isCancelled, isTrue);
        expect(LearningPactStatus.completed.isCompleted, isTrue);
      });

      test('safely parses strings with various casing', () {
        expect(LearningPactStatus.parse('ACTIVE'), LearningPactStatus.active);
        expect(LearningPactStatus.parse('active'), LearningPactStatus.active);
        expect(LearningPactStatus.parse('pending'), LearningPactStatus.pending);
        expect(LearningPactStatus.parse('cancelled'),
            LearningPactStatus.cancelled);
        expect(
            LearningPactStatus.parse('canceled'), LearningPactStatus.cancelled);
        expect(LearningPactStatus.parse('withdrawn'),
            LearningPactStatus.cancelled);
        expect(LearningPactStatus.parse('completed'),
            LearningPactStatus.completed);
        expect(LearningPactStatus.parse('unknown'), LearningPactStatus.pending);
        expect(LearningPactStatus.parse(null), LearningPactStatus.pending);
      });
    });

    group('PactInvitationDecision', () {
      test('correctly reports isAccepted, isPending, isDeclined', () {
        expect(PactInvitationDecision.accepted.isAccepted, isTrue);
        expect(PactInvitationDecision.pending.isPending, isTrue);
        expect(PactInvitationDecision.declined.isDeclined, isTrue);
      });

      test('safely parses strings', () {
        expect(PactInvitationDecision.parse('accepted'),
            PactInvitationDecision.accepted);
        expect(PactInvitationDecision.parse('AGREE'),
            PactInvitationDecision.accepted);
        expect(PactInvitationDecision.parse('agreed'),
            PactInvitationDecision.accepted);
        expect(PactInvitationDecision.parse('declined'),
            PactInvitationDecision.declined);
        expect(PactInvitationDecision.parse('rejected'),
            PactInvitationDecision.declined);
        expect(PactInvitationDecision.parse('pending'),
            PactInvitationDecision.pending);
        expect(
            PactInvitationDecision.parse(null), PactInvitationDecision.pending);
      });
    });

    group('PactHistoryEventType', () {
      test('safely parses history event type names', () {
        expect(PactHistoryEventType.parse('proposal'),
            PactHistoryEventType.proposal);
        expect(
            PactHistoryEventType.parse('agreed'), PactHistoryEventType.agreed);
        expect(PactHistoryEventType.parse('selfReported'),
            PactHistoryEventType.selfReported);
        expect(PactHistoryEventType.parse('partnerUpdate'),
            PactHistoryEventType.partnerUpdate);
        expect(PactHistoryEventType.parse('withdrawn'),
            PactHistoryEventType.withdrawn);
        expect(PactHistoryEventType.parse('completed'),
            PactHistoryEventType.completed);
        expect(PactHistoryEventType.parse('unknown'),
            PactHistoryEventType.selfReported);
        expect(PactHistoryEventType.parse(null),
            PactHistoryEventType.selfReported);
      });
    });

    group('PactParticipation', () {
      test('instantiates and validates required fields', () {
        final p = PactParticipation(
          participantProfileId: 'prof_123',
          participantDisplayName: 'Alice Doe',
          decision: PactInvitationDecision.accepted,
          completionConfirmed: false,
        );

        expect(p.participantProfileId, 'prof_123');
        expect(p.participantDisplayName, 'Alice Doe');
        expect(p.decision, PactInvitationDecision.accepted);
        expect(p.completionConfirmed, isFalse);
      });

      test('throws ArgumentError on empty profile ID or display name', () {
        expect(
          () => PactParticipation(
            participantProfileId: '  ',
            participantDisplayName: 'Alice',
          ),
          throwsArgumentError,
        );
        expect(
          () => PactParticipation(
            participantProfileId: 'prof_1',
            participantDisplayName: '',
          ),
          throwsArgumentError,
        );
      });

      test('serializes to and from JSON', () {
        final p = PactParticipation(
          participantProfileId: 'prof_1',
          participantDisplayName: 'Alice',
          participantAvatarUrl: 'https://example.com/avatar.png',
          decision: PactInvitationDecision.accepted,
          completionConfirmed: true,
          agreedAt: DateTime.parse('2026-11-26T12:00:00Z'),
        );

        final json = p.toJson();
        final deserialized = PactParticipation.fromJson(json);

        expect(deserialized.participantProfileId, p.participantProfileId);
        expect(deserialized.participantDisplayName, p.participantDisplayName);
        expect(deserialized.participantAvatarUrl, p.participantAvatarUrl);
        expect(deserialized.decision, p.decision);
        expect(deserialized.completionConfirmed, isTrue);
        expect(deserialized.agreedAt, isNotNull);
      });

      test('redacts toString for PII and security protection', () {
        final p = PactParticipation(
          participantProfileId: 'secret_prof_id',
          participantDisplayName: 'Alice Secret',
        );
        expect(p.toString(), contains('private identity omitted'));
        expect(p.toString(), isNot(contains('secret_prof_id')));
        expect(p.toString(), isNot(contains('Alice Secret')));
      });
    });

    group('PactCommitment', () {
      test('validates non-empty id, pactId, and text', () {
        expect(
          () => PactCommitment(id: '', pactId: 'pact_1', text: 'Study'),
          throwsArgumentError,
        );
        expect(
          () => PactCommitment(id: 'c1', pactId: ' ', text: 'Study'),
          throwsArgumentError,
        );
        expect(
          () => PactCommitment(id: 'c1', pactId: 'pact_1', text: '   '),
          throwsArgumentError,
        );
      });

      test('serializes and deserializes correctly', () {
        final c = PactCommitment(
          id: 'cmt_1',
          pactId: 'pact_1',
          text: 'Complete 3 chapters',
          isCompleted: true,
          completedAt: DateTime.parse('2026-11-26T10:00:00Z'),
        );

        final json = c.toJson();
        final deserialized = PactCommitment.fromJson(json);

        expect(deserialized.id, 'cmt_1');
        expect(deserialized.pactId, 'pact_1');
        expect(deserialized.text, 'Complete 3 chapters');
        expect(deserialized.isCompleted, isTrue);
        expect(deserialized.completedAt, isNotNull);
      });

      test('redacts toString', () {
        final c = PactCommitment(
          id: 'cmt_1',
          pactId: 'pact_1',
          text: 'Secret study goal',
        );
        expect(c.toString(), contains('private terms omitted'));
        expect(c.toString(), isNot(contains('Secret study goal')));
      });
    });

    group('PactHistoryEvent', () {
      test('serializes and deserializes', () {
        final event = PactHistoryEvent(
          id: 'hist_1',
          pactId: 'pact_1',
          title: 'Proposal Sent',
          description: 'Alice proposed a new pact.',
          type: PactHistoryEventType.proposal,
          actorDisplayName: 'Alice',
        );

        final json = event.toJson();
        final deserialized = PactHistoryEvent.fromJson(json);

        expect(deserialized.id, 'hist_1');
        expect(deserialized.title, 'Proposal Sent');
        expect(deserialized.type, PactHistoryEventType.proposal);
        expect(deserialized.actorDisplayName, 'Alice');
      });

      test('redacts toString', () {
        final event = PactHistoryEvent(
          id: 'hist_1',
          pactId: 'pact_1',
          title: 'Proposal',
          description: 'Confidential text',
          type: PactHistoryEventType.proposal,
        );
        expect(event.toString(), contains('private record omitted'));
        expect(event.toString(), isNot(contains('Confidential text')));
      });
    });

    group('LearningPact Entity Governance & Invariants', () {
      test('enforces module == "learning" strictly', () {
        expect(
          () => LearningPact.create(
            id: 'pact_1',
            module: 'classroom',
            title: 'Title',
            sharedGoal: 'Goal',
            proposerProfileId: 'prof_1',
            proposerDisplayName: 'Proposer',
            status: LearningPactStatus.pending,
            participants: [
              PactParticipation(
                participantProfileId: 'prof_1',
                participantDisplayName: 'Proposer',
                decision: PactInvitationDecision.accepted,
              ),
              PactParticipation(
                participantProfileId: 'prof_2',
                participantDisplayName: 'Partner',
                decision: PactInvitationDecision.pending,
              ),
            ],
          ),
          throwsArgumentError,
        );
      });

      test('enforces at least 2 distinct participants', () {
        expect(
          () => LearningPact.create(
            id: 'pact_1',
            title: 'Title',
            sharedGoal: 'Goal',
            proposerProfileId: 'prof_1',
            proposerDisplayName: 'Proposer',
            status: LearningPactStatus.pending,
            participants: [
              PactParticipation(
                participantProfileId: 'prof_1',
                participantDisplayName: 'Proposer',
              ),
            ],
          ),
          throwsArgumentError,
        );

        expect(
          () => LearningPact.create(
            id: 'pact_1',
            title: 'Title',
            sharedGoal: 'Goal',
            proposerProfileId: 'prof_1',
            proposerDisplayName: 'Proposer',
            status: LearningPactStatus.pending,
            participants: [
              PactParticipation(
                participantProfileId: 'prof_1',
                participantDisplayName: 'Proposer',
              ),
              PactParticipation(
                participantProfileId: 'prof_1', // duplicate participant ID
                participantDisplayName: 'Proposer Fake',
              ),
            ],
          ),
          throwsArgumentError,
        );
      });

      test(
          'MUTUAL ACCEPTANCE RULE (DEC-20261120-LRN03-01): cannot be active if any participant is pending',
          () {
        expect(
          () => LearningPact.create(
            id: 'pact_1',
            title: 'Title',
            sharedGoal: 'Goal',
            proposerProfileId: 'prof_1',
            proposerDisplayName: 'Proposer',
            status:
                LearningPactStatus.active, // INVALID: participant 2 is pending
            participants: [
              PactParticipation(
                participantProfileId: 'prof_1',
                participantDisplayName: 'Proposer',
                decision: PactInvitationDecision.accepted,
              ),
              PactParticipation(
                participantProfileId: 'prof_2',
                participantDisplayName: 'Partner',
                decision: PactInvitationDecision.pending,
              ),
            ],
          ),
          throwsStateError,
        );
      });

      test(
          'MUTUAL ACCEPTANCE RULE (DEC-20261120-LRN03-01): cannot be active if any participant declined',
          () {
        expect(
          () => LearningPact.create(
            id: 'pact_1',
            title: 'Title',
            sharedGoal: 'Goal',
            proposerProfileId: 'prof_1',
            proposerDisplayName: 'Proposer',
            status:
                LearningPactStatus.active, // INVALID: participant 2 declined
            participants: [
              PactParticipation(
                participantProfileId: 'prof_1',
                participantDisplayName: 'Proposer',
                decision: PactInvitationDecision.accepted,
              ),
              PactParticipation(
                participantProfileId: 'prof_2',
                participantDisplayName: 'Partner',
                decision: PactInvitationDecision.declined,
              ),
            ],
          ),
          throwsStateError,
        );
      });

      test(
          'propose factory creates pending pact with proposer accepted and partner pending',
          () {
        final pact = LearningPact.propose(
          id: 'pact_new',
          title: 'Algorithms Mastery',
          sharedGoal: 'Complete LeetCode 75',
          proposerProfileId: 'prof_me',
          proposerDisplayName: 'Current Learner',
          partnerProfileId: 'prof_partner',
          partnerDisplayName: 'Study Buddy',
          duration: '6 weeks',
          studyPlan: '3 hours/week',
          commitmentTexts: ['Arrays & Strings', 'Trees & Graphs'],
        );

        expect(pact.status, LearningPactStatus.pending);
        expect(pact.isPending, isTrue);
        expect(pact.isActive, isFalse);
        expect(pact.participants.length, 2);

        final myPart = pact.myParticipation('prof_me');
        expect(myPart, isNotNull);
        expect(myPart!.decision, PactInvitationDecision.accepted);

        final partnerPart = pact.myParticipation('prof_partner');
        expect(partnerPart, isNotNull);
        expect(partnerPart!.decision, PactInvitationDecision.pending);

        expect(pact.commitments.length, 2);
        expect(pact.commitments.first.text, 'Arrays & Strings');
        expect(pact.history.length, 1);
        expect(pact.history.first.type, PactHistoryEventType.proposal);
      });

      test('calculates completedCommitmentsCount and progressPercent correctly',
          () {
        final pact = LearningPact.create(
          id: 'pact_active',
          title: 'Title',
          sharedGoal: 'Goal',
          proposerProfileId: 'prof_1',
          proposerDisplayName: 'Proposer',
          status: LearningPactStatus.active,
          participants: [
            PactParticipation(
              participantProfileId: 'prof_1',
              participantDisplayName: 'Proposer',
              decision: PactInvitationDecision.accepted,
            ),
            PactParticipation(
              participantProfileId: 'prof_2',
              participantDisplayName: 'Partner',
              decision: PactInvitationDecision.accepted,
            ),
          ],
          commitments: [
            PactCommitment(
                id: 'c1',
                pactId: 'pact_active',
                text: 'Task 1',
                isCompleted: true),
            PactCommitment(
                id: 'c2',
                pactId: 'pact_active',
                text: 'Task 2',
                isCompleted: false),
            PactCommitment(
                id: 'c3',
                pactId: 'pact_active',
                text: 'Task 3',
                isCompleted: true),
            PactCommitment(
                id: 'c4',
                pactId: 'pact_active',
                text: 'Task 4',
                isCompleted: false),
          ],
        );

        expect(pact.completedCommitmentsCount, 2);
        expect(pact.progressPercent, 50);
      });

      test('serializes to and from JSON cleanly', () {
        final original = LearningPact.propose(
          id: 'pact_json_test',
          title: 'Full Stack App',
          sharedGoal: 'Deploy on Cloud',
          proposerProfileId: 'prof_1',
          proposerDisplayName: 'Alice',
          partnerProfileId: 'prof_2',
          partnerDisplayName: 'Bob',
          duration: '2 weeks',
          studyPlan: 'Evenings',
          commitmentTexts: ['Design Schema', 'Build API'],
        );

        final json = original.toJson();
        final reconstructed = LearningPact.fromJson(json);

        expect(reconstructed.id, original.id);
        expect(reconstructed.module, 'learning');
        expect(reconstructed.title, original.title);
        expect(reconstructed.sharedGoal, original.sharedGoal);
        expect(reconstructed.duration, '2 weeks');
        expect(reconstructed.studyPlan, 'Evenings');
        expect(reconstructed.participants.length, 2);
        expect(reconstructed.commitments.length, 2);
        expect(reconstructed.status, LearningPactStatus.pending);
      });

      test('redacts toString representation', () {
        final pact = LearningPact.propose(
          id: 'pact_secret',
          title: 'Confidential App',
          sharedGoal: 'Top secret objective',
          proposerProfileId: 'prof_1',
          proposerDisplayName: 'Secret Proposer',
          partnerProfileId: 'prof_2',
          partnerDisplayName: 'Secret Partner',
        );

        final str = pact.toString();
        expect(str, contains('private terms omitted'));
        expect(str, isNot(contains('Top secret objective')));
      });
    });
  });
}
