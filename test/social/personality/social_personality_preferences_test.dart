import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/interests_preferences/domain/social_preferences_model.dart';
import 'package:andril_mobile/features/social/interests_preferences/presentation/social_discovery_languages_screen.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';
import 'package:andril_mobile/features/social/personality/data/repositories/personality_questionnaire_repository.dart';
import 'package:andril_mobile/features/social/personality/domain/entities/personality_questionnaire.dart';
import 'package:andril_mobile/features/social/personality/presentation/screens/personality_answers_screen.dart';
import 'package:andril_mobile/features/social/personality/presentation/screens/personality_review_screen.dart';
import 'package:andril_mobile/features/social/personality/presentation/viewmodels/personality_questionnaire_viewmodel.dart';
import 'package:andril_mobile/features/social/smart_matching/presentation/social_smart_matching_screen.dart';

class MockQuestionnaireRepo implements IPersonalityQuestionnaireRepository {
  QuestionnaireResult<PersonalityQuestionnaire> result =
      QuestionnaireResult.success(PersonalityQuestionnaire(
    version: 'v1.0',
    questions: [
      PersonalityQuestion(
        id: 'q01',
        prompt: 'What is your ideal weekend activity?',
        isRequired: true,
        options: [
          PersonalityOption(id: '1', label: 'Hiking in nature'),
          PersonalityOption(id: '2', label: 'Coffee and books'),
        ],
      ),
      PersonalityQuestion(
        id: 'q02',
        prompt: 'How do you prefer to communicate with new friends?',
        isRequired: false,
        options: [
          PersonalityOption(id: '1', label: 'Text messaging'),
          PersonalityOption(id: '2', label: 'In-person conversation'),
        ],
      ),
    ],
  ));

  @override
  Future<QuestionnaireResult<PersonalityQuestionnaire>> getActiveQuestionnaire() async => result;
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject = 'test-user-123';
  VoidCallback? _clearer;

  @override
  SessionPhase get phase => _phase;

