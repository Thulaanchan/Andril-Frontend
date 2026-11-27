import 'package:flutter/foundation.dart';

import '../../../../core/security/session/session_controller.dart';
import '../../../../shared_core/account/account_handoff_controller.dart';
import '../../../../shared_core/onboarding/domain/onboarding_status_repository.dart';
import '../../../../features/social/likes_matches/domain/authorization/social_access_boundary.dart';
import '../../interests_preferences/domain/social_preferences_model.dart';
import '../data/social_discovery_repository.dart';
import '../domain/social_candidate.dart';

/// Operational presentation states for Social Discovery (Screen S09).
enum SocialDiscoveryStatus {
  /// Uninitialized or awaiting authorization inspection.
  initial,

  /// Asynchronously retrieving candidate queue or recording decision.
  loading,

  /// Candidates are loaded and available for user review.
  ready,

  /// Candidate queue has been exhausted with zero candidates remaining.
  empty,

  /// General operational or network failure.
  error,

  /// Caller is unauthenticated or has not opted in to Social module.
  accessDenied,

  /// Backend discovery or relationship endpoints are dormant / preparing.
  unavailableService,
}

/// Presentation ViewModel for Social Discovery and candidate card evaluation (SOC-02, CF-20).
///
/// Follows Task 109 Fast Feature Delivery Governance:
/// - Fails closed: Denies access if session is unauthenticated, missing, or user lacks authoritative eligibility.
/// - Bound to authoritative [SocialAccessBoundary] and active session lifecycle.
/// - Clears private candidate data upon session invalidation or account switching.
/// - Discards stale asynchronous responses arriving after session invalidation or disposal.
/// - Prevents duplicate concurrent in-flight requests.
class SocialDiscoveryViewModel extends ChangeNotifier {
  final ISocialDiscoveryRepository repository;
  final SessionController? sessionController;
  final AccountHandoffController? handoffController;
  final bool isSocialOptedIn;
  final SocialAccessEvidence? accessEvidence;
  final ISocialAccessBoundary accessBoundary;

  VoidCallback? _unregisterSessionClearer;

  SocialDiscoveryStatus _status = SocialDiscoveryStatus.initial;
  List<SocialCandidate> _candidates = const [];
  int _currentIndex = 0;
  String? _errorMessage;
  bool _isActionInProgress = false;
  SocialPreferencesModel? _activeFilters;
  int _rotationOffset = 0;
  bool _disposed = false;
  int _activeLifecycleGeneration = 0;
  String? _boundSubject;

  /// Optional decoupled callback invoked when mutual interest establishes a match.
  ValueChanged<SocialInterestResult>? onMatchCreated;

  /// Optional navigation callbacks
  ValueChanged<SocialCandidate>? onViewProfileDetails;
  VoidCallback? onOpenFilters;

  SocialDiscoveryViewModel({
    required this.repository,
    this.sessionController,
    this.handoffController,
    this.isSocialOptedIn = false,
    this.accessEvidence,
    ISocialAccessBoundary? accessBoundary,
    List<SocialCandidate>? initialCandidates,
  })  : accessBoundary = accessBoundary ?? const SocialAccessBoundary(),
        _candidates = initialCandidates != null
            ? List.unmodifiable(initialCandidates.where(
                (c) => c.age >= 18 && c.id.trim().isNotEmpty && c.displayName.trim().isNotEmpty,
              ))
            : const [] {
    final session = sessionController;
    if (session != null) {
      _boundSubject = _resolveSubject(session);
      _unregisterSessionClearer =
          session.registerPrivateStateClearer(_onSessionCleared);
      session.addListener(_onSessionStateChanged);
    }
  }

