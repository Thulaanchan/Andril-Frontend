import '../entities/hobbies_media.dart';

/// Abstract domain repository contract for reading private Hobbies Media Gallery items.
///
/// Designed under HOB-01 (Hobbies Photo Gallery and Media Management) requirements
/// and ANDRIL architectural constraints.
///
/// Architectural & Security Boundaries:
/// - Context Ownership: Media belongs strictly to the active, server-verified Hobbies module context.
/// - No Identity Injection: Callers must not select another user's private Gallery through arbitrary
///   identity parameters (no caller-supplied `ownerId`, `userId`, `profileId`, or arbitrary module parameters).
/// - Authorization Independence: The interface alone does not authenticate or authorize access;
///   concrete implementations must derive caller identity from verified session context and fail
///   closed if Hobbies authorization is missing or denied.
/// - Module Isolation: Learning and Dating profile identities remain strictly segregated;
///   no cross-module data exchange is permitted.
/// - Map Non-Equivalence: Gallery media cannot be substituted for HOB-03 Andril Map contributions
///   (which require fresh in-app camera capture, moderation, and location verification).
/// - Excluded Scope: Excludes Hobbies Photo Portfolios (permanently retired per BRD v2.4-R1).
/// - Dependency Purity: Pure Dart domain contract free of HTTP, Dio, Supabase, or local storage dependencies.
abstract class HobbiesGalleryRepository {
  /// Retrieves the list of private [HobbiesMedia] items for the authorized caller.
  ///
  /// Returns a typed asynchronous collection of [HobbiesMedia].
  /// Concrete implementations must fail closed if the caller lacks active Hobbies authorization.
  Future<List<HobbiesMedia>> listMedia();
}
