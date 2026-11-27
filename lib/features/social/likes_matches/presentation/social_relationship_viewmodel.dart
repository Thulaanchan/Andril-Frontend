import 'package:flutter/foundation.dart';
import '../../../../core/security/session/session_controller.dart';
import '../../discovery/data/social_discovery_repository.dart';
import '../../discovery/domain/social_candidate.dart';
import '../data/social_relationship_repository.dart';
import '../domain/authorization/social_access_boundary.dart';
import '../domain/social_relationship.dart';

/// Presentation operational states for Social relationship flows (SOC-03 / CF-20).
enum SocialRelationshipViewStatus {
  /// Uninitialized or awaiting session authorization.
  initial,

  /// Asynchronously loading items or processing relationship decision.
  loading,

  /// Items are loaded and ready for user interaction.
  ready,

  /// Loaded list contains zero items (empty state).
  empty,

  /// Network, operational, or validation failure.
  error,

  /// Access denied due to unauthenticated session or lack of Social opt-in.
  accessDenied,

  /// Target relationship service is dormant or unavailable.
  unavailableService,
}

/// Presentation ViewModel orchestrating Received Likes, Sent Likes, Connections, and Mutual Matches.
///
/// Follows M5-FE-S12/S13 relationship presentation governance:
/// - Fails closed: Denies access if session is unauthenticated, missing, or user has not opted into Social.
/// - Defensively protects against concurrent duplicate operations on the same target profile.
/// - Discards stale asynchronous results and clears private relationship data on session termination.
/// - NEVER generates mutual matches locally without authoritative server-confirmed evidence.
class SocialRelationshipViewModel extends ChangeNotifier {
  final ISocialRelationshipRepository repository;
  final SessionController? sessionController;
  final bool isSocialOptedIn;
  final ISocialAccessBoundary accessBoundary;
  final SocialAccessEvidence? accessEvidence;
  String? _boundSubject;

  VoidCallback? _unregisterSessionClearer;

  SocialRelationshipViewStatus _status = SocialRelationshipViewStatus.initial;
  List<SocialRelationship> _receivedLikes = const [];
  List<SocialRelationship> _sentLikes = const [];
  List<SocialRelationship> _connections = const [];
  SocialConnectionCategory _selectedCategory = SocialConnectionCategory.all;

  String? _errorMessage;
  final Set<String> _activeOperations = <String>{};
  int _operationSeq = 0;
  bool _disposed = false;

  /// Optional decoupled callback invoked when mutual matching is authoritatively confirmed.
  ValueChanged<SocialRelationship>? onMatchConfirmed;

  /// Optional navigation callback for profile inspection.
  ValueChanged<String>? onViewCandidateProfile;

  SocialRelationshipViewModel({
    required this.repository,
    this.sessionController,
    this.isSocialOptedIn = false,
    this.accessBoundary = const SocialAccessBoundary(),
    this.accessEvidence,
    List<SocialRelationship>? initialReceivedLikes,
    List<SocialRelationship>? initialSentLikes,
    List<SocialRelationship>? initialConnections,
  })  : _receivedLikes = initialReceivedLikes != null
            ? List.unmodifiable(initialReceivedLikes)
            : const [],
        _sentLikes = initialSentLikes != null
            ? List.unmodifiable(initialSentLikes)
            : const [],
        _connections = initialConnections != null
            ? List.unmodifiable(initialConnections)
            : const [] {
    final session = sessionController;
    if (session != null) {
      try {
        _boundSubject = session.subject;
      } catch (_) {
        _boundSubject = null;
      }
      _unregisterSessionClearer =
          session.registerPrivateStateClearer(_onSessionCleared);
      session.addListener(_onSessionStateChanged);
    }
  }

  SocialRelationshipViewStatus get status => _status;
  List<SocialRelationship> get receivedLikes => _receivedLikes;
  List<SocialRelationship> get sentLikes => _sentLikes;
  List<SocialRelationship> get connections => _connections;
  SocialConnectionCategory get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == SocialRelationshipViewStatus.loading;
  bool get isAccessDenied => _status == SocialRelationshipViewStatus.accessDenied;
  bool get isServiceUnavailable =>
      _status == SocialRelationshipViewStatus.unavailableService;

