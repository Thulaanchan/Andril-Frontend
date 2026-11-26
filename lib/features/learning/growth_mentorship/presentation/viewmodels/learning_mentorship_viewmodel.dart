import 'package:flutter/foundation.dart';

import '../../../../../core/security/session/session_controller.dart';
import '../../domain/entities/learning_growth_evidence.dart';
import '../../domain/entities/learning_mentorship.dart';
import '../../domain/repositories/i_learning_growth_repository.dart';

enum MentorshipViewStatus {
  initial,
  loading,
  ready,
  empty,
  accessDenied,
  unavailableService,
  error,
}

enum MentorshipTab {
  discover,
  requests,
  active,
}

/// Presentation ViewModel governing voluntary Learning Mentorship (LRN-04, GRW-01-05).
///
/// Follows strict ANDRIL M1 governance:
/// - Voluntary mentor participation only.
/// - Learner-initiated mentorship requests.
/// - Activation occurs ONLY upon mutual agreement (mentor acceptance).
/// - No automatic connection, chat, or XP grant.
/// - Purges private mentorship data immediately upon session revocation.
/// - Rejects stale asynchronous responses via epoch generation checks.
class LearningMentorshipViewModel extends ChangeNotifier {
  final ILearningGrowthRepository repository;
  final SessionController? sessionController;
  final bool isLearningActivated;
  final String currentProfileId;
  final String currentAccountId;
  final String currentDisplayName;

  VoidCallback? _unregisterSessionClearer;

  MentorshipViewStatus _status = MentorshipViewStatus.initial;
  MentorshipTab _activeTab = MentorshipTab.discover;

  List<LearningMentorshipOffer> _offers = const [];
  List<LearningMentorship> _mentorships = const [];
  String? _errorMessage;
  final Set<String> _activeOperations = <String>{};

  int _requestEpoch = 0;
  bool _disposed = false;

  LearningMentorshipViewModel({
    required this.repository,
    this.sessionController,
    this.isLearningActivated = false,
    this.currentProfileId = 'current_learner_prof',
    this.currentAccountId = 'current_learner_acc',
    this.currentDisplayName = 'Current Learner',
    List<LearningMentorshipOffer>? initialOffers,
    List<LearningMentorship>? initialMentorships,
  }) {
    if (initialOffers != null) {
      _offers = List.unmodifiable(initialOffers);
    }
    if (initialMentorships != null) {
      _mentorships = List.unmodifiable(initialMentorships);
    }
    if (initialOffers != null || initialMentorships != null) {
      _status = (_offers.isEmpty && _mentorships.isEmpty)
          ? MentorshipViewStatus.empty
          : MentorshipViewStatus.ready;
    }

    final session = sessionController;
    if (session != null) {
      _unregisterSessionClearer =
          session.registerPrivateStateClearer(_onSessionCleared);
      session.addListener(_onSessionStateChanged);
    }
  }

  MentorshipViewStatus get status => _status;
  MentorshipTab get activeTab => _activeTab;
  String? get errorMessage => _errorMessage;

  List<LearningMentorshipOffer> get offers => _offers;
  List<LearningMentorship> get mentorships => _mentorships;

  List<LearningMentorship> get pendingRequests =>
      _mentorships.where((m) => m.status.isPending).toList();

  List<LearningMentorship> get activeAgreements =>
      _mentorships.where((m) => m.isActive).toList();

  int get pendingRequestsCount => pendingRequests.length;
  int get activeAgreementsCount => activeAgreements.length;
  int get availableOffersCount => _offers.where((o) => o.isAvailable).length;

  bool get isLoading => _status == MentorshipViewStatus.loading;
  bool get isReady => _status == MentorshipViewStatus.ready;
  bool get isEmpty => _status == MentorshipViewStatus.empty;
  bool get isAccessDenied => _status == MentorshipViewStatus.accessDenied;
  bool get isServiceUnavailable =>
      _status == MentorshipViewStatus.unavailableService;

  bool isOperationInProgress(String opId) => _activeOperations.contains(opId);

