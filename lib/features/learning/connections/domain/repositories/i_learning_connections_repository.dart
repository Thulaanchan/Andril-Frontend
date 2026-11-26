import '../entities/learning_connection.dart';
import '../entities/learning_connection_request.dart';

/// Categorized failure reasons for Learning Connections operations.
enum LearningConnectionsFailureType {
  /// Session is unauthenticated or invalid.
  unauthorized,

  /// Learning profile has not been activated or lacks permission.
  accessDenied,

  /// Target request or connection was not found.
  notFound,

  /// A pending request or connection already exists with this peer.
  conflict,

  /// Remote backend endpoint is dormant, pending OpenAPI v1 contract, or unreachable.
  serviceUnavailable,

  /// Invalid parameters or request formatting.
  badRequest,

  /// Transient network transport error.
  networkError,

  /// An unclassified or unexpected error occurred.
  unknown,
}

/// Generic outcome wrapper for Learning Connections domain operations.
class LearningConnectionsResult<T> {
  final T? data;
  final String? errorMessage;
  final LearningConnectionsFailureType? failureType;
  final bool isSuccess;

  const LearningConnectionsResult.success(this.data)
      : errorMessage = null,
        failureType = null,
        isSuccess = true;

  const LearningConnectionsResult.failure({
    required this.errorMessage,
    required this.failureType,
  })  : data = null,
        isSuccess = false;

  bool get isFailure => !isSuccess;
}

/// Abstract contract defining Learning Connections repository capabilities (CF-05).
///
/// Follows fail-closed governance:
/// - Distinguishes between active connections, incoming requests, and outgoing requests.
/// - Requires server-authoritative state transitions for accept, decline, cancel, and remove.
/// - Returns explicit [LearningConnectionsResult] outcomes; never fabricates dummy success.
abstract class ILearningConnectionsRepository {
  /// Retrieves established learning connections for the authenticated profile.
  Future<LearningConnectionsResult<List<LearningConnection>>> getConnections();

  /// Retrieves pending incoming connection requests.
  Future<LearningConnectionsResult<List<LearningConnectionRequest>>>
      getIncomingRequests();

  /// Retrieves pending outgoing connection requests initiated by current user.
  Future<LearningConnectionsResult<List<LearningConnectionRequest>>>
      getOutgoingRequests();

  /// Initiates a new connection request to an eligible learning partner candidate.
  Future<LearningConnectionsResult<LearningConnectionRequest>> sendRequest({
    required String recipientProfileId,
    required String recipientDisplayName,
    Iterable<String>? recipientSkills,
    String? note,
  });

  /// Authoritatively accepts a pending incoming connection request.
  Future<LearningConnectionsResult<LearningConnectionRequest>> acceptRequest(
    String requestId,
  );

  /// Authoritatively declines a pending incoming connection request.
  Future<LearningConnectionsResult<LearningConnectionRequest>> declineRequest(
    String requestId,
  );

  /// Authoritatively cancels a pending outgoing connection request.
  Future<LearningConnectionsResult<LearningConnectionRequest>> cancelRequest(
    String requestId,
  );

  /// Authoritatively removes an existing learning connection.
  Future<LearningConnectionsResult<void>> removeConnection(
    String connectionId,
  );
}
