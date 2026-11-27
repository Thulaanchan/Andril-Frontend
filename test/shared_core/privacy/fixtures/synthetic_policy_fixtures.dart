import 'package:andril_mobile/shared_core/privacy/domain/entities/policy_document.dart';

/// Isolated synthetic policy fixtures for automated offline testing only.
///
/// Complies with R01.02 Section 4.4:
/// - Explicitly marked [isSynthetic = true].
/// - Not included in normal runtime repositories.
/// - Does not grant actual onboarding completion or legal receipts.
class SyntheticPolicyFixtures {
  static const String termsId = 'terms_of_service';
  static const String privacyId = 'privacy_policy';
  static const String guidelinesId = 'community_guidelines';

  /// Synthetic Terms of Service test fixture (v1.0.0, English).
  static PolicyDocument termsFixture({
    String version = '1.0.0',
    String languageCode = 'en',
    String url = 'https://andril.app/policies/terms',
  }) {
    return PolicyDocument(
      id: termsId,
      title: 'Terms of Service',
      version: version,
      languageCode: languageCode,
      url: url,
      isSynthetic: true,
    );
  }

  /// Synthetic Privacy Policy test fixture (v1.0.0, English).
  static PolicyDocument privacyFixture({
    String version = '1.0.0',
    String languageCode = 'en',
    String url = 'https://andril.app/policies/privacy',
  }) {
    return PolicyDocument(
      id: privacyId,
      title: 'Privacy Policy',
      version: version,
      languageCode: languageCode,
      url: url,
      isSynthetic: true,
    );
  }

  /// Synthetic Community Guidelines test fixture (v1.0.0, English).
  static PolicyDocument guidelinesFixture({
    String version = '1.0.0',
    String languageCode = 'en',
    String url = 'https://andril.app/policies/community-guidelines',
  }) {
    return PolicyDocument(
      id: guidelinesId,
      title: 'Community Guidelines',
      version: version,
      languageCode: languageCode,
      url: url,
      isSynthetic: true,
    );
  }

  /// Returns standard 3-document test fixture list.
  static List<PolicyDocument> defaultFixtures() => [
        termsFixture(),
        privacyFixture(),
        guidelinesFixture(),
      ];
}
