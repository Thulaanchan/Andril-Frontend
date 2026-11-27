import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:andril_mobile/core/constants/app_config.dart';
import 'package:andril_mobile/core/network/api_client/andril_api_client.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/portfolio_maker/data/services/learning_cv_import_api_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared_core/authentication/foundation_fakes.dart';

class _TestTransport implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  late FutureOr<ResponseBody> Function(RequestOptions) reply;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

class _Source extends FakeSessionSource implements BackendSessionSource {
  _Source()
      : super(
            restored:
                const SessionEvent(SessionEventKind.initial, subject: 'U'));

  @override
  BackendCredential? backendCredential =
      const BackendCredential('U', 'fake.token.jwt', emailConfirmed: true);

  @override
  Future<void> refreshBackendCredential(BackendCredential rejected) async {}
}

void main() {
  late _Source source;
  late SessionController session;
  late _TestTransport http;
  late AndrilApiClient apiClient;
  late LearningCvImportRemoteDataSource remoteDataSource;

  setUp(() async {
    source = _Source();
    session = SessionController(source);
    http = _TestTransport();
    apiClient = AndrilApiClient(
      AppConfig.fromValues(
        environment: 'development',
        supabaseUrl: 'https://synthetic.supabase.co',
        publicKey: 'sb_publishable_synthetic',
        apiBaseUrl: 'https://andril.invalid:8443/',
      ),
      session,
      adapter: http,
    );
    remoteDataSource = LearningCvImportRemoteDataSource(apiClient);
    await session.start();
  });

  tearDown(() async {
    apiClient.close();
    session.dispose();
    await source.signals.close();
  });

  group('LearningCvImportRemoteDataSource', () {
    const portfolioId = '11111111-1111-1111-1111-111111111111';
    const cvId = '22222222-2222-2222-2222-222222222222';
    const projId = '33333333-3333-3333-3333-333333333333';
    const reviewId = '44444444-4444-4444-4444-444444444444';

    test('requestImportReview sends valid body and parses review response',
        () async {
      http.reply = (options) {
        expect(options.method, 'POST');
        expect(options.path,
            'https://andril.invalid:8443/api/v1/learning/cv-imports/reviews');
        final data = jsonDecode(options.data as String);
        expect(data['portfolioId'], portfolioId);
        expect(data['cvId'], cvId);
        expect(data['projectIds'], [projId]);

        return ResponseBody.fromString(
          jsonEncode({
            'reviewId': reviewId,
            'portfolioId': portfolioId,
            'cvId': cvId,
            'projects': [
              {
                'projectId': projId,
                'title': 'Awesome App',
                'description': 'Mobile Flutter app',
              }
            ],
          }),
          200,
          headers: {
            'content-type': ['application/json']
          },
        );
      };

      final result = await remoteDataSource.requestImportReview(
        session: session.backendSession!,
        portfolioId: portfolioId,
        cvId: cvId,
        projectIds: [projId],
      );

      expect(result.reviewId, reviewId);
      expect(result.portfolioId, portfolioId);
      expect(result.cvId, cvId);
      expect(result.projects.length, 1);
      expect(result.projects.first.title, 'Awesome App');
    });

    test('confirmImportReview sends POST confirmation and receives 204',
        () async {
      http.reply = (options) {
        expect(options.method, 'POST');
        expect(options.path,
            'https://andril.invalid:8443/api/v1/learning/cv-imports/$reviewId/confirm');
        final data = jsonDecode(options.data as String);
        expect(data['confirmed'], true);

        return ResponseBody.fromString('', 204);
      };

      await expectLater(
        remoteDataSource.confirmImportReview(
          session: session.backendSession!,
          reviewId: reviewId,
          confirmed: true,
        ),
        completes,
      );
    });

    test('rejects malformed UUIDs with ArgumentError', () async {
      expect(
        () => remoteDataSource.requestImportReview(
          session: session.backendSession!,
          portfolioId: 'invalid-id',
          cvId: cvId,
          projectIds: [projId],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
