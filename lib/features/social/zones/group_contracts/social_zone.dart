import 'package:flutter/foundation.dart';

/// Presentation membership standing of a user within a Social Zone.
enum ZoneMembershipStatus {
  notMember,
  pendingApproval,
  member,
  host,
}

/// Immutable domain model representing a Social Zone (community interest space).
///
/// Follows M5 Social Groups & Privacy Governance:
/// - Contains presentation-ready identifiers, metadata, and caller membership standing.
/// - Defensive immutability with unmodifiable list of rules/tags.
/// - Does not invent unapproved quotas, member capacity caps, or arbitrary role escalation.
/// - Redacts internal diagnostic information in [toString].
@immutable
class SocialZone {
  final String id;
  final String name;
  final String description;
  final String category;
  final int memberCount;
  final ZoneMembershipStatus membershipStatus;
  final String? imageUrl;
  final bool requiresApproval;
  final List<String> rules;
  final List<String> tags;
  final DateTime? createdAt;

  const SocialZone({
    required this.id,
    required this.name,
    required this.description,
    this.category = 'General',
    this.memberCount = 0,
    this.membershipStatus = ZoneMembershipStatus.notMember,
    this.imageUrl,
    this.requiresApproval = false,
    this.rules = const [],
    this.tags = const [],
    this.createdAt,
  });

  bool get isJoined => membershipStatus == ZoneMembershipStatus.member || membershipStatus == ZoneMembershipStatus.host;
  bool get isPending => membershipStatus == ZoneMembershipStatus.pendingApproval;
  bool get isHost => membershipStatus == ZoneMembershipStatus.host;

  SocialZone copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? memberCount,
    ZoneMembershipStatus? membershipStatus,
    String? imageUrl,
    bool? requiresApproval,
    List<String>? rules,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return SocialZone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      memberCount: memberCount ?? this.memberCount,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      imageUrl: imageUrl ?? this.imageUrl,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      rules: rules != null ? List.unmodifiable(rules) : this.rules,
      tags: tags != null ? List.unmodifiable(tags) : this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SocialZone.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? json['title'] as String? ?? '';
    final description = json['description'] as String? ?? '';
    final category = json['category'] as String? ?? 'General';
    final memberCount = (json['memberCount'] as num?)?.toInt() ?? 0;
    
    final statusStr = json['membershipStatus'] as String?;
    final ZoneMembershipStatus status;
    switch (statusStr?.toLowerCase()) {
      case 'member':
        status = ZoneMembershipStatus.member;
        break;
      case 'host':
      case 'admin':
        status = ZoneMembershipStatus.host;
        break;
      case 'pending':
      case 'pendingapproval':
        status = ZoneMembershipStatus.pendingApproval;
        break;
      default:
        status = ZoneMembershipStatus.notMember;
    }

    final imageUrl = json['imageUrl'] as String? ?? json['avatarUrl'] as String?;
    final requiresApproval = json['requiresApproval'] as bool? ?? false;
    
    final rulesRaw = json['rules'] as List<dynamic>?;
    final rules = rulesRaw != null 
        ? List<String>.unmodifiable(rulesRaw.map((e) => e.toString()))
        : const <String>[];

    final tagsRaw = json['tags'] as List<dynamic>?;
    final tags = tagsRaw != null
        ? List<String>.unmodifiable(tagsRaw.map((e) => e.toString()))
        : const <String>[];

    DateTime? createdAt;
    if (json['createdAt'] != null) {
      createdAt = DateTime.tryParse(json['createdAt'].toString());
    }

    return SocialZone(
      id: id,
      name: name,
      description: description,
      category: category,
      memberCount: memberCount,
      membershipStatus: status,
      imageUrl: imageUrl,
      requiresApproval: requiresApproval,
      rules: rules,
      tags: tags,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'memberCount': memberCount,
      'membershipStatus': membershipStatus.name,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'requiresApproval': requiresApproval,
      'rules': rules,
      'tags': tags,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialZone &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          category == other.category &&
          memberCount == other.memberCount &&
          membershipStatus == other.membershipStatus &&
          imageUrl == other.imageUrl &&
          requiresApproval == other.requiresApproval &&
          listEquals(rules, other.rules) &&
          listEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        category,
        memberCount,
        membershipStatus,
        imageUrl,
        requiresApproval,
        Object.hashAll(rules),
        Object.hashAll(tags),
      );

  @override
  String toString() {
    return 'SocialZone(id: $id, name: $name, category: $category, memberCount: $memberCount, status: ${membershipStatus.name})';
  }
}
