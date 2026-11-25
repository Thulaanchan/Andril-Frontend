import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/presentation/screens/portfolio_template_selection_preview_screen.dart';

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

Future<void> _safeTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group(
      'Portfolio Template Selection & Preview Widget Tests (LRN-06 / PORT-01..05)',
      () {
    // =========================================================================
    // GROUP 1: Initial Rendering & Template Selection
    // =========================================================================

    testWidgets(
      'TEST-PREV-01: Initial state renders title input, 3 template cards and actions',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Portfolio Templates'), findsOneWidget);
        expect(find.byKey(const Key('privacy_badge_private')), findsOneWidget);
        expect(find.byKey(const Key('portfolio_title_input')), findsOneWidget);
        expect(
            find.byKey(const Key('template_card_developer')), findsOneWidget);
        expect(find.byKey(const Key('template_card_creative')), findsOneWidget);
        expect(find.byKey(const Key('template_card_professional')),
            findsOneWidget);
        expect(
            find.byKey(const Key('preview_portfolio_button')), findsOneWidget);
        expect(
            find.byKey(const Key('continue_to_editor_button')), findsOneWidget);
        expect(find.byKey(const Key('save_portfolio_draft_button')),
            findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PREV-02: Developer template is selected by default with SELECTED badge',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
            find.byKey(const Key('selected_badge_developer')), findsOneWidget);
        expect(find.byKey(const Key('selected_badge_creative')), findsNothing);
        expect(
            find.byKey(const Key('selected_badge_professional')), findsNothing);
      },
    );

    testWidgets(
      'TEST-PREV-03: Tapping Creative card switches selection and triggers callback',
      (tester) async {
        _setupTestViewport(tester);

        PortfolioTemplate? changedTemplate;

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
              onTemplateChanged: (t) => changedTemplate = t,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(tester, find.byKey(const Key('template_card_creative')));

        expect(changedTemplate, PortfolioTemplate.creative);
        expect(
            find.byKey(const Key('selected_badge_creative')), findsOneWidget);
        expect(find.byKey(const Key('selected_badge_developer')), findsNothing);
      },
    );

    testWidgets(
      'TEST-PREV-04: Tapping Professional card switches selection and triggers callback',
      (tester) async {
        _setupTestViewport(tester);

        PortfolioTemplate? changedTemplate;

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
              onTemplateChanged: (t) => changedTemplate = t,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(
            tester, find.byKey(const Key('template_card_professional')));

        expect(changedTemplate, PortfolioTemplate.professional);
        expect(find.byKey(const Key('selected_badge_professional')),
            findsOneWidget);
        expect(find.byKey(const Key('selected_badge_developer')), findsNothing);
      },
    );

    testWidgets(
      'TEST-PREV-05: Template features are rendered for Developer, Creative, and Professional',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Code-styled technical hierarchy'), findsOneWidget);
        expect(find.text('Media-first showcase layout'), findsOneWidget);
        expect(find.text('Executive accomplishment hierarchy'), findsOneWidget);
      },
    );

    // =========================================================================
    // GROUP 2: Validation on Actions
    // =========================================================================

    testWidgets(
      'TEST-PREV-06: Empty title triggers validation error and blocks Live Preview',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('portfolio_title_input')), '');
        await tester.pumpAndSettle();

        await _safeTap(
            tester, find.byKey(const Key('preview_portfolio_button')));

        expect(find.byKey(const Key('error_banner')), findsOneWidget);
        expect(
            find.text('Portfolio document title is required.'), findsOneWidget);
        expect(
            find.byKey(const Key('portfolio_document_canvas')), findsNothing);
      },
    );

    testWidgets(
      'TEST-PREV-07: Empty title triggers validation error and blocks Continue',
      (tester) async {
        _setupTestViewport(tester);

        bool continued = false;

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
              onContinue: (_) => continued = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('portfolio_title_input')), '');
        await tester.pumpAndSettle();

        await _safeTap(
            tester, find.byKey(const Key('continue_to_editor_button')));

        expect(continued, isFalse);
        expect(find.byKey(const Key('error_banner')), findsOneWidget);
        expect(
            find.text('Portfolio document title is required.'), findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PREV-08: Empty title triggers validation error and blocks Save Draft',
      (tester) async {
        _setupTestViewport(tester);

        bool saved = false;

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
              onSaveDraft: (_) => saved = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('portfolio_title_input')), '');
        await tester.pumpAndSettle();

        await _safeTap(
            tester, find.byKey(const Key('save_portfolio_draft_button')));

        expect(saved, isFalse);
        expect(find.byKey(const Key('error_banner')), findsOneWidget);
        expect(
            find.text('Portfolio document title is required.'), findsOneWidget);
      },
    );

    // =========================================================================
    // GROUP 3: Live Preview Transition & Canvas Rendering
    // =========================================================================

    testWidgets(
      'TEST-PREV-09: Live Preview button transitions to document canvas view',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(
            tester, find.byKey(const Key('preview_portfolio_button')));

        expect(
            find.byKey(const Key('portfolio_document_canvas')), findsOneWidget);
        expect(
            find.byKey(const Key('preview_template_switcher')), findsOneWidget);
        expect(
            find.byKey(const Key('back_to_templates_button')), findsOneWidget);
        expect(find.byKey(const Key('edit_portfolio_from_preview_button')),
            findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PREV-10: initialPreviewMode = true opens directly in canvas preview',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioTemplateSelectionPreviewScreen(
              initialPreviewMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
            find.byKey(const Key('portfolio_document_canvas')), findsOneWidget);
        expect(find.byKey(const Key('template_card_developer')), findsNothing);
      },
    );

    testWidgets(
      'TEST-PREV-11: Back to Templates button returns to selection view',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioTemplateSelectionPreviewScreen(
              initialPreviewMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(
            tester, find.byKey(const Key('back_to_templates_button')));

        expect(
            find.byKey(const Key('template_card_developer')), findsOneWidget);
        expect(
            find.byKey(const Key('portfolio_document_canvas')), findsNothing);
      },
    );

    testWidgets(
      'TEST-PREV-12: Document canvas renders title, owner ID, and private badge',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'custom_owner_99',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              initialPortfolio: sample,
              initialPreviewMode: true,
              currentUserId: 'custom_owner_99',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('canvas_portfolio_title')), findsOneWidget);
        expect(
            find.text('Mobile Systems Engineering Portfolio'), findsOneWidget);
        expect(find.text('Owner Profile ID: custom_owner_99'), findsOneWidget);
        expect(find.byKey(const Key('canvas_privacy_badge')), findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PREV-13: Document canvas renders showcase project cards with media and link references',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              initialPortfolio: sample,
              initialPreviewMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('preview_project_0')), findsOneWidget);
        expect(find.byKey(const Key('preview_project_1')), findsOneWidget);
        expect(find.text('ANDRIL Mobile Learning Suite'), findsOneWidget);
        expect(find.text('Accessible Design System'), findsOneWidget);

        // Media reference chip
        expect(find.byKey(const Key('preview_media_0_0')), findsOneWidget);
        expect(find.text('https://andril.dev/media/showcase-01.png'),
            findsOneWidget);

        // External link chip
        expect(find.byKey(const Key('preview_link_0_0')), findsOneWidget);
        expect(find.text('https://github.com/andril/learning-mobile'),
            findsOneWidget);
      },
    );

    // =========================================================================
    // GROUP 4: Lossless Template Switching
    // =========================================================================

    testWidgets(
      'TEST-PREV-14: Switching to Creative updates active theme without modifying projects or order',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              initialPortfolio: sample,
              initialPreviewMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DEVELOPER THEME'), findsOneWidget);

        // Switch to Creative
        await _safeTap(
            tester, find.byKey(const Key('preview_switch_creative')));

        expect(find.text('CREATIVE THEME'), findsOneWidget);
        // Projects still present in identical order
        expect(find.byKey(const Key('preview_project_0')), findsOneWidget);
        expect(find.byKey(const Key('preview_project_1')), findsOneWidget);
        expect(find.text('ANDRIL Mobile Learning Suite'), findsOneWidget);
        expect(find.text('Accessible Design System'), findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PREV-15: Switching to Professional updates active theme without loss',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              initialPortfolio: sample,
              initialPreviewMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Professional
        await _safeTap(
            tester, find.byKey(const Key('preview_switch_professional')));

        expect(find.text('PROFESSIONAL THEME'), findsOneWidget);
        expect(find.byKey(const Key('preview_project_0')), findsOneWidget);
        expect(find.text('ANDRIL Mobile Learning Suite'), findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PREV-16: Switching back to Developer restores Developer theme',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              initialPortfolio: sample,
              initialPreviewMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(
            tester, find.byKey(const Key('preview_switch_creative')));
        expect(find.text('CREATIVE THEME'), findsOneWidget);

        await _safeTap(
            tester, find.byKey(const Key('preview_switch_developer')));
        expect(find.text('DEVELOPER THEME'), findsOneWidget);
      },
    );

    // =========================================================================
    // GROUP 5: States Coverage (Loading, Empty, Access Denied)
    // =========================================================================

    testWidgets(
      'TEST-PREV-17: Loading state renders loading_indicator',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioTemplateSelectionPreviewScreen(
              isLoading: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
        expect(find.byKey(const Key('portfolio_title_input')), findsNothing);
      },
    );

    testWidgets(
      'TEST-PREV-18: Explicit access-denied state renders access_denied_card',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioTemplateSelectionPreviewScreen(
              isAccessDenied: true,
              currentUserId: 'test_owner_01',
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
      'TEST-PREV-19: Unauthorized user renders access_denied_card',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'actual_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              initialPortfolio: sample,
              currentUserId: 'attacker_user_02',
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
      'TEST-PREV-20: Authorized user renders selection view normally',
      (tester) async {
        _setupTestViewport(tester);

        final sample = LearningPortfolio.syntheticSample(
          ownerLearningProfileId: 'actual_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              initialPortfolio: sample,
              currentUserId: 'actual_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('access_denied_card')), findsNothing);
        expect(find.byKey(const Key('portfolio_title_input')), findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PREV-21: Empty projects portfolio renders placeholder on canvas',
      (tester) async {
        _setupTestViewport(tester);

        final emptyPortfolio = LearningPortfolio.empty(
          ownerLearningProfileId: 'test_owner_01',
        );

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              initialPortfolio: emptyPortfolio,
              initialPreviewMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('preview_empty_projects')), findsOneWidget);
        expect(find.text('No projects added yet.'), findsOneWidget);
      },
    );

    // =========================================================================
    // GROUP 6: Callback Invocation & In-Memory Draft Saving
    // =========================================================================

    testWidgets(
      'TEST-PREV-22: Continue button invokes onContinue with updated portfolio',
      (tester) async {
        _setupTestViewport(tester);

        LearningPortfolio? continuedPortfolio;

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
              onContinue: (p) => continuedPortfolio = p,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Creative
        await _safeTap(tester, find.byKey(const Key('template_card_creative')));
        await _safeTap(
            tester, find.byKey(const Key('continue_to_editor_button')));

        expect(continuedPortfolio, isNotNull);
        expect(continuedPortfolio!.template, PortfolioTemplate.creative);
      },
    );

    testWidgets(
      'TEST-PREV-23: Save Draft invokes onSaveDraft and displays confirmation banner',
      (tester) async {
        _setupTestViewport(tester);

        LearningPortfolio? savedPortfolio;

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
              onSaveDraft: (p) => savedPortfolio = p,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(
            tester, find.byKey(const Key('save_portfolio_draft_button')));

        expect(savedPortfolio, isNotNull);
        expect(find.byKey(const Key('status_banner')), findsOneWidget);
        expect(find.text('Portfolio "${savedPortfolio!.title}" saved.'),
            findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PREV-24: Save Draft without callback displays local persistence pending banner',
      (tester) async {
        _setupTestViewport(tester);

        await tester.pumpWidget(
          _buildTestHarness(
            child: const PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(
            tester, find.byKey(const Key('save_portfolio_draft_button')));

        expect(find.byKey(const Key('status_banner')), findsOneWidget);
        expect(
          find.text(
              'Portfolio "Mobile Systems Engineering Portfolio" saved locally. Remote repository persistence contract pending.'),
          findsOneWidget,
        );
      },
    );

    // =========================================================================
    // GROUP 7: Responsive Layouts & Overflow Prevention
    // =========================================================================

    testWidgets(
      'TEST-PREV-25: Selection view renders across 320dp, 360dp, 412dp viewports without overflow',
      (tester) async {
        for (final size in [
          const Size(320, 640),
          const Size(360, 800),
          const Size(412, 915),
        ]) {
          _setupTestViewport(tester, size: size);

          await tester.pumpWidget(
            _buildTestHarness(
              size: size,
              child: const PortfolioTemplateSelectionPreviewScreen(
                currentUserId: 'test_owner_01',
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
              find.byKey(const Key('template_card_developer')), findsOneWidget);
        }
      },
    );

    testWidgets(
      'TEST-PREV-26: Live preview canvas renders across 320dp, 360dp, 412dp viewports without overflow',
      (tester) async {
        for (final size in [
          const Size(320, 640),
          const Size(360, 800),
          const Size(412, 915),
        ]) {
          _setupTestViewport(tester, size: size);

          await tester.pumpWidget(
            _buildTestHarness(
              size: size,
              child: const PortfolioTemplateSelectionPreviewScreen(
                initialPreviewMode: true,
                currentUserId: 'test_owner_01',
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('portfolio_document_canvas')),
              findsOneWidget);
        }
      },
    );

    testWidgets(
      'TEST-PREV-27: Selection view renders with 1.5x dynamic text scale without overflow',
      (tester) async {
        _setupTestViewport(tester, size: const Size(360, 800));

        await tester.pumpWidget(
          _buildTestHarness(
            size: const Size(360, 800),
            textScaler: const TextScaler.linear(1.5),
            child: const PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
            find.byKey(const Key('template_card_developer')), findsOneWidget);
      },
    );

    testWidgets(
      'TEST-PREV-28: Live preview canvas renders with 1.5x dynamic text scale without overflow',
      (tester) async {
        _setupTestViewport(tester, size: const Size(360, 800));

        await tester.pumpWidget(
          _buildTestHarness(
            size: const Size(360, 800),
            textScaler: const TextScaler.linear(1.5),
            child: const PortfolioTemplateSelectionPreviewScreen(
              initialPreviewMode: true,
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
            find.byKey(const Key('portfolio_document_canvas')), findsOneWidget);
      },
    );

    // =========================================================================
    // GROUP 8: Accessibility Semantics
    // =========================================================================

    testWidgets(
      'TEST-PREV-29: Template cards have accessible semantics selected state',
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
            child: const PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        final devCardFinder = find.byKey(const Key('template_card_developer'));
        expect(
          tester.getSemantics(devCardFinder),
          isSemantics(
            hasSelectedState: true,
            isSelected: true,
          ),
        );

        final creativeCardFinder =
            find.byKey(const Key('template_card_creative'));
        expect(
          tester.getSemantics(creativeCardFinder),
          isSemantics(
            hasSelectedState: true,
            isSelected: false,
          ),
        );

        disposeSemantics();
      },
    );

    testWidgets(
      'TEST-PREV-30: Edit Projects button in preview canvas invokes onContinue',
      (tester) async {
        _setupTestViewport(tester);

        bool editTapped = false;

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              initialPreviewMode: true,
              currentUserId: 'test_owner_01',
              onContinue: (_) => editTapped = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(tester,
            find.byKey(const Key('edit_portfolio_from_preview_button')));

        expect(editTapped, isTrue);
      },
    );

    testWidgets(
      'TEST-PREV-31: Module isolation: module is always "learning"',
      (tester) async {
        _setupTestViewport(tester);

        LearningPortfolio? saved;

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioTemplateSelectionPreviewScreen(
              currentUserId: 'test_owner_01',
              onSaveDraft: (p) => saved = p,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _safeTap(
            tester, find.byKey(const Key('save_portfolio_draft_button')));

        expect(saved, isNotNull);
        expect(saved!.module, 'learning');
      },
    );
  });
}
