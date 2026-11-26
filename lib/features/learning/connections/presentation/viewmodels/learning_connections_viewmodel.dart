import 'package:flutter/foundation.dart';

import '../../../../../core/security/session/session_controller.dart';
import '../../../discovery/domain/entities/learning_partner_candidate.dart';
import '../../domain/entities/learning_connection.dart';
import '../../domain/entities/learning_connection_request.dart';
import '../../domain/repositories/i_learning_connections_repository.dart';

/// Presentation operational statuses for Learning Connections (CF-05).
enum LearningConnectionsViewStatus {
  /// Uninitialized or awaiting authorization inspection.
  initial,

  /// Asynchronously loading items or processing an action.
  loading,

  /// Items are loaded and ready for user interaction.
  ready,

  /// Current tab / category contains zero items.
  empty,

  /// Network, operational, or validation failure.
  error,

  /// Access denied due to unauthenticated session or lack of Learning profile activation.
  accessDenied,

  /// Target connections service is dormant or unavailable (pending OpenAPI contract).
  unavailableService,
}

/// Navigation tabs in the Learning Connections presentation layer.
enum LearningConnectionsTab {
  /// Active mutual learning connections.
  myConnections,

  /// Incoming requests from other learners awaiting decision.
  incomingRequests,

  /// Outgoing requests sent by current user awaiting answer.
  sentRequests,
}

/// Presentation ViewModel for Learning Connections and Request Management (CF-05).
///
/// Follows ANDRIL M1 Learning Module governance:
/// - Enforces authenticated and activated Learning profile scope (fail-closed).
/// - Distinguishes account IDs from opaque module-profile IDs. Never exposes account IDs.
/// - Purges private connection state immediately on session termination or identity changes.
/// - Rejects stale asynchronous responses via epoch generation checks.
/// - In-flight operation locking prevents concurrent duplicate submissions.
/// - Never automatically establishes connections or activates chat permissions without backend authority.
class LearningConnectionsViewModel extends ChangeNotifier {
  final ILearningConnectionsRepository repository;
  final SessionController? sessionController;
  final bool isLearningActivated;

  VoidCallback? _unregisterSessionClearer;

  LearningConnectionsViewStatus _status = LearningConnectionsViewStatus.initial;
  LearningConnectionsTab _activeTab = LearningConnectionsTab.myConnections;

  List<LearningConnection> _connections = const [];
  List<LearningConnectionRequest> _incomingRequests = const [];
  List<LearningConnectionRequest> _outgoingRequests = const [];

  String _searchQuery = '';
  String? _errorMessage;
  final Set<String> _activeOperations = <String>{};

  int _requestEpoch = 0;
  bool _disposed = false;

  /// Notice displayed when running under disconnected / pending backend contract.
  static const String disconnectedNotice =
      'Remote connections backend contract pending in OpenAPI v1. Operating in local presentation mode.';

  LearningConnectionsViewModel({
    required this.repository,
    this.sessionController,
    this.isLearningActivated = false,
    List<LearningConnection>? initialConnections,
    List<LearningConnectionRequest>? initialIncomingRequests,
    List<LearningConnectionRequest>? initialOutgoingRequests,
  }) {
    if (initialConnections != null) {
      _connections = _sanitizeConnections(initialConnections);
    }
    if (initialIncomingRequests != null) {
      _incomingRequests = _sanitizeRequests(initialIncomingRequests);
    }
    if (initialOutgoingRequests != null) {
      _outgoingRequests = _sanitizeRequests(initialOutgoingRequests);
    }

    final session = sessionController;
    if (session != null) {
      _unregisterSessionClearer =
          session.registerPrivateStateClearer(_onSessionCleared);
      session.addListener(_onSessionStateChanged);
    }
  }

  LearningConnectionsViewStatus get status => _status;
  LearningConnectionsTab get activeTab => _activeTab;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  List<LearningConnection> get connections => _connections;
  List<LearningConnectionRequest> get incomingRequests => _incomingRequests;
  List<LearningConnectionRequest> get outgoingRequests => _outgoingRequests;

