export '../../../virtual_gifts/domain/gift_catalogs.dart';

class MoodTone {
  final String id;
  final String emoji;
  final String label;

  const MoodTone(this.id, this.emoji, this.label);
}

/// P-09 vocabulary is a selected UI design, not a signed BRD policy.
const socialMoodTones = <MoodTone>[
  MoodTone('romantic', '❤️', 'Romantic'),
  MoodTone('flirty', '😉', 'Flirty'),
  MoodTone('playful', '😜', 'Playful'),
  MoodTone('joyful', '😄', 'Joyful'),
  MoodTone('supportive', '🤗', 'Supportive'),
  MoodTone('curious', '🤔', 'Curious'),
  MoodTone('shy', '🫣', 'Shy'),
  MoodTone('serious', '🧐', 'Serious'),
  MoodTone('sad', '😔', 'Sad'),
  MoodTone('angry', '😠', 'Angry'),
];

enum ChatContentType { text, giftSticker, imagePreview, filePreview }

class ChatEntry {
  final ChatContentType type;
  final bool sent;
  final String text;
  final String time;
  final MoodTone? mood;
  final String? imagePath;
  final bool isLocalFile;

  const ChatEntry({
    this.type = ChatContentType.text,
    required this.sent,
    required this.text,
    required this.time,
    this.mood,
    this.imagePath,
    this.isLocalFile = false,
  });
}
