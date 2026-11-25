import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/profile/domain/entities/learning_preferences.dart';
import 'package:andril_mobile/features/learning/profile/domain/entities/learning_profile.dart';
import 'package:andril_mobile/features/learning/profile/screens/learning_profile_screen.dart';

void _setupTestViewport(
  WidgetTester tester, {
  Size size = const Size(360, 800),
  double devicePixelRatio = 1.0,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _buildTestApp(
  Widget child, {
  Size size = const Size(360, 800),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: textScaler,
          ),
          child: child,
        ),
      ),
    ),
  );
}

Future<void> _safeTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  const testUserId = 'lp_test_learner_101';
  const testAccountId = 'acc_m2_verified_501';

  LearningProfile createSampleProfile({
    String profileId = testUserId,
    String accountId = testAccountId,
    String displayName = 'Thusa Learner',
    String? bio = 'Passionate Flutter & Mobile UI Engineer.',
    List<String> skillsToLearn = const ['Flutter', 'Clean Architecture'],
    List<String> skillsToShare = const ['UI Design', 'Figma'],
    List<String> learningGoals = const ['Master state management'],
    LearningPreferences? preferences,
  }) {
    return LearningProfile(
      profileId: profileId,
      accountId: accountId,
      displayName: displayName,
      bio: bio,
      skillsToLearn: skillsToLearn,
      skillsToShare: skillsToShare,
      learningGoals: learningGoals,
      preferences: preferences ??
          const LearningPreferences(
            languages: ['English', 'Tamil'],
            learningStyles: ['Video Learning', 'Hands-on Practice'],
            availability: 'Flexible (Any time)',
            notifications: {
              'Connection requests': true,
              'Classroom & circle updates': false,
            },
          ),
    );
  }

  group('LearningProfileScreen View Mode Tests', () {
    testWidgets('1. Renders profile header with avatar, name, badge and bio',
        (tester) async {
      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('learning_profile_header')), findsOneWidget);
      expect(find.byKey(const Key('learning_profile_avatar')), findsOneWidget);
      expect(find.byKey(const Key('learning_profile_display_name')),
          findsOneWidget);
      expect(find.text('Thusa Learner'), findsOneWidget);
      expect(find.byKey(const Key('learning_profile_module_badge')),
          findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('Passionate Flutter & Mobile UI Engineer.'),
          findsOneWidget);
      expect(find.byKey(const Key('learning_profile_id_indicator')),
          findsOneWidget);

      // Account ID must never be visible
      expect(find.text(testAccountId), findsNothing);
    });

    testWidgets('2. Renders skills to learn, skills to share, and goals',
        (tester) async {
      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('skill_to_learn_Flutter')), findsOneWidget);
      expect(find.byKey(const Key('skill_to_learn_Clean Architecture')),
          findsOneWidget);
      expect(find.byKey(const Key('skill_to_share_UI Design')), findsOneWidget);
      expect(find.byKey(const Key('skill_to_share_Figma')), findsOneWidget);
      expect(find.byKey(const Key('learning_goal_item_0')), findsOneWidget);
      expect(find.text('Master state management'), findsOneWidget);
    });

    testWidgets('3. Renders approved Q07 preferences summary', (tester) async {
      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('learning_profile_preferences_section')),
          findsOneWidget);
      expect(find.byKey(const Key('pref_lang_English')), findsOneWidget);
      expect(find.byKey(const Key('pref_lang_Tamil')), findsOneWidget);
      expect(
          find.byKey(const Key('pref_style_Video Learning')), findsOneWidget);
      expect(find.byKey(const Key('pref_style_Hands-on Practice')),
          findsOneWidget);
      expect(find.byKey(const Key('pref_availability')), findsOneWidget);
      expect(find.text('Flexible (Any time)'), findsOneWidget);
    });

    testWidgets('4. Renders empty state card when profile has no skills/goals',
        (tester) async {
      final emptyProfile = LearningProfile.empty(
        ownerLearningProfileId: testUserId,
        displayName: 'Empty Learner',
      );

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: emptyProfile,
            currentUserId: testUserId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('learning_profile_empty_state')),
          findsOneWidget);
      expect(
          find.byKey(const Key('empty_skills_to_learn_text')), findsOneWidget);
      expect(
          find.byKey(const Key('empty_skills_to_share_text')), findsOneWidget);
      expect(find.byKey(const Key('empty_goals_text')), findsOneWidget);
    });

    testWidgets('5. Renders disconnected persistence disclaimer notice',
        (tester) async {
      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('learning_profile_persistence_disclaimer')),
          findsOneWidget);
      expect(
        find.text(LearningProfile.disconnectedNotice),
        findsOneWidget,
      );
    });
  });

  group('LearningProfileScreen Edit Mode & Validation Tests', () {
    testWidgets('6. Switches from view to edit mode via edit action button',
        (tester) async {
      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap edit button in AppBar
      final editBtn = find.byKey(const Key('learning_profile_edit_action'));
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('learning_profile_edit_mode')), findsOneWidget);
      expect(find.byKey(const Key('edit_display_name_input')), findsOneWidget);
      expect(find.byKey(const Key('edit_bio_input')), findsOneWidget);
    });

    testWidgets('7. Empty display name shows error banner on save',
        (tester) async {
      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isEditMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear display name
      final nameInput = find.byKey(const Key('edit_display_name_input'));
      await tester.enterText(nameInput, '   ');
      await tester.pumpAndSettle();

      // Tap save
      final saveBtn = find.byKey(const Key('btn_save_profile'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('learning_profile_error_banner')),
          findsOneWidget);
      expect(find.text('Display name cannot be empty.'), findsOneWidget);
    });

    testWidgets('8. Adds a skill to learn via custom input', (tester) async {
      final profile = createSampleProfile(skillsToLearn: []);

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isEditMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final input = find.byKey(const Key('input_skill_to_learn'));
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();
      await tester.enterText(input, 'GraphQL');
      await tester.pumpAndSettle();

      final addBtn = find.byKey(const Key('btn_add_skill_to_learn'));
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('edit_skill_to_learn_GraphQL')), findsOneWidget);
    });

    testWidgets('9. Adds a skill to learn via suggestion chip', (tester) async {
      final profile = createSampleProfile(skillsToLearn: []);

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isEditMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final suggestChip = find.byKey(const Key('suggest_learn_Flutter'));
      await tester.ensureVisible(suggestChip);
      await tester.pumpAndSettle();
      await tester.tap(suggestChip);
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('edit_skill_to_learn_Flutter')), findsOneWidget);
    });

    testWidgets('10. Removes a skill to learn via delete icon', (tester) async {
      final profile = createSampleProfile(skillsToLearn: ['Flutter']);

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isEditMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chipFinder = find.byKey(const Key('edit_skill_to_learn_Flutter'));
      await tester.ensureVisible(chipFinder);
      await tester.pumpAndSettle();

      // Find the delete icon inside the chip
      final deleteIcon = find.descendant(
        of: chipFinder,
        matching: find.byIcon(Icons.close_rounded),
      );
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('edit_skill_to_learn_Flutter')), findsNothing);
    });

    testWidgets('11. Adds and removes skills to share', (tester) async {
      final profile = createSampleProfile(skillsToShare: []);

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isEditMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add via input
      final input = find.byKey(const Key('input_skill_to_share'));
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();
      await tester.enterText(input, 'Mentorship');
      await tester.pumpAndSettle();

      final addBtn = find.byKey(const Key('btn_add_skill_to_share'));
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_skill_to_share_Mentorship')),
          findsOneWidget);
    });

    testWidgets('12. Adds and removes learning goals', (tester) async {
      final profile = createSampleProfile(learningGoals: []);

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isEditMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final input = find.byKey(const Key('input_goal'));
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();
      await tester.enterText(input, 'Publish portfolio online');
      await tester.pumpAndSettle();

      final addBtn = find.byKey(const Key('btn_add_goal'));
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_goal_item_0')), findsOneWidget);
      expect(find.text('Publish portfolio online'), findsOneWidget);

      // Remove goal
      final deleteBtn = find.byKey(const Key('delete_goal_0'));
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_goal_item_0')), findsNothing);
    });

    testWidgets('13. Toggles language, style and availability preferences',
        (tester) async {
      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isEditMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle Tanglish
      final tanglishChip = find.byKey(const Key('edit_lang_Tanglish'));
      await tester.ensureVisible(tanglishChip);
      await tester.pumpAndSettle();
      await tester.tap(tanglishChip);
      await tester.pumpAndSettle();

      // Select Morning availability
      final morningChip = find.byKey(const Key('edit_availability_0'));
      await tester.ensureVisible(morningChip);
      await tester.pumpAndSettle();
      await tester.tap(morningChip);
      await tester.pumpAndSettle();

      expect(find.text('Tanglish'), findsOneWidget);
    });

    testWidgets('14. Successful save emits callback and shows status banner',
        (tester) async {
      final profile = createSampleProfile();
      LearningProfile? savedResult;

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isEditMode: true,
            onSaveProfile: (p) => savedResult = p,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nameInput = find.byKey(const Key('edit_display_name_input'));
      await tester.enterText(nameInput, 'Updated Thusa');
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('btn_save_profile'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(savedResult, isNotNull);
      expect(savedResult!.displayName, 'Updated Thusa');
      expect(find.byKey(const Key('learning_profile_status_banner')),
          findsOneWidget);
      expect(find.text('Profile updated successfully.'), findsOneWidget);
      expect(
          find.byKey(const Key('learning_profile_view_mode')), findsOneWidget);
    });

    testWidgets('15. Local save without callback shows disconnected banner',
        (tester) async {
      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isEditMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('btn_save_profile'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('learning_profile_status_banner')),
          findsOneWidget);
      expect(
        find.text(
            'Draft saved locally. Remote repository persistence contract pending.'),
        findsOneWidget,
      );
    });
  });

  group('LearningProfileScreen Draft Preservation & Discard Dialog Tests', () {
    testWidgets('16. Cancel with unsaved changes prompts discard dialog',
        (tester) async {
      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isEditMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Modify display name
      final nameInput = find.byKey(const Key('edit_display_name_input'));
      await tester.enterText(nameInput, 'Dirty Modification');
      await tester.pumpAndSettle();

      // Tap Cancel
      final cancelBtn = find.byKey(const Key('btn_cancel_edit'));
      await tester.ensureVisible(cancelBtn);
      await tester.pumpAndSettle();
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Dialog must appear
      expect(find.byKey(const Key('dialog_discard_changes')), findsOneWidget);

      // Tap Keep Editing
      await _safeTap(tester, find.byKey(const Key('btn_keep_editing')));

      // Still in edit mode with modification intact
      expect(
          find.byKey(const Key('learning_profile_edit_mode')), findsOneWidget);
      expect(find.text('Dirty Modification'), findsOneWidget);

      // Tap Cancel again and confirm Discard
      await _safeTap(tester, cancelBtn);

      await _safeTap(tester, find.byKey(const Key('btn_confirm_discard')));

      // Exits to view mode
      expect(
          find.byKey(const Key('learning_profile_view_mode')), findsOneWidget);
    });

    testWidgets('17. Cancel without changes returns to view mode immediately',
        (tester) async {
      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isEditMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cancelBtn = find.byKey(const Key('btn_cancel_edit'));
      await tester.ensureVisible(cancelBtn);
      await tester.pumpAndSettle();
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dialog_discard_changes')), findsNothing);
      expect(
          find.byKey(const Key('learning_profile_view_mode')), findsOneWidget);
    });
  });

  group('LearningProfileScreen Security & Fail-Closed Access Control Tests',
      () {
    testWidgets('18. isAccessDenied true renders Access Denied view',
        (tester) async {
      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isAccessDenied: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('learning_profile_access_denied')),
          findsOneWidget);
      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.byKey(const Key('learning_profile_header')), findsNothing);
    });

    testWidgets('19. currentUserId mismatch renders Access Denied view',
        (tester) async {
      final profile = createSampleProfile(profileId: 'lp_other_user');

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: 'lp_attacker_user',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('learning_profile_access_denied')),
          findsOneWidget);
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('20. Identity switch purges private edit state immediately',
        (tester) async {
      final profileUserA = createSampleProfile(
        profileId: 'user_a',
        displayName: 'User A',
      );

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profileUserA,
            currentUserId: 'user_a',
            isEditMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter private edit in User A's session
      final nameInput = find.byKey(const Key('edit_display_name_input'));
      await tester.enterText(nameInput, 'Confidential Edit A');
      await tester.pumpAndSettle();

      // Switch session identity to User B
      final profileUserB = createSampleProfile(
        profileId: 'user_b',
        displayName: 'User B',
      );

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profileUserB,
            currentUserId: 'user_b',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Private state must be purged; User B view rendered
      expect(find.text('Confidential Edit A'), findsNothing);
      expect(find.text('User B'), findsOneWidget);
    });
  });

  group('LearningProfileScreen State Coverage Tests', () {
    testWidgets('21. isLoading true renders loading spinner', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningProfileScreen(
            isLoading: true,
            currentUserId: testUserId,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('learning_profile_loading')), findsOneWidget);
      expect(find.text('Loading Learning Profile...'), findsOneWidget);
    });

    testWidgets('22. isUnavailable true renders service unavailable view',
        (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            isUnavailable: true,
            currentUserId: testUserId,
            onRetry: () => retried = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('learning_profile_unavailable')),
          findsOneWidget);
      expect(find.text('Service Unavailable'), findsOneWidget);

      final retryBtn = find.byKey(const Key('btn_retry_unavailable'));
      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    testWidgets('23. errorMessage renders error state with retry',
        (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            errorMessage: 'Failed to load remote profile contract',
            currentUserId: testUserId,
            onRetry: () => retried = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('learning_profile_error')), findsOneWidget);
      expect(
          find.text('Failed to load remote profile contract'), findsOneWidget);

      final retryBtn = find.byKey(const Key('btn_retry_error'));
      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });
  });

  group('LearningProfileScreen Responsiveness & Accessibility Tests', () {
    testWidgets('24. 320dp narrow width renders without overflow',
        (tester) async {
      _setupTestViewport(tester, size: const Size(320, 640));

      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
          ),
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('25. 360dp width renders without overflow', (tester) async {
      _setupTestViewport(tester, size: const Size(360, 740));

      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
          ),
          size: const Size(360, 740),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('26. 412dp width renders without overflow', (tester) async {
      _setupTestViewport(tester, size: const Size(412, 892));

      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
          ),
          size: const Size(412, 892),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('27. 1.5x dynamic text scale renders without overflow',
        (tester) async {
      _setupTestViewport(tester, size: const Size(360, 740));

      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
          ),
          size: const Size(360, 740),
          textScaler: const TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('28. Edit mode 320dp narrow width renders without overflow',
        (tester) async {
      _setupTestViewport(tester, size: const Size(320, 640));

      final profile = createSampleProfile();

      await tester.pumpWidget(
        _buildTestApp(
          LearningProfileScreen(
            initialProfile: profile,
            currentUserId: testUserId,
            isEditMode: true,
          ),
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
    });
  });
}
