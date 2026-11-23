/// Unified virtual gift model for M4 mock catalogs.
///
/// IMPORTANT MOCK NOTICE:
/// All sample coin prices (1, 1, 2, 2, 5, 5, 10, 10, 20, 20) and starting balances
/// are non-authoritative MOCK data. No real wallet transaction, payment gateway,
/// or transferable coin credit occurs.
class AndrilGift {
  final String id;
  final String
  name; // Internal / a11y label only. Never shown in visual picker.
  final int coins;
  final String assetPath;
  final String? stickerOverride;

  const AndrilGift({
    required this.id,
    required this.name,
    required this.coins,
    required this.assetPath,
    this.stickerOverride,
  });

  String get stickerAsset => stickerOverride ?? assetPath;
}

/// Backwards-compatibility alias for existing Social prototype code.
typedef SocialGift = AndrilGift;

/// MOCK Learning gift catalog (10 items).
const learningGifts = <AndrilGift>[
  AndrilGift(
    id: 'LRN-G01',
    name: 'Study Buddy',
    coins: 1,
    assetPath: 'assets/gifts/learning/study_buddy.png',
  ),
  AndrilGift(
    id: 'LRN-G02',
    name: 'Note Card',
    coins: 1,
    assetPath: 'assets/gifts/learning/note_card.png',
  ),
  AndrilGift(
    id: 'LRN-G03',
    name: 'Clap Cheer',
    coins: 2,
    assetPath: 'assets/gifts/learning/clap_cheer.png',
  ),
  AndrilGift(
    id: 'LRN-G04',
    name: 'Study Lamp',
    coins: 2,
    assetPath: 'assets/gifts/learning/study_lamp.png',
  ),
  AndrilGift(
    id: 'LRN-G05',
    name: 'Growth Ladder',
    coins: 5,
    assetPath: 'assets/gifts/learning/growth_ladder.png',
  ),
  AndrilGift(
    id: 'LRN-G06',
    name: 'Skill Star',
    coins: 5,
    assetPath: 'assets/gifts/learning/skill_star.png',
  ),
  AndrilGift(
    id: 'LRN-G07',
    name: 'Learning Star',
    coins: 10,
    assetPath: 'assets/gifts/learning/learning_star.png',
  ),
  AndrilGift(
    id: 'LRN-G08',
    name: 'Mentor Token',
    coins: 10,
    assetPath: 'assets/gifts/learning/mentor_token.png',
  ),
  AndrilGift(
    id: 'LRN-G09',
    name: 'Achievement Trophy',
    coins: 20,
    assetPath: 'assets/gifts/learning/achievement_trophy.png',
  ),
  AndrilGift(
    id: 'LRN-G10',
    name: 'Graduation Cap',
    coins: 20,
    assetPath: 'assets/gifts/learning/graduation_cap.png',
  ),
];

/// MOCK Hobbies gift catalog (10 items).
const hobbiesGifts = <AndrilGift>[
  AndrilGift(
    id: 'HOB-G01',
    name: 'Art Palette',
    coins: 1,
    assetPath: 'assets/gifts/hobbies/art_palette.png',
  ),
  AndrilGift(
    id: 'HOB-G02',
    name: 'Photo Snap',
    coins: 1,
    assetPath: 'assets/gifts/hobbies/photo_snap.png',
  ),
  AndrilGift(
    id: 'HOB-G03',
    name: 'Music Vibe',
    coins: 2,
    assetPath: 'assets/gifts/hobbies/music_vibe.png',
  ),
  AndrilGift(
    id: 'HOB-G04',
    name: 'Game Buddy',
    coins: 2,
    assetPath: 'assets/gifts/hobbies/game_buddy.png',
  ),
  AndrilGift(
    id: 'HOB-G05',
    name: 'Explorer Compass',
    coins: 5,
    assetPath: 'assets/gifts/hobbies/explorer_compass.png',
  ),
  AndrilGift(
    id: 'HOB-G06',
    name: 'Camp Vibes',
    coins: 5,
    assetPath: 'assets/gifts/hobbies/camp_vibes.png',
  ),
  AndrilGift(
    id: 'HOB-G07',
    name: 'Adventure Ride',
    coins: 10,
    assetPath: 'assets/gifts/hobbies/adventure_ride.png',
  ),
  AndrilGift(
    id: 'HOB-G08',
    name: 'Travel Frame',
    coins: 10,
    assetPath: 'assets/gifts/hobbies/travel_frame.png',
  ),
  AndrilGift(
    id: 'HOB-G09',
    name: 'Andril Stamp',
    coins: 20,
    assetPath: 'assets/gifts/hobbies/andril_stamp.png',
  ),
  AndrilGift(
    id: 'HOB-G10',
    name: 'Hobby Star',
    coins: 20,
    assetPath: 'assets/gifts/hobbies/hobby_star.png',
  ),
];

/// MOCK Social gift catalog (10 items).
/// Preserves exact v6 asset paths and Moon Lamp sticker override.
const socialGifts = <SocialGift>[
  SocialGift(
    id: 'SOC-G01',
    name: 'Teddy Bear',
    coins: 1,
    assetPath: 'assets/gifts/01_teddy_bear.png',
  ),
  SocialGift(
    id: 'SOC-G02',
    name: 'Love Note',
    coins: 1,
    assetPath: 'assets/gifts/02_love_note.png',
  ),
  SocialGift(
    id: 'SOC-G03',
    name: 'White Heart',
    coins: 2,
    assetPath: 'assets/gifts/03_white_heart.png',
  ),
  SocialGift(
    id: 'SOC-G04',
    name: 'Moon Lamp',
    coins: 2,
    assetPath: 'assets/gifts/04_moon_lamp.png',
    stickerOverride: 'assets/stickers/full_moon_sticker.png',
  ),
  SocialGift(
    id: 'SOC-G05',
    name: 'Butterfly',
    coins: 5,
    assetPath: 'assets/gifts/05_butterfly.png',
  ),
  SocialGift(
    id: 'SOC-G06',
    name: 'Joy Lantern',
    coins: 5,
    assetPath: 'assets/gifts/06_joy_lantern.png',
  ),
  SocialGift(
    id: 'SOC-G07',
    name: 'Red Heart',
    coins: 10,
    assetPath: 'assets/gifts/07_red_heart.png',
  ),
  SocialGift(
    id: 'SOC-G08',
    name: 'Time Capsule',
    coins: 10,
    assetPath: 'assets/gifts/08_time_capsule.png',
  ),
  SocialGift(
    id: 'SOC-G09',
    name: 'Red Rose',
    coins: 20,
    assetPath: 'assets/gifts/09_red_rose.png',
  ),
  SocialGift(
    id: 'SOC-G10',
    name: 'Proposal',
    coins: 20,
    assetPath: 'assets/gifts/10_proposal.png',
  ),
];
