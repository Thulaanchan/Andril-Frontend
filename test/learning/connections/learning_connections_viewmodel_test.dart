import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/connections/domain/entities/learning_connection.dart';
import 'package:andril_mobile/features/learning/connections/domain/entities/learning_connection_request.dart';
import 'package:andril_mobile/features/learning/connections/domain/repositories/i_learning_connections_repository.dart';
import 'package:andril_mobile/features/learning/connections/presentation/viewmodels/learning_connections_viewmodel.dart';
import 'package:andril_mobile/features/learning/discovery/domain/entities/learning_partner_candidate.dart';

class FakeSessionController extends ChangeNotifier
    implements SessionController {
  SessionPhase _stubPhase;
  final Set<VoidCallback> _clearers = {};

  FakeSessionController({SessionPhase phase = SessionPhase.signedIn})
      : _stubPhase = phase;

  @override
  SessionPhase get phase => _stubPhase;

  @override
  bool get moduleHomeAuthorized => false;

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clear) {
    _clearers.add(clear);
    return () => _clearers.remove(clear);
  }

  void triggerPrivateStateClearers() {
    for (final clearer in List.of(_clearers)) {
      clearer();
    }
  }

  void setPhase(SessionPhase phase) {
    _stubPhase = phase;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLearningConnectionsRepository
    implements ILearningConnectionsRepository {
  bool isBackendActivated;
  List<LearningConnection> connections;
  List<LearningConnectionRequest> incomingRequests;
  List<LearningConnectionRequest> outgoingRequests;
  Completer<void>? delayCompleter;

  _FakeLearningConnectionsRepository({
    this.isBackendActivated = true,
    List<LearningConnection>? connections,
    List<LearningConnectionRequest>? incomingRequests,
    List<LearningConnectionRequest>? outgoingRequests,
  })  : connections = connections ?? [],
        incomingRequests = incomingRequests ?? [],
        outgoingRequests = outgoingRequests ?? [];

  @override
  Future<LearningConnectionsResult<List<LearningConnection>>>
      getConnections() async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: LearningConnectionsViewModel.disconnectedNotice,
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }
    return LearningConnectionsResult.success(connections);
  }

  @override
  Future<LearningConnectionsResult<List<LearningConnectionRequest>>>
      getIncomingRequests() async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: LearningConnectionsViewModel.disconnectedNotice,
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }
    return LearningConnectionsResult.success(incomingRequests);
  }

  @override
  Future<LearningConnectionsResult<List<LearningConnectionRequest>>>
      getOutgoingRequests() async {
    if (delayCompleter != null) await delayCompleter!.future;
    if (!isBackendActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: LearningConnectionsViewModel.disconnectedNotice,
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }
    return LearningConnectionsResult.success(outgoingRequests);
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> sendRequest({
    required String recipientProfileId,
    required String recipientDisplayName,
    Iterable<String>? recipientSkills,
    String? note,
  }) async {
    if (delayCompleter != null) await delayCompleter!.future;
    final newReq = LearningConnectionRequest(
      id: 'req_sent_${outgoingRequests.length + 1}',
      senderProfileId: 'current_user',
      senderDisplayName: 'Current User',
      receiverProfileId: recipientProfileId,
      receiverDisplayName: recipientDisplayName,
      note: note,
      isIncoming: false,
    );
    outgoingRequests.add(newReq);
    return LearningConnectionsResult.success(newReq);
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> acceptRequest(
    String requestId,
  ) async {
    if (delayCompleter != null) await delayCompleter!.future;
    final index = incomingRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Request not found',
        failureType: LearningConnectionsFailureType.notFound,
      );
    }
    final req = incomingRequests[index];
    incomingRequests.removeAt(index);
    final updated = req.copyWith(status: LearningRequestStatus.accepted);
    connections.add(LearningConnection(
      id: 'conn_${req.id}',
      peerProfileId: req.senderProfileId,
      peerDisplayName: req.senderDisplayName,
      sharedSkills: req.senderSkills,
    ));
    return LearningConnectionsResult.success(updated);
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> declineRequest(
    String requestId,
  ) async {
    if (delayCompleter != null) await delayCompleter!.future;
    final index = incomingRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Request not found',
        failureType: LearningConnectionsFailureType.notFound,
      );
    }
    final req = incomingRequests.removeAt(index);
    return LearningConnectionsResult.success(
      req.copyWith(status: LearningRequestStatus.declined),
    );
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> cancelRequest(
    String requestId,
  ) async {
    if (delayCompleter != null) await delayCompleter!.future;
    final index = outgoingRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Request not found',
        failureType: LearningConnectionsFailureType.notFound,
      );
    }
    final req = outgoingRequests.removeAt(index);
    return LearningConnectionsResult.success(
      req.copyWith(status: LearningRequestStatus.cancelled),
    );
  }

  @override
  Future<LearningConnectionsResult<void>> removeConnection(
    String connectionId,
  ) async {
    if (delayCompleter != null) await delayCompleter!.future;
    connections.removeWhere((c) => c.id == connectionId);
    return const LearningConnectionsResult.success(null);
  }
}

