import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/dependencies/registrations/social/social_dependencies.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'package:andril_mobile/features/social/home/viewmodels/social_navigation_coordinator.dart';
import 'package:andril_mobile/features/social/likes_matches/domain/authorization/social_access_boundary.dart';

class _FakeSessionController extends ChangeNotifier implements SessionController {
  SessionPhase _phase = SessionPhase.signedIn;
  String? _subject = 'test-subject-1';
  final Set<VoidCallback> _clearers = {};

  @override
  SessionPhase get phase => _phase;

  set phase(SessionPhase value) {
    _phase = value;
    notifyListeners();
  }

  @override
  String? get subject => _subject;

  set subject(String? value) {
    _subject = value;
    notifyListeners();
  }

  @override
  VoidCallback registerPrivateStateClearer(VoidCallback clearer) {
    _clearers.add(clearer);
    return () => _clearers.remove(clearer);
  }

  void triggerPrivateStateClearers() {
    for (final clearer in List<VoidCallback>.from(_clearers)) {
      clearer();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeSessionController sessionController;

  setUp(() {
    sessionController = _FakeSessionController();
    sessionController.phase = SessionPhase.signedIn;
    sessionController.subject = 'user-test-uuid';
  });

  group('SocialDependenciesScope Session & Authorization Lifecycle', () {
    test('missing session fails closed and prohibits zone repository creation', () {
      final scope = SocialDependenciesScope(
        sessionController: null,
        isSocialOptedIn: true,
      );

      expect(scope.isSocialAuthorized, isFalse);
      expect(() => scope.zoneRepository, throwsA(isA<StateError>()));
      expect(scope.isDisposed, isFalse);
    });

    test('unauthenticated session fails closed even with opt-in flag', () {
      sessionController.phase = SessionPhase.signedOut;
      final scope = SocialDependenciesScope(
        sessionController: sessionController,
        isSocialOptedIn: true,
      );

      expect(scope.isSocialAuthorized, isFalse);
    });

    test('signed-in session without authoritative access evidence fails closed', () {
      sessionController.phase = SessionPhase.signedIn;
      final scope = SocialDependenciesScope(
        sessionController: sessionController,
        isSocialOptedIn: true, // Local boolean alone is insufficient
        accessEvidence: null,
      );

      expect(scope.isSocialAuthorized, isFalse);
    });

    test('authoritative adult opt-in evidence grants social access', () {
      final evidence = SocialAccessEvidence.authorized(
        userId: 'user-test-uuid',
      );

      final scope = SocialDependenciesScope(
        sessionController: sessionController,
        isSocialOptedIn: true,
        accessEvidence: evidence,
      );

      expect(scope.isSocialAuthorized, isTrue);
      expect(scope.accessBoundary, isNotNull);
      expect(scope.communicationBoundary, isNotNull);
    });

    test('revoked evidence fails closed', () {
      final evidence = SocialAccessEvidence.revoked(
        userId: 'user-test-uuid',
      );

      final scope = SocialDependenciesScope(
        sessionController: sessionController,
        isSocialOptedIn: true,
        accessEvidence: evidence,
      );

      expect(scope.isSocialAuthorized, isFalse);
    });

    test('underage or unverified evidence fails closed', () {
      final evidence = SocialAccessEvidence.unverified(
        userId: 'user-test-uuid',
      );

      final scope = SocialDependenciesScope(
        sessionController: sessionController,
        isSocialOptedIn: true,
        accessEvidence: evidence,
      );

      expect(scope.isSocialAuthorized, isFalse);
    });
  });

  group('SocialDependenciesScope Invalidation & Disposal Boundaries', () {
    test('session invalidation triggers automatic scope disposal', () {
      final scope = SocialDependenciesScope(
        sessionController: sessionController,
      );

      expect(scope.isDisposed, isFalse);
      sessionController.triggerPrivateStateClearers();
      expect(scope.isDisposed, isTrue);
    });

    test('disposal is idempotent and safe against multiple invocations', () {
      final scope = SocialDependenciesScope(
        sessionController: sessionController,
      );

      scope.dispose();
      expect(scope.isDisposed, isTrue);
      // Repeated invocation does not throw or corrupt state
      expect(() => scope.dispose(), returnsNormally);
      expect(scope.isDisposed, isTrue);
    });

    test('accessing dependencies after disposal throws StateError', () {
      final scope = SocialDependenciesScope(
        sessionController: sessionController,
      );

      scope.dispose();

      expect(() => scope.isSocialAuthorized, throwsA(isA<StateError>()));
      expect(() => scope.zonesViewModel, throwsA(isA<StateError>()));
      expect(() => scope.zoneManagementViewModel, throwsA(isA<StateError>()));
      expect(() => scope.zoneRepository, throwsA(isA<StateError>()));
      expect(() => scope.createHomeViewModel(), throwsA(isA<StateError>()));
      expect(() => scope.accessBoundary, throwsA(isA<StateError>()));
      expect(() => scope.communicationBoundary, throwsA(isA<StateError>()));
      expect(() => scope.createNavigationCoordinator(), throwsA(isA<StateError>()));
    });
  });

  group('SocialDependenciesScope Navigation Coordinator Scoping (Tasks 123 & 124)', () {
    test('createNavigationCoordinator provides scoped singleton with matching access evidence', () {
      final evidence = SocialAccessEvidence.authorized(userId: 'user-test-uuid');
      final scope = SocialDependenciesScope(
        sessionController: sessionController,
        isSocialOptedIn: true,
        accessEvidence: evidence,
      );

      final coordinator1 = scope.createNavigationCoordinator();
      final coordinator2 = scope.createNavigationCoordinator();

      expect(identical(coordinator1, coordinator2), isTrue);
      expect(coordinator1.isAuthorized, isTrue);
      expect(coordinator1.accessEvidence?.userId, 'user-test-uuid');
      expect(coordinator1.currentDestination, SocialDestination.home);

      scope.dispose();
      expect(scope.isDisposed, isTrue);
      expect(() => scope.createNavigationCoordinator(), throwsA(isA<StateError>()));
    });
  });

  group('SocialDependenciesScope Private State Isolation', () {
    test('distinct scopes maintain isolated instances without global singleton leakage', () {
      final scopeA = SocialDependenciesScope(
        sessionController: sessionController,
      );
      final scopeB = SocialDependenciesScope(
        sessionController: sessionController,
      );

      expect(identical(scopeA.zonesViewModel, scopeB.zonesViewModel), isFalse);
      expect(identical(scopeA.zoneManagementViewModel, scopeB.zoneManagementViewModel), isFalse);
      expect(identical(scopeA.zoneRepository, scopeB.zoneRepository), isFalse);

      scopeA.dispose();
      expect(scopeA.isDisposed, isTrue);
      expect(scopeB.isDisposed, isFalse);
      scopeB.dispose();
    });
  });
}
