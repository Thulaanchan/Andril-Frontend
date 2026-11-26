import 'package:flutter/material.dart';
import '../group_contracts/social_zone.dart';
import '../group_contracts/social_zone_management.dart';
import 'social_zone_management_viewmodel.dart';

/// Presentation screen for viewing and managing Zone members (CF-07 / S49).
///
/// Follows M5 Social Groups & Privacy Governance:
/// - Displays member list with role badges (Host, Moderator, Member).
/// - Respects profile privacy: only surfaces display name and safe avatar.
/// - Only surfaces administrative moderation controls when backed by authoritative [ZonePermissionEvidence].
/// - Responsive across 320dp, 400dp, and 800dp viewports.
class SocialZoneMembersScreen extends StatefulWidget {
  final SocialZone zone;
  final SocialZoneManagementViewModel viewModel;
  final List<ZoneMemberEntry> members;
  final ValueChanged<ZoneMemberEntry>? onMemberSelected;
  final VoidCallback? onBack;

  const SocialZoneMembersScreen({
    super.key,
    required this.zone,
    required this.viewModel,
    this.members = const [],
    this.onMemberSelected,
    this.onBack,
  });

  @override
  State<SocialZoneMembersScreen> createState() => _SocialZoneMembersScreenState();
}

class _SocialZoneMembersScreenState extends State<SocialZoneMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.viewModel;
    final evidence = vm.permissionEvidence;
    final canManageRoles = evidence?.hasPermission(ZoneManagementPermission.manageRoles) ?? false;

    final filteredMembers = widget.members.where((m) {
      if (_query.isEmpty) return true;
      return m.displayName.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.zone.name} Members'),
        leading: widget.onBack != null
            ? IconButton(
                key: const Key('members_back_button'),
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                key: const Key('search_members_field'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (val) => setState(() => _query = val.trim()),
              ),
            ),
            if (vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  vm.errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            Expanded(
              child: filteredMembers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search, size: 56, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            _query.isNotEmpty ? 'No members matching "$_query"' : 'No members found.',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredMembers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final member = filteredMembers[index];
                        return Card(
                          key: Key('member_card_${member.memberId}'),
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    member.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (member.isSelf) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('You', style: TextStyle(fontSize: 10)),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(_roleLabel(member.role)),
                            trailing: canManageRoles && !member.isSelf
                                ? PopupMenuButton<ZoneRole>(
                                    key: Key('role_menu_${member.memberId}'),
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (newRole) {
                                      vm.updateMemberRole(member.memberId, newRole);
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: ZoneRole.moderator,
                                        child: Text('Promote to Moderator'),
                                      ),
                                      const PopupMenuItem(
                                        value: ZoneRole.member,
                                        child: Text('Set as Member'),
                                      ),
                                    ],
                                  )
                                : null,
                            onTap: () => widget.onMemberSelected?.call(member),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(ZoneRole role) {
    return switch (role) {
      ZoneRole.host => 'Host',
      ZoneRole.moderator => 'Moderator',
      ZoneRole.member => 'Member',
    };
  }
}
