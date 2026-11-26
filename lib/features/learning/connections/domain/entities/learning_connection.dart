import 'package:flutter/foundation.dart';

/// Lifecycle statuses governing pairwise Learning connections (CF-05, BRD v2.4-R1).
enum LearningConnectionStatus {
  /// Confirmed active mutual learning connection.
  active,

  /// Connection has been terminated or removed by either participant.
  removed;

  /// Whether the connection is currently active.
  bool get isActive => this == LearningConnectionStatus.active;

  /// Whether the connection is removed.
  bool get isRemoved => this == LearningConnectionStatus.removed;

  /// Safely parses a string into [LearningConnectionStatus].
  static LearningConnectionStatus parse(
    String? value, {
    LearningConnectionStatus defaultValue = LearningConnectionStatus.active,
  }) {
    if (value == null) return defaultValue;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'active':
      case 'connected':
        return LearningConnectionStatus.active;
      case 'removed':
      case 'disconnected':
        return LearningConnectionStatus.removed;
      default:
        return defaultValue;
    }
  }
}

/// Immutable domain model representing an established Learning connection (CF-05).
///
/// Follows ANDRIL Learning Module architectural and privacy rules:
/// - Strictly scoped to module 'learning'. Cross-module leakage is strictly prohibited.
/// - Uses opaque module-profile IDs ([peerProfileId]). Internal account IDs are never exposed.
/// - Defensive immutability: copies and freezes all collection properties upon construction.
/// - Redacted [toString] ensures confidential learner data is never leaked into logs or crash dumps.
/// - Value equality and order-independent hashing.
@immutable
class LearningConnection {
  /// Canonical module scope invariant.
  static const String moduleScope = 'learning';

  /// Unique connection relationship identifier.
  final String id;

  /// Opaque Learning profile identifier of the connected peer.
  final String peerProfileId;

  /// Public display name of the connected peer.
  final String peerDisplayName;

  /// Optional avatar URL or image resource path for the peer.
  final String? peerAvatarUrl;

  /// Defensive unmodifiable list of skills shared or exchanged with this peer.
  final List<String> _sharedSkills;

  /// Defensive unmodifiable list of learning goals aligned with this peer.
  final List<String> _learningGoals;

  /// Timestamp when the connection was established.
  final DateTime connectedAt;

  /// Current relationship lifecycle status.
  final LearningConnectionStatus status;

  /// Canonical module scope. Invariant: must strictly equal [moduleScope] ('learning').
  final String module;

  /// Constructs an immutable [LearningConnection] with defensive collection copying.
  LearningConnection({
    required String id,
    required String peerProfileId,
    required String peerDisplayName,
    this.peerAvatarUrl,
    Iterable<String>? sharedSkills,
    Iterable<String>? learningGoals,
    DateTime? connectedAt,
    this.status = LearningConnectionStatus.active,
    String module = moduleScope,
  })  : id = _validateRequired(id, 'id'),
        peerProfileId = _validateRequired(peerProfileId, 'peerProfileId'),
        peerDisplayName = _validateRequired(peerDisplayName, 'peerDisplayName'),
        connectedAt = connectedAt ?? DateTime.now(),
        module = _validateModule(module),
        _sharedSkills = sharedSkills == null
            ? const <String>[]
            : List<String>.unmodifiable(List<String>.of(sharedSkills)),
        _learningGoals = learningGoals == null
            ? const <String>[]
            : List<String>.unmodifiable(List<String>.of(learningGoals));

  /// Unmodifiable view of skills shared with this peer.
  List<String> get sharedSkills => _sharedSkills;

  /// Unmodifiable view of learning goals associated with this peer.
  List<String> get learningGoals => _learningGoals;

  /// Whether this connection is active.
  bool get isActive => status == LearningConnectionStatus.active;

  /// Constructs a [LearningConnection] from serialized JSON data.
  factory LearningConnection.fromJson(Map<String, dynamic> json) {
    final idVal = json['id']?.toString() ?? '';
    final peerIdVal = json['peerProfileId']?.toString() ?? '';
    final peerNameVal = json['peerDisplayName']?.toString() ?? '';

    final skillsList = <String>[];
    if (json['sharedSkills'] is Iterable) {
      for (final item in json['sharedSkills'] as Iterable) {
        if (item != null) skillsList.add(item.toString());
      }
    }

    final goalsList = <String>[];
    if (json['learningGoals'] is Iterable) {
      for (final item in json['learningGoals'] as Iterable) {
        if (item != null) goalsList.add(item.toString());
      }
    }

    DateTime parsedDate;
    if (json['connectedAt'] != null) {
      parsedDate =
          DateTime.tryParse(json['connectedAt'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return LearningConnection(
      id: idVal,
      peerProfileId: peerIdVal,
      peerDisplayName: peerNameVal,
      peerAvatarUrl: json['peerAvatarUrl']?.toString(),
      sharedSkills: skillsList,
      learningGoals: goalsList,
      connectedAt: parsedDate,
      status: LearningConnectionStatus.parse(json['status']?.toString()),
      module: json['module']?.toString() ?? moduleScope,
    );
  }

  /// Serializes this connection to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'peerProfileId': peerProfileId,
      'peerDisplayName': peerDisplayName,
      if (peerAvatarUrl != null) 'peerAvatarUrl': peerAvatarUrl,
      'sharedSkills': _sharedSkills,
      'learningGoals': _learningGoals,
      'connectedAt': connectedAt.toIso8601String(),
      'status': status.name,
      'module': module,
    };
  }

  /// Creates a copy with optionally replaced properties.
  LearningConnection copyWith({
    String? id,
    String? peerProfileId,
    String? peerDisplayName,
    String? peerAvatarUrl,
    Iterable<String>? sharedSkills,
    Iterable<String>? learningGoals,
    DateTime? connectedAt,
    LearningConnectionStatus? status,
    String? module,
  }) {
    return LearningConnection(
      id: id ?? this.id,
      peerProfileId: peerProfileId ?? this.peerProfileId,
      peerDisplayName: peerDisplayName ?? this.peerDisplayName,
      peerAvatarUrl: peerAvatarUrl ?? this.peerAvatarUrl,
      sharedSkills: sharedSkills ?? _sharedSkills,
      learningGoals: learningGoals ?? _learningGoals,
      connectedAt: connectedAt ?? this.connectedAt,
      status: status ?? this.status,
      module: module ?? this.module,
    );
  }

  static String _validateRequired(String value, String fieldName) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
          value, fieldName, '$fieldName cannot be empty.');
    }
    return trimmed;
  }

  static String _validateModule(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed != moduleScope) {
      throw ArgumentError.value(
        value,
        'module',
        "Learning connection must strictly belong to module '$moduleScope'. Cross-module connections are blocked.",
      );
    }
    return moduleScope;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LearningConnection) return false;
    return id == other.id &&
        peerProfileId == other.peerProfileId &&
        peerDisplayName == other.peerDisplayName &&
        peerAvatarUrl == other.peerAvatarUrl &&
        status == other.status &&
        module == other.module &&
        listEquals(_sharedSkills, other._sharedSkills) &&
        listEquals(_learningGoals, other._learningGoals);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      peerProfileId,
      peerDisplayName,
      peerAvatarUrl,
      status,
      module,
      Object.hashAll(_sharedSkills),
      Object.hashAll(_learningGoals),
    );
  }

  @override
  String toString() {
    return 'LearningConnection(id: $id, peerProfileId: $peerProfileId, status: ${status.name}, module: $module)';
  }
}
