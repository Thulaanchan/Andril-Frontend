import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/learning/discovery/domain/entities/learning_partner_candidate.dart';
import 'package:andril_mobile/features/learning/discovery/domain/entities/learning_partner_filters.dart';
import 'package:andril_mobile/features/learning/discovery/domain/entities/learning_partner_sort.dart';
import 'package:andril_mobile/features/learning/discovery/domain/repositories/i_learning_discovery_repository.dart';
import 'package:andril_mobile/features/learning/discovery/presentation/viewmodels/learning_partner_explorer_viewmodel.dart';

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

class FakeLearningDiscoveryRepository implements ILearningDiscoveryRepository {
  LearningDiscoveryResult<List<LearningPartnerCandidate>> result =
      const LearningDiscoveryResult.success(<LearningPartnerCandidate>[]);
  Completer<void>? delayCompleter;

  @override
  Future<LearningDiscoveryResult<List<LearningPartnerCandidate>>>
      getCandidates({
    LearningPartnerFilters? filters,
    int offset = 0,
    int limit = 20,
  }) async {
    if (delayCompleter != null) {
      await delayCompleter!.future;
    }
    return result;
  }
}

List<LearningPartnerCandidate> _createSampleCandidates() {
  return [
    LearningPartnerCandidate(
      id: 'cand_01',
      displayName: 'Amara Fernando',
      skillsToShare: const ['Flutter', 'Dart', 'Clean Architecture'],
      skillsToLearn: const ['Figma', 'UI/UX Design'],
      learningGoals: const ['Master state management'],
      proficiencyLevel: 'Advanced',
      languages: const ['English', 'Tamil'],
      availability: 'Flexible (Any time)',
      isActive: true,
    ),
    LearningPartnerCandidate(
      id: 'cand_02',
      displayName: 'Bawantha Silva',
      skillsToShare: const ['Python', 'FastAPI'],
      skillsToLearn: const ['Flutter', 'Mobile Prototyping'],
      learningGoals: const ['Build production apps'],
      proficiencyLevel: 'Intermediate',
      languages: const ['English', 'Tamil', 'Tanglish'],
      availability: 'Evening (6 PM – 10 PM)',
      isActive: true,
    ),
    LearningPartnerCandidate(
      id: 'cand_03',
      displayName: 'Chathura Perera',
      skillsToShare: const ['Figma', 'UI/UX Design'],
      skillsToLearn: const ['Dart', 'Web Development'],
      learningGoals: const ['Career transition'],
      proficiencyLevel: 'Beginner',
      languages: const ['English'],
      availability: 'Morning (6 AM – 12 PM)',
      isActive: true,
    ),
    LearningPartnerCandidate(
      id: 'cand_04',
      displayName: 'Dinuka Senanayake',
      skillsToShare: const ['Data Science', 'Python', 'SQL', 'Pandas'],
      skillsToLearn: const ['Flutter'],
      learningGoals: const ['Learn Clean Architecture'],
      proficiencyLevel: 'Advanced',
      languages: const ['English'],
      availability: 'Flexible (Any time)',
      isActive: true,
    ),
  ];
}

