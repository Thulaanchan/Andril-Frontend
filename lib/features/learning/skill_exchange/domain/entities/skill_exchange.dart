import 'package:flutter/foundation.dart';

import 'skill_exchange_participant.dart';

/// Proposal lifecycle status matching backend `SkillExchangeStatus`.
enum SkillExchangeStatus {
  pending,
  accepted,
  declined,
  cancelled,
}

/// Comparison result matching backend `PendingProposalComparison`.
enum PendingProposalComparison {
  exactDuplicate,
  notBothPending,
  pendingPairConflict,
  differentPair,
}

/// Domain entity representing a Learning Skill Exchange proposal.
///
/// Models the local proposal lifecycle under DEC-20261120-LRN01-01 / DEC-M1-01.
/// Strictly scoped to module 'learning'.
@immutable
class SkillExchange {
  /// Canonical module scope identifier.
  static const String moduleScope = 'learning';

  /// Standard disconnected persistence disclaimer notice.
  static const String disconnectedNotice =
      'Remote Skill Exchange contract pending in OpenAPI v1. Exchanges operate in local disconnected mode.';

  /// Unique proposal identifier.
  final String id;

  /// Module identifier (strictly 'learning').
  final String module;

  /// Sender of the exchange proposal.
  final SkillExchangeParticipant sender;

  /// Recipient of the exchange proposal.
  final SkillExchangeParticipant recipient;

  /// Skill offered by the sender.
  final String offeredSkill;

  /// Skill wanted by the sender (requested from the recipient).
  final String wantedSkill;

  /// Current proposal lifecycle status.
  final SkillExchangeStatus status;

  /// Timestamp when the proposal was created.
  final DateTime createdAt;

  /// Optional message accompanying the proposal.
  final String? note;

  const SkillExchange._({
    required this.id,
    required this.module,
    required this.sender,
    required this.recipient,
    required this.offeredSkill,
    required this.wantedSkill,
    required this.status,
    required this.createdAt,
    this.note,
  });

