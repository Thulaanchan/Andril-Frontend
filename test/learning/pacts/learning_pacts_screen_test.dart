import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/pacts/domain/entities/learning_pact.dart';
import 'package:andril_mobile/features/learning/pacts/domain/repositories/i_learning_pacts_repository.dart';
import 'package:andril_mobile/features/learning/pacts/presentation/screens/learning_pact_progress_screen.dart';
import 'package:andril_mobile/features/learning/pacts/presentation/screens/learning_pacts_hub_screen.dart';
import 'package:andril_mobile/features/learning/pacts/presentation/viewmodels/learning_pacts_viewmodel.dart';
import 'package:andril_mobile/features/learning/pacts/presentation/widgets/end_pact_dialog.dart';
import 'package:andril_mobile/features/learning/pacts/presentation/widgets/pact_invitation_bottom_sheet.dart';

class _FakeSessionController extends ChangeNotifier
    implements SessionController {
  SessionPhase _stubPhase;
  final Set<VoidCallback> _clearers = {};

  _FakeSessionController({SessionPhase phase = SessionPhase.signedIn})
      : _stubPhase = phase;

  @override
  SessionPhase get phase => _stubPhase;

  @override
  bool get moduleHomeAuthorized => false;

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clear) {
    _clearers.add(clear);
    return () => _clearers.remove(clear);
  }

  void triggerPrivateStateClearers() {
    for (final clearer in List.of(_clearers)) {
      clearer();
    }
  }

  void setPhase(SessionPhase phase) {
    _stubPhase = phase;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePactsScreenRepository implements ILearningPactsRepository {
  bool isBackendActivated;
  List<LearningPact> pacts;
  Completer<void>? delayCompleter;
  bool shouldFail = false;
  String? errorMessage;

  _FakePactsScreenRepository({
    List<LearningPact>? pacts,
  })  : isBackendActivated = true,
        pacts = pacts ?? [];

  @override
  Future<LearningPactsResult<List<LearningPact>>> getPacts() async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningPactsResult.failure(
        errorMessage: LearningPactsViewModel.disconnectedNotice,
        failureType: LearningPactsFailureType.serviceUnavailable,
      );
    }
    if (shouldFail) {
      return LearningPactsResult.failure(
        errorMessage: errorMessage ?? 'Failed to load pacts',
        failureType: LearningPactsFailureType.unknown,
      );
    }
    return LearningPactsResult.success(pacts);
  }

  @override
  Future<LearningPactsResult<LearningPact>> getPactById(String pactId) async {
    if (delayCompleter != null) await delayCompleter!.future;
    final pact = pacts.where((p) => p.id == pactId).firstOrNull;
    if (pact == null) {
      return const LearningPactsResult.failure(
        errorMessage: 'Not found',
        failureType: LearningPactsFailureType.notFound,
      );
    }
    return LearningPactsResult.success(pact);
  }

  @override
  Future<LearningPactsResult<LearningPact>> proposePact({
    required String title,
    required String sharedGoal,
    required String partnerProfileId,
    required String partnerDisplayName,
    String? partnerAvatarUrl,
    String? duration,
    String? studyPlan,
    Iterable<String>? commitmentTexts,
  }) async {
    final pact = LearningPact.propose(
      id: 'pact_${pacts.length + 1}',
      title: title,
      sharedGoal: sharedGoal,
      proposerProfileId: 'current_learner_prof',
      proposerDisplayName: 'Current Learner',
      partnerProfileId: partnerProfileId,
      partnerDisplayName: partnerDisplayName,
      partnerAvatarUrl: partnerAvatarUrl,
      duration: duration,
      studyPlan: studyPlan,
      commitmentTexts: commitmentTexts,
    );
    pacts.add(pact);
    return LearningPactsResult.success(pact);
  }

  @override
  Future<LearningPactsResult<LearningPact>> acceptPact(String pactId) async {
    final idx = pacts.indexWhere((p) => p.id == pactId);
    if (idx != -1) {
      final existing = pacts[idx];
      final updatedParts = existing.participants.map((p) {
        if (p.participantProfileId == 'current_learner_prof') {
          return p.copyWith(
              decision: PactInvitationDecision.accepted,
              agreedAt: DateTime.now());
        }
        return p;
      }).toList();
      final allAccepted = updatedParts
          .every((p) => p.decision == PactInvitationDecision.accepted);
      final updated = existing.copyWith(
        participants: updatedParts,
        status: allAccepted
            ? LearningPactStatus.active
            : LearningPactStatus.pending,
      );
      pacts[idx] = updated;
      return LearningPactsResult.success(updated);
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Not found',
      failureType: LearningPactsFailureType.notFound,
    );
  }

  @override
  Future<LearningPactsResult<LearningPact>> declinePact(String pactId) async {
    final idx = pacts.indexWhere((p) => p.id == pactId);
    if (idx != -1) {
      final existing = pacts[idx];
      final updatedParts = existing.participants.map((p) {
        if (p.participantProfileId == 'current_learner_prof') {
          return p.copyWith(decision: PactInvitationDecision.declined);
        }
        return p;
      }).toList();
      final updated = existing.copyWith(participants: updatedParts);
      pacts[idx] = updated;
      return LearningPactsResult.success(updated);
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Not found',
      failureType: LearningPactsFailureType.notFound,
    );
  }

  @override
  Future<LearningPactsResult<LearningPact>> cancelPact(String pactId) async {
    final idx = pacts.indexWhere((p) => p.id == pactId);
    if (idx != -1) {
      final updated = pacts[idx].copyWith(status: LearningPactStatus.cancelled);
      pacts[idx] = updated;
      return LearningPactsResult.success(updated);
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Not found',
      failureType: LearningPactsFailureType.notFound,
    );
  }

  @override
  Future<LearningPactsResult<LearningPact>> withdrawPact(String pactId) async {
    final idx = pacts.indexWhere((p) => p.id == pactId);
    if (idx != -1) {
      final updated = pacts[idx].copyWith(status: LearningPactStatus.cancelled);
      pacts[idx] = updated;
      return LearningPactsResult.success(updated);
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Not found',
      failureType: LearningPactsFailureType.notFound,
    );
  }

  @override
  Future<LearningPactsResult<LearningPact>> confirmCompletion(
      String pactId) async {
    final idx = pacts.indexWhere((p) => p.id == pactId);
    if (idx != -1) {
      final existing = pacts[idx];
      final updatedParts = existing.participants.map((p) {
        if (p.participantProfileId == 'current_learner_prof') {
          return p.copyWith(completionConfirmed: true);
        }
        return p;
      }).toList();
      final allDone = updatedParts.every((p) => p.completionConfirmed);
      final updated = existing.copyWith(
        participants: updatedParts,
        status:
            allDone ? LearningPactStatus.completed : LearningPactStatus.active,
      );
      pacts[idx] = updated;
      return LearningPactsResult.success(updated);
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Not found',
      failureType: LearningPactsFailureType.notFound,
    );
  }

  @override
  Future<LearningPactsResult<LearningPact>> updateCommitmentProgress({
    required String pactId,
    required String commitmentId,
    required bool isCompleted,
  }) async {
    final idx = pacts.indexWhere((p) => p.id == pactId);
    if (idx != -1) {
      final existing = pacts[idx];
      final updatedCmts = existing.commitments.map((c) {
        if (c.id == commitmentId) {
          return c.copyWith(isCompleted: isCompleted);
        }
        return c;
      }).toList();
      final updated = existing.copyWith(commitments: updatedCmts);
      pacts[idx] = updated;
      return LearningPactsResult.success(updated);
    }
    return const LearningPactsResult.failure(
      errorMessage: 'Not found',
      failureType: LearningPactsFailureType.notFound,
    );
  }
}

