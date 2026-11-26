import 'package:flutter/material.dart';
import '../domain/social_candidate.dart';
import 'social_search_viewmodel.dart';

/// Presentation screen for searching Social members (S25 Search People, S26 No People Found).
///
/// Follows M5 Search Governance:
/// - Strictly searches verified Social profiles.
/// - Meaningful loading, empty (S26), access denied, and error states.
/// - Responsive layout supporting 320dp, 400dp, and 800dp viewports.
class SocialSearchScreen extends StatefulWidget {
  final SocialSearchViewModel viewModel;
  final List<SocialCandidate> candidates;
  final ValueChanged<SocialCandidate>? onViewProfile;

  const SocialSearchScreen({
    super.key,
    required this.viewModel,
    this.candidates = const [],
    this.onViewProfile,
  });

  @override
  State<SocialSearchScreen> createState() => _SocialSearchScreenState();
}

class _SocialSearchScreenState extends State<SocialSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    _searchController.addListener(() {
      widget.viewModel.search(
        _searchController.text,
        candidateSource: widget.candidates,
      );
    });
  }

  @override
  void didUpdateWidget(covariant SocialSearchScreen oldWidget) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search People'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                key: const Key('search_people_field'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, interests, or bio...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          key: const Key('clear_search_button'),
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            vm.clearSearch();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: _buildBody(context, vm, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SocialSearchViewModel vm,
    ThemeData theme,
  ) {
    if (vm.isAccessDenied) {
      return _buildAccessDeniedState(theme, vm);
    }

    if (vm.isError) {
      return _buildErrorState(theme, vm);
    }

    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.status == SocialSearchViewStatus.initial) {
      return _buildInitialPrompt(theme);
    }

    if (vm.isEmpty || vm.results.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vm.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final candidate = vm.results[index];
        return _buildCandidateCard(context, candidate, theme);
      },
    );
  }

  Widget _buildCandidateCard(
    BuildContext context,
    SocialCandidate candidate,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
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
            Text(
              '${candidate.displayName}, ${candidate.age}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
            if (candidate.biography != null) ...[
              const SizedBox(height: 2),
              Text(
                candidate.biography!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (candidate.interests.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                candidate.interests.take(3).join(', '),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => widget.onViewProfile?.call(candidate),
      ),
    );
  }

  Widget _buildInitialPrompt(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 56, color: theme.colorScheme.primary.withAlpha(128)),
          const SizedBox(height: 16),
          Text(
            'Search Social Members',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter a name, interest, or keyword to find people.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
            Icon(Icons.person_search_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No People Found',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or keywords to discover new people.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedState(ThemeData theme, SocialSearchViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, SocialSearchViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Search Error', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(vm.errorMessage ?? 'An error occurred during search.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
