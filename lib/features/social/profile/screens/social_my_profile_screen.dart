import 'package:flutter/material.dart';
import '../viewmodels/social_profile_management_viewmodel.dart';

/// Presentation screen for viewing the caller's private Social profile (S20 My Social Profile).
///
/// Follows M5 Profile Management Governance:
/// - Displays authorized Social identity, photo, bio, and verification standing.
/// - Does not disclose other module identities or raw questionnaire answers.
/// - Includes entry to optional Personality Assessment quiz.
/// - Provides responsive layout supporting 320dp, 400dp, and 800dp viewports.
class SocialMyProfileScreen extends StatefulWidget {
  final SocialProfileManagementViewModel viewModel;
  final VoidCallback? onEditProfile;
  final VoidCallback? onTakePersonalityQuiz;
  final VoidCallback? onSettings;

  const SocialMyProfileScreen({
    super.key,
    required this.viewModel,
    this.onEditProfile,
    this.onTakePersonalityQuiz,
    this.onSettings,
  });

  @override
  State<SocialMyProfileScreen> createState() => _SocialMyProfileScreenState();
}

class _SocialMyProfileScreenState extends State<SocialMyProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    if (widget.viewModel.status == SocialProfileManagementStatus.initial) {
      widget.viewModel.loadProfile();
    }
  }

  @override
  void didUpdateWidget(covariant SocialMyProfileScreen oldWidget) {
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
        title: const Text('My Profile'),
        actions: [
          if (widget.onSettings != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: widget.onSettings,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: vm.isLoading ? null : () => vm.loadProfile(refresh: true),
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
    SocialProfileManagementViewModel vm,
    ThemeData theme,
  ) {
    if (vm.isAccessDenied) {
      return _buildAccessDeniedState(theme, vm);
    }

    if (vm.isError) {
      return _buildErrorState(theme, vm);
    }

    if (vm.isLoading && vm.profile.displayName.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = vm.profile;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              children: [
                // Avatar & Name Card
                _buildProfileHeader(profile, theme),
                const SizedBox(height: 20),
                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    key: const Key('edit_profile_button'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                    onPressed: widget.onEditProfile,
                  ),
                ),
                const SizedBox(height: 24),
                // Personality Assessment Entry Card
                _buildPersonalityEntryCard(theme),
                const SizedBox(height: 20),
                // Bio & Details Section
                _buildBioCard(profile, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(dynamic profile, ThemeData theme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: const Icon(Icons.person, size: 54),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              child: const Icon(Icons.lock, size: 14, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              profile.displayName.isNotEmpty ? profile.displayName : 'Social Member',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Private Profile',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalityEntryCard(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(128),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.psychology_outlined, color: theme.colorScheme.primary),
        ),
        title: const Text(
          'Personality Quiz',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Discover compatible matches based on shared lifestyle.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: widget.onTakePersonalityQuiz,
      ),
    );
  }

  Widget _buildBioCard(dynamic profile, ThemeData theme) {
    final bioText = profile.bio as String?;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Me',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (bioText != null && bioText.trim().isNotEmpty)
                ? bioText
                : 'No bio added yet. Tell other members about yourself!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: (bioText != null && bioText.trim().isNotEmpty)
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDeniedState(ThemeData theme, SocialProfileManagementViewModel vm) {
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
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => vm.loadProfile(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, SocialProfileManagementViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to Load Profile', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(vm.errorMessage ?? 'An unexpected error occurred.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => vm.loadProfile(refresh: true),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
