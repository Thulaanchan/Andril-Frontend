import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/domain/entities/learning_topic_gap.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/domain/repositories/i_learning_growth_repository.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/presentation/screens/topic_gap_explanation_screen.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/presentation/viewmodels/learning_topic_gap_viewmodel.dart';

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

class _FakeTopicGapRepository implements ILearningGrowthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  bool isBackendActivated = true;
  LearningTopicGap? gapToReturn;
  bool shouldFail = false;
  LearningGrowthFailureType failureType = LearningGrowthFailureType.unknown;
  String? errorMessage;
  Completer<void>? delayCompleter;
  int getGapCalls = 0;

  @override
  Future<LearningGrowthResult<LearningTopicGap>> getTopicGapById(
      String gapId) async {
    getGapCalls++;
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningTopicGap.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    if (shouldFail) {
      return LearningGrowthResult.failure(
        errorMessage: errorMessage ?? 'Failed to load topic gap',
        failureType: failureType,
      );
    }
    if (gapToReturn != null) {
      return LearningGrowthResult.success(gapToReturn!);
    }
    return LearningGrowthResult.success(
      LearningTopicGap(
        id: gapId,
        accountId: 'acc_learner_1',
        learningProfileId: 'prof_learner_1',
        topicTitle: 'State Management Foundations',
        topicDomain: 'Mobile Development',
        isSufficientEvidence: true,
        explanation:
            'Focus on immutable state flow and reactive data pipelines.',
        suggestedNextStep:
            'Review unidirectional data flow patterns and create a peer pact.',
        reviewedEvidenceTitles: const [
          'State Management Lab Exercise',
          'Peer Code Review - Epoch Guarding',
        ],
      ),
    );
  }
}