  void switchTab(MentorshipTab tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  Future<void> initialize({bool force = false}) async {
    if (_status == MentorshipViewStatus.loading && !force) return;

    if (!_isAuthorized()) {
      _status = MentorshipViewStatus.accessDenied;
      _errorMessage =
          'Authentication and an activated Learning profile are required to view mentorship.';
      notifyListeners();
      return;
    }

    _status = MentorshipViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final currentEpoch = ++_requestEpoch;

    try {
      final offersResult = await repository.getMentorshipOffers();
      final mentorshipsResult = await repository.getMentorships();

      if (_disposed || currentEpoch != _requestEpoch) return;

      if (offersResult.failureType ==
              LearningGrowthFailureType.serviceUnavailable ||
          mentorshipsResult.failureType ==
              LearningGrowthFailureType.serviceUnavailable) {
        _status = MentorshipViewStatus.unavailableService;
        _errorMessage = LearningGrowthEvidence.disconnectedNotice;
        notifyListeners();
        return;
      }

      if (offersResult.failureType == LearningGrowthFailureType.accessDenied ||
          mentorshipsResult.failureType ==
              LearningGrowthFailureType.accessDenied) {
        _status = MentorshipViewStatus.accessDenied;
        _errorMessage = offersResult.errorMessage;
        notifyListeners();
        return;
      }

      if (offersResult.isFailure || mentorshipsResult.isFailure) {
        _status = MentorshipViewStatus.error;
        _errorMessage = offersResult.errorMessage ??
            mentorshipsResult.errorMessage ??
            'Failed to load mentorship records.';
        notifyListeners();
        return;
      }

      _offers = List.unmodifiable(offersResult.data ?? const []);
      _mentorships = List.unmodifiable(mentorshipsResult.data ?? const []);

      _status = (_offers.isEmpty && _mentorships.isEmpty)
          ? MentorshipViewStatus.empty
          : MentorshipViewStatus.ready;
      notifyListeners();
    } catch (e) {
      if (_disposed || currentEpoch != _requestEpoch) return;
      _status = MentorshipViewStatus.error;
      _errorMessage =
          'An unexpected error occurred while loading mentorship records.';
      notifyListeners();
    }
  }

  /// Sends a voluntary mentorship request to an available mentor offer.
  Future<bool> sendMentorshipRequest({
    required LearningMentorshipOffer offer,
    required String learningGoal,
    required String message,
  }) async {
    if (!_isAuthorized()) return false;
    final cleanGoal = learningGoal.trim();
    final cleanMsg = message.trim();
    if (cleanGoal.isEmpty || cleanMsg.isEmpty) {
      _errorMessage = 'Learning goal and message are required.';
      notifyListeners();
      return false;
    }

    final opKey = 'request_${offer.id}';
    _activeOperations.add(opKey);
    notifyListeners();

    try {
      final result = await repository.requestMentorship(
        offerId: offer.id,
        learningGoal: cleanGoal,
        message: cleanMsg,
      );

      _activeOperations.remove(opKey);

      final newMentorship = result.data ??
          LearningMentorship.request(
            id: 'mentorship_${DateTime.now().millisecondsSinceEpoch}',
            learner: LearningMentorshipParticipant(
              accountId: currentAccountId,
              learningProfileId: currentProfileId,
              displayName: currentDisplayName,
            ),
            offer: offer,
            learningGoal: cleanGoal,
            message: cleanMsg,
          );

      final list = List<LearningMentorship>.of(_mentorships);
      list.insert(0, newMentorship);
      _mentorships = List.unmodifiable(list);

      if (_status == MentorshipViewStatus.empty) {
        _status = MentorshipViewStatus.ready;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _activeOperations.remove(opKey);
      _errorMessage = 'Error submitting mentorship request.';
      notifyListeners();
      return false;
    }
  }

  /// Accepts a pending mentorship request (mentor action).
  Future<bool> acceptMentorship(String mentorshipId) async {
    if (!_isAuthorized()) return false;
    final opKey = 'accept_$mentorshipId';
    _activeOperations.add(opKey);
    notifyListeners();

    try {
      final result = await repository.acceptMentorship(mentorshipId);
      _activeOperations.remove(opKey);

      final currentParticipant = LearningMentorshipParticipant(
        accountId: currentAccountId,
        learningProfileId: currentProfileId,
        displayName: currentDisplayName,
      );

      final updatedList = _mentorships.map((m) {
        if (m.id == mentorshipId) {
          return result.data ?? m.accept(currentParticipant);
        }
        return m;
      }).toList();

      _mentorships = List.unmodifiable(updatedList);
      notifyListeners();
      return true;
    } catch (e) {
      _activeOperations.remove(opKey);
      _errorMessage = 'Failed to accept mentorship request.';
      notifyListeners();
      return false;
    }
  }

  /// Declines a pending mentorship request (mentor action).
  Future<bool> declineMentorship(String mentorshipId) async {
    if (!_isAuthorized()) return false;
    final opKey = 'decline_$mentorshipId';
    _activeOperations.add(opKey);
    notifyListeners();

    try {
      final result = await repository.declineMentorship(mentorshipId);
      _activeOperations.remove(opKey);

      final currentParticipant = LearningMentorshipParticipant(
        accountId: currentAccountId,
        learningProfileId: currentProfileId,
        displayName: currentDisplayName,
      );

      final updatedList = _mentorships.map((m) {
        if (m.id == mentorshipId) {
          return result.data ?? m.decline(currentParticipant);
        }
        return m;
      }).toList();

      _mentorships = List.unmodifiable(updatedList);
      notifyListeners();
      return true;
    } catch (e) {
      _activeOperations.remove(opKey);
      _errorMessage = 'Failed to decline mentorship request.';
      notifyListeners();
      return false;
    }
  }

  /// Cancels a pending mentorship request (learner action).
  Future<bool> cancelMentorship(String mentorshipId) async {
    if (!_isAuthorized()) return false;
    final opKey = 'cancel_$mentorshipId';
    _activeOperations.add(opKey);
    notifyListeners();

    try {
      final result = await repository.cancelMentorship(mentorshipId);
      _activeOperations.remove(opKey);

      final currentParticipant = LearningMentorshipParticipant(
        accountId: currentAccountId,
        learningProfileId: currentProfileId,
        displayName: currentDisplayName,
      );

      final updatedList = _mentorships.map((m) {
        if (m.id == mentorshipId) {
          return result.data ?? m.cancel(currentParticipant);
        }
        return m;
      }).toList();

      _mentorships = List.unmodifiable(updatedList);
      notifyListeners();
      return true;
    } catch (e) {
      _activeOperations.remove(opKey);
      _errorMessage = 'Failed to cancel mentorship request.';
      notifyListeners();
      return false;
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
    _offers = const [];
    _mentorships = const [];
    _status = MentorshipViewStatus.accessDenied;
    _errorMessage = null;
    _activeOperations.clear();
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
