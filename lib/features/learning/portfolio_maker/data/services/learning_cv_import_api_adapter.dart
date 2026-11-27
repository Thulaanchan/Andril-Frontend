import 'package:flutter/foundation.dart';

import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';

/// DTO representing an individual reviewed project returned by remote backend.
@immutable
class ProjectImportReviewedProjectItem {
  final String projectId;
  final String? title;
  final String? description;

  const ProjectImportReviewedProjectItem({
    required this.projectId,
    this.title,
    this.description,
  });

  factory ProjectImportReviewedProjectItem.fromJson(Map<String, dynamic> json) {
    final id = json['projectId'] ?? json['project_id'] ?? json['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException(
          'Missing or invalid projectId in reviewed item');
    }
    return ProjectImportReviewedProjectItem(
      projectId: id.trim(),
      title: json['title'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'title': title,
        'description': description,
      };
}

/// DTO representing the remote CV project import review response.
@immutable
class ProjectImportReviewResult {
  final String reviewId;
  final String portfolioId;
  final String cvId;
  final List<ProjectImportReviewedProjectItem> projects;

  const ProjectImportReviewResult({
    required this.reviewId,
    required this.portfolioId,
    required this.cvId,
    required this.projects,
  });

  factory ProjectImportReviewResult.fromJson(Map<String, dynamic> json) {
    final reviewId = json['reviewId'] ?? json['review_id'] ?? json['id'];
    final portfolioId = json['portfolioId'] ?? json['portfolio_id'];
    final cvId = json['cvId'] ?? json['cv_id'];
    final rawProjects = json['projects'];

    if (reviewId is! String || reviewId.trim().isEmpty) {
      throw const FormatException('Missing or invalid reviewId');
    }
    if (portfolioId is! String || portfolioId.trim().isEmpty) {
      throw const FormatException('Missing or invalid portfolioId');
    }
    if (cvId is! String || cvId.trim().isEmpty) {
      throw const FormatException('Missing or invalid cvId');
    }

    final parsedProjects = <ProjectImportReviewedProjectItem>[];
    if (rawProjects is List) {
      for (final p in rawProjects) {
        if (p is Map<String, dynamic>) {
          parsedProjects.add(ProjectImportReviewedProjectItem.fromJson(p));
        } else if (p is Map) {
          parsedProjects.add(ProjectImportReviewedProjectItem.fromJson(
              p.map((k, v) => MapEntry(k.toString(), v))));
        }
      }
    }

    return ProjectImportReviewResult(
      reviewId: reviewId.trim(),
      portfolioId: portfolioId.trim(),
      cvId: cvId.trim(),
      projects: List.unmodifiable(parsedProjects),
    );
  }
}

/// Contract for remote Learning CV project import backend service.
abstract class ILearningCvImportRemoteDataSource {
  /// Submits project IDs from a portfolio to request an import review.
  Future<ProjectImportReviewResult> requestImportReview({
    required BackendSession session,
    required String portfolioId,
    required String cvId,
    required List<String> projectIds,
  });

  /// Confirms an import review by reviewId.
  Future<void> confirmImportReview({
    required BackendSession session,
    required String reviewId,
    required bool confirmed,
  });
}

/// Implementation of [ILearningCvImportRemoteDataSource] backed by [AndrilApiClient].
class LearningCvImportRemoteDataSource
    implements ILearningCvImportRemoteDataSource {
  final AndrilApiClient _apiClient;

  const LearningCvImportRemoteDataSource(this._apiClient);

  @override
  Future<ProjectImportReviewResult> requestImportReview({
    required BackendSession session,
    required String portfolioId,
    required String cvId,
    required List<String> projectIds,
  }) async {
    _validateGuid(portfolioId, 'portfolioId');
    _validateGuid(cvId, 'cvId');
    for (final id in projectIds) {
      _validateGuid(id, 'projectId in projectIds');
    }

    final response = await _apiClient.requestLearning(
      LearningEndpoint.cvImportReviews,
      session,
      body: {
        'portfolioId': portfolioId,
        'cvId': cvId,
        'projectIds': projectIds,
      },
    );

    return ProjectImportReviewResult.fromJson(response);
  }

  @override
  Future<void> confirmImportReview({
    required BackendSession session,
    required String reviewId,
    required bool confirmed,
  }) async {
    _validateGuid(reviewId, 'reviewId');
    await _apiClient.requestLearningPath(
      'POST',
      '/api/v1/learning/cv-imports/$reviewId/confirm',
      session,
      body: {
        'confirmed': confirmed,
      },
    );
  }

  static void _validateGuid(String value, String field) {
    final trimmed = value.trim();
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(trimmed)) {
      throw ArgumentError('Invalid UUID format for $field: $value');
    }
  }
}