  bool isOperationInProgress(String targetProfileId) =>
      _activeOperations.contains(targetProfileId);

  /// Evaluates authoritative session and module opt-in status.
  bool get isAuthorized {
    if (_disposed) return false;
    final session = sessionController;
    if (session == null || session.phase != SessionPhase.signedIn) return false;

    try {
      if (_boundSubject != null && session.subject != _boundSubject) {
        return false;
      }
    } catch (_) {}

    if (accessEvidence != null) {
      return accessBoundary.isAccessGranted(
        sessionController: session,
        evidence: accessEvidence,
      );
    }

    return isSocialOptedIn;
  }

  /// Loads received likes (S43) with authoritative session verification.
  Future<void> loadReceivedLikes({bool refresh = false}) async {
    if (_disposed) return;
    if (!isAuthorized) {
      _status = SocialRelationshipViewStatus.accessDenied;
      _errorMessage = 'Social participation requires active opt-in and adult eligibility.';
      notifyListeners();
      return;
    }

    _status = SocialRelationshipViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final currentSeq = ++_operationSeq;
    final result = await repository.getReceivedLikes();

    if (_disposed || currentSeq != _operationSeq) return;

    if (result.isSuccess) {
      final items = result.data ?? const [];
      _receivedLikes = List.unmodifiable(items);
      _status = _receivedLikes.isEmpty
          ? SocialRelationshipViewStatus.empty
          : SocialRelationshipViewStatus.ready;
    } else {
      _mapFailure(result.failureType, result.errorMessage);
    }
    notifyListeners();
  }

  /// Loads sent likes (S11) with authoritative session verification.
  Future<void> loadSentLikes({bool refresh = false}) async {
    if (_disposed) return;
    if (!isAuthorized) {
      _status = SocialRelationshipViewStatus.accessDenied;
      _errorMessage = 'Social participation requires active opt-in and adult eligibility.';
      notifyListeners();
      return;
    }

    _status = SocialRelationshipViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final currentSeq = ++_operationSeq;
    final result = await repository.getSentLikes();

    if (_disposed || currentSeq != _operationSeq) return;

    if (result.isSuccess) {
      final items = result.data ?? const [];
      _sentLikes = List.unmodifiable(items);
      _status = _sentLikes.isEmpty
          ? SocialRelationshipViewStatus.empty
          : SocialRelationshipViewStatus.ready;
    } else {
      _mapFailure(result.failureType, result.errorMessage);
    }
    notifyListeners();
  }

  /// Loads confirmed connections (S13) with category filtering.
  Future<void> loadConnections({
    SocialConnectionCategory category = SocialConnectionCategory.all,
    bool refresh = false,
  }) async {
    if (_disposed) return;
    if (!isAuthorized) {
      _status = SocialRelationshipViewStatus.accessDenied;
      _errorMessage = 'Social participation requires active opt-in and adult eligibility.';
      notifyListeners();
      return;
    }

    _selectedCategory = category;
    _status = SocialRelationshipViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final currentSeq = ++_operationSeq;
    final result = await repository.getConnections(category: category);

    if (_disposed || currentSeq != _operationSeq) return;

    if (result.isSuccess) {
      final items = result.data ?? const [];
      _connections = List.unmodifiable(items);
      _status = _connections.isEmpty
          ? SocialRelationshipViewStatus.empty
          : SocialRelationshipViewStatus.ready;
    } else {
      _mapFailure(result.failureType, result.errorMessage);
    }
    notifyListeners();
  }

