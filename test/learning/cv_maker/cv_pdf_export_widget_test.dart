import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/entities/cv_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/entities/cv_pdf_export_result.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/services/i_cv_pdf_export_service.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/widgets/cv_pdf_export_sheet.dart';

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
}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Scaffold(
      body: child,
    ),
  );
}

/// Fake service for deterministic UI widget testing.
class _FakeCvPdfExportService implements ICvPdfExportService {
  final bool shouldFail;
  final bool shouldDenyAccess;
  final Duration delay;
  CvPdfExportOptions? capturedOptions;

  _FakeCvPdfExportService({
    this.shouldFail = false,
    this.shouldDenyAccess = false,
    this.delay = Duration.zero,
  });

  @override
  Future<CvPdfExportResult> exportCvToPdf(
    CvDraftData draft, {
    CvPdfExportOptions? options,
    String? currentUserId,
  }) async {
    capturedOptions = options;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldDenyAccess) {
      throw const CvPdfExportAccessDeniedException(
        'Session is revoked or expired. Please re-authenticate.',
      );
    }
    if (shouldFail) {
      throw const CvPdfExportException('Disk full or generation error.');
    }
    return CvPdfExportResult(
      pdfBytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E]),
      fileName: 'My_Professional_CV_export.pdf',
      pageCount: 2,
      fileSizeBytes: 245000,
      filePath: '/tmp/My_Professional_CV_export.pdf',
      generatedAt: DateTime(2026, 11, 26),
      templateUsed: options?.template ?? draft.selectedTemplate,
      contactInfoIncluded: options?.includeContactInfo ?? true,
    );
  }

  @override
  Future<Uint8List> generatePdfBytes(
    CvDraftData draft, {
    CvPdfExportOptions? options,
  }) async {
    return Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]);
  }

  @override
  Future<int> cleanupTempFiles() async => 0;
}

void main() {
  group('CV PDF Export Widget Tests (LRN-05 & CV-01..05)', () {
    late CvDraftData sampleDraft;

    setUp(() {
      sampleDraft = CvDraftData.syntheticSample();
    });

    testWidgets(
        'TEST-UI-01: Export sheet renders title, summary, and action button',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvPdfExportSheet(
            draft: sampleDraft,
            exportService: _FakeCvPdfExportService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export CV as PDF'), findsOneWidget);
      expect(find.textContaining('Modern'), findsOneWidget);
      expect(find.text('Include Contact Information'), findsOneWidget);
      expect(find.text('Document Summary'), findsOneWidget);
      expect(find.byKey(const Key('btn_confirm_export')), findsOneWidget);
      expect(find.byKey(const Key('consent_contact_toggle')), findsOneWidget);
    });

    testWidgets('TEST-UI-02: Toggling privacy consent switch updates option',
        (tester) async {
      _setupTestViewport(tester);
      final fakeService = _FakeCvPdfExportService();

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvPdfExportSheet(
            draft: sampleDraft,
            exportService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch is initially ON because sample draft has contacts
      final switchFinder = find.byKey(const Key('consent_contact_toggle'));
      expect(switchFinder, findsOneWidget);

      // Tap switch to turn OFF
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Tap confirm export
      await tester.tap(find.byKey(const Key('btn_confirm_export')));
      await tester.pumpAndSettle();

      expect(fakeService.capturedOptions?.includeContactInfo, isFalse);
    });

    testWidgets('TEST-UI-03: Loading indicator is shown while generating PDF',
        (tester) async {
      _setupTestViewport(tester);
      final fakeService = _FakeCvPdfExportService(
        delay: const Duration(milliseconds: 200),
      );

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvPdfExportSheet(
            draft: sampleDraft,
            exportService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap export
      await tester.tap(find.byKey(const Key('btn_confirm_export')));
      await tester.pump(); // Advance to loading state

      expect(find.byKey(const Key('export_loading_indicator')), findsOneWidget);
      expect(find.text('Generating PDF Document...'), findsOneWidget);

      await tester.pumpAndSettle(); // Settle delayed future
      expect(find.byKey(const Key('export_loading_indicator')), findsNothing);
      expect(find.byKey(const Key('export_success_banner')), findsOneWidget);
    });

    testWidgets(
        'TEST-UI-04: Successful export displays success banner and metadata',
        (tester) async {
      _setupTestViewport(tester);
      final fakeService = _FakeCvPdfExportService();
      CvPdfExportResult? capturedResult;

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvPdfExportSheet(
            draft: sampleDraft,
            exportService: fakeService,
            onExportSuccess: (r) => capturedResult = r,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirm_export')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('export_success_banner')), findsOneWidget);
      expect(find.text('PDF Export Successful!'), findsOneWidget);
      expect(find.text('My_Professional_CV_export.pdf'), findsOneWidget);
      expect(find.text('2 page(s)'), findsOneWidget);
      expect(find.byKey(const Key('btn_close_export')), findsOneWidget);
      expect(capturedResult, isNotNull);
    });

    testWidgets('TEST-UI-05: Access denied error displays export_denied_banner',
        (tester) async {
      _setupTestViewport(tester);
      final fakeService = _FakeCvPdfExportService(shouldDenyAccess: true);

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvPdfExportSheet(
            draft: sampleDraft,
            exportService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirm_export')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('export_denied_banner')), findsOneWidget);
      expect(find.text('Export Access Denied'), findsOneWidget);
      expect(find.byKey(const Key('btn_retry_export')), findsOneWidget);
      expect(find.byKey(const Key('btn_cancel_export')), findsOneWidget);
    });

    testWidgets(
        'TEST-UI-06: General error displays export_error_banner and allows retry',
        (tester) async {
      _setupTestViewport(tester);
      final fakeService = _FakeCvPdfExportService(shouldFail: true);

      await tester.pumpWidget(
        _buildTestHarness(
          child: CvPdfExportSheet(
            draft: sampleDraft,
            exportService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirm_export')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('export_error_banner')), findsOneWidget);
      expect(find.text('Export Failed'), findsOneWidget);
      expect(find.byKey(const Key('btn_retry_export')), findsOneWidget);
    });

    testWidgets(
        'TEST-UI-07: Preview screen renders export_pdf_button and opens sheet',
        (tester) async {
      _setupTestViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: LearningTheme.theme,
          home: CvTemplateSelectionPreviewScreen(
            initialDraft: sampleDraft,
            initialPreviewMode: true,
            exportService: _FakeCvPdfExportService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final exportBtn = find.byKey(const Key('export_pdf_button'));
      await tester.ensureVisible(exportBtn);
      await tester.pumpAndSettle();

      expect(exportBtn, findsOneWidget);
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      // Modal sheet should now be visible
      expect(find.text('Export CV as PDF'), findsOneWidget);
      expect(find.byKey(const Key('btn_confirm_export')), findsOneWidget);
    });

    testWidgets(
        'TEST-UI-08: Responsive viewport test at 320dp, 360dp, 412dp without overflow',
        (tester) async {
      final viewports = [
        const Size(320, 640),
        const Size(360, 800),
        const Size(412, 915),
      ];

      for (final vp in viewports) {
        _setupTestViewport(tester, size: vp);

        await tester.pumpWidget(
          _buildTestHarness(
            size: vp,
            child: CvPdfExportSheet(
              draft: sampleDraft,
              exportService: _FakeCvPdfExportService(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Export CV as PDF'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
