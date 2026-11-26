import '../../domain/entities/hobbies_media.dart';
import '../../domain/exceptions/hobbies_gallery_access_denied_exception.dart';
import '../../domain/repositories/hobbies_gallery_repository.dart';
import '../datasources/hobbies_gallery_data_source.dart';

/// Concrete implementation of [HobbiesGalleryRepository] under HOB-01.
///
/// Coordinates media retrieval from an injected [HobbiesGalleryDataSource],
/// enforcing defensive unmodifiable collection copying, fail-closed access denial,
/// zero private media caching after failures, and sanitized error diagnostics.
///
/// Architectural & Privacy Boundaries:
/// - Pure Data Layer: Implements [HobbiesGalleryRepository] without caller identity parameters.
///   Depends only on Domain and Data layers; zero presentation dependencies.
/// - Defensive Copying: Returns [List.unmodifiable] collections to prevent external mutation
///   of data source collections.
/// - Fail-Closed: Preserves and propagates [HobbiesGalleryAccessDeniedException] directly.
/// - Privacy Protection: Generic error diagnostics never expose private URLs, tokens,
///   or sensitive media payloads.
/// - Zero Stale Caching: Does not retain or return previously retrieved media when a subsequent
///   request fails or is denied.
class HobbiesGalleryRepositoryImpl implements HobbiesGalleryRepository {
  final HobbiesGalleryDataSource _dataSource;

  /// Creates a [HobbiesGalleryRepositoryImpl] with injected [dataSource].
  const HobbiesGalleryRepositoryImpl(this._dataSource);

  @override
  Future<List<HobbiesMedia>> listMedia() async {
    try {
      final List<HobbiesMedia> media = await _dataSource.getGalleryMedia();
      return List<HobbiesMedia>.unmodifiable(List<HobbiesMedia>.of(media));
    } on HobbiesGalleryAccessDeniedException {
      // Fail closed immediately on authoritative access denial
      rethrow;
    } catch (_) {
      // Sanitize generic exceptions to ensure private media URLs,
      // tokens, and payloads are never disclosed in diagnostics or logs.
      throw Exception('Gallery media retrieval failed.');
    }
  }
}