void main() {
  group('LearningTopicGap - Domain Invariants', () {
    test('constructs valid entity with required defaults', () {
      final gap = LearningTopicGap(
        id: 'gap_123',
        accountId: 'acc_learner_1',
        learningProfileId: 'prof_learner_1',
        topicTitle: 'Asynchronous Stream Safety',
        topicDomain: 'Concurrency',
        isSufficientEvidence: true,
        explanation: 'Demonstrated solid understanding of epoch cancellation.',
        suggestedNextStep: 'Conduct a peer pact on stream subscription leaks.',
        reviewedEvidenceTitles: const [
          'Evidence Record A',
          'Evidence Record B'
        ],
      );

      expect(gap.id, 'gap_123');
      expect(gap.accountId, 'acc_learner_1');
      expect(gap.learningProfileId, 'prof_learner_1');
      expect(gap.topicTitle, 'Asynchronous Stream Safety');
      expect(gap.topicDomain, 'Concurrency');
      expect(gap.isSufficientEvidence, isTrue);
      expect(gap.isPrivate, isTrue);
      expect(gap.module, 'learning');
      expect(gap.reviewedEvidenceTitles.length, 2);
    });

    test('enforces module invariant strictly to "learning"', () {
      expect(
        () => LearningTopicGap(
          id: 'gap_123',
          accountId: 'acc_1',
          learningProfileId: 'prof_1',
          topicTitle: 'Topic',
          topicDomain: 'Domain',
          explanation: 'Explanation',
          suggestedNextStep: 'Step',
          module: 'classroom',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('enforces isPrivate invariant strictly to true', () {
      expect(
        () => LearningTopicGap(
          id: 'gap_123',
          accountId: 'acc_1',
          learningProfileId: 'prof_1',
          topicTitle: 'Topic',
          topicDomain: 'Domain',
          explanation: 'Explanation',
          suggestedNextStep: 'Step',
          isPrivate: false,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty or whitespace required strings', () {
      expect(
        () => LearningTopicGap(
          id: '  ',
          accountId: 'acc_1',
          learningProfileId: 'prof_1',
          topicTitle: 'Topic',
          topicDomain: 'Domain',
          explanation: 'Explanation',
          suggestedNextStep: 'Step',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => LearningTopicGap(
          id: 'gap_1',
          accountId: 'acc_1',
          learningProfileId: 'prof_1',
          topicTitle: '',
          topicDomain: 'Domain',
          explanation: 'Explanation',
          suggestedNextStep: 'Step',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => LearningTopicGap(
          id: 'gap_1',
          accountId: 'acc_1',
          learningProfileId: 'prof_1',
          topicTitle: 'Topic',
          topicDomain: 'Domain',
          explanation: '   ',
          suggestedNextStep: 'Step',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => LearningTopicGap(
          id: 'gap_1',
          accountId: 'acc_1',
          learningProfileId: 'prof_1',
          topicTitle: 'Topic',
          topicDomain: 'Domain',
          explanation: 'Explanation',
          suggestedNextStep: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('reviewedEvidenceTitles creates unmodifiable list and trims items',
        () {
      final gap = LearningTopicGap(
        id: 'gap_1',
        accountId: 'acc_1',
        learningProfileId: 'prof_1',
        topicTitle: 'Topic',
        topicDomain: 'Domain',
        explanation: 'Explanation',
        suggestedNextStep: 'Step',
        reviewedEvidenceTitles: ['  Evidence 1  ', '', 'Evidence 2'],
      );

      expect(gap.reviewedEvidenceTitles, ['Evidence 1', 'Evidence 2']);
      expect(() => (gap.reviewedEvidenceTitles as List).add('New'),
          throwsUnsupportedError);
    });

    test('factory insufficientEvidence produces valid compliant entity', () {
      final gap = LearningTopicGap.insufficientEvidence(
        id: 'gap_insuff_1',
        accountId: 'acc_1',
        learningProfileId: 'prof_1',
        topicTitle: 'Deep Async Concurrency',
        topicDomain: 'Architecture',
      );

      expect(gap.id, 'gap_insuff_1');
      expect(gap.topicTitle, 'Deep Async Concurrency');
      expect(gap.isSufficientEvidence, isFalse);
      expect(gap.isPrivate, isTrue);
      expect(gap.module, 'learning');
      expect(gap.reviewedEvidenceTitles, isEmpty);
      expect(gap.explanation, contains('Evidence is currently insufficient'));
      expect(gap.suggestedNextStep,
          contains('Record self-reported practice reflections'));
    });

    test('redacted toString prevents narrative and steps leakage', () {
      final gap = LearningTopicGap(
        id: 'gap_sensitive_999',
        accountId: 'acc_secret_learner',
        learningProfileId: 'prof_secret_learner',
        topicTitle: 'Confidential Learning Goal',
        topicDomain: 'Proprietary',
        explanation: 'Highly private narrative details.',
        suggestedNextStep: 'Private recommendation.',
        reviewedEvidenceTitles: const ['Private Artifact 1'],
      );

      final str = gap.toString();
      expect(str, contains('LearningTopicGap [private references omitted]'));
      expect(str, isNot(contains('acc_secret_learner')));
      expect(str, isNot(contains('Highly private narrative details')));
      expect(str, isNot(contains('Private recommendation')));
      expect(str, isNot(contains('Private Artifact 1')));
    });

    test('JSON serialization round-trip maintains integrity', () {
      final original = LearningTopicGap(
        id: 'gap_json_1',
        accountId: 'acc_1',
        learningProfileId: 'prof_1',
        topicTitle: 'Serialization Patterns',
        topicDomain: 'Data Architecture',
        isSufficientEvidence: true,
        explanation: 'Clear explanation of models.',
        suggestedNextStep: 'Implement DTOs with factory constructors.',
        reviewedEvidenceTitles: const ['DTO exercise', 'Parser test'],
      );

      final json = original.toJson();
      final revived = LearningTopicGap.fromJson(json);

      expect(revived, equals(original));
      expect(revived.id, original.id);
      expect(revived.topicTitle, original.topicTitle);
      expect(revived.topicDomain, original.topicDomain);
      expect(revived.isSufficientEvidence, original.isSufficientEvidence);
      expect(revived.explanation, original.explanation);
      expect(revived.suggestedNextStep, original.suggestedNextStep);
      expect(revived.reviewedEvidenceTitles, original.reviewedEvidenceTitles);
    });
  });

  group('LearningTopicGapViewModel', () {
    late _FakeTopicGapRepository repository;
    late _FakeSessionController sessionController;

    setUp(() {
      repository = _FakeTopicGapRepository();
      sessionController = _FakeSessionController();
    });

    test('rejects unauthenticated or deactivated profile with accessDenied',
        () async {
      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: false,
        gapId: 'gap_1',
      );

      await vm.initialize();

      expect(vm.status, TopicGapViewStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      expect(vm.errorMessage,
          contains('Authentication and an activated Learning profile'));
    });

    test('handles disconnected backend with unavailableService state',
        () async {
      repository.isBackendActivated = false;
      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      await vm.initialize();

      expect(vm.status, TopicGapViewStatus.unavailableService);
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.errorMessage, LearningTopicGap.disconnectedNotice);
    });

    test('successfully initializes and loads sufficient topic gap', () async {
      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      await vm.initialize();

      expect(vm.status, TopicGapViewStatus.ready);
      expect(vm.isReady, isTrue);
      expect(vm.topicGap, isNotNull);
      expect(vm.topicGap!.topicTitle, 'State Management Foundations');
      expect(vm.topicGap!.isSufficientEvidence, isTrue);
    });

    test(
        'loads insufficient evidence topic gap into insufficientEvidence status',
        () async {
      repository.gapToReturn = LearningTopicGap.insufficientEvidence(
        id: 'gap_insuff',
        accountId: 'acc_1',
        learningProfileId: 'prof_1',
        topicTitle: 'Reactive Streams',
        topicDomain: 'Architecture',
      );

      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_insuff',
      );

      await vm.initialize();

      expect(vm.status, TopicGapViewStatus.insufficientEvidence);
      expect(vm.isInsufficientEvidence, isTrue);
      expect(vm.topicGap!.isSufficientEvidence, isFalse);
    });

    test('handles repository errors with error status', () async {
      repository.shouldFail = true;
      repository.errorMessage = 'Network connection dropped';
      repository.failureType = LearningGrowthFailureType.unknown;

      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      await vm.initialize();

      expect(vm.status, TopicGapViewStatus.error);
      expect(vm.errorMessage, 'Network connection dropped');
    });

    test('purges private topic gap state upon session revocation', () async {
      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      await vm.initialize();
      expect(vm.status, TopicGapViewStatus.ready);
      expect(vm.topicGap, isNotNull);

      sessionController.triggerPrivateStateClearers();

      expect(vm.topicGap, isNull);
      expect(vm.status, TopicGapViewStatus.accessDenied);
    });

    test('stale epoch guard discards outdated asynchronous responses',
        () async {
      final completer1 = Completer<void>();
      repository.delayCompleter = completer1;

      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      final future1 = vm.initialize();

      // Trigger second request which increments epoch
      repository.delayCompleter = null;
      repository.gapToReturn = LearningTopicGap(
        id: 'gap_second',
        accountId: 'acc_1',
        learningProfileId: 'prof_1',
        topicTitle: 'Second Topic',
        topicDomain: 'Architecture',
        explanation: 'Updated narrative',
        suggestedNextStep: 'Updated next step',
      );
      final future2 = vm.initialize(force: true);
      await future2;

      expect(vm.topicGap!.id, 'gap_second');

      // Complete first request
      repository.gapToReturn = LearningTopicGap(
        id: 'gap_first',
        accountId: 'acc_1',
        learningProfileId: 'prof_1',
        topicTitle: 'First Topic',
        topicDomain: 'Architecture',
        explanation: 'First narrative',
        suggestedNextStep: 'First next step',
      );
      completer1.complete();
      await future1;

      // Ensure first request did NOT overwrite second request
      expect(vm.topicGap!.id, 'gap_second');
    });
  });

  group('TopicGapExplanationScreen - Presentation States & Interactions', () {
    late _FakeTopicGapRepository repository;
    late _FakeSessionController sessionController;

    setUp(() {
      repository = _FakeTopicGapRepository();
      sessionController = _FakeSessionController();
    });

    Widget createTestWidget({
      required LearningTopicGapViewModel viewModel,
      VoidCallback? onBack,
      VoidCallback? onExploreMentorship,
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
          child: TopicGapExplanationScreen(
            viewModel: viewModel,
            onBack: onBack,
            onExploreMentorship: onExploreMentorship,
          ),
        ),
      );
    }

    testWidgets('displays loading indicator initially', (tester) async {
      final completer = Completer<void>();
      repository.delayCompleter = completer;

      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      await tester.pumpWidget(createTestWidget(viewModel: vm));
      await tester.pump();

      expect(find.byKey(const ValueKey('loading_indicator')), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('displays access denied when unauthorized', (tester) async {
      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: false,
        gapId: 'gap_1',
      );

      await tester.pumpWidget(createTestWidget(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_access_denied')), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('displays unavailable state with retry action', (tester) async {
      repository.isBackendActivated = false;
      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      await tester.pumpWidget(createTestWidget(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_unavailable')), findsOneWidget);
      expect(find.text('Topic Gap Service Unavailable'), findsOneWidget);

      // Now activate backend and retry
      repository.isBackendActivated = true;
      final retryBtn = find.byKey(const ValueKey('btn_retry_unavailable'));
      expect(retryBtn, findsOneWidget);
      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('card_gap_explanation')), findsOneWidget);
    });

    testWidgets('displays error state with retry action', (tester) async {
      repository.shouldFail = true;
      repository.errorMessage = 'Simulated backend failure';
      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      await tester.pumpWidget(createTestWidget(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_error')), findsOneWidget);
      expect(find.text('Simulated backend failure'), findsOneWidget);

      // Fix failure and retry
      repository.shouldFail = false;
      final retryBtn = find.byKey(const ValueKey('btn_retry_error'));
      expect(retryBtn, findsOneWidget);
      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('card_gap_explanation')), findsOneWidget);
    });

    testWidgets(
        'renders all cards and responds to button interactions in ready state',
        (tester) async {
      bool backTapped = false;
      bool mentorshipTapped = false;

      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      await tester.pumpWidget(createTestWidget(
        viewModel: vm,
        onBack: () => backTapped = true,
        onExploreMentorship: () => mentorshipTapped = true,
      ));
      await tester.pumpAndSettle();

      // Check header and privacy indicators
      expect(find.text('State Management Foundations'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('chip_private_learning')), findsOneWidget);

      // Check reviewed evidence card
      expect(
          find.byKey(const ValueKey('card_evidence_reviewed')), findsOneWidget);
      expect(find.text('State Management Lab Exercise'), findsOneWidget);
      expect(find.text('Peer Code Review - Epoch Guarding'), findsOneWidget);

      // Check explanation and next step cards
      expect(
          find.byKey(const ValueKey('card_gap_explanation')), findsOneWidget);
      expect(
          find.text(
              'Focus on immutable state flow and reactive data pipelines.'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('card_suggested_next_step')),
          findsOneWidget);
      expect(
          find.text(
              'Review unidirectional data flow patterns and create a peer pact.'),
          findsOneWidget);

      // Test mentorship CTA
      final mentorBtn = find.byKey(const ValueKey('btn_explore_mentorship'));
      expect(mentorBtn, findsOneWidget);
      await tester.ensureVisible(mentorBtn);
      await tester.tap(mentorBtn);
      await tester.pump();
      expect(mentorshipTapped, isTrue);

      // Test back button
      final backBtn = find.byKey(const ValueKey('btn_topic_gap_back'));
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pump();
      expect(backTapped, isTrue);
    });

    testWidgets(
        'renders insufficient evidence state banner with governance disclaimer',
        (tester) async {
      repository.gapToReturn = LearningTopicGap.insufficientEvidence(
        id: 'gap_sparse_evidence',
        accountId: 'acc_1',
        learningProfileId: 'prof_1',
        topicTitle: 'Advanced WebSockets',
        topicDomain: 'Networking',
      );

      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_sparse_evidence',
      );

      await tester.pumpWidget(createTestWidget(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('banner_insufficient_evidence')),
          findsOneWidget);
      expect(find.text('Insufficient Evidence'), findsOneWidget);
      expect(
        find.textContaining('Missing evidence does not imply absence of skill'),
        findsOneWidget,
      );
    });

    testWidgets('renders cleanly on 320dp viewport without overflow',
        (tester) async {
      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      await tester.pumpWidget(createTestWidget(
        viewModel: vm,
        width: 320.0,
        height: 640.0,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
          find.byKey(const ValueKey('card_gap_explanation')), findsOneWidget);
    });

    testWidgets('renders cleanly on 360dp viewport without overflow',
        (tester) async {
      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      await tester.pumpWidget(createTestWidget(
        viewModel: vm,
        width: 360.0,
        height: 740.0,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
          find.byKey(const ValueKey('card_gap_explanation')), findsOneWidget);
    });

    testWidgets('renders cleanly on 412dp viewport without overflow',
        (tester) async {
      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      await tester.pumpWidget(createTestWidget(
        viewModel: vm,
        width: 412.0,
        height: 915.0,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
          find.byKey(const ValueKey('card_gap_explanation')), findsOneWidget);
    });

    testWidgets('renders cleanly with 1.5x dynamic font scale without overflow',
        (tester) async {
      final vm = LearningTopicGapViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
        gapId: 'gap_1',
      );

      await tester.pumpWidget(createTestWidget(
        viewModel: vm,
        width: 360.0,
        height: 800.0,
        textScaleFactor: 1.5,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
          find.byKey(const ValueKey('card_gap_explanation')), findsOneWidget);
    });
  });
}
