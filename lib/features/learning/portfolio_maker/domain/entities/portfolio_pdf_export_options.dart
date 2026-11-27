import 'package:flutter/foundation.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/domain/models/portfolio_models.dart';

/// Configuration options for private, owner-scoped Portfolio PDF export
/// per ANDRIL LRN-06, PORT-01..05 & DEC-20261120-LRN06-01.
@immutable
class PortfolioPdfExportOptions {
  /// The visual template layout to use for export. Defaults to the portfolio's selected template.
  final PortfolioTemplate template;

  /// Whether to include media references in the exported PDF.
  final bool includeMediaReferences;

  /// Whether to include external links in the exported PDF.
  final bool includeExternalLinks;

  /// Custom file name without extension. If null, derived from portfolio title.
  final String? customFileName;

  /// ID of the user requesting export, for owner-scoped access validation.
  final String? ownerUserId;

  /// Optional active session token or identifier to verify session validity.
  final String? sessionToken;

  /// Whether the session is currently authenticated and active.
  final bool isSessionActive;

  const PortfolioPdfExportOptions({
    this.template = PortfolioTemplate.developer,
    this.includeMediaReferences = true,
    this.includeExternalLinks = true,
    this.customFileName,
    this.ownerUserId,
    this.sessionToken,
    this.isSessionActive = true,
  });

  /// Factory to construct export options aligned with a given portfolio's current settings.
  factory PortfolioPdfExportOptions.fromPortfolio(
    LearningPortfolio portfolio, {
    bool includeMediaReferences = true,
    bool includeExternalLinks = true,
    String? ownerUserId,
    String? sessionToken,
    bool isSessionActive = true,
  }) {
    return PortfolioPdfExportOptions(
      template: portfolio.template,
      includeMediaReferences: includeMediaReferences,
      includeExternalLinks: includeExternalLinks,
      customFileName: sanitizeFileName(portfolio.title),
      ownerUserId: ownerUserId ?? portfolio.ownerLearningProfileId,
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
      sanitized = 'andril_portfolio';
    }
    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }
    return sanitized;
  }

  /// Creates a copy with optionally updated fields.
  PortfolioPdfExportOptions copyWith({
    PortfolioTemplate? template,
    bool? includeMediaReferences,
    bool? includeExternalLinks,
    String? customFileName,
    String? ownerUserId,
    String? sessionToken,
    bool? isSessionActive,
  }) {
    return PortfolioPdfExportOptions(
      template: template ?? this.template,
      includeMediaReferences:
          includeMediaReferences ?? this.includeMediaReferences,
      includeExternalLinks: includeExternalLinks ?? this.includeExternalLinks,
      customFileName: customFileName ?? this.customFileName,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      sessionToken: sessionToken ?? this.sessionToken,
      isSessionActive: isSessionActive ?? this.isSessionActive,
    );
  }
}