  int get connectionsCount => _connections.length;
  int get incomingCount => _incomingRequests.length;
  int get outgoingCount => _outgoingRequests.length;

  bool get isLoading => _status == LearningConnectionsViewStatus.loading;
  bool get isAccessDenied =>
      _status == LearningConnectionsViewStatus.accessDenied;
  bool get isServiceUnavailable =>
      _status == LearningConnectionsViewStatus.unavailableService;
  bool get isReady => _status == LearningConnectionsViewStatus.ready;
  bool get isEmpty => _status == LearningConnectionsViewStatus.empty;

  bool isOperationInProgress(String id) => _activeOperations.contains(id);

  /// Filtered connections based on active search query.
  List<LearningConnection> get filteredConnections {
    if (_searchQuery.isEmpty) return _connections;
    final q = _searchQuery.toLowerCase();
    return _connections.where((c) {
      if (c.peerDisplayName.toLowerCase().contains(q)) return true;
      if (c.sharedSkills.any((s) => s.toLowerCase().contains(q))) return true;
      if (c.learningGoals.any((g) => g.toLowerCase().contains(q))) return true;
      return false;
    }).toList();
  }

  /// Filtered incoming requests based on active search query.
  List<LearningConnectionRequest> get filteredIncomingRequests {
    if (_searchQuery.isEmpty) return _incomingRequests;
    final q = _searchQuery.toLowerCase();
    return _incomingRequests.where((r) {
      if (r.senderDisplayName.toLowerCase().contains(q)) return true;
      if (r.senderSkills.any((s) => s.toLowerCase().contains(q))) return true;
      if (r.note != null && r.note!.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  /// Filtered outgoing requests based on active search query.
  List<LearningConnectionRequest> get filteredOutgoingRequests {
    if (_searchQuery.isEmpty) return _outgoingRequests;
    final q = _searchQuery.toLowerCase();
    return _outgoingRequests.where((r) {
      if (r.receiverDisplayName.toLowerCase().contains(q)) return true;
      if (r.note != null && r.note!.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  void switchTab(LearningConnectionsTab tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    final trimmed = query.trim();
    if (_searchQuery != trimmed) {
      _searchQuery = trimmed;
      notifyListeners();
    }
  }

  /// Initializes the ViewModel and loads connections and requests.
  Future<void> initialize({bool force = false}) async {
    if (_status == LearningConnectionsViewStatus.loading && !force) return;

    // Fail-closed authorization inspection
    if (!_isAuthorized()) {
      _status = LearningConnectionsViewStatus.accessDenied;
      _errorMessage =
          'Authentication and an activated Learning profile are required.';
      notifyListeners();
      return;
    }

    _status = LearningConnectionsViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final currentEpoch = ++_requestEpoch;

    try {
      final results = await Future.wait([
        repository.getConnections(),
        repository.getIncomingRequests(),
        repository.getOutgoingRequests(),
      ]);

      if (_disposed || currentEpoch != _requestEpoch) return;

      final connResult =
          results[0] as LearningConnectionsResult<List<LearningConnection>>;
      final incResult = results[1]
          as LearningConnectionsResult<List<LearningConnectionRequest>>;
      final outResult = results[2]
          as LearningConnectionsResult<List<LearningConnectionRequest>>;

      // Check if service is dormant / unavailable
      if (connResult.failureType ==
              LearningConnectionsFailureType.serviceUnavailable ||
          incResult.failureType ==
              LearningConnectionsFailureType.serviceUnavailable ||
          outResult.failureType ==
              LearningConnectionsFailureType.serviceUnavailable) {
        _status = LearningConnectionsViewStatus.unavailableService;
        _errorMessage = connResult.errorMessage ??
            incResult.errorMessage ??
            outResult.errorMessage ??
            disconnectedNotice;
        notifyListeners();
        return;
      }

      if (connResult.isFailure &&
          connResult.failureType ==
              LearningConnectionsFailureType.accessDenied) {
        _status = LearningConnectionsViewStatus.accessDenied;
        _errorMessage = connResult.errorMessage;
        notifyListeners();
        return;
      }

      if (connResult.isFailure || incResult.isFailure || outResult.isFailure) {
        _status = LearningConnectionsViewStatus.error;
        _errorMessage = connResult.errorMessage ??
            incResult.errorMessage ??
            outResult.errorMessage ??
            'Failed to load connections.';
        notifyListeners();
        return;
      }

      _connections = _sanitizeConnections(connResult.data ?? const []);
      _incomingRequests = _sanitizeRequests(incResult.data ?? const []);
      _outgoingRequests = _sanitizeRequests(outResult.data ?? const []);

      _status = (_connections.isEmpty &&
              _incomingRequests.isEmpty &&
              _outgoingRequests.isEmpty)
          ? LearningConnectionsViewStatus.empty
          : LearningConnectionsViewStatus.ready;
      notifyListeners();
    } catch (e) {
      if (_disposed || currentEpoch != _requestEpoch) return;
      _status = LearningConnectionsViewStatus.error;
      _errorMessage = 'An unexpected error occurred while loading connections.';
      notifyListeners();
    }
  }

  /// Sends a new connection request to an eligible learning candidate.
  Future<bool> sendRequest(
    LearningPartnerCandidate candidate, {
    String? note,
  }) async {
    if (!_isAuthorized()) {
      _status = LearningConnectionsViewStatus.accessDenied;
      notifyListeners();
      return false;
    }

    if (candidate.module != LearningPartnerCandidate.moduleScope) {
      _errorMessage = 'Cannot connect across different modules.';
      notifyListeners();
      return false;
    }

    final targetId = candidate.id;
    if (_activeOperations.contains(targetId)) return false;
    _activeOperations.add(targetId);
    notifyListeners();

    try {
      final result = await repository.sendRequest(
        recipientProfileId: candidate.id,
        recipientDisplayName: candidate.displayName,
        recipientSkills: candidate.skillsToShare,
        note: note,
      );

      _activeOperations.remove(targetId);

      if (result.isSuccess && result.data != null) {
        _outgoingRequests = [
          ..._outgoingRequests.where((r) => r.id != result.data!.id),
          result.data!,
        ];
        if (_status == LearningConnectionsViewStatus.empty) {
          _status = LearningConnectionsViewStatus.ready;
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            result.errorMessage ?? 'Failed to send connection request.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _activeOperations.remove(targetId);
      _errorMessage = 'Error sending connection request.';
      notifyListeners();
      return false;
    }
  }

  /// Accepts a pending incoming connection request.
  Future<bool> acceptRequest(String requestId) async {
    if (!_isAuthorized()) return false;
    final trimmedId = requestId.trim();
    if (trimmedId.isEmpty || _activeOperations.contains(trimmedId))
      return false;

    _activeOperations.add(trimmedId);
    notifyListeners();

    try {
      final result = await repository.acceptRequest(trimmedId);
      _activeOperations.remove(trimmedId);

      if (result.isSuccess) {
        // Find the accepted request
        final accepted = _incomingRequests.firstWhere(
          (r) => r.id == trimmedId,
          orElse: () => LearningConnectionRequest(
            id: trimmedId,
            senderProfileId: result.data?.senderProfileId ?? 'unknown',
            senderDisplayName: result.data?.senderDisplayName ?? 'Learner',
            receiverProfileId: 'current_user',
            receiverDisplayName: 'Me',
          ),
        );

        // Remove from incoming requests
        _incomingRequests =
            _incomingRequests.where((r) => r.id != trimmedId).toList();

        // Create new active connection
        final newConn = LearningConnection(
          id: 'conn_${accepted.id}',
          peerProfileId: accepted.senderProfileId,
          peerDisplayName: accepted.senderDisplayName,
          peerAvatarUrl: accepted.senderAvatarUrl,
          sharedSkills: accepted.senderSkills,
          connectedAt: DateTime.now(),
        );

        _connections = [
          ..._connections
              .where((c) => c.peerProfileId != newConn.peerProfileId),
          newConn,
        ];

        if (_status == LearningConnectionsViewStatus.empty) {
          _status = LearningConnectionsViewStatus.ready;
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage ?? 'Failed to accept request.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _activeOperations.remove(trimmedId);
      _errorMessage = 'Error accepting connection request.';
      notifyListeners();
      return false;
    }
  }

  /// Declines a pending incoming connection request.
  Future<bool> declineRequest(String requestId) async {
    if (!_isAuthorized()) return false;
    final trimmedId = requestId.trim();
    if (trimmedId.isEmpty || _activeOperations.contains(trimmedId))
      return false;

    _activeOperations.add(trimmedId);
    notifyListeners();

    try {
      final result = await repository.declineRequest(trimmedId);
      _activeOperations.remove(trimmedId);

      if (result.isSuccess) {
        _incomingRequests =
            _incomingRequests.where((r) => r.id != trimmedId).toList();
        if (_connections.isEmpty &&
            _incomingRequests.isEmpty &&
            _outgoingRequests.isEmpty) {
          _status = LearningConnectionsViewStatus.empty;
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage ?? 'Failed to decline request.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _activeOperations.remove(trimmedId);
      _errorMessage = 'Error declining connection request.';
      notifyListeners();
      return false;
    }
  }

  /// Cancels a pending outgoing connection request.
  Future<bool> cancelRequest(String requestId) async {
    if (!_isAuthorized()) return false;
    final trimmedId = requestId.trim();
    if (trimmedId.isEmpty || _activeOperations.contains(trimmedId))
      return false;

    _activeOperations.add(trimmedId);
    notifyListeners();

    try {
      final result = await repository.cancelRequest(trimmedId);
      _activeOperations.remove(trimmedId);

      if (result.isSuccess) {
        _outgoingRequests =
            _outgoingRequests.where((r) => r.id != trimmedId).toList();
        if (_connections.isEmpty &&
            _incomingRequests.isEmpty &&
            _outgoingRequests.isEmpty) {
          _status = LearningConnectionsViewStatus.empty;
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage ?? 'Failed to cancel request.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _activeOperations.remove(trimmedId);
      _errorMessage = 'Error cancelling connection request.';
      notifyListeners();
      return false;
    }
  }

  /// Removes an active learning connection.
  Future<bool> removeConnection(String connectionId) async {
    if (!_isAuthorized()) return false;
    final trimmedId = connectionId.trim();
    if (trimmedId.isEmpty || _activeOperations.contains(trimmedId))
      return false;

    _activeOperations.add(trimmedId);
    notifyListeners();

    try {
      final result = await repository.removeConnection(trimmedId);
      _activeOperations.remove(trimmedId);

      if (result.isSuccess) {
        _connections = _connections.where((c) => c.id != trimmedId).toList();
        if (_connections.isEmpty &&
            _incomingRequests.isEmpty &&
            _outgoingRequests.isEmpty) {
          _status = LearningConnectionsViewStatus.empty;
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage ?? 'Failed to remove connection.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _activeOperations.remove(trimmedId);
      _errorMessage = 'Error removing connection.';
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

  List<LearningConnection> _sanitizeConnections(List<LearningConnection> list) {
    return list.where((c) {
      if (c.module != LearningConnection.moduleScope) return false;
      if (c.status != LearningConnectionStatus.active) return false;
      return true;
    }).toList();
  }

  List<LearningConnectionRequest> _sanitizeRequests(
      List<LearningConnectionRequest> list) {
    return list.where((r) {
      if (r.module != LearningConnectionRequest.moduleScope) return false;
      if (r.status != LearningRequestStatus.pending) return false;
      return true;
    }).toList();
  }

  void _onSessionCleared() {
    _connections = const [];
    _incomingRequests = const [];
    _outgoingRequests = const [];
    _status = LearningConnectionsViewStatus.accessDenied;
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

  @override
  String toString() {
    return 'LearningConnectionsViewModel(status: ${_status.name}, tab: ${_activeTab.name}, connections: ${_connections.length}, incoming: ${_incomingRequests.length}, outgoing: ${_outgoingRequests.length})';
  }
}
