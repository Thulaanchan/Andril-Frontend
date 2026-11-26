import 'package:flutter/material.dart';
import '../viewmodels/social_profile_draft.dart';
import '../viewmodels/social_profile_management_viewmodel.dart';

/// Presentation screen for editing the caller's private Social profile (S32 Edit Social Profile).
///
/// Follows M5 Profile Management Governance:
/// - Only permits editing approved fields: display name and biography.
/// - Visibility is locked strictly to 'private'.
/// - Uses standard validation rules matching backend contract constraints.
/// - Warns on unsaved changes when cancelling.
/// - Responsive layout supporting 320dp, 400dp, and 800dp viewports.
class SocialEditProfileScreen extends StatefulWidget {
  final SocialProfileManagementViewModel viewModel;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const SocialEditProfileScreen({
    super.key,
    required this.viewModel,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<SocialEditProfileScreen> createState() => _SocialEditProfileScreenState();
}

class _SocialEditProfileScreenState extends State<SocialEditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.viewModel.draft.displayName);
    _bioController = TextEditingController(text: widget.viewModel.draft.bio ?? '');
    widget.viewModel.addListener(_onViewModelChanged);

    _nameController.addListener(() {
      widget.viewModel.updateDisplayName(_nameController.text);
    });
    _bioController.addListener(() {
      widget.viewModel.updateBio(_bioController.text);
    });
  }

  @override
  void didUpdateWidget(covariant SocialEditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      widget.viewModel.addListener(_onViewModelChanged);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
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

    final nameError = vm.draft.displayName.isNotEmpty && vm.draft.displayNameError != null
        ? vm.draft.displayNameError
        : null;

    final bioError = vm.draft.bio != null && vm.draft.bioError != null
        ? vm.draft.bioError
        : null;

    return PopScope(
      canPop: !vm.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && vm.hasUnsavedChanges) {
          _confirmDiscard(context, vm);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: () {
              if (vm.hasUnsavedChanges) {
                _confirmDiscard(context, vm);
              } else {
                widget.onCancel?.call();
                Navigator.of(context).maybePop();
              }
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                key: const Key('save_profile_button'),
                onPressed: vm.canSave
                    ? () async {
                        final success = await vm.saveProfile();
                        if (success && mounted) {
                          widget.onSaved?.call();
                          Navigator.of(context).maybePop();
                        }
                      }
                    : null,
                child: vm.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vm.errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            vm.errorMessage!,
                            style: TextStyle(color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Display Name Field
                      Text(
                        'Display Name',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        key: const Key('display_name_field'),
                        controller: _nameController,
                        maxLength: SocialProfileDraft.maxDisplayNameLength,
                        decoration: InputDecoration(
                          hintText: 'Enter your name or nickname',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          errorText: nameError,
                          counterText: '${_nameController.text.characters.length}/${SocialProfileDraft.maxDisplayNameLength}',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Biography Field
                      Text(
                        'About Me',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        key: const Key('bio_field'),
                        controller: _bioController,
                        maxLines: 4,
                        maxLength: SocialProfileDraft.maxBioLength,
                        decoration: InputDecoration(
                          hintText: 'Share a little about yourself, your hobbies, and what you are looking for...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          errorText: bioError,
                          counterText: '${_bioController.text.characters.length}/${SocialProfileDraft.maxBioLength}',
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Privacy information badge
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(64)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.privacy_tip_outlined, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Profile visibility is private by default and visible only to verified eligible Social members.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmDiscard(BuildContext context, SocialProfileManagementViewModel vm) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              vm.discardEdits();
              widget.onCancel?.call();
              Navigator.of(context).maybePop();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}