  /// Records directional response toward received like or candidate.
  Future<bool> respondToLike({
    required String targetProfileId,
    required bool isPositive,
  }) async {
    if (_disposed || !isAuthorized) return false;
    if (_activeOperations.contains(targetProfileId)) return false;

    _activeOperations.add(targetProfileId);
    notifyListeners();

    final currentSeq = ++_operationSeq;
    try {
      final result = await repository.recordInterest(
        targetProfileId: targetProfileId,
        isPositive: isPositive,
      );

      if (_disposed || currentSeq != _operationSeq) return false;

      if (result.isSuccess && result.data != null) {
        final opData = result.data!;
        // Remove from received likes list upon decision
        _receivedLikes = List.unmodifiable(
          _receivedLikes.where((r) => r.targetProfileId != targetProfileId),
        );

        if (opData.matchCreated && opData.matchId != null) {
          // Authoritative server-confirmed match
          final matchedItem = SocialRelationship(
            id: opData.matchId!,
            targetProfileId: targetProfileId,
            candidate: _findCandidate(targetProfileId),
            state: SocialRelationshipState.matched,
            callerInterest: DirectionalInterest.positive,
            matchEvidence: SocialMatchEvidence(
              matchId: opData.matchId!,
              matchedAtUtc: DateTime.now().toUtc(),
            ),
          );
          _connections = List.unmodifiable([matchedItem, ..._connections]);
          onMatchConfirmed?.call(matchedItem);
        }

        if (_receivedLikes.isEmpty && _status == SocialRelationshipViewStatus.ready) {
          _status = SocialRelationshipViewStatus.empty;
        }
        return true;
      } else {
        _mapFailure(result.failureType, result.errorMessage);
        return false;
      }
    } finally {
      _activeOperations.remove(targetProfileId);
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// Revokes an active mutual match (unmatch) between participants.
  Future<bool> revokeConnection({required String targetProfileId}) async {
    if (_disposed || !isAuthorized) return false;
    if (_activeOperations.contains(targetProfileId)) return false;

    _activeOperations.add(targetProfileId);
    notifyListeners();

    final currentSeq = ++_operationSeq;
    try {
      final result = await repository.revokeMatch(targetProfileId: targetProfileId);

      if (_disposed || currentSeq != _operationSeq) return false;

      if (result.isSuccess) {
        _connections = List.unmodifiable(
          _connections.where((c) => c.targetProfileId != targetProfileId),
        );
        if (_connections.isEmpty) {
          _status = SocialRelationshipViewStatus.empty;
        }
        return true;
      } else {
        _mapFailure(result.failureType, result.errorMessage);
        return false;
      }
    } finally {
      _activeOperations.remove(targetProfileId);
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  void _mapFailure(DiscoveryFailureType? failureType, String? message) {
    switch (failureType) {
      case DiscoveryFailureType.unauthorized:
        _status = SocialRelationshipViewStatus.accessDenied;
        _errorMessage = message ?? 'Authentication or module opt-in required.';
        break;
      case DiscoveryFailureType.serviceUnavailable:
        _status = SocialRelationshipViewStatus.unavailableService;
        _errorMessage = message ?? 'Social relationship service is currently preparing.';
        break;
      default:
        _status = SocialRelationshipViewStatus.error;
        _errorMessage = message ?? 'An unexpected error occurred. Please try again.';
        break;
    }
  }

  SocialCandidate _findCandidate(String targetProfileId) {
    for (final rel in _receivedLikes) {
      if (rel.targetProfileId == targetProfileId) return rel.candidate;
    }
    for (final rel in _sentLikes) {
      if (rel.targetProfileId == targetProfileId) return rel.candidate;
    }
    return SocialCandidate(
      id: targetProfileId,
      displayName: 'Match Member',
      age: 18,
    );
  }

  void _onSessionStateChanged() {
    if (_disposed) return;
    final session = sessionController;
    if (session == null) return;
    String? currentSubject;
    try {
      currentSubject = session.subject;
    } catch (_) {
      currentSubject = null;
    }

    if (session.phase != SessionPhase.signedIn ||
        (_boundSubject != null && currentSubject != _boundSubject)) {
      _onSessionCleared();
      _status = SocialRelationshipViewStatus.accessDenied;
      _errorMessage = 'Session terminated or account switched.';
      notifyListeners();
    }
  }

  void _onSessionCleared() {
    _receivedLikes = const [];
    _sentLikes = const [];
    _connections = const [];
    _activeOperations.clear();
    _operationSeq++;
    _errorMessage = null;
    _status = isAuthorized
        ? SocialRelationshipViewStatus.initial
        : SocialRelationshipViewStatus.accessDenied;
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Manually clears all private relationship data and active operations.
  void clearPrivateState() {
    _onSessionCleared();
  }

  @override
  void dispose() {
    _disposed = true;
    _unregisterSessionClearer?.call();
    sessionController?.removeListener(_onSessionStateChanged);
    super.dispose();
  }
}
