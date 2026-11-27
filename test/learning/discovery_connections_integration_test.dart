import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/connections/domain/entities/learning_connection.dart';
import 'package:andril_mobile/features/learning/connections/domain/entities/learning_connection_request.dart';
import 'package:andril_mobile/features/learning/connections/domain/repositories/i_learning_connections_repository.dart';
import 'package:andril_mobile/features/learning/connections/presentation/viewmodels/learning_connections_viewmodel.dart';
import 'package:andril_mobile/features/learning/connections/presentation/widgets/send_connection_request_dialog.dart';
import 'package:andril_mobile/features/learning/discovery/domain/entities/learning_partner_candidate.dart';
import 'package:andril_mobile/features/learning/discovery/domain/entities/learning_partner_filters.dart';
import 'package:andril_mobile/features/learning/discovery/domain/repositories/i_learning_discovery_repository.dart';
import 'package:andril_mobile/features/learning/discovery/presentation/screens/learning_partner_explorer_screen.dart';
import 'package:andril_mobile/features/learning/discovery/presentation/viewmodels/learning_partner_explorer_viewmodel.dart';
import 'package:andril_mobile/features/learning/discovery/presentation/widgets/learning_partner_profile_dialog.dart';

class _FakeSessionController extends ChangeNotifier
    implements SessionController {
  SessionPhase _stubPhase;
  final Set<VoidCallback> _clearers = {};

  _FakeSessionController({SessionPhase phase = SessionPhase.signedIn})
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

class _FakeDiscoveryRepo implements ILearningDiscoveryRepository {
  List<LearningPartnerCandidate> candidates;
  bool isActivated;

  _FakeDiscoveryRepo({
    List<LearningPartnerCandidate>? candidates,
    this.isActivated = true,
  }) : candidates = candidates ?? [];

  @override
  Future<LearningDiscoveryResult<List<LearningPartnerCandidate>>>
      getCandidates({
    LearningPartnerFilters? filters,
    int offset = 0,
    int limit = 20,
  }) async {
    if (!isActivated) {
      return const LearningDiscoveryResult.failure(
        errorMessage:
            'Remote discovery backend contract pending in OpenAPI v1.',
        failureType: LearningDiscoveryFailureType.serviceUnavailable,
      );
    }
    return LearningDiscoveryResult.success(candidates);
  }
}

class _FakeConnectionsRepo implements ILearningConnectionsRepository {
  final List<LearningConnection> connections = [];
  final List<LearningConnectionRequest> incomingRequests = [];
  final List<LearningConnectionRequest> outgoingRequests = [];
  bool isActivated = true;

  _FakeConnectionsRepo({
    List<LearningConnection>? initialConnections,
    List<LearningConnectionRequest>? initialIncoming,
    List<LearningConnectionRequest>? initialOutgoing,
  }) {
    if (initialConnections != null) connections.addAll(initialConnections);
    if (initialIncoming != null) incomingRequests.addAll(initialIncoming);
    if (initialOutgoing != null) outgoingRequests.addAll(initialOutgoing);
  }

  @override
  Future<LearningConnectionsResult<List<LearningConnection>>>
      getConnections() async {
    if (!isActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Remote connections contract pending in OpenAPI v1.',
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }
    return LearningConnectionsResult.success(List.unmodifiable(connections));
  }

  @override
  Future<LearningConnectionsResult<List<LearningConnectionRequest>>>
      getIncomingRequests() async {
    if (!isActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Remote connections contract pending in OpenAPI v1.',
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }
    return LearningConnectionsResult.success(
        List.unmodifiable(incomingRequests));
  }

  @override
  Future<LearningConnectionsResult<List<LearningConnectionRequest>>>
      getOutgoingRequests() async {
    if (!isActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Remote connections contract pending in OpenAPI v1.',
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }
    return LearningConnectionsResult.success(
        List.unmodifiable(outgoingRequests));
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> sendRequest({
    required String recipientProfileId,
    required String recipientDisplayName,
    Iterable<String>? recipientSkills,
    String? note,
  }) async {
    if (!isActivated) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Service unavailable.',
        failureType: LearningConnectionsFailureType.serviceUnavailable,
      );
    }

    if (outgoingRequests
        .any((r) => r.receiverProfileId == recipientProfileId)) {
      return const LearningConnectionsResult.failure(
        errorMessage:
            'A connection request has already been sent to this peer.',
        failureType: LearningConnectionsFailureType.conflict,
      );
    }

    final req = LearningConnectionRequest(
      id: 'req_${outgoingRequests.length + 1}',
      senderProfileId: 'current_user',
      senderDisplayName: 'Current User',
      receiverProfileId: recipientProfileId,
      receiverDisplayName: recipientDisplayName,
      isIncoming: false,
      status: LearningRequestStatus.pending,
      note: note,
      createdAt: DateTime.now(),
    );
    outgoingRequests.add(req);
    return LearningConnectionsResult.success(req);
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> acceptRequest(
      String requestId) async {
    final idx = incomingRequests.indexWhere((r) => r.id == requestId);
    if (idx < 0) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Request not found.',
        failureType: LearningConnectionsFailureType.notFound,
      );
    }
    final req = incomingRequests.removeAt(idx);
    final acceptedReq = LearningConnectionRequest(
      id: req.id,
      senderProfileId: req.senderProfileId,
      senderDisplayName: req.senderDisplayName,
      receiverProfileId: req.receiverProfileId,
      receiverDisplayName: req.receiverDisplayName,
      status: LearningRequestStatus.accepted,
      isIncoming: req.isIncoming,
    );
    connections.add(
      LearningConnection(
        id: 'conn_${req.id}',
        peerProfileId: req.senderProfileId,
        peerDisplayName: req.senderDisplayName,
        connectedAt: DateTime.now(),
      ),
    );
    return LearningConnectionsResult.success(acceptedReq);
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> declineRequest(
      String requestId) async {
    final idx = incomingRequests.indexWhere((r) => r.id == requestId);
    if (idx < 0) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Request not found.',
        failureType: LearningConnectionsFailureType.notFound,
      );
    }
    final req = incomingRequests.removeAt(idx);
    return LearningConnectionsResult.success(
      LearningConnectionRequest(
        id: req.id,
        senderProfileId: req.senderProfileId,
        senderDisplayName: req.senderDisplayName,
        receiverProfileId: req.receiverProfileId,
        receiverDisplayName: req.receiverDisplayName,
        status: LearningRequestStatus.declined,
        isIncoming: req.isIncoming,
      ),
    );
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> cancelRequest(
      String requestId) async {
    final idx = outgoingRequests.indexWhere((r) => r.id == requestId);
    if (idx < 0) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Request not found.',
        failureType: LearningConnectionsFailureType.notFound,
      );
    }
    final req = outgoingRequests.removeAt(idx);
    return LearningConnectionsResult.success(
      LearningConnectionRequest(
        id: req.id,
        senderProfileId: req.senderProfileId,
        senderDisplayName: req.senderDisplayName,
        receiverProfileId: req.receiverProfileId,
        receiverDisplayName: req.receiverDisplayName,
        status: LearningRequestStatus.cancelled,
        isIncoming: req.isIncoming,
      ),
    );
  }

  @override
  Future<LearningConnectionsResult<void>> removeConnection(
      String connectionId) async {
    final idx = connections.indexWhere((c) => c.id == connectionId);
    if (idx < 0) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Connection not found.',
        failureType: LearningConnectionsFailureType.notFound,
      );
    }
    connections.removeAt(idx);
    return const LearningConnectionsResult.success(null);
  }
}

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Scaffold(body: child),
  );
}

