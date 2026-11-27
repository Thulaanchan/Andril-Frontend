import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_cv_import_result.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/services/i_portfolio_cv_import_service.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/presentation/screens/portfolio_template_selection_preview_screen.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/presentation/widgets/portfolio_cv_import_sheet.dart';

Widget _buildTestHarness({
  required Widget child,
}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Scaffold(
      body: child,
    ),
  );
}

/// Fake service for deterministic CV import widget testing.
class _FakePortfolioCvImportService implements IPortfolioCvImportService {
  final bool shouldFail;
  final bool shouldDenyAccess;
  final Duration delay;
  List<String>? capturedProjectIds;

  _FakePortfolioCvImportService({
    this.shouldFail = false,
    this.shouldDenyAccess = false,
    this.delay = Duration.zero,
  });

  @override
  Future<PortfolioCvImportResult> importProjectsIntoCv({
    required LearningPortfolio portfolio,
    required List<String> selectedProjectIds,
    required CvDraftData targetCv,
    required String currentUserId,
    bool isSessionActive = true,
  }) async {
    capturedProjectIds = selectedProjectIds;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldDenyAccess) {
      throw const PortfolioCvImportAccessDeniedException(
        'Session is revoked or expired. Please re-authenticate.',
      );
    }
    if (shouldFail) {
      throw const PortfolioCvImportException(
          'Import failed due to storage error.');
    }

    final newCvProjects = [
      ...targetCv.projects,
      ...selectedProjectIds.map((id) => CvProjectItem(name: 'Project $id')),
    ];

    return PortfolioCvImportResult(
      updatedCv: targetCv.copyWith(projects: newCvProjects),
      importedCount: selectedProjectIds.length,
      importedProjectTitles:
          selectedProjectIds.map((id) => 'Project $id').toList(),
      totalCvProjects: newCvProjects.length,
      importedAt: DateTime(2026, 11, 26),
    );
  }
}

void main() {
  group('Portfolio CV Import Widget Tests (LRN-06 & CV-01..05)', () {
    late LearningPortfolio samplePortfolio;

    setUp(() {
      samplePortfolio = LearningPortfolio.syntheticSample();
    });

    testWidgets(
        'TEST-CV-UI-01: Renders import sheet with target CV review and project checkbox list',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioCvImportSheet(
            portfolio: samplePortfolio,
            importService: _FakePortfolioCvImportService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Import Projects into CV'), findsOneWidget);
      expect(find.text('Target CV Draft Review'), findsOneWidget);
      expect(find.byKey(const Key('btn_confirm_cv_import')), findsOneWidget);
      expect(find.byKey(const Key('btn_toggle_select_all')), findsOneWidget);

      // Verify each project has a checkbox
      for (final proj in samplePortfolio.projects) {
        expect(find.byKey(Key('checkbox_project_${proj.id}')), findsOneWidget);
      }
    });

    testWidgets(
        'TEST-CV-UI-02: Toggling individual checkboxes updates selection state',
        (tester) async {
      final fakeService = _FakePortfolioCvImportService();

      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioCvImportSheet(
            portfolio: samplePortfolio,
            importService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Uncheck first project
      final firstProjId = samplePortfolio.projects.first.id;
      await tester.tap(find.byKey(Key('checkbox_project_$firstProjId')));
      await tester.pumpAndSettle();

      // Tap confirm import
      await tester.tap(find.byKey(const Key('btn_confirm_cv_import')));
      await tester.pumpAndSettle();

      expect(fakeService.capturedProjectIds, isNot(contains(firstProjId)));
    });

    testWidgets('TEST-CV-UI-03: Select All and Deselect All works as expected',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioCvImportSheet(
            portfolio: samplePortfolio,
            importService: _FakePortfolioCvImportService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Deselect All (all are initially selected)
      await tester.tap(find.byKey(const Key('btn_toggle_select_all')));
      await tester.pumpAndSettle();

      expect(find.text('Select All'), findsOneWidget);
      expect(
          find.text('Select Projects (0 / ${samplePortfolio.projects.length})'),
          findsOneWidget);

      // Tap Select All
      await tester.tap(find.byKey(const Key('btn_toggle_select_all')));
      await tester.pumpAndSettle();

      expect(find.text('Deselect All'), findsOneWidget);
      expect(
          find.text(
              'Select Projects (${samplePortfolio.projects.length} / ${samplePortfolio.projects.length})'),
          findsOneWidget);
    });

    testWidgets(
        'TEST-CV-UI-04: Displays loading state and success banner upon import completion',
        (tester) async {
      PortfolioCvImportResult? capturedResult;
      final fakeService = _FakePortfolioCvImportService(
        delay: const Duration(milliseconds: 300),
      );

      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioCvImportSheet(
            portfolio: samplePortfolio,
            importService: fakeService,
            onImportSuccess: (res) => capturedResult = res,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirm_cv_import')));
      await tester.pump(); // Start import

      expect(find.byKey(const Key('import_loading_indicator')), findsOneWidget);

      await tester.pumpAndSettle(); // Finish import

      expect(find.byKey(const Key('import_success_banner')), findsOneWidget);
      expect(find.text('Projects Successfully Imported!'), findsOneWidget);
      expect(find.byKey(const Key('btn_done_cv_import')), findsOneWidget);
      expect(capturedResult, isNotNull);
    });

    testWidgets(
        'TEST-CV-UI-05: Displays access denied banner when user is not authorized',
        (tester) async {
      final fakeService = _FakePortfolioCvImportService(shouldDenyAccess: true);

      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioCvImportSheet(
            portfolio: samplePortfolio,
            importService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirm_cv_import')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import_denied_banner')), findsOneWidget);
      expect(find.text('Import Access Denied'), findsOneWidget);
    });

    testWidgets(
        'TEST-CV-UI-06: Displays error banner when import service fails',
        (tester) async {
      final fakeService = _FakePortfolioCvImportService(shouldFail: true);

      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioCvImportSheet(
            portfolio: samplePortfolio,
            importService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirm_cv_import')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import_error_banner')), findsOneWidget);
      expect(find.text('Import Failed'), findsOneWidget);
    });

    testWidgets(
        'TEST-CV-UI-07: Preview screen renders Export PDF and Import to CV buttons in live preview mode',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioTemplateSelectionPreviewScreen(
            initialPortfolio: samplePortfolio,
            initialPreviewMode: true,
            currentUserId: samplePortfolio.ownerLearningProfileId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('export_portfolio_pdf_button')), findsOneWidget);
      expect(find.byKey(const Key('import_to_cv_button')), findsOneWidget);
      expect(find.byKey(const Key('back_to_templates_button')), findsOneWidget);
    });
  });
}
