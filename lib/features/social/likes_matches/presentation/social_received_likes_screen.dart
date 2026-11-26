import 'package:flutter/material.dart';
import '../../discovery/domain/social_candidate.dart';
import '../domain/social_relationship.dart';
import 'social_relationship_viewmodel.dart';

/// Presentation screen for Received Dating Interest ('Likes') (S43 Connection Requests).
///
/// Follows M5-FE-S43 presentation governance:
/// - Fails closed: Displays access-denied state if session or Social opt-in is missing.
/// - Renders explicit service-unavailable state when backend is dormant.
/// - Defensively manages action controls with progress indicators.
/// - Does not invent Premium barriers or disclose unauthorized identity fields.
class SocialReceivedLikesScreen extends StatefulWidget {
  final SocialRelationshipViewModel viewModel;
  final ValueChanged<SocialCandidate>? onViewProfile;
  final VoidCallback? onExplore;

  const SocialReceivedLikesScreen({
    super.key,
    required this.viewModel,
    this.onViewProfile,
    this.onExplore,
  });

  @override
  State<SocialReceivedLikesScreen> createState() =>
      _SocialReceivedLikesScreenState();
}

class _SocialReceivedLikesScreenState extends State<SocialReceivedLikesScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    if (widget.viewModel.status == SocialRelationshipViewStatus.initial) {
      widget.viewModel.loadReceivedLikes();
    }
  }

  @override
  void didUpdateWidget(covariant SocialReceivedLikesScreen oldWidget) {
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
            const Text('Received Likes'),
            if (vm.receivedLikes.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${vm.receivedLikes.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
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
            onPressed: vm.isLoading ? null : () => vm.loadReceivedLikes(refresh: true),
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

    if (vm.isLoading && vm.receivedLikes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.receivedLikes.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadReceivedLikes(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vm.receivedLikes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final rel = vm.receivedLikes[index];
          return _buildLikeCard(context, rel, vm, theme);
        },
      ),
    );
  }

  Widget _buildLikeCard(
    BuildContext context,
    SocialRelationship rel,
    SocialRelationshipViewModel vm,
    ThemeData theme,
  ) {
    final candidate = rel.candidate;
    final inProgress = vm.isOperationInProgress(rel.targetProfileId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onViewProfile?.call(candidate),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: candidate.primaryPhotoUrl != null
                        ? NetworkImage(candidate.primaryPhotoUrl!)
                        : null,
                    child: candidate.primaryPhotoUrl == null
                        ? Icon(Icons.person, size: 28, color: theme.colorScheme.onPrimaryContainer)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (candidate.approximateDistanceKm != null)
                          Text(
                            '${candidate.approximateDistanceKm} km away',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (candidate.biography != null && candidate.biography!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            candidate.biography!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (inProgress)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      key: Key('pass_button_${rel.targetProfileId}'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Pass'),
                      onPressed: () => vm.respondToLike(
                        targetProfileId: rel.targetProfileId,
                        isPositive: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      key: Key('like_back_button_${rel.targetProfileId}'),
                      icon: const Icon(Icons.favorite, size: 18),
                      label: const Text('Like Back'),
                      onPressed: () => vm.respondToLike(
                        targetProfileId: rel.targetProfileId,
                        isPositive: true,
                      ),
                    ),
                  ],
                ),
            ],
          ),
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
              Icons.favorite_border,
              size: 64,
              color: theme.colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'No Likes Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'When other members express interest in your profile, they will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
            Text(
              'Access Restricted',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? 'Adult eligibility verification and Social opt-in are required.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => vm.loadReceivedLikes(refresh: true),
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
            Text(
              'Service Preparing',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? 'The relationship service is currently preparing and unavailable.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => vm.loadReceivedLikes(refresh: true),
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
            Text(
              'Something Went Wrong',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => vm.loadReceivedLikes(refresh: true),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
