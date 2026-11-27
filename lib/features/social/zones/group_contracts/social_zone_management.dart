import 'package:flutter/foundation.dart';
import 'social_zone.dart';

/// Explicit management permissions applicable to Social Zones.
enum ZoneManagementPermission {
  /// Ability to edit name, description, category, and tags.
  editDetails,

  /// Ability to update community rules and guidelines.
  manageRules,

  /// Ability to view the list of zone members.
  viewMembers,

  /// Ability to review pending membership requests.
  reviewJoinRequests,

  /// Ability to moderate posts and member interactions.
  moderateContent,

  /// Ability to manage host/moderator roles (exclusive to verified hosts).
  manageRoles,
}

/// Approved roles within a Social Zone.
enum ZoneRole {
  /// Regular member with standard participation privileges.
  member,

  /// Moderator with moderation and rule enforcement privileges.
  moderator,

  /// Host with full governance authority over the Zone.
  host;

  static ZoneRole fromString(String value) {
    return switch (value.toLowerCase().trim()) {
      'host' || 'owner' || 'creator' => ZoneRole.host,
      'moderator' || 'mod' || 'admin' => ZoneRole.moderator,
      _ => ZoneRole.member,
    };
  }
}

/// Immutable record of authoritative permission evidence for a Social Zone.
///
/// Follows M5 Social Groups Governance:
/// - Permissions must originate from authoritative server evidence.
/// - Locally selected roles or arbitrary client flags never grant permissions.
/// - Prohibits client-side role escalation.
@immutable
class ZonePermissionEvidence {
  final String zoneId;
  final String userId;
  final ZoneRole role;
  final Set<ZoneManagementPermission> permissions;
  final DateTime verifiedAt;
  final bool isAuthoritative;

  ZonePermissionEvidence({
    required this.zoneId,
    required this.userId,
    required this.role,
    required Set<ZoneManagementPermission> permissions,
    required this.verifiedAt,
    this.isAuthoritative = true,
  }) : permissions = Set.unmodifiable(permissions);

  /// Default permission evidence for unverified or non-privileged members.
  factory ZonePermissionEvidence.memberDefault({
    required String zoneId,
    required String userId,
    DateTime? verifiedAt,
  }) {
    return ZonePermissionEvidence(
      zoneId: zoneId,
      userId: userId,
      role: ZoneRole.member,
      permissions: const {ZoneManagementPermission.viewMembers},
      verifiedAt: verifiedAt ?? DateTime.now(),
      isAuthoritative: true,
    );
  }

  /// Construct permission evidence for a verified Moderator.
  factory ZonePermissionEvidence.moderator({
    required String zoneId,
    required String userId,
    DateTime? verifiedAt,
  }) {
    return ZonePermissionEvidence(
      zoneId: zoneId,
      userId: userId,
      role: ZoneRole.moderator,
      permissions: const {
        ZoneManagementPermission.viewMembers,
        ZoneManagementPermission.reviewJoinRequests,
        ZoneManagementPermission.moderateContent,
      },
      verifiedAt: verifiedAt ?? DateTime.now(),
      isAuthoritative: true,
    );
  }

  /// Construct permission evidence for a verified Host.
  factory ZonePermissionEvidence.host({
    required String zoneId,
    required String userId,
    DateTime? verifiedAt,
  }) {
    return ZonePermissionEvidence(
      zoneId: zoneId,
      userId: userId,
      role: ZoneRole.host,
      permissions: const {
        ZoneManagementPermission.editDetails,
        ZoneManagementPermission.manageRules,
        ZoneManagementPermission.viewMembers,
        ZoneManagementPermission.reviewJoinRequests,
        ZoneManagementPermission.moderateContent,
        ZoneManagementPermission.manageRoles,
      },
      verifiedAt: verifiedAt ?? DateTime.now(),
      isAuthoritative: true,
    );
  }

  /// Empty / unverified evidence that fails closed.
  factory ZonePermissionEvidence.unverified({
    required String zoneId,
    required String userId,
  }) {
    return ZonePermissionEvidence(
      zoneId: zoneId,
      userId: userId,
      role: ZoneRole.member,
      permissions: const {},
      verifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
      isAuthoritative: false,
    );
  }

  /// Whether the caller possesses the requested [permission] backed by authoritative evidence.
  bool hasPermission(ZoneManagementPermission permission) {
    if (!isAuthoritative) return false;
    if (verifiedAt.millisecondsSinceEpoch <= 0) return false;
    if (zoneId.trim().isEmpty || userId.trim().isEmpty) return false;
    return permissions.contains(permission);
  }

