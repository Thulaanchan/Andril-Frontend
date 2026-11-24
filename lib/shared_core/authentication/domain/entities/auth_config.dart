/// Injected authentication configuration parameters.
///
/// Complies with Mandatory Rule 03: production values for OTP expiration,
/// resend cooldown, password length, and password complexity remain unconfirmed
/// by the backend authority.
///
/// This configuration has NO fixed production defaults. Values must be provided
/// explicitly by server/provider configuration at runtime or injected explicitly
/// within isolated automated test suites.
class AuthConfig {
  const AuthConfig({
    this.otpLength,
    this.resendCooldownSeconds,
    this.otpExpirationMinutes,
    this.minPasswordLength,
    this.requireSpecialCharacter,
  });

  /// Optional OTP token length. The visual 6-box input is an interface guideline,
  /// but the authoritative verification length is supplied by the backend provider.
  final int? otpLength;

  /// Resend cooldown in seconds. Must not assume an unapproved production default (e.g. 60s).
  final int? resendCooldownSeconds;

  /// OTP validity window in minutes.
  final int? otpExpirationMinutes;

  /// Minimum password length if enforced by provider policy.
  final int? minPasswordLength;

  /// Whether a special character is required.
  final bool? requireSpecialCharacter;

  /// Pre-configured test-only instance for automated test execution.
  static const AuthConfig testFixture = AuthConfig(
    otpLength: 6,
    resendCooldownSeconds: 30,
    otpExpirationMinutes: 10,
    minPasswordLength: 8,
    requireSpecialCharacter: true,
  );
}
