import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
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

void main() {
  group('CV Template Selection & Preview Widget Tests (LRN-05, CV-01..05)', () {
    // =========================================================================
    // GROUP 1: Template Selection View & Initial Rendering
    // =========================================================================

    testWidgets(
        'TEST-CV-01: Initial state renders title input, 3 template cards and actions',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvTemplateSelectionPreviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose CV Template'), findsOneWidget);
      expect(find.byKey(const Key('cv_title_input')), findsOneWidget);
      expect(find.text('My Professional CV'), findsOneWidget);

      // Verify all 3 approved templates exist
      expect(find.byKey(const Key('template_card_modern')), findsOneWidget);
      expect(
          find.byKey(const Key('template_card_professional')), findsOneWidget);
      expect(find.byKey(const Key('template_card_creative')), findsOneWidget);

      expect(find.text('Modern'), findsOneWidget);
      expect(find.text('Professional'), findsOneWidget);
      expect(find.text('Creative'), findsOneWidget);

      // Verify action buttons
      expect(find.byKey(const Key('live_preview_button')), findsOneWidget);
      expect(find.byKey(const Key('save_draft_button')), findsOneWidget);
      expect(find.byKey(const Key('continue_button')), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-CV-02: Modern template is selected by default with SELECTED badge',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvTemplateSelectionPreviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SELECTED'), findsOneWidget);
      expect(find.text('Contemporary Cyan \u2022 Card Bricks'), findsOneWidget);
      expect(
        find.textContaining('Teal accent header', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets(
        'TEST-CV-03: Tapping Professional card switches selection and triggers callback',
        (tester) async {
      _setupTestViewport(tester);
      CvTemplate? selected;

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvTemplateSelectionPreviewScreen(
            onTemplateChanged: (t) => selected = t,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Professional card
      final profCard = find.byKey(const Key('template_card_professional'));
      await tester.ensureVisible(profCard);
      await tester.pumpAndSettle();
      await tester.tap(profCard);
      await tester.pumpAndSettle();

      expect(selected, CvTemplate.professional);
      expect(find.text('SELECTED'), findsOneWidget);
      expect(find.text('Executive Navy \u2022 Formal Rules'), findsOneWidget);
      expect(find.byKey(const Key('status_banner')), findsOneWidget);
      expect(
        find.text(
            'Switched to Professional template. All draft content preserved.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'TEST-CV-04: Tapping Creative card switches selection and updates preview CTA label',
        (tester) async {
      _setupTestViewport(tester);
      CvTemplate? selected;

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvTemplateSelectionPreviewScreen(
            onTemplateChanged: (t) => selected = t,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Creative card
      final creativeCard = find.byKey(const Key('template_card_creative'));
      await tester.ensureVisible(creativeCard);
      await tester.pumpAndSettle();
      await tester.tap(creativeCard);
      await tester.pumpAndSettle();

      expect(selected, CvTemplate.creative);
      expect(
          find.text('Expressive Indigo \u2022 Sidebar Accent'), findsOneWidget);
      expect(find.text('Live Preview (Creative)'), findsOneWidget);
    });

    testWidgets('TEST-CV-05: Status confirmation banner can be dismissed',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvTemplateSelectionPreviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch template to show banner
      final profCard = find.byKey(const Key('template_card_professional'));
      await tester.ensureVisible(profCard);
      await tester.pumpAndSettle();
      await tester.tap(profCard);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('status_banner')), findsOneWidget);

      // Scroll banner back into view before tapping dismiss
      final bannerFinder = find.byKey(const Key('status_banner'));
      await tester.ensureVisible(bannerFinder);
      await tester.pumpAndSettle();

      // Tap dismiss icon in banner
      await tester.tap(find.descendant(
        of: bannerFinder,
        matching: find.byType(IconButton),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('status_banner')), findsNothing);
    });

    // =========================================================================
    // GROUP 2: Validation & Form Actions
    // =========================================================================

    testWidgets(
        'TEST-CV-06: Empty title triggers validation error and blocks continue',
        (tester) async {
      _setupTestViewport(tester);
      bool continued = false;

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvTemplateSelectionPreviewScreen(
            onContinue: (_) => continued = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear title field
      await tester.enterText(find.byKey(const Key('cv_title_input')), '');
      await tester.pumpAndSettle();
      final continueBtn = find.byKey(const Key('continue_button'));
      await tester.ensureVisible(continueBtn);
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(continued, isFalse);
      expect(find.text('Please enter a title for this CV'), findsOneWidget);
    });

    testWidgets(
        'TEST-CV-07: Title exceeding 60 characters triggers length validation error',
        (tester) async {
      _setupTestViewport(tester);
      bool continued = false;

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvTemplateSelectionPreviewScreen(
            onContinue: (_) => continued = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final longTitle = 'A' * 61;
      await tester.enterText(
          find.byKey(const Key('cv_title_input')), longTitle);
      await tester.pumpAndSettle();
      final continueBtn = find.byKey(const Key('continue_button'));
      await tester.ensureVisible(continueBtn);
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(continued, isFalse);
      expect(find.text('Title must be 60 characters or fewer'), findsOneWidget);
    });

    testWidgets('TEST-CV-08: Valid title and template propagate via onContinue',
        (tester) async {
      _setupTestViewport(tester);
      CvDraftData? resultDraft;

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvTemplateSelectionPreviewScreen(
            onContinue: (d) => resultDraft = d,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('cv_title_input')),
        'My Mobile Architect CV',
      );
      await tester.pumpAndSettle();
      final profCard = find.byKey(const Key('template_card_professional'));
      await tester.ensureVisible(profCard);
      await tester.pumpAndSettle();
      await tester.tap(profCard);
      await tester.pumpAndSettle();

      final continueBtn = find.byKey(const Key('continue_button'));
      await tester.ensureVisible(continueBtn);
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(resultDraft, isNotNull);
      expect(resultDraft!.title, 'My Mobile Architect CV');
      expect(resultDraft!.selectedTemplate, CvTemplate.professional);
    });

    testWidgets(
        'TEST-CV-09: Save Draft button validates and invokes onSaveDraft callback',
        (tester) async {
      _setupTestViewport(tester);
      CvDraftData? savedDraft;

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvTemplateSelectionPreviewScreen(
            onSaveDraft: (d) => savedDraft = d,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('cv_title_input')),
        'Draft Research CV',
      );
      await tester.pumpAndSettle();
      final saveBtn = find.byKey(const Key('save_draft_button'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(savedDraft, isNotNull);
      expect(savedDraft!.title, 'Draft Research CV');
      expect(find.text('Draft "Draft Research CV" saved successfully.'),
          findsOneWidget);
    });

    // =========================================================================
    // GROUP 3: Live Preview & Lossless Template Switching (CV-02)
    // =========================================================================

    testWidgets(
        'TEST-CV-10: Live Preview button transitions to document canvas view',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvTemplateSelectionPreviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final previewBtn = find.byKey(const Key('live_preview_button'));
      await tester.ensureVisible(previewBtn);
      await tester.pumpAndSettle();
      await tester.tap(previewBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cv_document_canvas')), findsOneWidget);
      expect(
          find.byKey(const Key('lossless_template_switcher')), findsOneWidget);
      expect(find.byKey(const Key('back_to_selection_button')), findsOneWidget);
      expect(find.text('Active: Modern'), findsOneWidget);
      expect(find.text('Executive Summary'), findsOneWidget);
    });

    testWidgets(
        'TEST-CV-11: Modern preview renders full name, headline, competencies and experience',
        (tester) async {
      _setupTestViewport(tester);
      final sample = CvDraftData.syntheticSample();

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvTemplateSelectionPreviewScreen(
            initialDraft: sample,
            initialPreviewMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(sample.fullName), findsOneWidget);
      expect(find.text(sample.headline), findsOneWidget);
      expect(find.text(sample.summary), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Lead Mobile Frontend Engineer'), findsOneWidget);
      expect(find.text('ANDRIL Education Labs'), findsOneWidget);
      expect(find.text('B.Sc. (Hons) in Software Engineering'), findsOneWidget);
    });

    testWidgets(
        'TEST-CV-12: Lossless switcher in preview updates to Professional layout without losing content',
        (tester) async {
      _setupTestViewport(tester);
      final sample = CvDraftData.syntheticSample();

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvTemplateSelectionPreviewScreen(
            initialDraft: sample,
            initialPreviewMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Professional inside preview
      await tester.tap(find.byKey(const Key('preview_switch_professional')));
      await tester.pumpAndSettle();

      expect(find.text('Active: Professional'), findsOneWidget);
      // Professional layout has all-caps name and formal headings
      expect(find.text(sample.fullName.toUpperCase()), findsOneWidget);
      expect(find.text('Professional Summary'), findsOneWidget);
      expect(find.text('Core Competencies'), findsOneWidget);
      expect(find.text('Professional Experience'), findsOneWidget);
      expect(find.text('Education & Credentials'), findsOneWidget);

      // Verify all draft content preserved
      expect(find.text(sample.summary), findsOneWidget);
      expect(find.text('Lead Mobile Frontend Engineer'), findsOneWidget);
      expect(find.text(sample.education.first.degree), findsOneWidget);
    });

    testWidgets(
        'TEST-CV-13: Lossless switcher in preview updates to Creative layout with sidebar',
        (tester) async {
      _setupTestViewport(tester);
      final sample = CvDraftData.syntheticSample();

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvTemplateSelectionPreviewScreen(
            initialDraft: sample,
            initialPreviewMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Creative
      await tester.tap(find.byKey(const Key('preview_switch_creative')));
      await tester.pumpAndSettle();

      expect(find.text('Active: Creative'), findsOneWidget);
      expect(find.text('CONTACT'), findsOneWidget);
      expect(find.text('SKILLS'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Initials badge in Creative sidebar
      expect(find.text('TK'), findsOneWidget);
      expect(find.text('# Flutter'), findsOneWidget);
      expect(find.text('# Dart'), findsOneWidget);
      expect(find.text(sample.fullName), findsOneWidget);
    });

    testWidgets(
        'TEST-CV-14: Contact privacy toggles suppress disabled contact items (CV-03)',
        (tester) async {
      _setupTestViewport(tester);
      final privateDraft = CvDraftData.syntheticSample().copyWith(
        showEmail: false,
        showPhone: false,
        showLocation: false,
      );

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvTemplateSelectionPreviewScreen(
            initialDraft: privateDraft,
            initialPreviewMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Suppressed contact items should not appear
      expect(find.text('thusha.sample@andril.local'), findsNothing);
      expect(find.text('+94 77 123 4567'), findsNothing);
      expect(find.text('Jaffna, Sri Lanka'), findsNothing);

      // But core content remains
      expect(find.text(privateDraft.fullName), findsOneWidget);
      expect(find.text(privateDraft.headline), findsOneWidget);
    });

    testWidgets('TEST-CV-15: Back to Templates returns to selection screen',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const CvTemplateSelectionPreviewScreen(
            initialPreviewMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cv_document_canvas')), findsOneWidget);

      await tester.tap(find.byKey(const Key('back_to_selection_button')));
      await tester.pumpAndSettle();

      expect(find.text('Choose CV Template'), findsOneWidget);
      expect(find.byKey(const Key('template_card_modern')), findsOneWidget);
    });

    testWidgets(
        'TEST-CV-16: Use This Template in preview triggers onContinue with latest state',
        (tester) async {
      _setupTestViewport(tester);
      CvDraftData? finalDraft;

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvTemplateSelectionPreviewScreen(
            initialPreviewMode: true,
            onContinue: (d) => finalDraft = d,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to creative in preview
      await tester.tap(find.byKey(const Key('preview_switch_creative')));
      await tester.pumpAndSettle();

      // Tap bottom Continue
      final continueBtn = find.byKey(const Key('preview_continue_button'));
      await tester.ensureVisible(continueBtn);
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(finalDraft, isNotNull);
      expect(finalDraft!.selectedTemplate, CvTemplate.creative);
    });

    // =========================================================================
    // GROUP 4: Responsiveness, Overflows & Accessibility
    // =========================================================================

    testWidgets('TEST-CV-17: 320dp narrow viewport renders without overflow',
        (tester) async {
      _setupTestViewport(tester, size: const Size(320, 640));

      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(320, 640),
          child: const CvTemplateSelectionPreviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-CV-18: 360dp standard phone viewport renders without overflow',
        (tester) async {
      _setupTestViewport(tester, size: const Size(360, 800));

      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(360, 800),
          child: const CvTemplateSelectionPreviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-CV-19: 412dp modern phone viewport renders without overflow',
        (tester) async {
      _setupTestViewport(tester, size: const Size(412, 915));

      await tester.pumpWidget(
        _buildTestHarness(
          size: const Size(412, 915),
          child: const CvTemplateSelectionPreviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-CV-20: 1.5x dynamic text scaling renders without overflow',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          textScaler: const TextScaler.linear(1.5),
          child: const CvTemplateSelectionPreviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TEST-CV-21: Semantics check on template cards for accessibility',
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
          child: const CvTemplateSelectionPreviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final modernCardFinder = find.byKey(const Key('template_card_modern'));
      expect(
        tester.getSemantics(modernCardFinder),
        isSemantics(
          hasSelectedState: true,
          isSelected: true,
        ),
      );

      final profCardFinder =
          find.byKey(const Key('template_card_professional'));
      await tester.ensureVisible(profCardFinder);
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(profCardFinder),
        isSemantics(
          hasSelectedState: true,
          isSelected: false,
        ),
      );

      disposeSemantics();
    });

    testWidgets(
        'TEST-CV-22: Preview mode renders across viewports without overflow',
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
            child: const CvTemplateSelectionPreviewScreen(
              initialPreviewMode: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
        'TEST-CV-23: Invalid draft title in preview mode cannot bypass validation',
        (tester) async {
      _setupTestViewport(tester);
      bool continued = false;
      final invalidDraft = CvDraftData.syntheticSample().copyWith(title: '');

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvTemplateSelectionPreviewScreen(
            initialDraft: invalidDraft,
            initialPreviewMode: true,
            onContinue: (_) => continued = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final continueBtn = find.byKey(const Key('preview_continue_button'));
      await tester.ensureVisible(continueBtn);
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(continued, isFalse);
      expect(find.byKey(const Key('template_card_modern')), findsOneWidget);
      expect(
        find.text('Please enter a valid title for this CV.'),
        findsOneWidget,
      );
    });
  });
}
