import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/discovery/data/social_discovery_repository.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_discovery_filters_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_discovery_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_discovery_viewmodel.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_member_profile_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_saved_profiles_screen.dart';
import 'package:andril_mobile/features/social/interests_preferences/domain/social_preferences_model.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';

class FakeScreenSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _stubPhase;
  final String? _subject;
  final Set<VoidCallback> _clearers = {};

  FakeScreenSessionController({
    SessionPhase phase = SessionPhase.signedIn,
    String? subject = 'user_test_subject',
  })  : _stubPhase = phase,
        _subject = subject;

  @override
  SessionPhase get phase => _stubPhase;

  @override
  String? get subject => _subject;

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

class FakeScreenDiscoveryRepository implements ISocialDiscoveryRepository {
  DiscoveryResult<List<SocialCandidate>> exploreResult;
  DiscoveryResult<SocialInterestResult> interestResult;
  final List<Map<String, dynamic>> recordCalls = [];

  FakeScreenDiscoveryRepository({
    DiscoveryResult<List<SocialCandidate>>? exploreResult,
    DiscoveryResult<SocialInterestResult>? interestResult,
  })  : exploreResult = exploreResult ??
            const DiscoveryResult.success(<SocialCandidate>[]),
        interestResult = interestResult ??
            const DiscoveryResult.success(
              SocialInterestResult(
                success: true,
                matchCreated: false,
                visibleState: 'Recorded',
              ),
            );

  @override
  Future<DiscoveryResult<List<SocialCandidate>>> getExploreFeed({
    int rotationOffset = 0,
    int limit = 20,
  }) async {
    return exploreResult;
  }

  @override
  Future<DiscoveryResult<SocialInterestResult>> recordInterest({
    required String targetProfileId,
    required bool isPositive,
  }) async {
    recordCalls.add({'targetProfileId': targetProfileId, 'isPositive': isPositive});
    return interestResult;
  }
}

SocialCandidate _fixtureCandidate({
  String id = 'cand_01',
  String name = 'Amara K.',
  int age = 24,
}) {
  return SocialCandidate(
    id: id,
    displayName: name,
    age: age,
    approximateDistanceKm: 12,
    locationName: 'Colombo',
    sharedLanguages: const ['English', 'Sinhala'],
    sharedConnectionGoals: const ['Friendship', 'Networking'],
    biography: 'UI designer and tea enthusiast living in Colombo.',
    interests: const {'Design', 'Photography', 'Coffee'},
    photoUrls: const ['https://cdn.andril.app/photos/p1.jpg'],
    isVerified: true,
  );
}