  @override
  String? get subject => _subject;

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) {
    _clearer = clearer;
    return () => _clearer = null;
  }

  void signOut() {
    _phase = SessionPhase.signedOut;
    _subject = null;
    _clearer?.call();
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockQuestionnaireRepo mockRepo;
  late FakeSessionController fakeSession;

  setUp(() {
    mockRepo = MockQuestionnaireRepo();
    fakeSession = FakeSessionController();
  });

  Widget buildTestHost(
    Widget child, {
    Size size = const Size(400, 800),
    double textScale = 1.0,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Task 139 - S28 Why We Matched (SocialSmartMatchingScreen)', () {
    testWidgets('renders ready state with verified highlights and triggers back/explore callbacks', (tester) async {
      bool backed = false;
      bool explored = false;

      const explanation = ServerMatchExplanation(
        matchedCandidateName: 'Aria',
        sharedGoals: ['Meaningful friendships', 'Language exchange'],
        commonInterests: ['Photography', 'Travel'],
        approximateDistance: '12 km away',
      );

      await tester.pumpWidget(buildTestHost(SocialSmartMatchingScreen(
        state: SmartMatchingState.ready,
        matchExplanation: explanation,
        onBack: () => backed = true,
        onExplore: () => explored = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Why We Matched'), findsOneWidget);
      expect(find.text('Compatibility Highlights'), findsOneWidget);
      expect(find.text('Shared preferences between you and Aria'), findsOneWidget);
      expect(find.text('Meaningful friendships'), findsOneWidget);
      expect(find.text('Photography'), findsOneWidget);
      expect(find.text('12 km away'), findsOneWidget);

      // Back button
      await tester.tap(find.byKey(const Key('why_we_matched_back_button')));
      expect(backed, isTrue);

      // Explore button
      final exploreBtn = find.byKey(const Key('explore_button'));
      await tester.ensureVisible(exploreBtn);
      await tester.tap(exploreBtn);
      expect(explored, isTrue);
    });

    testWidgets('renders unavailable and empty states accurately', (tester) async {
      bool retried = false;
      bool tookQuiz = false;

      // Unavailable state
      await tester.pumpWidget(buildTestHost(SocialSmartMatchingScreen(
        state: SmartMatchingState.unavailable,
        errorMessage: 'Matching backend service is preparing.',
        onRetry: () => retried = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Smart Matching Preparing'), findsOneWidget);
      expect(find.text('Matching backend service is preparing.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('retry_button')));
      expect(retried, isTrue);

      // Empty state
      await tester.pumpWidget(buildTestHost(SocialSmartMatchingScreen(
        state: SmartMatchingState.empty,
        onRetakeQuiz: () => tookQuiz = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('No Criteria Available'), findsOneWidget);
      await tester.tap(find.byKey(const Key('take_quiz_button')));
      expect(tookQuiz, isTrue);
    });
  });

  group('Task 140 - S37 Personality Answers (PersonalityAnswersScreen)', () {
    testWidgets('renders empty answers state when no draft exists', (tester) async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'test-user-123'),
      );

      bool tookQuiz = false;
      await tester.pumpWidget(buildTestHost(PersonalityAnswersScreen(
        viewModel: vm,
        onRetakeQuiz: () => tookQuiz = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Personality Answers'), findsOneWidget);
      expect(find.text('No Answers Recorded'), findsOneWidget);

      await tester.tap(find.byKey(const Key('take_quiz_button')));
      expect(tookQuiz, isTrue);
    });

    testWidgets('renders user answers, privacy notice, edit triggers, and retake quiz', (tester) async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'test-user-123'),
      );
      await vm.loadQuestionnaire();
      vm.selectOption('1'); // answer Q1 with 'Hiking in nature'

      int? editedIndex;
      bool retook = false;
      bool backed = false;

      await tester.pumpWidget(buildTestHost(PersonalityAnswersScreen(
        viewModel: vm,
        onEditQuestion: (idx) => editedIndex = idx,
        onRetakeQuiz: () => retook = true,
        onBack: () => backed = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Private to You'), findsOneWidget);
      expect(find.text('Recorded Answers (1 of 2)'), findsOneWidget);
      expect(find.text('What is your ideal weekend activity?'), findsOneWidget);
      expect(find.text('Hiking in nature'), findsOneWidget);
      expect(find.text('Skipped (Optional)'), findsOneWidget);

      // Tap edit on Q1
      await tester.tap(find.byKey(const Key('edit_answer_0')));
      expect(editedIndex, 0);

      // Back navigation
      await tester.tap(find.byKey(const Key('personality_answers_back_button')));
      expect(backed, isTrue);

      // Retake quiz button
      final retakeBtn = find.byKey(const Key('retake_quiz_button'));
      await tester.ensureVisible(retakeBtn);
      await tester.tap(retakeBtn);
      expect(retook, isTrue);
    });

    testWidgets('clears private answers and restricts access on session signout', (tester) async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'test-user-123'),
      );
      await vm.loadQuestionnaire();
      vm.selectOption('1');

      await tester.pumpWidget(buildTestHost(PersonalityAnswersScreen(viewModel: vm)));
      await tester.pumpAndSettle();
      expect(find.text('Hiking in nature'), findsOneWidget);

      // Sign out
      fakeSession.signOut();
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(vm.answerDraft, isNull);
    });
  });

  group('Task 140 - S82 Questionnaire Review (PersonalityReviewScreen)', () {
    testWidgets('displays review summary, edit callbacks, and dormant notice', (tester) async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'test-user-123'),
      );
      await vm.loadQuestionnaire();
      vm.selectOption('1');

      int? edited;
      bool completed = false;

      await tester.pumpWidget(buildTestHost(PersonalityReviewScreen(
        viewModel: vm,
        onEditQuestion: (idx) => edited = idx,
        onDone: () => completed = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Review Answers'), findsOneWidget);
      expect(find.text('All Required Questions Answered'), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit_question_0')));
      expect(edited, 0);

      final saveBtn = find.byKey(const Key('save_review_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      expect(completed, isTrue);
    });
  });

  group('Task 141 - S81 Edit Discovery Languages (SocialDiscoveryLanguagesScreen)', () {
    testWidgets('renders available languages, toggles selection, and emits unmodifiable set on save', (tester) async {
      Set<String>? savedLanguages;
      bool cancelled = false;

      await tester.pumpWidget(buildTestHost(SocialDiscoveryLanguagesScreen(
        initialSelectedLanguages: const {'English'},
        onSave: (langs) => savedLanguages = langs,
        onCancel: () => cancelled = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Edit Discovery Languages'), findsOneWidget);
      expect(find.text('Selected (1)'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Tamil'), findsOneWidget);

      // Toggle Tamil
      await tester.tap(find.byKey(const Key('language_tile_Tamil')));
      await tester.pumpAndSettle();
      expect(find.text('Selected (2)'), findsOneWidget);

      // Save
      await tester.tap(find.byKey(const Key('save_languages_button')));
      await tester.pumpAndSettle();

      expect(savedLanguages, isNotNull);
      expect(savedLanguages, contains('English'));
      expect(savedLanguages, contains('Tamil'));
      expect(() => savedLanguages!.add('Sinhala'), throwsUnsupportedError);

      // Cancel button
      await tester.tap(find.byKey(const Key('cancel_languages_button')));
      expect(cancelled, isTrue);
    });

    testWidgets('filters languages via search and clear all button operates correctly', (tester) async {
      await tester.pumpWidget(buildTestHost(const SocialDiscoveryLanguagesScreen(
        initialSelectedLanguages: {'English', 'Tamil'},
      )));
      await tester.pumpAndSettle();

      expect(find.text('Selected (2)'), findsOneWidget);

      // Search 'Sin'
      await tester.enterText(find.byKey(const Key('language_search_field')), 'Sin');
      await tester.pumpAndSettle();

      expect(find.text('Sinhala'), findsOneWidget);
      expect(find.text('English'), findsNothing);

      // Clear search
      await tester.enterText(find.byKey(const Key('language_search_field')), '');
      await tester.pumpAndSettle();
      expect(find.text('English'), findsOneWidget);

      // Clear all
      await tester.tap(find.byKey(const Key('clear_all_languages_button')));
      await tester.pumpAndSettle();
      expect(find.text('Selected (0)'), findsOneWidget);
    });

    testWidgets('updates SocialPreferencesModel context on apply', (tester) async {
      final initialPrefs = SocialPreferencesModel(
        showMe: 'Everyone',
        minAge: 21,
        maxAge: 35,
        languages: {'English'},
      );

      SocialPreferencesModel? appliedPrefs;

      await tester.pumpWidget(buildTestHost(SocialDiscoveryLanguagesScreen(
        preferencesContext: initialPrefs,
        onApplyPreferences: (model) => appliedPrefs = model,
      )));
      await tester.pumpAndSettle();

      // Toggle Sinhala
      await tester.tap(find.byKey(const Key('language_tile_Sinhala')));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.byKey(const Key('save_languages_button')));
      await tester.pumpAndSettle();

      expect(appliedPrefs, isNotNull);
      expect(appliedPrefs!.showMe, 'Everyone');
      expect(appliedPrefs!.minAge, 21);
      expect(appliedPrefs!.maxAge, 35);
      expect(appliedPrefs!.languages, containsAll({'English', 'Sinhala'}));
    });
  });

  group('Batch 05 Responsive Viewports', () {
    testWidgets('all Batch 05 screens render across 320dp, 400dp, 800dp viewports without overflow', (tester) async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'test-user-123'),
      );
      await vm.loadQuestionnaire();
      vm.selectOption('1');

      for (final size in [
        const Size(320, 640),
        const Size(400, 800),
        const Size(800, 1200),
      ]) {
        // S28 Why We Matched
        await tester.pumpWidget(buildTestHost(
          const SocialSmartMatchingScreen(
            state: SmartMatchingState.ready,
            matchExplanation: ServerMatchExplanation(
              matchedCandidateName: 'Maya',
              sharedGoals: ['Friendship'],
              commonInterests: ['Art'],
            ),
          ),
          size: size,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // S37 Personality Answers
        await tester.pumpWidget(buildTestHost(
          PersonalityAnswersScreen(viewModel: vm),
          size: size,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // S82 Questionnaire Review
        await tester.pumpWidget(buildTestHost(
          PersonalityReviewScreen(viewModel: vm),
          size: size,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // S81 Edit Discovery Languages
        await tester.pumpWidget(buildTestHost(
          const SocialDiscoveryLanguagesScreen(
            initialSelectedLanguages: {'English', 'Tamil'},
          ),
          size: size,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