void main() {
  group('LearningConnectionsViewModel Unit Tests', () {
    late _FakeLearningConnectionsRepository repository;
    late FakeSessionController sessionController;

    setUp(() {
      repository = _FakeLearningConnectionsRepository(
        connections: [
          LearningConnection(
            id: 'conn_01',
            peerProfileId: 'peer_1',
            peerDisplayName: 'Alice Johnson',
            sharedSkills: ['Flutter', 'Dart'],
            learningGoals: ['Cross Platform Dev'],
          ),
          LearningConnection(
            id: 'conn_02',
            peerProfileId: 'peer_2',
            peerDisplayName: 'Bob Smith',
            sharedSkills: ['Python', 'Machine Learning'],
            learningGoals: ['Data Science'],
          ),
        ],
        incomingRequests: [
          LearningConnectionRequest(
            id: 'req_inc_01',
            senderProfileId: 'sender_1',
            senderDisplayName: 'Charlie Davis',
            receiverProfileId: 'current_user',
            receiverDisplayName: 'Me',
            senderSkills: ['Kotlin'],
            note: 'Want to learn together?',
            isIncoming: true,
          ),
        ],
        outgoingRequests: [
          LearningConnectionRequest(
            id: 'req_out_01',
            senderProfileId: 'current_user',
            senderDisplayName: 'Me',
            receiverProfileId: 'receiver_1',
            receiverDisplayName: 'Diana Prince',
            isIncoming: false,
          ),
        ],
      );
      sessionController = FakeSessionController();
    });

    test('initializes with default status and tab', () {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      expect(vm.status, equals(LearningConnectionsViewStatus.initial));
      expect(vm.activeTab, equals(LearningConnectionsTab.myConnections));
      expect(vm.searchQuery, isEmpty);
      expect(vm.connectionsCount, equals(0));
    });

    test('fails closed with accessDenied when isLearningActivated is false',
        () async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: false,
      );

      await vm.initialize();
      expect(vm.status, equals(LearningConnectionsViewStatus.accessDenied));
      expect(vm.isAccessDenied, isTrue);
    });

    test('fails closed with accessDenied when unauthenticated', () async {
      final unauthSession =
          FakeSessionController(phase: SessionPhase.signedOut);
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: unauthSession,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.status, equals(LearningConnectionsViewStatus.accessDenied));
    });

    test('successfully loads connections, incoming, and outgoing requests',
        () async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.status, equals(LearningConnectionsViewStatus.ready));
      expect(vm.connectionsCount, equals(2));
      expect(vm.incomingCount, equals(1));
      expect(vm.outgoingCount, equals(1));
    });

    test('sets status to empty when repository returns no items', () async {
      final emptyRepo = _FakeLearningConnectionsRepository();
      final vm = LearningConnectionsViewModel(
        repository: emptyRepo,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.status, equals(LearningConnectionsViewStatus.empty));
      expect(vm.isEmpty, isTrue);
    });

    test(
        'sets status to unavailableService when backend contract is disconnected',
        () async {
      final dormantRepo =
          _FakeLearningConnectionsRepository(isBackendActivated: false);
      final vm = LearningConnectionsViewModel(
        repository: dormantRepo,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(
          vm.status, equals(LearningConnectionsViewStatus.unavailableService));
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.errorMessage,
          contains('Remote connections backend contract pending'));
    });

    test('search filtering filters across connections by name and skills',
        () async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();

      // Search by name
      vm.setSearchQuery('Alice');
      expect(vm.filteredConnections.length, equals(1));
      expect(vm.filteredConnections.first.peerDisplayName,
          equals('Alice Johnson'));

      // Search by skill
      vm.setSearchQuery('Machine Learning');
      expect(vm.filteredConnections.length, equals(1));
      expect(vm.filteredConnections.first.peerDisplayName, equals('Bob Smith'));

      // Clear search
      vm.setSearchQuery('');
      expect(vm.filteredConnections.length, equals(2));
    });

    test(
        'acceptRequest authoritatively accepts incoming and adds to connections',
        () async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.incomingCount, equals(1));
      expect(vm.connectionsCount, equals(2));

      final success = await vm.acceptRequest('req_inc_01');
      expect(success, isTrue);
      expect(vm.incomingCount, equals(0));
      expect(vm.connectionsCount, equals(3));
      expect(vm.connections.any((c) => c.peerDisplayName == 'Charlie Davis'),
          isTrue);
    });

    test('declineRequest removes request from incoming list', () async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.incomingCount, equals(1));

      final success = await vm.declineRequest('req_inc_01');
      expect(success, isTrue);
      expect(vm.incomingCount, equals(0));
    });

    test('cancelRequest removes request from outgoing list', () async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.outgoingCount, equals(1));

      final success = await vm.cancelRequest('req_out_01');
      expect(success, isTrue);
      expect(vm.outgoingCount, equals(0));
    });

    test('removeConnection authoritatively removes active connection',
        () async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.connectionsCount, equals(2));

      final success = await vm.removeConnection('conn_01');
      expect(success, isTrue);
      expect(vm.connectionsCount, equals(1));
      expect(vm.connections.first.id, equals('conn_02'));
    });

    test('sendRequest adds new request to outgoing list', () async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.outgoingCount, equals(1));

      final candidate = LearningPartnerCandidate(
        id: 'cand_new_01',
        displayName: 'Frank Castle',
        skillsToShare: ['Strategy', 'Leadership'],
      );

      final success = await vm.sendRequest(candidate, note: 'Glad to connect!');
      expect(success, isTrue);
      expect(vm.outgoingCount, equals(2));
      expect(
          vm.outgoingRequests.last.receiverDisplayName, equals('Frank Castle'));
    });

    test('clears private state on session revocation / sign out', () async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.connectionsCount, equals(2));

      // Revoke session
      sessionController.setPhase(SessionPhase.signedOut);
      sessionController.triggerPrivateStateClearers();

      expect(vm.connectionsCount, equals(0));
      expect(vm.incomingCount, equals(0));
      expect(vm.outgoingCount, equals(0));
      expect(vm.status, equals(LearningConnectionsViewStatus.accessDenied));
    });

    test('discards stale asynchronous responses via epoch check', () async {
      final completer1 = Completer<void>();
      repository.delayCompleter = completer1;

      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      final future1 = vm.initialize();

      // Trigger second supersede initialize
      repository.delayCompleter = null;
      final future2 = vm.initialize(force: true);

      completer1.complete();
      await future1;
      await future2;

      expect(vm.status, equals(LearningConnectionsViewStatus.ready));
      expect(vm.connectionsCount, equals(2));
    });
  });
}
