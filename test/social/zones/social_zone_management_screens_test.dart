import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone_management.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone_repository.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_create_zone_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_my_zones_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_communication_section.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_management_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_management_viewmodel.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_members_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zones_viewmodel.dart';

class MockSocialZoneRepository implements ISocialZoneRepository {
  List<SocialZone> zones = [
    const SocialZone(
      id: 'z-joined-1',
      name: 'Mobile App Builders',
      description: 'Flutter & native developers.',
      category: 'Technology',
      memberCount: 120,
      membershipStatus: ZoneMembershipStatus.member,
      rules: ['Respect one another'],
    ),
    const SocialZone(
      id: 'z-host-1',
      name: 'Designers Circle',
      description: 'UI/UX designers sharing critiques.',
      category: 'Creative Arts',
      memberCount: 45,
      membershipStatus: ZoneMembershipStatus.host,
      rules: ['Constructive critiques only'],
    ),
  ];

  @override
  Future<ZoneResult<List<SocialZone>>> getZones({String? category, String? query}) async =>
      ZoneResult.success(zones);

  @override
  Future<ZoneResult<SocialZone>> getZoneDetails(String zoneId) async =>
      ZoneResult.success(zones.first);

  @override
  Future<ZoneResult<SocialZone>> joinZone(String zoneId) async =>
      const ZoneResult.failure(ZoneFailure(
        type: ZoneFailureType.serviceUnavailable,
        message: 'Deferred',
      ));

