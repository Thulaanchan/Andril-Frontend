import 'package:flutter/material.dart';
import '../group_contracts/social_zone.dart';
import '../group_contracts/social_zone_management.dart';
import 'social_zone_management_viewmodel.dart';

/// Presentation screen for Zone host management and settings.
///
/// Follows M5 Social Groups Governance:
/// - Accessible only when backed by authoritative [ZonePermissionEvidence] (`canManageZone`).
/// - Surfaces deferred backend availability without inventing unapproved deletion or mass-removal policies.
/// - Allows editing zone description, rules, and reviewing membership approval settings.
/// - Responsive across 320dp, 400dp, and 800dp viewports.
class SocialZoneManagementScreen extends StatefulWidget {
  final SocialZone zone;
  final SocialZoneManagementViewModel viewModel;
  final VoidCallback? onBack;
  final VoidCallback? onManageMembers;
  final VoidCallback? onModerateZone;

  const SocialZoneManagementScreen({
    super.key,
    required this.zone,
    required this.viewModel,
    this.onBack,
    this.onManageMembers,
    this.onModerateZone,
  });

  @override
  State<SocialZoneManagementScreen> createState() => _SocialZoneManagementScreenState();
}

class _SocialZoneManagementScreenState extends State<SocialZoneManagementScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  final TextEditingController _ruleController = TextEditingController();

  late String _category;
  late bool _requiresApproval;
  late final List<String> _rules;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.zone.name);
    _descController = TextEditingController(text: widget.zone.description);
    _category = widget.zone.category;
    _requiresApproval = widget.zone.requiresApproval;
    _rules = List<String>.from(widget.zone.rules);

    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _ruleController.dispose();
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  void _addRule() {
    final text = _ruleController.text.trim();
    if (text.isNotEmpty && !_rules.contains(text)) {
      setState(() {
        _rules.add(text);
        _ruleController.clear();
      });
    }
  }

  void _removeRule(int index) {
    setState(() {
      _rules.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    final draft = ZoneManagementDraft(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      rules: _rules,
      tags: widget.zone.tags,
      requiresApproval: _requiresApproval,
    );

    widget.viewModel.updateDraft(draft);
    await widget.viewModel.updateZone(widget.zone.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.viewModel;
    final evidence = vm.permissionEvidence;
    final canManage = evidence?.canManageZone ?? false;

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Zone Management')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gpp_bad, size: 56, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Management Restricted', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Only verified Zone hosts possess authority to manage zone settings.',
                  textAlign: TextAlign.center,
                ),
                if (widget.onBack != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    key: const Key('management_back_button'),
                    onPressed: widget.onBack,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.zone.name}'),
        leading: widget.onBack != null
            ? IconButton(
                key: const Key('management_close_button'),
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (vm.errorMessage != null) ...[
                Container(
                  key: const Key('management_error_banner'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          vm.errorMessage!,
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('Zone Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                key: const Key('edit_zone_name_field'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Zone Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('edit_zone_desc_field'),
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              Text('Membership Governance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SwitchListTile(
                key: const Key('edit_zone_approval_switch'),
                title: const Text('Require Host Approval'),
                subtitle: const Text('Pending members must be approved manually'),
                value: _requiresApproval,
                onChanged: (val) => setState(() => _requiresApproval = val),
              ),
              if (widget.onManageMembers != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  key: const Key('manage_members_tile'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: theme.colorScheme.surfaceContainerHighest.withAlpha(64),
                  leading: const Icon(Icons.people_alt_outlined),
                  title: const Text('Manage Members & Roles'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.onManageMembers,
                ),
              ],
              if (widget.onModerateZone != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  key: const Key('zone_moderation_tile'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: theme.colorScheme.surfaceContainerHighest.withAlpha(64),
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Zone Moderation & Requests'),
                  subtitle: const Text('Review join requests and manage zone activity'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.onModerateZone,
                ),
              ],
              const SizedBox(height: 24),
              Text('Community Guidelines', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('edit_rule_input'),
                      controller: _ruleController,
                      decoration: const InputDecoration(hintText: 'Add rule', border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('add_rule_edit_button'),
                    icon: const Icon(Icons.add),
                    onPressed: _addRule,
                  ),
                ],
              ),
              if (_rules.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._rules.asMap().entries.map((e) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text('${e.key + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                      title: Text(e.value),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeRule(e.key),
                      ),
                    )),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                key: const Key('save_zone_changes_button'),
                onPressed: vm.isSubmitting ? null : _saveChanges,
                icon: vm.isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
