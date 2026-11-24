import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_editor_screen.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';

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

Widget _buildTestHarness({
  required Widget child,
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

/// Helper to ensure a widget is visible and pumped before tapping.
Future<void> _safeTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('CV Editor Screen Widget Tests (LRN-05, CV-01..05)', () {
    // =========================================================================
    // GROUP 1: Initial Render & Mode Distinction
    // =========================================================================

    testWidgets(
        'TEST-ED-01: Create mode renders CREATE MODE badge, 7 section tabs, and empty defaults',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create CV'), findsOneWidget);
      expect(find.text('CREATE MODE'), findsOneWidget);
      expect(find.byKey(const Key('cv_title_input')), findsOneWidget);

      // Verify all 7 section tabs exist
      expect(find.byKey(const Key('section_tab_profile')), findsOneWidget);
      expect(find.byKey(const Key('section_tab_experience')), findsOneWidget);
      expect(find.byKey(const Key('section_tab_education')), findsOneWidget);
      expect(find.byKey(const Key('section_tab_skills')), findsOneWidget);
      expect(
          find.byKey(const Key('section_tab_certifications')), findsOneWidget);
      expect(find.byKey(const Key('section_tab_projects')), findsOneWidget);
      expect(find.byKey(const Key('section_tab_links')), findsOneWidget);

      // Verify default title is populated in create mode
      final titleField = tester.widget<TextFormField>(
        find.byKey(const Key('cv_title_input')),
      );
      expect(titleField.controller?.text, equals('My Professional CV'));

      // Verify stepper shows Section 1 of 7
      expect(find.textContaining('Section 1 of 7'), findsOneWidget);
      expect(find.text('14% Complete'), findsOneWidget);

      // Verify bottom action buttons
      expect(find.byKey(const Key('next_section_button')), findsOneWidget);
      expect(find.byKey(const Key('preview_template_button')), findsOneWidget);
      expect(find.byKey(const Key('save_draft_button')), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-ED-02: Edit mode renders EDIT MODE badge and populates initial draft',
        (tester) async {
      _setupTestViewport(tester);

      final sampleDraft = CvDraftData.syntheticSample();

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvEditorScreen(
            initialDraft: sampleDraft,
            isCreateMode: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit CV'), findsOneWidget);
      expect(find.text('EDIT MODE'), findsOneWidget);

      final titleField = tester.widget<TextFormField>(
        find.byKey(const Key('cv_title_input')),
      );
      expect(titleField.controller?.text, equals(sampleDraft.title));

      final fullNameField = tester.widget<TextFormField>(
        find.byKey(const Key('profile_full_name_input')),
      );
      expect(fullNameField.controller?.text, equals(sampleDraft.fullName));

      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // GROUP 2: Contact Privacy Consent (CV-03)
    // =========================================================================

    testWidgets(
        'TEST-ED-03: Contact export consent toggles default to off in create mode and toggle cleanly',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      final emailSwitch = find.byKey(const Key('consent_email_switch'));
      final phoneSwitch = find.byKey(const Key('consent_phone_switch'));
      final locationSwitch = find.byKey(const Key('consent_location_switch'));
      final websiteSwitch = find.byKey(const Key('consent_website_switch'));

      await tester.ensureVisible(emailSwitch);
      await tester.pumpAndSettle();

      // In create mode, all contact export consents must be default-off (CV-03)
      final emailTile = tester.widget<SwitchListTile>(emailSwitch);
      final phoneTile = tester.widget<SwitchListTile>(phoneSwitch);
      final locationTile = tester.widget<SwitchListTile>(locationSwitch);
      final websiteTile = tester.widget<SwitchListTile>(websiteSwitch);

      expect(emailTile.value, isFalse);
      expect(phoneTile.value, isFalse);
      expect(locationTile.value, isFalse);
      expect(websiteTile.value, isFalse);

      // Toggle email switch on
      await _safeTap(tester, emailSwitch);
      final updatedEmailTile = tester.widget<SwitchListTile>(emailSwitch);
      expect(updatedEmailTile.value, isTrue);

      // Toggle phone switch on
      await _safeTap(tester, phoneSwitch);
      final updatedPhoneTile = tester.widget<SwitchListTile>(phoneSwitch);
      expect(updatedPhoneTile.value, isTrue);

      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // GROUP 3: Input Validation & Title Restrictions
    // =========================================================================

    testWidgets(
        'TEST-ED-04: Document title validation blocks empty and >60 character strings',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      final titleInput = find.byKey(const Key('cv_title_input'));
      final saveBtn = find.byKey(const Key('save_draft_button'));

      // Clear title first to test empty validation
      await tester.enterText(titleInput, '');
      await tester.pumpAndSettle();

      // Attempt saving with empty title
      await _safeTap(tester, saveBtn);

      expect(find.text('Please enter a title for this CV'), findsOneWidget);
      expect(
        find.text('Please resolve validation errors before saving draft.'),
        findsOneWidget,
      );

      // Enter string exceeding 60 characters
      final longTitle = 'A' * 61;
      await tester.ensureVisible(titleInput);
      await tester.pumpAndSettle();
      await tester.enterText(titleInput, longTitle);
      await tester.pumpAndSettle();

      await _safeTap(tester, saveBtn);

      expect(
        find.text('Title must be 60 characters or fewer'),
        findsOneWidget,
      );

      // Enter valid title (<= 60 chars)
      await tester.ensureVisible(titleInput);
      await tester.pumpAndSettle();
      await tester.enterText(titleInput, 'Senior Flutter Developer CV');
      await tester.pumpAndSettle();

      await _safeTap(tester, saveBtn);

      expect(find.text('Title must be 60 characters or fewer'), findsNothing);
    });

    testWidgets(
        'TEST-ED-05: Mandatory profile full name validation triggers on empty submit',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in valid title first
      final titleInput = find.byKey(const Key('cv_title_input'));
      await tester.enterText(titleInput, 'Valid Title');
      await tester.pumpAndSettle();

      // Ensure full name is empty and tap preview
      final previewBtn = find.byKey(const Key('preview_template_button'));
      await _safeTap(tester, previewBtn);

      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(
        find.text('Please resolve validation errors before previewing.'),
        findsOneWidget,
      );
    });

    // =========================================================================
    // GROUP 4: Navigation & Stepper
    // =========================================================================

    testWidgets(
        'TEST-ED-06: Stepper navigation advances and retreats through sections',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Section 1 of 7 • Profile'), findsOneWidget);

      // Next section -> Section 2 (Experience)
      final nextBtn = find.byKey(const Key('next_section_button'));
      await _safeTap(tester, nextBtn);

      expect(
          find.textContaining('Section 2 of 7 • Experience'), findsOneWidget);
      expect(find.byKey(const Key('add_experience_button')), findsOneWidget);

      // Previous section -> Section 1 (Profile)
      final prevBtn = find.byKey(const Key('prev_section_button'));
      await _safeTap(tester, prevBtn);

      expect(find.textContaining('Section 1 of 7 • Profile'), findsOneWidget);
      expect(find.byKey(const Key('profile_full_name_input')), findsOneWidget);
    });

    testWidgets(
        'TEST-ED-07: Direct section tab jumping navigates to selected section immediately',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Jump directly to Education (tab 3)
      final eduTab = find.byKey(const Key('section_tab_education'));
      await _safeTap(tester, eduTab);

      expect(find.textContaining('Section 3 of 7 • Education'), findsOneWidget);
      expect(find.byKey(const Key('add_education_button')), findsOneWidget);

      // Jump directly to Links (tab 7)
      final linksTab = find.byKey(const Key('section_tab_links'));
      await _safeTap(tester, linksTab);

      expect(find.textContaining('Section 7 of 7 • Links'), findsOneWidget);
      expect(find.byKey(const Key('add_link_button')), findsOneWidget);
    });

    // =========================================================================
    // GROUP 5: Section CRUD Operations
    // =========================================================================

    testWidgets(
        'TEST-ED-08: Experience section supports adding and deleting work experience item',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Experience tab
      await _safeTap(tester, find.byKey(const Key('section_tab_experience')));

      // Open add form
      final addBtn = find.byKey(const Key('add_experience_button'));
      await _safeTap(tester, addBtn);

      expect(find.byKey(const Key('exp_job_title_input')), findsOneWidget);
      expect(find.byKey(const Key('exp_company_input')), findsOneWidget);

      // Fill in fields
      await tester.enterText(
        find.byKey(const Key('exp_job_title_input')),
        'Staff Mobile Engineer',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('exp_company_input')),
        'Tech Global',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('exp_period_input')),
        '2022 - Present',
      );
      await tester.pumpAndSettle();

      // Save item
      final saveExpBtn = find.byKey(const Key('save_experience_button'));
      await _safeTap(tester, saveExpBtn);

      // Verify item card is displayed
      expect(find.text('Staff Mobile Engineer'), findsOneWidget);
      expect(find.text('Tech Global • 2022 - Present'), findsOneWidget);
      expect(find.byKey(const Key('delete_experience_0')), findsOneWidget);

      // Delete item
      await _safeTap(tester, find.byKey(const Key('delete_experience_0')));

      expect(find.text('Staff Mobile Engineer'), findsNothing);
      expect(find.textContaining('No experience entries yet'), findsOneWidget);
    });

    testWidgets(
        'TEST-ED-09: Education section supports adding and deleting degree item',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Education
      await _safeTap(tester, find.byKey(const Key('section_tab_education')));

      final addBtn = find.byKey(const Key('add_education_button'));
      await _safeTap(tester, addBtn);

      await tester.enterText(
        find.byKey(const Key('edu_degree_input')),
        'B.Sc. in Computer Science',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edu_institution_input')),
        'Oxford University',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edu_year_input')),
        '2020',
      );
      await tester.pumpAndSettle();

      final saveEduBtn = find.byKey(const Key('save_education_button'));
      await _safeTap(tester, saveEduBtn);

      expect(find.text('B.Sc. in Computer Science'), findsOneWidget);
      expect(find.text('Oxford University • 2020'), findsOneWidget);

      // Delete education item
      await _safeTap(tester, find.byKey(const Key('delete_education_0')));

      expect(find.text('B.Sc. in Computer Science'), findsNothing);
    });

    testWidgets(
        'TEST-ED-10: Skills section supports custom chips and preset suggestions',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Skills
      await _safeTap(tester, find.byKey(const Key('section_tab_skills')));

      // Add custom skill
      final skillInput = find.byKey(const Key('add_skill_input'));
      await tester.ensureVisible(skillInput);
      await tester.pumpAndSettle();
      await tester.enterText(skillInput, 'Riverpod');
      await tester.pumpAndSettle();

      final addSkillBtn = find.byKey(const Key('add_skill_button'));
      await _safeTap(tester, addSkillBtn);

      expect(find.byKey(const Key('skill_chip_Riverpod')), findsOneWidget);

      // Add preset suggestion chip: Flutter
      final flutterPreset = find.byKey(const Key('preset_skill_Flutter'));
      await _safeTap(tester, flutterPreset);

      expect(find.byKey(const Key('skill_chip_Flutter')), findsOneWidget);

      // Remove custom skill chip
      final riverpodDelete = find.descendant(
        of: find.byKey(const Key('skill_chip_Riverpod')),
        matching: find.byIcon(Icons.close),
      );
      await _safeTap(tester, riverpodDelete);

      expect(find.byKey(const Key('skill_chip_Riverpod')), findsNothing);
      expect(find.byKey(const Key('skill_chip_Flutter')), findsOneWidget);
    });

    testWidgets(
        'TEST-ED-11: Certifications section supports adding and deleting certification',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Certifications
      await _safeTap(
          tester, find.byKey(const Key('section_tab_certifications')));

      final addCertBtn = find.byKey(const Key('add_certification_button'));
      await _safeTap(tester, addCertBtn);

      await tester.enterText(
        find.byKey(const Key('cert_name_input')),
        'Google Cloud Certified Architect',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('cert_issuer_input')),
        'Google',
      );
      await tester.pumpAndSettle();

      final saveCertBtn = find.byKey(const Key('save_certification_button'));
      await _safeTap(tester, saveCertBtn);

      expect(find.text('Google Cloud Certified Architect'), findsOneWidget);
      expect(find.byKey(const Key('delete_certification_0')), findsOneWidget);

      await _safeTap(tester, find.byKey(const Key('delete_certification_0')));

      expect(find.text('Google Cloud Certified Architect'), findsNothing);
    });

    testWidgets(
        'TEST-ED-12: Projects section supports adding and deleting showcase project',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Projects
      await _safeTap(tester, find.byKey(const Key('section_tab_projects')));

      final addProjBtn = find.byKey(const Key('add_project_button'));
      await _safeTap(tester, addProjBtn);

      await tester.enterText(
        find.byKey(const Key('proj_name_input')),
        'Andril Mobile App',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('proj_role_input')),
        'Lead Engineer',
      );
      await tester.pumpAndSettle();

      final saveProjBtn = find.byKey(const Key('save_project_button'));
      await _safeTap(tester, saveProjBtn);

      expect(find.text('Andril Mobile App'), findsOneWidget);
      expect(find.byKey(const Key('delete_project_0')), findsOneWidget);

      await _safeTap(tester, find.byKey(const Key('delete_project_0')));

      expect(find.text('Andril Mobile App'), findsNothing);
    });

    testWidgets(
        'TEST-ED-13: Links section supports adding and deleting external link',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Links
      await _safeTap(tester, find.byKey(const Key('section_tab_links')));

      final addLinkBtn = find.byKey(const Key('add_link_button'));
      await _safeTap(tester, addLinkBtn);

      await tester.enterText(
        find.byKey(const Key('link_label_input')),
        'GitHub',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('link_url_input')),
        'https://github.com/andril',
      );
      await tester.pumpAndSettle();

      final saveLinkBtn = find.byKey(const Key('save_link_button'));
      await _safeTap(tester, saveLinkBtn);

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('https://github.com/andril'), findsOneWidget);

      await _safeTap(tester, find.byKey(const Key('delete_link_0')));

      expect(find.text('GitHub'), findsNothing);
    });

    // =========================================================================
    // GROUP 6: Lossless Draft Preservation & Handoff
    // =========================================================================

    testWidgets(
        'TEST-ED-14: Draft state preserved across section tab switching',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Enter profile details
      await tester.enterText(
        find.byKey(const Key('profile_full_name_input')),
        'Alex Mercer',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('profile_headline_input')),
        'Principal System Architect',
      );
      await tester.pumpAndSettle();

      // Switch to Section 4: Skills
      await _safeTap(tester, find.byKey(const Key('section_tab_skills')));

      // Add a skill
      await _safeTap(tester, find.byKey(const Key('preset_skill_Dart')));

      // Switch back to Profile
      await _safeTap(tester, find.byKey(const Key('section_tab_profile')));

      // Verify profile inputs remain intact
      final nameField = tester.widget<TextFormField>(
        find.byKey(const Key('profile_full_name_input')),
      );
      final headField = tester.widget<TextFormField>(
        find.byKey(const Key('profile_headline_input')),
      );
      expect(nameField.controller?.text, equals('Alex Mercer'));
      expect(headField.controller?.text, equals('Principal System Architect'));

      // Switch to Skills and verify skill is preserved
      await _safeTap(tester, find.byKey(const Key('section_tab_skills')));
      expect(find.byKey(const Key('skill_chip_Dart')), findsOneWidget);
    });

    testWidgets(
        'TEST-ED-15: Save Draft invokes onSaveDraft callback and displays status banner',
        (tester) async {
      _setupTestViewport(tester);

      CvDraftData? savedDraft;

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvEditorScreen(
            isCreateMode: true,
            onSaveDraft: (draft) => savedDraft = draft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill required fields
      await tester.enterText(
        find.byKey(const Key('cv_title_input')),
        'Preserved Lead CV',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('profile_full_name_input')),
        'Taylor Swift',
      );
      await tester.pumpAndSettle();

      // Save draft
      final saveBtn = find.byKey(const Key('save_draft_button'));
      await _safeTap(tester, saveBtn);

      expect(savedDraft, isNotNull);
      expect(savedDraft!.title, equals('Preserved Lead CV'));
      expect(savedDraft!.fullName, equals('Taylor Swift'));
      expect(find.byKey(const Key('status_banner')), findsOneWidget);
      expect(
        find.textContaining('Draft "Preserved Lead CV" saved.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'TEST-ED-16: Preview button validates and triggers onPreview callback with complete draft',
        (tester) async {
      _setupTestViewport(tester);

      CvDraftData? previewDraft;

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvEditorScreen(
            isCreateMode: true,
            onPreview: (draft) => previewDraft = draft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter title and full name
      await tester.enterText(
        find.byKey(const Key('cv_title_input')),
        'Preview Ready CV',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('profile_full_name_input')),
        'Morgan Vance',
      );
      await tester.pumpAndSettle();

      // Tap preview
      final previewBtn = find.byKey(const Key('preview_template_button'));
      await _safeTap(tester, previewBtn);

      expect(previewDraft, isNotNull);
      expect(previewDraft!.title, equals('Preview Ready CV'));
      expect(previewDraft!.fullName, equals('Morgan Vance'));
    });

    // =========================================================================
    // GROUP 7: Responsive Layouts & Dynamic Scaling
    // =========================================================================

    testWidgets(
        'TEST-ED-17: 320dp narrow viewport renders without RenderFlex overflow',
        (tester) async {
      _setupTestViewport(tester, size: const Size(320, 640));

      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(320, 640),
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create CV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-ED-18: 360dp standard viewport renders without RenderFlex overflow',
        (tester) async {
      _setupTestViewport(tester, size: const Size(360, 800));

      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(360, 800),
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create CV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-ED-19: 412dp modern viewport renders without RenderFlex overflow',
        (tester) async {
      _setupTestViewport(tester, size: const Size(412, 915));

      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(412, 915),
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create CV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-ED-20: 1.5x dynamic text scaling renders without RenderFlex overflow',
        (tester) async {
      _setupTestViewport(tester, size: const Size(360, 800));

      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(360, 800),
          textScaler: const TextScaler.linear(1.5),
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create CV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // GROUP 8: Accessibility & Semantics
    // =========================================================================

    testWidgets(
        'TEST-ED-21: Section tabs expose correct semantics selection state',
        (tester) async {
      _setupTestViewport(tester);

      final semanticsHandle = tester.ensureSemantics();
      var semanticsDisposed = false;
      void disposeSemantics() {
        if (!semanticsDisposed) {
          semanticsDisposed = true;
          semanticsHandle.dispose();
        }
      }

      addTearDown(disposeSemantics);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Profile tab should have isSelected = true
      final profileTab = find.byKey(const Key('section_tab_profile'));
      expect(
        tester.getSemantics(profileTab),
        isSemantics(
          hasSelectedState: true,
          isSelected: true,
        ),
      );

      // Experience tab should have isSelected = false
      final expTab = find.byKey(const Key('section_tab_experience'));
      expect(
        tester.getSemantics(expTab),
        isSemantics(
          hasSelectedState: true,
          isSelected: false,
        ),
      );

      disposeSemantics();
    });

    testWidgets(
        'TEST-ED-22: Cancel button closes item creation form without saving',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Experience tab
      await _safeTap(tester, find.byKey(const Key('section_tab_experience')));

      // Open add form
      await _safeTap(tester, find.byKey(const Key('add_experience_button')));

      final cancelBtn = find.byKey(const Key('cancel_experience_button'));
      expect(cancelBtn, findsOneWidget);

      // Tap cancel
      await _safeTap(tester, cancelBtn);

      expect(find.byKey(const Key('exp_job_title_input')), findsNothing);
      expect(find.byKey(const Key('add_experience_button')), findsOneWidget);
    });

    testWidgets(
        'TEST-ED-23: Local status banner displays persistence contract pending when onSaveDraft is omitted',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvEditorScreen(isCreateMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid fields
      await tester.enterText(
        find.byKey(const Key('cv_title_input')),
        'Standalone Draft',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('profile_full_name_input')),
        'Sam Stone',
      );
      await tester.pumpAndSettle();

      // Tap save without callback
      final saveBtn = find.byKey(const Key('save_draft_button'));
      await _safeTap(tester, saveBtn);

      expect(find.byKey(const Key('status_banner')), findsOneWidget);
      expect(
        find.text(
          'Draft "Standalone Draft" saved locally. Remote repository persistence contract pending.',
        ),
        findsOneWidget,
      );
    });
  });
}
