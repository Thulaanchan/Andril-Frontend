import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/discovery/domain/entities/learning_partner_candidate.dart';
import 'package:andril_mobile/features/learning/discovery/domain/entities/learning_partner_filters.dart';
import 'package:andril_mobile/features/learning/discovery/domain/entities/learning_partner_sort.dart';
import 'package:andril_mobile/features/learning/discovery/domain/repositories/i_learning_discovery_repository.dart';
import 'package:andril_mobile/features/learning/discovery/presentation/screens/learning_partner_explorer_screen.dart';
import 'package:andril_mobile/features/learning/discovery/presentation/viewmodels/learning_partner_explorer_viewmodel.dart';

class FakeSessionController extends ChangeNotifier
    implements SessionController {
  SessionPhase _stubPhase;
  final Set<VoidCallback> _clearers = {};

  FakeSessionController({SessionPhase phase = SessionPhase.signedIn})
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

class FakeLearningDiscoveryRepository implements ILearningDiscoveryRepository {
  LearningDiscoveryResult<List<LearningPartnerCandidate>> result =
      const LearningDiscoveryResult.success(<LearningPartnerCandidate>[]);
  Completer<void>? delayCompleter;

  @override
  Future<LearningDiscoveryResult<List<LearningPartnerCandidate>>>
      getCandidates({
    LearningPartnerFilters? filters,
    int offset = 0,
    int limit = 20,
  }) async {
    if (delayCompleter != null) {
      await delayCompleter!.future;
    }
    return result;
  }
}

List<LearningPartnerCandidate> _createSampleCandidates() {
  return [
    LearningPartnerCandidate(
      id: 'cand_01',
      displayName: 'Amara Fernando',
      skillsToShare: const ['Flutter', 'Dart', 'Clean Architecture'],
      skillsToLearn: const ['Figma', 'UI/UX Design'],
      learningGoals: const ['Master state management'],
      proficiencyLevel: 'Advanced',
      languages: const ['English', 'Tamil'],
      availability: 'Flexible (Any time)',
      bio: 'Mobile architect passionate about Clean Architecture.',
      isActive: true,
    ),
    LearningPartnerCandidate(
      id: 'cand_02',
      displayName: 'Bawantha Silva',
      skillsToShare: const ['Python', 'FastAPI'],
      skillsToLearn: const ['Flutter', 'Mobile Prototyping'],
      learningGoals: const ['Build production apps'],
      proficiencyLevel: 'Intermediate',
      languages: const ['English', 'Tamil', 'Tanglish'],
      availability: 'Evening (6 PM – 10 PM)',
      bio: 'Backend developer expanding into cross-platform UI.',
      isActive: true,
    ),
  ];
}

Widget _buildTestApp({
  required LearningPartnerExplorerViewModel viewModel,
  ValueChanged<LearningPartnerCandidate>? onConnect,
  Size size = const Size(360, 640),
  double textScaleFactor = 1.0,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: Scaffold(
        body: LearningPartnerExplorerScreen(
          viewModel: viewModel,
          onConnect: onConnect,
        ),
      ),
    ),
  );
}