void main() {
  group('LearningPartnerExplorerViewModel State & Security Tests', () {
    late FakeLearningDiscoveryRepository fakeRepository;
    late FakeSessionController fakeSession;

    setUp(() {
      fakeRepository = FakeLearningDiscoveryRepository();
      fakeSession = FakeSessionController(phase: SessionPhase.signedIn);
    });

    test('access denied when sessionController is null', () async {
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: null,
        isLearningActivated: true,
      );

      await vm.initialize();

      expect(vm.status, equals(LearningPartnerExplorerStatus.accessDenied));
      expect(vm.isAccessDenied, isTrue);
      expect(vm.candidates, isEmpty);
      expect(vm.errorMessage,
          contains('Authentication and activated Learning profile required'));
    });

    test('access denied when sessionPhase is signedOut', () async {
      fakeSession.setPhase(SessionPhase.signedOut);
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      await vm.initialize();

      expect(vm.status, equals(LearningPartnerExplorerStatus.accessDenied));
      expect(vm.isAccessDenied, isTrue);
    });

    test('access denied when Learning profile is not activated', () async {
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: false,
      );

      await vm.initialize();

      expect(vm.status, equals(LearningPartnerExplorerStatus.accessDenied));
      expect(vm.isAccessDenied, isTrue);
    });

    test(
        'initializes successfully with authorized session and populated repository',
        () async {
      final sample = _createSampleCandidates();
      fakeRepository.result = LearningDiscoveryResult.success(sample);

      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      await vm.initialize();

      expect(vm.status, equals(LearningPartnerExplorerStatus.ready));
      expect(vm.isReady, isTrue);
      expect(vm.totalCount, equals(4));
      expect(vm.filteredCount, equals(4));
      expect(vm.candidates.length, equals(4));
    });

    test('handles serviceUnavailable repository response', () async {
      fakeRepository.result = const LearningDiscoveryResult.failure(
        errorMessage:
            'Remote discovery backend contract pending in OpenAPI v1.',
        failureType: LearningDiscoveryFailureType.serviceUnavailable,
      );

      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      await vm.initialize();

      expect(
          vm.status, equals(LearningPartnerExplorerStatus.unavailableService));
      expect(vm.isServiceUnavailable, isTrue);
      expect(vm.errorMessage,
          contains('Remote discovery backend contract pending'));
      expect(vm.candidates, isEmpty);
    });

    test('handles unauthorized repository response', () async {
      fakeRepository.result = const LearningDiscoveryResult.failure(
        errorMessage: 'Session expired or unverified.',
        failureType: LearningDiscoveryFailureType.unauthorized,
      );

      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      await vm.initialize();

      expect(vm.status, equals(LearningPartnerExplorerStatus.accessDenied));
      expect(vm.isAccessDenied, isTrue);
    });

    test('handles unexpected error repository response', () async {
      fakeRepository.result = const LearningDiscoveryResult.failure(
        errorMessage: 'Network timeout.',
        failureType: LearningDiscoveryFailureType.networkError,
      );

      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      await vm.initialize();

      expect(vm.status, equals(LearningPartnerExplorerStatus.error));
      expect(vm.errorMessage, equals('Network timeout.'));
    });

    test(
        'filters candidates by search text query across displayName, skills, and goals',
        () async {
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: _createSampleCandidates(),
      );

      await vm.initialize();
      expect(vm.filteredCount, equals(4));

      // Search by name
      vm.setSearchQuery('Amara');
      expect(vm.filteredCount, equals(1));
      expect(vm.candidates.first.displayName, equals('Amara Fernando'));

      // Search by offered skill
      vm.setSearchQuery('FastAPI');
      expect(vm.filteredCount, equals(1));
      expect(vm.candidates.first.displayName, equals('Bawantha Silva'));

      // Search by wanted skill
      vm.setSearchQuery('Web Development');
      expect(vm.filteredCount, equals(1));
      expect(vm.candidates.first.displayName, equals('Chathura Perera'));

      // Search by goal
      vm.setSearchQuery('Clean Architecture');
      // Matches Amara (skill) and Dinuka (goal)
      expect(vm.filteredCount, equals(2));

      // Clear search
      vm.setSearchQuery('');
      expect(vm.filteredCount, equals(4));
    });

    test(
        'filters candidates by categorical criteria (proficiency, language, availability, skill, goal)',
        () async {
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: _createSampleCandidates(),
      );

      await vm.initialize();

      // Proficiency: Beginner
      vm.applyFilters(
          LearningPartnerFilters(selectedProficiencies: const ['Beginner']));
      expect(vm.filteredCount, equals(1));
      expect(vm.candidates.first.displayName, equals('Chathura Perera'));

      // Language: Tanglish
      vm.applyFilters(
          LearningPartnerFilters(selectedLanguages: const ['Tanglish']));
      expect(vm.filteredCount, equals(1));
      expect(vm.candidates.first.displayName, equals('Bawantha Silva'));

      // Availability: Morning
      vm.applyFilters(LearningPartnerFilters(
          selectedAvailabilities: const ['Morning (6 AM – 12 PM)']));
      expect(vm.filteredCount, equals(1));
      expect(vm.candidates.first.displayName, equals('Chathura Perera'));

      // Skill: Flutter
      vm.applyFilters(
          LearningPartnerFilters(selectedSkills: const ['Flutter']));
      // Amara (shares Flutter), Bawantha (learns Flutter), Dinuka (learns Flutter)
      expect(vm.filteredCount, equals(3));

      // Goal: Career transition
      vm.applyFilters(
          LearningPartnerFilters(selectedGoals: const ['Career transition']));
      expect(vm.filteredCount, equals(1));
      expect(vm.candidates.first.displayName, equals('Chathura Perera'));
    });

    test('yields empty state when search or filters match zero candidates',
        () async {
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: _createSampleCandidates(),
      );

      await vm.initialize();

      vm.setSearchQuery('NonExistentTechnology123');
      expect(vm.status, equals(LearningPartnerExplorerStatus.empty));
      expect(vm.isEmpty, isTrue);
      expect(vm.filteredCount, equals(0));

      // Resetting filters restores ready state
      vm.resetFilters();
      expect(vm.status, equals(LearningPartnerExplorerStatus.ready));
      expect(vm.filteredCount, equals(4));
    });

    test('removeFilter removes single categorical filter item', () async {
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: _createSampleCandidates(),
      );

      await vm.initialize();

      vm.applyFilters(LearningPartnerFilters(
        selectedSkills: const ['Flutter'],
        selectedProficiencies: const ['Beginner'],
      ));
      // Flutter + Beginner = 0 matching (Chathura is Beginner but does not have Flutter)
      expect(vm.filteredCount, equals(0));

      // Remove proficiency filter
      vm.removeFilter(category: 'Proficiency', value: 'Beginner');
      expect(vm.filters.selectedProficiencies, isEmpty);
      expect(vm.filteredCount, equals(3));
    });

    test('sorts candidates according to selected sort option', () async {
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: _createSampleCandidates(),
      );

      await vm.initialize();

      // Alphabetical A to Z
      vm.setSortOption(LearningPartnerSort.nameAsc);
      expect(vm.candidates[0].displayName, equals('Amara Fernando'));
      expect(vm.candidates[1].displayName, equals('Bawantha Silva'));
      expect(vm.candidates[2].displayName, equals('Chathura Perera'));
      expect(vm.candidates[3].displayName, equals('Dinuka Senanayake'));

      // Alphabetical Z to A
      vm.setSortOption(LearningPartnerSort.nameDesc);
      expect(vm.candidates[0].displayName, equals('Dinuka Senanayake'));
      expect(vm.candidates[1].displayName, equals('Chathura Perera'));
      expect(vm.candidates[2].displayName, equals('Bawantha Silva'));
      expect(vm.candidates[3].displayName, equals('Amara Fernando'));

      // Most skills offered
      vm.setSortOption(LearningPartnerSort.skillsCount);
      expect(vm.candidates[0].displayName,
          equals('Dinuka Senanayake')); // 4 skills
      expect(
          vm.candidates[1].displayName, equals('Amara Fernando')); // 3 skills
    });

    test(
        'security boundary: excludes inactive, non-learning, and blocked candidates',
        () async {
      final mixedCandidates = [
        LearningPartnerCandidate(
          id: 'cand_active',
          displayName: 'Active Learner',
          isActive: true,
        ),
        LearningPartnerCandidate(
          id: 'cand_inactive',
          displayName: 'Inactive Learner',
          isActive: false, // server-side candidate eligibility failed
        ),
        LearningPartnerCandidate(
          id: 'cand_blocked',
          displayName: 'Blocked Learner',
          isActive: true,
        ),
      ];

      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        blockedProfileIds: const ['cand_blocked'],
        initialCandidates: mixedCandidates,
      );

      await vm.initialize();

      expect(vm.totalCount, equals(1));
      expect(vm.filteredCount, equals(1));
      expect(vm.candidates.first.id, equals('cand_active'));
    });

    test('clears private state on session revocation and identity changes',
        () async {
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: _createSampleCandidates(),
      );

      await vm.initialize();
      expect(vm.candidates.length, equals(4));

      // Trigger private state clearer (e.g. SessionController logout)
      fakeSession.triggerPrivateStateClearers();

      expect(vm.status, equals(LearningPartnerExplorerStatus.accessDenied));
      expect(vm.candidates, isEmpty);
      expect(vm.totalCount, equals(0));
      expect(vm.filters.searchQuery, isEmpty);
    });

    test('clears private state when session phase transitions to signedOut',
        () async {
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: _createSampleCandidates(),
      );

      await vm.initialize();
      expect(vm.isReady, isTrue);

      fakeSession.setPhase(SessionPhase.signedOut);

      expect(vm.status, equals(LearningPartnerExplorerStatus.accessDenied));
      expect(vm.candidates, isEmpty);
    });

    test(
        'rejects stale asynchronous responses arriving after request epoch advance',
        () async {
      final firstCompleter = Completer<void>();
      final secondCompleter = Completer<void>();

      fakeRepository.delayCompleter = firstCompleter;

      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
      );

      // Start first async operation
      final firstInit = vm.initialize();
      expect(vm.isLoading, isTrue);

      // Trigger second operation with force: true and a different completer
      fakeRepository.delayCompleter = secondCompleter;
      fakeRepository.result =
          LearningDiscoveryResult.success(_createSampleCandidates());
      final secondInit = vm.initialize(force: true);

      // Complete second request first
      secondCompleter.complete();
      await secondInit;
      expect(vm.status, equals(LearningPartnerExplorerStatus.ready));
      expect(vm.candidates.length, equals(4));

      // Now complete the stale first request with empty result
      fakeRepository.result =
          const LearningDiscoveryResult.success(<LearningPartnerCandidate>[]);
      firstCompleter.complete();
      await firstInit;

      // Stale response must be rejected: candidate count remains 4
      expect(vm.candidates.length, equals(4));
    });

    test('selectCandidateForProfile selects candidate and notifies listeners',
        () async {
      final sample = _createSampleCandidates();
      final vm = LearningPartnerExplorerViewModel(
        repository: fakeRepository,
        sessionController: fakeSession,
        isLearningActivated: true,
        initialCandidates: sample,
      );

      await vm.initialize();

      expect(vm.selectedCandidateForProfile, isNull);

      vm.selectCandidateForProfile(sample.first);
      expect(vm.selectedCandidateForProfile, equals(sample.first));

      vm.selectCandidateForProfile(null);
      expect(vm.selectedCandidateForProfile, isNull);
    });
  });
}
