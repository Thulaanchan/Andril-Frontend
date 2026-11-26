import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone_repository.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_details_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_discovery_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_membership_section.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zones_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zones_viewmodel.dart';

class MockSocialZoneRepository implements ISocialZoneRepository {
  List<SocialZone> zonesList = [
    const SocialZone(
      id: 'z-test-1',
      name: 'Photography Enthusiasts',
      description: 'Landscape and street photography.',
      category: 'Creative Arts',
      memberCount: 88,
      membershipStatus: ZoneMembershipStatus.notMember,
      rules: ['Respect original content', 'Be constructive'],
      tags: ['photo', 'art'],
    ),
    const SocialZone(
      id: 'z-test-2',
      name: 'Trail Runners',
      description: 'Weekly running and marathons.',
      category: 'Outdoors',
      memberCount: 54,
      membershipStatus: ZoneMembershipStatus.member,
      rules: ['Hydrate and stay safe'],
      tags: ['running', 'fitness'],
    ),
  ];

  ZoneResult<SocialZone> joinOutcome = const ZoneResult.failure(ZoneFailure(
    type: ZoneFailureType.serviceUnavailable,
    message: 'Zone membership registration is temporarily deferred pending backend service activation.',
  ));

  @override
  Future<ZoneResult<List<SocialZone>>> getZones({String? category, String? query}) async {
    var filtered = zonesList;
    if (category != null && category != 'All') {
      filtered = filtered.where((z) => z.category.toLowerCase() == category.toLowerCase()).toList();
    }
    if (query != null && query.isNotEmpty) {
      filtered = filtered.where((z) => z.name.toLowerCase().contains(query.toLowerCase())).toList();
    }
    return ZoneResult.success(filtered);
  }

  @override
  Future<ZoneResult<SocialZone>> getZoneDetails(String zoneId) async {
    final match = zonesList.where((z) => z.id == zoneId).firstOrNull;
    if (match != null) return ZoneResult.success(match);
    return const ZoneResult.failure(ZoneFailure(
      type: ZoneFailureType.notFound,
      message: 'Not found',
    ));
  }

  @override
  Future<ZoneResult<SocialZone>> joinZone(String zoneId) async => joinOutcome;

  @override
  Future<ZoneResult<SocialZone>> leaveZone(String zoneId) async => const ZoneResult.failure(ZoneFailure(
    type: ZoneFailureType.serviceUnavailable,
    message: 'Zone membership modification is temporarily deferred pending backend service activation.',
  ));
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  @override
  SessionPhase get phase => SessionPhase.signedIn;

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) => () {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockSocialZoneRepository mockRepo;
  late FakeSessionController fakeSession;

  setUp(() {
    mockRepo = MockSocialZoneRepository();
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

  group('SocialZonesScreen (S44)', () {
    testWidgets('renders list of zones and triggers callbacks', (tester) async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      SocialZone? selected;
      bool createdPressed = false;
      bool myZonesPressed = false;

      await tester.pumpWidget(buildTestHost(SocialZonesScreen(
        viewModel: vm,
        onZoneSelected: (z) => selected = z,
        onCreateZone: () => createdPressed = true,
        onMyZones: () => myZonesPressed = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Social Zones'), findsOneWidget);
      expect(find.text('Photography Enthusiasts'), findsOneWidget);
      expect(find.text('Trail Runners'), findsOneWidget);

      await tester.tap(find.byKey(const Key('my_zones_button')));
      expect(myZonesPressed, isTrue);

      await tester.tap(find.byKey(const Key('create_zone_fab')));
      expect(createdPressed, isTrue);

      await tester.tap(find.byKey(const Key('zone_card_z-test-1')));
      expect(selected?.id, 'z-test-1');
    });

    testWidgets('displays access denied when not opted in', (tester) async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );

      await tester.pumpWidget(buildTestHost(SocialZonesScreen(viewModel: vm)));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('filters zones using category chips', (tester) async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await tester.pumpWidget(buildTestHost(SocialZonesScreen(viewModel: vm)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_chip_outdoors')));
      await tester.pumpAndSettle();

      expect(find.text('Trail Runners'), findsOneWidget);
      expect(find.text('Photography Enthusiasts'), findsNothing);
    });
  });

  group('SocialZoneDiscoveryScreen (S45)', () {
    testWidgets('renders grid layout and handles selection', (tester) async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      await vm.loadZones();

      SocialZone? selected;
      bool backPressed = false;

      await tester.pumpWidget(buildTestHost(SocialZoneDiscoveryScreen(
        viewModel: vm,
        onZoneSelected: (z) => selected = z,
        onBack: () => backPressed = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Discover Zones'), findsOneWidget);
      expect(find.text('Photography Enthusiasts'), findsOneWidget);

      await tester.tap(find.byKey(const Key('discovery_zone_card_z-test-1')));
      expect(selected?.id, 'z-test-1');

      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(backPressed, isTrue);
    });
  });

  group('SocialZoneDetailsScreen (S46) & SocialZoneMembershipSection', () {
    testWidgets('renders zone details, guidelines, and handles deferred join action', (tester) async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      final zone = mockRepo.zonesList.first;
      vm.selectZone(zone);

      bool membersClicked = false;

      await tester.pumpWidget(buildTestHost(SocialZoneDetailsScreen(
        zone: zone,
        viewModel: vm,
        onMembersPressed: () => membersClicked = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Photography Enthusiasts'), findsWidgets);
      expect(find.text('About This Zone'), findsOneWidget);
      expect(find.text('Community Guidelines'), findsOneWidget);
      expect(find.text('Respect original content'), findsOneWidget);

      final joinBtn = find.byKey(const Key('join_zone_button'));
      expect(joinBtn, findsOneWidget);

      await tester.tap(joinBtn);
      await tester.pumpAndSettle();

      // Backend readiness: displays deferred message
      expect(find.textContaining('Zone membership registration is temporarily deferred'), findsOneWidget);

      await tester.tap(find.byKey(const Key('zone_members_tile')));
      expect(membersClicked, isTrue);
    });

    testWidgets('SocialZoneMembershipSection renders standalone membership actions', (tester) async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(buildTestHost(SocialZoneMembershipSection(
        zone: mockRepo.zonesList.first,
        viewModel: vm,
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('join_zone_button')), findsOneWidget);
    });
  });

  group('Responsive Viewport Tests', () {
    testWidgets('renders screens across 320dp, 400dp, 800dp viewports without overflow', (tester) async {
      final vm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      await vm.loadZones();

      for (final size in [
        const Size(320, 640),
        const Size(400, 800),
        const Size(800, 1200),
      ]) {
        await tester.pumpWidget(buildTestHost(SocialZonesScreen(viewModel: vm), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(buildTestHost(SocialZoneDiscoveryScreen(viewModel: vm), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(buildTestHost(SocialZoneDetailsScreen(
          zone: mockRepo.zonesList.first,
          viewModel: vm,
        ), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
