/// Authoritative policy document metadata entity for ANDRIL Member-02.
///
/// Complies with R01.02:
/// - Represents authoritative document metadata returned by the backend authority
///   (`GET /api/v1/account/policies/status`).
/// - Prohibits locally fabricated unapproved legal clauses, fake summaries, or synthetic versions
///   in production runtime.
/// - Requires valid secure HTTPS URLs.
/// - Accurately represents the authoritative legal document language (English) separately
///   from user interface localization.
class PolicyDocument {
  const PolicyDocument({
    required this.id,
    required this.title,
    required this.version,
    required this.languageCode,
    required this.url,
    this.isSynthetic = false,
  });

  /// Unique document identifier: 'terms_of_service', 'privacy_policy', 'community_guidelines'.
  final String id;

  /// Authoritative document title.
  final String title;

  /// Authoritative version string (e.g. '1.0.0').
  final String version;

  /// Authoritative document language (e.g. 'en').
  final String languageCode;

  /// Official HTTPS URL where the complete authoritative document is published.
  final String url;

  /// Explicit flag identifying synthetic test fixtures (prohibited in normal runtime).
  final bool isSynthetic;

  /// Validates that the document URL uses a valid, secure HTTPS scheme.
  bool get hasValidHttpsUrl {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        !uri.authority.contains('@');
  }

  /// Parses authoritative policy metadata from backend JSON response.
  factory PolicyDocument.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? json['documentId'] as String? ?? '';
    final title = json['title'] as String? ?? '';
    final version = json['version'] as String? ?? '';
    final language = json['languageCode'] as String? ?? json['language'] as String? ?? 'en';
    final url = json['url'] as String? ?? '';

    return PolicyDocument(
      id: id,
      title: title,
      version: version,
      languageCode: language,
      url: url,
      isSynthetic: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'version': version,
        'languageCode': languageCode,
        'url': url,
        'isSynthetic': isSynthetic,
      };
}
