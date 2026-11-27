import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../../../likes_matches/domain/authorization/social_access_boundary.dart';
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
/// Follows Task 113 Fast Feature Delivery Governance:
/// - Purely client-side draft progression; never submits answers to dormant backend endpoints.
/// - Requires current authoritative Social access evidence (SocialAccessBoundary).
/// - Default-true Social opt-in authorization is removed (defaults to false / fail-closed).
/// - Keeps Personality Test completely optional (never required for Social entry).
/// - Clears private answer drafts immediately upon session invalidation, logout, or account switch.
/// - Does not fabricate local psychological or personality match outcomes.
/// - Guarantees single-option selection per question and enforces required question answers.
class PersonalityQuestionnaireViewModel extends ChangeNotifier {
  final IPersonalityQuestionnaireRepository _repository;
  final SessionController _sessionController;
  final ISocialAccessBoundary _accessBoundary;
  final SocialAccessEvidence? _accessEvidence;
  final bool _isSocialOptedIn;

  PersonalityQuestionnaireStatus _status = PersonalityQuestionnaireStatus.initial;
  PersonalityQuestionnaire? _questionnaire;
  PersonalityAnswerDraft? _answerDraft;
  int _currentQuestionIndex = 0;
  String? _errorMessage;
  int _activeOperationId = 0;
  bool _disposed = false;
  String? _boundSubject;

  PersonalityQuestionnaireViewModel({
    required IPersonalityQuestionnaireRepository repository,
    required SessionController sessionController,
    ISocialAccessBoundary accessBoundary = const SocialAccessBoundary(),
    SocialAccessEvidence? accessEvidence,
    bool isSocialOptedIn = false, // Defaults to false: fails closed
  })  : _repository = repository,
        _sessionController = sessionController,
        _accessBoundary = accessBoundary,
        _accessEvidence = accessEvidence,
        _isSocialOptedIn = isSocialOptedIn {
    try {
      _boundSubject = _sessionController.subject;
    } catch (_) {
      _boundSubject = null;
    }
    _sessionController.addListener(_onSessionChanged);
    _sessionController.registerPrivateStateClearer(_clearPrivateDraft);
  }

  PersonalityQuestionnaireStatus get status => _status;
  PersonalityQuestionnaire? get questionnaire => _questionnaire;
  PersonalityAnswerDraft? get answerDraft => _answerDraft;
  int get currentQuestionIndex => _currentQuestionIndex;
  String? get errorMessage => _errorMessage;
  bool get isSocialOptedIn => _isSocialOptedIn;

  bool get isLoading => _status == PersonalityQuestionnaireStatus.loading;
  bool get isReady => _status == PersonalityQuestionnaireStatus.ready;
  bool get isAccessDenied => _status == PersonalityQuestionnaireStatus.accessDenied;
  bool get isServiceUnavailable => _status == PersonalityQuestionnaireStatus.serviceUnavailable;
  bool get isError => _status == PersonalityQuestionnaireStatus.error;

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

  /// Evaluates current authoritative access to Personality Questionnaire.
  bool get isAuthorized {
    if (_sessionController.phase != SessionPhase.signedIn) return false;
    if (_accessEvidence != null) {
      return _accessBoundary.isAccessGranted(
        sessionController: _sessionController,
        evidence: _accessEvidence,
      );
    }
    return false;
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

    // Subject validation
    final currentSubject = _resolveSubject();
    if (_boundSubject != null && currentSubject != null && currentSubject != _boundSubject) {
      _questionnaire = null;
      _clearPrivateDraft();
      _boundSubject = currentSubject;
      _status = PersonalityQuestionnaireStatus.accessDenied;
      _errorMessage = 'Session subject changed.';
      notifyListeners();
      return;
    }
    if (_boundSubject == null && currentSubject != null) {
      _boundSubject = currentSubject;
    }

    if (!isAuthorized) {
      _questionnaire = null;
      _clearPrivateDraft();
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

    if (!_disposed && opId == _activeOperationId) {
      notifyListeners();
    }
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
    _clearPrivateDraft(resetToEmptyDraft: true);
    notifyListeners();
  }

  void _clearPrivateDraft({bool resetToEmptyDraft = false}) {
    if (resetToEmptyDraft && _questionnaire != null) {
      _answerDraft = PersonalityAnswerDraft(questionnaireVersion: _questionnaire!.version);
    } else {
      _answerDraft = null;
    }
    _currentQuestionIndex = 0;
  }

  String? _resolveSubject() {
    try {
      return _sessionController.subject;
    } catch (_) {
      return null;
    }
  }

  void _onSessionChanged() {
    if (_disposed) return;
    final currentSubject = _resolveSubject();
    if (_sessionController.phase != SessionPhase.signedIn ||
        (_boundSubject != null && currentSubject != null && currentSubject != _boundSubject)) {
      _questionnaire = null;
      _clearPrivateDraft();
      _boundSubject = currentSubject;
      _status = PersonalityQuestionnaireStatus.accessDenied;
      _errorMessage = 'Session signed out or account switched.';
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

  @override
  String toString() => 'PersonalityQuestionnaireViewModel(status: ${_status.name})';
}
