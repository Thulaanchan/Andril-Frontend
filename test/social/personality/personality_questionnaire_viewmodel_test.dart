import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';
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
  int submitCount = 0;
  QuestionnaireResult<bool> submitResult = const QuestionnaireResult.success(true);
  QuestionnaireResult<PersonalityAnswerDraft> savedResult =
      QuestionnaireResult.success(PersonalityAnswerDraft(questionnaireVersion: 'v1.0'));

  @override
  Future<QuestionnaireResult<PersonalityQuestionnaire>> getActiveQuestionnaire() async {
    callCount++;
    return result;
  }

  @override
  Future<QuestionnaireResult<bool>> submitAnswers(
    PersonalityAnswerDraft draft, {
    bool skip = false,
  }) async {
    submitCount++;
    return submitResult;
  }

  @override
  Future<QuestionnaireResult<PersonalityAnswerDraft>> getSavedAnswers() async =>
      savedResult;
}

class FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject = 'user-test-123';
  final List<VoidCallback> _clearers = [];

  FakeSessionController({
    SessionPhase phase = SessionPhase.signedIn,
    String? subject = 'user-test-123',
  })  : _phase = phase,
        _subject = subject;

  @override
  SessionPhase get phase => _phase;

  @override
  String? get subject => _subject;

  set subject(String? newSubject) {
    _subject = newSubject;
    notifyListeners();
  }

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

  group('PersonalityQuestionnaireViewModel Security & Lifecycle Tests (Tasks 113-114)', () {
    test('default construction fails closed (isSocialOptedIn defaults to false, no evidence)', () {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
      );

      expect(vm.status, PersonalityQuestionnaireStatus.initial);
      expect(vm.questionnaire, isNull);
      expect(vm.answerDraft, isNull);
      expect(vm.currentQuestionIndex, 0);
      expect(vm.progress, 0.0);
      expect(vm.isComplete, isFalse);
      expect(vm.isAuthorized, isFalse);
    });

    test('denies access on load if not opted in or unverified', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.unverified(userId: 'user-test-123'),
      );

      await vm.loadQuestionnaire();
      expect(vm.status, PersonalityQuestionnaireStatus.accessDenied);
      expect(vm.isAccessDenied, isTrue);
      expect(mockRepo.callCount, 0);
    });

    test('loads questionnaire successfully when authoritatively authorized', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
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

    test('handles option selection, answer updating, and local completion', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      await vm.loadQuestionnaire();

      // Invalid option selection ignored
      vm.selectOption('invalid_option');
      expect(vm.selectedOptionForCurrentQuestion(), isNull);

      // Valid option selection recorded
      vm.selectOption('1');
      expect(vm.selectedOptionForCurrentQuestion(), '1');
      expect(vm.progress, 0.5);
      // q01 is required and answered, so questionnaire is complete
      expect(vm.isComplete, isTrue);
    });

    test('handles navigation and cancel draft correctly', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      await vm.loadQuestionnaire();
      vm.selectOption('1');
      expect(vm.nextQuestion(), isTrue);
      expect(vm.currentQuestionIndex, 1);

      vm.cancelDraft();
      expect(vm.currentQuestionIndex, 0);
      expect(vm.selectedOptionForCurrentQuestion(), isNull);
    });

    test('clears answers and denies access on session sign-out', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      await vm.loadQuestionnaire();
      vm.selectOption('1');
      expect(vm.isReady, isTrue);

      fakeSession.setPhase(SessionPhase.signedOut);
      expect(vm.status, PersonalityQuestionnaireStatus.accessDenied);
      expect(vm.questionnaire, isNull);
      expect(vm.answerDraft, isNull);
    });

    test('clears answers and denies access on account switch', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      await vm.loadQuestionnaire();
      vm.selectOption('1');

      fakeSession.subject = 'switched-user-999';
      expect(vm.status, PersonalityQuestionnaireStatus.accessDenied);
      expect(vm.questionnaire, isNull);
      expect(vm.answerDraft, isNull);
    });

    test('maps repository failures gracefully', () async {
      mockRepo.result = const QuestionnaireResult.failure(
        failureType: QuestionnaireFailureType.serviceUnavailable,
        errorMessage: 'Backend personality service unavailable',
      );

      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      await vm.loadQuestionnaire();
      expect(vm.status, PersonalityQuestionnaireStatus.serviceUnavailable);
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.errorMessage, 'Backend personality service unavailable');
    });

    test('safely handles disposal without throws', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      final future = vm.loadQuestionnaire();
      vm.dispose();
      await future;
      expect(vm.isLoading, isTrue); // Was loading when disposed
    });

    test('session change while loadQuestionnaire() is in flight discards late response and sets accessDenied', () async {
      final completer = Completer<QuestionnaireResult<PersonalityQuestionnaire>>();
      mockRepo.result = const QuestionnaireResult.failure(
        failureType: QuestionnaireFailureType.serviceUnavailable,
        errorMessage: 'temp',
      );

      // Create a delayed mock repo
      final delayedRepo = _DelayedMockRepo(completer);
      final vm = PersonalityQuestionnaireViewModel(
        repository: delayedRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      final future = vm.loadQuestionnaire();
      expect(vm.isLoading, isTrue);

      // Switch user while request is in flight
      fakeSession.subject = 'switched-user-456';

      // Server returns questionnaire for the previous user
      completer.complete(QuestionnaireResult.success(PersonalityQuestionnaire(
        version: 'v1.0',
        questions: [
          PersonalityQuestion(
            id: 'q01',
            prompt: 'Question 1',
            isRequired: true,
            options: [
              PersonalityOption(id: '1', label: 'Option 1'),
            ],
          ),
        ],
      )));

      await future;

      expect(vm.status, PersonalityQuestionnaireStatus.accessDenied);
      expect(vm.questionnaire, isNull);
      expect(vm.answerDraft, isNull);
    });

    test('repository failure clears existing questionnaire and draft answers', () async {
      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      await vm.loadQuestionnaire();
      expect(vm.status, PersonalityQuestionnaireStatus.ready);
      expect(vm.questionnaire, isNotNull);

      // Subsequent refresh fails
      mockRepo.result = const QuestionnaireResult.failure(
        failureType: QuestionnaireFailureType.unauthorized,
        errorMessage: 'Session revoked',
      );

      await vm.loadQuestionnaire(refresh: true);

      expect(vm.status, PersonalityQuestionnaireStatus.accessDenied);
      expect(vm.questionnaire, isNull);
      expect(vm.answerDraft, isNull);
    });

    test('malformed payload failure maps to error state', () async {
      mockRepo.result = const QuestionnaireResult.failure(
        failureType: QuestionnaireFailureType.unknown,
        errorMessage: 'Malformed questionnaire definition format.',
      );

      final vm = PersonalityQuestionnaireViewModel(
        repository: mockRepo,
        sessionController: fakeSession,
        accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
      );

      await vm.loadQuestionnaire();
      expect(vm.status, PersonalityQuestionnaireStatus.error);
      expect(vm.isError, isTrue);
      expect(vm.errorMessage, 'Malformed questionnaire definition format.');
    });

    group('submitAnswers & loadSavedAnswers (Task 154)', () {
      test('submitting complete answers succeeds and clears submitting flag', () async {
        final mockRepo = MockQuestionnaireRepository();
        final fakeSession = FakeSessionController();
        final vm = PersonalityQuestionnaireViewModel(
          repository: mockRepo,
          sessionController: fakeSession,
          accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
        );

        await vm.loadQuestionnaire();
        vm.selectOption('1'); // q01 answered (required)

        expect(vm.isComplete, isTrue);
        final success = await vm.submitAnswers();
        expect(success, isTrue);
        expect(mockRepo.submitCount, 1);
        expect(vm.isSubmitting, isFalse);
      });

      test('submitting incomplete answers fails before dispatch unless skipped', () async {
        final mockRepo = MockQuestionnaireRepository();
        final fakeSession = FakeSessionController();
        final vm = PersonalityQuestionnaireViewModel(
          repository: mockRepo,
          sessionController: fakeSession,
          accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
        );

        await vm.loadQuestionnaire();
        // q01 is required, not answered yet
        expect(vm.isComplete, isFalse);

        final failed = await vm.submitAnswers();
        expect(failed, isFalse);
        expect(mockRepo.submitCount, 0);

        final skipped = await vm.submitAnswers(skip: true);
        expect(skipped, isTrue);
        expect(mockRepo.submitCount, 1);
      });

      test('submitting answers fails when unauthorized', () async {
        final mockRepo = MockQuestionnaireRepository();
        final fakeSession = FakeSessionController(phase: SessionPhase.signedOut);
        final vm = PersonalityQuestionnaireViewModel(
          repository: mockRepo,
          sessionController: fakeSession,
        );

        final success = await vm.submitAnswers(skip: true);
        expect(success, isFalse);
        expect(vm.isAccessDenied, isTrue);
      });

      test('serviceUnavailable failure during submission sets serviceUnavailable status', () async {
        final mockRepo = MockQuestionnaireRepository();
        mockRepo.submitResult = const QuestionnaireResult.failure(
          errorMessage: 'Personality questionnaire service is currently unavailable.',
          failureType: QuestionnaireFailureType.serviceUnavailable,
        );
        final fakeSession = FakeSessionController();
        final vm = PersonalityQuestionnaireViewModel(
          repository: mockRepo,
          sessionController: fakeSession,
          accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
        );

        await vm.loadQuestionnaire();
        vm.selectOption('1');

        final success = await vm.submitAnswers();
        expect(success, isFalse);
        expect(vm.isServiceUnavailable, isTrue);
        expect(vm.errorMessage, contains('unavailable'));
      });

      test('loadSavedAnswers restores existing draft from backend', () async {
        final mockRepo = MockQuestionnaireRepository();
        mockRepo.savedResult = QuestionnaireResult.success(PersonalityAnswerDraft(
          questionnaireVersion: 'v1.0',
          answers: {'q01': '1', 'q02': '1'},
        ));
        final fakeSession = FakeSessionController();
        final vm = PersonalityQuestionnaireViewModel(
          repository: mockRepo,
          sessionController: fakeSession,
          accessEvidence: SocialAccessEvidence.authorized(userId: 'user-test-123'),
        );

        await vm.loadQuestionnaire();
        final loaded = await vm.loadSavedAnswers();
        expect(loaded, isTrue);
        expect(vm.selectedOptionForQuestion('q01'), '1');
        expect(vm.selectedOptionForQuestion('q02'), '1');
      });
    });
  });
}

class _DelayedMockRepo implements IPersonalityQuestionnaireRepository {
  final Completer<QuestionnaireResult<PersonalityQuestionnaire>> completer;
  _DelayedMockRepo(this.completer);

  @override
  Future<QuestionnaireResult<PersonalityQuestionnaire>> getActiveQuestionnaire() => completer.future;

  @override
  Future<QuestionnaireResult<bool>> submitAnswers(PersonalityAnswerDraft draft, {bool skip = false}) async =>
      const QuestionnaireResult.success(true);

  @override
  Future<QuestionnaireResult<PersonalityAnswerDraft>> getSavedAnswers() async =>
      const QuestionnaireResult.failure(
        errorMessage: 'Not implemented',
        failureType: QuestionnaireFailureType.unknown,
      );
}
