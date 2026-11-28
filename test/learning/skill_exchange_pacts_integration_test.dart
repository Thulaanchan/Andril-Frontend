import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/router/learning_router.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/pacts/data/repositories/learning_pacts_repository.dart';
import 'package:andril_mobile/features/learning/pacts/domain/entities/learning_pact.dart';
import 'package:andril_mobile/features/learning/pacts/domain/repositories/i_learning_pacts_repository.dart';
import 'package:andril_mobile/features/learning/pacts/presentation/screens/propose_pact_flow_screen.dart';
import 'package:andril_mobile/features/learning/pacts/presentation/viewmodels/learning_pacts_viewmodel.dart';
import 'package:andril_mobile/features/learning/profile/domain/entities/learning_profile.dart';
import 'package:andril_mobile/features/learning/profile/domain/repositories/profile_repository.dart';
import 'package:andril_mobile/features/learning/skill_exchange/presentation/screens/skill_exchange_hub_screen.dart';

class _Session extends ChangeNotifier implements SessionController {
  final Set<VoidCallback> clearers = {};
  @override
  SessionPhase get phase => SessionPhase.signedIn;
  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clear) {
    clearers.add(clear);
    return () => clearers.remove(clear);
  }

  void revoke() {
    for (final clear in List.of(clearers)) {
      clear();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements ILearningPactsRepository {
  List<LearningPact> pacts = [];
  int reads = 0;
  int writes = 0;
  bool denyReads = false;
  Future<LearningPactsResult<LearningPact>> Function()? action;
  Future<LearningPactsResult<LearningPact>> write() {
    writes++;
    return action?.call() ??
        Future.value(const LearningPactsResult.failure(
            errorMessage: 'Unavailable',
            failureType: LearningPactsFailureType.serviceUnavailable));
  }

  @override
  Future<LearningPactsResult<List<LearningPact>>> getPacts() async {
    reads++;
    if (denyReads) {
      return const LearningPactsResult.failure(
        errorMessage: 'Access denied',
        failureType: LearningPactsFailureType.accessDenied,
      );
    }
    return LearningPactsResult.success(List.of(pacts));
  }

  @override
  Future<LearningPactsResult<LearningPact>> getPactById(String pactId) =>
      write();
  @override
  Future<LearningPactsResult<LearningPact>> proposePact(
          {required String title,
          required String sharedGoal,
          required String partnerProfileId,
          required String partnerDisplayName,
          String? partnerAvatarUrl,
          String? duration,
          String? studyPlan,
          Iterable<String>? commitmentTexts}) =>
      write();
  @override
  Future<LearningPactsResult<LearningPact>> acceptPact(String pactId) =>
      write();
  @override
  Future<LearningPactsResult<LearningPact>> declinePact(String pactId) =>
      write();
  @override
  Future<LearningPactsResult<LearningPact>> cancelPact(String pactId) =>
      write();
  @override
  Future<LearningPactsResult<LearningPact>> withdrawPact(String pactId) =>
      write();
  @override
  Future<LearningPactsResult<LearningPact>> confirmCompletion(String pactId) =>
      write();
  @override
  Future<LearningPactsResult<LearningPact>> updateCommitmentProgress(
          {required String pactId,
          required String commitmentId,
          required bool isCompleted}) =>
      write();
}

LearningPact _pending({bool outgoing = false, String partner = 'partner'}) =>
    LearningPact.propose(
      id: 'pact',
      title: 'Study together',
      sharedGoal: 'Learn Dart',
      proposerProfileId: outgoing ? 'current_learner_prof' : partner,
      proposerDisplayName: 'Proposer',
      partnerProfileId: outgoing ? partner : 'current_learner_prof',
      partnerDisplayName: 'Invitee',
    );
LearningPact _active() => LearningPact.create(
      id: 'pact',
      title: 'Study together',
      sharedGoal: 'Learn Dart',
      proposerProfileId: 'current_learner_prof',
      proposerDisplayName: 'Proposer',
      status: LearningPactStatus.active,
      participants: [
        PactParticipation(
            participantProfileId: 'current_learner_prof',
            participantDisplayName: 'Proposer',
            decision: PactInvitationDecision.accepted),
        PactParticipation(
            participantProfileId: 'partner',
            participantDisplayName: 'Partner',
            decision: PactInvitationDecision.accepted),
      ],
      commitments: [
        PactCommitment(id: 'commitment', pactId: 'pact', text: 'Practice')
      ],
    );

class _Allowed implements LearningAccessPolicy {
  @override
  bool get isAuthenticated => true;
  @override
  bool get isLearningActivated => true;
}

class _Profiles implements ProfileRepository {
  _Profiles(this.load);
  final Future<ProfileResult<LearningProfile>> Function() load;
  @override
  Future<ProfileResult<LearningProfile>> getProfile() => load();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  LearningProfile serverProfile({bool activated = true}) => LearningProfile(
        profileId: 'server-profile',
        accountId: 'server-account',
        displayName: 'Verified learner',
        isActivated: activated,
      );

  test(
      'activated profile success uses only the backend-issued Learning identity',
      () async {
    final repository = _Repository()
      ..pacts = [
        LearningPact.propose(
          id: 'server-pact',
          title: 'Study',
          sharedGoal: 'Learn',
          proposerProfileId: 'partner',
          proposerDisplayName: 'Partner',
          partnerProfileId: 'server-profile',
          partnerDisplayName: 'Verified learner',
        )
      ];
    final vm = LearningPactsViewModel(
      repository: repository,
      currentProfileId: '',
      isLearningActivated: true,
      profileRepository: _Profiles(
          () async => ProfileSuccess<LearningProfile>(serverProfile())),
    );
    addTearDown(vm.dispose);
    await vm.initialize();
    expect(vm.currentProfileId, 'server-profile');
    expect(vm.incomingInvitations.single.id, 'server-pact');
    expect(repository.reads, 1);
  });

  final rejectedProfiles = <String, ProfileResult<LearningProfile>>{
    'denied': const ProfileAccessDenied<LearningProfile>(),
    'not found': const ProfileNotFound<LearningProfile>(),
    'unavailable': const ProfileDependencyUnavailable<LearningProfile>(),
    'inactive':
        ProfileSuccess<LearningProfile>(serverProfile(activated: false)),
  };
  for (final entry in rejectedProfiles.entries) {
    test('${entry.key} profile cannot authorize pact reads', () async {
      final repository = _Repository();
      final vm = LearningPactsViewModel(
        repository: repository,
        currentProfileId: '',
        isLearningActivated: true,
        profileRepository: _Profiles(() async => entry.value),
      );
      addTearDown(vm.dispose);
      await vm.initialize();
      expect(vm.currentProfileId, isEmpty);
      expect(vm.allPacts, isEmpty);
      expect(repository.reads, 0);
      expect(
          vm.status,
          entry.key == 'denied'
              ? LearningPactsViewStatus.accessDenied
              : LearningPactsViewStatus.unavailableService);
    });
  }

  test(
      'late profile success after revocation cannot install an identity or read pacts',
      () async {
    final pending = Completer<ProfileResult<LearningProfile>>();
    final session = _Session();
    final repository = _Repository();
    final vm = LearningPactsViewModel(
      repository: repository,
      sessionController: session,
      currentProfileId: '',
      isLearningActivated: true,
      profileRepository: _Profiles(() => pending.future),
    );
    addTearDown(session.dispose);
    addTearDown(vm.dispose);
    final loading = vm.initialize();
    session.revoke();
    pending.complete(ProfileSuccess<LearningProfile>(serverProfile()));
    await loading;
    expect(vm.currentProfileId, isEmpty);
    expect(repository.reads, 0);
    expect(vm.status, LearningPactsViewStatus.accessDenied);
  });

  final operations = <String, Future<bool> Function(LearningPactsViewModel)>{
    'propose': (vm) => vm.proposePact(
        title: 'Study together',
        sharedGoal: 'Learn Dart',
        partnerProfileId: 'partner',
        partnerDisplayName: 'Partner'),
    'accept': (vm) => vm.acceptPact('pact'),
    'decline': (vm) => vm.declinePact('pact'),
    'cancel': (vm) => vm.cancelPact('pact'),
    'withdraw': (vm) => vm.withdrawPact('pact'),
    'complete': (vm) => vm.confirmCompletion('pact'),
    'progress': (vm) => vm.toggleCommitment(
        pactId: 'pact', commitmentId: 'commitment', isCompleted: true),
  };
  LearningPact fixture(String name) => name == 'cancel' || name == 'propose'
      ? _pending(outgoing: true)
      : name == 'accept' || name == 'decline'
          ? _pending()
          : _active();

  test('activation flag cannot fabricate a successful remote list or lookup',
      () async {
    const repository = LearningPactsRepository(isBackendActivated: true);
    expect((await repository.getPacts()).failureType,
        LearningPactsFailureType.serviceUnavailable);
    expect((await repository.getPactById('pact')).failureType,
        LearningPactsFailureType.serviceUnavailable);
  });

  for (final entry in operations.entries) {
    test('${entry.key}: repository failure cannot fabricate persistence',
        () async {
      final repository = _Repository()..pacts = [fixture(entry.key)];
      final vm = LearningPactsViewModel(
          repository: repository, isLearningActivated: true);
      addTearDown(vm.dispose);
      await vm.initialize();
      final before = vm.allPacts;
      expect(await entry.value(vm), isFalse);
      expect(repository.writes, 1);
      expect(vm.allPacts, before);
      expect(vm.errorMessage, 'Unavailable');
    });
    test(
        '${entry.key}: stale successful response after revocation is discarded',
        () async {
      final completer = Completer<LearningPactsResult<LearningPact>>();
      final repository = _Repository()
        ..pacts = [fixture(entry.key)]
        ..action = () => completer.future;
      final session = _Session();
      final vm = LearningPactsViewModel(
          repository: repository,
          sessionController: session,
          isLearningActivated: true);
      addTearDown(vm.dispose);
      addTearDown(session.dispose);
      await vm.initialize();
      final pending = entry.value(vm);
      session.revoke();
      completer.complete(LearningPactsResult.success(fixture(entry.key)));
      expect(await pending, isFalse);
      expect(vm.allPacts, isEmpty);
      expect(vm.status, LearningPactsViewStatus.accessDenied);
      expect(await entry.value(vm), isFalse);
      expect(repository.writes, 1);
    });
  }

  test('concurrent proposals to the same partner issue one repository call',
      () async {
    final completer = Completer<LearningPactsResult<LearningPact>>();
    final repository = _Repository()..action = () => completer.future;
    final vm = LearningPactsViewModel(
        repository: repository, isLearningActivated: true);
    addTearDown(vm.dispose);
    final first = operations['propose']!(vm);
    expect(await operations['propose']!(vm), isFalse);
    expect(repository.writes, 1);
    completer.complete(LearningPactsResult.success(_pending(outgoing: true)));
    expect(await first, isTrue);
    expect(vm.pendingPacts, hasLength(1));
  });

  test(
      'late operation error after disposal cannot notify or restore private state',
      () async {
    final completer = Completer<LearningPactsResult<LearningPact>>();
    final repository = _Repository()..action = () => completer.future;
    final vm = LearningPactsViewModel(
        repository: repository, isLearningActivated: true);
    final pending = operations['propose']!(vm);
    vm.dispose();
    completer.completeError(StateError('Synthetic unavailable response'));
    expect(await pending, isFalse);
    expect(vm.allPacts, isEmpty);
  });

  test('unauthorized lifecycle transitions never reach the repository',
      () async {
    final repository = _Repository()..pacts = [_pending(outgoing: true)];
    final vm = LearningPactsViewModel(
        repository: repository, isLearningActivated: true);
    addTearDown(vm.dispose);
    await vm.initialize();
    expect(await vm.acceptPact('pact'), isFalse);
    expect(await vm.declinePact('pact'), isFalse);
    expect(await vm.withdrawPact('pact'), isFalse);
    expect(await vm.confirmCompletion('pact'), isFalse);
    expect(
        await vm.toggleCommitment(
            pactId: 'pact', commitmentId: 'missing', isCompleted: true),
        isFalse);
    expect(repository.writes, 0);
  });

  test('foreign participation is excluded and result lists are immutable',
      () async {
    final foreign = LearningPact.propose(
        id: 'foreign',
        title: 'Private',
        sharedGoal: 'Private',
        proposerProfileId: 'other',
        proposerDisplayName: 'Other',
        partnerProfileId: 'third',
        partnerDisplayName: 'Third');
    final repository = _Repository()..pacts = [foreign, _pending()];
    final vm = LearningPactsViewModel(
        repository: repository, isLearningActivated: true);
    addTearDown(vm.dispose);
    await vm.initialize();
    expect(vm.allPacts.map((p) => p.id), ['pact']);
    expect(() => vm.allPacts.clear(), throwsUnsupportedError);
  });

  test('a mismatched mutation response cannot replace a pact', () async {
    final returned = _pending().copyWith(id: 'different');
    final repository = _Repository()
      ..pacts = [_pending()]
      ..action = () async => LearningPactsResult.success(returned);
    final vm = LearningPactsViewModel(
        repository: repository, isLearningActivated: true);
    addTearDown(vm.dispose);
    await vm.initialize();
    expect(await vm.acceptPact('pact'), isFalse);
    expect(vm.allPacts.single.id, 'pact');
  });

  test('denied reload purges cached pact details and blocks later writes',
      () async {
    final repository = _Repository()..pacts = [_pending()];
    final vm = LearningPactsViewModel(
      repository: repository,
      isLearningActivated: true,
    );
    addTearDown(vm.dispose);
    await vm.initialize();
    expect(vm.allPacts, hasLength(1));
    repository.denyReads = true;
    await vm.initialize(force: true);
    expect(vm.allPacts, isEmpty);
    expect(vm.status, LearningPactsViewStatus.accessDenied);
    expect(await operations['propose']!(vm), isFalse);
    expect(repository.writes, 0);
  });

  testWidgets('production exchange route is unavailable and links to pacts',
      (tester) async {
    final router = createLearningRouter(
        accessPolicy: _Allowed(), initialLocation: '/learning/skill-exchange');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('card_hub_unavailable')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab_discover_partners')), findsNothing);
    await tester.tap(find.byTooltip('Learning Pacts'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Skill Exchange'), findsOneWidget);
    await tester.tap(find.byTooltip('Skill Exchange'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('card_hub_unavailable')), findsOneWidget);
  });

  testWidgets('proposal form invents no partner or study schedule',
      (tester) async {
    final repository = _Repository();
    final vm = LearningPactsViewModel(repository: repository);
    addTearDown(vm.dispose);
    await tester
        .pumpWidget(MaterialApp(home: ProposePactFlowScreen(viewModel: vm)));
    // Hint text is not an entered value and is never submitted by the form.
    for (final key in ['input_pact_duration', 'input_pact_study_plan']) {
      final field = tester.widget<TextFormField>(find.byKey(ValueKey(key)));
      expect(field.controller!.text, isEmpty);
    }
    await tester.enterText(
        find.byKey(const ValueKey('input_pact_title')), 'Study together');
    await tester.enterText(
        find.byKey(const ValueKey('input_pact_goal')), 'Learn Dart');
    await tester.tap(find.byKey(const ValueKey('btn_step1_continue')));
    await tester.pumpAndSettle();
    expect(
        tester.widget<ListView>(find.byType(ListView)).semanticChildCount, 0);
    expect(find.text('Naveen R.'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('btn_step2_continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('btn_submit_propose_pact')), findsNothing);
    expect(repository.writes, 0);
  });

  testWidgets(
      'exchange account switch clears private search even with the same profile id',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: SkillExchangeHubScreen(
      currentUserId: 'profile',
      currentAccountId: 'first',
    )));
    await tester.enterText(find.byType(TextField).first, 'Private search');
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(
        home: SkillExchangeHubScreen(
      currentUserId: 'profile',
      currentAccountId: 'second',
    )));
    await tester.pump();
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isEmpty);
  });
}
