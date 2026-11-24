import '../../../../app/themes/common/chat_theme.dart';
import '../../virtual_gifts/domain/gift_catalogs.dart';

/// The three isolated ANDRIL module types.
enum AndrilModuleType { learning, hobbies, social }

/// Private profile configuration for a module.
/// Decoupled per module to enforce identity isolation and privacy rules.
class AndrilModuleProfile {
  final String name;
  final String status;
  final String avatarAsset;
  final AndrilModuleType moduleType;

  const AndrilModuleProfile({
    required this.name,
    required this.status,
    required this.avatarAsset,
    required this.moduleType,
  });
}

/// Reusable configuration binding theme, mock gift catalog, and profile per module.
class AndrilModuleConfig {
  final AndrilModuleType type;
  final String name;
  final AndrilChatTheme theme;
  final List<AndrilGift> giftCatalog;
  final AndrilModuleProfile defaultPartner;
  final bool allowsMoodTone;

  const AndrilModuleConfig({
    required this.type,
    required this.name,
    required this.theme,
    required this.giftCatalog,
    required this.defaultPartner,
    required this.allowsMoodTone,
  });

  /// Invariant: MoodTone is strictly Social-only (BRD v2.4-R1 DEC-20261111-MOOD-01).
  /// MoodTone is prohibited in Learning and Hobbies.
  bool get supportsMoodTone =>
      allowsMoodTone && type == AndrilModuleType.social;

  static const learning = AndrilModuleConfig(
    type: AndrilModuleType.learning,
    name: 'Learning',
    theme: LearningChatTheme(),
    giftCatalog: learningGifts,
    defaultPartner: AndrilModuleProfile(
      name: 'Maya',
      status: 'Online',
      avatarAsset: 'assets/profile/maya_avatar.webp',
      moduleType: AndrilModuleType.learning,
    ),
    allowsMoodTone: false,
  );

  static const hobbies = AndrilModuleConfig(
    type: AndrilModuleType.hobbies,
    name: 'Hobbies',
    theme: HobbiesChatTheme(),
    giftCatalog: hobbiesGifts,
    defaultPartner: AndrilModuleProfile(
      name: 'Nila',
      status: 'Online',
      avatarAsset: 'assets/profile/nila_avatar.png',
      moduleType: AndrilModuleType.hobbies,
    ),
    allowsMoodTone: false,
  );

  static const social = AndrilModuleConfig(
    type: AndrilModuleType.social,
    name: 'Social',
    theme: SocialChatTheme(),
    giftCatalog: socialGifts,
    defaultPartner: AndrilModuleProfile(
      name: 'Aira',
      status: 'Online',
      avatarAsset: 'assets/profile/aira_avatar.png',
      moduleType: AndrilModuleType.social,
    ),
    allowsMoodTone: true,
  );

  static const List<AndrilModuleConfig> values = [learning, hobbies, social];

  static AndrilModuleConfig forType(AndrilModuleType type) {
    switch (type) {
      case AndrilModuleType.learning:
        return learning;
      case AndrilModuleType.hobbies:
        return hobbies;
      case AndrilModuleType.social:
        return social;
    }
  }
}
