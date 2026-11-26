import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/domain/entities/learning_growth_evidence.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/domain/entities/learning_mentorship.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/domain/repositories/i_learning_growth_repository.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/presentation/screens/learning_mentorship_hub_screen.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/presentation/screens/mentorship_agreement_screen.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/presentation/screens/request_mentorship_screen.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/presentation/viewmodels/learning_mentorship_viewmodel.dart';

class _FakeSessionController extends ChangeNotifier
    implements SessionController {
  SessionPhase _phase;
  final Set<VoidCallback> _clearers = {};

  _FakeSessionController({SessionPhase phase = SessionPhase.signedIn})
      : _phase = phase;

  @override
  SessionPhase get phase => _phase;

  @override
  bool get moduleHomeAuthorized => false;

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clear) {
    _clearers.add(clear);
    return () => _clearers.remove(clear);
  }

  void triggerPrivateStateClearers() {
    for (final c in List.of(_clearers)) {
      c();
    }
  }

  void setPhase(SessionPhase phase) {
    _phase = phase;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMentorshipRepository implements ILearningGrowthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  bool isBackendActivated = true;
  List<LearningMentorshipOffer> offers = [];
  List<LearningMentorship> mentorships = [];
  bool shouldFail = false;
  LearningGrowthFailureType failureType = LearningGrowthFailureType.unknown;
  String? errorMessage;
  Completer<void>? delayCompleter;
  int getOffersCalls = 0;
  int getMentorshipsCalls = 0;

  @override
  Future<LearningGrowthResult<List<LearningMentorshipOffer>>>
      getMentorshipOffers() async {
    getOffersCalls++;
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    if (shouldFail) {
      return LearningGrowthResult.failure(
        errorMessage: errorMessage ?? 'Failed to load offers',
        failureType: failureType,
      );
    }
    return LearningGrowthResult.success(offers);
  }

  @override
  Future<LearningGrowthResult<List<LearningMentorship>>>
      getMentorships() async {
    getMentorshipsCalls++;
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    if (shouldFail) {
      return LearningGrowthResult.failure(
        errorMessage: errorMessage ?? 'Failed to load mentorships',
        failureType: failureType,
      );
    }
    return LearningGrowthResult.success(mentorships);
  }

  @override
  Future<LearningGrowthResult<LearningMentorship>> requestMentorship({
    required String offerId,
    required String learningGoal,
    required String message,
  }) async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    if (shouldFail) {
      return LearningGrowthResult.failure(
        errorMessage: errorMessage ?? 'Failed to request mentorship',
        failureType: failureType,
      );
    }
    final offer = offers.firstWhere(
      (o) => o.id == offerId,
      orElse: () => LearningMentorshipOffer(
        id: offerId,
        mentor: LearningMentorshipParticipant(
          accountId: 'acc_mentor_default',
          learningProfileId: 'prof_mentor_default',
          displayName: 'Default Mentor',
        ),
        specialtyTopics: const ['General Learning'],
      ),
    );
    final mentorship = LearningMentorship.request(
      id: 'mentorship_${DateTime.now().millisecondsSinceEpoch}',
      learner: LearningMentorshipParticipant(
        accountId: 'acc_learner_1',
        learningProfileId: 'prof_learner_1',
        displayName: 'Current Learner',
      ),
      offer: offer,
      learningGoal: learningGoal,
      message: message,
    );
    mentorships.add(mentorship);
    return LearningGrowthResult.success(mentorship);
  }

  @override
  Future<LearningGrowthResult<LearningMentorship>> acceptMentorship(
    String mentorshipId,
  ) async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    final index = mentorships.indexWhere((m) => m.id == mentorshipId);
    if (index == -1) {
      return const LearningGrowthResult.failure(
        errorMessage: 'Mentorship not found',
        failureType: LearningGrowthFailureType.notFound,
      );
    }
    final accepted = mentorships[index].accept(mentorships[index].mentor);
    mentorships[index] = accepted;
    return LearningGrowthResult.success(accepted);
  }

  @override
  Future<LearningGrowthResult<LearningMentorship>> declineMentorship(
    String mentorshipId,
  ) async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    final index = mentorships.indexWhere((m) => m.id == mentorshipId);
    if (index == -1) {
      return const LearningGrowthResult.failure(
        errorMessage: 'Mentorship not found',
        failureType: LearningGrowthFailureType.notFound,
      );
    }
    final declined = mentorships[index].decline(mentorships[index].mentor);
    mentorships[index] = declined;
    return LearningGrowthResult.success(declined);
  }

  @override
  Future<LearningGrowthResult<LearningMentorship>> cancelMentorship(
    String mentorshipId,
  ) async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthEvidence.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    final index = mentorships.indexWhere((m) => m.id == mentorshipId);
    if (index == -1) {
      return const LearningGrowthResult.failure(
        errorMessage: 'Mentorship not found',
        failureType: LearningGrowthFailureType.notFound,
      );
    }
    final cancelled = mentorships[index].cancel(mentorships[index].learner);
    mentorships[index] = cancelled;
    return LearningGrowthResult.success(cancelled);
  }
}

