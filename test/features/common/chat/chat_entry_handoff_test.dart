import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/common/chat/domain/module_config.dart';
import 'package:andril_mobile/features/common/chat/presentation/navigation/chat_entry_handoff.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/social_relationship.dart';

void main() {
  group('M4 Chat Entry Handoff Adapter — List Entry Navigation', () {
    late ChatEntryHandoffAdapter adapter;

    setUp(() {
      adapter = ChatEntryHandoffAdapter();
    });

    test('1. Learning Chat tab handoff routes to /preview/chat/learning', () {
      final request = ChatListEntryRequest.forModule(AndrilModuleType.learning);
      final result = adapter.handleListEntry(request);

      expect(result.isSuccess, isTrue);
      expect(result.status, ChatEntryStatus.validList);
      expect(result.targetRoute, '/preview/chat/learning');
      expect(result.params?.moduleType, AndrilModuleType.learning);
      expect(result.denialReason, isNull);
    });

    test('2. Hobbies Chat tab handoff routes to /preview/chat/hobbies', () {
      final request = ChatListEntryRequest.forModule(AndrilModuleType.hobbies);
      final result = adapter.handleListEntry(request);

      expect(result.isSuccess, isTrue);
      expect(result.status, ChatEntryStatus.validList);
      expect(result.targetRoute, '/preview/chat/hobbies');
      expect(result.params?.moduleType, AndrilModuleType.hobbies);
      expect(result.denialReason, isNull);
    });

    test('3. Dating/Social Chat tab handoff routes to /preview/chat/social', () {
      // Direct module enum
      final requestEnum = ChatListEntryRequest.forModule(AndrilModuleType.social);
      final resultEnum = adapter.handleListEntry(requestEnum);

      expect(resultEnum.isSuccess, isTrue);
      expect(resultEnum.status, ChatEntryStatus.validList);
      expect(resultEnum.targetRoute, '/preview/chat/social');
      expect(resultEnum.params?.moduleType, AndrilModuleType.social);

      // Raw string 'dating' maps to social
      final requestDating = const ChatListEntryRequest(rawModule: 'dating');
      final resultDating = adapter.handleListEntry(requestDating);

      expect(resultDating.isSuccess, isTrue);
      expect(resultDating.status, ChatEntryStatus.validList);
      expect(resultDating.targetRoute, '/preview/chat/social');
      expect(resultDating.params?.moduleType, AndrilModuleType.social);
    });

    test('4. Rejects unsupported module name for list handoff', () {
      final request = const ChatListEntryRequest(rawModule: 'gaming');
      final result = adapter.handleListEntry(request);

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.unsupportedModule);
      expect(result.denialReason, contains('Unsupported module: "gaming"'));
      expect(result.targetRoute, contains('/preview/chat/denied'));
    });

    test('5. Rejects unauthorized list handoff request (fail-closed)', () {
      final request = ChatListEntryRequest.forModule(
        AndrilModuleType.learning,
        isAuthorized: false,
      );
      final result = adapter.handleListEntry(request);

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.authorizationDenied);
      expect(result.denialReason, contains('not authorized'));
      expect(result.targetRoute, contains('/preview/chat/denied'));
    });
  });

  group('M4 Chat Entry Handoff Adapter — Direct Conversation Handoff', () {
    late ChatEntryHandoffAdapter adapter;

    setUp(() {
      adapter = ChatEntryHandoffAdapter();
    });

    test('6. Valid conversation handoff in Learning routes to Maya', () {
      final request = ConversationEntryRequest.forModule(
        moduleType: AndrilModuleType.learning,
        conversationId: 'lrn_maya',
      );
      final result = adapter.handleConversationEntry(request);

      expect(result.isSuccess, isTrue);
      expect(result.status, ChatEntryStatus.validConversation);
      expect(result.targetRoute, '/preview/chat/learning/lrn_maya');
      expect(result.partner?.name, 'Maya');
      expect(result.partner?.moduleType, AndrilModuleType.learning);
      expect(adapter.hasActiveState, isTrue);
      expect(adapter.lastResolvedParams?.conversationId, 'lrn_maya');
    });

    test('7. Valid conversation handoff in Hobbies routes to Nila', () {
      final request = ConversationEntryRequest.forModule(
        moduleType: AndrilModuleType.hobbies,
        conversationId: 'hob_nila',
      );
      final result = adapter.handleConversationEntry(request);

      expect(result.isSuccess, isTrue);
      expect(result.status, ChatEntryStatus.validConversation);
      expect(result.targetRoute, '/preview/chat/hobbies/hob_nila');
      expect(result.partner?.name, 'Nila');
      expect(result.partner?.moduleType, AndrilModuleType.hobbies);
    });

    test('8. Valid conversation handoff in Social routes to Aira', () {
      final request = ConversationEntryRequest.forModule(
        moduleType: AndrilModuleType.social,
        conversationId: 'soc_aira',
      );
      final result = adapter.handleConversationEntry(request);

      expect(result.isSuccess, isTrue);
      expect(result.status, ChatEntryStatus.validConversation);
      expect(result.targetRoute, '/preview/chat/social/soc_aira');
      expect(result.partner?.name, 'Aira');
      expect(result.partner?.moduleType, AndrilModuleType.social);
    });

    test('9. Rejects cross-module request: Learning requesting Social conversation (soc_aira)', () {
      final request = const ConversationEntryRequest(
        rawModule: 'learning',
        conversationId: 'soc_aira',
      );
      final result = adapter.handleConversationEntry(request);

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.crossModuleDenied);
      expect(result.denialReason, contains('belongs to module "social", not "learning"'));
    });

    test('10. Rejects cross-module request: Social requesting Hobbies conversation (hob_nila)', () {
      final request = const ConversationEntryRequest(
        rawModule: 'social',
        conversationId: 'hob_nila',
      );
      final result = adapter.handleConversationEntry(request);

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.crossModuleDenied);
      expect(result.denialReason, contains('belongs to module "hobbies", not "social"'));
    });

    test('11. Rejects malformed conversation IDs (email, token, bearer, oversize)', () {
      // Email forbidden
      final emailResult = adapter.handleConversationEntry(const ConversationEntryRequest(
        rawModule: 'learning',
        conversationId: 'student@andril.com',
      ));
      expect(emailResult.isSuccess, isFalse);
      expect(emailResult.status, ChatEntryStatus.invalidIdentifier);

      // Bearer token forbidden
      final tokenResult = adapter.handleConversationEntry(const ConversationEntryRequest(
        rawModule: 'learning',
        conversationId: 'bearer secret_jwt_token_123',
      ));
      expect(tokenResult.isSuccess, isFalse);
      expect(tokenResult.status, ChatEntryStatus.invalidIdentifier);

      // Empty identifier forbidden
      final emptyResult = adapter.handleConversationEntry(const ConversationEntryRequest(
        rawModule: 'learning',
        conversationId: '   ',
      ));
      expect(emptyResult.isSuccess, isFalse);
      expect(emptyResult.status, ChatEntryStatus.invalidIdentifier);

      // Oversized string forbidden
      final oversizeResult = adapter.handleConversationEntry(ConversationEntryRequest(
        rawModule: 'learning',
        conversationId: 'A' * 130,
      ));
      expect(oversizeResult.isSuccess, isFalse);
      expect(oversizeResult.status, ChatEntryStatus.invalidIdentifier);
    });

    test('12. Rejects unknown conversation ID not in module catalog', () {
      final result = adapter.handleConversationEntry(const ConversationEntryRequest(
        rawModule: 'learning',
        conversationId: 'random_unknown_chat_id',
      ));

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.conversationNotFound);
      expect(result.denialReason, contains('is not available in module "learning"'));
    });

    test('13. Rejects unauthorized conversation entry request (fail-closed)', () {
      final result = adapter.handleConversationEntry(const ConversationEntryRequest(
        rawModule: 'learning',
        conversationId: 'lrn_maya',
        isAuthorized: false,
      ));

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.authorizationDenied);
      expect(result.denialReason, contains('not authorized'));
    });
  });

  group('M4 Chat Entry Handoff Adapter — Social Profile Handoff & Mutual Match', () {
    late ChatEntryHandoffAdapter adapter;
    late SocialCandidate candidateAira;
    late SocialCandidate candidateAva;
    late SocialMatchEvidence matchEvidence;

    setUp(() {
      adapter = ChatEntryHandoffAdapter();

      candidateAira = SocialCandidate(
        id: 'candidate_aira',
        displayName: 'Aira',
        age: 23,
        approximateDistanceKm: 5,
        isVerified: true,
      );

      candidateAva = SocialCandidate(
        id: 'candidate_ava',
        displayName: 'Ava',
        age: 25,
        approximateDistanceKm: 8,
        isVerified: true,
      );

      matchEvidence = SocialMatchEvidence(
        matchId: 'match-guid-001',
        matchedAtUtc: DateTime.utc(2026, 11, 26, 10, 0),
      );
    });

    test('14. Resolves confirmed mutual match for candidate Aira to /preview/chat/social/soc_aira', () {
      final request = const SocialProfileHandoffRequest(
        targetProfileId: 'soc_aira',
        relationshipState: SocialRelationshipState.matched,
        hasActiveMatchEvidence: true,
      );

      final result = adapter.handleProfileHandoff(request);

      expect(result.isSuccess, isTrue);
      expect(result.status, ChatEntryStatus.validConversation);
      expect(result.targetRoute, '/preview/chat/social/soc_aira');
      expect(result.partner?.name, 'Aira');
      expect(result.partner?.moduleType, AndrilModuleType.social);
    });

    test('15. Resolves confirmed mutual match for candidate Ava with independent identity', () {
      final request = const SocialProfileHandoffRequest(
        targetProfileId: 'soc_ava',
        relationshipState: SocialRelationshipState.matched,
        hasActiveMatchEvidence: true,
      );

      final result = adapter.handleProfileHandoff(request);

      expect(result.isSuccess, isTrue);
      expect(result.status, ChatEntryStatus.validConversation);
      expect(result.targetRoute, '/preview/chat/social/soc_ava');
      expect(result.partner?.name, 'Ava');
      expect(result.partner?.moduleType, AndrilModuleType.social);
    });

    test('16. Rejects unconfirmed match (pendingUnilateral) with unconfirmedMatchDenied', () {
      final request = const SocialProfileHandoffRequest(
        targetProfileId: 'soc_aira',
        relationshipState: SocialRelationshipState.pendingUnilateral,
        hasActiveMatchEvidence: false,
      );

      final result = adapter.handleProfileHandoff(request);

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.unconfirmedMatchDenied);
      expect(result.denialReason, contains('requires an authoritative, server-confirmed mutual match'));
    });

    test('17. Rejects matched state lacking server evidence with unconfirmedMatchDenied', () {
      final request = const SocialProfileHandoffRequest(
        targetProfileId: 'soc_aira',
        relationshipState: SocialRelationshipState.matched,
        hasActiveMatchEvidence: false, // Invariant violation: matched without evidence
      );

      final result = adapter.handleProfileHandoff(request);

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.unconfirmedMatchDenied);
      expect(result.denialReason, contains('evidence is missing or unverified'));
    });

    test('18. Rejects blocked relationship with blockedRelationshipDenied and prohibits communication', () {
      final request = const SocialProfileHandoffRequest(
        targetProfileId: 'soc_aira',
        relationshipState: SocialRelationshipState.blocked,
        hasActiveMatchEvidence: false,
      );

      final result = adapter.handleProfileHandoff(request);

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.blockedRelationshipDenied);
      expect(result.denialReason, contains('blocked profile "soc_aira" is strictly prohibited'));
    });

    test('19. Rejects unmapped candidate profile ID with unresolvedProfileMapping', () {
      final request = const SocialProfileHandoffRequest(
        targetProfileId: 'uuid-candidate-999-unmapped',
        relationshipState: SocialRelationshipState.matched,
        hasActiveMatchEvidence: true,
      );

      final result = adapter.handleProfileHandoff(request);

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.unresolvedProfileMapping);
      expect(result.denialReason, contains('Server conversation resolution required'));
    });

    test('20. Rejects cross-module persona profile ID in Social with crossModuleDenied', () {
      final request = const SocialProfileHandoffRequest(
        targetProfileId: 'lrn_maya',
        relationshipState: SocialRelationshipState.matched,
        hasActiveMatchEvidence: true,
      );

      final result = adapter.handleProfileHandoff(request);

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.crossModuleDenied);
      expect(result.denialReason, contains('belongs to Learning module and cannot be accessed in Dating/Social'));
    });

    test('21. Rejects non-adult candidate (isAdult == false) with authorizationDenied', () {
      final request = const SocialProfileHandoffRequest(
        targetProfileId: 'soc_aira',
        relationshipState: SocialRelationshipState.matched,
        hasActiveMatchEvidence: true,
        isAdult: false,
      );

      final result = adapter.handleProfileHandoff(request);

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.authorizationDenied);
      expect(result.denialReason, contains('adult eligibility (age 18+)'));
    });

    test('22. Rejects user without social opt-in (hasSocialOptIn == false) with authorizationDenied', () {
      final request = const SocialProfileHandoffRequest(
        targetProfileId: 'soc_aira',
        relationshipState: SocialRelationshipState.matched,
        hasActiveMatchEvidence: true,
        hasSocialOptIn: false,
      );

      final result = adapter.handleProfileHandoff(request);

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.authorizationDenied);
      expect(result.denialReason, contains('requires an explicit user profile opt-in'));
    });

    test('23. Rejects unauthorized profile handoff request (isAuthorized == false)', () {
      final request = const SocialProfileHandoffRequest(
        targetProfileId: 'soc_aira',
        relationshipState: SocialRelationshipState.matched,
        hasActiveMatchEvidence: true,
        isAuthorized: false,
      );

      final result = adapter.handleProfileHandoff(request);

      expect(result.isSuccess, isFalse);
      expect(result.status, ChatEntryStatus.authorizationDenied);
      expect(result.denialReason, contains('not authorized'));
    });

    test('24. SocialProfileHandoffRequest.fromRelationship factory integrates with M5 SocialRelationship domain model', () {
      // 1. Confirmed connection with active match evidence
      final relationshipAira = SocialRelationship(
        id: 'rel-aira-01',
        targetProfileId: 'candidate_aira',
        candidate: candidateAira,
        state: SocialRelationshipState.matched,
        callerInterest: DirectionalInterest.positive,
        matchEvidence: matchEvidence,
      );

      final requestFromRel = SocialProfileHandoffRequest.fromRelationship(relationshipAira);
      expect(requestFromRel.targetProfileId, 'candidate_aira');
      expect(requestFromRel.relationshipState, SocialRelationshipState.matched);
      expect(requestFromRel.hasActiveMatchEvidence, isTrue);

      final result = adapter.handleProfileHandoff(requestFromRel);
      expect(result.isSuccess, isTrue);
      expect(result.status, ChatEntryStatus.validConversation);
      expect(result.targetRoute, '/preview/chat/social/soc_aira');
      expect(result.partner?.name, 'Aira');

      // 2. Unconfirmed unilateral connection from M5
      final relationshipUnilateral = SocialRelationship(
        id: 'rel-unilateral-02',
        targetProfileId: 'candidate_ava',
        candidate: candidateAva,
        state: SocialRelationshipState.pendingUnilateral,
        callerInterest: DirectionalInterest.positive,
        matchEvidence: null,
      );

      final unconfirmedRequest = SocialProfileHandoffRequest.fromRelationship(relationshipUnilateral);
      final unconfirmedResult = adapter.handleProfileHandoff(unconfirmedRequest);
      expect(unconfirmedResult.isSuccess, isFalse);
      expect(unconfirmedResult.status, ChatEntryStatus.unconfirmedMatchDenied);
    });
  });

  group('M4 Chat Entry Handoff Adapter — Session Cleanup Contract', () {
    late ChatEntryHandoffAdapter adapter;

    setUp(() {
      adapter = ChatEntryHandoffAdapter();
    });

    test('25. clearPrivateChatState purges transient drafts, resolved parameters, and partner state', () {
      // Set up active state via conversation handoff
      final result = adapter.handleConversationEntry(ConversationEntryRequest.forModule(
        moduleType: AndrilModuleType.social,
        conversationId: 'soc_aira',
      ));
      expect(result.isSuccess, isTrue);

      // Record a transient draft
      adapter.recordDraft('soc_aira', 'Hey Aira! Nice to connect with you.');
      expect(adapter.getDraft('soc_aira'), 'Hey Aira! Nice to connect with you.');
      expect(adapter.hasActiveState, isTrue);
      expect(adapter.lastResolvedParams, isNotNull);
      expect(adapter.lastResolvedPartner, isNotNull);
      expect(adapter.clearCount, 0);

      // Trigger session clearance (simulating SessionController.registerPrivateStateClearer)
      adapter.clearPrivateChatState();

      expect(adapter.hasActiveState, isFalse);
      expect(adapter.lastResolvedParams, isNull);
      expect(adapter.lastResolvedPartner, isNull);
      expect(adapter.getDraft('soc_aira'), isNull);
      expect(adapter.clearCount, 1);
    });
  });
}
