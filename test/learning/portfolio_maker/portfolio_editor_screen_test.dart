import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/presentation/screens/portfolio_editor_screen.dart';

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
  group('Portfolio Editor Screen Widget Tests (LRN-06 / PORT-01..05)', () {
    // =========================================================================
    // GROUP 1: Mode Distinction & Initial Render
    // =========================================================================

    testWidgets(
      'TEST-PORT-01: Create mode renders CREATE MODE badge, title input with default, PRIVATE badge, and empty placeholder',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mode_badge_create')), findsOneWidget);
        expect(find.text('CREATE MODE'), findsOneWidget);
        expect(find.byKey(const Key('privacy_badge_private')), findsOneWidget);
        expect(find.text('PRIVATE'), findsOneWidget);
        expect(find.byKey(const Key('portfolio_title_input')), findsOneWidget);
        expect(find.text('My Learning Portfolio'), findsOneWidget);
        expect(find.byKey(const Key('empty_projects_placeholder')),
            findsOneWidget);
        expect(find.text('No projects added yet.'), findsOneWidget);
        expect(find.byKey(const Key('add_project_button')), findsOneWidget);
        expect(find.byKey(const Key('save_portfolio_button')), findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PORT-02: Edit mode renders EDIT MODE badge, prefilled title, and prefilled project cards',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioEditorScreen(
              initialPortfolio: sample,
              isCreateMode: false,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mode_badge_edit')), findsOneWidget);
        expect(find.text('EDIT MODE'), findsOneWidget);
        expect(
            find.text('Mobile Systems Engineering Portfolio'), findsOneWidget);
        expect(find.byKey(const Key('project_card_0')), findsOneWidget);
        expect(find.byKey(const Key('project_card_1')), findsOneWidget);
        expect(find.text('ANDRIL Mobile Learning Suite'), findsOneWidget);
        expect(find.text('Accessible Design System'), findsOneWidget);
        expect(find.text('2 Media'), findsOneWidget);
        expect(find.text('2 Links'), findsOneWidget);
      },
    );

    // =========================================================================
    // GROUP 2: State Coverage: Loading & Access Denied
    // =========================================================================

    testWidgets(
      'TEST-PORT-03: Loading state renders loading_indicator and suppresses main editor content',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isLoading: true,
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
        expect(find.byKey(const Key('portfolio_title_input')), findsNothing);
        expect(find.byKey(const Key('save_portfolio_button')), findsNothing);
      },
    );

    testWidgets(
      'TEST-PORT-04: Explicit access-denied state renders access_denied_card',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isAccessDenied: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('access_denied_card')), findsOneWidget);
        expect(find.text('Access Denied'), findsOneWidget);
        expect(
          find.text(
              'This Learning Portfolio is private and can only be accessed by its owner.'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('portfolio_title_input')), findsNothing);
      },
    );

    testWidgets(
      'TEST-PORT-05: Unauthorized user renders access_denied_card',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'actual_owner_id',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioEditorScreen(
              initialPortfolio: sample,
              currentUserId: 'unauthorized_attacker_id',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('access_denied_card')), findsOneWidget);
        expect(find.text('Access Denied'), findsOneWidget);
        expect(find.byKey(const Key('portfolio_title_input')), findsNothing);
      },
    );

    testWidgets(
      'TEST-PORT-06: Authorized user renders editor screen without access denied',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'actual_owner_id',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioEditorScreen(
              initialPortfolio: sample,
              currentUserId: 'actual_owner_id',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('access_denied_card')), findsNothing);
        expect(find.byKey(const Key('portfolio_title_input')), findsOneWidget);
      },
    );

    // =========================================================================
    // GROUP 3: Portfolio Title Validation & Saving
    // =========================================================================

    testWidgets(
      'TEST-PORT-07: Empty portfolio title triggers error banner on Save Draft',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Clear portfolio title
        final titleFinder = find.byKey(const Key('portfolio_title_input'));
        await tester.enterText(titleFinder, '');
        await tester.pumpAndSettle();

        // Tap Save Portfolio Draft
        await _safeTap(tester, find.byKey(const Key('save_portfolio_button')));

        expect(find.byKey(const Key('error_banner')), findsOneWidget);
        expect(find.text('Portfolio document title is required.'),
            findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'TEST-PORT-08: Save Portfolio invokes onSavePortfolio callback with updated immutable portfolio and shows confirmation banner',
      (tester) async {
        _setupTestViewport(tester);

        LearningPortfolio? savedPortfolio;

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
              onSavePortfolio: (portfolio) {
                savedPortfolio = portfolio;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final titleFinder = find.byKey(const Key('portfolio_title_input'));
        await tester.enterText(titleFinder, 'Cloud Architecture Portfolio');
        await tester.pumpAndSettle();

        await _safeTap(tester, find.byKey(const Key('save_portfolio_button')));

        expect(savedPortfolio, isNotNull);
        expect(savedPortfolio!.title, 'Cloud Architecture Portfolio');
        expect(savedPortfolio!.isPrivate, isTrue);
        expect(savedPortfolio!.module, 'learning');
        expect(find.byKey(const Key('status_banner')), findsOneWidget);
        expect(find.text('Portfolio "Cloud Architecture Portfolio" saved.'),
            findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PORT-09: Save Portfolio without callback shows local persistence pending confirmation banner',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(tester, find.byKey(const Key('save_portfolio_button')));

        expect(find.byKey(const Key('status_banner')), findsOneWidget);
        expect(
          find.text(
              'Portfolio "My Learning Portfolio" saved locally. Remote repository persistence contract pending.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TEST-PORT-10: Banner close button dismisses status and error banners',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger status banner
        await _safeTap(tester, find.byKey(const Key('save_portfolio_button')));
        expect(find.byKey(const Key('status_banner')), findsOneWidget);

        // Tap close button in status banner
        final closeButtonFinder = find.descendant(
          of: find.byKey(const Key('status_banner')),
          matching: find.byType(IconButton),
        );
        await _safeTap(tester, closeButtonFinder);
        expect(find.byKey(const Key('status_banner')), findsNothing);
      },
    );

    // =========================================================================
    // GROUP 4: Structured Project Editing (Add, Edit, Cancel, Validation)
    // =========================================================================

    testWidgets(
      'TEST-PORT-11: Add Project button opens project form with empty inputs',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(tester, find.byKey(const Key('add_project_button')));

        expect(find.text('Add New Project'), findsOneWidget);
        expect(find.byKey(const Key('project_title_input')), findsOneWidget);
        expect(
            find.byKey(const Key('project_description_input')), findsOneWidget);
        expect(find.byKey(const Key('media_url_input')), findsOneWidget);
        expect(find.byKey(const Key('link_url_input')), findsOneWidget);
        expect(find.byKey(const Key('cancel_project_button')), findsOneWidget);
        expect(
            find.byKey(const Key('save_project_entry_button')), findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PORT-12: Cancel project form closes form without modifying project list',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(tester, find.byKey(const Key('add_project_button')));
        expect(find.byKey(const Key('project_title_input')), findsOneWidget);

        // Enter some text then cancel
        await tester.enterText(
            find.byKey(const Key('project_title_input')), 'Draft Title');
        await _safeTap(tester, find.byKey(const Key('cancel_project_button')));

        expect(find.byKey(const Key('project_title_input')), findsNothing);
        expect(find.byKey(const Key('empty_projects_placeholder')),
            findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PORT-13: Empty project title triggers error banner when saving project entry',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(tester, find.byKey(const Key('add_project_button')));
        await _safeTap(
            tester, find.byKey(const Key('save_project_entry_button')));

        expect(find.byKey(const Key('error_banner')), findsOneWidget);
        expect(find.text('Project title is required.'), findsOneWidget);
      },
    );

    // =========================================================================
    // GROUP 5: Media & Link Reference Management
    // =========================================================================

    testWidgets(
      'TEST-PORT-14: Adding valid media URL creates chip; invalid media URL triggers error banner',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(tester, find.byKey(const Key('add_project_button')));

        // Invalid media URL (ftp scheme)
        await tester.enterText(
          find.byKey(const Key('media_url_input')),
          'ftp://files.example.com/demo.png',
        );
        await _safeTap(tester, find.byKey(const Key('add_media_button')));
        expect(find.byKey(const Key('error_banner')), findsOneWidget);
        expect(
          find.text('Media reference must be an absolute HTTP or HTTPS URL.'),
          findsOneWidget,
        );

        // Invalid media URL (relative)
        await tester.enterText(
          find.byKey(const Key('media_url_input')),
          '/assets/demo.png',
        );
        await _safeTap(tester, find.byKey(const Key('add_media_button')));
        expect(find.byKey(const Key('error_banner')), findsOneWidget);

        // Valid HTTPS URL
        await tester.enterText(
          find.byKey(const Key('media_url_input')),
          'https://andril.dev/screenshot.png',
        );
        await _safeTap(tester, find.byKey(const Key('add_media_button')));
        expect(find.byKey(const Key('media_chip_0')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('media_chip_0')),
            matching: find.text('https://andril.dev/screenshot.png'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TEST-PORT-15: Media reference chip can be removed',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(tester, find.byKey(const Key('add_project_button')));
        await tester.enterText(
          find.byKey(const Key('media_url_input')),
          'https://andril.dev/screenshot.png',
        );
        await _safeTap(tester, find.byKey(const Key('add_media_button')));
        expect(find.byKey(const Key('media_chip_0')), findsOneWidget);

        // Remove media chip
        final deleteIconFinder = find.descendant(
          of: find.byKey(const Key('media_chip_0')),
          matching: find.byIcon(Icons.close),
        );
        await _safeTap(tester, deleteIconFinder);
        expect(find.byKey(const Key('media_chip_0')), findsNothing);
      },
    );

    testWidgets(
      'TEST-PORT-16: Adding valid external link URL creates chip; invalid URL triggers error banner',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(tester, find.byKey(const Key('add_project_button')));

        // Invalid link (javascript pseudo-protocol)
        await tester.enterText(
          find.byKey(const Key('link_url_input')),
          'javascript:alert(1)',
        );
        await _safeTap(tester, find.byKey(const Key('add_link_button')));
        expect(find.byKey(const Key('error_banner')), findsOneWidget);
        expect(
          find.text('External link must be an absolute HTTP or HTTPS URL.'),
          findsOneWidget,
        );

        // Valid link
        await tester.enterText(
          find.byKey(const Key('link_url_input')),
          'https://github.com/andril/learning-mobile',
        );
        await _safeTap(tester, find.byKey(const Key('add_link_button')));
        expect(find.byKey(const Key('link_chip_0')), findsOneWidget);
        expect(find.text('https://github.com/andril/learning-mobile'),
            findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PORT-17: External link chip can be removed',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(tester, find.byKey(const Key('add_project_button')));
        await tester.enterText(
          find.byKey(const Key('link_url_input')),
          'https://github.com/andril/learning-mobile',
        );
        await _safeTap(tester, find.byKey(const Key('add_link_button')));
        expect(find.byKey(const Key('link_chip_0')), findsOneWidget);

        final deleteIconFinder = find.descendant(
          of: find.byKey(const Key('link_chip_0')),
          matching: find.byIcon(Icons.close),
        );
        await _safeTap(tester, deleteIconFinder);
        expect(find.byKey(const Key('link_chip_0')), findsNothing);
      },
    );

    // =========================================================================
    // GROUP 6: Project CRUD Operations
    // =========================================================================

    testWidgets(
      'TEST-PORT-18: Successfully add project entry and verify project card in list',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(tester, find.byKey(const Key('add_project_button')));

        await tester.enterText(
          find.byKey(const Key('project_title_input')),
          'Microservices Observability',
        );
        await tester.enterText(
          find.byKey(const Key('project_description_input')),
          'Distributed tracing and OpenTelemetry collector pipeline.',
        );

        // Add media reference
        await tester.enterText(
          find.byKey(const Key('media_url_input')),
          'https://andril.dev/telemetry.png',
        );
        await _safeTap(tester, find.byKey(const Key('add_media_button')));

        // Add link reference
        await tester.enterText(
          find.byKey(const Key('link_url_input')),
          'https://github.com/andril/telemetry',
        );
        await _safeTap(tester, find.byKey(const Key('add_link_button')));

        // Save project entry
        await _safeTap(
            tester, find.byKey(const Key('save_project_entry_button')));

        expect(find.byKey(const Key('project_card_0')), findsOneWidget);
        expect(find.text('Microservices Observability'), findsOneWidget);
        expect(
          find.text(
              'Distributed tracing and OpenTelemetry collector pipeline.'),
          findsOneWidget,
        );
        expect(find.text('1 Media'), findsOneWidget);
        expect(find.text('1 Links'), findsOneWidget);
        expect(find.byKey(const Key('status_banner')), findsOneWidget);
        expect(
          find.text(
              'Project "Microservices Observability" added to portfolio.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TEST-PORT-19: Edit existing project entry and verify updated details',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioEditorScreen(
              initialPortfolio: sample,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ANDRIL Mobile Learning Suite'), findsOneWidget);

        // Tap edit button on project 0
        await _safeTap(tester, find.byKey(const Key('edit_project_0')));

        expect(find.text('Edit Project Entry'), findsOneWidget);
        expect(
          find.widgetWithText(TextFormField, 'ANDRIL Mobile Learning Suite'),
          findsOneWidget,
        );

        // Update project title
        await tester.enterText(
          find.byKey(const Key('project_title_input')),
          'ANDRIL Mobile Client v2',
        );

        // Save changes
        await _safeTap(
            tester, find.byKey(const Key('save_project_entry_button')));

        expect(find.text('ANDRIL Mobile Client v2'), findsOneWidget);
        expect(find.byKey(const Key('status_banner')), findsOneWidget);
        expect(
          find.text('Project "ANDRIL Mobile Client v2" updated.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TEST-PORT-20: Delete project removes it from list and updates project count',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioEditorScreen(
              initialPortfolio: sample,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('project_card_0')), findsOneWidget);
        expect(find.byKey(const Key('project_card_1')), findsOneWidget);

        // Delete first project
        await _safeTap(tester, find.byKey(const Key('delete_project_0')));

        // Card 1 is now Card 0
        expect(find.byKey(const Key('project_card_0')), findsOneWidget);
        expect(find.byKey(const Key('project_card_1')), findsNothing);
        expect(find.text('Accessible Design System'), findsOneWidget);
        expect(find.byKey(const Key('status_banner')), findsOneWidget);
      },
    );

    // =========================================================================
    // GROUP 7: Project Reordering (Move Up / Move Down)
    // =========================================================================

    testWidgets(
      'TEST-PORT-21: Reordering: Move Down moves project at 0 to 1, Move Up moves it back',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioEditorScreen(
              initialPortfolio: sample,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Project 0 is ANDRIL Mobile Learning Suite
        // Project 1 is Accessible Design System
        final card0Before = find.descendant(
          of: find.byKey(const Key('project_card_0')),
          matching: find.text('ANDRIL Mobile Learning Suite'),
        );
        expect(card0Before, findsOneWidget);

        // Move project 0 down
        await _safeTap(tester, find.byKey(const Key('move_down_project_0')));

        // Now Project 0 should be Accessible Design System
        final card0After = find.descendant(
          of: find.byKey(const Key('project_card_0')),
          matching: find.text('Accessible Design System'),
        );
        expect(card0After, findsOneWidget);

        // Now Project 1 should be ANDRIL Mobile Learning Suite
        final card1After = find.descendant(
          of: find.byKey(const Key('project_card_1')),
          matching: find.text('ANDRIL Mobile Learning Suite'),
        );
        expect(card1After, findsOneWidget);

        // Move project 1 up
        await _safeTap(tester, find.byKey(const Key('move_up_project_1')));

        // Restored: Project 0 is ANDRIL Mobile Learning Suite
        expect(
          find.descendant(
            of: find.byKey(const Key('project_card_0')),
            matching: find.text('ANDRIL Mobile Learning Suite'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TEST-PORT-22: Reorder boundary: Move Up is disabled for first project, Move Down disabled for last project',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioEditorScreen(
              initialPortfolio: sample,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Move Up on index 0 should have onPressed == null
        final moveUp0 = tester
            .widget<IconButton>(find.byKey(const Key('move_up_project_0')));
        expect(moveUp0.onPressed, isNull);

        // Move Down on index 0 should be enabled
        final moveDown0 = tester
            .widget<IconButton>(find.byKey(const Key('move_down_project_0')));
        expect(moveDown0.onPressed, isNotNull);

        // Move Up on index 1 should be enabled
        final moveUp1 = tester
            .widget<IconButton>(find.byKey(const Key('move_up_project_1')));
        expect(moveUp1.onPressed, isNotNull);

        // Move Down on index 1 (last project) should have onPressed == null
        final moveDown1 = tester
            .widget<IconButton>(find.byKey(const Key('move_down_project_1')));
        expect(moveDown1.onPressed, isNull);
      },
    );

    // =========================================================================
    // GROUP 8: Responsive Layouts & Overflow Prevention
    // =========================================================================

    testWidgets(
      'TEST-PORT-23: 320dp narrow viewport renders without RenderFlex overflow',
      (tester) async {
        _setupTestViewport(tester, size: const Size(320, 700));

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            size: const Size(320, 700),
            child: PortfolioEditorScreen(
              initialPortfolio: sample,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('project_card_0')), findsOneWidget);
        expect(find.byKey(const Key('save_portfolio_button')), findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PORT-24: 360dp standard viewport renders without RenderFlex overflow',
      (tester) async {
        _setupTestViewport(tester, size: const Size(360, 800));

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            size: const Size(360, 800),
            child: PortfolioEditorScreen(
              initialPortfolio: sample,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('project_card_0')), findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PORT-25: 412dp modern viewport renders without RenderFlex overflow',
      (tester) async {
        _setupTestViewport(tester, size: const Size(412, 915));

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            size: const Size(412, 915),
            child: PortfolioEditorScreen(
              initialPortfolio: sample,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('project_card_0')), findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PORT-26: 1.5x dynamic text scaling renders without RenderFlex overflow',
      (tester) async {
        _setupTestViewport(tester, size: const Size(360, 800));

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            size: const Size(360, 800),
            textScaler: const TextScaler.linear(1.5),
            child: PortfolioEditorScreen(
              initialPortfolio: sample,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('project_card_0')), findsOneWidget);
      },
    );

    // =========================================================================
    // GROUP 9: Accessibility Semantics & Module Isolation
    // =========================================================================

    testWidgets(
      'TEST-PORT-27: Semantics: Action buttons have accessible semantics labels',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioEditorScreen(
              initialPortfolio: sample,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check Move Up tooltip semantics
        final moveUpFinder = find.byKey(const Key('move_up_project_1'));
        final moveUpWidget = tester.widget<IconButton>(moveUpFinder);
        expect(moveUpWidget.tooltip, 'Move Up');

        // Check Move Down tooltip semantics
        final moveDownFinder = find.byKey(const Key('move_down_project_0'));
        final moveDownWidget = tester.widget<IconButton>(moveDownFinder);
        expect(moveDownWidget.tooltip, 'Move Down');

        // Check Delete tooltip semantics
        final deleteFinder = find.byKey(const Key('delete_project_0'));
        final deleteWidget = tester.widget<IconButton>(deleteFinder);
        expect(deleteWidget.tooltip, 'Remove');
      },
    );

    testWidgets(
      'TEST-PORT-28: Module isolation: LearningPortfolio module is always "learning"',
      (tester) async {
        _setupTestViewport(tester);

        LearningPortfolio? saved;

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioEditorScreen(
              isCreateMode: true,
              currentUserId: 'test_owner_01',
              onSavePortfolio: (p) => saved = p,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(tester, find.byKey(const Key('save_portfolio_button')));

        expect(saved, isNotNull);
        expect(saved!.module, 'learning');
      },
    );
  });
}
