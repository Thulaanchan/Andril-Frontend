import '../entities/hobbies_media.dart';
import '../repositories/hobbies_gallery_repository.dart';

/// Domain use case for retrieving private Hobbies Media Gallery items.
///
/// Under HOB-01 (Hobbies Photo Gallery and Media Management), this use case
/// coordinates read-only media retrieval from [HobbiesGalleryRepository].
///
/// Architectural & Privacy Boundaries:
/// - Active Context: Media belongs strictly to the authenticated caller's active,
///   server-verified Hobbies module context.
/// - No Identity Injection: Accepts no arbitrary `ownerId`, `userId`, `profileId`,
///   or module parameters; access is determined by verified session authority.
/// - Fail-Closed: Propagates missing/denied authorization and repository errors
///   directly as failures without converting them into empty success results.
/// - Privacy: Emits no sensitive media metadata (identifiers, titles, URLs, tags)
///   in diagnostics or logs.
/// - Module Isolation: Learning and Dating identities remain segregated; no cross-module
///   data leakage.
/// - Feature Boundaries: Gallery media is never substituted for HOB-03 Andril Map
///   contributions (which require in-app capture and moderation). Hobbies Photo Portfolios
///   remain permanently excluded per BRD v2.4-R1.
/// - Dependency Purity: Pure Dart domain logic with no Flutter UI, HTTP, Dio, or
///   Supabase dependencies.
class GetHobbiesGalleryMediaUseCase {
  /// The underlying repository contract for Hobbies gallery media operations.
  final HobbiesGalleryRepository repository;

  /// Creates a [GetHobbiesGalleryMediaUseCase] with injected [repository].
  const GetHobbiesGalleryMediaUseCase(this.repository);

  /// Executes the use case to retrieve the caller's private gallery media.
  ///
  /// Returns a [Future] completing with the list of [HobbiesMedia] items.
  /// Propagates any underlying repository or authorization exceptions.
  Future<List<HobbiesMedia>> call() {
    return repository.listMedia();
  }
}
