import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/personality/data/repositories/personality_questionnaire_repository.dart';
import 'package:andril_mobile/features/social/personality/domain/entities/personality_questionnaire.dart';
import 'package:andril_mobile/features/social/personality/presentation/viewmodels/personality_questionnaire_viewmodel.dart';

class MockQuestionnaireRepository implements IPersonalityQuestionnaireRepository {
  QuestionnaireResult<PersonalityQuestionnaire> result =
      QuestionnaireResult.success(PersonalityQuestionnaire(
    version: 'v1.0',
    questions: [
      PersonalityQuestion(
        id: 'q01',
        prompt: 'Question 1',
        isRequired: true,
        options: [
          PersonalityOption(id: '1', label: 'Option 1'),
          PersonalityOption(id: '2', label: 'Option 2'),
        ],
      ),
      PersonalityQuestion(
        id: 'q02',
        prompt: 'Question 2',
        isRequired: false,
        options: [
          PersonalityOption(id: '1', label: 'Option A'),
        ],
      ),
    ],
  ));

  int callCount = 0;

  @override
  Future<QuestionnaireResult<PersonalityQuestionnaire>> getActiveQuestionnaire() async {
    callCount++;
    return result;
  }
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  final List<VoidCallback> _clearers = [];

  @override
  SessionPhase get phase => _phase;

  void setPhase(SessionPhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) {
    _clearers.add(clearer);
    return () => _clearers.remove(clearer);
  }

  void invokeClearers() {
    for (final c in List.of(_clearers)) {
      c();
    }
  }

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

  group('PersonalityQuestionnaireViewModel', () {
    test('initializes with initial status and empty state', () {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      expect(vm.status, PersonalityQuestionnaireStatus.initial);
      expect(vm.questionnaire, isNull);
      expect(vm.answerDraft, isNull);
      expect(vm.currentQuestionIndex, 0);
      expect(vm.progress, 0.0);
      expect(vm.isComplete, isFalse);
    });

    test('denies access if caller is not opted in to Social', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: false,
      );

      await vm.loadQuestionnaire();

      expect(vm.status, PersonalityQuestionnaireStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      expect(mockRepo.callCount, 0);
    });

    test('loads questionnaire successfully and initializes answer draft', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadQuestionnaire();

      expect(vm.status, PersonalityQuestionnaireStatus.ready);
      expect(vm.isReady, isTrue);
      expect(vm.totalQuestions, 2);
      expect(vm.currentQuestion?.id, 'q01');
      expect(vm.hasPreviousQuestion, isFalse);
      expect(vm.hasNextQuestion, isTrue);
      expect(vm.isLastQuestion, isFalse);
      expect(vm.answerDraft?.questionnaireVersion, 'v1.0');
    });

    test('handles option selection and answer updating', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadQuestionnaire();

      // Invalid option selection ignored
      vm.selectOption('invalid_option');
      expect(vm.selectedOptionForCurrentQuestion(), isNull);

      // Valid option selection recorded
      vm.selectOption('1');
      expect(vm.selectedOptionForCurrentQuestion(), '1');
      expect(vm.progress, 0.5);
      // q01 is required and answered, so questionnaire is complete!
      expect(vm.isComplete, isTrue);
    });

    test('handles question navigation backwards and forwards', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadQuestionnaire();

      expect(vm.previousQuestion(), isFalse);
      expect(vm.nextQuestion(), isTrue);
      expect(vm.currentQuestionIndex, 1);
      expect(vm.currentQuestion?.id, 'q02');
      expect(vm.isLastQuestion, isTrue);
      expect(vm.nextQuestion(), isFalse);

      expect(vm.previousQuestion(), isTrue);
      expect(vm.currentQuestionIndex, 0);

      // Direct jump
      vm.goToQuestion(1);
      expect(vm.currentQuestionIndex, 1);
    });

    test('clears private answer draft on cancellation', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadQuestionnaire();
      vm.selectOption('1');
      expect(vm.selectedOptionForCurrentQuestion(), '1');

      vm.cancelDraft();
      expect(vm.selectedOptionForCurrentQuestion(), isNull);
      expect(vm.progress, 0.0);
    });

    test('clears private answers on session sign-out or invalidation', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadQuestionnaire();
      vm.selectOption('1');

      // Trigger session sign-out
      fakeSession.setPhase(SessionPhase.signedOut);

      expect(vm.status, PersonalityQuestionnaireStatus.accessDenied);
      expect(vm.answerDraft?.answers.isEmpty ?? true, isTrue);
      expect(vm.questionnaire, isNull);
    });

    test('private state clearer resets private draft answers', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadQuestionnaire();
      vm.selectOption('1');
      expect(vm.selectedOptionForCurrentQuestion(), '1');

      // Session clearer invoked
      fakeSession.invokeClearers();
      expect(vm.selectedOptionForCurrentQuestion(), isNull);
    });

    test('handles service unavailable failure', () async {
      mockRepo.result = const QuestionnaireResult.failure(
        errorMessage: 'Questionnaires unavailable.',
        failureType: QuestionnaireFailureType.serviceUnavailable,
      );

      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        isSocialOptedIn: true,
      );

      await vm.loadQuestionnaire();

      expect(vm.status, PersonalityQuestionnaireStatus.serviceUnavailable);
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.errorMessage, 'Questionnaires unavailable.');
    });
  });
}
