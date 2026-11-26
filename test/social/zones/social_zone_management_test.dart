import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone_management.dart';

void main() {
  group('ZoneRole', () {
    test('parses approved roles case-insensitively', () {
      expect(ZoneRole.fromString('host'), ZoneRole.host);
      expect(ZoneRole.fromString('HOST'), ZoneRole.host);
      expect(ZoneRole.fromString('owner'), ZoneRole.host);
      expect(ZoneRole.fromString('creator'), ZoneRole.host);

      expect(ZoneRole.fromString('moderator'), ZoneRole.moderator);
      expect(ZoneRole.fromString('MOD'), ZoneRole.moderator);
      expect(ZoneRole.fromString('admin'), ZoneRole.moderator);

      expect(ZoneRole.fromString('member'), ZoneRole.member);
      expect(ZoneRole.fromString('unknown_role'), ZoneRole.member);
      expect(ZoneRole.fromString(''), ZoneRole.member);
    });
  });

  group('ZonePermissionEvidence', () {
    test('host factory provides full management permissions', () {
      final hostEvidence = ZonePermissionEvidence.host(
        zoneId: 'z-tech-1',
        userId: 'u-host-1',
      );

      expect(hostEvidence.isAuthoritative, isTrue);
      expect(hostEvidence.role, ZoneRole.host);
      expect(hostEvidence.canManageZone, isTrue);
      expect(hostEvidence.canModerate, isTrue);
      expect(hostEvidence.hasPermission(ZoneManagementPermission.manageRoles), isTrue);
      expect(hostEvidence.hasPermission(ZoneManagementPermission.manageRules), isTrue);
      expect(hostEvidence.hasPermission(ZoneManagementPermission.editDetails), isTrue);
      expect(hostEvidence.hasPermission(ZoneManagementPermission.viewMembers), isTrue);
    });

    test('moderator factory grants moderation but denies zone editing and role management', () {
      final modEvidence = ZonePermissionEvidence.moderator(
        zoneId: 'z-tech-1',
        userId: 'u-mod-1',
      );

      expect(modEvidence.isAuthoritative, isTrue);
      expect(modEvidence.role, ZoneRole.moderator);
      expect(modEvidence.canModerate, isTrue);
      expect(modEvidence.hasPermission(ZoneManagementPermission.reviewJoinRequests), isTrue);
      expect(modEvidence.canManageZone, isFalse);
      expect(modEvidence.hasPermission(ZoneManagementPermission.manageRoles), isFalse);
      expect(modEvidence.hasPermission(ZoneManagementPermission.editDetails), isFalse);
    });

    test('memberDefault factory allows member view but denies privileged management', () {
      final memberEvidence = ZonePermissionEvidence.memberDefault(
        zoneId: 'z-tech-1',
        userId: 'u-member-1',
      );

      expect(memberEvidence.isAuthoritative, isTrue);
      expect(memberEvidence.role, ZoneRole.member);
      expect(memberEvidence.hasPermission(ZoneManagementPermission.viewMembers), isTrue);
      expect(memberEvidence.canManageZone, isFalse);
      expect(memberEvidence.canModerate, isFalse);
      expect(memberEvidence.hasPermission(ZoneManagementPermission.manageRoles), isFalse);
    });

    test('unverified evidence fails closed on all permission checks', () {
      final unverified = ZonePermissionEvidence.unverified(
        zoneId: 'z-tech-1',
        userId: 'u-attacker-1',
      );

      expect(unverified.isAuthoritative, isFalse);
      expect(unverified.canManageZone, isFalse);
      expect(unverified.canModerate, isFalse);
      expect(unverified.hasPermission(ZoneManagementPermission.viewMembers), isFalse);
      expect(unverified.hasPermission(ZoneManagementPermission.editDetails), isFalse);
    });

    test('immutability: permissions set cannot be modified', () {
      final evidence = ZonePermissionEvidence.host(
        zoneId: 'z-1',
        userId: 'u-1',
      );

      expect(() => (evidence.permissions as dynamic).add(ZoneManagementPermission.viewMembers),
          throwsA(isA<UnsupportedError>()));
    });

    test('JSON serialization roundtrip preserves authoritative evidence', () {
      final original = ZonePermissionEvidence.moderator(
        zoneId: 'z-json-1',
        userId: 'u-json-1',
        verifiedAt: DateTime.utc(2026, 11, 26, 12, 0, 0),
      );

      final json = original.toJson();
      final restored = ZonePermissionEvidence.fromJson(json);

      expect(restored.zoneId, original.zoneId);
      expect(restored.userId, original.userId);
      expect(restored.role, original.role);
      expect(restored.isAuthoritative, original.isAuthoritative);
      expect(restored.canModerate, isTrue);
      expect(restored.canManageZone, isFalse);
    });
  });

  group('ZoneManagementDraft', () {
    test('valid draft passes validation', () {
      final draft = ZoneManagementDraft(
        name: 'Mobile App Builders',
        description: 'Collaborative development of cross-platform apps.',
        category: 'Technology',
        rules: ['No spam', 'Be kind'],
        tags: ['flutter', 'dart'],
      );

      expect(draft.isValid, isTrue);
      expect(draft.validate(), isNull);
    });

    test('rejects short or empty name', () {
      final emptyName = ZoneManagementDraft(
        name: '  ',
        description: 'Valid description with sufficient length.',
        category: 'Tech',
      );
      expect(emptyName.isValid, isFalse);
      expect(emptyName.validate(), 'Zone name cannot be empty.');

      final shortName = ZoneManagementDraft(
        name: 'AB',
        description: 'Valid description with sufficient length.',
        category: 'Tech',
      );
      expect(shortName.isValid, isFalse);
      expect(shortName.validate(), 'Zone name must be at least 3 characters.');
    });

    test('rejects short or empty description', () {
      final emptyDesc = ZoneManagementDraft(
        name: 'Valid Name',
        description: '',
        category: 'Tech',
      );
      expect(emptyDesc.isValid, isFalse);
      expect(emptyDesc.validate(), 'Description cannot be empty.');

      final shortDesc = ZoneManagementDraft(
        name: 'Valid Name',
        description: 'Too short',
        category: 'Tech',
      );
      expect(shortDesc.isValid, isFalse);
      expect(shortDesc.validate(), 'Description must be at least 10 characters.');
    });

    test('immutability: rules and tags cannot be mutated', () {
      final draft = ZoneManagementDraft(
        name: 'Valid Name',
        description: 'Valid description that meets minimum length.',
        category: 'Tech',
        rules: ['Rule 1'],
        tags: ['tag1'],
      );

      expect(() => (draft.rules as dynamic).add('Rule 2'), throwsA(isA<UnsupportedError>()));
      expect(() => (draft.tags as dynamic).add('tag2'), throwsA(isA<UnsupportedError>()));
    });
  });

  group('ZoneMemberEntry', () {
    test('roundtrip serialization works cleanly', () {
      final member = ZoneMemberEntry(
        memberId: 'mem-101',
        displayName: 'Alice Engineer',
        role: ZoneRole.moderator,
        joinedAt: DateTime.utc(2026, 10, 15),
        isSelf: true,
      );

      final json = member.toJson();
      final restored = ZoneMemberEntry.fromJson(json);

      expect(restored.memberId, 'mem-101');
      expect(restored.displayName, 'Alice Engineer');
      expect(restored.role, ZoneRole.moderator);
      expect(restored.isSelf, isTrue);
    });
  });
}