  /// Whether the caller can manage the Zone as host.
  bool get canManageZone => hasPermission(ZoneManagementPermission.editDetails);

  /// Whether the caller can moderate members and join requests.
  bool get canModerate => hasPermission(ZoneManagementPermission.moderateContent);

  Map<String, dynamic> toJson() => {
        'zoneId': zoneId,
        'userId': userId,
        'role': role.name,
        'permissions': permissions.map((p) => p.name).toList(),
        'verifiedAt': verifiedAt.toIso8601String(),
        'isAuthoritative': isAuthoritative,
      };

  factory ZonePermissionEvidence.fromJson(Map<String, dynamic> json) {
    final role = ZoneRole.fromString(json['role'] as String? ?? 'member');
    final rawPerms = (json['permissions'] as List<dynamic>?) ?? [];
    final perms = rawPerms
        .map((p) => ZoneManagementPermission.values.where((v) => v.name == p).firstOrNull)
        .whereType<ZoneManagementPermission>()
        .toSet();

    return ZonePermissionEvidence(
      zoneId: json['zoneId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      role: role,
      permissions: perms,
      verifiedAt: DateTime.tryParse(json['verifiedAt'] as String? ?? '') ?? DateTime.now(),
      isAuthoritative: json['isAuthoritative'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'ZonePermissionEvidence(zoneId: $zoneId, role: ${role.name}, authoritative: $isAuthoritative)';
}

/// Immutable draft model for creating or editing a Social Zone.
@immutable
class ZoneManagementDraft {
  final String name;
  final String description;
  final String category;
  final List<String> rules;
  final List<String> tags;
  final bool requiresApproval;

  ZoneManagementDraft({
    required this.name,
    required this.description,
    required this.category,
    List<String> rules = const [],
    List<String> tags = const [],
    this.requiresApproval = false,
  })  : rules = List.unmodifiable(rules),
        tags = List.unmodifiable(tags);

  const ZoneManagementDraft.empty()
      : name = '',
        description = '',
        category = 'Technology',
        rules = const [],
        tags = const [],
        requiresApproval = false;

  factory ZoneManagementDraft.fromZone(SocialZone zone) {
    return ZoneManagementDraft(
      name: zone.name,
      description: zone.description,
      category: zone.category,
      rules: zone.rules,
      tags: zone.tags,
      requiresApproval: zone.requiresApproval,
    );
  }

  ZoneManagementDraft copyWith({
    String? name,
    String? description,
    String? category,
    List<String>? rules,
    List<String>? tags,
    bool? requiresApproval,
  }) {
    return ZoneManagementDraft(
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      rules: rules ?? this.rules,
      tags: tags ?? this.tags,
      requiresApproval: requiresApproval ?? this.requiresApproval,
    );
  }

  /// Validation: returns error string if invalid, or null if valid.
  String? validate() {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'Zone name cannot be empty.';
    if (trimmedName.length < 3) return 'Zone name must be at least 3 characters.';
    if (trimmedName.length > 50) return 'Zone name cannot exceed 50 characters.';

    final trimmedDesc = description.trim();
    if (trimmedDesc.isEmpty) return 'Description cannot be empty.';
    if (trimmedDesc.length < 10) return 'Description must be at least 10 characters.';
    if (trimmedDesc.length > 500) return 'Description cannot exceed 500 characters.';

    if (category.trim().isEmpty) return 'Category must be selected.';

    return null;
  }

  bool get isValid => validate() == null;
}

/// Immutable representation of a member entry in a Social Zone.
@immutable
class ZoneMemberEntry {
  final String memberId;
  final String displayName;
  final String? avatarUrl;
  final ZoneRole role;
  final DateTime joinedAt;
  final bool isSelf;

  const ZoneMemberEntry({
    required this.memberId,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
    this.isSelf = false,
  });

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'role': role.name,
        'joinedAt': joinedAt.toIso8601String(),
        'isSelf': isSelf,
      };

  factory ZoneMemberEntry.fromJson(Map<String, dynamic> json) {
    return ZoneMemberEntry(
      memberId: json['memberId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Member',
      avatarUrl: json['avatarUrl'] as String?,
      role: ZoneRole.fromString(json['role'] as String? ?? 'member'),
      joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? '') ?? DateTime.now(),
      isSelf: json['isSelf'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'ZoneMemberEntry(memberId: $memberId, role: ${role.name}, isSelf: $isSelf)';
}