  SocialDiscoveryStatus get status => _status;
  List<SocialCandidate> get candidates => _candidates;
  int get currentIndex => _currentIndex;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == SocialDiscoveryStatus.loading;
  bool get isActionInProgress => _isActionInProgress;
  bool get isAccessDenied => _status == SocialDiscoveryStatus.accessDenied;
  bool get isServiceUnavailable =>
      _status == SocialDiscoveryStatus.unavailableService;
  SocialPreferencesModel? get activeFilters => _activeFilters;

  /// The candidate currently on top of the discovery card stack.
  SocialCandidate? get currentCandidate =>
      (_currentIndex >= 0 && _currentIndex < _candidates.length)
          ? _candidates[_currentIndex]
          : null;

  /// Number of remaining candidates in the active queue.
  int get remainingCount =>
      _candidates.length > _currentIndex ? _candidates.length - _currentIndex : 0;

  /// Whether additional candidates remain in the loaded queue.
  bool get hasMoreCandidates => _currentIndex < _candidates.length;

  static String? _resolveSubject(SessionController? controller) {
    if (controller == null) return null;
    try {
      return controller.subject;
    } catch (_) {
      return null;
    }
  }

  /// Evaluates authoritative session and module opt-in status.
  bool get isAuthorized {
    if (_disposed) return false;
    final session = sessionController;
    if (session == null || session.phase != SessionPhase.signedIn) return false;

    if (accessEvidence != null) {
      return accessBoundary.isAccessGranted(
        sessionController: session,
        evidence: accessEvidence,
      );
    }

    final handoff = handoffController;
    if (handoff != null) {
      final status = handoff.status;
      if (status != null &&
          status.starterModule == StarterModule.social &&
          status.progress.identityVerified &&
          status.progress.currentPoliciesAccepted &&
          status.progress.starterModuleSelected &&
          status.moduleHomeAuthorized &&
          isSocialOptedIn) {
        return true;
      }
    }

    return false;
  }

  /// Initializes discovery feed with authoritative session verification.
  Future<void> initialize() async {
    if (_disposed || _status == SocialDiscoveryStatus.loading) return;

    final requestGeneration = ++_activeLifecycleGeneration;
    final requestSubject = _resolveSubject(sessionController);

    if (!isAuthorized) {
      _status = SocialDiscoveryStatus.accessDenied;
      _errorMessage = 'Access to Social Discovery requires signed-in module authorization.';
      notifyListeners();
      return;
    }

    _status = SocialDiscoveryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getExploreFeed(
        rotationOffset: _rotationOffset,
        limit: 20,
      );

      // Stale response or account switch guards
      if (_disposed ||
          requestGeneration != _activeLifecycleGeneration ||
          _resolveSubject(sessionController) != requestSubject ||
          !isAuthorized) {
        return;
      }

      if (result.isSuccess) {
        final items = result.data ?? const <SocialCandidate>[];
        _candidates = List.unmodifiable(items);
        _currentIndex = 0;
        _status = _candidates.isEmpty
            ? SocialDiscoveryStatus.empty
            : SocialDiscoveryStatus.ready;
        _errorMessage = null;
      } else {
        _errorMessage = result.errorMessage;
        if (result.failureType == DiscoveryFailureType.unauthorized) {
          _status = SocialDiscoveryStatus.accessDenied;
        } else if (result.failureType == DiscoveryFailureType.serviceUnavailable) {
          _status = SocialDiscoveryStatus.unavailableService;
        } else {
          _status = SocialDiscoveryStatus.error;
        }
      }
    } catch (_) {
      if (_disposed ||
          requestGeneration != _activeLifecycleGeneration ||
          _resolveSubject(sessionController) != requestSubject) {
        return;
      }
      _status = SocialDiscoveryStatus.error;
      _errorMessage = 'An error occurred while loading candidates.';
    }

