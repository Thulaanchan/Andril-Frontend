import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:andril_mobile/features/learning/cv_maker/domain/entities/cv_pdf_export_options.dart';
import 'package:andril_mobile/features/learning/cv_maker/domain/services/i_cv_pdf_export_service.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';

/// Core PDF document generator for CV Maker per ANDRIL LRN-05 & CV-01..05.
///
/// Features:
/// 1. Supports Modern, Professional, and Creative template layouts.
/// 2. Multipage generation with running headers and "Page X of Y" pagination.
/// 3. Strict contact information gating based on explicit user consent (CV-03).
/// 4. Renders all 7 structured CV sections.
/// 5. Overflow and unicode protection for long text descriptions.
class CvPdfGenerator {
  const CvPdfGenerator();

  /// Generates a valid PDF document as a raw byte array in memory.
  Future<Uint8List> generate(
    CvDraftData draft, {
    CvPdfExportOptions? options,
  }) async {
    final opts = options ?? CvPdfExportOptions.fromDraft(draft);

    if (draft.fullName.trim().isEmpty) {
      throw const CvPdfExportException(
        'Cannot generate CV PDF: Full name is required.',
      );
    }

    final doc = pw.Document(
      title: opts.customFileName ?? draft.title,
      author: draft.fullName,
      creator: 'ANDRIL CV Maker (LRN-05)',
      subject: draft.headline,
    );

    final template = opts.template;

    switch (template) {
      case CvTemplate.modern:
        _buildModernDocument(doc, draft, opts);
        break;
      case CvTemplate.professional:
        _buildProfessionalDocument(doc, draft, opts);
        break;
      case CvTemplate.creative:
        _buildCreativeDocument(doc, draft, opts);
        break;
    }

    try {
      final bytes = await doc.save();
      if (bytes.isEmpty) {
        throw const CvPdfExportException('Generated PDF bytes are empty.');
      }
      return bytes;
    } catch (e) {
      if (e is CvPdfExportException) rethrow;
      throw CvPdfExportException('Failed to compile PDF document', e);
    }
  }

  /// Generates a valid PDF document with metadata (bytes and exact page count).
  Future<({Uint8List bytes, int pageCount})> generateWithMetadata(
    CvDraftData draft, {
    CvPdfExportOptions? options,
  }) async {
    final opts = options ?? CvPdfExportOptions.fromDraft(draft);

    if (draft.fullName.trim().isEmpty) {
      throw const CvPdfExportException(
        'Cannot generate CV PDF: Full name is required.',
      );
    }

    final doc = pw.Document(
      title: opts.customFileName ?? draft.title,
      author: draft.fullName,
      creator: 'ANDRIL CV Maker (LRN-05)',
      subject: draft.headline,
    );

    final template = opts.template;

    switch (template) {
      case CvTemplate.modern:
        _buildModernDocument(doc, draft, opts);
        break;
      case CvTemplate.professional:
        _buildProfessionalDocument(doc, draft, opts);
        break;
      case CvTemplate.creative:
        _buildCreativeDocument(doc, draft, opts);
        break;
    }

    try {
      final pageCount = doc.document.pdfPageList.pages.length;
      final bytes = await doc.save();
      if (bytes.isEmpty) {
        throw const CvPdfExportException('Generated PDF bytes are empty.');
      }
      return (bytes: bytes, pageCount: pageCount);
    } catch (e) {
      if (e is CvPdfExportException) rethrow;
      throw CvPdfExportException('Failed to compile PDF document', e);
    }
  }

  // ===========================================================================
  // TEMPLATE 1: MODERN (Cyan / Teal Accent, Structured Cards, Tag Pills)
  // ===========================================================================

