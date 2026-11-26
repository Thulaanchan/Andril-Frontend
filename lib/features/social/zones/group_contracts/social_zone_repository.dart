import 'package:andril_mobile/core/security/session/session_controller.dart';
import 'social_zone.dart';

/// Categorized failure reasons for Social Zone operations.
enum ZoneFailureType {
  /// Caller is unauthenticated, underage, or not opted-in to Social.
  authorizationDenied,

  /// Zone was not found or has been archived.
  notFound,

  /// Input failed schema or validation rules.
  validationFailure,

  /// Backend service or database dependency unavailable.
  dependencyFailure,

  /// Service is currently dormant in production (e.g. GroupMembershipController deferred).
  serviceUnavailable,

  /// User session expired or context changed.
  sessionExpired,

  /// Unclassified or unexpected failure.
  unknown,
}

/// Structured diagnostic outcome for Social Zone operations.
class ZoneFailure {
  final ZoneFailureType type;
  final String message;

  const ZoneFailure({
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'ZoneFailure(type: $type, message: $message)';
}

/// Discriminated union outcome for Social Zone operations.
sealed class ZoneResult<T> {
  const ZoneResult();

  const factory ZoneResult.success(T data) = ZoneSuccess<T>;
  const factory ZoneResult.failure(ZoneFailure failure) = ZoneFailureResult<T>;

  bool get isSuccess => this is ZoneSuccess<T>;
  bool get isFailure => this is ZoneFailureResult<T>;

  T? get dataOrNull => switch (this) {
        ZoneSuccess(:final data) => data,
        ZoneFailureResult() => null,
      };

  ZoneFailure? get failureOrNull => switch (this) {
        ZoneSuccess() => null,
        ZoneFailureResult(:final failure) => failure,
      };
}

final class ZoneSuccess<T> extends ZoneResult<T> {
  final T data;
  const ZoneSuccess(this.data);
}

final class ZoneFailureResult<T> extends ZoneResult<T> {
  final ZoneFailure failure;
  const ZoneFailureResult(this.failure);
}

/// Abstract contract for Social Zone discovery and membership operations.
abstract class ISocialZoneRepository {
  /// Fetches approved Social Zones, optionally filtered by category or search query.
  Future<ZoneResult<List<SocialZone>>> getZones({
    String? category,
    String? query,
  });

  /// Fetches detailed information for a specific Social Zone by [zoneId].
  Future<ZoneResult<SocialZone>> getZoneDetails(String zoneId);

  /// Requests to join a Social Zone. Returns explicit unavailable for dormant backend services.
  Future<ZoneResult<SocialZone>> joinZone(String zoneId);

  /// Requests to leave a Social Zone. Returns explicit unavailable for dormant backend services.
  Future<ZoneResult<SocialZone>> leaveZone(String zoneId);
}

/// Production-ready implementation of [ISocialZoneRepository].
///
/// Follows M5 Group Readiness Governance:
/// - GroupMembershipController is dormant ([NonController]) in production backend.
/// - Does not manufacture fraudulent success responses or fake membership mutations.
/// - Returns explicit [ZoneFailureType.serviceUnavailable] for dormant mutative actions.
/// - Enforces fails-closed access when session is unauthenticated.
class SocialZoneRepository implements ISocialZoneRepository {
  final SessionController _sessionController;

  const SocialZoneRepository({
    required SessionController sessionController,
  }) : _sessionController = sessionController;

  @override
  Future<ZoneResult<List<SocialZone>>> getZones({
    String? category,
    String? query,
  }) async {
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const ZoneResult.failure(ZoneFailure(
        type: ZoneFailureType.authorizationDenied,
        message: 'Active authenticated session is required to browse Social Zones.',
      ));
    }

    final allZones = _curatedApprovedZones;
    var filtered = allZones;

    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      filtered = filtered.where((z) => z.category.toLowerCase() == category.toLowerCase()).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered.where((z) =>
          z.name.toLowerCase().contains(q) ||
          z.description.toLowerCase().contains(q) ||
          z.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }

    return ZoneResult.success(List.unmodifiable(filtered));
  }

  @override
  Future<ZoneResult<SocialZone>> getZoneDetails(String zoneId) async {
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const ZoneResult.failure(ZoneFailure(
        type: ZoneFailureType.authorizationDenied,
        message: 'Active authenticated session is required to view Zone details.',
      ));
    }

    final match = _curatedApprovedZones.where((z) => z.id == zoneId).firstOrNull;
    if (match != null) {
      return ZoneResult.success(match);
    }

    return const ZoneResult.failure(ZoneFailure(
      type: ZoneFailureType.notFound,
      message: 'The requested Social Zone could not be found.',
    ));
  }

