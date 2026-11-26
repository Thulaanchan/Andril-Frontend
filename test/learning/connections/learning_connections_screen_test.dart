import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/connections/domain/entities/learning_connection.dart';
import 'package:andril_mobile/features/learning/connections/domain/entities/learning_connection_request.dart';
import 'package:andril_mobile/features/learning/connections/domain/repositories/i_learning_connections_repository.dart';
import 'package:andril_mobile/features/learning/connections/presentation/screens/learning_connections_screen.dart';
import 'package:andril_mobile/features/learning/connections/presentation/viewmodels/learning_connections_viewmodel.dart';
import 'package:andril_mobile/features/learning/connections/presentation/widgets/send_connection_request_dialog.dart';
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

class _FakeScreenRepo implements ILearningConnectionsRepository {
  bool isBackendActivated;
  List<LearningConnection> connections;
  List<LearningConnectionRequest> incomingRequests;
  List<LearningConnectionRequest> outgoingRequests;
  Completer<void>? delayCompleter;

  _FakeScreenRepo({
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
        errorMessage: 'Not found',
        failureType: LearningConnectionsFailureType.notFound,
      );
    }
    final req = incomingRequests.removeAt(index);
    connections.add(LearningConnection(
      id: 'conn_${req.id}',
      peerProfileId: req.senderProfileId,
      peerDisplayName: req.senderDisplayName,
      sharedSkills: req.senderSkills,
    ));
    return LearningConnectionsResult.success(
      req.copyWith(status: LearningRequestStatus.accepted),
    );
  }

  @override
  Future<LearningConnectionsResult<LearningConnectionRequest>> declineRequest(
    String requestId,
  ) async {
    if (delayCompleter != null) await delayCompleter!.future;
    final index = incomingRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      return const LearningConnectionsResult.failure(
        errorMessage: 'Not found',
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
        errorMessage: 'Not found',
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

Widget _buildTestApp({
  required LearningConnectionsViewModel viewModel,
  ValueChanged<LearningConnection>? onViewProfile,
  ValueChanged<LearningConnection>? onMessage,
  VoidCallback? onExplorePartners,
  Size size = const Size(360, 640),
  double textScaleFactor = 1.0,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(textScaleFactor),
    ),
    child: MaterialApp(
      home: LearningConnectionsScreen(
        viewModel: viewModel,
        onViewProfile: onViewProfile,
        onMessage: onMessage,
        onExplorePartners: onExplorePartners,
      ),
    ),
  );
}

void main() {
  group('LearningConnectionsScreen Widget Tests', () {
    late _FakeScreenRepo repository;
    late FakeSessionController sessionController;

    setUp(() {
      repository = _FakeScreenRepo(
        connections: [
          LearningConnection(
            id: 'conn_01',
            peerProfileId: 'peer_1',
            peerDisplayName: 'Alice Johnson',
            sharedSkills: ['Flutter', 'Dart'],
            learningGoals: ['Cross Platform Dev'],
          ),
        ],
        incomingRequests: [
          LearningConnectionRequest(
            id: 'req_inc_01',
            senderProfileId: 'sender_1',
            senderDisplayName: 'Charlie Davis',
            receiverProfileId: 'current_user',
            receiverDisplayName: 'Me',
            senderSkills: ['Kotlin', 'Android'],
            note: 'Would love to swap skills!',
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

    testWidgets(
        'renders all initial screen elements: tabs, badges, notice banner',
        (tester) async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Tab bar tabs
      expect(find.byKey(const ValueKey('tab_my_connections')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('tab_incoming_requests')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_sent_requests')), findsOneWidget);

      // Disconnected notice banner
      expect(find.byKey(const ValueKey('banner_disconnected_notice')),
          findsOneWidget);

      // Search input
      expect(find.byKey(const ValueKey('input_connections_search')),
          findsOneWidget);

      // Renders connections list and card
      expect(find.byKey(const ValueKey('card_learning_connection_conn_01')),
          findsOneWidget);
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
    });

    testWidgets('switching tabs switches between lists', (tester) async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Initially on Connections
      expect(find.text('Alice Johnson'), findsOneWidget);

      // Tap Incoming Requests Tab
      await tester.tap(find.byKey(const ValueKey('tab_incoming_requests')));
      await tester.pumpAndSettle();

      expect(find.text('Charlie Davis'), findsOneWidget);
      expect(find.text('"Would love to swap skills!"'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_accept_request_req_inc_01')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('btn_decline_request_req_inc_01')),
          findsOneWidget);

      // Tap Sent Requests Tab
      await tester.tap(find.byKey(const ValueKey('tab_sent_requests')));
      await tester.pumpAndSettle();

      expect(find.text('Diana Prince'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_cancel_request_req_out_01')),
          findsOneWidget);
    });

    testWidgets(
        'accepting incoming request shows updated state and adds connection',
        (tester) async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Go to Incoming tab
      await tester.tap(find.byKey(const ValueKey('tab_incoming_requests')));
      await tester.pumpAndSettle();

      expect(find.text('Charlie Davis'), findsOneWidget);

      // Tap Accept
      await tester
          .tap(find.byKey(const ValueKey('btn_accept_request_req_inc_01')));
      await tester.pumpAndSettle();

      // Now incoming tab is empty
      expect(find.byKey(const ValueKey('empty_incoming_requests_view')),
          findsOneWidget);

      // Go back to Connections tab
      await tester.tap(find.byKey(const ValueKey('tab_my_connections')));
      await tester.pumpAndSettle();

      expect(find.text('Charlie Davis'), findsOneWidget);
      expect(find.text('Alice Johnson'), findsOneWidget);
    });

    testWidgets(
        'declining incoming request shows confirmation dialog and removes',
        (tester) async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Go to Incoming tab
      await tester.tap(find.byKey(const ValueKey('tab_incoming_requests')));
      await tester.pumpAndSettle();

      // Tap Decline
      await tester
          .tap(find.byKey(const ValueKey('btn_decline_request_req_inc_01')));
      await tester.pumpAndSettle();

      // Confirmation dialog must appear
      expect(find.text('Decline Request?'), findsOneWidget);

      // Tap Decline on confirmation
      await tester.tap(find.text('Decline').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('empty_incoming_requests_view')),
          findsOneWidget);
    });

    testWidgets('cancelling sent request shows confirmation dialog and cancels',
        (tester) async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      // Go to Sent tab
      await tester.tap(find.byKey(const ValueKey('tab_sent_requests')));
      await tester.pumpAndSettle();

      // Tap Cancel Request button
      await tester
          .tap(find.byKey(const ValueKey('btn_cancel_request_req_out_01')));
      await tester.pumpAndSettle();

      // Confirmation dialog must appear
      expect(find.text('Cancel Request?'), findsOneWidget);

      // Confirm cancellation
      await tester.tap(find.text('Cancel Request').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('empty_sent_requests_view')),
          findsOneWidget);
    });

    testWidgets(
        'removing connection shows confirmation dialog and removes connection',
        (tester) async {
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.text('Alice Johnson'), findsOneWidget);

      // Tap Remove icon button
      await tester
          .tap(find.byKey(const ValueKey('btn_remove_connection_conn_01')));
      await tester.pumpAndSettle();

      // Confirmation dialog must appear
      expect(find.text('Remove Connection?'), findsOneWidget);

      // Confirm Remove
      await tester.tap(find.text('Remove').last);
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('empty_connections_view')), findsOneWidget);
    });

    testWidgets(
        'tapping explore button on empty view invokes onExplorePartners',
        (tester) async {
      final emptyRepo = _FakeScreenRepo();
      final vm = LearningConnectionsViewModel(
        repository: emptyRepo,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      bool explored = false;
      await tester.pumpWidget(_buildTestApp(
        viewModel: vm,
        onExplorePartners: () {
          explored = true;
        },
      ));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('empty_connections_view')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('btn_empty_action_explore')));
      await tester.pumpAndSettle();

      expect(explored, isTrue);
    });

    testWidgets('renders access-denied state when unauthenticated',
        (tester) async {
      final unauthSession =
          FakeSessionController(phase: SessionPhase.signedOut);
      final vm = LearningConnectionsViewModel(
        repository: repository,
        sessionController: unauthSession,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('access_denied_connections_view')),
          findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets(
        'renders service-unavailable state when remote contract is pending',
        (tester) async {
      final dormantRepo = _FakeScreenRepo(isBackendActivated: false);
      final vm = LearningConnectionsViewModel(
        repository: dormantRepo,
        sessionController: sessionController,
        isLearningActivated: true,
      );

      await tester.pumpWidget(_buildTestApp(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('service_unavailable_connections_view')),
          findsOneWidget);
      expect(find.text('Service Notice'), findsOneWidget);
    });

    testWidgets('SendConnectionRequestDialog renders and submits note',
        (tester) async {
      final candidate = LearningPartnerCandidate(
        id: 'cand_dlg_01',
        displayName: 'Grace Hopper',
        skillsToShare: ['Compilers', 'COBOL'],
      );

      String? submittedNote;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
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
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dialog_send_connection_request')),
          findsOneWidget);
      expect(find.text('Connect with Grace Hopper'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('input_connection_note')),
        'I would like to collaborate on compiler development.',
      );

      await tester.tap(find.byKey(const ValueKey('btn_confirm_send_request')));
      await tester.pumpAndSettle();

      expect(submittedNote,
          equals('I would like to collaborate on compiler development.'));
    });

    group('Responsive Viewport & Dynamic Text Scaling Tests', () {
      final viewports = [
        const Size(320, 568), // Compact / iPhone SE
        const Size(360, 640), // Standard Android
        const Size(412, 915), // Large flagship Android
      ];

      for (final vp in viewports) {
        testWidgets(
            'renders cleanly on ${vp.width}x${vp.height} without overflow',
            (tester) async {
          final vm = LearningConnectionsViewModel(
            repository: repository,
            sessionController: sessionController,
            isLearningActivated: true,
          );

          await tester.pumpWidget(
            _buildTestApp(viewModel: vm, size: vp),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Alice Johnson'), findsOneWidget);
        });
      }

      testWidgets('renders with 1.5x dynamic text scale without overflow',
          (tester) async {
        final vm = LearningConnectionsViewModel(
          repository: repository,
          sessionController: sessionController,
          isLearningActivated: true,
        );

        await tester.pumpWidget(
          _buildTestApp(
            viewModel: vm,
            size: const Size(360, 640),
            textScaleFactor: 1.5,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Alice Johnson'), findsOneWidget);
      });
    });
  });
}