    if (!_disposed && requestGeneration == _activeLifecycleGeneration) {
      notifyListeners();
    }
  }

  /// Refreshes the discovery feed, resetting rotation and clearing existing cards.
  Future<void> refresh() async {
    if (_disposed) return;
    _rotationOffset = 0;
    await initialize();
  }

  /// Records a directional PASS (negative interest) on the current candidate card.
  Future<SocialInterestResult?> pass() async {
    return _recordDecision(isPositive: false);
  }

  /// Records a directional LIKE (positive interest) on the current candidate card.
  Future<SocialInterestResult?> like() async {
    return _recordDecision(isPositive: true);
  }

  Future<SocialInterestResult?> _recordDecision({required bool isPositive}) async {
    if (_disposed || !isAuthorized || _isActionInProgress) return null;
    final candidate = currentCandidate;
    if (candidate == null) return null;

    final requestGeneration = _activeLifecycleGeneration;
    final requestSubject = _resolveSubject(sessionController);

    _isActionInProgress = true;
    notifyListeners();

    // Advance the card index in the local stack
    _currentIndex++;
    if (_currentIndex >= _candidates.length) {
      _status = SocialDiscoveryStatus.empty;
    }

    DiscoveryResult<SocialInterestResult> result;
    try {
      result = await repository.recordInterest(
        targetProfileId: candidate.id,
        isPositive: isPositive,
      );
    } catch (_) {
      _isActionInProgress = false;
      _status = SocialDiscoveryStatus.error;
      _errorMessage = 'An error occurred while recording decision.';
      notifyListeners();
      return null;
    }

    if (_disposed ||
        requestGeneration != _activeLifecycleGeneration ||
        _resolveSubject(sessionController) != requestSubject ||
        !isAuthorized) {
      _isActionInProgress = false;
      return null;
    }

    _isActionInProgress = false;

    if (result.isSuccess && result.data != null) {
      final interestResult = result.data!;
      if (interestResult.matchCreated) {
        onMatchCreated?.call(interestResult);
      }
      notifyListeners();
      return interestResult;
    } else {
      if (result.failureType == DiscoveryFailureType.serviceUnavailable) {
        _status = SocialDiscoveryStatus.unavailableService;
      } else if (result.failureType == DiscoveryFailureType.unauthorized) {
        _status = SocialDiscoveryStatus.accessDenied;
      }
      _errorMessage = result.errorMessage;
      notifyListeners();
      return null;
    }
  }

  /// Applies user-configured discovery preferences and triggers feed refresh.
  void applyFilters(SocialPreferencesModel filters) {
    if (_disposed || !isAuthorized) return;
    _activeFilters = filters;
    refresh();
  }

  /// Clears active discovery filters and refreshes feed with baseline criteria.
  void clearFilters() {
    if (_disposed || !isAuthorized) return;
    _activeFilters = null;
    refresh();
  }

  void triggerViewDetails(SocialCandidate candidate) {
    if (!isAuthorized || _disposed) return;
    onViewProfileDetails?.call(candidate);
  }

  void triggerOpenFilters() {
    if (!isAuthorized || _disposed) return;
    onOpenFilters?.call();
  }

  void _onSessionCleared() {
    _candidates = const [];
    _currentIndex = 0;
    _status = SocialDiscoveryStatus.accessDenied;
    _errorMessage = null;
    _activeFilters = null;
    _isActionInProgress = false;
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _onSessionStateChanged() {
    if (_disposed) return;
    final currentSubject = _resolveSubject(sessionController);
    if (_boundSubject != null && currentSubject != _boundSubject) {
      _boundSubject = currentSubject;
      _activeLifecycleGeneration++;
      _onSessionCleared();
      return;
    }
    if (!isAuthorized) {
      _onSessionCleared();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _activeLifecycleGeneration++;
    _unregisterSessionClearer?.call();
    _unregisterSessionClearer = null;
    sessionController?.removeListener(_onSessionStateChanged);
    _candidates = const [];
    super.dispose();
  }

  @override
  String toString() => 'SocialDiscoveryViewModel(status: ${_status.name}, remaining: $remainingCount)';
}
