import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/domain/entities/learning_growth_evidence.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/domain/repositories/i_learning_growth_repository.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/presentation/screens/my_growth_dashboard_screen.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/presentation/viewmodels/learning_growth_viewmodel.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/presentation/widgets/growth_evidence_card.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/presentation/widgets/growth_skill_card.dart';

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

  void setPhase(SessionPhase phase) {
    _stubPhase = phase;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDashboardRepository implements ILearningGrowthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  bool isBackendActivated = true;
  LearningGrowthSummary summary = const LearningGrowthSummary();
  List<LearningGrowthEvidence> evidenceList = [];
  List<LearningTrackedSkill> skillsList = [];
  bool shouldFail = false;
  LearningGrowthFailureType failureType = LearningGrowthFailureType.unknown;
  String? errorMessage;
  int initializeCalls = 0;

  @override
  Future<LearningGrowthResult<LearningGrowthSummary>> getGrowthSummary() async {
    initializeCalls++;
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthViewModel.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    if (shouldFail) {
      return LearningGrowthResult.failure(
        errorMessage: errorMessage ?? 'Error loading summary',
        failureType: failureType,
      );
    }
    return LearningGrowthResult.success(summary);
  }

  @override
  Future<LearningGrowthResult<List<LearningGrowthEvidence>>> getEvidenceList({
    LearningEvidenceKind? kindFilter,
    String? skillId,
  }) async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthViewModel.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    if (shouldFail) {
      return LearningGrowthResult.failure(
        errorMessage: errorMessage ?? 'Error loading evidence',
        failureType: failureType,
      );
    }
    return LearningGrowthResult.success(evidenceList);
  }

  @override
  Future<LearningGrowthResult<LearningGrowthEvidence>> getEvidenceById(
    String evidenceId,
  ) async {
    final ev = evidenceList.where((e) => e.id == evidenceId).firstOrNull;
    if (ev != null) return LearningGrowthResult.success(ev);
    return const LearningGrowthResult.failure(
      errorMessage: 'Not found',
      failureType: LearningGrowthFailureType.notFound,
    );
  }

  @override
  Future<LearningGrowthResult<List<LearningTrackedSkill>>>
      getTrackedSkills() async {
    if (!isBackendActivated) {
      return const LearningGrowthResult.failure(
        errorMessage: LearningGrowthViewModel.disconnectedNotice,
        failureType: LearningGrowthFailureType.serviceUnavailable,
      );
    }
    if (shouldFail) {
      return LearningGrowthResult.failure(
        errorMessage: errorMessage ?? 'Error loading skills',
        failureType: failureType,
      );
    }
    return LearningGrowthResult.success(skillsList);
  }

  @override
  Future<LearningGrowthResult<LearningGrowthEvidence>>
      recordSelfReportedEvidence({
    required String title,
    required String description,
    Iterable<String>? skillIds,
    Iterable<String>? skillNames,
    String? sourceReference,
  }) async {
    final ev = LearningGrowthEvidence.recordSelfReport(
      id: 'ev_${evidenceList.length + 1}',
      accountId: 'acc_01',
      learningProfileId: 'prof_01',
      title: title,
      description: description,
      skillIds: skillIds,
      skillNames: skillNames,
      sourceReference: sourceReference,
    );
    evidenceList.insert(0, ev);
    return LearningGrowthResult.success(ev);
  }
}

