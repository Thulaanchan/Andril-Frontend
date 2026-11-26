import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../group_contracts/social_zone.dart';
import '../group_contracts/social_zone_repository.dart';

/// State enum for Social Zones discovery presentation.
enum SocialZonesStatus {
  initial,
  loading,
  ready,
  empty,
  error,
  accessDenied,
  serviceUnavailable,
}

/// ViewModel managing state and operations for Social Zone discovery and membership actions.
///
/// Follows M5 Social Groups Governance:
/// - Enforces adult eligibility and active Social opt-in.
/// - Prevents concurrent in-flight requests and stale response overwrites.
/// - Unregisters and clears in-memory state on session reset or account switch.
/// - Respects dormant backend boundaries (displays graceful unavailable status).
class SocialZonesViewModel extends ChangeNotifier {
  final ISocialZoneRepository _repository;
  final SessionController? _sessionController;
  final bool _isSocialOptedIn;

  SocialZonesStatus _status = SocialZonesStatus.initial;
  List<SocialZone> _zones = const [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  SocialZone? _selectedZone;
  String? _errorMessage;
  bool _isActionInProgress = false;
  String? _actionFeedbackMessage;

  VoidCallback? _unregisterSessionClearer;
  int _activeRequestId = 0;

  SocialZonesViewModel({
    required ISocialZoneRepository repository,
    SessionController? sessionController,
    bool isSocialOptedIn = false,
  })  : _repository = repository,
        _sessionController = sessionController,
        _isSocialOptedIn = isSocialOptedIn {
    _unregisterSessionClearer = _sessionController?.registerPrivateStateClearer(_clearPrivateState);
  }

  SocialZonesStatus get status => _status;
  List<SocialZone> get zones => _zones;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  SocialZone? get selectedZone => _selectedZone;
  String? get errorMessage => _errorMessage;
  bool get isActionInProgress => _isActionInProgress;
  String? get actionFeedbackMessage => _actionFeedbackMessage;

  bool get isLoading => _status == SocialZonesStatus.loading;
  bool get isReady => _status == SocialZonesStatus.ready;
  bool get isEmpty => _status == SocialZonesStatus.empty;
  bool get isError => _status == SocialZonesStatus.error;
  bool get isAccessDenied => _status == SocialZonesStatus.accessDenied;
  bool get isServiceUnavailable => _status == SocialZonesStatus.serviceUnavailable;

  bool get isAuthorized =>
      _sessionController?.phase == SessionPhase.signedIn && _isSocialOptedIn;

  Future<void> loadZones({bool refresh = false}) async {
    if (_isActionInProgress && !refresh) return;

    if (!isAuthorized) {
      _status = SocialZonesStatus.accessDenied;
      _errorMessage = 'Active Social opt-in and adult eligibility verification are required to view Zones.';
      notifyListeners();
      return;
    }

    _status = SocialZonesStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final requestId = ++_activeRequestId;
    final result = await _repository.getZones(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      query: _searchQuery.isEmpty ? null : _searchQuery,
    );

    if (requestId != _activeRequestId) return;

    switch (result) {
      case ZoneSuccess(:final data):
        _zones = data;
        _status = data.isEmpty ? SocialZonesStatus.empty : SocialZonesStatus.ready;
        _errorMessage = null;
      case ZoneFailureResult(:final failure):
        _handleFailure(failure);
    }

    notifyListeners();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    loadZones();
  }

  void setSearchQuery(String query) {
    final trimmed = query.trim();
    if (_searchQuery == trimmed) return;
    _searchQuery = trimmed;
    loadZones();
  }

  void selectZone(SocialZone? zone) {
    _selectedZone = zone;
    _actionFeedbackMessage = null;
    notifyListeners();
  }

  Future<bool> joinZone(String zoneId) async {
    if (!isAuthorized) {
      _errorMessage = 'Caller is not authorized to join Social Zones.';
      notifyListeners();
      return false;
    }

    _isActionInProgress = true;
    _actionFeedbackMessage = null;
    notifyListeners();

    final result = await _repository.joinZone(zoneId);
    _isActionInProgress = false;

    switch (result) {
      case ZoneSuccess(:final data):
        _selectedZone = data;
        _updateZoneInList(data);
        _actionFeedbackMessage = 'Successfully joined ${data.name}!';
        notifyListeners();
        return true;
      case ZoneFailureResult(:final failure):
        _errorMessage = failure.message;
        _actionFeedbackMessage = failure.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> leaveZone(String zoneId) async {
    if (!isAuthorized) {
      _errorMessage = 'Caller is not authorized to modify Social Zone membership.';
      notifyListeners();
      return false;
    }

    _isActionInProgress = true;
    _actionFeedbackMessage = null;
    notifyListeners();

    final result = await _repository.leaveZone(zoneId);
    _isActionInProgress = false;

    switch (result) {
      case ZoneSuccess(:final data):
        _selectedZone = data;
        _updateZoneInList(data);
        _actionFeedbackMessage = 'You have left ${data.name}.';
        notifyListeners();
        return true;
      case ZoneFailureResult(:final failure):
        _errorMessage = failure.message;
        _actionFeedbackMessage = failure.message;
        notifyListeners();
        return false;
    }
  }

  void _updateZoneInList(SocialZone updated) {
    final idx = _zones.indexWhere((z) => z.id == updated.id);
    if (idx != -1) {
      final updatedList = List<SocialZone>.from(_zones);
      updatedList[idx] = updated;
      _zones = List.unmodifiable(updatedList);
    }
  }

  void _handleFailure(ZoneFailure failure) {
    switch (failure.type) {
      case ZoneFailureType.authorizationDenied:
      case ZoneFailureType.sessionExpired:
        _status = SocialZonesStatus.accessDenied;
      case ZoneFailureType.serviceUnavailable:
        _status = SocialZonesStatus.serviceUnavailable;
      case ZoneFailureType.notFound:
      case ZoneFailureType.validationFailure:
      case ZoneFailureType.dependencyFailure:
      case ZoneFailureType.unknown:
        _status = SocialZonesStatus.error;
    }
    _errorMessage = failure.message;
    _zones = const [];
  }

  void _clearPrivateState() {
    _status = SocialZonesStatus.initial;
    _zones = const [];
    _selectedZone = null;
    _errorMessage = null;
    _actionFeedbackMessage = null;
    _isActionInProgress = false;
    _selectedCategory = 'All';
    _searchQuery = '';
    _activeRequestId++;
    notifyListeners();
  }

  @override
  void dispose() {
    _unregisterSessionClearer?.call();
    _unregisterSessionClearer = null;
    super.dispose();
  }
}
