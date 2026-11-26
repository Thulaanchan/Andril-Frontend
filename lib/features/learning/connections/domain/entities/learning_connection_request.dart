import 'package:flutter/foundation.dart';

/// Lifecycle statuses governing Learning connection requests (CF-05).
enum LearningRequestStatus {
  /// Request is awaiting response from recipient.
  pending,

  /// Recipient accepted the connection request.
  accepted,

  /// Recipient declined the connection request.
  declined,

  /// Sender cancelled their pending request before recipient answered.
  cancelled;

  /// Whether the request is currently pending.
  bool get isPending => this == LearningRequestStatus.pending;

  /// Whether the request was accepted.
  bool get isAccepted => this == LearningRequestStatus.accepted;

  /// Whether the request was declined.
  bool get isDeclined => this == LearningRequestStatus.declined;

  /// Whether the request was cancelled.
  bool get isCancelled => this == LearningRequestStatus.cancelled;

  /// Safely parses a string into [LearningRequestStatus].
  static LearningRequestStatus parse(
    String? value, {
    LearningRequestStatus defaultValue = LearningRequestStatus.pending,
  }) {
    if (value == null) return defaultValue;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'pending':
        return LearningRequestStatus.pending;
      case 'accepted':
        return LearningRequestStatus.accepted;
      case 'declined':
      case 'rejected':
        return LearningRequestStatus.declined;
      case 'cancelled':
      case 'canceled':
        return LearningRequestStatus.cancelled;
      default:
        return defaultValue;
    }
  }
}

/// Immutable domain model representing a Learning connection request (CF-05).
///
/// Follows ANDRIL Learning Module privacy and security requirements:
/// - Strictly scoped to module 'learning'. Cross-module requests are prohibited.
/// - Distinguishes sender/receiver module-profile IDs from account IDs.
/// - Unidirectional pending requests never grant chat permissions or establish automatic connections.
/// - Immutably protects collections and validates parameters fail-closed.
/// - Redacted [toString] prevents leaking personal notes or private profile identifiers.
@immutable
class LearningConnectionRequest {
  /// Canonical module scope invariant.
  static const String moduleScope = 'learning';

  /// Unique connection request identifier.
  final String id;

  /// Opaque Learning profile identifier of the request sender.
  final String senderProfileId;

  /// Public display name of the request sender.
  final String senderDisplayName;

  /// Optional avatar URL or image resource path for the sender.
  final String? senderAvatarUrl;

  /// Defensive unmodifiable list of skills declared by the sender.
  final List<String> _senderSkills;

  /// Opaque Learning profile identifier of the intended recipient.
  final String receiverProfileId;

  /// Public display name of the intended recipient.
  final String receiverDisplayName;

  /// Optional contextual note or introduction sent with the request (max 200 chars).
  final String? note;

  /// Timestamp when the request was initiated.
  final DateTime createdAt;

  /// Current request lifecycle status.
  final LearningRequestStatus status;

  /// Whether this request was received by the current user (incoming) or sent by them (outgoing).
  final bool isIncoming;

  /// Canonical module scope. Invariant: must strictly equal [moduleScope] ('learning').
  final String module;

  /// Constructs an immutable [LearningConnectionRequest] with defensive collection copying.
  LearningConnectionRequest({
    required String id,
    required String senderProfileId,
    required String senderDisplayName,
    this.senderAvatarUrl,
    Iterable<String>? senderSkills,
    required String receiverProfileId,
    required String receiverDisplayName,
    this.note,
    DateTime? createdAt,
    this.status = LearningRequestStatus.pending,
    this.isIncoming = true,
    String module = moduleScope,
  })  : id = _validateRequired(id, 'id'),
        senderProfileId = _validateRequired(senderProfileId, 'senderProfileId'),
        senderDisplayName =
            _validateRequired(senderDisplayName, 'senderDisplayName'),
        receiverProfileId =
            _validateRequired(receiverProfileId, 'receiverProfileId'),
        receiverDisplayName =
            _validateRequired(receiverDisplayName, 'receiverDisplayName'),
        createdAt = createdAt ?? DateTime.now(),
        module = _validateModule(module),
        _senderSkills = senderSkills == null
            ? const <String>[]
            : List<String>.unmodifiable(List<String>.of(senderSkills));