Widget _buildTestApp({
  required LearningPactsViewModel viewModel,
  Size size = const Size(360, 640),
  double textScaleFactor = 1.0,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(textScaleFactor),
    ),
    child: MaterialApp(
      home: LearningPactsHubScreen(viewModel: viewModel),
    ),
  );
}

void main() {
  late _FakeSessionController sessionController;
  late _FakePactsScreenRepository repository;
  late LearningPact activePact;
  late LearningPact incomingPact;
  late LearningPact outgoingPact;
  late LearningPact completedPact;

  setUp(() {
    sessionController = _FakeSessionController(phase: SessionPhase.signedIn);
    repository = _FakePactsScreenRepository();

    activePact = LearningPact.create(
      id: 'pact_act_1',
      title: 'Mobile Architecture Sprint',
      sharedGoal: 'Build Clean Architecture Flutter App',
      duration: '4 Weeks',
      studyPlan: '3 days/week',
      proposerProfileId: 'current_learner_prof',
      proposerDisplayName: 'Current Learner',
      status: LearningPactStatus.active,
      participants: [
        PactParticipation(
          participantProfileId: 'current_learner_prof',
          participantDisplayName: 'Current Learner',
          decision: PactInvitationDecision.accepted,
        ),
        PactParticipation(
          participantProfileId: 'partner_prof_1',
          participantDisplayName: 'Ada Lovelace',
          decision: PactInvitationDecision.accepted,
        ),
      ],
      commitments: [
        PactCommitment(
          id: 'cmt_1',
          pactId: 'pact_act_1',
          text: 'Design domain layer',
          isCompleted: true,
        ),
        PactCommitment(
          id: 'cmt_2',
          pactId: 'pact_act_1',
          text: 'Implement presentation layer',
          isCompleted: false,
        ),
      ],
      history: [
        PactHistoryEvent(
          id: 'hist_1',
          pactId: 'pact_act_1',
          title: 'Pact Proposed',
          description: 'Current Learner proposed this pact.',
          type: PactHistoryEventType.proposal,
        ),
        PactHistoryEvent(
          id: 'hist_2',
          pactId: 'pact_act_1',
          title: 'Pact Activated',
          description: 'Both participants voluntarily accepted.',
          type: PactHistoryEventType.agreed,
        ),
      ],
    );

    incomingPact = LearningPact.propose(
      id: 'pact_inc_1',
      title: 'System Design Deep Dive',
      sharedGoal: 'Study Distributed Systems',
      proposerProfileId: 'partner_prof_2',
      proposerDisplayName: 'Grace Hopper',
      partnerProfileId: 'current_learner_prof',
      partnerDisplayName: 'Current Learner',
      commitmentTexts: ['Read DDIA Ch 1-5', 'Build Raft consensus'],
    );

    outgoingPact = LearningPact.propose(
      id: 'pact_out_1',
      title: 'Algorithms Mastery',
      sharedGoal: 'LeetCode practice',
      proposerProfileId: 'current_learner_prof',
      proposerDisplayName: 'Current Learner',
      partnerProfileId: 'partner_prof_3',
      partnerDisplayName: 'Alan Turing',
    );

    completedPact = LearningPact.create(
      id: 'pact_comp_1',
      title: 'Dart Generics Mastery',
      sharedGoal: 'Advanced Dart typing',
      proposerProfileId: 'current_learner_prof',
      proposerDisplayName: 'Current Learner',
      status: LearningPactStatus.completed,
      participants: [
        PactParticipation(
          participantProfileId: 'current_learner_prof',
          participantDisplayName: 'Current Learner',
          decision: PactInvitationDecision.accepted,
          completionConfirmed: true,
        ),
        PactParticipation(
          participantProfileId: 'partner_prof_1',
          participantDisplayName: 'Ada Lovelace',
          decision: PactInvitationDecision.accepted,
          completionConfirmed: true,
        ),
      ],
    );
  });

  group('LearningPactsHubScreen Widget Tests', () {
    testWidgets('renders disconnected notice banner and empty active state',
        (tester) async {
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('banner_disconnected_notice')),
          findsOneWidget);
      expect(
          find.text(LearningPactsViewModel.disconnectedNotice), findsOneWidget);
      expect(find.byKey(const ValueKey('view_pacts_empty')), findsOneWidget);
      expect(find.text('No Active Learning Pacts'), findsOneWidget);
      expect(find.byKey(const ValueKey('button_propose_pact')), findsOneWidget);

      vm.dispose();
    });

    testWidgets('renders loading indicator when status is loading',
        (tester) async {
      repository.delayCompleter = Completer<void>();
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pump();

      expect(find.byKey(const ValueKey('loading_indicator')), findsOneWidget);

      repository.delayCompleter!.complete();
      await tester.pumpAndSettle();
      vm.dispose();
    });

    testWidgets('renders access denied state when user is not authorized',
        (tester) async {
      sessionController.setPhase(SessionPhase.signedOut);
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_access_denied')), findsOneWidget);
      expect(find.text('Access Denied'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders service unavailable with retry button',
        (tester) async {
      repository.isBackendActivated = false;
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_unavailable')), findsOneWidget);
      expect(find.byKey(const ValueKey('button_retry')), findsOneWidget);

      // Now restore backend and tap retry
      repository.isBackendActivated = true;
      await tester.tap(find.byKey(const ValueKey('button_retry')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('view_pacts_empty')), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders populated active tab with pact cards and badges',
        (tester) async {
      repository.pacts = [
        activePact,
        incomingPact,
        outgoingPact,
        completedPact
      ];
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('list_active_pacts')), findsOneWidget);
      expect(find.text('Mobile Architecture Sprint'), findsOneWidget);
      expect(find.text('Active Pact'), findsOneWidget);
      expect(find.textContaining('Ada Lovelace'), findsOneWidget);
      expect(find.text('View Progress'), findsOneWidget);

      vm.dispose();
    });

    testWidgets(
        'switches to Invitations tab and renders incoming and outgoing sections',
        (tester) async {
      repository.pacts = [activePact, incomingPact, outgoingPact];
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Tap on Invitations tab
      await tester.tap(find.byKey(const ValueKey('tab_invitations')));
      await tester.pumpAndSettle();

      expect(find.text('Received Invitations (1)'), findsOneWidget);
      expect(find.text('System Design Deep Dive'), findsOneWidget);
      expect(find.text('Review Invitation'), findsOneWidget);

      expect(find.text('Outgoing Proposals (1)'), findsOneWidget);
      expect(find.text('Algorithms Mastery'), findsOneWidget);

      vm.dispose();
    });

    testWidgets('switches to History tab and renders past pacts',
        (tester) async {
      repository.pacts = [completedPact];
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab_history')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('list_history_pacts')), findsOneWidget);
      expect(find.text('Dart Generics Mastery'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      vm.dispose();
    });

    testWidgets('search filters pacts dynamically by query', (tester) async {
      repository.pacts = [
        activePact,
        LearningPact.create(
          id: 'pact_act_2',
          title: 'Quantum Computing Intro',
          sharedGoal: 'Qiskit fundamentals',
          proposerProfileId: 'current_learner_prof',
          proposerDisplayName: 'Current Learner',
          status: LearningPactStatus.active,
          participants: [
            PactParticipation(
              participantProfileId: 'current_learner_prof',
              participantDisplayName: 'Current Learner',
              decision: PactInvitationDecision.accepted,
            ),
            PactParticipation(
              participantProfileId: 'partner_prof_q',
              participantDisplayName: 'Richard Feynman',
              decision: PactInvitationDecision.accepted,
            ),
          ],
        ),
      ];

      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.text('Mobile Architecture Sprint'), findsOneWidget);
      expect(find.text('Quantum Computing Intro'), findsOneWidget);

      // Enter search query
      await tester.enterText(
          find.byKey(const ValueKey('input_pacts_search')), 'Quantum');
      await tester.pumpAndSettle();

      expect(find.text('Quantum Computing Intro'), findsOneWidget);
      expect(find.text('Mobile Architecture Sprint'), findsNothing);

      // Clear search query
      await tester.tap(find.byKey(const ValueKey('button_clear_search')));
      await tester.pumpAndSettle();

      expect(find.text('Mobile Architecture Sprint'), findsOneWidget);
      expect(find.text('Quantum Computing Intro'), findsOneWidget);

      vm.dispose();
    });

    testWidgets('tapping Propose Pact button opens ProposePactFlowScreen',
        (tester) async {
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_propose_pact')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('screen_propose_pact_flow')),
          findsOneWidget);
      expect(find.text('Pact Details'), findsOneWidget);

      vm.dispose();
    });
  });

  group('PactInvitationBottomSheet Widget Tests', () {
    testWidgets(
        'renders mutual acceptance disclaimer, terms, and action buttons',
        (tester) async {
      bool accepted = false;
      bool declined = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  PactInvitationBottomSheet.show(
                    ctx,
                    pact: incomingPact,
                    onAccept: () => accepted = true,
                    onDecline: () => declined = true,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('sheet_pact_invitation')), findsOneWidget);
      expect(find.text('System Design Deep Dive'), findsOneWidget);
      expect(find.text('Study Distributed Systems'), findsOneWidget);
      expect(
          find.textContaining('starts only after you accept'), findsOneWidget);
      expect(find.text('Accept Pact'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);

      // Tap Accept
      await tester.tap(find.text('Accept Pact'));
      await tester.pumpAndSettle();

      expect(accepted, isTrue);
      expect(declined, isFalse);
    });
  });

  group('EndPactDialog Widget Tests', () {
    testWidgets('renders voluntary exit confirmation and triggers callback',
        (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  EndPactDialog.show(
                    ctx,
                    onConfirmEnd: () async {
                      confirmed = true;
                      return true;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dialog_end_pact_participation')),
          findsOneWidget);
      expect(find.text('End your participation?'), findsOneWidget);
      expect(find.text('End Participation'), findsOneWidget);
      expect(find.text('Keep Participating'), findsOneWidget);

      // Tap End Participation
      await tester.tap(find.text('End Participation'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });
  });

  group('LearningPactProgressScreen Widget Tests', () {
    testWidgets(
        'renders pact progress details, milestone toggles, and history modal',
        (tester) async {
      repository.pacts = [activePact];
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: LearningPactProgressScreen(
            viewModel: vm,
            pactId: activePact.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('screen_learning_pact_progress')),
          findsOneWidget);
      expect(find.text('Mobile Architecture Sprint'), findsOneWidget);
      expect(find.text('Active Pact'), findsOneWidget);
      expect(find.text('Participants'), findsOneWidget);
      expect(find.text('Agreed Milestones'), findsOneWidget);

      // Verify milestone toggling
      final checkboxFinder =
          find.byKey(const ValueKey('checkbox_commitment_cmt_2'));
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      expect(vm.activePacts.first.commitments[1].isCompleted, isTrue);

      // Tap View Activity History in app bar
      await tester.tap(find.byKey(const ValueKey('button_app_bar_history')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('sheet_pact_activity_history')),
          findsOneWidget);
      expect(find.text('Pact Activity History'), findsOneWidget);
      expect(find.text('Pact Proposed'), findsOneWidget);

      vm.dispose();
    });
  });

  group('Responsive Viewport Tests (320dp, 360dp, 412dp, 1.5x font scale)', () {
    testWidgets('renders 320dp viewport without overflow', (tester) async {
      repository.pacts = [activePact, incomingPact];
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      final error = tester.takeException();
      if (error is FlutterError) {
        // ignore: avoid_print
        print('1.5x test overflow error deep: ${error.toStringDeep()}');
      }
      expect(error, isNull);
      vm.dispose();
    });

    testWidgets('renders 360dp viewport without overflow', (tester) async {
      repository.pacts = [activePact, incomingPact];
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        size: const Size(360, 640),
      ));
      await tester.pumpAndSettle();

      final error = tester.takeException();
      if (error is FlutterError) {
        // ignore: avoid_print
        print('1.5x test overflow error deep: ${error.toStringDeep()}');
      }
      expect(error, isNull);
      vm.dispose();
    });

    testWidgets('renders 412dp viewport without overflow', (tester) async {
      repository.pacts = [activePact, incomingPact];
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        size: const Size(412, 915),
      ));
      await tester.pumpAndSettle();

      final error = tester.takeException();
      if (error is FlutterError) {
        // ignore: avoid_print
        print('1.5x test overflow error deep: ${error.toStringDeep()}');
      }
      expect(error, isNull);
      vm.dispose();
    });

    testWidgets('renders 1.5x dynamic font scale without overflow',
        (tester) async {
      repository.pacts = [activePact, incomingPact];
      final vm = LearningPactsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        size: const Size(360, 640),
        textScaleFactor: 1.5,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      vm.dispose();
    });
  });
}
