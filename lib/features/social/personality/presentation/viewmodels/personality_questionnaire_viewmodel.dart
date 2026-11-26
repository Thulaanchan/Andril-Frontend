import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../../data/repositories/personality_questionnaire_repository.dart';
import '../../domain/entities/personality_questionnaire.dart';

/// Presentation state machine status for the Personality Questionnaire.
enum PersonalityQuestionnaireStatus {
  initial,
  loading,
  ready,
  accessDenied,
  serviceUnavailable,
  error,
}

/// Presentation ViewModel orchestrating the interactive Personality Questionnaire flow.
///
/// Follows M5 Personality & Privacy Governance:
/// - Purely client-side draft progression; never submits answers to dormant backend endpoints.
/// - Clears private answer drafts immediately upon session invalidation or cancellation.
/// - Does not fabricate local psychological or personality match outcomes.
/// - Guarantees single-option selection per question and enforces required question answers.
class PersonalityQuestionnaireViewModel extends ChangeNotifier {
  final IPersonalityQuestionnaireRepository _repository;
  final SessionController _sessionController;
  final bool _isSocialOptedIn;

  PersonalityQuestionnaireStatus _status = PersonalityQuestionnaireStatus.initial;
  PersonalityQuestionnaire? _questionnaire;
  PersonalityAnswerDraft? _answerDraft;
  int _currentQuestionIndex = 0;
  String? _errorMessage;
  int _activeOperationId = 0;
  bool _disposed = false;

  PersonalityQuestionnaireViewModel({
    required IPersonalityQuestionnaireRepository repository,
    required SessionController sessionController,
    bool isSocialOptedIn = true,
  })  : _repository = repository,
        _sessionController = sessionController,
        _isSocialOptedIn = isSocialOptedIn {
    _sessionController.addListener(_onSessionChanged);
    _sessionController.registerPrivateStateClearer(_clearPrivateDraft);
  }

  PersonalityQuestionnaireStatus get status => _status;
  PersonalityQuestionnaire? get questionnaire => _questionnaire;
  PersonalityAnswerDraft? get answerDraft => _answerDraft;
  int get currentQuestionIndex => _currentQuestionIndex;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == PersonalityQuestionnaireStatus.loading;
  bool get isReady => _status == PersonalityQuestionnaireStatus.ready;
  bool get isAccessDenied => _status == PersonalityQuestionnaireStatus.accessDenied;
  bool get isServiceUnavailable => _status == PersonalityQuestionnaireStatus.serviceUnavailable;

  int get totalQuestions => _questionnaire?.totalQuestions ?? 0;

  PersonalityQuestion? get currentQuestion {
    if (_questionnaire == null || _questionnaire!.questions.isEmpty) return null;
    if (_currentQuestionIndex < 0 || _currentQuestionIndex >= _questionnaire!.questions.length) {
      return null;
    }
    return _questionnaire!.questions[_currentQuestionIndex];
  }

  bool get hasPreviousQuestion => _currentQuestionIndex > 0;
  bool get hasNextQuestion =>
      _questionnaire != null && _currentQuestionIndex < _questionnaire!.questions.length - 1;

  bool get isLastQuestion =>
      _questionnaire != null && _currentQuestionIndex == _questionnaire!.questions.length - 1;

  double get progress {
    if (_questionnaire == null || _answerDraft == null) return 0.0;
    return _answerDraft!.completionProgress(_questionnaire!);
  }

  bool get isComplete {
    if (_questionnaire == null || _answerDraft == null) return false;
    return _answerDraft!.isCompleteFor(_questionnaire!);
  }

  String? selectedOptionForCurrentQuestion() {
    final q = currentQuestion;
    if (q == null || _answerDraft == null) return null;
    return _answerDraft!.answers[q.id];
  }

  String? selectedOptionForQuestion(String questionId) {
    if (_answerDraft == null) return null;
    return _answerDraft!.answers[questionId];
  }

