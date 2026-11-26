import 'package:flutter/material.dart';
import '../group_contracts/social_zone_management.dart';
import 'social_zone_management_viewmodel.dart';

/// Presentation screen for creating a new Social Zone (CF-07 / S47).
///
/// Follows M5 Social Groups Governance:
/// - Uses only approved fields: name, description, category, guidelines, tags, approval requirement.
/// - Does not invent arbitrary member quotas, creation fees, or artificial tier restrictions.
/// - Gracefully surfaces deferred backend availability without manufacturing fake success.
/// - Responsive across 320dp, 400dp, and 800dp viewports.
class SocialCreateZoneScreen extends StatefulWidget {
  final SocialZoneManagementViewModel viewModel;
  final VoidCallback? onBack;
  final VoidCallback? onSuccess;

  const SocialCreateZoneScreen({
    super.key,
    required this.viewModel,
    this.onBack,
    this.onSuccess,
  });

  @override
  State<SocialCreateZoneScreen> createState() => _SocialCreateZoneScreenState();
}

class _SocialCreateZoneScreenState extends State<SocialCreateZoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _ruleController = TextEditingController();
  final _tagController = TextEditingController();

  String _category = 'Technology';
  bool _requiresApproval = false;
  final List<String> _rules = [];
  final List<String> _tags = [];

  static const List<String> _availableCategories = [
    'Technology',
    'Outdoors',
    'Creative Arts',
    'Lifestyle',
    'Literature',
    'Fitness',
  ];

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _ruleController.dispose();
    _tagController.dispose();
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

  void _addTag() {
    final text = _tagController.text.trim().replaceAll('#', '');
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final draft = ZoneManagementDraft(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      rules: _rules,
      tags: _tags,
      requiresApproval: _requiresApproval,
    );

    widget.viewModel.updateDraft(draft);
    final success = await widget.viewModel.createZone();
    if (success && mounted) {
      widget.onSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Zone'),
        leading: widget.onBack != null
            ? IconButton(
                key: const Key('cancel_create_zone_button'),
                icon: const Icon(Icons.close),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (vm.errorMessage != null) ...[
                  Container(
                    key: const Key('create_zone_error_banner'),
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
                Text(
                  'Basic Information',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('create_zone_name_field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Zone Name *',
                    hintText: 'e.g. Flutter Mobile Developers',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('create_zone_category_dropdown'),
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableCategories
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('create_zone_desc_field'),
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'What is the purpose of this community?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Community Rules & Guidelines',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('create_zone_rule_input'),
                        controller: _ruleController,
                        decoration: const InputDecoration(
                          hintText: 'Add a community rule',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('add_rule_button'),
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
                const SizedBox(height: 24),
                Text(
                  'Tags & Discovery',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('create_zone_tag_input'),
                        controller: _tagController,
                        decoration: const InputDecoration(
                          hintText: 'Add a topic tag (e.g. coding)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('add_tag_button'),
                      icon: const Icon(Icons.add),
                      onPressed: _addTag,
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _tags.asMap().entries.map((e) => Chip(
                          label: Text('#${e.value}'),
                          onDeleted: () => _removeTag(e.key),
                        )).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                SwitchListTile(
                  key: const Key('create_zone_approval_switch'),
                  title: const Text('Require Host Approval to Join'),
                  subtitle: const Text('Members must be reviewed before joining'),
                  value: _requiresApproval,
                  onChanged: (val) => setState(() => _requiresApproval = val),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  key: const Key('submit_create_zone_button'),
                  onPressed: vm.isSubmitting ? null : _submit,
                  icon: vm.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Create Zone'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