  /// Unmodifiable view of skills declared by the sender.
  List<String> get senderSkills => _senderSkills;

  /// Whether this request is still pending action.
  bool get isPending => status == LearningRequestStatus.pending;

  /// Constructs a [LearningConnectionRequest] from serialized JSON data.
  factory LearningConnectionRequest.fromJson(Map<String, dynamic> json) {
    final idVal = json['id']?.toString() ?? '';
    final sIdVal = json['senderProfileId']?.toString() ?? '';
    final sNameVal = json['senderDisplayName']?.toString() ?? '';
    final rIdVal = json['receiverProfileId']?.toString() ?? '';
    final rNameVal = json['receiverDisplayName']?.toString() ?? '';

    final skillsList = <String>[];
    if (json['senderSkills'] is Iterable) {
      for (final item in json['senderSkills'] as Iterable) {
        if (item != null) skillsList.add(item.toString());
      }
    }

    DateTime parsedDate;
    if (json['createdAt'] != null) {
      parsedDate =
          DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return LearningConnectionRequest(
      id: idVal,
      senderProfileId: sIdVal,
      senderDisplayName: sNameVal,
      senderAvatarUrl: json['senderAvatarUrl']?.toString(),
      senderSkills: skillsList,
      receiverProfileId: rIdVal,
      receiverDisplayName: rNameVal,
      note: json['note']?.toString(),
      createdAt: parsedDate,
      status: LearningRequestStatus.parse(json['status']?.toString()),
      isIncoming: json['isIncoming'] == true,
      module: json['module']?.toString() ?? moduleScope,
    );
  }

  /// Serializes this request to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderProfileId': senderProfileId,
      'senderDisplayName': senderDisplayName,
      if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
      'senderSkills': _senderSkills,
      'receiverProfileId': receiverProfileId,
      'receiverDisplayName': receiverDisplayName,
      if (note != null) 'note': note,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'isIncoming': isIncoming,
      'module': module,
    };
  }

  /// Creates a copy with optionally replaced properties.
  LearningConnectionRequest copyWith({
    String? id,
    String? senderProfileId,
    String? senderDisplayName,
    String? senderAvatarUrl,
    Iterable<String>? senderSkills,
    String? receiverProfileId,
    String? receiverDisplayName,
    String? note,
    DateTime? createdAt,
    LearningRequestStatus? status,
    bool? isIncoming,
    String? module,
  }) {
    return LearningConnectionRequest(
      id: id ?? this.id,
      senderProfileId: senderProfileId ?? this.senderProfileId,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      senderSkills: senderSkills ?? _senderSkills,
      receiverProfileId: receiverProfileId ?? this.receiverProfileId,
      receiverDisplayName: receiverDisplayName ?? this.receiverDisplayName,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isIncoming: isIncoming ?? this.isIncoming,
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
        "Learning connection request must strictly belong to module '$moduleScope'. Cross-module requests are blocked.",
      );
    }
    return moduleScope;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LearningConnectionRequest) return false;
    return id == other.id &&
        senderProfileId == other.senderProfileId &&
        senderDisplayName == other.senderDisplayName &&
        senderAvatarUrl == other.senderAvatarUrl &&
        receiverProfileId == other.receiverProfileId &&
        receiverDisplayName == other.receiverDisplayName &&
        note == other.note &&
        status == other.status &&
        isIncoming == other.isIncoming &&
        module == other.module &&
        listEquals(_senderSkills, other._senderSkills);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      senderProfileId,
      senderDisplayName,
      senderAvatarUrl,
      receiverProfileId,
      receiverDisplayName,
      note,
      status,
      isIncoming,
      module,
      Object.hashAll(_senderSkills),
    );
  }

  @override
  String toString() {
    return 'LearningConnectionRequest(id: $id, isIncoming: $isIncoming, status: ${status.name}, module: $module)';
  }
}
