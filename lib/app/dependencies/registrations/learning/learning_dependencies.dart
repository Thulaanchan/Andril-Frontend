import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/network/api_client/andril_api_client.dart';
import '../../../../core/security/session/session_controller.dart';
import '../../../../features/learning/circles/data/repositories/learning_circles_repository.dart';
import '../../../../features/learning/circles/presentation/viewmodels/learning_circles_viewmodel.dart';
import '../../../../features/learning/connections/data/repositories/learning_connections_repository.dart';
import '../../../../features/learning/connections/presentation/viewmodels/learning_connections_viewmodel.dart';
import '../../../../features/learning/discovery/data/repositories/learning_discovery_repository.dart';
import '../../../../features/learning/discovery/presentation/viewmodels/learning_partner_explorer_viewmodel.dart';
import '../../../../features/learning/growth_mentorship/data/repositories/learning_growth_repository.dart';
import '../../../../features/learning/growth_mentorship/presentation/viewmodels/learning_growth_viewmodel.dart';
import '../../../../features/learning/growth_mentorship/presentation/viewmodels/learning_mentorship_viewmodel.dart';
import '../../../../features/learning/pacts/data/repositories/learning_pacts_repository.dart';
import '../../../../features/learning/pacts/presentation/viewmodels/learning_pacts_viewmodel.dart';
import '../../../../features/learning/portfolio_maker/data/services/learning_cv_import_api_adapter.dart';
import '../../../../features/learning/portfolio_maker/data/services/portfolio_cv_import_service.dart';
import '../../../../features/learning/portfolio_maker/domain/services/i_portfolio_cv_import_service.dart';
import '../../../../features/learning/profile/data/datasources/learning_remote_data_source.dart';
import '../../../../features/learning/profile/data/repositories/learning_profile_api_repository.dart';
import '../../../../features/learning/profile/data/repositories/learning_setup_api_repository.dart';
import '../../../../features/learning/profile/domain/repositories/profile_repository.dart';
import '../../../../features/learning/profile/viewmodels/learning_onboarding_viewmodel.dart';
import '../../../router/learning_router.dart';

/// Scoped dependency container managing lifecycle and instances of Learning module services.
///
/// Under ANDRIL Fast Feature Delivery & Security Governance:
/// - Reuses approved SessionController without constructing fake fallback sessions.
/// - Connects approved API adapters (Setup, Profile, CV Import).
/// - Enforces session boundaries: automatically registers for private state clearing.
/// - Discards state and prevents post-disposal invocation on logout or session change.
/// - Disposal is idempotent.
class LearningDependenciesScope {
  final SessionController? _sessionController;
  final AndrilApiClient? _apiClient;
  final AppConfig? _appConfig;
  final bool _ownsApiClient;

  // Lazily initialized service instances
  ILearningRemoteDataSource? _remoteDataSource;
  ILearningSetupRepository? _setupRepository;
  ProfileRepository? _profileRepository;
  ILearningCvImportRemoteDataSource? _cvImportRemoteDataSource;
  IPortfolioCvImportService? _portfolioCvImportService;
  LearningAccessPolicy? _accessPolicy;

  // Lazily initialized ViewModels
  LearningCirclesViewModel? _circlesViewModel;
  LearningPactsViewModel? _pactsViewModel;
  LearningGrowthViewModel? _growthViewModel;
  LearningMentorshipViewModel? _mentorshipViewModel;
  LearningConnectionsViewModel? _connectionsViewModel;
  LearningPartnerExplorerViewModel? _discoveryViewModel;
  LearningOnboardingViewModel? _onboardingViewModel;

  VoidCallback? _unregisterSessionClearer;
  bool _isDisposed = false;

  LearningDependenciesScope({
    SessionController? sessionController,
    AndrilApiClient? apiClient,
    AppConfig? appConfig,
  })  : _sessionController = sessionController,
        _appConfig = appConfig,
        _apiClient =
            apiClient ?? _createApiClient(appConfig, sessionController),
        _ownsApiClient = apiClient == null {
    _unregisterSessionClearer =
        _sessionController?.registerPrivateStateClearer(dispose);
  }

  static AndrilApiClient? _createApiClient(
    AppConfig? config,
    SessionController? session,
  ) {
    if (session == null || !session.supportsBackend) return null;
    final resolvedConfig = config ?? _tryEnvironmentConfig();
    if (resolvedConfig == null) return null;
    try {
      return AndrilApiClient(resolvedConfig, session);
    } catch (_) {
      return null;
    }
  }

  static AppConfig? _tryEnvironmentConfig() {
    try {
      return AppConfig.fromEnvironment();
    } catch (_) {
      return null;
    }
  }

  /// Whether this scope has been permanently disposed.
  bool get isDisposed => _isDisposed;

  /// The active session controller if bound.
  SessionController? get sessionController => _sessionController;

  /// The application configuration if supplied.
  AppConfig? get appConfig => _appConfig;

  /// Remote data source for Learning setup and profile APIs.
  ILearningRemoteDataSource? get remoteDataSource {
    if (_isDisposed) return null;
    final client = _apiClient;
    if (client == null) return null;
    return _remoteDataSource ??= LearningRemoteDataSource(client);
  }

  /// Authoritative repository for learning preferences and setup revisions.
  ILearningSetupRepository? get setupRepository {
    if (_isDisposed) return null;
    final session = _sessionController;
    final remote = remoteDataSource;
    if (session == null || remote == null) return null;
    return _setupRepository ??= LearningSetupApiRepository(
      sessionController: session,
      remoteDataSource: remote,
    );
  }

