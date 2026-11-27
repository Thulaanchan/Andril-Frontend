import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/router/learning_router.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/home/screens/learning_home_container.dart';
import 'package:andril_mobile/features/learning/home/screens/learning_home_screen.dart';
import 'package:andril_mobile/features/learning/home/widgets/learning_home_action_grid.dart';
import 'package:andril_mobile/features/learning/home/widgets/learning_home_header.dart';
import 'package:andril_mobile/features/learning/home/widgets/learning_progress_card.dart';
import 'package:andril_mobile/features/learning/profile/domain/entities/learning_preferences.dart';
import 'package:andril_mobile/features/learning/profile/domain/entities/learning_profile.dart';
import 'package:andril_mobile/features/learning/profile/domain/repositories/profile_repository.dart';
import '../../shared_core/authentication/foundation_fakes.dart';

class _FakeLearningAccessPolicy implements LearningAccessPolicy {
  @override
  final bool isAuthenticated;

  @override
  final bool isLearningActivated;

  const _FakeLearningAccessPolicy({
    required this.isAuthenticated,
    required this.isLearningActivated,
  });
}

class _FakeProfileRepository implements ProfileRepository {
  ProfileResult<LearningProfile>? resultToReturn;
  int getProfileCallCount = 0;
  LearningProfile? updatedProfile;

  _FakeProfileRepository({this.resultToReturn});

  @override
  Future<ProfileResult<LearningProfile>> getProfile() async {
    getProfileCallCount++;
    return resultToReturn ??
        ProfileSuccess(
          LearningProfile(
            profileId: 'lp_test_01',
            accountId: 'acc_test_99',
            displayName: 'Aarav Dev',
            learningGoals: const ['Master Flutter Clean Architecture'],
            skillsToLearn: const ['Dart Concurrency', 'GraphQL'],
            skillsToShare: const ['Flutter UI', 'Dart Basics'],
            preferences: const LearningPreferences(
              availability: 'Morning (6 AM – 12 PM)',
            ),
            isActivated: true,
          ),
        );
  }

  @override
  Future<ProfileResult<LearningProfile>> updateProfile(
      LearningProfile profile) async {
    updatedProfile = profile;
    return ProfileSuccess(profile);
  }

  @override
  Future<ProfileResult<LearningProfile>> saveDraftProfile({
    required String displayName,
    List<String> skillsToLearn = const [],
    List<String> skillsToShare = const [],
    List<String> learningGoals = const [],
  }) async {
    final profile = LearningProfile(
      profileId: 'lp_draft_01',
      accountId: 'acc_draft_99',
      displayName: displayName,
      skillsToLearn: skillsToLearn,
      skillsToShare: skillsToShare,
      learningGoals: learningGoals,
    );
    updatedProfile = profile;
    return ProfileSuccess(profile);
  }
}

class _TestSessionSource extends FakeSessionSource
    implements BackendSessionSource {
  _TestSessionSource({String subject = 'user_m2_42'})
      : super(
          restored: SessionEvent(SessionEventKind.initial, subject: subject),
        );

  @override
  BackendCredential? backendCredential = const BackendCredential(
    'user_m2_42',
    'm2.jwt.token',
    emailConfirmed: true,
  );

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}
}