  /// Factory constructor to propose a new Skill Exchange.
  ///
  /// Enforces structural invariants matching backend rules:
  /// - [id] non-empty.
  /// - [sender] and [recipient] must have distinct accounts and profiles.
  /// - [offeredSkill] and [wantedSkill] non-empty.
  /// - [offeredSkill] and [wantedSkill] must not be identical (unsupported without overlap policy).
  /// - [existingProposals] pair guard rejects any pending proposal for the same unordered profile pair.
  factory SkillExchange.propose({
    required String id,
    required SkillExchangeParticipant sender,
    required SkillExchangeParticipant recipient,
    required String offeredSkill,
    required String wantedSkill,
    DateTime? createdAt,
    String? note,
    Iterable<SkillExchange>? existingProposals,
  }) {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'An exchange ID is required.');
    }
    if (sender.accountId == recipient.accountId ||
        sender.learningProfileId == recipient.learningProfileId) {
      throw ArgumentError('A Skill Exchange requires distinct participants.');
    }
    final cleanOffered = offeredSkill.trim();
    final cleanWanted = wantedSkill.trim();
    if (cleanOffered.isEmpty) {
      throw ArgumentError.value(
        offeredSkill,
        'offeredSkill',
        'An offered skill reference is required.',
      );
    }
    if (cleanWanted.isEmpty) {
      throw ArgumentError.value(
        wantedSkill,
        'wantedSkill',
        'A wanted skill reference is required.',
      );
    }
    if (cleanOffered.toLowerCase() == cleanWanted.toLowerCase()) {
      throw UnsupportedError(
        'An identical offered and wanted skill requires an approved overlap policy.',
      );
    }

    final candidate = SkillExchange._(
      id: cleanId,
      module: moduleScope,
      sender: sender,
      recipient: recipient,
      offeredSkill: cleanOffered,
      wantedSkill: cleanWanted,
      status: SkillExchangeStatus.pending,
      createdAt: createdAt ?? DateTime.now(),
      note: note?.trim(),
    );

    if (existingProposals != null) {
      for (final existing in existingProposals) {
        final comparison = candidate.comparePendingProposal(existing);
        if (comparison == PendingProposalComparison.exactDuplicate ||
            comparison == PendingProposalComparison.pendingPairConflict) {
          throw StateError(
            'A pending Skill Exchange already exists for this Learning-profile pair.',
          );
        }
      }
    }

    return candidate;
  }

  /// Evaluates pending proposal comparison against another exchange.
  ///
  /// Matches backend DEC-M1-01 pair guard comparison logic.
  PendingProposalComparison comparePendingProposal(SkillExchange other) {
    if (status != SkillExchangeStatus.pending ||
        other.status != SkillExchangeStatus.pending) {
      return PendingProposalComparison.notBothPending;
    }

    final samePair = (sender.learningProfileId ==
                other.sender.learningProfileId &&
            recipient.learningProfileId == other.recipient.learningProfileId) ||
        (sender.learningProfileId == other.recipient.learningProfileId &&
            recipient.learningProfileId == other.sender.learningProfileId);

    if (!samePair) {
      return PendingProposalComparison.differentPair;
    }

    final isExact = sender == other.sender &&
        recipient == other.recipient &&
        offeredSkill.toLowerCase() == other.offeredSkill.toLowerCase() &&
        wantedSkill.toLowerCase() == other.wantedSkill.toLowerCase();

    return isExact
        ? PendingProposalComparison.exactDuplicate
        : PendingProposalComparison.pendingPairConflict;
  }

  /// Whether the supplied [participant] is either the sender or the recipient.
  bool isParticipant(SkillExchangeParticipant? participant) {
    if (participant == null) return false;
    return participant == sender || participant == recipient;
  }

  /// Accepts the pending exchange. Only the designated recipient may accept.
  SkillExchange accept(SkillExchangeParticipant participant) {
    _validateTransition(participant, recipient, 'accept');
    return copyWith(status: SkillExchangeStatus.accepted);
  }

  /// Declines the pending exchange. Only the designated recipient may decline.
  SkillExchange decline(SkillExchangeParticipant participant) {
    _validateTransition(participant, recipient, 'decline');
    return copyWith(status: SkillExchangeStatus.declined);
  }

  /// Cancels the pending exchange. Only the designated sender may cancel.
  SkillExchange cancel(SkillExchangeParticipant participant) {
    _validateTransition(participant, sender, 'cancel');
    return copyWith(status: SkillExchangeStatus.cancelled);
  }

  void _validateTransition(
    SkillExchangeParticipant participant,
    SkillExchangeParticipant requiredParticipant,
    String action,
  ) {
    if (participant != requiredParticipant) {
      throw ArgumentError(
        'The designated Skill Exchange participant is required to $action.',
      );
    }
    if (status != SkillExchangeStatus.pending) {
      throw StateError(
        'Only a pending proposal can be transitioned ($action).',
      );
    }
  }

  /// Creates a copy of this exchange with the specified fields replaced.
  SkillExchange copyWith({
    String? id,
    SkillExchangeParticipant? sender,
    SkillExchangeParticipant? recipient,
    String? offeredSkill,
    String? wantedSkill,
    SkillExchangeStatus? status,
    DateTime? createdAt,
    String? note,
  }) {
    return SkillExchange._(
      id: id ?? this.id,
      module: module,
      sender: sender ?? this.sender,
      recipient: recipient ?? this.recipient,
      offeredSkill: offeredSkill ?? this.offeredSkill,
      wantedSkill: wantedSkill ?? this.wantedSkill,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillExchange &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          module == other.module &&
          sender == other.sender &&
          recipient == other.recipient &&
          offeredSkill == other.offeredSkill &&
          wantedSkill == other.wantedSkill &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
        id,
        module,
        sender,
        recipient,
        offeredSkill,
        wantedSkill,
        status,
      );

  @override
  String toString() =>
      'Learning Skill Exchange ($status) [private references omitted]';
}
