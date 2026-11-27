import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone_management.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_management_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_management_viewmodel.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_membership_confirmation.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_moderation_screen.dart';

class FakeSessionController extends ChangeNotifier implements SessionController {
  @override
  SessionPhase get phase => SessionPhase.signedIn;

  @override
  String? get subject => 'test-host-user';

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) => () {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSessionController fakeSession;
  const testZone = SocialZone(
    id: 'zone-101',
    name: 'Colombo Tech Community',
    description: 'A space for software engineers and founders in Colombo.',
    category: 'Technology',
    memberCount: 42,
    requiresApproval: true,
    rules: ['Be respectful', 'No spamming'],
  );

  setUp(() {
    fakeSession = FakeSessionController();
  });

  Widget buildTestHost(
    Widget child, {
    Size size = const Size(400, 800),
    double textScale = 1.0,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Task 143 - S24/S66 Zone Membership Confirmation Dialog', () {
    testWidgets('renders Join confirmation with approval note and triggers confirm/cancel', (tester) async {
      bool confirmed = false;
      bool cancelled = false;

      await tester.pumpWidget(buildTestHost(SocialZoneMembershipConfirmationDialog(
        zone: testZone,
        action: ZoneMembershipAction.join,
        onConfirm: () async => confirmed = true,
        onCancel: () => cancelled = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Request to Join'), findsWidgets);
      expect(find.text('Would you like to join "Colombo Tech Community"?'), findsOneWidget);
      expect(find.textContaining('This zone requires host approval'), findsOneWidget);

      // Cancel button
      await tester.tap(find.byKey(const Key('cancel_membership_action_button')));
      expect(cancelled, isTrue);

      // Confirm button
      await tester.tap(find.byKey(const Key('confirm_join_zone_button')));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });

    testWidgets('renders Leave confirmation with consequence warning and error styling', (tester) async {
      bool confirmed = false;

      const nonApprovalZone = SocialZone(
        id: 'zone-102',
        name: 'Photography Enthusiasts',
        description: 'Share your photos',
        requiresApproval: false,
      );

      await tester.pumpWidget(buildTestHost(SocialZoneMembershipConfirmationDialog(
        zone: nonApprovalZone,
        action: ZoneMembershipAction.leave,
        onConfirm: () async => confirmed = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Leave Zone'), findsWidgets);
      expect(find.text('Are you sure you want to leave "Photography Enthusiasts"?'), findsOneWidget);
      expect(find.textContaining('You will no longer receive zone updates'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm_leave_zone_button')));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });
  });

  group('Task 144 - S44 Zone Host Tools (SocialZoneManagementScreen)', () {
    testWidgets('renders host controls, moderation tile, and handles back navigation', (tester) async {
      final hostEvidence = ZonePermissionEvidence.host(
        zoneId: testZone.id,
        userId: 'test-host-user',
      );

      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: hostEvidence,
      );

      bool backed = false;
      bool moderated = false;

      await tester.pumpWidget(buildTestHost(SocialZoneManagementScreen(
        zone: testZone,
        viewModel: vm,
        onBack: () => backed = true,
        onModerateZone: () => moderated = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Manage Colombo Tech Community'), findsOneWidget);
      expect(find.text('Zone Information'), findsOneWidget);
      expect(find.text('Membership Governance'), findsOneWidget);
      expect(find.text('Zone Moderation & Requests'), findsOneWidget);

      // Tap moderation tile
      await tester.tap(find.byKey(const Key('zone_moderation_tile')));
      expect(moderated, isTrue);

      // Tap back button
      await tester.tap(find.byKey(const Key('management_close_button')));
      expect(backed, isTrue);
    });

    testWidgets('restricts management when caller lacks host permission', (tester) async {
      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: ZonePermissionEvidence.unverified(
          zoneId: testZone.id,
          userId: 'test-unauthorized-user',
        ),
      );

      await tester.pumpWidget(buildTestHost(SocialZoneManagementScreen(
        zone: testZone,
        viewModel: vm,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Management Restricted'), findsOneWidget);
      expect(find.textContaining('Only verified Zone hosts possess authority'), findsOneWidget);
    });
  });

  group('Task 145 - S65 Zone Moderation (SocialZoneModerationScreen)', () {
    testWidgets('renders pending join requests and allows reviewing them', (tester) async {
      final hostEvidence = ZonePermissionEvidence.host(
        zoneId: testZone.id,
        userId: 'test-host-user',
      );

      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: hostEvidence,
      );

      final requests = [
        ZoneJoinRequestItem(
          requestId: 'req-001',
          memberId: 'user-001',
          displayName: 'Dilan Perera',
          requestedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestHost(SocialZoneModerationScreen(
        zone: testZone,
        viewModel: vm,
        pendingRequests: requests,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Colombo Tech Community Moderation'), findsOneWidget);
      expect(find.text('Zone Moderation applies only within "Colombo Tech Community".'), findsOneWidget);
      expect(find.text('Dilan Perera'), findsOneWidget);
      expect(find.byKey(const Key('approve_request_req-001')), findsOneWidget);
      expect(find.byKey(const Key('decline_request_req-001')), findsOneWidget);

      // Tap approve
      await tester.tap(find.byKey(const Key('approve_request_req-001')));
      await tester.pumpAndSettle();

      // Displays dormant backend notice
      expect(find.byKey(const Key('moderation_error_banner')), findsOneWidget);
      expect(find.textContaining('Membership moderation is temporarily deferred'), findsOneWidget);
    });

    testWidgets('member removal opens confirmation modal and preserves M6 boundaries', (tester) async {
      final hostEvidence = ZonePermissionEvidence.host(
        zoneId: testZone.id,
        userId: 'test-host-user',
      );

      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: hostEvidence,
      );

      await tester.pumpWidget(buildTestHost(SocialZoneModerationScreen(
        zone: testZone,
        viewModel: vm,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Zone Action Controls'), findsOneWidget);
      expect(find.textContaining('Platform-wide harassment, abuse, or safety concerns must be reported through Community Safety (M6)'), findsOneWidget);

      // Tap Remove button
      await tester.tap(find.byKey(const Key('remove_member_action_button')));
      await tester.pumpAndSettle();

      // Confirmation modal
      expect(find.text('Remove from Zone'), findsOneWidget);
      expect(find.textContaining('This action applies only to this Zone'), findsOneWidget);

      // Cancel removal
      await tester.tap(find.byKey(const Key('cancel_moderation_dialog_button')));
      await tester.pumpAndSettle();
      expect(find.text('Remove from Zone'), findsNothing);
    });

    testWidgets('denies access when caller lacks moderation authority', (tester) async {
      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: ZonePermissionEvidence.unverified(
          zoneId: testZone.id,
          userId: 'non-mod-user',
        ),
      );

      await tester.pumpWidget(buildTestHost(SocialZoneModerationScreen(
        zone: testZone,
        viewModel: vm,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Moderation Restricted'), findsOneWidget);
      expect(find.textContaining('Only verified Zone hosts and moderators possess authority'), findsOneWidget);
    });
  });

  group('Batch 06 Responsive Viewports', () {
    testWidgets('all Batch 06 screens render across 320dp, 400dp, 800dp viewports without overflow', (tester) async {
      final hostEvidence = ZonePermissionEvidence.host(
        zoneId: testZone.id,
        userId: 'test-host-user',
      );

      final vm = SocialZoneManagementViewModel(
        sessionController: fakeSession,
        isSocialOptedIn: true,
        initialEvidence: hostEvidence,
      );

      for (final size in [
        const Size(320, 640),
        const Size(400, 800),
        const Size(800, 1200),
      ]) {
        // Confirmation dialog
        await tester.pumpWidget(buildTestHost(
          const SocialZoneMembershipConfirmationDialog(
            zone: testZone,
            action: ZoneMembershipAction.join,
          ),
          size: size,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Management screen
        await tester.pumpWidget(buildTestHost(
          SocialZoneManagementScreen(
            zone: testZone,
            viewModel: vm,
          ),
          size: size,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Moderation screen
        await tester.pumpWidget(buildTestHost(
          SocialZoneModerationScreen(
            zone: testZone,
            viewModel: vm,
          ),
          size: size,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
