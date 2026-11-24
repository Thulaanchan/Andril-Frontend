import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/common/chat_theme.dart';
import 'package:andril_mobile/features/common/chat/domain/module_config.dart';
import 'package:andril_mobile/features/common/virtual_gifts/domain/gift_catalogs.dart';

void main() {
  group('M4 Chat Foundation — Module Configuration & Theme Isolation', () {
    test('1. Exactly three modules exist (Learning, Hobbies, Social)', () {
      expect(AndrilModuleType.values.length, 3);
      expect(
        AndrilModuleType.values,
        containsAll([
          AndrilModuleType.learning,
          AndrilModuleType.hobbies,
          AndrilModuleType.social,
        ]),
      );
      expect(AndrilModuleConfig.values.length, 3);
      expect(AndrilModuleConfig.values.map((c) => c.type).toList(), [
        AndrilModuleType.learning,
        AndrilModuleType.hobbies,
        AndrilModuleType.social,
      ]);
    });

    test('2. Each module uses the correct approved theme colors', () {
      // Learning theme
      final learning = AndrilModuleConfig.learning.theme;
      expect(learning.primary, const Color(0xFF2563EB)); // Approved Blue
      expect(learning.background, const Color(0xFFEEF2FF)); // Light Blue
      expect(learning.dark, const Color(0xFF1D4ED8)); // Dark Blue
      expect(learning.accent, const Color(0xFF006D77)); // Shared Teal accent

      // Hobbies theme
      final hobbies = AndrilModuleConfig.hobbies.theme;
      expect(hobbies.primary, const Color(0xFF16A34A)); // Primary Green
      expect(hobbies.background, const Color(0xFFECFDF5)); // Mint Background
      expect(hobbies.dark, const Color(0xFF006251)); // Dark Green
      expect(hobbies.accent, const Color(0xFF01999A)); // Prototype Teal Accent
      expect((hobbies as HobbiesChatTheme).teal, const Color(0xFF01999A));

      // Social theme
      final social = AndrilModuleConfig.social.theme;
      expect(social.primary, const Color(0xFF330099)); // Royal Purple
      expect(social.background, const Color(0xFFFAF7F2)); // Cream
      expect(
        (social as SocialChatTheme).copper,
        const Color(0xFFC47A44),
      ); // Copper
      expect(social.dark, const Color(0xFF1B1047)); // Ink
    });

    test('3. Learning and Hobbies configurations cannot enable MoodTone', () {
      expect(AndrilModuleConfig.learning.allowsMoodTone, isFalse);
      expect(AndrilModuleConfig.learning.supportsMoodTone, isFalse);

      expect(AndrilModuleConfig.hobbies.allowsMoodTone, isFalse);
      expect(AndrilModuleConfig.hobbies.supportsMoodTone, isFalse);

      expect(AndrilModuleConfig.social.allowsMoodTone, isTrue);
      expect(AndrilModuleConfig.social.supportsMoodTone, isTrue);

      // Invariant test: Server-side DEC-20261111-MOOD-01 policy enforcement
      // Even if allowsMoodTone is erroneously set to true on non-social module, supportsMoodTone must be false.
      const illegalLearning = AndrilModuleConfig(
        type: AndrilModuleType.learning,
        name: 'Illegal Learning',
        theme: LearningChatTheme(),
        giftCatalog: learningGifts,
        defaultPartner: AndrilModuleProfile(
          name: 'Maya',
          status: 'Online',
          avatarAsset: 'assets/profile/maya_avatar.webp',
          moduleType: AndrilModuleType.learning,
        ),
        allowsMoodTone: true,
      );
      expect(illegalLearning.supportsMoodTone, isFalse);

      const illegalHobbies = AndrilModuleConfig(
        type: AndrilModuleType.hobbies,
        name: 'Illegal Hobbies',
        theme: HobbiesChatTheme(),
        giftCatalog: hobbiesGifts,
        defaultPartner: AndrilModuleProfile(
          name: 'Nila',
          status: 'Online',
          avatarAsset: 'assets/profile/nila_avatar.png',
          moduleType: AndrilModuleType.hobbies,
        ),
        allowsMoodTone: true,
      );
      expect(illegalHobbies.supportsMoodTone, isFalse);
    });
  });

  group('M4 Chat Foundation — Gift Catalogs & Asset Resolution', () {
    test(
        '4. Each module has exactly 10 gift assets with non-authoritative MOCK coin pricing',
        () {
      expect(learningGifts.length, 10);
      expect(hobbiesGifts.length, 10);
      expect(socialGifts.length, 10);

      // Standard sample mock coin distribution: 1, 1, 2, 2, 5, 5, 10, 10, 20, 20
      const expectedCoins = [1, 1, 2, 2, 5, 5, 10, 10, 20, 20];
      expect(learningGifts.map((g) => g.coins).toList(), expectedCoins);
      expect(hobbiesGifts.map((g) => g.coins).toList(), expectedCoins);
      expect(socialGifts.map((g) => g.coins).toList(), expectedCoins);
    });

    test('5. Gift and avatar assets resolve correctly on disk', () {
      for (final gift in learningGifts) {
        expect(
          File(gift.assetPath).existsSync(),
          isTrue,
          reason: 'Missing Learning asset: ${gift.assetPath}',
        );
      }

      for (final gift in hobbiesGifts) {
        expect(
          File(gift.assetPath).existsSync(),
          isTrue,
          reason: 'Missing Hobbies asset: ${gift.assetPath}',
        );
      }

      for (final gift in socialGifts) {
        expect(
          File(gift.assetPath).existsSync(),
          isTrue,
          reason: 'Missing Social asset: ${gift.assetPath}',
        );
        if (gift.stickerOverride != null) {
          expect(
            File(gift.stickerOverride!).existsSync(),
            isTrue,
            reason: 'Missing sticker override: ${gift.stickerOverride}',
          );
        }
      }

      // Partner avatar resolution
      for (final config in AndrilModuleConfig.values) {
        expect(
          File(config.defaultPartner.avatarAsset).existsSync(),
          isTrue,
          reason:
              'Missing partner avatar: ${config.defaultPartner.avatarAsset}',
        );
      }
    });

    test('6. No cross-module gift catalog mixing occurs', () {
      final learningIds = learningGifts.map((g) => g.id).toSet();
      final hobbiesIds = hobbiesGifts.map((g) => g.id).toSet();
      final socialIds = socialGifts.map((g) => g.id).toSet();

      // IDs must be unique per module namespace
      expect(learningIds.every((id) => id.startsWith('LRN-')), isTrue);
      expect(hobbiesIds.every((id) => id.startsWith('HOB-')), isTrue);
      expect(socialIds.every((id) => id.startsWith('SOC-')), isTrue);

      expect(learningIds.intersection(hobbiesIds), isEmpty);
      expect(learningIds.intersection(socialIds), isEmpty);
      expect(hobbiesIds.intersection(socialIds), isEmpty);

      // Asset paths must not intersect
      final learningPaths = learningGifts.map((g) => g.assetPath).toSet();
      final hobbiesPaths = hobbiesGifts.map((g) => g.assetPath).toSet();
      final socialPaths = socialGifts.map((g) => g.assetPath).toSet();

      expect(learningPaths.intersection(hobbiesPaths), isEmpty);
      expect(learningPaths.intersection(socialPaths), isEmpty);
      expect(hobbiesPaths.intersection(socialPaths), isEmpty);
    });
  });
}
