import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:andril_mobile/features/learning/portfolio_maker/domain/entities/portfolio_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/services/i_portfolio_pdf_export_service.dart';

/// Core PDF document generator for Learning Portfolio per ANDRIL LRN-06 & PORT-01..05.
///
/// Features:
/// 1. Supports Developer, Creative, and Professional template layouts.
/// 2. Multipage generation with running headers and "Page X of Y" pagination.
/// 3. Preserves project ordering, titles, descriptions, media URLs, and external links.
/// 4. Empty-project placeholder to protect against zero-content page crashes.
/// 5. Overflow and unicode protection for long text descriptions.
class PortfolioPdfGenerator {
  const PortfolioPdfGenerator();

  /// Generates a valid PDF document as a raw byte array in memory.
  Future<Uint8List> generate(
    LearningPortfolio portfolio, {
    PortfolioPdfExportOptions? options,
  }) async {
    final opts = options ?? PortfolioPdfExportOptions.fromPortfolio(portfolio);

    if (portfolio.title.trim().isEmpty) {
      throw const PortfolioPdfExportException(
        'Cannot generate Portfolio PDF: Title is required.',
      );
    }

    final doc = pw.Document(
      title: opts.customFileName ?? portfolio.title,
      author: portfolio.ownerLearningProfileId,
      creator: 'ANDRIL Portfolio Maker (LRN-06)',
      subject: portfolio.title,
    );

    final template = opts.template;

    switch (template) {
      case PortfolioTemplate.developer:
        _buildDeveloperDocument(doc, portfolio, opts);
        break;
      case PortfolioTemplate.creative:
        _buildCreativeDocument(doc, portfolio, opts);
        break;
      case PortfolioTemplate.professional:
        _buildProfessionalDocument(doc, portfolio, opts);
        break;
    }

    try {
      final bytes = await doc.save();
      if (bytes.isEmpty) {
        throw const PortfolioPdfExportException(
            'Generated PDF bytes are empty.');
      }
      return bytes;
    } catch (e) {
      if (e is PortfolioPdfExportException) rethrow;
      throw PortfolioPdfExportException('Failed to compile PDF document', e);
    }
  }

  /// Generates a valid PDF document with metadata (bytes and exact page count).
  Future<({Uint8List bytes, int pageCount})> generateWithMetadata(
    LearningPortfolio portfolio, {
    PortfolioPdfExportOptions? options,
  }) async {
    final opts = options ?? PortfolioPdfExportOptions.fromPortfolio(portfolio);

    if (portfolio.title.trim().isEmpty) {
      throw const PortfolioPdfExportException(
        'Cannot generate Portfolio PDF: Title is required.',
      );
    }

    final doc = pw.Document(
      title: opts.customFileName ?? portfolio.title,
      author: portfolio.ownerLearningProfileId,
      creator: 'ANDRIL Portfolio Maker (LRN-06)',
      subject: portfolio.title,
    );

    final template = opts.template;

    switch (template) {
      case PortfolioTemplate.developer:
        _buildDeveloperDocument(doc, portfolio, opts);
        break;
      case PortfolioTemplate.creative:
        _buildCreativeDocument(doc, portfolio, opts);
        break;
      case PortfolioTemplate.professional:
        _buildProfessionalDocument(doc, portfolio, opts);
        break;
    }

    try {
      final pageCount = doc.document.pdfPageList.pages.length;
      final bytes = await doc.save();
      if (bytes.isEmpty) {
        throw const PortfolioPdfExportException(
            'Generated PDF bytes are empty.');
      }
      return (bytes: bytes, pageCount: pageCount);
    } catch (e) {
      if (e is PortfolioPdfExportException) rethrow;
      throw PortfolioPdfExportException('Failed to compile PDF document', e);
    }
  }

  // ===========================================================================
  // TEMPLATE 1: DEVELOPER (Tech Blue Accent, Code Hierarchy, Badges)
  // ===========================================================================