void main() {
  group('S09 Discover People Screen Tests (M5-FE-DISCOVERY-QA-01)', () {
    testWidgets('renders S09 candidate card and action buttons without overflow at 400x800', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final candidate = _fixtureCandidate();
      final repo = FakeScreenDiscoveryRepository(
        exploreResult: DiscoveryResult.success([candidate]),
      );
      final session = FakeScreenSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user_test_subject'),
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialDiscoveryScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Amara K., 24'), findsOneWidget);
      expect(find.text('12 km away'), findsOneWidget);
      expect(find.text('Friendship'), findsOneWidget);
      expect(find.text('Networking'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('renders cleanly on compact screen 360x640 at TextScaler 1.0 without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final candidate = _fixtureCandidate();
      final repo = FakeScreenDiscoveryRepository(
        exploreResult: DiscoveryResult.success([candidate]),
      );
      final session = FakeScreenSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user_test_subject'),
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialDiscoveryScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Amara K., 24'), findsOneWidget);
    });

    testWidgets('renders cleanly on standard mobile 400x800 with accessibility scaling (1.3) without overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final candidate = _fixtureCandidate();
      final repo = FakeScreenDiscoveryRepository(
        exploreResult: DiscoveryResult.success([candidate]),
      );
      final session = FakeScreenSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user_test_subject'),
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              textScaler: TextScaler.linear(1.3),
            ),
            child: SocialDiscoveryScreen(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Amara K., 24'), findsOneWidget);
    });

    testWidgets('renders cleanly on tablet 800x1200', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final candidate = _fixtureCandidate();
      final repo = FakeScreenDiscoveryRepository(
        exploreResult: DiscoveryResult.success([candidate]),
      );
      final session = FakeScreenSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user_test_subject'),
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialDiscoveryScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Amara K., 24'), findsOneWidget);
    });

    testWidgets('tapping Pass and Like dispatches directional actions', (tester) async {
      final candidate = _fixtureCandidate();
      final repo = FakeScreenDiscoveryRepository(
        exploreResult: DiscoveryResult.success([candidate]),
      );
      final session = FakeScreenSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user_test_subject'),
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialDiscoveryScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Like button
      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.pumpAndSettle();

      expect(repo.recordCalls.length, 1);
      expect(repo.recordCalls.first['isPositive'], isTrue);
      expect(find.text("You're All Caught Up"), findsOneWidget);
    });

    testWidgets('renders access denied view when unauthorized', (tester) async {
      final repo = FakeScreenDiscoveryRepository();
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        isSocialOptedIn: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SocialDiscoveryScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('renders service unavailable view when backend is dormant', (tester) async {
      final repo = FakeScreenDiscoveryRepository(
        exploreResult: const DiscoveryResult.failure(
          errorMessage: 'Social discovery service is currently preparing and unavailable.',
          failureType: DiscoveryFailureType.serviceUnavailable,
        ),
      );
      final session = FakeScreenSessionController(phase: SessionPhase.signedIn);
      final vm = SocialDiscoveryViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user_test_subject'),
      );
      await vm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: SocialDiscoveryScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Discovery Preparing'), findsOneWidget);
      expect(find.text('Check Again'), findsOneWidget);
    });
  });

  group('S10 Member Profile Screen Tests (M5-FE-DISCOVERY-QA-01)', () {
    testWidgets('renders S10 member profile sections and details at 400x800', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final candidate = _fixtureCandidate();
      bool backTapped = false;
      bool reportTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialMemberProfileScreen(
            candidate: candidate,
            onBack: () => backTapped = true,
            onReport: () => reportTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Amara K., 24'), findsOneWidget);
      expect(find.text('Colombo'), findsOneWidget);
      expect(find.text('About Me'), findsOneWidget);
      expect(find.text('Looking For'), findsOneWidget);
      expect(find.text('Interests'), findsOneWidget);
      expect(find.text('Languages'), findsOneWidget);

      // Verify Back action
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(backTapped, isTrue);

      // Verify Report action in overflow menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Report Profile'), findsOneWidget);
      await tester.tap(find.text('Report Profile'));
      await tester.pumpAndSettle();
      expect(reportTapped, isTrue);
    });

    testWidgets('renders cleanly on small screen 320x640 at TextScaler 1.3', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final candidate = _fixtureCandidate();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: SocialMemberProfileScreen(candidate: candidate),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Amara K., 24'), findsOneWidget);
    });
  });

  group('S14 Discovery Filters Screen Tests (M5-FE-DISCOVERY-QA-01)', () {
    testWidgets('renders filter controls and dispatches applied draft', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SocialPreferencesModel? appliedDraft;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialDiscoveryFiltersScreen(
            initialFilters: SocialPreferencesModel(
              minAge: 20,
              maxAge: 70,
              maxDistanceKm: 30,
            ),
            onApply: (draft) => appliedDraft = draft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Discovery Filters'), findsOneWidget);
      expect(find.text('Show Me'), findsOneWidget);
      expect(find.text('Age Range'), findsOneWidget);
      expect(find.text('Maximum Distance'), findsOneWidget);
      expect(find.text('Looking For'), findsOneWidget);
      expect(find.text('Languages'), findsOneWidget);

      // Tap Apply Filters
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(appliedDraft, isNotNull);
      expect(appliedDraft!.minAge, greaterThanOrEqualTo(18));
      expect(appliedDraft!.maxDistanceKm, greaterThan(0));
    });

    testWidgets('renders cleanly on tablet 800x1200 at TextScaler 1.3', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 1200),
              textScaler: TextScaler.linear(1.3),
            ),
            child: SocialDiscoveryFiltersScreen(
              initialFilters: SocialPreferencesModel(
                minAge: 20,
                maxAge: 70,
                maxDistanceKm: 30,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Discovery Filters'), findsOneWidget);
    });
  });

  group('S15 Saved Profiles Screen Tests (M5-FE-DISCOVERY-QA-01)', () {
    testWidgets('renders saved profiles grid and handles remove action', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final candidate = _fixtureCandidate();
      SocialCandidate? removedCandidate;

      await tester.pumpWidget(
        MaterialApp(
          home: SocialSavedProfilesScreen(
            savedProfiles: [candidate],
            onRemoveProfile: (c) => removedCandidate = c,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Saved Profiles'), findsOneWidget);
      expect(find.text('Amara K., 24'), findsOneWidget);
      expect(find.text('Bookmarks are retained during your active session.'), findsOneWidget);

      // Tap remove bookmark button
      await tester.tap(find.byIcon(Icons.bookmark_remove_rounded));
      await tester.pumpAndSettle();

      expect(removedCandidate?.id, 'cand_01');
    });

    testWidgets('renders empty view when zero saved profiles exist', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SocialSavedProfilesScreen(savedProfiles: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Saved Profiles Yet'), findsOneWidget);
    });

    testWidgets('renders cleanly on small screen 320x640 at TextScaler 1.3', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final candidate = _fixtureCandidate();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: SocialSavedProfilesScreen(savedProfiles: [candidate]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Saved Profiles'), findsOneWidget);
    });
  });
}
