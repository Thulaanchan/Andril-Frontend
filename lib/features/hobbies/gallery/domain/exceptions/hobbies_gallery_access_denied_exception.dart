/// Authoritative domain exception signaling access denial to the Hobbies Gallery.
///
/// Thrown when session authority is unauthenticated, missing, expired,
/// or denied by module policy under HOB-01 (Hobbies Photo Gallery and Media Management).
///
/// Architectural & Privacy Boundaries:
/// - Pure Dart domain exception; zero dependencies on Flutter UI, widgets,
///   ChangeNotifier, ViewModels, or external packages.
/// - Fixed diagnostic representation without caller-controlled messages to prevent
///   private metadata, URLs, tokens, or sensitive payloads from leaking in telemetry or logs.
class HobbiesGalleryAccessDeniedException implements Exception {
  /// Creates an authoritative [HobbiesGalleryAccessDeniedException].
  const HobbiesGalleryAccessDeniedException();

  @override
  String toString() => 'HobbiesGalleryAccessDeniedException';
}
