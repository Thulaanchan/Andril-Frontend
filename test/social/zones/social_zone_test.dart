import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/social/zones/group_contracts/social_zone.dart';

void main() {
  group('SocialZone Domain Model', () {
    test('constructs with valid required fields and defaults', () {
      const zone = SocialZone(
        id: 'zone-101',
        name: 'Photography Enthusiasts',
        description: 'A space for sharing landscape and portrait tips.',
      );

      expect(zone.id, 'zone-101');
      expect(zone.name, 'Photography Enthusiasts');
      expect(zone.description, 'A space for sharing landscape and portrait tips.');
      expect(zone.category, 'General');
      expect(zone.memberCount, 0);
      expect(zone.membershipStatus, ZoneMembershipStatus.notMember);
      expect(zone.isJoined, isFalse);
      expect(zone.isPending, isFalse);
      expect(zone.isHost, isFalse);
      expect(zone.requiresApproval, isFalse);
      expect(zone.rules, isEmpty);
      expect(zone.tags, isEmpty);
      expect(zone.imageUrl, isNull);
      expect(zone.createdAt, isNull);
    });

    test('supports defensive immutability on rules and tags', () {
      final mutableRules = ['Rule 1', 'Rule 2'];
      final mutableTags = ['photo', 'outdoors'];

      final zone = SocialZone(
        id: 'zone-102',
        name: 'Outdoor Life',
        description: 'Hiking and camping stories.',
        rules: List.unmodifiable(mutableRules),
        tags: List.unmodifiable(mutableTags),
      );

      expect(() => (zone.rules as dynamic).add('Rule 3'), throwsUnsupportedError);
      expect(() => (zone.tags as dynamic).add('hiking'), throwsUnsupportedError);
    });

    test('verifies membership status convenience getters', () {
      const notMember = SocialZone(
        id: 'z1',
        name: 'Z1',
        description: 'D1',
        membershipStatus: ZoneMembershipStatus.notMember,
      );
      expect(notMember.isJoined, isFalse);
      expect(notMember.isPending, isFalse);
      expect(notMember.isHost, isFalse);

      const pending = SocialZone(
        id: 'z2',
        name: 'Z2',
        description: 'D2',
        membershipStatus: ZoneMembershipStatus.pendingApproval,
      );
      expect(pending.isJoined, isFalse);
      expect(pending.isPending, isTrue);
      expect(pending.isHost, isFalse);

      const member = SocialZone(
        id: 'z3',
        name: 'Z3',
        description: 'D3',
        membershipStatus: ZoneMembershipStatus.member,
      );
      expect(member.isJoined, isTrue);
      expect(member.isPending, isFalse);
      expect(member.isHost, isFalse);

      const host = SocialZone(
        id: 'z4',
        name: 'Z4',
        description: 'D4',
        membershipStatus: ZoneMembershipStatus.host,
      );
      expect(host.isJoined, isTrue);
      expect(host.isPending, isFalse);
      expect(host.isHost, isTrue);
    });

    test('serializes to and deserializes from JSON accurately', () {
      final now = DateTime.utc(2026, 11, 26, 10, 0, 0);
      final original = SocialZone(
        id: 'zone-103',
        name: 'Indie Game Devs',
        description: 'Sharing prototypes and game mechanics.',
        category: 'Technology',
        memberCount: 42,
        membershipStatus: ZoneMembershipStatus.member,
        imageUrl: 'https://cdn.example.com/indie.jpg',
        requiresApproval: true,
        rules: const ['Be kind', 'No pirated assets'],
        tags: const ['gamedev', 'unity', 'flutter'],
        createdAt: now,
      );

      final json = original.toJson();
      final reconstituted = SocialZone.fromJson(json);

      expect(reconstituted, equals(original));
      expect(reconstituted.id, 'zone-103');
      expect(reconstituted.category, 'Technology');
      expect(reconstituted.memberCount, 42);
      expect(reconstituted.membershipStatus, ZoneMembershipStatus.member);
      expect(reconstituted.isJoined, isTrue);
      expect(reconstituted.requiresApproval, isTrue);
      expect(reconstituted.rules, ['Be kind', 'No pirated assets']);
      expect(reconstituted.tags, ['gamedev', 'unity', 'flutter']);
      expect(reconstituted.createdAt, now);
    });

    test('fromJson handles unknown or legacy membership strings defensively', () {
      final json = {
        'id': 'zone-104',
        'name': 'Unknown Status Zone',
        'description': 'Test unknown status',
        'membershipStatus': 'super_admin_unapproved_role',
      };

      final zone = SocialZone.fromJson(json);
      expect(zone.membershipStatus, ZoneMembershipStatus.notMember);
      expect(zone.isJoined, isFalse);
      expect(zone.isHost, isFalse);
    });

    test('copyWith produces updated instances without mutating original', () {
      const original = SocialZone(
        id: 'zone-105',
        name: 'Music Lovers',
        description: 'All genres welcome.',
        memberCount: 10,
      );

      final updated = original.copyWith(
        name: 'Acoustic & Classical Music',
        memberCount: 15,
        membershipStatus: ZoneMembershipStatus.member,
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Acoustic & Classical Music');
      expect(updated.memberCount, 15);
      expect(updated.membershipStatus, ZoneMembershipStatus.member);
      expect(updated.description, original.description);

      expect(original.name, 'Music Lovers');
      expect(original.memberCount, 10);
      expect(original.membershipStatus, ZoneMembershipStatus.notMember);
    });

    test('toString produces redacted presentation summary without leaking internal secrets', () {
      const zone = SocialZone(
        id: 'zone-106',
        name: 'Security Researchers',
        description: 'Vulnerability disclosure discussions.',
        category: 'Cybersecurity',
        memberCount: 99,
        membershipStatus: ZoneMembershipStatus.host,
      );

      final diagnostic = zone.toString();
      expect(diagnostic, contains('zone-106'));
      expect(diagnostic, contains('Security Researchers'));
      expect(diagnostic, contains('Cybersecurity'));
      expect(diagnostic, contains('host'));
      expect(diagnostic.startsWith('SocialZone('), isTrue);
    });
  });
}