  void _buildDeveloperDocument(
    pw.Document doc,
    LearningPortfolio portfolio,
    PortfolioPdfExportOptions opts,
  ) {
    const techBlue = PdfColor.fromInt(0xFF2563EB);
    const lightBadge = PdfColor.fromInt(0xFFEFF6FF);
    const darkHeader = PdfColor.fromInt(0xFF0F172A);
    const bodyText = PdfColor.fromInt(0xFF334155);
    const codeMuted = PdfColor.fromInt(0xFF64748B);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16.0),
            padding: const pw.EdgeInsets.all(16.0),
            decoration: pw.BoxDecoration(
              color: darkHeader,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8.0)),
              border: pw.Border.all(color: techBlue, width: 1.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '// DEVELOPER PORTFOLIO',
                      style: const pw.TextStyle(
                        color: techBlue,
                        fontSize: 10.0,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: const pw.BoxDecoration(
                        color: lightBadge,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(4.0)),
                      ),
                      child: pw.Text(
                        'PRIVATE DRAFT',
                        style: const pw.TextStyle(
                          color: techBlue,
                          fontSize: 8.0,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6.0),
                pw.Text(
                  _cleanText(portfolio.title),
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18.0,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4.0),
                pw.Text(
                  'Module: ${portfolio.module.toUpperCase()} • Projects: ${portfolio.projects.length} • Updated: ${_formatDate(portfolio.updatedAt)}',
                  style: const pw.TextStyle(
                    color: codeMuted,
                    fontSize: 9.0,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) => _buildStandardFooter(context),
        build: (pw.Context context) => [
          if (portfolio.projects.isEmpty)
            _buildEmptyProjectsPlaceholder(
                'No projects documented in this developer portfolio.')
          else ...[
            _buildDeveloperSectionHeader(
                'SHOWCASE PROJECTS (${portfolio.projects.length})', techBlue),
            pw.SizedBox(height: 10.0),
            ...portfolio.projects.asMap().entries.map((entry) {
              final idx = entry.key;
              final project = entry.value;
              return _buildDeveloperProjectCard(
                idx + 1,
                project,
                techBlue,
                lightBadge,
                bodyText,
                opts,
              );
            }),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildDeveloperSectionHeader(String title, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6.0),
      child: pw.Row(
        children: [
          pw.Text(
            '> ',
            style: pw.TextStyle(
              fontSize: 13.0,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
          pw.Text(
            _cleanText(title),
            style: pw.TextStyle(
              fontSize: 12.0,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDeveloperProjectCard(
    int index,
    PortfolioProject project,
    PdfColor accent,
    PdfColor lightBadge,
    PdfColor bodyColor,
    PortfolioPdfExportOptions opts,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14.0),
      padding: const pw.EdgeInsets.all(14.0),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6.0)),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 7.0, vertical: 2.0),
                decoration: pw.BoxDecoration(
                  color: lightBadge,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4.0)),
                  border: pw.Border.all(color: accent, width: 0.5),
                ),
                child: pw.Text(
                  'PROJECT #$index',
                  style: pw.TextStyle(
                    color: accent,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8.0),
              pw.Expanded(
                child: pw.Text(
                  _cleanText(project.title ?? 'Untitled Project'),
                  style: const pw.TextStyle(
                    fontSize: 12.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          if (project.description != null &&
              project.description!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 6.0),
            pw.Text(
              _cleanText(project.description!),
              style: pw.TextStyle(
                fontSize: 9.5,
                color: bodyColor,
                lineSpacing: 1.25,
              ),
            ),
          ],
          if (opts.includeExternalLinks &&
              project.externalLinks.isNotEmpty) ...[
            pw.SizedBox(height: 8.0),
            pw.Text(
              '// Repositories & External Links:',
              style: const pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF64748B),
              ),
            ),
            pw.SizedBox(height: 2.0),
            ...project.externalLinks.map((link) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8.0, top: 1.0),
                child: pw.Text(
                  '-> ${_cleanText(link)}',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: accent,
                  ),
                ),
              );
            }),
          ],
          if (opts.includeMediaReferences &&
              project.mediaReferences.isNotEmpty) ...[
            pw.SizedBox(height: 6.0),
            pw.Text(
              '// Media & Demonstrations:',
              style: const pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF64748B),
              ),
            ),
            pw.SizedBox(height: 2.0),
            ...project.mediaReferences.map((media) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8.0, top: 1.0),
                child: pw.Text(
                  '* ${_cleanText(media)}',
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColor.fromInt(0xFF475569),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // TEMPLATE 2: CREATIVE (Expressive Violet Accent, Media-First Layout)
  // ===========================================================================

  void _buildCreativeDocument(
    pw.Document doc,
    LearningPortfolio portfolio,
    PortfolioPdfExportOptions opts,
  ) {
    const violetAccent = PdfColor.fromInt(0xFF7C3AED);
    const lightViolet = PdfColor.fromInt(0xFFF3E8FF);
    const darkHeading = PdfColor.fromInt(0xFF1E1B4B);
    const bodyText = PdfColor.fromInt(0xFF374151);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16.0),
            padding: const pw.EdgeInsets.all(16.0),
            decoration: const pw.BoxDecoration(
              color: violetAccent,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(10.0)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'CREATIVE SHOWCASE PORTFOLIO',
                      style: const pw.TextStyle(
                        color: lightViolet,
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 2.0),
                      decoration: const pw.BoxDecoration(
                        color: lightViolet,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(6.0)),
                      ),
                      child: pw.Text(
                        'PRIVATE',
                        style: const pw.TextStyle(
                          color: violetAccent,
                          fontSize: 8.0,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6.0),
                pw.Text(
                  _cleanText(portfolio.title),
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20.0,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4.0),
                pw.Text(
                  'Visual Showcase & Design Focus • ${_formatDate(portfolio.updatedAt)}',
                  style: const pw.TextStyle(
                    color: lightViolet,
                    fontSize: 10.0,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) => _buildStandardFooter(context),
        build: (pw.Context context) => [
          if (portfolio.projects.isEmpty)
            _buildEmptyProjectsPlaceholder(
                'No projects showcase entries added yet.')
          else ...[
            _buildCreativeSectionHeader(
                'Curated Projects & Visual Work', violetAccent),
            pw.SizedBox(height: 10.0),
            ...portfolio.projects.asMap().entries.map((entry) {
              final idx = entry.key;
              final project = entry.value;
              return _buildCreativeProjectCard(
                idx + 1,
                project,
                violetAccent,
                lightViolet,
                darkHeading,
                bodyText,
                opts,
              );
            }),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildCreativeSectionHeader(String title, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6.0),
      child: pw.Row(
        children: [
          pw.Container(
            width: 5.0,
            height: 14.0,
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2.0)),
            ),
          ),
          pw.SizedBox(width: 8.0),
          pw.Text(
            _cleanText(title),
            style: pw.TextStyle(
              fontSize: 13.0,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCreativeProjectCard(
    int index,
    PortfolioProject project,
    PdfColor accent,
    PdfColor lightBadge,
    PdfColor headingColor,
    PdfColor bodyColor,
    PortfolioPdfExportOptions opts,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14.0),
      padding: const pw.EdgeInsets.all(14.0),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8.0)),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE9D5FF)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 22.0,
                height: 22.0,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: lightBadge,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(11.0)),
                ),
                child: pw.Text(
                  '$index',
                  style: pw.TextStyle(
                    color: accent,
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8.0),
              pw.Expanded(
                child: pw.Text(
                  _cleanText(project.title ?? 'Untitled Project'),
                  style: pw.TextStyle(
                    fontSize: 13.0,
                    fontWeight: pw.FontWeight.bold,
                    color: headingColor,
                  ),
                ),
              ),
            ],
          ),
          if (project.description != null &&
              project.description!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 6.0),
            pw.Text(
              _cleanText(project.description!),
              style: pw.TextStyle(
                fontSize: 9.5,
                color: bodyColor,
                lineSpacing: 1.3,
              ),
            ),
          ],
          if (opts.includeMediaReferences &&
              project.mediaReferences.isNotEmpty) ...[
            pw.SizedBox(height: 8.0),
            pw.Container(
              padding: const pw.EdgeInsets.all(8.0),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFFAF5FF),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6.0)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Media Demonstrations (${project.mediaReferences.length}):',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  pw.SizedBox(height: 2.0),
                  ...project.mediaReferences.map((media) {
                    return pw.Text(
                      '* ${_cleanText(media)}',
                      style: const pw.TextStyle(
                        fontSize: 8.0,
                        color: PdfColor.fromInt(0xFF581C87),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          if (opts.includeExternalLinks &&
              project.externalLinks.isNotEmpty) ...[
            pw.SizedBox(height: 6.0),
            pw.Wrap(
              spacing: 8.0,
              runSpacing: 3.0,
              children: project.externalLinks.map((link) {
                return pw.Text(
                  'Link: ${_cleanText(link)}',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: accent,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // TEMPLATE 3: PROFESSIONAL (Corporate Navy, Formal Dividers, Milestones)
  // ===========================================================================

  void _buildProfessionalDocument(
    pw.Document doc,
    LearningPortfolio portfolio,
    PortfolioPdfExportOptions opts,
  ) {
    const navyAccent = PdfColor.fromInt(0xFF0F172A);
    const slateAccent = PdfColor.fromInt(0xFF334155);
    const bodyText = PdfColor.fromInt(0xFF1E293B);
    const mutedText = PdfColor.fromInt(0xFF64748B);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36.0, vertical: 32.0),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16.0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'EXECUTIVE LEARNING PORTFOLIO',
                      style: const pw.TextStyle(
                        color: slateAccent,
                        fontSize: 10.0,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.Text(
                      'CONFIDENTIAL & PRIVATE',
                      style: const pw.TextStyle(
                        color: mutedText,
                        fontSize: 8.0,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4.0),
                pw.Text(
                  _cleanText(portfolio.title.toUpperCase()),
                  style: const pw.TextStyle(
                    color: navyAccent,
                    fontSize: 18.0,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: 2.0),
                pw.Text(
                  'Owner ID: ${_cleanText(portfolio.ownerLearningProfileId)} • Last Modified: ${_formatDate(portfolio.updatedAt)}',
                  style: const pw.TextStyle(
                    color: mutedText,
                    fontSize: 9.0,
                  ),
                ),
                pw.SizedBox(height: 8.0),
                pw.Container(
                  height: 1.5,
                  color: navyAccent,
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) => _buildStandardFooter(context),
        build: (pw.Context context) => [
          if (portfolio.projects.isEmpty)
            _buildEmptyProjectsPlaceholder(
                'No executive deliverables recorded in this portfolio.')
          else ...[
            _buildProfessionalSectionHeader(
                'KEY DELIVERABLES & ACCOMPLISHMENTS', navyAccent),
            pw.SizedBox(height: 8.0),
            ...portfolio.projects.asMap().entries.map((entry) {
              final idx = entry.key;
              final project = entry.value;
              return _buildProfessionalProjectCard(
                idx + 1,
                project,
                navyAccent,
                bodyText,
                mutedText,
                opts,
              );
            }),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildProfessionalSectionHeader(String title, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4.0, bottom: 4.0),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _cleanText(title),
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: accent,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 3.0),
          pw.Container(
            height: 0.75,
            color: const PdfColor.fromInt(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProfessionalProjectCard(
    int index,
    PortfolioProject project,
    PdfColor navyAccent,
    PdfColor bodyColor,
    PdfColor mutedColor,
    PortfolioPdfExportOptions opts,
  ) {
    final numStr = index < 10 ? '0$index' : '$index';
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12.0),
      padding: const pw.EdgeInsets.only(bottom: 10.0),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom:
              pw.BorderSide(color: PdfColor.fromInt(0xFFF1F5F9), width: 1.0),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$numStr.',
                style: pw.TextStyle(
                  fontSize: 11.5,
                  fontWeight: pw.FontWeight.bold,
                  color: navyAccent,
                ),
              ),
              pw.SizedBox(width: 8.0),
              pw.Expanded(
                child: pw.Text(
                  _cleanText(project.title ?? 'Untitled Deliverable'),
                  style: pw.TextStyle(
                    fontSize: 11.5,
                    fontWeight: pw.FontWeight.bold,
                    color: navyAccent,
                  ),
                ),
              ),
            ],
          ),
          if (project.description != null &&
              project.description!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4.0),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20.0),
              child: pw.Text(
                _cleanText(project.description!),
                style: pw.TextStyle(
                  fontSize: 9.0,
                  color: bodyColor,
                  lineSpacing: 1.3,
                ),
              ),
            ),
          ],
          if (opts.includeExternalLinks &&
              project.externalLinks.isNotEmpty) ...[
            pw.SizedBox(height: 4.0),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20.0),
              child: pw.Text(
                'References: ${project.externalLinks.map(_cleanText).join('  |  ')}',
                style: pw.TextStyle(
                  fontSize: 8.0,
                  color: mutedColor,
                ),
              ),
            ),
          ],
          if (opts.includeMediaReferences &&
              project.mediaReferences.isNotEmpty) ...[
            pw.SizedBox(height: 2.0),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20.0),
              child: pw.Text(
                'Media: ${project.mediaReferences.map(_cleanText).join('  |  ')}',
                style: pw.TextStyle(
                  fontSize: 8.0,
                  color: mutedColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // SHARED HELPERS
  // ===========================================================================

  pw.Widget _buildEmptyProjectsPlaceholder(String message) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 36.0),
      alignment: pw.Alignment.center,
      child: pw.Text(
        message,
        style: const pw.TextStyle(
          fontSize: 10.5,
          color: PdfColors.grey600,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  pw.Widget _buildStandardFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14.0),
      padding: const pw.EdgeInsets.only(top: 6.0),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Private & Confidential - ANDRIL Portfolio Maker (LRN-06)',
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final year = dt.year;
    final month = dt.month < 10 ? '0${dt.month}' : '${dt.month}';
    final day = dt.day < 10 ? '0${dt.day}' : '${dt.day}';
    return '$year-$month-$day';
  }

  /// Cleans unicode text to avoid PDF font crashes or unprintable glyphs.
  String _cleanText(String input) {
    return input
        .replaceAll('•', '*')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");
  }
}
