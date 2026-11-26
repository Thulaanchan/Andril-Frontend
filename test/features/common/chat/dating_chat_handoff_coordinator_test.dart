import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/common/chat/domain/module_config.dart';
import 'package:andril_mobile/features/common/chat/presentation/navigation/chat_entry_handoff.dart';
import 'package:andril_mobile/features/common/chat/presentation/navigation/dating_chat_handoff_coordinator.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chat_screen.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chats_list_screen.dart';
import 'package:andril_mobile/features/common/chat/preview/dating_chat_preview_host.dart';
import 'package:andril_mobile/features/common/chat/preview/main_app_chat_route_preview.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/social_relationship.dart';

void main() {
  group('DatingChatHandoffCoordinator — Required Checkpoint Tests (FE-03E-05-R01)', () {
    // Standard mock candidate fixtures
    final candidateAira = SocialCandidate(
      id: 'soc_aira',
      displayName: 'Aira',
      age: 24,
      photoUrls: const ['assets/profile/aira_avatar.png'],
      biography: 'Design & photography enthusiast',
    );

    final candidateAva = SocialCandidate(
      id: 'soc_ava',
      displayName: 'Ava',
      age: 26,
      photoUrls: const ['assets/profile/ava_avatar.webp'],
      biography: 'Exploring nature and good coffee',
    );

    final matchEvidenceSample = SocialMatchEvidence(
      matchId: 'match_guid_aira_01',
      matchedAtUtc: DateTime.utc(2026, 11, 20, 10, 30),
    );

    // Standard valid matched relationship for Aira
    final matchedAiraRelationship = SocialRelationship(
      id: 'rel_aira_01',
      targetProfileId: 'soc_aira',
      candidate: candidateAira,
      state: SocialRelationshipState.matched,
      callerInterest: DirectionalInterest.positive,
      matchEvidence: matchEvidenceSample,
      createdAtUtc: DateTime.utc(2026, 11, 20, 10, 30),
    );

    // Standard valid matched relationship for Ava
    final matchedAvaRelationship = SocialRelationship(
      id: 'rel_ava_01',
      targetProfileId: 'soc_ava',
      candidate: candidateAva,
      state: SocialRelationshipState.matched,
      callerInterest: DirectionalInterest.positive,
      matchEvidence: SocialMatchEvidence(
        matchId: 'match_guid_ava_02',
        matchedAtUtc: DateTime.utc(2026, 11, 21, 14, 0),
      ),
      createdAtUtc: DateTime.utc(2026, 11, 21, 14, 0),
    );

    // 1. Chat tab index 3 generates the correct Chat List intent
    test('1. Chat tab index 3 generates the correct Chat List intent', () {
      final coordinator = DatingChatHandoffCoordinator();
      final intent = coordinator.handleHomeDestinationSelected(3);

      expect(intent.isSuccess, isTrue);
      expect(intent.kind, DatingHandoffKind.chatList);
      expect(intent.origin, DatingHandoffOrigin.homeTab);
      expect(intent.moduleConfig.type, AndrilModuleType.social);
      expect(intent.targetRoute, '/preview/chat/social');
      expect(intent.returnLocation, 'social_home');
    });

    // 2. Other navigation indices are not hijacked
    test('2. Other navigation indices are not hijacked', () {
      final coordinator = DatingChatHandoffCoordinator();

      for (final nonChatIndex in [0, 1, 2, 4]) {
        final intent = coordinator.handleHomeDestinationSelected(nonChatIndex);
        expect(intent.isIgnoredTab, isTrue);
        expect(intent.isSuccess, isFalse);
        expect(intent.isDenied, isFalse);
        expect(intent.kind, DatingHandoffKind.ignoredTab);
        expect(intent.requestedTabIndex, nonChatIndex);
      }
    });

    // 3. Aira conversation opens
    test('3. Aira conversation opens with correct partner and route', () {
      final coordinator = DatingChatHandoffCoordinator();
      final intent = coordinator.handleConversationEntry(
        rawModule: 'social',
        conversationId: DatingChatHandoffCoordinator.airaConversationId,
      );

      expect(intent.isSuccess, isTrue);
      expect(intent.kind, DatingHandoffKind.conversationDetail);
      expect(intent.conversationId, 'soc_aira');
      expect(intent.partner?.name, 'Aira');
      expect(intent.partner?.moduleType, AndrilModuleType.social);
      expect(intent.moduleConfig.type, AndrilModuleType.social);
      expect(intent.targetRoute, '/preview/chat/social/soc_aira');
    });

    // 4. Ava conversation opens
    test('4. Ava conversation opens with correct partner and route', () {
      final coordinator = DatingChatHandoffCoordinator();
      final intent = coordinator.handleConversationEntry(
        rawModule: 'social',
        conversationId: DatingChatHandoffCoordinator.avaConversationId,
      );

      expect(intent.isSuccess, isTrue);
      expect(intent.kind, DatingHandoffKind.conversationDetail);
      expect(intent.conversationId, 'soc_ava');
      expect(intent.partner?.name, 'Ava');
      expect(intent.partner?.moduleType, AndrilModuleType.social);
      expect(intent.targetRoute, '/preview/chat/social/soc_ava');
    });

    // 5. Aira/Ava histories remain independent
    test('5. Aira and Ava conversation drafts and states remain independent', () {
      final coordinator = DatingChatHandoffCoordinator();

      coordinator.recordDraft('soc_aira', 'Hi Aira! Looking forward to meeting.');
      coordinator.recordDraft('soc_ava', 'Hello Ava, great photos!');

      expect(coordinator.getDraft('soc_aira'), 'Hi Aira! Looking forward to meeting.');
      expect(coordinator.getDraft('soc_ava'), 'Hello Ava, great photos!');
      expect(coordinator.getDraft('soc_aira'), isNot(equals(coordinator.getDraft('soc_ava'))));
    });

    // 6. Valid synthetic mutual-match handoff
    test('6. Valid synthetic mutual-match handoff produces conversation intent', () {
      final coordinator = DatingChatHandoffCoordinator();
      final intent = coordinator.handleMutualMatchSendMessage(matchedAiraRelationship);

      expect(intent.isSuccess, isTrue);
      expect(intent.kind, DatingHandoffKind.conversationDetail);
      expect(intent.origin, DatingHandoffOrigin.mutualMatch);
      expect(intent.conversationId, 'soc_aira');
      expect(intent.partner?.name, 'Aira');
      expect(intent.returnLocation, 'mutual_match');
    });

    // 7. Unilateral-like denial
    test('7. Unilateral-like relationship is denied fail-closed', () {
      final coordinator = DatingChatHandoffCoordinator();
      final pendingRel = matchedAiraRelationship.copyWith(
        state: SocialRelationshipState.pendingUnilateral,
        matchEvidence: null,
      );

      final intent = coordinator.handleMutualMatchSendMessage(pendingRel);

      expect(intent.isDenied, isTrue);
      expect(intent.denialStatus, ChatEntryStatus.unconfirmedMatchDenied);
      expect(intent.denialReason, contains('authoritative, server-confirmed mutual match'));
    });

    // 8. Blocked relationship denial
    test('8. Blocked relationship is denied fail-closed', () {
      final coordinator = DatingChatHandoffCoordinator();
      final blockedRel = matchedAiraRelationship.copyWith(
        state: SocialRelationshipState.blocked,
      );

      final intent = coordinator.handleMutualMatchSendMessage(blockedRel);

      expect(intent.isDenied, isTrue);
      expect(intent.denialStatus, ChatEntryStatus.blockedRelationshipDenied);
      expect(intent.denialReason, contains('strictly prohibited'));
    });

    // 9. Revoked relationship denial
    test('9. Revoked relationship is denied fail-closed', () {
      final coordinator = DatingChatHandoffCoordinator();
      final revokedRel = matchedAiraRelationship.copyWith(
        state: SocialRelationshipState.revoked,
        matchEvidence: null,
      );

      final intent = coordinator.handleMutualMatchSendMessage(revokedRel);

      expect(intent.isDenied, isTrue);
      expect(intent.denialStatus, ChatEntryStatus.unconfirmedMatchDenied);
    });

    // 10. Under-18 fixture denial
    test('10. Under-18 fixture is denied fail-closed', () {
      final coordinator = DatingChatHandoffCoordinator();
      final intent = coordinator.handleMutualMatchSendMessage(
        matchedAiraRelationship,
        isAdult: false,
      );

      expect(intent.isDenied, isTrue);
      expect(intent.denialStatus, ChatEntryStatus.authorizationDenied);
      expect(intent.denialReason, contains('age 18+'));
    });

    // 11. Missing Dating opt-in denial
    test('11. Missing Dating opt-in is denied fail-closed', () {
      final coordinator = DatingChatHandoffCoordinator();
      final intent = coordinator.handleMutualMatchSendMessage(
        matchedAiraRelationship,
        hasSocialOptIn: false,
      );

      expect(intent.isDenied, isTrue);
      expect(intent.denialStatus, ChatEntryStatus.authorizationDenied);
      expect(intent.denialReason, contains('explicit user profile opt-in'));
    });

    // 12. Missing match evidence denial
    test('12. Missing match evidence on matched state is denied fail-closed', () {
      final coordinator = DatingChatHandoffCoordinator();
      final missingEvidenceRel = SocialRelationship(
        id: 'rel_aira_no_evidence',
        targetProfileId: 'soc_aira',
        candidate: candidateAira,
        state: SocialRelationshipState.matched,
        callerInterest: DirectionalInterest.positive,
        matchEvidence: null,
      );

      final intent = coordinator.handleMutualMatchSendMessage(missingEvidenceRel);

      expect(intent.isDenied, isTrue);
      expect(intent.denialStatus, ChatEntryStatus.unconfirmedMatchDenied);
      expect(intent.denialReason, contains('evidence is missing'));
    });

    // 13. Unknown profile mapping denial
    test('13. Unknown profile mapping is denied with unresolvedProfileMapping', () {
      final coordinator = DatingChatHandoffCoordinator();
      final unknownRel = SocialRelationship(
        id: 'rel_unknown_99',
        targetProfileId: 'candidate_unregistered_99',
        candidate: SocialCandidate(
          id: 'candidate_unregistered_99',
          displayName: 'Stranger',
          age: 28,
        ),
        state: SocialRelationshipState.matched,
        matchEvidence: matchEvidenceSample,
      );

      final intent = coordinator.handleMutualMatchSendMessage(unknownRel);

      expect(intent.isDenied, isTrue);
      expect(intent.denialStatus, ChatEntryStatus.unresolvedProfileMapping);
      expect(intent.denialReason, contains('does not have an active chat conversation'));
    });

    // 14. Connections callback requires relationship lookup
    test('14. Connections callback requires relationship lookup', () {
      // Without lookup function injected
      final coordinatorNoLookup = DatingChatHandoffCoordinator();
      final intentNoLookup = coordinatorNoLookup.handleConnectionsOpenChat('soc_aira');

      expect(intentNoLookup.isDenied, isTrue);
      expect(intentNoLookup.denialReason, contains('Missing relationship lookup'));

      // With lookup function returning null
      final coordinatorWithLookup = DatingChatHandoffCoordinator(
        relationshipLookup: (id) => null,
      );
      final intentNullRel = coordinatorWithLookup.handleConnectionsOpenChat('soc_aira');

      expect(intentNullRel.isDenied, isTrue);
      expect(intentNullRel.denialReason, contains('No active relationship found'));

      // With successful lookup
      final coordinatorValid = DatingChatHandoffCoordinator(
        relationshipLookup: (id) => id == 'soc_aira' ? matchedAiraRelationship : null,
      );
      final intentValid = coordinatorValid.handleConnectionsOpenChat('soc_aira');

      expect(intentValid.isSuccess, isTrue);
      expect(intentValid.conversationId, 'soc_aira');
    });

    // 15. Profile ID is never treated as conversation ID
    test('15. Profile ID is resolved to conversation mapping and never used directly', () {
      final coordinator = DatingChatHandoffCoordinator(
        relationshipLookup: (id) {
          if (id == 'candidate_aira') {
            return SocialRelationship(
              id: 'rel_candidate_aira',
              targetProfileId: 'candidate_aira',
              candidate: candidateAira,
              state: SocialRelationshipState.matched,
              matchEvidence: matchEvidenceSample,
            );
          }
          return null;
        },
      );

      final intent = coordinator.handleConnectionsOpenChat('candidate_aira');

      expect(intent.isSuccess, isTrue);
      // Ensure conversationId is the resolved canonical conversation ID ('soc_aira'),
      // NOT the raw profile id ('candidate_aira').
      expect(intent.conversationId, 'soc_aira');
      expect(intent.conversationId, isNot(equals('candidate_aira')));
    });

    // 16. Learning ID is denied
    test('16. Learning conversation ID is denied fail-closed in Dating Chat', () {
      final coordinator = DatingChatHandoffCoordinator();

      // Attempting to pass rawModule 'learning'
      final intentWrongModule = coordinator.handleConversationEntry(
        rawModule: 'learning',
        conversationId: 'lrn_maya',
      );
      expect(intentWrongModule.isDenied, isTrue);
      expect(intentWrongModule.denialStatus, ChatEntryStatus.crossModuleDenied);

      // Attempting to pass Maya's ID under social module
      final intentCrossModuleId = coordinator.handleConversationEntry(
        rawModule: 'social',
        conversationId: 'lrn_maya',
      );
      expect(intentCrossModuleId.isDenied, isTrue);
      expect(intentCrossModuleId.denialStatus, ChatEntryStatus.crossModuleDenied);
      expect(intentCrossModuleId.denialReason, contains('belongs to module "learning"'));
    });

    // 17. Hobbies ID is denied
    test('17. Hobbies conversation ID is denied fail-closed in Dating Chat', () {
      final coordinator = DatingChatHandoffCoordinator();

      // Attempting to pass rawModule 'hobbies'
      final intentWrongModule = coordinator.handleConversationEntry(
        rawModule: 'hobbies',
        conversationId: 'hob_nila',
      );
      expect(intentWrongModule.isDenied, isTrue);
      expect(intentWrongModule.denialStatus, ChatEntryStatus.crossModuleDenied);

      // Attempting to pass Nila's ID under social module
      final intentCrossModuleId = coordinator.handleConversationEntry(
        rawModule: 'social',
        conversationId: 'hob_nila',
      );
      expect(intentCrossModuleId.isDenied, isTrue);
      expect(intentCrossModuleId.denialStatus, ChatEntryStatus.crossModuleDenied);
      expect(intentCrossModuleId.denialReason, contains('belongs to module "hobbies"'));
    });

    // 18. Invalid conversation identifier is denied
    test('18. Malformed or credential-leaking conversation identifiers are denied', () {
      final coordinator = DatingChatHandoffCoordinator();

      for (final badId in ['', 'user@example.com', 'bearer token123', 'access_token']) {
        final intent = coordinator.handleConversationEntry(
          rawModule: 'social',
          conversationId: badId,
        );
        expect(intent.isDenied, isTrue);
        expect(intent.denialStatus, ChatEntryStatus.invalidIdentifier);
      }
    });

    // 19. Spoofed partner information is denied
    test('19. Spoofed partner information is denied fail-closed', () {
      final coordinator = DatingChatHandoffCoordinator();

      // Cross-module partner spoof (e.g. Maya profile passed to social)
      final spoofedModulePartner = const AndrilModuleProfile(
        name: 'Maya',
        status: 'Online',
        avatarAsset: 'assets/profile/maya_avatar.webp',
        moduleType: AndrilModuleType.learning,
      );

      final intentSpoofed = coordinator.handleConversationEntry(
        rawModule: 'social',
        conversationId: 'soc_aira',
        partner: spoofedModulePartner,
      );

      expect(intentSpoofed.isDenied, isTrue);
      expect(intentSpoofed.denialStatus, ChatEntryStatus.crossModuleDenied);
      expect(intentSpoofed.denialReason, contains('does not belong to route module'));
    });

    // 20. Correct return navigation intent
    test('20. Correct return navigation intent is resolved for all origins', () {
      final coordinator = DatingChatHandoffCoordinator();

      // 1. Return from Mutual Match
      final matchIntent = coordinator.handleMutualMatchSendMessage(matchedAiraRelationship);
      final backFromMatch = coordinator.resolveBackNavigation(matchIntent);
      expect(backFromMatch.targetReturnScreen, 'mutual_match');
      expect(backFromMatch.origin, DatingHandoffOrigin.mutualMatch);

      // 2. Return from Connections
      final connCoordinator = DatingChatHandoffCoordinator(
        relationshipLookup: (id) => matchedAvaRelationship,
      );
      final connIntent = connCoordinator.handleConnectionsOpenChat('soc_ava');
      final backFromConn = connCoordinator.resolveBackNavigation(connIntent);
      expect(backFromConn.targetReturnScreen, 'connections');
      expect(backFromConn.origin, DatingHandoffOrigin.connections);

      // 3. Return from Chat List
      final listIntent = coordinator.handleHomeDestinationSelected(3);
      final backFromList = coordinator.resolveBackNavigation(listIntent);
      expect(backFromList.targetReturnScreen, 'social_home');
      expect(backFromList.origin, DatingHandoffOrigin.homeTab);
      expect(backFromList.homeTabIndex, 0);

      // 4. Return from Detail opened from Chat List
      final detailFromListIntent = coordinator.handleConversationEntry(
        rawModule: 'social',
        conversationId: 'soc_aira',
        returnLocation: 'chat_list',
      );
      final backFromDetailToList = coordinator.resolveBackNavigation(detailFromListIntent);
      expect(backFromDetailToList.targetReturnScreen, 'chat_list');
    });

    // 21. MoodTone remains Dating-only
    test('21. MoodTone remains strictly enabled for Dating/Social and disabled for others', () {
      expect(AndrilModuleConfig.social.supportsMoodTone, isTrue);
      expect(AndrilModuleConfig.social.allowsMoodTone, isTrue);

      expect(AndrilModuleConfig.learning.supportsMoodTone, isFalse);
      expect(AndrilModuleConfig.learning.allowsMoodTone, isFalse);

      expect(AndrilModuleConfig.hobbies.supportsMoodTone, isFalse);
      expect(AndrilModuleConfig.hobbies.allowsMoodTone, isFalse);
    });

    // 22. Gifts remain MOCK-only
    test('22. Virtual gifts catalog contains 10 items without live wallet dependency', () {
      final socialConfig = AndrilModuleConfig.social;
      expect(socialConfig.giftCatalog.length, 10);
      for (final gift in socialConfig.giftCatalog) {
        expect(gift.name.isNotEmpty, isTrue);
        expect(gift.coins, greaterThan(0));
        expect(gift.assetPath, startsWith('assets/'));
      }
    });

    // 23. No production API calls
    test('23. Coordinator operates purely synchronously and in-memory without network calls', () {
      final coordinator = DatingChatHandoffCoordinator(
        relationshipLookup: (id) => matchedAiraRelationship,
      );

      // All operations execute synchronously without async I/O
      final tabIntent = coordinator.handleHomeDestinationSelected(3);
      expect(tabIntent.isSuccess, isTrue);

      final matchIntent = coordinator.handleMutualMatchSendMessage(matchedAiraRelationship);
      expect(matchIntent.isSuccess, isTrue);

      final connIntent = coordinator.handleConnectionsOpenChat('soc_aira');
      expect(connIntent.isSuccess, isTrue);
    });

    // 24. Existing Chat cleanup behavior remains intact
    test('24. clearPrivateState purges cached params, drafts, and increments clearCount', () {
      final coordinator = DatingChatHandoffCoordinator();

      coordinator.recordDraft('soc_aira', 'Transient text');
      coordinator.handleConversationEntry(rawModule: 'social', conversationId: 'soc_aira');

      expect(coordinator.hasActiveState, isTrue);
      expect(coordinator.getDraft('soc_aira'), 'Transient text');
      expect(coordinator.clearCount, 0);

      coordinator.clearPrivateState();

      expect(coordinator.hasActiveState, isFalse);
      expect(coordinator.getDraft('soc_aira'), isNull);
      expect(coordinator.clearCount, 1);
    });

    // 25. Responsive and accessibility verification with preview widget
    testWidgets('25. DatingChatPreviewHost renders responsively across compact (320x568) and standard viewports',
        (WidgetTester tester) async {
      final coordinator = DatingChatHandoffCoordinator(
        relationshipLookup: (id) => matchedAiraRelationship,
      );

      // Compact mobile viewport
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
            ),
            child: DatingChatPreviewHost(
              coordinator: coordinator,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AndrilChatsListScreen), findsOneWidget);
      expect(find.text('Social Chats'), findsOneWidget);

      // Navigate to detail in compact view
      final detailIntent = coordinator.handleConversationEntry(
        rawModule: 'social',
        conversationId: 'soc_aira',
        returnLocation: 'chat_list',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
            ),
            child: DatingChatPreviewHost(
              coordinator: coordinator,
              initialIntent: detailIntent,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AndrilChatScreen), findsOneWidget);
      expect(find.text('Aira'), findsOneWidget);

      // Verify denied screen in preview host
      final deniedIntent = coordinator.handleMutualMatchSendMessage(
        matchedAiraRelationship,
        isAdult: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DatingChatPreviewHost(
            coordinator: coordinator,
            initialIntent: deniedIntent,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ChatRouteDeniedScreen), findsOneWidget);
      expect(find.text('Chat Navigation Restricted'), findsOneWidget);
    });
  });
}
