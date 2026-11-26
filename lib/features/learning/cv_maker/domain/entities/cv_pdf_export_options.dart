import 'package:flutter/foundation.dart';
import 'package:andril_mobile/features/learning/cv_maker/presentation/screens/cv_template_selection_preview_screen.dart';

/// Configuration options for private, owner-scoped CV PDF export per ANDRIL LRN-05 & CV-01..05.
@immutable
class CvPdfExportOptions {
  /// The visual template layout to use for export. Defaults to the draft's selected template.
  final CvTemplate template;

  /// Explicit master privacy consent gate for contact details in exported PDF (CV-03).
  ///
  /// When `false`, NO contact information (email, phone, location, website) is
  /// rendered in the output PDF document, regardless of individual draft consent flags.
  /// When `true`, each contact field is rendered ONLY IF its individual consent flag is also true.
  final bool includeContactInfo;

  /// Whether to include email address (only applicable if [includeContactInfo] is true).
  final bool includeEmail;

  /// Whether to include phone number (only applicable if [includeContactInfo] is true).
  final bool includePhone;

  /// Whether to include location (only applicable if [includeContactInfo] is true).
  final bool includeLocation;

  /// Whether to include website URL (only applicable if [includeContactInfo] is true).
  final bool includeWebsite;

  /// Custom file name without extension. If null, derived from draft title.
  final String? customFileName;

  /// ID of the user requesting export, for owner-scoped access validation.
  final String? ownerUserId;

  /// Optional active session token or identifier to verify session validity.
  final String? sessionToken;

  /// Whether the session is currently authenticated and active.
  final bool isSessionActive;

  const CvPdfExportOptions({
    this.template = CvTemplate.modern,
    this.includeContactInfo = true,
    this.includeEmail = true,
    this.includePhone = true,
    this.includeLocation = true,
    this.includeWebsite = true,
    this.customFileName,
    this.ownerUserId,
    this.sessionToken,
    this.isSessionActive = true,
  });

  /// Factory to construct export options aligned with a given draft's current settings.
  factory CvPdfExportOptions.fromDraft(
    CvDraftData draft, {
    bool includeContactInfo = true,
    String? ownerUserId,
    String? sessionToken,
    bool isSessionActive = true,
  }) {
    return CvPdfExportOptions(
      template: draft.selectedTemplate,
      includeContactInfo: includeContactInfo,
      includeEmail: draft.showEmail,
      includePhone: draft.showPhone,
      includeLocation: draft.showLocation,
      includeWebsite: draft.showWebsite,
      customFileName: sanitizeFileName(draft.title),
      ownerUserId: ownerUserId,
      sessionToken: sessionToken,
      isSessionActive: isSessionActive,
    );
  }

  /// Sanitizes a string into a safe file name (alphanumeric, hyphens, underscores).
  /// Prevents directory traversal attacks (`../`, `\`, null bytes, etc.).
  static String sanitizeFileName(String title) {
    var sanitized = title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w\-]'), '');
    if (sanitized.isEmpty) {
      sanitized = 'andril_cv';
    }
    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }
    return sanitized;
  }

  /// Creates a copy with optionally updated fields.
  CvPdfExportOptions copyWith({
    CvTemplate? template,
    bool? includeContactInfo,
    bool? includeEmail,
    bool? includePhone,
    bool? includeLocation,
    bool? includeWebsite,
    String? customFileName,
    String? ownerUserId,
    String? sessionToken,
    bool? isSessionActive,
  }) {
    return CvPdfExportOptions(
      template: template ?? this.template,
      includeContactInfo: includeContactInfo ?? this.includeContactInfo,
      includeEmail: includeEmail ?? this.includeEmail,
      includePhone: includePhone ?? this.includePhone,
      includeLocation: includeLocation ?? this.includeLocation,
      includeWebsite: includeWebsite ?? this.includeWebsite,
      customFileName: customFileName ?? this.customFileName,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      sessionToken: sessionToken ?? this.sessionToken,
      isSessionActive: isSessionActive ?? this.isSessionActive,
    );
  }
}
