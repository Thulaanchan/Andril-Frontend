import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/discovery/data/social_discovery_repository.dart';
import 'package:andril_mobile/features/social/discovery/domain/social_candidate.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_discovery_filters_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_discovery_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_discovery_viewmodel.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_member_photo_gallery_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_member_profile_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_photo_viewer_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_saved_profiles_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_search_screen.dart';
import 'package:andril_mobile/features/social/discovery/presentation/social_search_viewmodel.dart';
import 'package:andril_mobile/features/social/interests_preferences/presentation/social_discovery_languages_screen.dart';
import 'package:andril_mobile/features/social/interests_preferences/presentation/social_preferences_screen.dart';
import 'package:andril_mobile/features/social/likes_matches/data/social_relationship_repository.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/social_relationship.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_connections_screen.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_match_history_screen.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_mutual_match_screen.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_received_likes_screen.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_relationship_viewmodel.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_sent_likes_screen.dart';
import 'package:andril_mobile/features/social/likes_matches/presentation/social_unmatched_screen.dart';
import 'package:andril_mobile/features/social/personality/data/repositories/personality_questionnaire_repository.dart';
import 'package:andril_mobile/features/social/personality/domain/entities/personality_questionnaire.dart';
import 'package:andril_mobile/features/social/personality/presentation/screens/personality_answers_screen.dart';
import 'package:andril_mobile/features/social/personality/presentation/screens/personality_intro_screen.dart';
import 'package:andril_mobile/features/social/personality/presentation/screens/personality_questionnaire_screen.dart';
import 'package:andril_mobile/features/social/personality/presentation/screens/personality_review_screen.dart';
import 'package:andril_mobile/features/social/personality/presentation/viewmodels/personality_questionnaire_viewmodel.dart';
import 'package:andril_mobile/features/social/profile/screens/create_social_profile_screen.dart';
import 'package:andril_mobile/features/social/profile/screens/social_edit_profile_screen.dart';
import 'package:andril_mobile/features/social/profile/screens/social_my_profile_screen.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_draft.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_management_repository.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_management_viewmodel.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_repository.dart';
import 'package:andril_mobile/features/social/profile/viewmodels/social_profile_viewmodel.dart';
import 'package:andril_mobile/features/social/smart_matching/presentation/social_smart_matching_screen.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone_repository.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_create_zone_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_my_zones_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_details_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_discovery_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_management_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_management_viewmodel.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_membership_confirmation.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_members_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zone_moderation_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zones_screen.dart';
import 'package:andril_mobile/features/social/zones/presentation/social_zones_viewmodel.dart';

class _FakeCoverageSession extends ChangeNotifier implements SessionController {
  @override
  SessionPhase get phase => SessionPhase.signedIn;

