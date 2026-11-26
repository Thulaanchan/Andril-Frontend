import 'package:flutter/foundation.dart';
import 'package:andril_mobile/core/security/session/session_controller.dart';
import '../group_contracts/social_zone_management.dart';

/// Presentation state for Zone creation and management operations.
enum ZoneManagementStatus {
  initial,
  validating,
  submitting,
  success,
  failure,
  serviceUnavailable,
  accessDenied,
}

/// ViewModel managing Zone creation, editing, member moderation, and governance.
///
/// Follows M5 Social Groups Governance:
/// - Enforces adult eligibility and active Social opt-in.
/// - Requires authoritative [ZonePermissionEvidence] for privileged actions (edit, moderate, role management).
/// - Fails closed and reports explicit [serviceUnavailable] for dormant backend mutations.
/// - Protects against duplicate concurrent submissions.
/// - Unregisters and clears all private drafts upon session termination.
class SocialZoneManagementViewModel extends ChangeNotifier {
  final SessionController? _sessionController;
  final bool _isSocialOptedIn;

  ZoneManagementStatus _status = ZoneManagementStatus.initial;
  ZoneManagementDraft _draft = const ZoneManagementDraft.empty();
  ZonePermissionEvidence? _permissionEvidence;
  String? _errorMessage;
  String? _successMessage;
  bool _isSubmitting = false;

  VoidCallback? _unregisterSessionClearer;

  SocialZoneManagementViewModel({
    SessionController? sessionController,
    bool isSocialOptedIn = false,
    ZonePermissionEvidence? initialEvidence,
  })  : _sessionController = sessionController,
        _isSocialOptedIn = isSocialOptedIn,
        _permissionEvidence = initialEvidence {
    _unregisterSessionClearer = _sessionController?.registerPrivateStateClearer(_clearPrivateState);
  }

  ZoneManagementStatus get status => _status;
  ZoneManagementDraft get draft => _draft;
  ZonePermissionEvidence? get permissionEvidence => _permissionEvidence;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isSubmitting => _isSubmitting;

  bool get isAuthorized =>
      _sessionController?.phase == SessionPhase.signedIn && _isSocialOptedIn;

  void setPermissionEvidence(ZonePermissionEvidence evidence) {
    _permissionEvidence = evidence;
    notifyListeners();
  }

  void updateDraft(ZoneManagementDraft newDraft) {
    _draft = newDraft;
    _errorMessage = null;
    notifyListeners();
  }

  void resetDraft() {
    _draft = const ZoneManagementDraft.empty();
    _errorMessage = null;
    _successMessage = null;
    _status = ZoneManagementStatus.initial;
    notifyListeners();
  }

  /// Attempts to submit a new Social Zone creation request.
  Future<bool> createZone() async {
    if (_isSubmitting) return false;

    if (!isAuthorized) {
      _status = ZoneManagementStatus.accessDenied;
      _errorMessage = 'Adult eligibility and Social opt-in are required to create a Zone.';
      notifyListeners();
      return false;
    }

    final validationError = _draft.validate();
    if (validationError != null) {
      _status = ZoneManagementStatus.failure;
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _status = ZoneManagementStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    // Backend readiness: GroupMembershipController is dormant ([NonController]).
    // Must return explicit serviceUnavailable rather than manufacturing fake success.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _isSubmitting = false;
    _status = ZoneManagementStatus.serviceUnavailable;
    _errorMessage = 'Zone creation is temporarily deferred pending backend service activation.';
    notifyListeners();
    return false;
  }

  /// Attempts to update an existing Zone's details.
  Future<bool> updateZone(String zoneId) async {
    if (_isSubmitting) return false;

    if (!isAuthorized) {
      _status = ZoneManagementStatus.accessDenied;
      _errorMessage = 'Active session required to edit Zone details.';
      notifyListeners();
      return false;
    }

    if (_permissionEvidence == null || !_permissionEvidence!.canManageZone) {
      _status = ZoneManagementStatus.accessDenied;
      _errorMessage = 'Caller lacks authoritative host permission to edit this Zone.';
      notifyListeners();
      return false;
    }

    final validationError = _draft.validate();
    if (validationError != null) {
      _status = ZoneManagementStatus.failure;
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _status = ZoneManagementStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 50));
    _isSubmitting = false;
    _status = ZoneManagementStatus.serviceUnavailable;
    _errorMessage = 'Zone modification is temporarily deferred pending backend service activation.';
    notifyListeners();
    return false;
  }

  /// Moderates a pending membership join request.
  Future<bool> reviewJoinRequest(String requestId, bool approve) async {
    if (_isSubmitting) return false;

    if (!isAuthorized) {
      _errorMessage = 'Active session required to review membership requests.';
      notifyListeners();
      return false;
    }

    if (_permissionEvidence == null || !_permissionEvidence!.canModerate) {
      _status = ZoneManagementStatus.accessDenied;
      _errorMessage = 'Caller lacks moderation authority in this Zone.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 50));
    _isSubmitting = false;
    _status = ZoneManagementStatus.serviceUnavailable;
    _errorMessage = 'Membership moderation is temporarily deferred pending backend service activation.';
    notifyListeners();
    return false;
  }

  /// Updates a member's role (Host-only privilege).
  Future<bool> updateMemberRole(String memberId, ZoneRole newRole) async {
    if (_isSubmitting) return false;

    if (!isAuthorized) {
      _errorMessage = 'Active session required to manage roles.';
      notifyListeners();
      return false;
    }

    if (_permissionEvidence == null || !_permissionEvidence!.hasPermission(ZoneManagementPermission.manageRoles)) {
      _status = ZoneManagementStatus.accessDenied;
      _errorMessage = 'Only verified Zone hosts can modify member roles.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 50));
    _isSubmitting = false;
    _status = ZoneManagementStatus.serviceUnavailable;
    _errorMessage = 'Role management is temporarily deferred pending backend service activation.';
    notifyListeners();
    return false;
  }

  void _clearPrivateState() {
    _status = ZoneManagementStatus.initial;
    _draft = const ZoneManagementDraft.empty();
    _permissionEvidence = null;
    _errorMessage = null;
    _successMessage = null;
    _isSubmitting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _unregisterSessionClearer?.call();
    _unregisterSessionClearer = null;
    super.dispose();
  }
}
