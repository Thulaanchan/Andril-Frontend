import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';

/// Modal dialog for authoritatively creating a new Learning Circle (CF-07, LRN-02).
///
/// Features:
/// - Circle name input (required).
/// - Description / mission input (required).
/// - Subject category selection.
/// - Optional initial collaborative goal input.
/// - Accessible >= 44dp touch targets.
class CreateCircleDialog extends StatefulWidget {
  final Future<bool> Function({
    required String name,
    required String description,
    required String category,
    String? initialGoalText,
  }) onCreate;

  const CreateCircleDialog({
    super.key,
    required this.onCreate,
  });

  /// Displays the [CreateCircleDialog] modal.
  static Future<bool?> show(
    BuildContext context, {
    required Future<bool> Function({
      required String name,
      required String description,
      required String category,
      String? initialGoalText,
    }) onCreate,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateCircleDialog(onCreate: onCreate),
    );
  }

  @override
  State<CreateCircleDialog> createState() => _CreateCircleDialogState();
}

class _CreateCircleDialogState extends State<CreateCircleDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  String _selectedCategory = 'Programming';
  bool _isCreating = false;
  String? _errorMessage;

  final List<String> _categories = const [
    'Programming',
    'System Design',
    'Algorithms',
    'Design',
    'Data Science',
    'Mobile Dev',
    'Languages',
    'General',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.onCreate(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        initialGoalText: _goalController.text.trim().isNotEmpty
            ? _goalController.text.trim()
            : null,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _isCreating = false;
            _errorMessage = 'Could not create circle. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _errorMessage = 'An error occurred while creating circle.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey('dialog_create_circle'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: LearningColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: LearningColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      const Expanded(
                        child: Text(
                          'Create Learning Circle',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: LearningColors.heading,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Circle Name Field
                  const Text(
                    'Circle Name *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LearningColors.heading,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  TextFormField(
                    key: const ValueKey('input_circle_name'),
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Mobile Systems Architecture',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: LearningColors.secondaryText,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Circle name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12.0),

                  // Category Selection Dropdown
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LearningColors.heading,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('select_circle_category'),
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 10.0,
                      ),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12.0),

                  // Description Field
                  const Text(
                    'Description / Study Mission *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LearningColors.heading,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  TextFormField(
                    key: const ValueKey('input_circle_description'),
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Describe what your circle aims to learn, practice, or build together...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: LearningColors.secondaryText,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Circle description is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12.0),

                  // Optional First Goal Field
                  const Text(
                    'Initial Collaborative Goal (Optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LearningColors.heading,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  TextFormField(
                    key: const ValueKey('input_circle_initial_goal'),
                    controller: _goalController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Complete Chapter 3 & review PRs',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: LearningColors.secondaryText,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12.0),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20.0),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 44.0,
                        child: TextButton(
                          key: const ValueKey('btn_cancel_create_circle'),
                          onPressed: _isCreating
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      SizedBox(
                        height: 44.0,
                        child: ElevatedButton(
                          key: const ValueKey('btn_submit_create_circle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LearningColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          onPressed: _isCreating ? null : _handleCreate,
                          child: _isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create Circle'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