void main() {
  group(
      'LearningPartnerExplorerScreen Widget & Responsive Layout Tests (CF-04, Q13)',
      () {
    late FakeLearningDiscoveryRepository fakeRepository;
    late FakeSessionController fakeSession;

    setUp(() {
      fakeRepository = FakeLearningDiscoveryRepository();
      fakeSession = FakeSessionController(phase: SessionPhase.signedIn);
    });

    testWidgets(
        'renders all initial screen components and disconnected notice banner',
        (tester) async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.text('Learning Partner Explorer'), findsOneWidget);
      expect(find.byKey(const ValueKey('banner_disconnected_notice')),
          findsOneWidget);
      expect(find.text(LearningPartnerExplorerViewModel.disconnectedNotice),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('input_partner_search')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_open_filters')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('dropdown_sort_options')), findsOneWidget);
      expect(find.byKey(const ValueKey('text_result_count')), findsOneWidget);
      expect(find.text('2 partners found'), findsOneWidget);

      // Candidate cards rendered
      expect(find.byKey(const ValueKey('card_learning_partner_cand_01')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('card_learning_partner_cand_02')),
          findsOneWidget);
      expect(find.text('Amara Fernando'), findsOneWidget);
      expect(find.text('Bawantha Silva'), findsOneWidget);
    });

    testWidgets('renders loading state when status is loading', (tester) async {
      final completer = Completer<void>();
      fakeRepository.delayCompleter = completer;

      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      // Pump initial frame before async initialization completes
      await tester.pump();

      expect(find.byKey(const ValueKey('state_loading')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'renders access-denied state when caller is unauthenticated or unactivated',
        (tester) async {
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: null, // Unauthenticated
        isLearningActivated: false,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_access_denied')), findsOneWidget);
      expect(find.text('Access Denied'), findsOneWidget);
      expect(
          find.textContaining('Authentication and activated Learning profile'),
          findsOneWidget);
    });

    testWidgets('renders service unavailable state with retry control',
        (tester) async {
      fakeRepository.result = const LearningDiscoveryResult.failure(
        errorMessage:
            'Learning discovery service is currently preparing and unavailable.',
        failureType: LearningDiscoveryFailureType.serviceUnavailable,
      );

      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_unavailable')), findsOneWidget);
      expect(find.text('Service Preparing'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('btn_retry_unavailable')), findsOneWidget);
    });

    testWidgets('renders error state with retry control', (tester) async {
      fakeRepository.result = const LearningDiscoveryResult.failure(
        errorMessage: 'Network timeout connection lost.',
        failureType: LearningDiscoveryFailureType.networkError,
      );

      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_error')), findsOneWidget);
      expect(find.text('Unable to Load Partners'), findsOneWidget);
      expect(find.text('Network timeout connection lost.'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_retry_error')), findsOneWidget);
    });

    testWidgets('renders empty state when search filters yield 0 results',
        (tester) async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Enter search query that matches nothing
      await tester.enterText(
          find.byKey(const ValueKey('input_partner_search')), 'NonExistentXYZ');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_empty')), findsOneWidget);
      expect(find.text('No Learning Partners Found'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_reset_empty_filters')),
          findsOneWidget);

      // Tapping reset filters restores cards
      await tester.tap(find.byKey(const ValueKey('btn_reset_empty_filters')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('state_empty')), findsNothing);
      expect(find.byKey(const ValueKey('card_learning_partner_cand_01')),
          findsOneWidget);
    });

    testWidgets(
        'search text input live filters partner list and clear button works',
        (tester) async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Search by name
      await tester.enterText(
          find.byKey(const ValueKey('input_partner_search')), 'Bawantha');
      await tester.pumpAndSettle();

      expect(find.text('Bawantha Silva'), findsOneWidget);
      expect(find.text('Amara Fernando'), findsNothing);
      expect(find.text('1 partner found'), findsOneWidget);

      // Clear search text via clear button
      expect(
          find.byKey(const ValueKey('btn_clear_search_text')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('btn_clear_search_text')));
      await tester.pumpAndSettle();

      expect(find.text('Amara Fernando'), findsOneWidget);
      expect(find.text('Bawantha Silva'), findsOneWidget);
      expect(find.text('2 partners found'), findsOneWidget);
    });

    testWidgets(
        'opening filter sheet allows selecting proficiency, language, availability and applying filters',
        (tester) async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Tap filter button to open sheet
      await tester.tap(find.byKey(const ValueKey('btn_open_filters')));
      await tester.pumpAndSettle();

      expect(find.text('Filter Learning Partners'), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_proficiency_Intermediate')),
          findsOneWidget);

      // Select Intermediate proficiency
      await tester
          .tap(find.byKey(const ValueKey('filter_proficiency_Intermediate')));
      await tester.pumpAndSettle();

      // Tap Apply Filters
      await tester.tap(find.byKey(const ValueKey('btn_sheet_apply')));
      await tester.pumpAndSettle();

      // Only Bawantha is Intermediate
      expect(find.text('Bawantha Silva'), findsOneWidget);
      expect(find.text('Amara Fernando'), findsNothing);

      // Applied filter chip displayed
      expect(find.byKey(const ValueKey('chip_filter_Proficiency_Intermediate')),
          findsOneWidget);

      // Remove the applied filter chip via 'X'
      final chipDeleteIcon = find.descendant(
        of: find.byKey(const ValueKey('chip_filter_Proficiency_Intermediate')),
        matching: find.byIcon(Icons.close_rounded),
      );
      await tester.tap(chipDeleteIcon);
      await tester.pumpAndSettle();

      // Both candidates restored
      expect(find.text('Amara Fernando'), findsOneWidget);
      expect(find.text('Bawantha Silva'), findsOneWidget);
    });

    testWidgets('changing sort dropdown updates order of candidates',
        (tester) async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Open sort dropdown
      await tester.tap(find.byKey(const ValueKey('dropdown_sort_options')));
      await tester.pumpAndSettle();

      // Select 'Name: Z to A'
      await tester.tap(find.text('Name: Z to A').last);
      await tester.pumpAndSettle();

      expect(vm.filters.sortOption, equals(LearningPartnerSort.nameDesc));
      expect(vm.candidates.first.displayName, equals('Bawantha Silva'));
    });

    testWidgets(
        'view profile button opens authorized profile dialog with public details only',
        (tester) async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Tap 'View Profile' on Amara's card
      await tester.tap(find.byKey(const ValueKey('btn_view_profile_cand_01')));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(
          find.byKey(const ValueKey('dialog_learning_partner_profile_cand_01')),
          findsOneWidget);
      expect(find.text('Amara Fernando'), findsNWidgets(2)); // Card + Dialog
      expect(
          find.descendant(
            of: find.byKey(
                const ValueKey('dialog_learning_partner_profile_cand_01')),
            matching: find
                .text('Mobile architect passionate about Clean Architecture.'),
          ),
          findsOneWidget);
      expect(find.text('Skills Offered (Can Teach)'), findsOneWidget);
      expect(find.text('Skills Wanted (To Learn)'), findsOneWidget);
      expect(find.text('Learning Goals'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_dialog_connect')), findsOneWidget);

      // Verify ZERO leakage of account IDs or unapproved private fields
      expect(find.textContaining('account'), findsNothing);
      expect(find.textContaining('acc_'), findsNothing);

      // Close dialog
      await tester.tap(find.byKey(const ValueKey('btn_dialog_close')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('dialog_learning_partner_profile_cand_01')),
          findsNothing);
    });

    testWidgets(
        'connect button triggers callback and respects Task 05-02 boundary',
        (tester) async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      LearningPartnerCandidate? connectedCandidate;
      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        onConnect: (candidate) {
          connectedCandidate = candidate;
        },
      ));
      await tester.pumpAndSettle();

      // Tap 'Connect' on Amara's card
      await tester.tap(find.byKey(const ValueKey('btn_connect_cand_01')));
      await tester.pumpAndSettle();

      expect(connectedCandidate, isNotNull);
      expect(connectedCandidate!.id, equals('cand_01'));
      expect(connectedCandidate!.displayName, equals('Amara Fernando'));
    });

    testWidgets(
        'default connect action shows explicit Task 05-02 boundary snackbar',
        (tester) async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      await tester.pumpWidget(
          _buildTestApp(viewModel: vm)); // no onConnect callback passed
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('btn_connect_cand_01')));
      await tester.pump(); // Start SnackBar animation

      expect(find.textContaining('Task 05-02 boundary'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets(
        'responsive layout at 320dp width renders without RenderFlex overflow',
        (tester) async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        size: const Size(320, 568), // 320dp narrow viewport
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Amara Fernando'), findsOneWidget);
    });

    testWidgets(
        'responsive layout at 360dp width renders without RenderFlex overflow',
        (tester) async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        size: const Size(360, 640),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Amara Fernando'), findsOneWidget);
    });

    testWidgets(
        'responsive layout at 412dp width renders without RenderFlex overflow',
        (tester) async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        size: const Size(412, 915), // 412dp modern viewport
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Amara Fernando'), findsOneWidget);
    });

    testWidgets(
        'responsive layout with 1.5x dynamic text scaling renders without overflow',
        (tester) async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        size: const Size(360, 640),
        textScaleFactor: 1.5, // 1.5x text scaling
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Amara Fernando'), findsOneWidget);
    });
  });
}
