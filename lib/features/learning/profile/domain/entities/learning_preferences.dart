import 'package:flutter/foundation.dart';

/// Scoped domain entity representing a learner's module-specific preferences (Q07_LUC-03).
///
/// Follows approved visual specifications (Q07_LUC-03_Learning Preferences Setup):
/// 1. Communication Languages: English, Tamil, Tanglish
/// 2. Learning Styles: Video Learning, Reading / Articles, Discussion & Collaboration,
///    Hands-on Practice, Audio / Podcasts, Mini Projects
/// 3. Learning Availability: Morning (6 AM – 12 PM), Afternoon (12 PM – 6 PM),
///    Evening (6 PM – 10 PM), Late Night (10 PM – 2 AM), Flexible (Any time)
/// 4. Learning Notifications: Connection requests, Classroom & circle updates,
///    Learning tips & reminders
///
/// Confidentiality:
/// Personal preferences are confidential learner data. [toString] is redacted
/// to guarantee zero leakage into telemetry, logs, or exception traces.
@immutable
class LearningPreferences {
  /// Approved communication languages under Q07_LUC-03 specification.
  static const List<String> defaultLanguages = [
    'English',
    'Tamil',
    'Tanglish',
  ];

  /// Approved learning styles under Q07_LUC-03 specification.
  static const List<String> defaultLearningStyles = [
    'Video Learning',
    'Reading / Articles',
    'Discussion & Collaboration',
    'Hands-on Practice',
    'Audio / Podcasts',
    'Mini Projects',
  ];

  /// Approved learning availability options under Q07_LUC-03 specification.
  static const List<String> defaultAvailabilityOptions = [
    'Morning (6 AM – 12 PM)',
    'Afternoon (12 PM – 6 PM)',
    'Evening (6 PM – 10 PM)',
    'Late Night (10 PM – 2 AM)',
    'Flexible (Any time)',
  ];

  /// Approved notification preferences under Q07_LUC-03 specification.
  static const List<String> defaultNotificationOptions = [
    'Connection requests',
    'Classroom & circle updates',
    'Learning tips & reminders',
  ];

  /// Defensive unmodifiable collection of selected communication languages.
  final List<String> languages;

  /// Defensive unmodifiable collection of preferred learning styles.
  final List<String> learningStyles;

  /// Selected preferred availability window.
  final String? availability;

  /// Defensive unmodifiable map of notification preference toggles.
  final Map<String, bool> notifications;

  /// Creates an immutable [LearningPreferences] instance.
  const LearningPreferences({
    this.languages = const ['English'],
    this.learningStyles = const [],
    this.availability,
    this.notifications = const {},
  });

  /// Factory creating an empty preferences configuration.
  factory LearningPreferences.empty() {
    return const LearningPreferences(
      languages: [],
      learningStyles: [],
      availability: null,
      notifications: {},
    );
  }

  /// Factory creating a synthetic sample preferences configuration for previews and tests.
  factory LearningPreferences.syntheticSample() {
    return const LearningPreferences(
      languages: ['English', 'Tamil'],
      learningStyles: [
        'Video Learning',
        'Hands-on Practice',
        'Discussion & Collaboration',
      ],
      availability: 'Flexible (Any time)',
      notifications: {
        'Connection requests': true,
        'Classroom & circle updates': true,
        'Learning tips & reminders': false,
      },
    );
  }

  /// Creates a copy of this [LearningPreferences] with updated fields and defensive encapsulation.
  LearningPreferences copyWith({
    List<String>? languages,
    List<String>? learningStyles,
    String? availability,
    Map<String, bool>? notifications,
  }) {
    return LearningPreferences(
      languages: List.unmodifiable(languages ?? this.languages),
      learningStyles: List.unmodifiable(learningStyles ?? this.learningStyles),
      availability: availability ?? this.availability,
      notifications: Map.unmodifiable(notifications ?? this.notifications),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningPreferences &&
        listEquals(other.languages, languages) &&
        listEquals(other.learningStyles, learningStyles) &&
        other.availability == availability &&
        mapEquals(other.notifications, notifications);
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(languages),
      Object.hashAll(learningStyles),
      availability,
      Object.hashAll(notifications.keys),
      Object.hashAll(notifications.values),
    );
  }

  /// Strictly redacted representation to prevent confidential preference leakage.
  @override
  String toString() => 'LearningPreferences [private preferences omitted]';
}
