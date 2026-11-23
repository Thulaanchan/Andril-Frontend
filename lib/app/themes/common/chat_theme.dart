import 'package:flutter/material.dart';

import '../social/social_theme.dart';

/// Base contract for ANDRIL chat themes across Learning, Hobbies, and Social.
/// Preserves approved brand colors and module isolation.
abstract class AndrilChatTheme {
  Color get primary;
  Color get background;
  Color get dark;
  Color get ink;
  Color get border;
  Color get giftTile;
  Color get incomingBubble;
  Color get outgoingBubble;
  Color get incomingText;
  Color get outgoingText;
  Color get accent;

  const AndrilChatTheme();
}

/// Approved Learning Palette: Blue #2563EB, Background #EEF2FF, Dark #1D4ED8.
/// Teal #006D77 is retained as an accent for shared UI elements (e.g. gift sheet header).
class LearningChatTheme extends AndrilChatTheme {
  const LearningChatTheme();

  @override
  Color get primary => const Color(0xFF2563EB);

  @override
  Color get background => const Color(0xFFEEF2FF);

  @override
  Color get dark => const Color(0xFF1D4ED8);

  @override
  Color get ink => const Color(0xFF162B56);

  @override
  Color get border => const Color(0xFFDCE3FC);

  @override
  Color get giftTile => const Color(0xFFF0F4FF);

  @override
  Color get incomingBubble => Colors.white;

  @override
  Color get outgoingBubble => const Color(0xFF2563EB);

  @override
  Color get incomingText => const Color(0xFF162B56);

  @override
  Color get outgoingText => Colors.white;

  @override
  Color get accent => const Color(0xFF006D77);
}

/// Approved Hobbies Palette: Primary Green #16A34A, Background #ECFDF5.
/// Preserves prototype Teal #01999A and Dark #006251 accents.
class HobbiesChatTheme extends AndrilChatTheme {
  const HobbiesChatTheme();

  @override
  Color get primary => const Color(0xFF16A34A);

  @override
  Color get background => const Color(0xFFECFDF5);

  @override
  Color get dark => const Color(0xFF006251);

  Color get teal => const Color(0xFF01999A);

  @override
  Color get ink => const Color(0xFF133E39);

  @override
  Color get border => const Color(0xFFDCEFEA);

  @override
  Color get giftTile => const Color(0xFFF0FDF8);

  @override
  Color get incomingBubble => Colors.white;

  @override
  Color get outgoingBubble => const Color(0xFF008F81);

  @override
  Color get incomingText => const Color(0xFF133E39);

  @override
  Color get outgoingText => Colors.white;

  @override
  Color get accent => const Color(0xFF01999A);
}

/// Approved Social Palette: Royal Purple #330099, Copper #C47A44, Cream #FAF7F2.
class SocialChatTheme extends AndrilChatTheme {
  const SocialChatTheme();

  @override
  Color get primary => AndrilSocialColors.royalPurple; // #330099

  Color get copper => AndrilSocialColors.copper; // #C47A44

  @override
  Color get background => AndrilSocialColors.cream; // #FAF7F2

  Color get canvasCream => AndrilSocialColors.canvasCream; // #FFFFFCFA

  @override
  Color get dark => AndrilSocialColors.ink;

  @override
  Color get ink => AndrilSocialColors.ink; // #1B1047

  @override
  Color get border => AndrilSocialColors.border; // #E5DDE8

  @override
  Color get giftTile => AndrilSocialColors.giftTile; // #F7EDF4

  @override
  Color get incomingBubble => AndrilSocialColors.canvasCream;

  @override
  Color get outgoingBubble => AndrilSocialColors.royalPurple;

  @override
  Color get incomingText => AndrilSocialColors.ink;

  @override
  Color get outgoingText => Colors.white;

  @override
  Color get accent => AndrilSocialColors.copper;
}
