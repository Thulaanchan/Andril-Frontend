import 'social_profile_draft.dart';

/// Categorized failure reasons for Social profile operations.
///
/// Follows confirmed M2 backend contract boundaries:
/// `/api/v1/account/profiles/social`.
enum SocialProfileFailureType {
  /// Input failed client-side or server-side schema constraints.
  validationFailure,

  /// Display name is already taken or reserved.
  displayNameUnavailable,

  /// Caller is unauthenticated, lacks adult eligibility, or is denied Social access.
  authorizationDenied,

  /// Backend service or database dependency unavailable (e.g. 503, network drop).
  dependencyFailure,

  /// User session expired or context changed asynchronously.
  sessionExpired,

  /// Operation was cancelled by caller before completing.
  cancelled,

  /// Unclassified or unexpected failure.
  unknown,
}

/// Structured failure diagnostic for Social profile operations.
class SocialProfileFailure {
  final SocialProfileFailureType type;
  final String message;

  const SocialProfileFailure({
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'SocialProfileFailure(type: $type, message: $message)';
}

/// Discriminated union result representing outcome of Social profile operations.
sealed class SocialProfileResult {
  const SocialProfileResult();

  const factory SocialProfileResult.success(SocialProfileDraft draft) =
      SocialProfileSuccess;

  const factory SocialProfileResult.failure(SocialProfileFailure failure) =
      SocialProfileError;
}

/// Successful profile draft operation outcome.
final class SocialProfileSuccess extends SocialProfileResult {
  final SocialProfileDraft draft;

  const SocialProfileSuccess(this.draft);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialProfileSuccess &&
          runtimeType == other.runtimeType &&
          draft == other.draft;

  @override
  int get hashCode => draft.hashCode;

  @override
  String toString() => 'SocialProfileSuccess($draft)';
}

/// Failed profile draft operation outcome.
final class SocialProfileError extends SocialProfileResult {
  final SocialProfileFailure failure;

  const SocialProfileError(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialProfileError &&
          runtimeType == other.runtimeType &&
          failure.type == other.failure.type &&
          failure.message == other.failure.message;

  @override
  int get hashCode => Object.hash(failure.type, failure.message);

  @override
  String toString() => 'SocialProfileError($failure)';
}

/// Abstract contract for reading, initializing, and saving the caller's private
/// Social profile draft.
///
/// Implementations must rely on authenticated caller context rather than
/// caller-supplied account or profile ownership identifiers.
///
/// Draft operations do NOT complete onboarding or unlock Social Home.
abstract interface class SocialProfileRepository {
  /// Reads the caller's eligible private Social module profile draft.
  Future<SocialProfileResult> getProfileDraft();

  /// Initializes or creates the private profile identity using an empty JSON object.
  Future<SocialProfileResult> createProfileDraft();

  /// Saves or updates the permitted private profile draft fields.
  Future<SocialProfileResult> saveProfileDraft(SocialProfileDraft draft);
}