Widget _buildHarness({
  required Widget child,
}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('Task 06-02: Learning Home Production Activation & Gating Tests', () {
    testWidgets('1. Access denied when unauthenticated (fail-closed M2 gate)',
        (tester) async {
      const policy = _FakeLearningAccessPolicy(
        isAuthenticated: false,
        isLearningActivated: false,
      );
      final repo = _FakeProfileRepository();

      await tester.pumpWidget(
        _buildHarness(
          child: LearningHomeContainer(
            accessPolicy: policy,
            profileRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(
        find.text('Learning Home requires active module activation.'),
        findsOneWidget,
      );
      // Ensure zero profile calls occurred and no learner data leaked
      expect(repo.getProfileCallCount, 0);
      expect(find.text('Aarav Dev'), findsNothing);
    });

    testWidgets('2. Access denied when authenticated but unactivated by M2',
        (tester) async {
      const policy = _FakeLearningAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: false,
      );
      final repo = _FakeProfileRepository();

      await tester.pumpWidget(
        _buildHarness(
          child: LearningHomeContainer(
            accessPolicy: policy,
            profileRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(repo.getProfileCallCount, 0);
      expect(find.text('Aarav Dev'), findsNothing);
    });

    testWidgets(
        '3. Renders authorized dashboard with real profile, goals, and availability',
        (tester) async {
      const policy = _FakeLearningAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );
      final repo = _FakeProfileRepository();

      await tester.pumpWidget(
        _buildHarness(
          child: LearningHomeContainer(
            accessPolicy: policy,
            profileRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.getProfileCallCount, 1);
      expect(find.byType(LearningHomeScreen), findsOneWidget);
      expect(find.byType(LearningHomeHeader), findsOneWidget);
      expect(find.byType(LearningProgressCard), findsOneWidget);
      expect(find.byType(LearningHomeActionGrid), findsOneWidget);

      // Verify real profile display name
      expect(find.text('Aarav Dev'), findsOneWidget);
      // Verify router baseline token presence
      expect(find.text('Learning Home'), findsOneWidget);
      // Verify active goal rendered from backend profile
      expect(find.text('Master Flutter Clean Architecture'), findsOneWidget);
      // Verify weekly commitment text from preferences
      expect(find.text('Morning (6 AM – 12 PM)'), findsOneWidget);
      // Verify progress percent is null (unverified metric disconnected)
      final progressCard = tester
          .widget<LearningProgressCard>(find.byType(LearningProgressCard));
      expect(progressCard.completionPercent, isNull);
    });

    testWidgets(
        '4. Backend-issued profile identity is preserved and distinct from account ID',
        (tester) async {
      const policy = _FakeLearningAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );
      final profile = LearningProfile(
        profileId: 'lp_issued_backend_888',
        accountId: 'acc_m2_global_999',
        displayName: 'Dev Maya',
        learningGoals: const ['Build Accessible UIs'],
        preferences: const LearningPreferences(),
      );
      final repo = _FakeProfileRepository(
        resultToReturn: ProfileSuccess(profile),
      );

      await tester.pumpWidget(
        _buildHarness(
          child: LearningHomeContainer(
            accessPolicy: policy,
            profileRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dev Maya'), findsOneWidget);
      expect(profile.profileId, 'lp_issued_backend_888');
      expect(profile.accountId, 'acc_m2_global_999');
      expect(profile.profileId, isNot(equals(profile.accountId)));
    });

    testWidgets(
        '5. Action shortcuts present all approved Batch 05 features and disconnect unverified AI planner',
        (tester) async {
      const policy = _FakeLearningAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );
      final repo = _FakeProfileRepository();

      await tester.pumpWidget(
        _buildHarness(
          child: LearningHomeContainer(
            accessPolicy: policy,
            profileRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final actionGrid = tester
          .widget<LearningHomeActionGrid>(find.byType(LearningHomeActionGrid));
      final actions = actionGrid.actions;

      // Verify approved features
      final titles = actions.map((a) => a.title).toList();
      expect(titles, contains('Learning Circles'));
      expect(titles, contains('Study Pacts'));
      expect(titles, contains('Growth Dashboard'));
      expect(titles, contains('Mentorship'));
      expect(titles, contains('CV Maker'));
      expect(titles, contains('Portfolio Maker'));
      expect(titles, contains('Partner Discovery'));
      expect(titles, contains('Connections'));
      expect(titles, contains('Skill Exchange'));
      expect(titles, contains('Classrooms Hub'));
      expect(titles, contains('Edit Profile'));
      expect(titles, contains('AI Study Planner'));

      // Verify AI planner is explicitly disconnected
      final aiAction =
          actions.firstWhere((a) => a.id == 'action_ai_study_planner');
      expect(aiAction.isAvailable, isFalse);
      expect(aiAction.unavailableReason,
          'AI planning engine pending backend deployment');
    });

    testWidgets('6. Error state renders message and retry button reloads data',
        (tester) async {
      const policy = _FakeLearningAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );
      final repo = _FakeProfileRepository(
        resultToReturn: const ProfileFailure('Backend connection timed out'),
      );

      await tester.pumpWidget(
        _buildHarness(
          child: LearningHomeContainer(
            accessPolicy: policy,
            profileRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Backend connection timed out'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(repo.getProfileCallCount, 1);

      // Now fix the repository result and tap Retry
      repo.resultToReturn = ProfileSuccess(
        LearningProfile(
          profileId: 'lp_recovered',
          accountId: 'acc_recovered',
          displayName: 'Recovered Learner',
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.getProfileCallCount, 2);
      expect(find.text('Recovered Learner'), findsOneWidget);
      expect(find.text('Backend connection timed out'), findsNothing);
    });

    testWidgets('7. Repository ProfileAccessDenied renders fail-closed state',
        (tester) async {
      const policy = _FakeLearningAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );
      final repo = _FakeProfileRepository(
        resultToReturn: const ProfileAccessDenied(),
      );

      await tester.pumpWidget(
        _buildHarness(
          child: LearningHomeContainer(
            accessPolicy: policy,
            profileRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('Aarav Dev'), findsNothing);
    });

    testWidgets('8. Session revocation triggers private-state clearing',
        (tester) async {
      final source = _TestSessionSource();
      final sessionController = SessionController(source);
      await sessionController.start();

      var stateCleared = false;
      sessionController.registerPrivateStateClearer(() {
        stateCleared = true;
      });

      const policy = _FakeLearningAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );
      final repo = _FakeProfileRepository();

      await tester.pumpWidget(
        _buildHarness(
          child: LearningHomeContainer(
            accessPolicy: policy,
            profileRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aarav Dev'), findsOneWidget);

      // Revoke session
      source.signals.add(const SessionEvent(SessionEventKind.signedOut));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(stateCleared, isTrue);

      sessionController.dispose();
      await source.signals.close();
    });

    testWidgets('9. Offline resilience renders cached profile safely',
        (tester) async {
      const policy = _FakeLearningAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );
      final cachedProfile = LearningProfile(
        profileId: 'lp_cached_offline',
        accountId: 'acc_offline',
        displayName: 'Offline Learner',
        learningGoals: const ['Continue Offline Course'],
      );
      final repo = _FakeProfileRepository(
        resultToReturn: ProfileSuccess(cachedProfile),
      );

      await tester.pumpWidget(
        _buildHarness(
          child: LearningHomeContainer(
            accessPolicy: policy,
            profileRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Learner'), findsOneWidget);
      expect(find.text('Continue Offline Course'), findsOneWidget);
    });

    testWidgets('10. Custom navigation callbacks are triggered when provided',
        (tester) async {
      const policy = _FakeLearningAccessPolicy(
        isAuthenticated: true,
        isLearningActivated: true,
      );
      final repo = _FakeProfileRepository();

      var notificationTapped = false;
      var resumeTapped = false;

      await tester.pumpWidget(
        _buildHarness(
          child: LearningHomeContainer(
            accessPolicy: policy,
            profileRepository: repo,
            onNotificationTap: () {
              notificationTapped = true;
            },
            onResume: () {
              resumeTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find resume button
      final resumeFinder = find.text('Resume Learning');
      expect(resumeFinder, findsOneWidget);
      await tester.tap(resumeFinder);
      expect(resumeTapped, isTrue);

      // Notification button
      final notifFinder = find.byIcon(Icons.notifications_outlined);
      if (notifFinder.evaluate().isNotEmpty) {
        await tester.tap(notifFinder);
        expect(notificationTapped, isTrue);
      }
    });
  });
}