  /// Authoritative repository for Learning profile projection.
  ProfileRepository? get profileRepository {
    if (_isDisposed) return null;
    final session = _sessionController;
    final remote = remoteDataSource;
    if (session == null || remote == null) return null;
    return _profileRepository ??= LearningProfileApiRepository(
      sessionController: session,
      remoteDataSource: remote,
      setupRepository: setupRepository,
    );
  }

  /// Remote data source for CV project import reviews.
  ILearningCvImportRemoteDataSource? get cvImportRemoteDataSource {
    if (_isDisposed) return null;
    final client = _apiClient;
    if (client == null) return null;
    return _cvImportRemoteDataSource ??=
        LearningCvImportRemoteDataSource(client);
  }

  /// Service for importing portfolio projects into a CV.
  IPortfolioCvImportService get portfolioCvImportService {
    if (_isDisposed) return const PortfolioCvImportService();
    return _portfolioCvImportService ??= PortfolioCvImportService(
      remoteDataSource: cvImportRemoteDataSource,
    );
  }

  /// Access policy evaluating route permissions against M2 session standing.
  LearningAccessPolicy get accessPolicy {
    if (_isDisposed) return const ProductionLearningAccessPolicy();
    return _accessPolicy ??= SessionLearningAccessPolicy(_sessionController);
  }

  /// ViewModel for Learning Circles Hub screen.
  LearningCirclesViewModel get circlesViewModel {
    if (_isDisposed) {
      return LearningCirclesViewModel(
        repository: const LearningCirclesRepository(),
      );
    }
    return _circlesViewModel ??= LearningCirclesViewModel(
      repository: const LearningCirclesRepository(),
      sessionController: _sessionController,
      isLearningActivated: _sessionController?.moduleHomeAuthorized ?? false,
    );
  }

  /// ViewModel for Learning Pacts Hub and related screens.
  LearningPactsViewModel get pactsViewModel {
    if (_isDisposed) {
      return LearningPactsViewModel(
        repository: const LearningPactsRepository(),
      );
    }
    return _pactsViewModel ??= LearningPactsViewModel(
      repository: const LearningPactsRepository(),
      sessionController: _sessionController,
      isLearningActivated: _sessionController?.moduleHomeAuthorized ?? false,
    );
  }

  /// ViewModel for Learning Growth dashboard.
  LearningGrowthViewModel get growthViewModel {
    if (_isDisposed) {
      return LearningGrowthViewModel(
        repository: const LearningGrowthRepository(),
      );
    }
    return _growthViewModel ??= LearningGrowthViewModel(
      repository: const LearningGrowthRepository(),
      sessionController: _sessionController,
      isLearningActivated: _sessionController?.moduleHomeAuthorized ?? false,
    );
  }

  /// ViewModel for Learning Mentorship Hub.
  LearningMentorshipViewModel get mentorshipViewModel {
    if (_isDisposed) {
      return LearningMentorshipViewModel(
        repository: const LearningGrowthRepository(),
      );
    }
    return _mentorshipViewModel ??= LearningMentorshipViewModel(
      repository: const LearningGrowthRepository(),
      sessionController: _sessionController,
      isLearningActivated: _sessionController?.moduleHomeAuthorized ?? false,
    );
  }

  /// ViewModel for Learning Connections screen.
  LearningConnectionsViewModel get connectionsViewModel {
    if (_isDisposed) {
      return LearningConnectionsViewModel(
        repository: const LearningConnectionsRepository(),
      );
    }
    return _connectionsViewModel ??= LearningConnectionsViewModel(
      repository: const LearningConnectionsRepository(),
      sessionController: _sessionController,
      isLearningActivated: _sessionController?.moduleHomeAuthorized ?? false,
    );
  }

  /// ViewModel for Learning Discovery screen.
  LearningPartnerExplorerViewModel get discoveryViewModel {
    if (_isDisposed) {
      return LearningPartnerExplorerViewModel(
        repository: const LearningDiscoveryRepository(),
      );
    }
    return _discoveryViewModel ??= LearningPartnerExplorerViewModel(
      repository: const LearningDiscoveryRepository(),
      sessionController: _sessionController,
      isLearningActivated: _sessionController?.moduleHomeAuthorized ?? false,
    );
  }

  /// ViewModel for Learning Onboarding flow.
  LearningOnboardingViewModel get onboardingViewModel {
    if (_isDisposed) return LearningOnboardingViewModel();
    return _onboardingViewModel ??= LearningOnboardingViewModel();
  }

  /// Disposes all owned resources and clears private in-memory state.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _unregisterSessionClearer?.call();
    _unregisterSessionClearer = null;

    if (_ownsApiClient) {
      _apiClient?.close();
    }

    _remoteDataSource = null;
    _setupRepository = null;
    _profileRepository = null;
    _cvImportRemoteDataSource = null;
    _portfolioCvImportService = null;
    _accessPolicy = null;

    _circlesViewModel?.dispose();
    _circlesViewModel = null;
    _pactsViewModel?.dispose();
    _pactsViewModel = null;
    _growthViewModel?.dispose();
    _growthViewModel = null;
    _mentorshipViewModel?.dispose();
    _mentorshipViewModel = null;
    _connectionsViewModel?.dispose();
    _connectionsViewModel = null;
    _discoveryViewModel?.dispose();
    _discoveryViewModel = null;
    _onboardingViewModel?.dispose();
    _onboardingViewModel = null;
  }
}