void main() {
  late _FakeDashboardRepository repository;
  late _FakeSessionController sessionController;

  final sampleVerified = LearningGrowthEvidence.recordVerified(
    id: 'ev_1',
    accountId: 'acc_01',
    learningProfileId: 'prof_01',
    title: 'Distributed Systems Assessment',
    description: 'Passed peer code review on consensus algorithms.',
    skillIds: ['sys_design', 'concurrency'],
    skillNames: ['System Design', 'Concurrency'],
    sourceReference: 'Peer Review Session',
    verifierName: 'Lead Architect',
    recordedAt: DateTime(2026, 11, 25, 10, 0),
  );

  final sampleSelfReport = LearningGrowthEvidence.recordSelfReport(
    id: 'ev_2',
    accountId: 'acc_01',
    learningProfileId: 'prof_01',
    title: 'Flutter State Architecture Practice',
    description: 'Refactored state container with Riverpod.',
    skillIds: ['flutter'],
    skillNames: ['Flutter'],
    sourceReference: 'Personal Experiment',
    recordedAt: DateTime(2026, 11, 26, 9, 30),
  );

  final sampleSkill1 = LearningTrackedSkill(
    id: 'flutter',
    name: 'Flutter Architecture',
    category: 'Mobile Engineering',
    associatedEvidenceIds: ['ev_2'],
    sufficiencyStatus: EvidenceSufficiencyStatus.selfReportedOnly,
  );

  final sampleSkill2 = LearningTrackedSkill(
    id: 'sys_design',
    name: 'System Design',
    category: 'Backend Architecture',
    associatedEvidenceIds: ['ev_1'],
    sufficiencyStatus: EvidenceSufficiencyStatus.verifiedSource,
  );

  setUp(() {
    repository = _FakeDashboardRepository();
    sessionController = _FakeSessionController();
  });

  Widget buildTestableWidget(LearningGrowthViewModel vm,
      {double textScale = 1.0}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MyGrowthDashboardScreen(viewModel: vm),
      ),
    );
  }

  group('MyGrowthDashboardScreen - Presentation States', () {
    testWidgets('displays loading indicator initially', (tester) async {
      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(buildTestableWidget(vm));
      expect(find.byKey(const ValueKey('loading_indicator')), findsOneWidget);
    });

    testWidgets('displays access denied when unauthorized', (tester) async {
      sessionController.setPhase(SessionPhase.signedOut);
      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(buildTestableWidget(vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_access_denied')), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('displays unavailable state with retry action', (tester) async {
      repository.isBackendActivated = false;
      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(buildTestableWidget(vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_unavailable')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('btn_retry_unavailable')), findsOneWidget);

      // Tap retry
      repository.isBackendActivated = true;
      repository.evidenceList = [sampleSelfReport];
      await tester.tap(find.byKey(const ValueKey('btn_retry_unavailable')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_unavailable')), findsNothing);
      expect(find.byKey(const ValueKey('view_tab_overview')), findsOneWidget);
    });

    testWidgets('displays error state with retry action', (tester) async {
      repository.shouldFail = true;
      repository.errorMessage = 'Network failure';
      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(buildTestableWidget(vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_error')), findsOneWidget);
      expect(find.text('Network failure'), findsOneWidget);

      repository.shouldFail = false;
      repository.evidenceList = [sampleVerified];
      await tester.tap(find.byKey(const ValueKey('btn_retry_error')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_error')), findsNothing);
    });

    testWidgets('displays empty state when no records exist', (tester) async {
      repository.evidenceList = [];
      repository.skillsList = [];
      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(buildTestableWidget(vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('view_growth_empty')), findsOneWidget);
      expect(find.text('No Growth Records Yet'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_empty_record')), findsOneWidget);
    });
  });

  group('MyGrowthDashboardScreen - Tab Interactions & Details Sheet', () {
    testWidgets('renders overview tab with metrics and recent cards',
        (tester) async {
      repository.evidenceList = [sampleSelfReport, sampleVerified];
      repository.skillsList = [sampleSkill1, sampleSkill2];

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(buildTestableWidget(vm));
      await tester.pumpAndSettle();

      // Disconnected banner
      expect(find.byKey(const ValueKey('banner_growth_disconnected')),
          findsOneWidget);

      // Privacy banner
      expect(
          find.byKey(const ValueKey('banner_privacy_callout')), findsOneWidget);

      // Metric tiles
      expect(
          find.byKey(const ValueKey('metric_total_evidence')), findsOneWidget);
      expect(find.byKey(const ValueKey('metric_verified_evidence')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('metric_self_reported')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('metric_tracked_skills')), findsOneWidget);

      // Recent evidence cards
      expect(find.byType(GrowthEvidenceCard), findsWidgets);
    });

    testWidgets('tapping evidence card opens EvidenceDetailSheet',
        (tester) async {
      repository.evidenceList = [sampleVerified];
      repository.skillsList = [sampleSkill2];

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(buildTestableWidget(vm));
      await tester.pumpAndSettle();

      // Tap card
      await tester.tap(find.byKey(const ValueKey('card_evidence_ev_1')));
      await tester.pumpAndSettle();

      // Check detail sheet elements
      expect(find.text('Distributed Systems Assessment'), findsWidgets);
      expect(find.text('Verified By'), findsOneWidget);
      expect(find.text('Lead Architect'), findsOneWidget);
      expect(find.text('Private to you'), findsWidgets);
      expect(find.byKey(const ValueKey('btn_dismiss_evidence_sheet')),
          findsOneWidget);

      // Close sheet
      await tester
          .tap(find.byKey(const ValueKey('btn_dismiss_evidence_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('Verified By'), findsNothing);
    });

    testWidgets('switches to Evidence tab, filters by kind and search query',
        (tester) async {
      repository.evidenceList = [sampleSelfReport, sampleVerified];
      repository.skillsList = [sampleSkill1, sampleSkill2];

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(buildTestableWidget(vm));
      await tester.pumpAndSettle();

      // Tap Evidence tab
      await tester.tap(find.byKey(const ValueKey('tab_evidence')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('view_tab_evidence')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_record_evidence')), findsOneWidget);

      // Initial both cards present
      expect(find.text('Flutter State Architecture Practice'), findsOneWidget);
      expect(find.text('Distributed Systems Assessment'), findsOneWidget);

      // Tap Verified filter chip
      await tester.tap(find.byKey(const ValueKey('filter_verified')));
      await tester.pumpAndSettle();

      expect(find.text('Distributed Systems Assessment'), findsOneWidget);
      expect(find.text('Flutter State Architecture Practice'), findsNothing);

      // Tap Self-Reported filter chip
      await tester.tap(find.byKey(const ValueKey('filter_self_reported')));
      await tester.pumpAndSettle();

      expect(find.text('Flutter State Architecture Practice'), findsOneWidget);
      expect(find.text('Distributed Systems Assessment'), findsNothing);

      // Tap All filter chip
      await tester.tap(find.byKey(const ValueKey('filter_all')));
      await tester.pumpAndSettle();

      // Search field
      await tester.enterText(
          find.byKey(const ValueKey('input_growth_search')), 'consensus');
      await tester.pumpAndSettle();

      expect(find.text('Distributed Systems Assessment'), findsOneWidget);
      expect(find.text('Flutter State Architecture Practice'), findsNothing);

      // Clear search
      await tester.tap(find.byKey(const ValueKey('btn_clear_search')));
      await tester.pumpAndSettle();

      expect(find.text('Flutter State Architecture Practice'), findsOneWidget);
    });

    testWidgets('records self-reported evidence via dialog', (tester) async {
      repository.evidenceList = [sampleVerified];
      repository.skillsList = [sampleSkill2];

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(buildTestableWidget(vm));
      await tester.pumpAndSettle();

      // Switch to Evidence tab
      await tester.tap(find.byKey(const ValueKey('tab_evidence')));
      await tester.pumpAndSettle();

      // Tap record FAB
      await tester.tap(find.byKey(const ValueKey('btn_record_evidence')));
      await tester.pumpAndSettle();

      expect(find.text('Record Self-Reported Evidence'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('input_evidence_title')),
        'Learned Dart Isolates',
      );
      await tester.enterText(
        find.byKey(const ValueKey('input_evidence_desc')),
        'Tested multi-threaded background parsing with compute().',
      );
      await tester.enterText(
        find.byKey(const ValueKey('input_evidence_skills')),
        'Dart, Concurrency',
      );

      await tester.tap(find.byKey(const ValueKey('btn_submit_evidence')));
      await tester.pumpAndSettle();

      expect(find.text('Record Self-Reported Evidence'), findsNothing);
      expect(find.text('Learned Dart Isolates'), findsOneWidget);
    });

    testWidgets('switches to Skills tab and displays sufficiency status',
        (tester) async {
      repository.evidenceList = [sampleSelfReport, sampleVerified];
      repository.skillsList = [sampleSkill1, sampleSkill2];

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(buildTestableWidget(vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab_skills')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('view_tab_skills')), findsOneWidget);
      expect(
          find.text(
              'Missing evidence does not imply absence of skill. Track your qualitative growth as you complete learning circles and pacts.'),
          findsOneWidget);
      expect(find.byType(GrowthSkillCard), findsNWidgets(2));
    });

    testWidgets(
        'switches to Insights tab and displays mentorship scheduled banner',
        (tester) async {
      repository.evidenceList = [sampleSelfReport];
      repository.skillsList = [sampleSkill1];

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(buildTestableWidget(vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab_insights')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('view_tab_insights')), findsOneWidget);
      expect(find.byKey(const ValueKey('banner_mentorship_pending')),
          findsOneWidget);
      expect(find.text(LearningGrowthViewModel.mentorshipPendingNotice),
          findsOneWidget);
      expect(find.text('Continuous Commitment'), findsOneWidget);
    });
  });

  group(
      'MyGrowthDashboardScreen - Responsive Viewports & Font Scale (0 Overflows)',
      () {
    for (final width in [320.0, 360.0, 412.0]) {
      testWidgets('renders cleanly on ${width}dp viewport without overflow',
          (tester) async {
        tester.view.physicalSize = Size(width * 2.0, 800.0 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        repository.evidenceList = [sampleSelfReport, sampleVerified];
        repository.skillsList = [sampleSkill1, sampleSkill2];

        final vm = LearningGrowthViewModel(
          repository: repository,
          sessionController: sessionController,
          isLearningActivated: true,
        );

        await tester.pumpWidget(buildTestableWidget(vm));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Switch to evidence
        await tester.tap(find.byKey(const ValueKey('tab_evidence')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Switch to skills
        await tester.tap(find.byKey(const ValueKey('tab_skills')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Switch to insights
        await tester.tap(find.byKey(const ValueKey('tab_insights')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('renders cleanly with 1.5x dynamic font scale without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360.0 * 2.0, 800.0 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      repository.evidenceList = [sampleSelfReport, sampleVerified];
      repository.skillsList = [sampleSkill1, sampleSkill2];

      final vm = LearningGrowthViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(buildTestableWidget(vm, textScale: 1.5));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Check all tabs at 1.5x font scale
      await tester.tap(find.byKey(const ValueKey('tab_evidence')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('tab_skills')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('tab_insights')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
