/// Domain entity representing an authenticated or registered user identity in ANDRIL.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.isEmailVerified = false,
    this.createdAt,
  });

  final String id;
  final String email;
  final bool isEmailVerified;
  final DateTime? createdAt;
}
