import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/profile/viewmodels/learning_welcome_viewmodel.dart';

void main() {
  group('LearningWelcomeViewModel', () {
    late LearningWelcomeViewModel viewModel;

    setUp(() {
      viewModel = LearningWelcomeViewModel();
    });

    test('initializes with default card index 0', () {
      expect(viewModel.currentIndex, 0);
      expect(LearningWelcomeViewModel.cardCount, 3);
    });

    test('updates index and notifies listeners on valid change', () {
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.setIndex(1);
      expect(viewModel.currentIndex, 1);
      expect(notifications, 1);

      viewModel.setIndex(2);
      expect(viewModel.currentIndex, 2);
      expect(notifications, 2);
    });

    test('does not notify listeners when index is unchanged', () {
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.setIndex(0);
      expect(viewModel.currentIndex, 0);
      expect(notifications, 0);

      viewModel.setIndex(1);
      expect(notifications, 1);

      viewModel.setIndex(1);
      expect(notifications, 1);
    });

    test('safely clamps negative indices to 0', () {
      viewModel.setIndex(1);
      expect(viewModel.currentIndex, 1);

      viewModel.setIndex(-10);
      expect(viewModel.currentIndex, 0);
    });

    test('safely clamps excessive indices to max card index', () {
      viewModel.setIndex(99);
      expect(viewModel.currentIndex, 2);
    });

    test('nextCard advances index sequentially and respects boundary', () {
      expect(viewModel.currentIndex, 0);

      viewModel.nextCard();
      expect(viewModel.currentIndex, 1);

      viewModel.nextCard();
      expect(viewModel.currentIndex, 2);

      // Boundary check
      viewModel.nextCard();
      expect(viewModel.currentIndex, 2);
    });

    test('previousCard decrements index sequentially and respects boundary',
        () {
      viewModel.setIndex(2);
      expect(viewModel.currentIndex, 2);

      viewModel.previousCard();
      expect(viewModel.currentIndex, 1);

      viewModel.previousCard();
      expect(viewModel.currentIndex, 0);

      // Boundary check
      viewModel.previousCard();
      expect(viewModel.currentIndex, 0);
    });
  });
}
