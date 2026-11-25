import 'package:flutter/foundation.dart';

/// GroupKind definition matching M5 `Andril.Groups.Policies.GroupKind`.
enum GroupKind {
  classroom,
  club,
  zone,
}

/// Integration contract boundary for M1 Learning Classrooms interfacing with M5 Shared Groups.
///
/// Complies with:
/// - M5 CF-07 Proposed Shared Groups Contract (`M5_CF07_Groups_Integration_Contract_PROPOSED.md`).
/// - BRD v2.4-R1 §07.1 / §06.1, CF-06, CF-07.
/// - Module scope: strictly 'learning'.
/// - GroupKind: strictly 'Classroom'.
@immutable
class LearningGroupContract {
  /// Canonical module scope matching backend `GroupModuleScope`.
  static const String module = 'learning';

  /// Canonical group kind.
  static const GroupKind groupKind = GroupKind.classroom;

  /// Proposed path for Learning classrooms group creation.
  static const String creationEndpoint = '/api/v1/learning/groups';

  /// Proposed path for Learning classrooms discovery.
  static const String discoveryEndpoint = '/api/v1/learning/groups';

  /// Proposed path for join request creation.
  static String joinRequestEndpoint(String groupId) =>
      '/api/v1/learning/groups/$groupId/join-requests';

  /// Validates whether a given module scope is strictly compatible with Learning Classrooms.
  static bool isCompatible(String candidateModule, GroupKind candidateKind) {
    return candidateModule.toLowerCase() == module &&
        candidateKind == GroupKind.classroom;
  }
}