void main() {
  group('LearningMentorship - Domain Entities & Invariants', () {
    test('LearningMentorshipParticipant validates required fields', () {
      final participant = LearningMentorshipParticipant(
        accountId: 'acc_101',
        learningProfileId: 'prof_101',
        displayName: 'Alice Mentor',
      );

      expect(participant.accountId, 'acc_101');
      expect(participant.learningProfileId, 'prof_101');
      expect(participant.displayName, 'Alice Mentor');

      expect(
        () => LearningMentorshipParticipant(
          accountId: '',
          learningProfileId: 'prof_1',
          displayName: 'Name',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => LearningMentorshipParticipant(
          accountId: 'acc_1',
          learningProfileId: '  ',
          displayName: 'Name',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => LearningMentorshipParticipant(
          accountId: 'acc_1',
          learningProfileId: 'prof_1',
          displayName: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
        'LearningMentorshipOffer validates required fields and specialtyTopics',
        () {
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_mentor',
        learningProfileId: 'prof_mentor',
        displayName: 'Bob Mentor',
      );
      final offer = LearningMentorshipOffer(
        id: 'offer_1',
        mentor: mentor,
        specialtyTopics: ['Flutter', 'State Flow', ''],
      );

      expect(offer.id, 'offer_1');
      expect(offer.specialtyTopics, ['Flutter', 'State Flow']);
      expect(offer.isAvailable, isTrue);

      expect(
        () => LearningMentorshipOffer(
          id: '',
          mentor: mentor,
          specialtyTopics: ['Flutter'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('LearningMentorship strictly rejects self-mentorship', () {
      final sameProfile = LearningMentorshipParticipant(
        accountId: 'acc_1',
        learningProfileId: 'prof_same',
        displayName: 'Learner User',
      );
      final sameAccount = LearningMentorshipParticipant(
        accountId: 'acc_1',
        learningProfileId: 'prof_other',
        displayName: 'Mentor User',
      );
      final offer = LearningMentorshipOffer(
        id: 'offer_self',
        mentor: sameProfile,
        specialtyTopics: ['Flutter'],
      );

      expect(
        () => LearningMentorship.request(
          id: 'm_self_1',
          learner: sameProfile,
          offer: offer,
          learningGoal: 'Goal',
          message: 'Message',
        ),
        throwsA(isA<ArgumentError>()),
      );

      final offerSameAccount = LearningMentorshipOffer(
        id: 'offer_self_2',
        mentor: sameAccount,
        specialtyTopics: ['Flutter'],
      );
      expect(
        () => LearningMentorship.request(
          id: 'm_self_2',
          learner: sameProfile,
          offer: offerSameAccount,
          learningGoal: 'Goal',
          message: 'Message',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('LearningMentorship state transitions: accept requires mentor caller',
        () {
      final learner = LearningMentorshipParticipant(
        accountId: 'acc_learner',
        learningProfileId: 'prof_learner',
        displayName: 'Learner',
      );
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_mentor',
        learningProfileId: 'prof_mentor',
        displayName: 'Mentor',
      );
      final offer = LearningMentorshipOffer(
        id: 'offer_valid',
        mentor: mentor,
        specialtyTopics: ['Testing'],
      );

      final request = LearningMentorship.request(
        id: 'm_100',
        learner: learner,
        offer: offer,
        learningGoal: 'Master unit tests',
        message: 'Looking for weekly reviews.',
      );

      expect(request.status, LearningMentorshipStatus.pending);
      expect(request.status.isPending, isTrue);
      expect(request.isActive, isFalse);

      // Learner cannot accept own request
      expect(
        () => request.accept(learner),
        throwsA(isA<StateError>()),
      );

      // Mentor can accept
      final accepted = request.accept(mentor);
      expect(accepted.status, LearningMentorshipStatus.accepted);
      expect(accepted.status.isAccepted, isTrue);
      expect(accepted.isActive, isTrue);
      expect(accepted.updatedAt, isNotNull);

      // Cannot accept an already accepted mentorship
      expect(
        () => accepted.accept(mentor),
        throwsA(isA<StateError>()),
      );
    });

    test('LearningMentorship state transitions: decline and cancel rules', () {
      final learner = LearningMentorshipParticipant(
        accountId: 'acc_learner',
        learningProfileId: 'prof_learner',
        displayName: 'Learner',
      );
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_mentor',
        learningProfileId: 'prof_mentor',
        displayName: 'Mentor',
      );
      final offer = LearningMentorshipOffer(
        id: 'offer_valid',
        mentor: mentor,
        specialtyTopics: ['Testing'],
      );

      final request = LearningMentorship.request(
        id: 'm_101',
        learner: learner,
        offer: offer,
        learningGoal: 'Goal',
        message: 'Message',
      );

      // Learner cannot decline
      expect(
        () => request.decline(learner),
        throwsA(isA<StateError>()),
      );

      // Mentor can decline
      final declined = request.decline(mentor);
      expect(declined.status, LearningMentorshipStatus.declined);
      expect(declined.status.isDeclined, isTrue);
      expect(declined.isActive, isFalse);

      // Learner can cancel a pending request
      final request2 = LearningMentorship.request(
        id: 'm_102',
        learner: learner,
        offer: offer,
        learningGoal: 'Goal',
        message: 'Message',
      );
      final cancelled = request2.cancel(learner);
      expect(cancelled.status, LearningMentorshipStatus.cancelled);
      expect(cancelled.status.isCancelled, isTrue);
      expect(cancelled.isActive, isFalse);
    });

    test('redacted toString prevents personal details and message leakage', () {
      final learner = LearningMentorshipParticipant(
        accountId: 'acc_secret_learner',
        learningProfileId: 'prof_learner',
        displayName: 'Learner',
      );
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_secret_mentor',
        learningProfileId: 'prof_mentor',
        displayName: 'Mentor',
      );
      final offer = LearningMentorshipOffer(
        id: 'offer_secret',
        mentor: mentor,
        specialtyTopics: ['Testing'],
      );
      final mentorship = LearningMentorship.request(
        id: 'm_secret',
        learner: learner,
        offer: offer,
        learningGoal: 'Sensitive goal',
        message: 'Highly sensitive personal note.',
      );

      final str = mentorship.toString();
      expect(
          str,
          contains(
              'LearningMentorship (pending) [private references omitted]'));
      expect(str, isNot(contains('acc_secret_learner')));
      expect(str, isNot(contains('acc_secret_mentor')));
      expect(str, isNot(contains('Highly sensitive personal note')));
    });

    test('JSON serialization round-trip maintains aggregate integrity', () {
      final learner = LearningMentorshipParticipant(
        accountId: 'acc_l',
        learningProfileId: 'prof_l',
        displayName: 'Learner',
      );
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_m',
        learningProfileId: 'prof_m',
        displayName: 'Mentor',
      );
      final offer = LearningMentorshipOffer(
        id: 'offer_1',
        mentor: mentor,
        specialtyTopics: ['Dart'],
      );
      final original = LearningMentorship.request(
        id: 'm_json',
        learner: learner,
        offer: offer,
        learningGoal: 'Understand streams',
        message: 'Hello mentor',
      );

      final json = original.toJson();
      final revived = LearningMentorship.fromJson(json);

      expect(revived, equals(original));
      expect(revived.id, original.id);
      expect(revived.learner, original.learner);
      expect(revived.mentor, original.mentor);
      expect(revived.learningGoal, original.learningGoal);
      expect(revived.status, original.status);
    });
  });

  group('LearningMentorshipViewModel', () {
    late _FakeMentorshipRepository repository;
    late _FakeSessionController sessionController;

    setUp(() {
      repository = _FakeMentorshipRepository();
      sessionController = _FakeSessionController();
    });

    test('rejects unauthenticated or deactivated profile with accessDenied',
        () async {
      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: false,
        currentProfileId: 'prof_1',
      );

      await vm.initialize();

      expect(vm.status, MentorshipViewStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      expect(vm.errorMessage,
          contains('Authentication and an activated Learning profile'));
    });

    test('handles disconnected backend with unavailableService status',
        () async {
      repository.isBackendActivated = false;
      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_1',
      );

      await vm.initialize();

      expect(vm.status, MentorshipViewStatus.unavailableService);
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.errorMessage, LearningGrowthEvidence.disconnectedNotice);
    });

    test('successfully initializes and loads offers and mentorships', () async {
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_m1',
        learningProfileId: 'prof_m1',
        displayName: 'Mentor Bob',
      );
      repository.offers = [
        LearningMentorshipOffer(
          id: 'offer_10',
          mentor: mentor,
          specialtyTopics: const ['Clean Architecture', 'Testing'],
        ),
      ];

      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_learner_1',
      );

      await vm.initialize();

      expect(vm.status, MentorshipViewStatus.ready);
      expect(vm.isReady, isTrue);
      expect(vm.offers.length, 1);
      expect(vm.offers.first.id, 'offer_10');
      expect(vm.pendingRequestsCount, 0);
      expect(vm.activeAgreementsCount, 0);
    });

    test('switches tabs smoothly and notifies listeners', () async {
      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_1',
      );

      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.switchTab(MentorshipTab.requests);
      expect(vm.activeTab, MentorshipTab.requests);
      expect(notifyCount, 1);

      vm.switchTab(MentorshipTab.active);
      expect(vm.activeTab, MentorshipTab.active);
      expect(notifyCount, 2);
    });

    test('sends mentorship request and updates pending requests list',
        () async {
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_m1',
        learningProfileId: 'prof_m1',
        displayName: 'Mentor Bob',
      );
      final offer = LearningMentorshipOffer(
        id: 'offer_10',
        mentor: mentor,
        specialtyTopics: const ['Testing'],
      );
      repository.offers = [offer];

      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_learner_1',
      );
      await vm.initialize();

      final success = await vm.sendMentorshipRequest(
        offer: offer,
        learningGoal: 'Master unit tests',
        message: 'Looking forward to learning from you.',
      );

      expect(success, isTrue);
      expect(vm.pendingRequestsCount, 1);
      expect(vm.pendingRequests.first.learningGoal, 'Master unit tests');
    });

    test('acceptMentorship transitions status and adds to active agreements',
        () async {
      final learner = LearningMentorshipParticipant(
        accountId: 'acc_learner',
        learningProfileId: 'prof_learner',
        displayName: 'Learner',
      );
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_mentor',
        learningProfileId: 'prof_mentor',
        displayName: 'Mentor Bob',
      );
      final offer = LearningMentorshipOffer(
        id: 'offer_10',
        mentor: mentor,
        specialtyTopics: const ['Testing'],
      );
      final mentorship = LearningMentorship.request(
        id: 'm_to_accept',
        learner: learner,
        offer: offer,
        learningGoal: 'Goal',
        message: 'Message',
      );
      repository.offers = [offer];
      repository.mentorships = [mentorship];

      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_mentor',
      );
      await vm.initialize();

      expect(vm.pendingRequestsCount, 1);
      expect(vm.activeAgreementsCount, 0);

      final success = await vm.acceptMentorship('m_to_accept');
      expect(success, isTrue);
      expect(vm.pendingRequestsCount, 0);
      expect(vm.activeAgreementsCount, 1);
      expect(vm.activeAgreements.first.isActive, isTrue);
    });

    test('purges private mentorship state upon session revocation', () async {
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_m_rev',
        learningProfileId: 'prof_m_rev',
        displayName: 'Mentor',
      );
      repository.offers = [
        LearningMentorshipOffer(
          id: 'offer_rev_1',
          mentor: mentor,
          specialtyTopics: const ['Flutter'],
        ),
      ];

      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_learner',
      );
      await vm.initialize();
      expect(vm.status, MentorshipViewStatus.ready);

      sessionController.triggerPrivateStateClearers();

      expect(vm.offers, isEmpty);
      expect(vm.mentorships, isEmpty);
      expect(vm.status, MentorshipViewStatus.accessDenied);
    });
  });

  group('LearningMentorshipHubScreen - Presentation & Tabs', () {
    late _FakeMentorshipRepository repository;
    late _FakeSessionController sessionController;

    setUp(() {
      repository = _FakeMentorshipRepository();
      sessionController = _FakeSessionController();
    });

    Widget createHubWidget({
      required LearningMentorshipViewModel viewModel,
      double width = 360,
      double height = 800,
      double textScaleFactor = 1.0,
    }) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: LearningMentorshipHubScreen(viewModel: viewModel),
        ),
      );
    }

    testWidgets('displays empty states across all three tabs', (tester) async {
      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_learner',
      );

      await tester.pumpWidget(createHubWidget(viewModel: vm));
      await tester.pumpAndSettle();

      // Tab 0: Discover offers empty
      expect(find.byKey(const ValueKey('view_offers_empty')), findsOneWidget);
      expect(find.text('No Volunteer Mentors Available'), findsOneWidget);

      // Switch to Requests tab
      await tester.tap(find.byKey(const ValueKey('tab_mentors_requests')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('view_requests_empty')), findsOneWidget);
      expect(find.text('No Pending Requests'), findsOneWidget);

      // Switch to Active Agreements tab
      await tester.tap(find.byKey(const ValueKey('tab_mentors_active')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('view_active_empty')), findsOneWidget);
      expect(find.text('No Active Agreements'), findsOneWidget);
    });

    testWidgets('renders populated offers, requests, and active agreements',
        (tester) async {
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_m',
        learningProfileId: 'prof_m',
        displayName: 'Mentor Alice',
      );
      final offer = LearningMentorshipOffer(
        id: 'offer_populated',
        mentor: mentor,
        specialtyTopics: const ['Flutter Performance', 'Memory Profiling'],
      );
      repository.offers = [offer];

      final learner = LearningMentorshipParticipant(
        accountId: 'acc_l',
        learningProfileId: 'prof_learner',
        displayName: 'Learner User',
      );
      final activeMentorship = LearningMentorship.request(
        id: 'm_active_1',
        learner: learner,
        offer: offer,
        learningGoal: 'Eliminate jank in listviews',
        message: 'Looking for advice.',
      ).accept(mentor);
      repository.mentorships = [activeMentorship];

      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_learner',
      );

      await tester.pumpWidget(createHubWidget(viewModel: vm));
      await tester.pumpAndSettle();

      // Tab 0: Discover
      expect(find.text('Mentor Alice'), findsOneWidget);
      expect(find.text('Flutter Performance'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_open_request_offer_populated')),
          findsOneWidget);

      // Switch to Active Agreements tab
      await tester.tap(find.byKey(const ValueKey('tab_mentors_active')));
      await tester.pumpAndSettle();
      expect(find.text('Eliminate jank in listviews'), findsOneWidget);
      expect(find.text('Mentorship agreed'), findsOneWidget);
    });

    testWidgets('renders cleanly on 320dp viewport without overflow',
        (tester) async {
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_m',
        learningProfileId: 'prof_m',
        displayName: 'Mentor Alice',
      );
      repository.offers = [
        LearningMentorshipOffer(
          id: 'offer_pop',
          mentor: mentor,
          specialtyTopics: const ['Clean Arch', 'Widget Testing'],
        ),
      ];
      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_learner',
      );

      await tester.pumpWidget(createHubWidget(
        viewModel: vm,
        width: 320.0,
        height: 640.0,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'renders cleanly on 412dp viewport with 1.5x font scale without overflow',
        (tester) async {
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_m',
        learningProfileId: 'prof_m',
        displayName: 'Mentor Alice',
      );
      repository.offers = [
        LearningMentorshipOffer(
          id: 'offer_pop',
          mentor: mentor,
          specialtyTopics: const ['Clean Arch', 'Widget Testing'],
        ),
      ];
      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_learner',
      );

      await tester.pumpWidget(createHubWidget(
        viewModel: vm,
        width: 412.0,
        height: 915.0,
        textScaleFactor: 1.5,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('RequestMentorshipScreen & MentorshipAgreementScreen', () {
    late _FakeMentorshipRepository repository;
    late _FakeSessionController sessionController;

    setUp(() {
      repository = _FakeMentorshipRepository();
      sessionController = _FakeSessionController();
    });

    testWidgets(
        'RequestMentorshipScreen validates empty inputs and submits request',
        (tester) async {
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_m',
        learningProfileId: 'prof_m',
        displayName: 'Mentor Alice',
      );
      final offer = LearningMentorshipOffer(
        id: 'offer_test',
        mentor: mentor,
        specialtyTopics: const ['Dart Concurrency'],
      );
      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_learner',
      );
      bool successCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: RequestMentorshipScreen(
            offer: offer,
            viewModel: vm,
            onSuccess: () => successCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear fields to test empty submission
      await tester.enterText(
        find.byKey(const ValueKey('input_learning_goal')),
        '',
      );
      await tester.enterText(
        find.byKey(const ValueKey('input_mentor_message')),
        '',
      );
      await tester.pump();

      final submitBtn = find.byKey(const ValueKey('btn_submit_request'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(successCalled, isFalse);
      expect(vm.pendingRequestsCount, 0);

      // Enter goal and message
      await tester.enterText(
        find.byKey(const ValueKey('input_learning_goal')),
        'Understand Isolates and Background Tasks',
      );
      await tester.enterText(
        find.byKey(const ValueKey('input_mentor_message')),
        'Hello Alice, I would like to learn about compute() and isolate pooling.',
      );
      await tester.pump();

      // Submit valid form
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(successCalled, isTrue);
      expect(vm.pendingRequestsCount, 1);
    });

    testWidgets(
        'MentorshipAgreementScreen displays timeline, participants, and mentor actions',
        (tester) async {
      final learner = LearningMentorshipParticipant(
        accountId: 'acc_l',
        learningProfileId: 'prof_learner',
        displayName: 'Learner User',
      );
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_m',
        learningProfileId: 'prof_mentor',
        displayName: 'Mentor Alice',
      );
      final offer = LearningMentorshipOffer(
        id: 'offer_agr',
        mentor: mentor,
        specialtyTopics: const ['Dart Concurrency'],
      );
      final mentorship = LearningMentorship.request(
        id: 'm_agreement_test',
        learner: learner,
        offer: offer,
        learningGoal: 'Isolates in Depth',
        message: 'Looking forward to collaboration.',
      );

      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_mentor',
      );
      await vm.initialize();
      // Add the test mentorship to repository and refresh
      repository.mentorships = [mentorship];
      await vm.initialize(force: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: MentorshipAgreementScreen(
            mentorshipId: mentorship.id,
            viewModel: vm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Participants and banner verification
      expect(find.text('Isolates in Depth'), findsOneWidget);
      expect(find.text('Learner User'), findsWidgets);
      expect(find.text('Mentor Alice'), findsWidgets);

      // As mentor, action buttons should be Accept and Decline
      final acceptBtn = find.byKey(const ValueKey('btn_accept_mentorship'));
      final declineBtn = find.byKey(const ValueKey('btn_decline_mentorship'));
      expect(acceptBtn, findsOneWidget);
      expect(declineBtn, findsOneWidget);

      // Tap Accept
      await tester.ensureVisible(acceptBtn);
      await tester.tap(acceptBtn);
      await tester.pumpAndSettle();

      // Mentorship is now accepted and shows active handshake banner
      expect(find.byKey(const ValueKey('banner_mentorship_agreed')),
          findsOneWidget);
      expect(find.text('Mentorship agreed'), findsOneWidget);
    });

    testWidgets('MentorshipAgreementScreen renders cleanly on 320dp viewport',
        (tester) async {
      final learner = LearningMentorshipParticipant(
        accountId: 'acc_l',
        learningProfileId: 'prof_learner',
        displayName: 'Learner User',
      );
      final mentor = LearningMentorshipParticipant(
        accountId: 'acc_m',
        learningProfileId: 'prof_mentor',
        displayName: 'Mentor Alice',
      );
      final offer = LearningMentorshipOffer(
        id: 'offer_agr',
        mentor: mentor,
        specialtyTopics: const ['Dart Concurrency'],
      );
      final mentorship = LearningMentorship.request(
        id: 'm_resp_test',
        learner: learner,
        offer: offer,
        learningGoal: 'Isolates in Depth',
        message: 'Collaborate',
      );

      final vm = LearningMentorshipViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        currentProfileId: 'prof_learner',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 640)),
            child: MentorshipAgreementScreen(
              mentorshipId: mentorship.id,
              viewModel: vm,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
