import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/personality/data/repositories/personality_questionnaire_repository.dart';
import 'package:andril_mobile/features/social/personality/domain/entities/personality_questionnaire.dart';
import 'package:andril_mobile/features/social/personality/presentation/screens/personality_intro_screen.dart';
import 'package:andril_mobile/features/social/personality/presentation/screens/personality_questionnaire_screen.dart';
import 'package:andril_mobile/features/social/personality/presentation/screens/personality_review_screen.dart';
import 'package:andril_mobile/features/social/personality/presentation/viewmodels/personality_questionnaire_viewmodel.dart';
import 'package:andril_mobile/features/social/smart_matching/presentation/social_smart_matching_screen.dart';

class MockQuestionnaireRepository implements IPersonalityQuestionnaireRepository {
  QuestionnaireResult<PersonalityQuestionnaire> result =
      QuestionnaireResult.success(PersonalityQuestionnaire(
    version: 'v1.0',
    questions: [
      PersonalityQuestion(
        id: 'q01',
        prompt: 'How do you spend your free weekends?',
        isRequired: true,
        options: [
          PersonalityOption(id: '1', label: 'Exploring outdoors'),
          PersonalityOption(id: '2', label: 'Relaxing at home'),
        ],
      ),
      PersonalityQuestion(
        id: 'q02',
        prompt: 'When meeting new people in a social setting:',
        isRequired: false,
        options: [
          PersonalityOption(id: '1', label: 'Introduce proactively'),
          PersonalityOption(id: '2', label: 'Observe first'),
        ],
      ),
    ],
  ));

  @override
  Future<QuestionnaireResult<PersonalityQuestionnaire>> getActiveQuestionnaire() async => result;
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  @override
  SessionPhase get phase => SessionPhase.signedIn;

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) => () {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockQuestionnaireRepository mockRepo;
  late FakeSessionController fakeSession;

  setUp(() {
    mockRepo = MockQuestionnaireRepository();
    fakeSession = FakeSessionController();
  });

  Widget buildTestHost(Widget child, {Size size = const Size(400, 800), double textScale = 1.0}) {
    return MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('PersonalityIntroScreen', () {
    testWidgets('renders intro content and triggers start and skip callbacks', (tester) async {
      bool started = false;
      bool skipped = false;

      await tester.pumpWidget(buildTestHost(PersonalityIntroScreen(
        onStart: () => started = true,
        onSkip: () => skipped = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Discover Your Vibe'), findsOneWidget);
      expect(find.text('Private & Protected'), findsOneWidget);
      expect(find.text('Completely Optional'), findsOneWidget);

      final startBtn = find.byKey(const Key('start_quiz_button'));
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      expect(started, isTrue);

      final skipBtn = find.byKey(const Key('skip_quiz_button'));
      await tester.ensureVisible(skipBtn);
      await tester.tap(skipBtn);
      expect(skipped, isTrue);
    });
  });

  group('PersonalityQuestionnaireScreen', () {
    testWidgets('renders questions dynamically, selects options, and navigates', (tester) async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      bool completed = false;
      await tester.pumpWidget(buildTestHost(PersonalityQuestionnaireScreen(
        viewModel: vm,
        onComplete: () => completed = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Question 1 of 2'), findsOneWidget);
      expect(find.text('How do you spend your free weekends?'), findsOneWidget);
      expect(find.text('Exploring outdoors'), findsOneWidget);
      expect(find.text('Relaxing at home'), findsOneWidget);

      // Next button disabled before required answer
      final nextBtn = find.byKey(const Key('next_question_button'));
      expect(tester.widget<FilledButton>(nextBtn).onPressed, isNull);

      // Select option 1
      await tester.tap(find.byKey(const Key('option_1')));
      await tester.pumpAndSettle();

      // Now Next button enabled
      expect(tester.widget<FilledButton>(nextBtn).onPressed, isNotNull);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // On question 2
      expect(find.text('Question 2 of 2'), findsOneWidget);
      expect(find.text('When meeting new people in a social setting:'), findsOneWidget);

      // Since Q2 is optional, finish button is enabled
      final finishBtn = find.byKey(const Key('finish_quiz_button'));
      expect(tester.widget<FilledButton>(finishBtn).onPressed, isNotNull);

      await tester.tap(finishBtn);
      expect(completed, isTrue);
    });
  });

  group('PersonalityReviewScreen', () {
    testWidgets('renders question summary cards, edit callbacks, and dormant notice', (tester) async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      await vm.loadQuestionnaire();
      vm.selectOption('1'); // answer Q1

      int? editedIndex;
      bool saved = false;

      await tester.pumpWidget(buildTestHost(PersonalityReviewScreen(
        viewModel: vm,
        onEditQuestion: (idx) => editedIndex = idx,
        onDone: () => saved = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Review Answers'), findsOneWidget);
      expect(find.text('All Required Questions Answered'), findsOneWidget);
      expect(find.text('Exploring outdoors'), findsOneWidget);
      expect(find.text('Skipped (Optional)'), findsOneWidget);

      // Tap edit button on Q1
      await tester.tap(find.byKey(const Key('edit_question_0')));
      expect(editedIndex, 0);

      // Tap save
      final saveBtn = find.byKey(const Key('save_review_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      expect(saved, isTrue);
    });
  });

  group('SocialSmartMatchingScreen', () {
    testWidgets('renders unavailable state when matching service is dormant', (tester) async {
      bool checked = false;
      await tester.pumpWidget(buildTestHost(SocialSmartMatchingScreen(
        state: SmartMatchingState.unavailable,
        onRetry: () => checked = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Smart Matching Preparing'), findsOneWidget);
      await tester.tap(find.byKey(const Key('retry_button')));
      expect(checked, isTrue);
    });

    testWidgets('renders ready state with verified criteria highlights', (tester) async {
      const explanation = ServerMatchExplanation(
        matchedCandidateName: 'Elena',
        sharedGoals: ['Long-term dating'],
        commonInterests: ['Coffee', 'Photography'],
        approximateDistance: '8 km away',
      );

      await tester.pumpWidget(buildTestHost(const SocialSmartMatchingScreen(
        state: SmartMatchingState.ready,
        matchExplanation: explanation,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Compatibility Highlights'), findsOneWidget);
      expect(find.text('Long-term dating'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('8 km away'), findsOneWidget);
    });
  });

  group('Responsive Viewport Tests', () {
    testWidgets('all Batch 06 screens render across 320dp, 400dp, 800dp viewports without overflow', (tester) async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );
      await vm.loadQuestionnaire();
      vm.selectOption('1');

      for (final size in [
        const Size(320, 640),
        const Size(400, 800),
        const Size(800, 1200),
      ]) {
        // Intro
        await tester.pumpWidget(buildTestHost(PersonalityIntroScreen(onStart: () {}, onSkip: () {}), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Quiz
        await tester.pumpWidget(buildTestHost(PersonalityQuestionnaireScreen(viewModel: vm), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Review
        await tester.pumpWidget(buildTestHost(PersonalityReviewScreen(viewModel: vm), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Smart Matching
        await tester.pumpWidget(buildTestHost(const SocialSmartMatchingScreen(state: SmartMatchingState.unavailable), size: size));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
