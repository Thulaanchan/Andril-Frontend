import 'package:flutter/foundation.dart';

import 'skill_exchange_participant.dart';

/// Presentation model representing an eligible partner in the Skill Exchange Hub.
///
/// In compliance with DEC-20261120-LRN01-01 and privacy constraints:
/// - Internal account IDs are never exposed in UI or presentation.
/// - Ratings, exchange counts, and live availability schedules are not fabricated.
/// - Clearly models verified skills offered and skills wanted.
@immutable
class SkillPartner {
  /// Opaque Learning profile identifier.
  final String profileId;

  /// Opaque account identifier (kept private; used solely for constructing participant).
  final String accountId;

  /// Public display name (BRD NAME-01-07).
  final String displayName;

  /// Optional biographical summary.
  final String? bio;

  /// Optional avatar URL or initials source.
  final String? avatarUrl;

  /// Approved skill category for filtering.
  final String category;

  /// Skills this partner can teach / offer.
  final List<String> skillsOffered;

  /// Skills this partner wants to learn.
  final List<String> skillsWanted;

  /// Communication languages (e.g., English, Tamil, Tanglish).
  final List<String> communicationLanguages;

  /// Preferred learning styles.
  final List<String> preferredStyles;

  /// Stated availability description.
  final String? availability;

  SkillPartner({
    required String profileId,
    required String accountId,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    required this.category,
    List<String> skillsOffered = const [],
    List<String> skillsWanted = const [],
    List<String> communicationLanguages = const [],
    List<String> preferredStyles = const [],
    this.availability,
  })  : profileId = profileId.trim(),
        accountId = accountId.trim(),
        skillsOffered = List.unmodifiable(skillsOffered),
        skillsWanted = List.unmodifiable(skillsWanted),
        communicationLanguages = List.unmodifiable(communicationLanguages),
        preferredStyles = List.unmodifiable(preferredStyles);

  /// Converts this partner into a domain [SkillExchangeParticipant].
  SkillExchangeParticipant toParticipant() => SkillExchangeParticipant(
        accountId: accountId,
        learningProfileId: profileId,
      );

  /// Disconnected sample partners for offline presentation and test verification.
  /// Clearly identified as synthetic demonstration data without remote persistence.
  static List<SkillPartner> get samplePartners => [
        SkillPartner(
          profileId: 'partner_ananya_01',
          accountId: 'acc_partner_01',
          displayName: 'Ananya Sharma',
          bio:
              'Flutter enthusiast & Mobile UI architect passionate about clean architecture.',
          category: 'Technology',
          skillsOffered: const ['Flutter', 'Dart', 'Clean Architecture'],
          skillsWanted: const ['Figma', 'UI/UX Design', 'Design Systems'],
          communicationLanguages: const ['English', 'Tamil'],
          preferredStyles: const ['Visual', 'Hands-on practice'],
          availability: 'Flexible (Any time)',
        ),
        SkillPartner(
          profileId: 'partner_marcus_02',
          accountId: 'acc_partner_02',
          displayName: 'Marcus Chen',
          bio:
              'Product designer focusing on accessible and responsive interaction design.',
          category: 'Design',
          skillsOffered: const ['Figma', 'UI/UX Design', 'Wireframing'],
          skillsWanted: const ['Flutter', 'Mobile Prototyping'],
          communicationLanguages: const ['English'],
          preferredStyles: const ['Visual', 'Interactive exercises'],
          availability: 'Evenings (6 PM - 9 PM)',
        ),
        SkillPartner(
          profileId: 'partner_priya_03',
          accountId: 'acc_partner_03',
          displayName: 'Priya Raman',
          bio:
              'Polyglot educator eager to exchange language learning techniques.',
          category: 'Languages',
          skillsOffered: const ['Tamil', 'Spoken English', 'Pronunciation'],
          skillsWanted: const ['Python', 'Data Analysis'],
          communicationLanguages: const ['English', 'Tamil', 'Tanglish'],
          preferredStyles: const ['Conversational', 'Reading / writing'],
          availability: 'Weekends (Saturday & Sunday)',
        ),
        SkillPartner(
          profileId: 'partner_david_04',
          accountId: 'acc_partner_04',
          displayName: 'David K.',
          bio:
              'Tech lead & backend engineer with distributed systems background.',
          category: 'Technology',
          skillsOffered: const ['Python', 'FastAPI', 'PostgreSQL'],
          skillsWanted: const ['Dart', 'Flutter'],
          communicationLanguages: const ['English'],
          preferredStyles: const ['Hands-on practice'],
          availability: 'Mornings (8 AM - 12 PM)',
        ),
        SkillPartner(
          profileId: 'partner_elena_05',
          accountId: 'acc_partner_05',
          displayName: 'Elena Rostova',
          bio: 'Digital marketing strategist & growth analyst.',
          category: 'Business',
          skillsOffered: const [
            'SEO Optimization',
            'Content Marketing',
            'Analytics'
          ],
          skillsWanted: const ['Graphic Design', 'Figma'],
          communicationLanguages: const ['English'],
          preferredStyles: const ['Interactive exercises'],
          availability: 'Flexible (Any time)',
        ),
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillPartner &&
          runtimeType == other.runtimeType &&
          profileId == other.profileId &&
          displayName == other.displayName &&
          category == other.category;

  @override
  int get hashCode => Object.hash(profileId, displayName, category);

  @override
  String toString() =>
      'SkillPartner($displayName, category: $category) [private references omitted]';
}