  void _buildModernDocument(
    pw.Document doc,
    CvDraftData draft,
    CvPdfExportOptions opts,
  ) {
    const accent = PdfColor.fromInt(0xFF00B4D8);
    const lightBadge = PdfColor.fromInt(0xFFE0F7FA);
    const darkHeading = PdfColor.fromInt(0xFF0F172A);
    const bodyText = PdfColor.fromInt(0xFF334155);
    const mutedText = PdfColor.fromInt(0xFF64748B);

    final contactItems = _extractPermittedContacts(draft, opts);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
        header: (pw.Context context) {
          // Top teal accent band with candidate name
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 14.0),
            padding: const pw.EdgeInsets.all(16.0),
            decoration: const pw.BoxDecoration(
              color: accent,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8.0)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _cleanText(draft.fullName),
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20.0,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3.0),
                pw.Text(
                  _cleanText(draft.headline),
                  style: const pw.TextStyle(
                    color: lightBadge,
                    fontSize: 12.0,
                  ),
                ),
                if (contactItems.isNotEmpty) ...[
                  pw.SizedBox(height: 8.0),
                  pw.Wrap(
                    spacing: 12.0,
                    runSpacing: 4.0,
                    children: contactItems.map((item) {
                      return pw.Text(
                        _cleanText(item),
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9.5,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        },
        footer: (pw.Context context) => _buildStandardFooter(context),
        build: (pw.Context context) => [
          if (_isAllBodyEmpty(draft))
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 24.0),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Profile information pending completion in CV Editor.',
                style: const pw.TextStyle(
                  fontSize: 10.0,
                  color: mutedText,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          // Section 1: Executive Summary
          if (draft.summary.trim().isNotEmpty) ...[
            _buildModernSectionHeader('Executive Summary', accent),
            pw.SizedBox(height: 4.0),
            pw.Text(
              _cleanText(draft.summary),
              style: const pw.TextStyle(
                fontSize: 10.5,
                color: bodyText,
                lineSpacing: 1.3,
              ),
            ),
            pw.SizedBox(height: 14.0),
          ],

          // Section 2: Skills / Competencies
          if (draft.skills.isNotEmpty) ...[
            _buildModernSectionHeader('Key Competencies & Skills', accent),
            pw.SizedBox(height: 6.0),
            pw.Wrap(
              spacing: 6.0,
              runSpacing: 5.0,
              children: draft.skills.map((skill) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 3.0,
                  ),
                  decoration: pw.BoxDecoration(
                    color: lightBadge,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4.0)),
                    border: pw.Border.all(color: accent, width: 0.5),
                  ),
                  child: pw.Text(
                    _cleanText(skill),
                    style: const pw.TextStyle(
                      color: PdfColor.fromInt(0xFF0077B6),
                      fontSize: 9.0,
                    ),
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 14.0),
          ],

          // Section 3: Professional Experience
          if (draft.experiences.isNotEmpty) ...[
            _buildModernSectionHeader('Professional Experience', accent),
            pw.SizedBox(height: 6.0),
            ...draft.experiences.map((exp) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8.0),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          _cleanText(exp.jobTitle),
                          style: const pw.TextStyle(
                            fontSize: 11.0,
                            fontWeight: pw.FontWeight.bold,
                            color: darkHeading,
                          ),
                        ),
                        pw.Text(
                          _cleanText(exp.period),
                          style: const pw.TextStyle(
                            fontSize: 9.0,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      _cleanText(exp.company),
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    if (exp.description.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 2.0),
                      pw.Text(
                        _cleanText(exp.description),
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: bodyText,
                          lineSpacing: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8.0),
          ],

          // Section 4: Education
          if (draft.education.isNotEmpty) ...[
            _buildModernSectionHeader('Education', accent),
            pw.SizedBox(height: 6.0),
            ...draft.education.map((edu) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6.0),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _cleanText(edu.degree),
                          style: const pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                            color: darkHeading,
                          ),
                        ),
                        pw.Text(
                          _cleanText(edu.institution),
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            color: bodyText,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      _cleanText(edu.year),
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8.0),
          ],

          // Section 5: Certifications
          if (draft.certifications.isNotEmpty) ...[
            _buildModernSectionHeader('Certifications & Credentials', accent),
            pw.SizedBox(height: 6.0),
            ...draft.certifications.map((cert) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5.0),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _cleanText(cert.name),
                            style: const pw.TextStyle(
                              fontSize: 10.0,
                              fontWeight: pw.FontWeight.bold,
                              color: darkHeading,
                            ),
                          ),
                          pw.Text(
                            '${_cleanText(cert.issuer)}${cert.credentialId != null && cert.credentialId!.isNotEmpty ? " - ID: ${_cleanText(cert.credentialId!)}" : ""}',
                            style: const pw.TextStyle(
                              fontSize: 9.0,
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Text(
                      _cleanText(cert.year),
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8.0),
          ],

          // Section 6: Projects
          if (draft.projects.isNotEmpty) ...[
            _buildModernSectionHeader('Key Projects', accent),
            pw.SizedBox(height: 6.0),
            ...draft.projects.map((proj) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6.0),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          _cleanText(proj.name),
                          style: const pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                            color: darkHeading,
                          ),
                        ),
                        if (proj.role != null && proj.role!.isNotEmpty)
                          pw.Text(
                            _cleanText(proj.role!),
                            style: const pw.TextStyle(
                              fontSize: 9.0,
                              color: mutedText,
                            ),
                          ),
                      ],
                    ),
                    if (proj.description != null &&
                        proj.description!.isNotEmpty) ...[
                      pw.SizedBox(height: 2.0),
                      pw.Text(
                        _cleanText(proj.description!),
                        style: const pw.TextStyle(
                          fontSize: 9.0,
                          color: bodyText,
                        ),
                      ),
                    ],
                    if (proj.link != null && proj.link!.isNotEmpty) ...[
                      pw.SizedBox(height: 1.0),
                      pw.Text(
                        _cleanText(proj.link!),
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: accent,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8.0),
          ],

          // Section 7: Links
          if (draft.links.isNotEmpty) ...[
            _buildModernSectionHeader('Links & Portfolio', accent),
            pw.SizedBox(height: 4.0),
            pw.Wrap(
              spacing: 12.0,
              runSpacing: 4.0,
              children: draft.links.map((link) {
                return pw.Text(
                  '${_cleanText(link.label)}: ${_cleanText(link.url)}',
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColor.fromInt(0xFF0077B6),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildModernSectionHeader(String title, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 2.0),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4.0,
            height: 12.0,
            color: accent,
          ),
          pw.SizedBox(width: 6.0),
          pw.Text(
            _cleanText(title),
            style: pw.TextStyle(
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TEMPLATE 2: PROFESSIONAL (Corporate Navy, Formal Dividers, Timeless Rules)
  // ===========================================================================

  void _buildProfessionalDocument(
    pw.Document doc,
    CvDraftData draft,
    CvPdfExportOptions opts,
  ) {
    const navyAccent = PdfColor.fromInt(0xFF1E3A8A);
    const darkHeading = PdfColor.fromInt(0xFF0F172A);
    const bodyText = PdfColor.fromInt(0xFF1E293B);
    const mutedText = PdfColor.fromInt(0xFF475569);

    final contactItems = _extractPermittedContacts(draft, opts);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36.0, vertical: 32.0),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12.0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _cleanText(draft.fullName.toUpperCase()),
                  style: const pw.TextStyle(
                    color: navyAccent,
                    fontSize: 19.0,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 2.0),
                pw.Text(
                  _cleanText(draft.headline),
                  style: const pw.TextStyle(
                    color: mutedText,
                    fontSize: 11.5,
                  ),
                ),
                if (contactItems.isNotEmpty) ...[
                  pw.SizedBox(height: 6.0),
                  pw.Text(
                    contactItems.map(_cleanText).join('  |  '),
                    style: const pw.TextStyle(
                      color: bodyText,
                      fontSize: 9.0,
                    ),
                  ),
                ],
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
          if (_isAllBodyEmpty(draft))
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 24.0),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Profile information pending completion in CV Editor.',
                style: const pw.TextStyle(
                  fontSize: 10.0,
                  color: mutedText,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          // Section 1: Executive Summary
          if (draft.summary.trim().isNotEmpty) ...[
            _buildProfessionalSectionHeader('PROFESSIONAL SUMMARY', navyAccent),
            pw.SizedBox(height: 4.0),
            pw.Text(
              _cleanText(draft.summary),
              style: const pw.TextStyle(
                fontSize: 10.0,
                color: bodyText,
                lineSpacing: 1.35,
              ),
            ),
            pw.SizedBox(height: 12.0),
          ],

          // Section 2: Skills
          if (draft.skills.isNotEmpty) ...[
            _buildProfessionalSectionHeader('CORE COMPETENCIES', navyAccent),
            pw.SizedBox(height: 4.0),
            pw.Text(
              draft.skills.map(_cleanText).join('  *  '),
              style: const pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: darkHeading,
                lineSpacing: 1.3,
              ),
            ),
            pw.SizedBox(height: 12.0),
          ],

          // Section 3: Experience
          if (draft.experiences.isNotEmpty) ...[
            _buildProfessionalSectionHeader(
                'PROFESSIONAL EXPERIENCE', navyAccent),
            pw.SizedBox(height: 6.0),
            ...draft.experiences.map((exp) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8.0),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          _cleanText(exp.jobTitle),
                          style: const pw.TextStyle(
                            fontSize: 11.0,
                            fontWeight: pw.FontWeight.bold,
                            color: darkHeading,
                          ),
                        ),
                        pw.Text(
                          _cleanText(exp.period),
                          style: const pw.TextStyle(
                            fontSize: 9.0,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      _cleanText(exp.company),
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: navyAccent,
                      ),
                    ),
                    if (exp.description.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 2.0),
                      pw.Text(
                        _cleanText(exp.description),
                        style: const pw.TextStyle(
                          fontSize: 9.0,
                          color: bodyText,
                          lineSpacing: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8.0),
          ],

          // Section 4: Education
          if (draft.education.isNotEmpty) ...[
            _buildProfessionalSectionHeader(
                'EDUCATION & CREDENTIALS', navyAccent),
            pw.SizedBox(height: 6.0),
            ...draft.education.map((edu) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5.0),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _cleanText(edu.degree),
                          style: const pw.TextStyle(
                            fontSize: 10.0,
                            fontWeight: pw.FontWeight.bold,
                            color: darkHeading,
                          ),
                        ),
                        pw.Text(
                          _cleanText(edu.institution),
                          style: const pw.TextStyle(
                            fontSize: 9.0,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      _cleanText(edu.year),
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8.0),
          ],

          // Section 5: Certifications
          if (draft.certifications.isNotEmpty) ...[
            _buildProfessionalSectionHeader('CERTIFICATIONS', navyAccent),
            pw.SizedBox(height: 4.0),
            ...draft.certifications.map((cert) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4.0),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${_cleanText(cert.name)} - ${_cleanText(cert.issuer)}',
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                        color: bodyText,
                      ),
                    ),
                    pw.Text(
                      _cleanText(cert.year),
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8.0),
          ],

          // Section 6: Projects
          if (draft.projects.isNotEmpty) ...[
            _buildProfessionalSectionHeader('PROJECTS', navyAccent),
            pw.SizedBox(height: 4.0),
            ...draft.projects.map((proj) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5.0),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${_cleanText(proj.name)}${proj.role != null && proj.role!.isNotEmpty ? " (${_cleanText(proj.role!)})" : ""}',
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkHeading,
                      ),
                    ),
                    if (proj.description != null &&
                        proj.description!.isNotEmpty)
                      pw.Text(
                        _cleanText(proj.description!),
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: bodyText,
                        ),
                      ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8.0),
          ],

          // Section 7: Links
          if (draft.links.isNotEmpty) ...[
            _buildProfessionalSectionHeader('REFERENCES & LINKS', navyAccent),
            pw.SizedBox(height: 4.0),
            pw.Text(
              draft.links
                  .map((l) => '${_cleanText(l.label)}: ${_cleanText(l.url)}')
                  .join('   |   '),
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: mutedText,
              ),
            ),
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
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 2.0),
          pw.Container(
            height: 0.8,
            color: accent,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TEMPLATE 3: CREATIVE (Dynamic Indigo Accent, Side Highlights, Expressive Badges)
  // ===========================================================================

  void _buildCreativeDocument(
    pw.Document doc,
    CvDraftData draft,
    CvPdfExportOptions opts,
  ) {
    const violetAccent = PdfColor.fromInt(0xFF7C3AED);
    const lightViolet = PdfColor.fromInt(0xFFEDE9FE);
    const darkHeading = PdfColor.fromInt(0xFF1E1B4B);
    const bodyText = PdfColor.fromInt(0xFF334155);
    const mutedText = PdfColor.fromInt(0xFF6B7280);

    final contactItems = _extractPermittedContacts(draft, opts);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28.0, vertical: 26.0),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12.0),
            padding: const pw.EdgeInsets.all(14.0),
            decoration: pw.BoxDecoration(
              color: lightViolet,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10.0)),
              border: pw.Border.all(color: violetAccent, width: 1.0),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Initials Circle
                pw.Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: const pw.BoxDecoration(
                    color: violetAccent,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      _getInitials(draft.fullName),
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16.0,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 14.0),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _cleanText(draft.fullName),
                        style: const pw.TextStyle(
                          color: darkHeading,
                          fontSize: 18.0,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        _cleanText(draft.headline),
                        style: const pw.TextStyle(
                          color: violetAccent,
                          fontSize: 11.0,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (contactItems.isNotEmpty) ...[
                        pw.SizedBox(height: 4.0),
                        pw.Text(
                          contactItems.map(_cleanText).join('  *  '),
                          style: const pw.TextStyle(
                            color: bodyText,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) => _buildStandardFooter(context),
        build: (pw.Context context) => [
          if (_isAllBodyEmpty(draft))
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 24.0),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Creative highlights pending completion in CV Editor.',
                style: const pw.TextStyle(
                  fontSize: 10.0,
                  color: mutedText,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          // Section 1: Creative Profile
          if (draft.summary.trim().isNotEmpty) ...[
            _buildCreativeSectionHeader('Creative Profile', violetAccent),
            pw.SizedBox(height: 4.0),
            pw.Text(
              _cleanText(draft.summary),
              style: const pw.TextStyle(
                fontSize: 10.0,
                color: bodyText,
                lineSpacing: 1.3,
              ),
            ),
            pw.SizedBox(height: 12.0),
          ],

          // Section 2: Skills Badges
          if (draft.skills.isNotEmpty) ...[
            _buildCreativeSectionHeader('Superpowers & Skills', violetAccent),
            pw.SizedBox(height: 6.0),
            pw.Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              children: draft.skills.map((skill) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 7.0,
                    vertical: 3.0,
                  ),
                  decoration: const pw.BoxDecoration(
                    color: violetAccent,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(12.0)),
                  ),
                  child: pw.Text(
                    '# ${_cleanText(skill)}',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 12.0),
          ],

          // Section 3: Experience
          if (draft.experiences.isNotEmpty) ...[
            _buildCreativeSectionHeader('Career Milestones', violetAccent),
            pw.SizedBox(height: 6.0),
            ...draft.experiences.map((exp) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8.0),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          _cleanText(exp.jobTitle),
                          style: const pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                            color: darkHeading,
                          ),
                        ),
                        pw.Text(
                          _cleanText(exp.period),
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      _cleanText(exp.company),
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                        fontWeight: pw.FontWeight.bold,
                        color: violetAccent,
                      ),
                    ),
                    if (exp.description.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 2.0),
                      pw.Text(
                        _cleanText(exp.description),
                        style: const pw.TextStyle(
                          fontSize: 9.0,
                          color: bodyText,
                          lineSpacing: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8.0),
          ],

          // Section 4: Education
          if (draft.education.isNotEmpty) ...[
            _buildCreativeSectionHeader('Education', violetAccent),
            pw.SizedBox(height: 6.0),
            ...draft.education.map((edu) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5.0),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _cleanText(edu.degree),
                          style: const pw.TextStyle(
                            fontSize: 10.0,
                            fontWeight: pw.FontWeight.bold,
                            color: darkHeading,
                          ),
                        ),
                        pw.Text(
                          _cleanText(edu.institution),
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      _cleanText(edu.year),
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                        fontWeight: pw.FontWeight.bold,
                        color: violetAccent,
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8.0),
          ],

          // Section 5: Certifications
          if (draft.certifications.isNotEmpty) ...[
            _buildCreativeSectionHeader('Certifications', violetAccent),
            pw.SizedBox(height: 4.0),
            ...draft.certifications.map((cert) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4.0),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${_cleanText(cert.name)} (${_cleanText(cert.issuer)})',
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                        color: bodyText,
                      ),
                    ),
                    pw.Text(
                      _cleanText(cert.year),
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8.0),
          ],

          // Section 6: Projects
          if (draft.projects.isNotEmpty) ...[
            _buildCreativeSectionHeader('Featured Creations', violetAccent),
            pw.SizedBox(height: 4.0),
            ...draft.projects.map((proj) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5.0),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _cleanText(proj.name),
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkHeading,
                      ),
                    ),
                    if (proj.description != null &&
                        proj.description!.isNotEmpty)
                      pw.Text(
                        _cleanText(proj.description!),
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: bodyText,
                        ),
                      ),
                    if (proj.link != null && proj.link!.isNotEmpty)
                      pw.Text(
                        _cleanText(proj.link!),
                        style: const pw.TextStyle(
                          fontSize: 8.0,
                          color: violetAccent,
                        ),
                      ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 8.0),
          ],

          // Section 7: Links
          if (draft.links.isNotEmpty) ...[
            _buildCreativeSectionHeader('Connect & Explore', violetAccent),
            pw.SizedBox(height: 4.0),
            pw.Wrap(
              spacing: 12.0,
              runSpacing: 4.0,
              children: draft.links.map((link) {
                return pw.Text(
                  '${_cleanText(link.label)}: ${_cleanText(link.url)}',
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: violetAccent,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildCreativeSectionHeader(String title, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 2.0, bottom: 2.0),
      child: pw.Row(
        children: [
          pw.Container(
            width: 8.0,
            height: 8.0,
            decoration: pw.BoxDecoration(
              color: accent,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 6.0),
          pw.Text(
            _cleanText(title),
            style: pw.TextStyle(
              fontSize: 11.0,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SHARED UTILITIES & GATING
  // ===========================================================================

  /// Extracts contact items strictly adhering to master consent gate and individual draft consent.
  List<String> _extractPermittedContacts(
    CvDraftData draft,
    CvPdfExportOptions opts,
  ) {
    // CV-03: Master consent gate must be explicitly enabled
    if (!opts.includeContactInfo) {
      return const [];
    }

    final items = <String>[];

    if (opts.includeEmail &&
        draft.showEmail &&
        draft.email != null &&
        draft.email!.trim().isNotEmpty) {
      items.add(draft.email!.trim());
    }

    if (opts.includePhone &&
        draft.showPhone &&
        draft.phone != null &&
        draft.phone!.trim().isNotEmpty) {
      items.add(draft.phone!.trim());
    }

    if (opts.includeLocation &&
        draft.showLocation &&
        draft.location != null &&
        draft.location!.trim().isNotEmpty) {
      items.add(draft.location!.trim());
    }

    if (opts.includeWebsite &&
        draft.showWebsite &&
        draft.website != null &&
        draft.website!.trim().isNotEmpty) {
      items.add(draft.website!.trim());
    }

    return items;
  }

  /// Builds a consistent running footer with "Page X of Y" pagination.
  pw.Widget _buildStandardFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Private & Confidential * ANDRIL CV Maker',
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

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'CV';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Returns true if all optional structured body sections are empty.
  bool _isAllBodyEmpty(CvDraftData draft) {
    return draft.summary.trim().isEmpty &&
        draft.skills.isEmpty &&
        draft.experiences.isEmpty &&
        draft.education.isEmpty &&
        draft.certifications.isEmpty &&
        draft.projects.isEmpty &&
        draft.links.isEmpty;
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
