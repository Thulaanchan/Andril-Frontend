import 'package:flutter/foundation.dart';

/// Approved Portfolio templates per ANDRIL LRN-06 / PORT-01..05 & DEC-20261120-LRN06-01.
///
/// Selection and visual preview are reserved for Task 04-05.
enum PortfolioTemplate {
  developer('Developer', 'Clean code & tech focus'),
  creative('Creative', 'Visual showcase & design focus'),
  professional('Professional', 'Corporate & leadership focus');

  final String displayName;
  final String description;

  const PortfolioTemplate(this.displayName, this.description);
}

/// Immutable entity representing a single project within a Learning Portfolio.
///
/// Satisfies LRN-06 / PORT-01..05 & DEC-20261120-LRN06-01:
/// - Private, manually edited project content only.
/// - Media and external links are inert absolute HTTP/HTTPS URL references.
/// - No external network fetching, file-system access, or cross-module lookups.
@immutable
class PortfolioProject {
  /// Stable unique identifier for this project within the portfolio.
  final String id;

  /// Project title or headline.
  final String? title;

  /// Detailed summary or accomplishment notes.
  final String? description;

  /// Collection of inert absolute HTTP/HTTPS media references (screenshots, demos).
  final List<String> mediaReferences;

  /// Collection of inert absolute HTTP/HTTPS external links (code repository, live demo).
  final List<String> externalLinks;

  const PortfolioProject({
    required this.id,
    this.title,
    this.description,
    this.mediaReferences = const [],
    this.externalLinks = const [],
  });

  /// Validates that a reference string is a valid absolute HTTP or HTTPS URL.
  /// Rejects empty, relative, file, data, blob, and javascript schemes.
  static bool isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    if (!uri.hasScheme || !uri.hasAuthority) return false;
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && uri.host.isNotEmpty;
  }

  /// Creates a copy of this project with optional replacements.
  PortfolioProject copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? mediaReferences,
    List<String>? externalLinks,
  }) {
    return PortfolioProject(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaReferences: mediaReferences != null
          ? List.unmodifiable(mediaReferences)
          : this.mediaReferences,
      externalLinks: externalLinks != null
          ? List.unmodifiable(externalLinks)
          : this.externalLinks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortfolioProject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          listEquals(mediaReferences, other.mediaReferences) &&
          listEquals(externalLinks, other.externalLinks);

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      Object.hashAll(mediaReferences) ^
      Object.hashAll(externalLinks);

  @override
  String toString() =>
      'Private Portfolio Project [id=$id, title=${title ?? "untitled"}]';
}

/// Immutable Learning Portfolio entity.
///
/// Architecture & Security Constraints (LRN-06 / PORT-01..05 & DEC-20261120-LRN06-01):
/// - Private by design (`isPrivate = true`). Public sharing is pending approval.
/// - Scoped to the authenticated owner's Learning profile ([ownerLearningProfileId]).
/// - Isolated strictly to `module = 'learning'`.
/// - Supports complete in-memory draft preservation and structured project reordering.
@immutable
class LearningPortfolio {
  /// Unique identifier of the portfolio.
  final String id;

  /// Owner Learning profile identifier for ownership verification and access control.
  final String ownerLearningProfileId;

  /// Human-readable title of this portfolio document.
  final String title;

  /// Learning module isolation identifier.
  final String module;

  /// Whether this portfolio is private to the owner. Always true per LRN-06.
  final bool isPrivate;

  /// Chosen visual template category (Task 04-05 scope for template switching/preview).
  final PortfolioTemplate template;

  /// Ordered list of showcase projects.
  final List<PortfolioProject> projects;

  /// Last modification timestamp.
  final DateTime updatedAt;

  const LearningPortfolio({
    required this.id,
    required this.ownerLearningProfileId,
    required this.title,
    this.module = 'learning',
    this.isPrivate = true,
    this.template = PortfolioTemplate.developer,
    this.projects = const [],
    required this.updatedAt,
  });

  /// Factory creating an empty portfolio draft for Create Mode.
  factory LearningPortfolio.empty({
    required String ownerLearningProfileId,
    String title = 'My Learning Portfolio',
    PortfolioTemplate template = PortfolioTemplate.developer,
  }) {
    return LearningPortfolio(
      id: 'port_${DateTime.now().millisecondsSinceEpoch}',
      ownerLearningProfileId: ownerLearningProfileId,
      title: title,
      template: template,
      projects: const [],
      updatedAt: DateTime.now(),
    );
  }

  /// Realistic synthetic sample for offline testing and preview.
  factory LearningPortfolio.syntheticSample({
    String ownerLearningProfileId = 'owner_synthetic_01',
  }) {
    return LearningPortfolio(
      id: 'port_synthetic_sample',
      ownerLearningProfileId: ownerLearningProfileId,
      title: 'Mobile Systems Engineering Portfolio',
      template: PortfolioTemplate.developer,
      projects: const [
        PortfolioProject(
          id: 'proj_01',
          title: 'ANDRIL Mobile Learning Suite',
          description:
              'Architected the cross-platform learning client with resilient offline synchronization and clean module isolation.',
          mediaReferences: [
            'https://andril.dev/media/showcase-01.png',
            'https://andril.dev/media/showcase-02.png',
          ],
          externalLinks: [
            'https://github.com/andril/learning-mobile',
            'https://docs.andril.dev/architecture',
          ],
        ),
        PortfolioProject(
          id: 'proj_02',
          title: 'Accessible Design System',
          description:
              'Engineered a semantic, high-contrast, scalable component library adhering to strict WCAG 2.1 AA specifications.',
          mediaReferences: [
            'https://andril.dev/media/design-system.png',
          ],
          externalLinks: [
            'https://andril.dev/design-system',
          ],
        ),
      ],
      updatedAt: DateTime(2026, 11, 24),
    );
  }

  /// Returns a copy of this portfolio with updated fields.
  LearningPortfolio copyWith({
    String? id,
    String? ownerLearningProfileId,
    String? title,
    String? module,
    bool? isPrivate,
    PortfolioTemplate? template,
    List<PortfolioProject>? projects,
    DateTime? updatedAt,
  }) {
    return LearningPortfolio(
      id: id ?? this.id,
      ownerLearningProfileId:
          ownerLearningProfileId ?? this.ownerLearningProfileId,
      title: title ?? this.title,
      module: module ?? this.module,
      isPrivate: isPrivate ?? this.isPrivate,
      template: template ?? this.template,
      projects: projects != null ? List.unmodifiable(projects) : this.projects,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningPortfolio &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerLearningProfileId == other.ownerLearningProfileId &&
          title == other.title &&
          module == other.module &&
          isPrivate == other.isPrivate &&
          template == other.template &&
          listEquals(projects, other.projects);

  @override
  int get hashCode =>
      id.hashCode ^
      ownerLearningProfileId.hashCode ^
      title.hashCode ^
      module.hashCode ^
      isPrivate.hashCode ^
      template.hashCode ^
      Object.hashAll(projects);

  @override
  String toString() =>
      'Private Learning Portfolio [id=$id, owner=$ownerLearningProfileId, projectsCount=${projects.length}]';
}
