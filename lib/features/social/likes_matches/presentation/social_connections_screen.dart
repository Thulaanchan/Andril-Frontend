import 'package:flutter/material.dart';
import '../../discovery/domain/social_candidate.dart';
import '../domain/social_relationship.dart';
import 'social_relationship_viewmodel.dart';

/// Presentation screen for Confirmed Connections (S13 My Connections).
///
/// Follows M5-FE-S13 presentation governance:
/// - Strictly restricts connections to Social module (keeps separate from Learning/Hobbies).
/// - Enforces server-confirmed mutual match evidence for communication entry eligibility.
/// - Does not implement M4 chat functionality directly; emits decoupled action callback.
/// - Provides category filtering (All, Recent, Favorites) and voluntary unmatch action.
class SocialConnectionsScreen extends StatefulWidget {
  final SocialRelationshipViewModel viewModel;
  final ValueChanged<SocialCandidate>? onViewProfile;
  final ValueChanged<String>? onOpenChat;
  final VoidCallback? onExplore;

  const SocialConnectionsScreen({
    super.key,
    required this.viewModel,
    this.onViewProfile,
    this.onOpenChat,
    this.onExplore,
  });

  @override
  State<SocialConnectionsScreen> createState() => _SocialConnectionsScreenState();
}

class _SocialConnectionsScreenState extends State<SocialConnectionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    if (widget.viewModel.status == SocialRelationshipViewStatus.initial) {
      widget.viewModel.loadConnections();
    }
  }

  @override
  void didUpdateWidget(covariant SocialConnectionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      widget.viewModel.addListener(_onViewModelChanged);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.viewModel;

    final filteredConnections = vm.connections.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.displayName.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Connections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: vm.isLoading ? null : () => vm.loadConnections(refresh: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCategoryFilterBar(theme, vm),
            if (vm.connections.isNotEmpty) _buildSearchBar(theme),
            Expanded(
              child: _buildBody(context, vm, filteredConnections, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterBar(ThemeData theme, SocialRelationshipViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: SocialConnectionCategory.values.map((category) {
          final isSelected = vm.selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category.displayName),
              selected: isSelected,
              onSelected: vm.isLoading
                  ? null
                  : (selected) {
                      if (selected) {
                        vm.loadConnections(category: category);
                      }
                    },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search connections...',
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SocialRelationshipViewModel vm,
    List<SocialRelationship> connections,
    ThemeData theme,
  ) {
    if (vm.isAccessDenied) {
      return _buildAccessDeniedState(theme, vm);
    }

    if (vm.isServiceUnavailable) {
      return _buildServiceUnavailableState(theme, vm);
    }

    if (vm.status == SocialRelationshipViewStatus.error) {
      return _buildErrorState(theme, vm);
    }

    if (vm.isLoading && vm.connections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.connections.isEmpty) {
      return _buildEmptyState(theme);
    }

    if (connections.isEmpty) {
      return Center(
        child: Text(
          'No connections match "$_searchQuery"',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadConnections(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: connections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final rel = connections[index];
          return _buildConnectionCard(context, rel, vm, theme);
        },
      ),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    SocialRelationship rel,
    SocialRelationshipViewModel vm,
    ThemeData theme,
  ) {
    final candidate = rel.candidate;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: candidate.primaryPhotoUrl != null
                  ? NetworkImage(candidate.primaryPhotoUrl!)
                  : null,
              child: candidate.primaryPhotoUrl == null
                  ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.surface, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                '${candidate.displayName}, ${candidate.age}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (candidate.isVerified) ...[
              const SizedBox(width: 4),
              Icon(Icons.verified, size: 16, color: theme.colorScheme.primary),
            ],
          ],
        ),
        subtitle: Text(
          candidate.biography ?? 'Connected',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onOpenChat != null && rel.canCommunicate)
              IconButton(
                key: Key('chat_button_${rel.targetProfileId}'),
                icon: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.primary),
                tooltip: 'Chat',
                onPressed: () => widget.onOpenChat?.call(rel.targetProfileId),
              ),
            PopupMenuButton<String>(
              key: Key('menu_button_${rel.targetProfileId}'),
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'view') {
                  widget.onViewProfile?.call(candidate);
                } else if (value == 'unmatch') {
                  _showUnmatchConfirmation(context, rel, vm);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Text('View Profile'),
                ),
                const PopupMenuItem(
                  value: 'unmatch',
                  child: Text('Unmatch', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        onTap: () => widget.onViewProfile?.call(candidate),
      ),
    );
  }

  void _showUnmatchConfirmation(
    BuildContext context,
    SocialRelationship rel,
    SocialRelationshipViewModel vm,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unmatch Confirmation'),
        content: Text(
          'Are you sure you want to unmatch with ${rel.displayName}? This will end direct communication.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              vm.revokeConnection(targetProfileId: rel.targetProfileId);
            },
            child: const Text('Unmatch'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'No Connections Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you and another member mutually like each other, you will become connected and can start chatting.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.onExplore != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.explore),
                label: const Text('Discover People'),
                onPressed: widget.onExplore,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedState(ThemeData theme, SocialRelationshipViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Access Restricted', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? 'Adult eligibility verification and Social opt-in are required.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => vm.loadConnections(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceUnavailableState(
    ThemeData theme,
    SocialRelationshipViewModel vm,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text('Service Preparing', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? 'Connections service is currently preparing and unavailable.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => vm.loadConnections(refresh: true),
              child: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, SocialRelationshipViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Something Went Wrong', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(vm.errorMessage ?? 'An unexpected error occurred.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => vm.loadConnections(refresh: true),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
