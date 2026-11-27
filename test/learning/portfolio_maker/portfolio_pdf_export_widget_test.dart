import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_pdf_export_result.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/services/i_portfolio_pdf_export_service.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/presentation/widgets/portfolio_pdf_export_sheet.dart';

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

/// Fake service for deterministic UI widget testing.
class _FakePortfolioPdfExportService implements IPortfolioPdfExportService {
  final bool shouldFail;
  final bool shouldDenyAccess;
  final Duration delay;
  PortfolioPdfExportOptions? capturedOptions;

  _FakePortfolioPdfExportService({
    this.shouldFail = false,
    this.shouldDenyAccess = false,
    this.delay = Duration.zero,
  });

  @override
  Future<PortfolioPdfExportResult> exportPortfolioToPdf(
    LearningPortfolio portfolio, {
    PortfolioPdfExportOptions? options,
    String? currentUserId,
  }) async {
    capturedOptions = options;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldDenyAccess) {
      throw const PortfolioPdfExportAccessDeniedException(
        'Session is revoked or expired. Please re-authenticate.',
      );
    }
    if (shouldFail) {
      throw const PortfolioPdfExportException('Disk full or generation error.');
    }
    return PortfolioPdfExportResult(
      pdfBytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E]),
      fileName: 'My_Portfolio_export.pdf',
      pageCount: 2,
      fileSizeBytes: 245000,
      filePath: '/tmp/My_Portfolio_export.pdf',
      generatedAt: DateTime(2026, 11, 26),
      templateUsed: options?.template ?? portfolio.template,
      projectCount: portfolio.projects.length,
    );
  }

  @override
  Future<Uint8List> generatePdfBytes(
    LearningPortfolio portfolio, {
    PortfolioPdfExportOptions? options,
  }) async {
    return Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]);
  }

  @override
  Future<int> cleanupTempFiles() async => 0;
}

void main() {
  group('Portfolio PDF Export Widget Tests (LRN-06 & PORT-01..05)', () {
    late LearningPortfolio samplePortfolio;

    setUp(() {
      samplePortfolio = LearningPortfolio.syntheticSample();
    });

    testWidgets(
        'TEST-UI-01: Export sheet renders title, summary, and action button',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioPdfExportSheet(
            portfolio: samplePortfolio,
            exportService: _FakePortfolioPdfExportService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export Portfolio as PDF'), findsOneWidget);
      expect(find.byKey(const Key('btn_confirm_export')), findsOneWidget);
      expect(find.byKey(const Key('toggle_external_links')), findsOneWidget);
      expect(find.byKey(const Key('toggle_media_references')), findsOneWidget);
      expect(find.text('Portfolio Summary'), findsOneWidget);
    });

    testWidgets('TEST-UI-02: Toggling links and media updates state correctly',
        (tester) async {
      final fakeService = _FakePortfolioPdfExportService();

      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioPdfExportSheet(
            portfolio: samplePortfolio,
            exportService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap toggle switches
      await tester.tap(find.byKey(const Key('toggle_external_links')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle_media_references')));
      await tester.pumpAndSettle();

      // Trigger export
      await tester.tap(find.byKey(const Key('btn_confirm_export')));
      await tester.pumpAndSettle();

      expect(fakeService.capturedOptions?.includeExternalLinks, isFalse);
      expect(fakeService.capturedOptions?.includeMediaReferences, isFalse);
    });

    testWidgets(
        'TEST-UI-03: Displays loading state while export is in progress',
        (tester) async {
      final fakeService = _FakePortfolioPdfExportService(
        delay: const Duration(milliseconds: 500),
      );

      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioPdfExportSheet(
            portfolio: samplePortfolio,
            exportService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirm_export')));
      await tester.pump(); // Start export

      expect(find.byKey(const Key('export_loading_indicator')), findsOneWidget);

      await tester.pumpAndSettle(); // Finish export
      expect(find.byKey(const Key('export_success_banner')), findsOneWidget);
    });

    testWidgets(
        'TEST-UI-04: Displays success banner with metadata upon export completion',
        (tester) async {
      PortfolioPdfExportResult? capturedResult;

      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioPdfExportSheet(
            portfolio: samplePortfolio,
            exportService: _FakePortfolioPdfExportService(),
            onExportSuccess: (res) => capturedResult = res,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirm_export')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('export_success_banner')), findsOneWidget);
      expect(find.text('Portfolio PDF Export Successful!'), findsOneWidget);
      expect(find.byKey(const Key('btn_close_export')), findsOneWidget);
      expect(capturedResult, isNotNull);
      expect(capturedResult!.pageCount, equals(2));
    });

    testWidgets(
        'TEST-UI-05: Displays access denied banner when session is invalid',
        (tester) async {
      final fakeService =
          _FakePortfolioPdfExportService(shouldDenyAccess: true);

      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioPdfExportSheet(
            portfolio: samplePortfolio,
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
    });

    testWidgets('TEST-UI-06: Displays error banner when export fails',
        (tester) async {
      final fakeService = _FakePortfolioPdfExportService(shouldFail: true);

      await tester.pumpWidget(
        _buildTestHarness(
          child: PortfolioPdfExportSheet(
            portfolio: samplePortfolio,
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
        'TEST-UI-07: Responsive across 320dp, 360dp, and 412dp viewports',
        (tester) async {
      final viewports = [
        const Size(320, 600),
        const Size(360, 780),
        const Size(412, 915),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          _buildTestHarness(
            child: PortfolioPdfExportSheet(
              portfolio: samplePortfolio,
              exportService: _FakePortfolioPdfExportService(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('btn_confirm_export')), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