  /// Loads the authoritative questionnaire definition from repository.
  Future<void> loadQuestionnaire({bool refresh = false}) async {
    if (_disposed) return;

    if (!_isSocialOptedIn || _sessionController.phase != SessionPhase.signedIn) {
      _status = PersonalityQuestionnaireStatus.accessDenied;
      _errorMessage = 'Adult eligibility verification and Social opt-in are required.';
      notifyListeners();
      return;
    }

    if (_status == PersonalityQuestionnaireStatus.ready && !refresh) {
      return;
    }

    final opId = ++_activeOperationId;
    _status = PersonalityQuestionnaireStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getActiveQuestionnaire();
      if (_disposed || opId != _activeOperationId) return;

      if (result.isSuccess && result.data != null) {
        _questionnaire = result.data;
        _answerDraft = PersonalityAnswerDraft(
          questionnaireVersion: _questionnaire!.version,
        );
        _currentQuestionIndex = 0;
        _status = PersonalityQuestionnaireStatus.ready;
        _errorMessage = null;
      } else {
        _handleFailure(result.failureType, result.errorMessage);
      }
    } catch (_) {
      if (_disposed || opId != _activeOperationId) return;
      _status = PersonalityQuestionnaireStatus.error;
      _errorMessage = 'Failed to load questionnaire.';
    }

    notifyListeners();
  }

  /// Records the caller's chosen option for the current question.
  void selectOption(String optionId) {
    final q = currentQuestion;
    if (q == null || _answerDraft == null) return;

    // Validate that optionId is defined on the current question
    final valid = q.options.any((opt) => opt.id == optionId);
    if (!valid) return;

    _answerDraft = _answerDraft!.setAnswer(questionId: q.id, optionId: optionId);
    notifyListeners();
  }

  /// Navigates to the next question if available.
  bool nextQuestion() {
    if (!hasNextQuestion) return false;
    _currentQuestionIndex++;
    notifyListeners();
    return true;
  }

  /// Navigates to the previous question if available.
  bool previousQuestion() {
    if (!hasPreviousQuestion) return false;
    _currentQuestionIndex--;
    notifyListeners();
    return true;
  }

  /// Jumps to a specific question by index.
  void goToQuestion(int index) {
    if (_questionnaire == null) return;
    if (index >= 0 && index < _questionnaire!.questions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  /// Clears in-memory draft answers and resets to the first question.
  void cancelDraft() {
    _clearPrivateDraft();
    notifyListeners();
  }

  void _clearPrivateDraft() {
    if (_questionnaire != null) {
      _answerDraft = PersonalityAnswerDraft(questionnaireVersion: _questionnaire!.version);
    } else {
      _answerDraft = null;
    }
    _currentQuestionIndex = 0;
  }

  void _onSessionChanged() {
    if (_disposed) return;
    if (_sessionController.phase != SessionPhase.signedIn) {
      _clearPrivateDraft();
      _questionnaire = null;
      _status = PersonalityQuestionnaireStatus.accessDenied;
      _errorMessage = 'Session signed out.';
      notifyListeners();
    }
  }

  void _handleFailure(QuestionnaireFailureType? type, String? message) {
    switch (type) {
      case QuestionnaireFailureType.unauthorized:
        _status = PersonalityQuestionnaireStatus.accessDenied;
        _errorMessage = message ?? 'Access denied.';
        break;
      case QuestionnaireFailureType.serviceUnavailable:
        _status = PersonalityQuestionnaireStatus.serviceUnavailable;
        _errorMessage = message ?? 'Service currently unavailable.';
        break;
      case QuestionnaireFailureType.networkError:
      case QuestionnaireFailureType.badRequest:
      case QuestionnaireFailureType.unknown:
      case null:
        _status = PersonalityQuestionnaireStatus.error;
        _errorMessage = message ?? 'Failed to load questionnaire.';
        break;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionController.removeListener(_onSessionChanged);
    super.dispose();
  }
}
