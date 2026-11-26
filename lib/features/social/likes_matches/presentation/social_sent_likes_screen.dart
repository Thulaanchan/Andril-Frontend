import 'package:flutter/material.dart';
import '../../discovery/domain/social_candidate.dart';
import '../domain/social_relationship.dart';
import 'social_relationship_viewmodel.dart';

/// Presentation screen for Sent Dating Interest ('Sent Likes') (S11 Interest Sent).
///
/// Follows M5-FE-S11 presentation governance:
/// - Displays caller's sent directional interest and relationship status.
/// - Unreciprocated decisions remain confidential; reveals matching standing safely.
/// - Provides profile navigation and refresh capability.
class SocialSentLikesScreen extends StatefulWidget {
  final SocialRelationshipViewModel viewModel;
  final ValueChanged<SocialCandidate>? onViewProfile;
  final VoidCallback? onExplore;

  const SocialSentLikesScreen({
    super.key,
    required this.viewModel,
    this.onViewProfile,
    this.onExplore,
  });

  @override
  State<SocialSentLikesScreen> createState() => _SocialSentLikesScreenState();
}

class _SocialSentLikesScreenState extends State<SocialSentLikesScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    if (widget.viewModel.status == SocialRelationshipViewStatus.initial) {
      widget.viewModel.loadSentLikes();
    }
  }

  @override
  void didUpdateWidget(covariant SocialSentLikesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      widget.viewModel.addListener(_onViewModelChanged);
    }
  }

  @override
  void dispose() {
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sent Likes'),
            if (vm.sentLikes.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${vm.sentLikes.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: vm.isLoading ? null : () => vm.loadSentLikes(refresh: true),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(context, vm, theme),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SocialRelationshipViewModel vm,
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

    if (vm.isLoading && vm.sentLikes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.sentLikes.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadSentLikes(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vm.sentLikes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final rel = vm.sentLikes[index];
          return _buildSentLikeCard(context, rel, vm, theme);
        },
      ),
    );
  }

  Widget _buildSentLikeCard(
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
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: candidate.primaryPhotoUrl != null
              ? NetworkImage(candidate.primaryPhotoUrl!)
              : null,
          child: candidate.primaryPhotoUrl == null
              ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer)
              : null,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (candidate.approximateDistanceKm != null)
              Text('${candidate.approximateDistanceKm} km away'),
            const SizedBox(height: 6),
            _buildStatusChip(rel.state, theme),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => widget.onViewProfile?.call(candidate),
      ),
    );
  }

  Widget _buildStatusChip(SocialRelationshipState state, ThemeData theme) {
    Color bg;
    Color fg;
    String label;

    switch (state) {
      case SocialRelationshipState.matched:
        bg = Colors.green.withAlpha(38);
        fg = Colors.green.shade800;
        label = 'Matched';
        break;
      case SocialRelationshipState.passed:
        bg = Colors.grey.withAlpha(38);
        fg = Colors.grey.shade700;
        label = 'Passed';
        break;
      case SocialRelationshipState.revoked:
        bg = Colors.orange.withAlpha(38);
        fg = Colors.orange.shade800;
        label = 'Revoked';
        break;
      case SocialRelationshipState.pendingUnilateral:
      default:
        bg = theme.colorScheme.primaryContainer.withAlpha(128);
        fg = theme.colorScheme.onPrimaryContainer;
        label = 'Interest Sent';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
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
              Icons.send_outlined,
              size: 64,
              color: theme.colorScheme.secondary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'No Sent Likes',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "When you like someone's profile, they will appear here while pending their decision.",
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
              onPressed: () => vm.loadSentLikes(refresh: true),
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
              vm.errorMessage ?? 'Sent likes service is currently preparing and unavailable.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => vm.loadSentLikes(refresh: true),
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
              onPressed: () => vm.loadSentLikes(refresh: true),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
