import '../../domain/entities/hobbies_media.dart';
import '../../domain/exceptions/hobbies_gallery_access_denied_exception.dart';

/// Abstract data source contract for retrieving private Hobbies Media Gallery items.
///
/// Designed under HOB-01 (Hobbies Photo Gallery and Media Management) requirements
/// and ANDRIL architectural constraints.
///
/// Architectural & Security Boundaries:
/// - Pure Dart Abstraction: Free of Flutter UI widget dependencies and cross-module couplings.
/// - Context Scoping: Production implementations must derive caller identity and
///   module authority from verified backend sessions, not client-supplied parameters.
/// - Explicit Authorization Denial: Must throw [HobbiesGalleryAccessDeniedException]
///   when session authority is missing, unauthenticated, expired, or cross-module.
/// - No Persistent Storage: Does not prescribe or enforce local caching in this abstraction.
/// - No Fabricated Production Authorization: Does not implement local client-authoritative
///   security checks or claim independent verification of backend permissions.
abstract class HobbiesGalleryDataSource {
  /// Asynchronously retrieves private [HobbiesMedia] items for the active Hobbies profile.
  ///
  /// Throws [HobbiesGalleryAccessDeniedException] if the user is unauthenticated, unauthorized,
  /// or if access is denied by module policy.
  /// Throws an [Exception] on network, transport, or serialization failures.
  Future<List<HobbiesMedia>> getGalleryMedia();
}
