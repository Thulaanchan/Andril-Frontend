import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_search_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_search_viewmodel.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  final List<VoidCallback> _clearers = [];

  @override
  SessionPhase get phase => _phase;

  void setPhase(SessionPhase phase) {
    _phase = phase;
    notifyListeners();
  }

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) {
    _clearers.add(clearer);
    return () => _clearers.remove(clearer);
  }

  void invokeClearers() {
    for (final c in List.of(_clearers)) {
      c();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSessionController fakeSession;

  final sampleCandidates = [
    SocialCandidate(
      id: 'cand-01',
      displayName: 'Elena Rostova',
      age: 26,
      biography: 'Exploring coffee shops and film photography.',
      interests: const ['Photography', 'Coffee', 'Hiking'],
      isVerified: true,
    ),
    SocialCandidate(
      id: 'cand-02',
      displayName: 'Marcus Chen',
      age: 29,
      biography: 'Tech enthusiast, runner, and foodie.',
      interests: const ['Running', 'Technology', 'Cooking'],
      isVerified: false,
    ),
  ];

  setUp(() {
    fakeSession = FakeSessionController();
  });

  Widget buildTestHost(Widget child, {Size size = const Size(400, 800)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('SocialSearchViewModel', () {
    test('initializes with empty query and results', () {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.status, SocialSearchViewStatus.initial);
      expect(vm.currentQuery, isEmpty);
      expect(vm.results, isEmpty);
      expect(vm.isLoading, isFalse);
    });

    test('denies access if caller is not opted in', () async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );

      await vm.search('Elena', candidateSource: sampleCandidates);

      expect(vm.status, SocialSearchViewStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      expect(vm.results, isEmpty);
    });

    test('filters candidates by name, bio, and interest', () async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      // Search by name
      await vm.search('Elena', candidateSource: sampleCandidates);
      expect(vm.status, SocialSearchViewStatus.ready);
      expect(vm.results.length, 1);
      expect(vm.results.first.displayName, 'Elena Rostova');

      // Search by interest
      await vm.search('Running', candidateSource: sampleCandidates);
      expect(vm.status, SocialSearchViewStatus.ready);
      expect(vm.results.length, 1);
      expect(vm.results.first.displayName, 'Marcus Chen');

      // Search by non-existent term
      await vm.search('NonExistentTerm', candidateSource: sampleCandidates);
      expect(vm.status, SocialSearchViewStatus.empty);
      expect(vm.isEmpty, isTrue);
      expect(vm.results, isEmpty);
    });

    test('clears search results when query is emptied or clearSearch called', () async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.search('Elena', candidateSource: sampleCandidates);
      expect(vm.results.length, 1);

      vm.clearSearch();
      expect(vm.status, SocialSearchViewStatus.initial);
      expect(vm.currentQuery, isEmpty);
      expect(vm.results, isEmpty);
    });

    test('clears private search on session invalidation', () async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.search('Elena', candidateSource: sampleCandidates);
      expect(vm.results.length, 1);

      fakeSession.setPhase(SessionPhase.signedOut);
      expect(vm.status, SocialSearchViewStatus.accessDenied);
      expect(vm.results, isEmpty);
    });
  });

  group('SocialSearchScreen Widget Tests', () {
    testWidgets('renders search field and displays matching candidate cards', (tester) async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      SocialCandidate? selectedCandidate;
      await tester.pumpWidget(buildTestHost(SocialSearchScreen(
        viewModel: vm,
        candidates: sampleCandidates,
        onViewProfile: (c) => selectedCandidate = c,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Search Social Members'), findsOneWidget);

      // Enter search text
      await tester.enterText(find.byKey(const Key('search_people_field')), 'Elena');
      await tester.pumpAndSettle();

      expect(find.text('Elena Rostova, 26'), findsOneWidget);
      expect(find.text('Photography, Coffee, Hiking'), findsOneWidget);

      // Tap on candidate card
      await tester.tap(find.text('Elena Rostova, 26'));
      expect(selectedCandidate?.displayName, 'Elena Rostova');

      // Clear search
      await tester.tap(find.byKey(const Key('clear_search_button')));
      await tester.pumpAndSettle();

      expect(find.text('Search Social Members'), findsOneWidget);
    });

    testWidgets('renders empty state S26 when no candidates match', (tester) async {
      final vm = SocialSearchViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await tester.pumpWidget(buildTestHost(SocialSearchScreen(
        viewModel: vm,
        candidates: sampleCandidates,
      )));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('search_people_field')), 'Astronaut');
      await tester.pumpAndSettle();

      expect(find.text('No People Found'), findsOneWidget);
    });
  });
}
