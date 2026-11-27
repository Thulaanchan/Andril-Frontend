import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/home/screens/social_home_screen.dart';
import 'package:andril_mobile/features/social/home/viewmodels/social_home_viewmodel.dart';
import 'package:andril_mobile/features/social/home/viewmodels/social_navigation_coordinator.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone_repository.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zones_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zones_viewmodel.dart';

class MockSocialZoneRepository implements ISocialZoneRepository {
  @override
  Future<ZoneResult<List<SocialZone>>> getZones({String? category, String? query}) async {
    return const ZoneResult.success([
      SocialZone(
        id: 'z-journey-1',
        name: 'Photography Explorers',
        description: 'Landscape and architecture photography.',
        category: 'Creative Arts',
        memberCount: 88,
      ),
    ]);
  }

  @override
  Future<ZoneResult<SocialZone>> getZoneDetails(String zoneId) async =>
      const ZoneResult.failure(ZoneFailure(type: ZoneFailureType.notFound, message: ''));

  @override
  Future<ZoneResult<SocialZone>> joinZone(String zoneId) async =>
      const ZoneResult.failure(ZoneFailure(type: ZoneFailureType.serviceUnavailable, message: ''));

  @override
  Future<ZoneResult<SocialZone>> leaveZone(String zoneId) async =>
      const ZoneResult.failure(ZoneFailure(type: ZoneFailureType.serviceUnavailable, message: ''));
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  @override
  SessionPhase get phase => SessionPhase.signedIn;

  @override
  String? get subject => 'journey_user_id';

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) => () {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSessionController fakeSession;
  late MockSocialZoneRepository mockZoneRepo;

  setUp(() {
    fakeSession = FakeSessionController();
    mockZoneRepo = MockSocialZoneRepository();
  });

  Widget buildHarness({
    required SocialNavigationCoordinator coordinator,
    required SocialHomeViewModel homeVm,
    required SocialZonesViewModel zonesVm,
  }) {
    return MaterialApp(
      home: AnimatedBuilder(
        animation: coordinator,
        builder: (context, _) {
          return switch (coordinator.currentDestination) {
            SocialDestination.home => SocialHomeScreen(
                viewModel: homeVm,
                onExplorePeople: () => coordinator.navigateTo(SocialDestination.discovery),
                onDestinationSelected: (idx) {
                  if (idx == 1) coordinator.navigateTo(SocialDestination.zones);
                },
              ),
            SocialDestination.zones => SocialZonesScreen(
                viewModel: zonesVm,
              ),
            SocialDestination.discovery => Scaffold(
                appBar: AppBar(title: const Text('Discovery Surface')),
                body: const Center(child: Text('Discovery Screen Mock')),
              ),
            SocialDestination.connections => Scaffold(
                appBar: AppBar(title: const Text('Connections Surface')),
                body: const Center(child: Text('Connections Screen Mock')),
              ),
            SocialDestination.profile => Scaffold(
                appBar: AppBar(title: const Text('Profile Surface')),
                body: const Center(child: Text('Profile Screen Mock')),
              ),
            SocialDestination.personality => Scaffold(
                appBar: AppBar(title: const Text('Personality Surface')),
                body: const Center(child: Text('Personality Screen Mock')),
              ),
            SocialDestination.search => Scaffold(
                appBar: AppBar(title: const Text('Search Surface')),
                body: const Center(child: Text('Search Screen Mock')),
              ),
            SocialDestination.savedProfiles => Scaffold(
                appBar: AppBar(title: const Text('Saved Profiles Surface')),
                body: const Center(child: Text('Saved Profiles Screen Mock')),
              ),
            SocialDestination.preferences => Scaffold(
                appBar: AppBar(title: const Text('Preferences Surface')),
                body: const Center(child: Text('Preferences Screen Mock')),
              ),
            SocialDestination.accessDenied => Scaffold(
                appBar: AppBar(title: const Text('Access Denied')),
                body: const Center(child: Text('Restricted Access')),
              ),
          };
        },
      ),
    );
  }

  group('Social Journey Integration (Task 093)', () {
    testWidgets('executes complete journey from Home to Zones and Discovery', (tester) async {
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'journey_user_id'),
      );
      final homeVm = SocialHomeViewModel(
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'journey_user_id'),
      );
      await homeVm.initialize();

      final zonesVm = SocialZonesViewModel(
        repository: mockZoneRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await tester.pumpWidget(buildHarness(
        coordinator: coordinator,
        homeVm: homeVm,
        zonesVm: zonesVm,
      ));
      await tester.pumpAndSettle();

      // 1. Initial surface is Home
      expect(find.byType(SocialHomeScreen), findsOneWidget);

      // 2. Journey: Home -> Zones
      coordinator.navigateTo(SocialDestination.zones);
      await tester.pumpAndSettle();

      expect(find.byType(SocialZonesScreen), findsOneWidget);
      expect(find.text('Photography Explorers'), findsOneWidget);

      // 3. Journey: Zones -> Discovery
      coordinator.navigateTo(SocialDestination.discovery);
      await tester.pumpAndSettle();

      expect(find.text('Discovery Surface'), findsOneWidget);

      // 4. Journey: Discovery -> Connections
      coordinator.navigateTo(SocialDestination.connections);
      await tester.pumpAndSettle();

      expect(find.text('Connections Surface'), findsOneWidget);

      // 5. Journey: Back to Home
      coordinator.navigateTo(SocialDestination.home);
      await tester.pumpAndSettle();

      expect(find.byType(SocialHomeScreen), findsOneWidget);
    });

    testWidgets('journey halts and redirects to accessDenied when unauthorized', (tester) async {
      final coordinator = SocialNavigationCoordinator(
        sessionController: fakeSession,
        isSocialOptedIn: false, // Unauthorized
      );
      final homeVm = SocialHomeViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );
      final zonesVm = SocialZonesViewModel(
        repository: mockZoneRepo,
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );

      await tester.pumpWidget(buildHarness(
        coordinator: coordinator,
        homeVm: homeVm,
        zonesVm: zonesVm,
      ));
      await tester.pumpAndSettle();

      final navigated = coordinator.navigateTo(SocialDestination.zones);
      expect(navigated, isFalse);

      await tester.pumpAndSettle();
      expect(find.text('Restricted Access'), findsOneWidget);
    });
  });
}
