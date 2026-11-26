import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/data/repositories/learning_growth_repository.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/domain/entities/learning_growth_evidence.dart';
import 'package:andril_mobile/features/learning/growth_mentorship/domain/repositories/i_learning_growth_repository.dart';

void main() {
  group('LearningGrowthRepository - Fail-Closed (Disconnected)', () {
    late LearningGrowthRepository repository;

    setUp(() {
      repository = const LearningGrowthRepository(isBackendActivated: false);
    });

    test(
        'getGrowthSummary returns serviceUnavailable when backend is deactivated',
        () async {
      final result = await repository.getGrowthSummary();
      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningGrowthFailureType.serviceUnavailable);
      expect(result.errorMessage, LearningGrowthEvidence.disconnectedNotice);
      expect(result.data, isNull);
    });

    test(
        'getEvidenceList returns serviceUnavailable when backend is deactivated',
        () async {
      final result = await repository.getEvidenceList();
      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningGrowthFailureType.serviceUnavailable);
      expect(result.errorMessage, LearningGrowthEvidence.disconnectedNotice);
    });

    test(
        'getEvidenceById returns serviceUnavailable when backend is deactivated',
        () async {
      final result = await repository.getEvidenceById('ev_123');
      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningGrowthFailureType.serviceUnavailable);
      expect(result.errorMessage, LearningGrowthEvidence.disconnectedNotice);
    });

    test(
        'getTrackedSkills returns serviceUnavailable when backend is deactivated',
        () async {
      final result = await repository.getTrackedSkills();
      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningGrowthFailureType.serviceUnavailable);
      expect(result.errorMessage, LearningGrowthEvidence.disconnectedNotice);
    });

    test(
        'recordSelfReportedEvidence returns serviceUnavailable when deactivated',
        () async {
      final result = await repository.recordSelfReportedEvidence(
        title: 'Title',
        description: 'Desc',
      );
      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningGrowthFailureType.serviceUnavailable);
      expect(result.errorMessage, LearningGrowthEvidence.disconnectedNotice);
    });
  });

  group('LearningGrowthRepository - Activated Validation', () {
    late LearningGrowthRepository repository;

    setUp(() {
      repository = const LearningGrowthRepository(isBackendActivated: true);
    });

    test('getGrowthSummary succeeds with default summary', () async {
      final result = await repository.getGrowthSummary();
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.totalEvidenceCount, 0);
    });

    test('getEvidenceById rejects empty id with validation error', () async {
      final result = await repository.getEvidenceById('   ');
      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningGrowthFailureType.validationError);
      expect(result.errorMessage, contains('cannot be empty'));
    });

    test('getEvidenceById returns notFound for non-existent evidence',
        () async {
      final result = await repository.getEvidenceById('missing_id');
      expect(result.isFailure, isTrue);
      expect(result.failureType, LearningGrowthFailureType.notFound);
    });

    test('recordSelfReportedEvidence rejects blank title or description',
        () async {
      final result1 = await repository.recordSelfReportedEvidence(
        title: '   ',
        description: 'Valid description',
      );
      expect(result1.isFailure, isTrue);
      expect(result1.failureType, LearningGrowthFailureType.validationError);

      final result2 = await repository.recordSelfReportedEvidence(
        title: 'Valid title',
        description: '   ',
      );
      expect(result2.isFailure, isTrue);
      expect(result2.failureType, LearningGrowthFailureType.validationError);
    });

    test('recordSelfReportedEvidence succeeds with valid inputs', () async {
      final result = await repository.recordSelfReportedEvidence(
        title: 'Architecture Refactor',
        description: 'Applied Clean Architecture in Learning module',
        skillIds: ['flutter', 'clean_arch'],
        skillNames: ['Flutter', 'Clean Architecture'],
        sourceReference: 'Personal Project',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      final ev = result.data!;
      expect(ev.title, 'Architecture Refactor');
      expect(ev.description, 'Applied Clean Architecture in Learning module');
      expect(ev.kind, LearningEvidenceKind.selfReported);
      expect(ev.isPrivate, isTrue);
      expect(ev.module, 'learning');
      expect(ev.skillIds, ['flutter', 'clean_arch']);
      expect(ev.sourceReference, 'Personal Project');
    });
  });
}
