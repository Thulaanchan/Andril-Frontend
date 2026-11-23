import '../entities/learning_profile.dart';

/// Sealed result hierarchy representing deterministic outcomes of profile repository operations.
sealed class ProfileResult<T> {
  const ProfileResult();
}

/// Operation succeeded with requested payload data.
final class ProfileSuccess<T> extends ProfileResult<T> {
  final T data;
  const ProfileSuccess(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileSuccess<T> && other.data == data);

  @override
  int get hashCode => data.hashCode;
}

/// Profile does not exist or has not been provisioned for the authenticated caller.
final class ProfileNotFound<T> extends ProfileResult<T> {
  final String message;
  const ProfileNotFound([this.message = 'Learning profile not found']);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileNotFound<T> && other.message == message);

  @override
  int get hashCode => message.hashCode;
}

/// Caller is unauthenticated, lacks required permissions, or attempted unauthorized access.
final class ProfileAccessDenied<T> extends ProfileResult<T> {
  final String message;
  const ProfileAccessDenied([
    this.message = 'Access denied: caller is not authorized for this profile',
  ]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileAccessDenied<T> && other.message == message);

  @override
  int get hashCode => message.hashCode;
}

/// Required upstream dependency (e.g. M2 auth/identity service or backend network) is unavailable.
final class ProfileDependencyUnavailable<T> extends ProfileResult<T> {
  final String message;
  const ProfileDependencyUnavailable([
    this.message =
        'Underlying M2 authentication or backend service is currently unavailable',
  ]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileDependencyUnavailable<T> && other.message == message);

  @override
  int get hashCode => message.hashCode;
}

/// Recoverable error or failure during profile operations.
final class ProfileFailure<T> extends ProfileResult<T> {
  final String message;
  final Object? error;
  const ProfileFailure(this.message, [this.error]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileFailure<T> &&
          other.message == message &&
          other.error == error);

  @override
  int get hashCode => Object.hash(message, error);
}

/// Abstract contract for Learning profile data operations.
///
/// Under security and privacy constraints (BRD §04.1-04.3, docs/SECURITY_BOUNDARIES.md),
/// operations derive identity strictly from the verified session context. The repository
/// never accepts caller-supplied profile IDs that could bypass backend ownership validation.
abstract interface class ProfileRepository {
  /// Fetches the authenticated user's Learning profile projection.
  ///
  /// Returns [ProfileSuccess] when found, [ProfileNotFound] if unprovisioned,
  /// [ProfileAccessDenied] if unauthenticated, or [ProfileDependencyUnavailable]
  /// if upstream dependencies cannot be reached.
  Future<ProfileResult<LearningProfile>> getProfile();

  /// Updates presentation attributes and learning preferences on the caller's profile.
  ///
  /// Identity fields ([LearningProfile.profileId], [LearningProfile.accountId]) are
  /// validated against session context and cannot be reassigned.
  Future<ProfileResult<LearningProfile>> updateProfile(LearningProfile profile);

  /// Saves draft learning preferences during onboarding or profile editing.
  Future<ProfileResult<LearningProfile>> saveDraftProfile({
    required String displayName,
    List<String> skillsToLearn = const [],
    List<String> skillsToShare = const [],
    List<String> learningGoals = const [],
  });
}