  @override
  Future<ZoneResult<SocialZone>> leaveZone(String zoneId) async =>
      const ZoneResult.failure(ZoneFailure(
        type: ZoneFailureType.serviceUnavailable,
        message: 'Deferred',
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

  group('SocialCreateZoneScreen (S47)', () {
    testWidgets('allows entering details, rules, tags, and displays deferred status on submit', (tester) async {
      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      bool backCalled = false;

      await tester.pumpWidget(buildTestHost(SocialCreateZoneScreen(
        viewModel: vm,
        onBack: () => backCalled = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Create New Zone'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('create_zone_name_field')), 'Fullstack Innovators');
      await tester.enterText(find.byKey(const Key('create_zone_desc_field')), 'A dedicated space for fullstack web and mobile engineering.');

      await tester.enterText(find.byKey(const Key('create_zone_rule_input')), 'No unsolicited self-promotion');
      await tester.tap(find.byKey(const Key('add_rule_button')));
      await tester.pumpAndSettle();
      expect(find.text('No unsolicited self-promotion'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('create_zone_tag_input')), 'fullstack');
      await tester.ensureVisible(find.byKey(const Key('add_tag_button')));
      await tester.tap(find.byKey(const Key('add_tag_button')));
      await tester.pumpAndSettle();
      expect(find.text('#fullstack'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('submit_create_zone_button')));
      await tester.tap(find.byKey(const Key('submit_create_zone_button')));
      await tester.pumpAndSettle();

      // Backend readiness: displays deferred message
      expect(find.byKey(const Key('create_zone_error_banner')), findsOneWidget);
      expect(find.textContaining('Zone creation is temporarily deferred'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cancel_create_zone_button')));
      expect(backCalled, isTrue);
    });
  });

  group('SocialMyZonesScreen (S48)', () {
    testWidgets('displays joined and managed tabs with appropriate cards', (tester) async {
      final zonesVm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      await zonesVm.loadZones();

      SocialZone? selected;
      SocialZone? managed;

      await tester.pumpWidget(buildTestHost(SocialMyZonesScreen(
        viewModel: zonesVm,
        onZoneSelected: (z) => selected = z,
        onManageZone: (z) => managed = z,
      )));
      await tester.pumpAndSettle();

      expect(find.text('My Zones'), findsOneWidget);
      expect(find.text('Mobile App Builders'), findsOneWidget);

      await tester.tap(find.byKey(const Key('my_zone_card_z-joined-1')));
      expect(selected?.id, 'z-joined-1');

      // Switch to Managed tab
      await tester.tap(find.byKey(const Key('managed_zones_tab')));
      await tester.pumpAndSettle();

      expect(find.text('Designers Circle'), findsOneWidget);
      await tester.tap(find.byKey(const Key('manage_zone_btn_z-host-1')));
      expect(managed?.id, 'z-host-1');
    });
  });

  group('SocialZoneMembersScreen (S49)', () {
    testWidgets('renders member entries and surfaces moderation actions when permitted', (tester) async {
      final hostEvidence = ZonePermissionEvidence.host(
        zoneId: 'z-host-1',
        userId: 'u-self',
      );

      final mgmtVm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: hostEvidence,
      );

      final now = DateTime.fromMillisecondsSinceEpoch(0);
      final members = [
        ZoneMemberEntry(
          memberId: 'm-1',
          displayName: 'Bob Moderator',
          role: ZoneRole.moderator,
          joinedAt: now,
        ),
        ZoneMemberEntry(
          memberId: 'u-self',
          displayName: 'Myself Host',
          role: ZoneRole.host,
          joinedAt: now,
          isSelf: true,
        ),
      ];

      await tester.pumpWidget(buildTestHost(SocialZoneMembersScreen(
        zone: mockRepo.zones.last,
        viewModel: mgmtVm,
        members: members,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Bob Moderator'), findsOneWidget);
      expect(find.text('Myself Host'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      expect(find.byKey(const Key('role_menu_m-1')), findsOneWidget);
    });
  });

  group('SocialZoneManagementScreen', () {
    testWidgets('allows host to edit settings and displays deferred update feedback', (tester) async {
      final hostEvidence = ZonePermissionEvidence.host(
        zoneId: 'z-host-1',
        userId: 'u-host-1',
      );

      final mgmtVm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: hostEvidence,
      );

      await tester.pumpWidget(buildTestHost(SocialZoneManagementScreen(
        zone: mockRepo.zones.last,
        viewModel: mgmtVm,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Manage Designers Circle'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('edit_zone_desc_field')), 'Updated description for the design community with proper length.');
      await tester.ensureVisible(find.byKey(const Key('save_zone_changes_button')));
      await tester.tap(find.byKey(const Key('save_zone_changes_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('management_error_banner')), findsOneWidget);
      expect(find.textContaining('Zone modification is temporarily deferred'), findsOneWidget);
    });

    testWidgets('restricts access when caller lacks host permission evidence', (tester) async {
      final memberEvidence = ZonePermissionEvidence.memberDefault(
        zoneId: 'z-host-1',
        userId: 'u-nonhost',
      );

      final mgmtVm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: memberEvidence,
      );

      await tester.pumpWidget(buildTestHost(SocialZoneManagementScreen(
        zone: mockRepo.zones.last,
        viewModel: mgmtVm,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Management Restricted'), findsOneWidget);
      expect(find.byKey(const Key('save_zone_changes_button')), findsNothing);
    });
  });

  group('SocialZoneCommunicationSection', () {
    testWidgets('enables chat button only for active members and keeps live stage disabled', (tester) async {
      bool chatOpened = false;

      // Non-member test
      await tester.pumpWidget(buildTestHost(SocialZoneCommunicationSection(
        zone: mockRepo.zones.first,
        isMember: false,
        onOpenChat: () => chatOpened = true,
      )));
      await tester.pumpAndSettle();

      final nonMemberChatBtn = tester.widget<FilledButton>(find.byKey(const Key('zone_chat_button')));
      expect(nonMemberChatBtn.onPressed, isNull);
      expect(find.text('Join this zone to access community chat channels.'), findsOneWidget);

      // Member test
      await tester.pumpWidget(buildTestHost(SocialZoneCommunicationSection(
        zone: mockRepo.zones.first,
        isMember: true,
        onOpenChat: () => chatOpened = true,
      )));
      await tester.pumpAndSettle();

      final memberChatBtn = tester.widget<FilledButton>(find.byKey(const Key('zone_chat_button')));
      expect(memberChatBtn.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('zone_chat_button')));
      expect(chatOpened, isTrue);

      final liveBtn = tester.widget<OutlinedButton>(find.byKey(const Key('zone_audio_stage_button')));
      expect(liveBtn.onPressed, isNull);
    });
  });

  group('Responsive Viewport Verification', () {
    testWidgets('Batch 09 screens render across 320dp, 400dp, 800dp without overflow', (tester) async {
      final hostEvidence = ZonePermissionEvidence.host(
        zoneId: 'z-host-1',
        userId: 'u-host-1',
      );
      final mgmtVm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: hostEvidence,
      );
      final zonesVm = SocialZonesViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      await zonesVm.loadZones();

      for (final size in [
        const Size(320, 640),
        const Size(400, 800),
        const Size(800, 1200),
      ]) {
        await tester.pumpWidget(buildTestHost(SocialCreateZoneScreen(viewModel: mgmtVm), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(buildTestHost(SocialMyZonesScreen(viewModel: zonesVm), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(buildTestHost(SocialZoneMembersScreen(
          zone: mockRepo.zones.first,
          viewModel: mgmtVm,
        ), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(buildTestHost(SocialZoneManagementScreen(
          zone: mockRepo.zones.last,
          viewModel: mgmtVm,
        ), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