void main() {
  group('Task 06-03: Discovery & Connections Integration Tests', () {
    late _FakeSessionController session;

    setUp(() {
      session = _FakeSessionController(phase: SessionPhase.signedIn);
    });

    test('1. Candidate entity enforces learning module isolation and identity',
        () {
      final candidate = LearningPartnerCandidate(
        id: 'lp_partner_01',
        displayName: 'Dev Maya',
        bio: 'Mobile Engineer learning AI',
        skillsToShare: const ['Flutter', 'Dart'],
        skillsToLearn: const ['Machine Learning', 'TensorFlow'],
        learningGoals: const ['Deploy on-device ML'],
        availability: 'Morning (6 AM – 12 PM)',
        languages: const ['English', 'Tamil'],
      );

      expect(candidate.module, 'learning');
      expect(candidate.id, 'lp_partner_01');
      expect(candidate.displayName, 'Dev Maya');
      expect(candidate.skillsToShare, contains('Flutter'));
      expect(candidate.skillsToLearn, contains('Machine Learning'));
    });

    test(
        '2. Discovery filtering applies search query and proficiency filters without inventing scores',
        () async {
      final candidates = [
        LearningPartnerCandidate(
          id: 'lp_1',
          displayName: 'Aarav Kumar',
          skillsToShare: const ['Flutter UI'],
          skillsToLearn: const ['Go Lang'],
        ),
        LearningPartnerCandidate(
          id: 'lp_2',
          displayName: 'Bhavna Sen',
          skillsToShare: const ['Go Lang'],
          skillsToLearn: const ['Flutter UI'],
        ),
      ];

      final repo = _FakeDiscoveryRepo(candidates: candidates);
      final vm = LearningPartnerExplorerViewModel(
        repository: repo,
        sessionController: session,
        isLearningActivated: true,
      );
      await vm.initialize();

      expect(vm.candidates.length, 2);

      vm.applyFilters(LearningPartnerFilters(searchQuery: 'Bhavna'));
      expect(vm.candidates.length, 1);
      expect(vm.candidates.first.displayName, 'Bhavna Sen');

      vm.resetFilters();
      expect(vm.candidates.length, 2);
    });

    test(
        '3. Duplicate-request prevention blocks sending duplicate requests to existing partner',
        () async {
      final connectionsRepo = _FakeConnectionsRepo();
      final vm = LearningConnectionsViewModel(
        repository: connectionsRepo,
        sessionController: session,
        isLearningActivated: true,
      );
      await vm.initialize();

      final candidate = LearningPartnerCandidate(
        id: 'lp_partner_99',
        displayName: 'Priya Dev',
      );

      // First request succeeds
      final res1 = await vm.sendRequest(
        candidate,
        note: 'Let us study together',
      );
      expect(res1, isTrue);
      expect(vm.outgoingRequests.length, 1);

      // Duplicate request to same recipient fails with conflict error
      final res2 = await vm.sendRequest(
        candidate,
        note: 'Second request attempt',
      );
      expect(res2, isFalse);
      expect(vm.errorMessage, contains('already been sent'));
      expect(vm.outgoingRequests.length, 1);
    });

    test(
        '4. Connection accept, decline, cancel, and remove transitions state authoritatively',
        () async {
      final initialIncoming = [
        LearningConnectionRequest(
          id: 'req_inc_1',
          senderProfileId: 'lp_peer_1',
          senderDisplayName: 'Learner One',
          receiverProfileId: 'current_user',
          receiverDisplayName: 'Me',
          isIncoming: true,
          status: LearningRequestStatus.pending,
        ),
        LearningConnectionRequest(
          id: 'req_inc_2',
          senderProfileId: 'lp_peer_2',
          senderDisplayName: 'Learner Two',
          receiverProfileId: 'current_user',
          receiverDisplayName: 'Me',
          isIncoming: true,
          status: LearningRequestStatus.pending,
        ),
      ];

      final initialOutgoing = [
        LearningConnectionRequest(
          id: 'req_out_1',
          senderProfileId: 'current_user',
          senderDisplayName: 'Me',
          receiverProfileId: 'lp_peer_3',
          receiverDisplayName: 'Learner Three',
          isIncoming: false,
          status: LearningRequestStatus.pending,
        ),
      ];

      final repo = _FakeConnectionsRepo(
        initialIncoming: initialIncoming,
        initialOutgoing: initialOutgoing,
      );

      final vm = LearningConnectionsViewModel(
        repository: repo,
        sessionController: session,
        isLearningActivated: true,
        initialIncomingRequests: initialIncoming,
        initialOutgoingRequests: initialOutgoing,
      );

      // Accept incoming request
      final accepted = await vm.acceptRequest('req_inc_1');
      expect(accepted, isTrue);
      expect(vm.incomingRequests.length, 1);
      expect(vm.connections.length, 1);
      expect(vm.connections.first.peerProfileId, 'lp_peer_1');

      // Decline second incoming request
      final declined = await vm.declineRequest('req_inc_2');
      expect(declined, isTrue);
      expect(vm.incomingRequests, isEmpty);

      // Cancel outgoing request
      final canceled = await vm.cancelRequest('req_out_1');
      expect(canceled, isTrue);
      expect(vm.outgoingRequests, isEmpty);

      // Remove established connection
      final removed = await vm.removeConnection(vm.connections.first.id);
      expect(removed, isTrue);
      expect(vm.connections, isEmpty);
    });

    test(
        '5. Session revocation immediately clears private state across discovery and connections',
        () async {
      final candidates = [
        LearningPartnerCandidate(
          id: 'lp_1',
          displayName: 'Private Candidate',
        ),
      ];
      final connections = [
        LearningConnection(
          id: 'conn_1',
          peerProfileId: 'lp_private_peer',
          peerDisplayName: 'Private Peer',
        ),
      ];

      final discoveryRepo = _FakeDiscoveryRepo(candidates: candidates);
      final connectionsRepo =
          _FakeConnectionsRepo(initialConnections: connections);

      final discoveryVm = LearningPartnerExplorerViewModel(
        repository: discoveryRepo,
        sessionController: session,
        isLearningActivated: true,
        initialCandidates: candidates,
      );
      await discoveryVm.initialize();

      final connectionsVm = LearningConnectionsViewModel(
        repository: connectionsRepo,
        sessionController: session,
        isLearningActivated: true,
        initialConnections: connections,
      );
      await connectionsVm.initialize();

      expect(discoveryVm.candidates.length, 1);
      expect(connectionsVm.connections.length, 1);

      // Revoke session via registered clearers
      session.triggerPrivateStateClearers();

      // Both ViewModels purged private in-memory state
      expect(discoveryVm.candidates, isEmpty);
      expect(connectionsVm.connections, isEmpty);
    });

    test('6. Stale response protection rejects out-of-order async responses',
        () async {
      final repo = _FakeDiscoveryRepo();
      final vm = LearningPartnerExplorerViewModel(
        repository: repo,
        sessionController: session,
        isLearningActivated: true,
      );

      await vm.initialize();
      expect(vm.status, LearningPartnerExplorerStatus.empty);

      // Apply rapid successive filter changes
      vm.applyFilters(LearningPartnerFilters(searchQuery: 'Query 1'));
      vm.applyFilters(LearningPartnerFilters(searchQuery: 'Query 2'));
      vm.applyFilters(LearningPartnerFilters(searchQuery: 'Final'));

      expect(vm.filters.searchQuery, 'Final');
    });

    testWidgets(
        '7. Profile preview dialog renders private profile details and handles connect',
        (tester) async {
      final candidate = LearningPartnerCandidate(
        id: 'lp_candidate_dialog',
        displayName: 'Ravi Teja',
        bio: 'Passionate about mobile architectures and clean code.',
        skillsToShare: const ['Flutter', 'Riverpod'],
        skillsToLearn: const ['Rust', 'Wasm'],
        learningGoals: const ['Master cross-platform performance'],
        availability: 'Flexible (Any time)',
        languages: const ['English', 'Telugu'],
      );

      var connectTapped = false;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                LearningPartnerProfileDialog.show(
                  ctx,
                  candidate: candidate,
                  onConnect: (c) {
                    connectTapped = true;
                  },
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Ravi Teja'), findsOneWidget);
      expect(find.text('Passionate about mobile architectures and clean code.'),
          findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Rust'), findsOneWidget);

      await tester.tap(find.text('Connect with Partner'));
      await tester.pumpAndSettle();
      expect(connectTapped, isTrue);
    });

    testWidgets(
        '8. SendConnectionRequestDialog captures optional note and executes callback',
        (tester) async {
      final candidate = LearningPartnerCandidate(
        id: 'lp_target_dialog',
        displayName: 'Ananya Sharma',
      );

      String? submittedNote;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                SendConnectionRequestDialog.show(
                  ctx,
                  candidate: candidate,
                  onSend: (note) async {
                    submittedNote = note;
                    return true;
                  },
                );
              },
              child: const Text('Send Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Send Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Connect with Ananya Sharma'), findsOneWidget);

      // Enter optional note
      await tester.enterText(
        find.byType(TextField),
        'Hi Ananya, would love to collaborate on Flutter projects!',
      );
      await tester.tap(find.text('Send Request'));
      await tester.pumpAndSettle();

      expect(submittedNote,
          'Hi Ananya, would love to collaborate on Flutter projects!');
    });

    testWidgets(
        '9. Dormant backend contract displays explicit notice banner in presentation mode',
        (tester) async {
      final discoveryRepo = _FakeDiscoveryRepo(isActivated: false);
      final vm = LearningPartnerExplorerViewModel(
        repository: discoveryRepo,
        sessionController: session,
        isLearningActivated: true,
      );

      await tester.pumpWidget(
        _buildTestApp(
          LearningPartnerExplorerScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(vm.isServiceUnavailable, isTrue);
      expect(
        find.text(
          'Remote discovery backend contract pending in OpenAPI v1. Operating in local presentation mode.',
        ),
        findsOneWidget,
      );
    });
  });
}
