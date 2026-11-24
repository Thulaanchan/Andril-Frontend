import 'package:flutter/foundation.dart';

/// ViewModel managing state and pagination for the Learning Welcome screen.
///
/// Follows ChangeNotifier pattern without storing tokens, user data, or global state.
class LearningWelcomeViewModel extends ChangeNotifier {
  /// Total number of preview cards in the Welcome feature carousel.
  static const int cardCount = 3;

  int _currentIndex = 0;

  /// The zero-based index of the currently active feature card (0, 1, or 2).
  int get currentIndex => _currentIndex;

  /// Updates the active feature card index.
  ///
  /// Clamps [newIndex] to [0, cardCount - 1] to prevent unsupported indices
  /// and avoids redundant notifications if the index has not changed.
  void setIndex(int newIndex) {
    final int clampedIndex = newIndex.clamp(0, cardCount - 1);
    if (_currentIndex != clampedIndex) {
      _currentIndex = clampedIndex;
      notifyListeners();
    }
  }

  /// Advances to the next card index if not already at the final card.
  void nextCard() {
    if (_currentIndex < cardCount - 1) {
      setIndex(_currentIndex + 1);
    }
  }

  /// Returns to the previous card index if not already at the first card.
  void previousCard() {
    if (_currentIndex > 0) {
      setIndex(_currentIndex - 1);
    }
  }
}