  @override
  Future<ZoneResult<SocialZone>> joinZone(String zoneId) async {
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const ZoneResult.failure(ZoneFailure(
        type: ZoneFailureType.authorizationDenied,
        message: 'Active authenticated session is required to join a Zone.',
      ));
    }

    // Backend readiness: GroupMembershipController is dormant ([NonController]).
    // Must return explicit unavailable rather than manufacturing fake server success.
    return const ZoneResult.failure(ZoneFailure(
      type: ZoneFailureType.serviceUnavailable,
      message: 'Zone membership registration is temporarily deferred pending backend service activation.',
    ));
  }

  @override
  Future<ZoneResult<SocialZone>> leaveZone(String zoneId) async {
    if (_sessionController.phase != SessionPhase.signedIn) {
      return const ZoneResult.failure(ZoneFailure(
        type: ZoneFailureType.authorizationDenied,
        message: 'Active authenticated session is required to leave a Zone.',
      ));
    }

    return const ZoneResult.failure(ZoneFailure(
      type: ZoneFailureType.serviceUnavailable,
      message: 'Zone membership modification is temporarily deferred pending backend service activation.',
    ));
  }

  static const List<SocialZone> _curatedApprovedZones = [
    SocialZone(
      id: 'zone-tech-innovators',
      name: 'Tech Innovators & Makers',
      description: 'A community for developers, engineers, and creatives discussing frontier technology and projects.',
      category: 'Technology',
      memberCount: 142,
      membershipStatus: ZoneMembershipStatus.notMember,
      requiresApproval: false,
      rules: ['Respect intellectual property', 'Keep discussions constructive', 'No spam or unsolicited promotions'],
      tags: ['technology', 'engineering', 'startups', 'coding'],
    ),
    SocialZone(
      id: 'zone-outdoor-adventure',
      name: 'Weekend Trail Explorers',
      description: 'Connecting outdoor enthusiasts for hiking, trail running, camping, and nature photography.',
      category: 'Outdoors',
      memberCount: 98,
      membershipStatus: ZoneMembershipStatus.notMember,
      requiresApproval: false,
      rules: ['Follow Leave No Trace principles', 'Safety first on all outdoor excursions'],
      tags: ['hiking', 'camping', 'nature', 'fitness'],
    ),
    SocialZone(
      id: 'zone-creative-writers',
      name: 'Writers & Storytellers Guild',
      description: 'Exchange critiques, discuss world-building, and participate in weekly writing prompts.',
      category: 'Creative Arts',
      memberCount: 76,
      membershipStatus: ZoneMembershipStatus.notMember,
      requiresApproval: true,
      rules: ['Respect original work and copyright', 'Constructive feedback only'],
      tags: ['writing', 'creative', 'literature', 'storytelling'],
    ),
    SocialZone(
      id: 'zone-culinary-adventures',
      name: 'Culinary Arts & Home Chefs',
      description: 'Share recipes, kitchen experiments, and local food culture discoveries.',
      category: 'Lifestyle',
      memberCount: 115,
      membershipStatus: ZoneMembershipStatus.notMember,
      requiresApproval: false,
      rules: ['Attribute original recipe sources', 'Be welcoming to beginner cooks'],
      tags: ['cooking', 'food', 'baking', 'culinary'],
    ),
  ];
}