  @override
  String? get subject => 'u-coverage-1';

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) => () {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCoverageQuestionnaireRepo implements IPersonalityQuestionnaireRepository {
  @override
  Future<QuestionnaireResult<PersonalityQuestionnaire>> getActiveQuestionnaire() async {
    return QuestionnaireResult.success(PersonalityQuestionnaire(
      version: 'v1.0',
      questions: [
        PersonalityQuestion(
          id: 'q01',
          prompt: 'What is your ideal weekend activity?',
          isRequired: true,
          options: [
            PersonalityOption(id: '1', label: 'Hiking in nature'),
            PersonalityOption(id: '2', label: 'Coffee and books'),
          ],
        ),
      ],
    ));
  }
}

class _FakeProfileMgmtRepo implements ISocialProfileManagementRepository {
  @override
  Future<SocialProfileResult> getProfile() async =>
      const SocialProfileResult.success(SocialProfileDraft(displayName: 'Test User'));
  @override
  Future<SocialProfileResult> updateProfile(SocialProfileDraft draft) async =>
      SocialProfileResult.success(draft);
}

class _FakeInnerProfileRepo implements SocialProfileRepository {
  @override
  Future<SocialProfileResult> createProfileDraft() async =>
      const SocialProfileResult.success(SocialProfileDraft());
  @override
  Future<SocialProfileResult> getProfileDraft() async =>
      const SocialProfileResult.success(SocialProfileDraft());
  @override
  Future<SocialProfileResult> saveProfileDraft(SocialProfileDraft draft) async =>
      SocialProfileResult.success(draft);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeCoverageSession session;
  final evidence = SocialAccessEvidence.authorized(userId: 'u-coverage-1');

  final candidate = SocialCandidate(
    id: 'cand-1',
    displayName: 'Ananya',
    age: 24,
    approximateDistanceKm: 5,
    sharedLanguages: const ['English', 'Tamil'],
  );

  const zone = SocialZone(
    id: 'z-1',
    name: 'Photography',
    description: 'Explore the visual world',
    memberCount: 42,
  );

  setUp(() {
    session = _FakeCoverageSession();
  });

  tearDown(() {
    session.dispose();
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('M5 Discovery Screen Coverage (S09, S11, S12, S13, S15, S22, S26, S29, S70, S71, S72, S73)', () {
    testWidgets('renders S22 SocialDiscoveryScreen', (tester) async {
      final vm = SocialDiscoveryViewModel(
        repository: const SocialDiscoveryRepository(isBackendActivated: false),
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialDiscoveryScreen(viewModel: vm)));
      expect(find.byType(SocialDiscoveryScreen), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S26 SocialMemberProfileScreen', (tester) async {
      await tester.pumpWidget(host(SocialMemberProfileScreen(candidate: candidate)));
      expect(find.text('Ananya, 24'), findsOneWidget);
    });

    testWidgets('renders S72 SocialMemberPhotoGalleryScreen', (tester) async {
      await tester.pumpWidget(host(const SocialMemberPhotoGalleryScreen(
        memberName: 'Ananya',
        memberId: 'cand-1',
        photoUrls: ['https://example.com/1.jpg'],
      )));
      expect(find.text("Ananya's Photos"), findsOneWidget);
    });

    testWidgets('renders S73 SocialPhotoViewerScreen', (tester) async {
      await tester.pumpWidget(host(const SocialPhotoViewerScreen(
        memberName: 'Ananya',
        photoUrls: ['https://example.com/1.jpg'],
      )));
      expect(find.text('Ananya'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('renders S70 SocialSavedProfilesScreen', (tester) async {
      await tester.pumpWidget(host(SocialSavedProfilesScreen(savedProfiles: [candidate])));
      expect(find.text('Saved Profiles'), findsOneWidget);
      expect(find.text('Ananya, 24'), findsOneWidget);
    });

    testWidgets('renders S29 SocialDiscoveryFiltersScreen', (tester) async {
      await tester.pumpWidget(host(const SocialDiscoveryFiltersScreen()));
      expect(find.text('Discovery Filters'), findsOneWidget);
    });

    testWidgets('renders S71 SocialSearchScreen', (tester) async {
      final vm = SocialSearchViewModel(
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialSearchScreen(viewModel: vm)));
      expect(find.byType(SocialSearchScreen), findsOneWidget);
      vm.dispose();
    });
  });

  group('M5 Likes & Relationships Screen Coverage (S23, S27, S43, S67, S68, S69, S79)', () {
    testWidgets('renders S23 SocialConnectionsScreen', (tester) async {
      final vm = SocialRelationshipViewModel(
        repository: const SocialRelationshipRepository(isBackendActivated: false),
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialConnectionsScreen(viewModel: vm)));
      expect(find.text('My Connections'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S67/S43 SocialReceivedLikesScreen', (tester) async {
      final vm = SocialRelationshipViewModel(
        repository: const SocialRelationshipRepository(isBackendActivated: false),
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialReceivedLikesScreen(viewModel: vm)));
      expect(find.byType(SocialReceivedLikesScreen), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S79 SocialSentLikesScreen', (tester) async {
      final vm = SocialRelationshipViewModel(
        repository: const SocialRelationshipRepository(isBackendActivated: false),
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialSentLikesScreen(viewModel: vm)));
      expect(find.byType(SocialSentLikesScreen), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S27 SocialMutualMatchScreen', (tester) async {
      final rel = SocialRelationship(
        id: 'rel-1',
        targetProfileId: 'cand-1',
        candidate: candidate,
        state: SocialRelationshipState.matched,
        callerInterest: DirectionalInterest.positive,
        matchEvidence: SocialMatchEvidence(
          matchId: 'm-1',
          matchedAtUtc: DateTime(2026, 11, 25),
        ),
      );
      await tester.pumpWidget(host(SocialMutualMatchScreen(relationship: rel)));
      expect(find.text("It's a Match!"), findsOneWidget);
    });

    testWidgets('renders S68 SocialMatchHistoryScreen', (tester) async {
      final records = [
        SocialMatchHistoryRecord(
          id: 'm-1',
          displayName: 'Ananya',
          matchedAt: DateTime(2026, 11, 25),
          status: SocialRelationshipState.matched,
        ),
      ];
      await tester.pumpWidget(host(SocialMatchHistoryScreen(historyRecords: records)));
      expect(find.text('Match History'), findsOneWidget);
      expect(find.text('Ananya'), findsOneWidget);
    });

    testWidgets('renders S69 SocialUnmatchedScreen', (tester) async {
      await tester.pumpWidget(host(const SocialUnmatchedScreen(targetName: 'Ananya')));
      expect(find.text('Connection Removed'), findsOneWidget);
      expect(find.textContaining('Ananya'), findsOneWidget);
    });
  });

  group('M5 Preferences & Languages Screen Coverage (S80, S81)', () {
    testWidgets('renders S80 SocialPreferencesScreen', (tester) async {
      await tester.pumpWidget(host(const SocialPreferencesScreen()));
      expect(find.text('Interests & Preferences'), findsOneWidget);
    });

    testWidgets('renders S81 SocialDiscoveryLanguagesScreen', (tester) async {
      await tester.pumpWidget(host(const SocialDiscoveryLanguagesScreen()));
      expect(find.text('Edit Discovery Languages'), findsOneWidget);
    });
  });

  group('M5 Zones & Moderation Screen Coverage (S24, S38, S44, S60, S61, S62, S63, S64, S65, S66)', () {
    testWidgets('renders S38 SocialZonesScreen', (tester) async {
      final repo = SocialZoneRepository(sessionController: session, isDormant: true);
      final vm = SocialZonesViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialZonesScreen(viewModel: vm)));
      expect(find.text('Social Zones'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S60 SocialZoneDiscoveryScreen', (tester) async {
      final repo = SocialZoneRepository(sessionController: session, isDormant: true);
      final vm = SocialZonesViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialZoneDiscoveryScreen(viewModel: vm)));
      expect(find.text('Discover Zones'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S61 SocialZoneDetailsScreen', (tester) async {
      final repo = SocialZoneRepository(sessionController: session, isDormant: true);
      final vm = SocialZonesViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialZoneDetailsScreen(zone: zone, viewModel: vm)));
      expect(find.byType(SocialZoneDetailsScreen), findsOneWidget);
      expect(find.text('Photography'), findsWidgets);
      vm.dispose();
    });

    testWidgets('renders S62 SocialZoneMembersScreen', (tester) async {
      final vm = SocialZoneManagementViewModel(
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialZoneMembersScreen(zone: zone, viewModel: vm)));
      expect(find.text('Photography Members'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S44 SocialZoneManagementScreen', (tester) async {
      final vm = SocialZoneManagementViewModel(
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialZoneManagementScreen(zone: zone, viewModel: vm)));
      expect(find.text('Zone Management'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S65 SocialZoneModerationScreen', (tester) async {
      final vm = SocialZoneManagementViewModel(
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialZoneModerationScreen(zone: zone, viewModel: vm)));
      expect(find.text('Zone Moderation'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S63 SocialCreateZoneScreen', (tester) async {
      final vm = SocialZoneManagementViewModel(
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialCreateZoneScreen(viewModel: vm)));
      expect(find.text('Create New Zone'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S64 SocialMyZonesScreen', (tester) async {
      final repo = SocialZoneRepository(sessionController: session, isDormant: true);
      final vm = SocialZonesViewModel(
        repository: repo,
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialMyZonesScreen(viewModel: vm)));
      expect(find.text('My Zones'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('presents S24/S66 confirmation dialogs cleanly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: ctx,
                builder: (_) => SocialZoneMembershipConfirmationDialog(
                  zone: zone,
                  action: ZoneMembershipAction.join,
                  onConfirm: () async {},
                  onCancel: () {},
                ),
              ),
              child: const Text('Open Join'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Join'));
      await tester.pumpAndSettle();

      expect(find.byType(SocialZoneMembershipConfirmationDialog), findsOneWidget);
      expect(find.text('Would you like to join "Photography"?'), findsOneWidget);
    });
  });

  group('M5 Personality & Smart Matching Screen Coverage (S25, S28, S37, S77, S82)', () {
    testWidgets('renders S25 PersonalityIntroScreen', (tester) async {
      await tester.pumpWidget(host(PersonalityIntroScreen(onStart: () {}, onSkip: () {})));
      expect(find.text('Personality Assessment'), findsOneWidget);
      expect(find.text('Discover Your Vibe'), findsOneWidget);
    });

    testWidgets('renders S77 PersonalityQuestionnaireScreen', (tester) async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: _FakeCoverageQuestionnaireRepo(),
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(PersonalityQuestionnaireScreen(viewModel: vm)));
      expect(find.byType(PersonalityQuestionnaireScreen), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S82 PersonalityReviewScreen', (tester) async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: _FakeCoverageQuestionnaireRepo(),
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(PersonalityReviewScreen(viewModel: vm)));
      expect(find.text('Review Answers'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S37 PersonalityAnswersScreen', (tester) async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: _FakeCoverageQuestionnaireRepo(),
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(PersonalityAnswersScreen(viewModel: vm)));
      expect(find.text('Personality Answers'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S28 SocialSmartMatchingScreen', (tester) async {
      await tester.pumpWidget(host(const SocialSmartMatchingScreen(
        state: SmartMatchingState.ready,
        matchExplanation: ServerMatchExplanation(
          matchedCandidateName: 'Ananya',
          commonInterests: ['Photography'],
        ),
      )));
      expect(find.text('Why We Matched'), findsOneWidget);
      expect(find.text('Compatibility Highlights'), findsOneWidget);
      expect(find.text('Shared preferences between you and Ananya'), findsOneWidget);
    });
  });

  group('M5 Profile Management Screen Coverage (S30, S76, S78)', () {
    testWidgets('renders S30 SocialMyProfileScreen', (tester) async {
      final vm = SocialProfileManagementViewModel(
        repository: _FakeProfileMgmtRepo(),
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialMyProfileScreen(viewModel: vm)));
      expect(find.text('My Profile'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S76 SocialEditProfileScreen', (tester) async {
      final vm = SocialProfileManagementViewModel(
        repository: _FakeProfileMgmtRepo(),
        sessionController: session,
        accessEvidence: evidence,
        isSocialOptedIn: true,
      );
      await tester.pumpWidget(host(SocialEditProfileScreen(viewModel: vm)));
      expect(find.text('Edit Profile'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('renders S78 CreateSocialProfileScreen', (tester) async {
      final vm = SocialProfileViewModel(repository: _FakeInnerProfileRepo());
      await tester.pumpWidget(host(CreateSocialProfileScreen(viewModel: vm)));
      expect(find.byType(CreateSocialProfileScreen), findsOneWidget);
      vm.dispose();
    });
  });
}
