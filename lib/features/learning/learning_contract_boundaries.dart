import 'package:flutter/foundation.dart';

/// Contract boundary registry defining the integration standing of Learning module features
/// with backend services per BRD v2.4-R1 and Task AND-M1-FE-05-09.
///
/// Under zero-invention and fail-closed security rules:
/// 1. Ready and approved APIs are integrated via [AndrilApiClient] and verified session context.
/// 2. Features lacking backend controllers/endpoints are explicitly recorded with dependency
///    owners and blockers.
/// 3. Offline/local resilience is preserved without fabricating mock or unauthorized endpoints.
@immutable
class LearningContractBoundary {
  final String featureArea;
  final String requirementRef;
  final bool isBackendReady;
  final String? approvedEndpoints;
  final String? dependencyOwner;
  final String? blockerDetails;

  const LearningContractBoundary({
    required this.featureArea,
    required this.requirementRef,
    required this.isBackendReady,
    this.approvedEndpoints,
    this.dependencyOwner,
    this.blockerDetails,
  });
}

/// Registry of all Learning feature contract boundaries.
abstract final class LearningContractBoundaries {
  /// 1. Learning Home, Profile & Preferences
  static const learningSetupAndProfile = LearningContractBoundary(
    featureArea: 'Learning Profile & Preferences',
    requirementRef: 'LRN-01 / CF-01..02',
    isBackendReady: true,
    approvedEndpoints:
        'GET /api/v1/learning/setup, PUT /api/v1/learning/setup/selections, '
        'POST/PUT/DELETE /api/v1/learning/setup/goals, '
        'PUT/GET /api/v1/account/profiles/learning',
  );

  /// 2. Controlled CV Project Import
  static const cvProjectImport = LearningContractBoundary(
    featureArea: 'CV Project Import Review & Confirm',
    requirementRef: 'LRN-06 / PORT-01..05 / CV-01..05',
    isBackendReady: true,
    approvedEndpoints: 'POST /api/v1/learning/cv-imports/reviews, '
        'POST /api/v1/learning/cv-imports/{reviewId}/confirm',
  );

  /// 3. People Discovery & Connections
  static const peopleDiscoveryAndConnections = LearningContractBoundary(
    featureArea: 'People Discovery & Connections',
    requirementRef: 'LRN-01 / DSC-01..05 / CON-01..05',
    isBackendReady: false,
    dependencyOwner: 'Backend Team (M5 / Learning Team)',
    blockerDetails:
        'Domain reader ILearningPartnerDiscoveryReader exists in backend, but HTTP API '
        'endpoints are not exposed in Andril.API. Local UI fallback remains active.',
  );

  /// 4. Skill Exchange, Classrooms, Circles and Pacts
  static const collaborationFeatures = LearningContractBoundary(
    featureArea: 'Skill Exchange, Classrooms, Circles & Pacts',
    requirementRef: 'LRN-02..03 / CF-07 / GRP-01..05',
    isBackendReady: false,
    dependencyOwner: 'Backend Team (Groups / Learning Team)',
    blockerDetails:
        'Domain models LearningCircle, LearningPact, and SkillExchange exist in domain library, '
        'but no HTTP API controllers or routes are registered in Andril.API. Local UI fallback active.',
  );

  /// 5. Growth Dashboard, Topic Gaps and Mentorship
  static const growthAndMentorship = LearningContractBoundary(
    featureArea: 'Growth Dashboard, Topic Gaps & Mentorship',
    requirementRef: 'LRN-04 / GRW-01..05',
    isBackendReady: false,
    dependencyOwner: 'Backend Team (Learning Team)',
    blockerDetails:
        'Domain entities LearningGrowthEvidence and LearningMentorship exist in backend library, '
        'but no HTTP endpoints exist in Andril.API. Local UI fallback active.',
  );

  /// 6. CV Maker, Portfolio Maker & Diary Remote Persistence
  static const remoteDocumentPersistence = LearningContractBoundary(
    featureArea: 'CV Maker, Portfolio Maker & Diary Remote Persistence',
    requirementRef: 'LRN-05..06 / CV-01..05 / PORT-01..05',
    isBackendReady: false,
    dependencyOwner: 'Backend Team (Learning Team)',
    blockerDetails:
        'IsolatedLearningCvRepository and IsolatedLearningPortfolioRepository exist in backend EF library, '
        'but HTTP CRUD endpoints are not mapped in Andril.API. Local in-memory storage & private PDF export active.',
  );

  /// 7. AI Chat Box
  static const aiChatBox = LearningContractBoundary(
    featureArea: 'AI Chat Box',
    requirementRef: 'AI-01..03',
    isBackendReady: false,
    dependencyOwner: 'Backend Team (AI Team)',
    blockerDetails:
        'AiChatController is marked [NonController] and dormant. No route attributes, registration, '
        'or production authority exist until admission, dispatch and delivery contracts are approved.',
  );

  /// All boundaries.
  static const List<LearningContractBoundary> all = [
    learningSetupAndProfile,
    cvProjectImport,
    peopleDiscoveryAndConnections,
    collaborationFeatures,
    growthAndMentorship,
    remoteDocumentPersistence,
    aiChatBox,
  ];
}
