import 'package:flutter/foundation.dart';

import '../../../../../core/security/session/session_controller.dart';
import '../../domain/entities/learning_topic_gap.dart';
import '../../domain/repositories/i_learning_growth_repository.dart';

enum TopicGapViewStatus {
  initial,
  loading,
  ready,
  insufficientEvidence,
  empty,
  accessDenied,
  unavailableService,
  error,
}

/// ViewModel governing the private Topic Gap Explanation screen (LRN-04, GRW-01-05).
///
/// Follows strict ANDRIL M1 governance:
/// - Only presents topic-gap explanations when authoritative evidence sufficiency is established.
/// - Never interprets missing evidence as missing skill.
/// - Clears private explanation state immediately upon session revocation.
/// - Rejects stale asynchronous responses via epoch generation checks.
class LearningTopicGapViewModel extends ChangeNotifier {
  final ILearningGrowthRepository repository;
  final SessionController? sessionController;
  final bool isLearningActivated;
  final String gapId;
  final String currentProfileId;

  VoidCallback? _unregisterSessionClearer;

  TopicGapViewStatus _status = TopicGapViewStatus.initial;
  LearningTopicGap? _topicGap;
  String? _errorMessage;
  int _requestEpoch = 0;
  bool _disposed = false;

  LearningTopicGapViewModel({
    required this.repository,
    this.sessionController,
    this.isLearningActivated = false,
    this.gapId = 'gap_flutter_state',
    this.currentProfileId = 'current_learner_prof',
    LearningTopicGap? initialGap,
  }) : _topicGap = initialGap {
    if (initialGap != null) {
      _status = initialGap.isSufficientEvidence
          ? TopicGapViewStatus.ready
          : TopicGapViewStatus.insufficientEvidence;
    }

    final session = sessionController;
    if (session != null) {
      _unregisterSessionClearer =
          session.registerPrivateStateClearer(_onSessionCleared);
      session.addListener(_onSessionStateChanged);
    }
  }

  TopicGapViewStatus get status => _status;
  LearningTopicGap? get topicGap => _topicGap;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == TopicGapViewStatus.loading;
  bool get isReady => _status == TopicGapViewStatus.ready;
  bool get isInsufficientEvidence =>
      _status == TopicGapViewStatus.insufficientEvidence;
  bool get isAccessDenied => _status == TopicGapViewStatus.accessDenied;
  bool get isServiceUnavailable =>
      _status == TopicGapViewStatus.unavailableService;

  Future<void> initialize({bool force = false}) async {
    if (_status == TopicGapViewStatus.loading && !force) return;

    if (!_isAuthorized()) {
      _status = TopicGapViewStatus.accessDenied;
      _errorMessage =
          'Authentication and an activated Learning profile are required to view topic gap insights.';
      notifyListeners();
      return;
    }

    _status = TopicGapViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final currentEpoch = ++_requestEpoch;

    try {
      final result = await repository.getTopicGapById(gapId);

      if (_disposed || currentEpoch != _requestEpoch) return;

      if (result.failureType == LearningGrowthFailureType.serviceUnavailable) {
        _status = TopicGapViewStatus.unavailableService;
        _errorMessage =
            result.errorMessage ?? LearningTopicGap.disconnectedNotice;
        notifyListeners();
        return;
      }

      if (result.failureType == LearningGrowthFailureType.accessDenied) {
        _status = TopicGapViewStatus.accessDenied;
        _errorMessage = result.errorMessage;
        notifyListeners();
        return;
      }

      if (result.isFailure) {
        _status = TopicGapViewStatus.error;
        _errorMessage =
            result.errorMessage ?? 'Failed to load topic gap explanation.';
        notifyListeners();
        return;
      }

      final gap = result.data;
      if (gap == null) {
        _status = TopicGapViewStatus.empty;
        _errorMessage = 'No explanation found for this topic.';
      } else if (!gap.isSufficientEvidence) {
        _topicGap = gap;
        _status = TopicGapViewStatus.insufficientEvidence;
      } else {
        _topicGap = gap;
        _status = TopicGapViewStatus.ready;
      }
      notifyListeners();
    } catch (e) {
      if (_disposed || currentEpoch != _requestEpoch) return;
      _status = TopicGapViewStatus.error;
      _errorMessage =
          'An unexpected error occurred while loading topic gap explanation.';
      notifyListeners();
    }
  }

  bool _isAuthorized() {
    final session = sessionController;
    if (session != null && session.phase != SessionPhase.signedIn) {
      return false;
    }
    return isLearningActivated;
  }

  void _onSessionCleared() {
    _topicGap = null;
    _status = TopicGapViewStatus.accessDenied;
    _errorMessage = null;
    _requestEpoch++;
    notifyListeners();
  }

  void _onSessionStateChanged() {
    if (!_isAuthorized()) {
      _onSessionCleared();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _unregisterSessionClearer?.call();
    sessionController?.removeListener(_onSessionStateChanged);
    super.dispose();
  }
}
