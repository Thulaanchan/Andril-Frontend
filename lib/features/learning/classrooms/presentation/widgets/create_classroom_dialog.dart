import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_classroom.dart';

/// Modal dialog for authoritatively creating a new Learning Classroom as host (CF-06, CF-07).
///
/// Features:
/// - Classroom name input (required).
/// - Curriculum description input (required).
/// - Subject category selection.
/// - Privacy model selection (Public, Approval Required, Private).
/// - Optional learner capacity.
/// - Optional comma-separated tags.
/// - Accessible >= 44dp touch targets.
class CreateClassroomDialog extends StatefulWidget {
  final Future<bool> Function({
    required String name,
    required String description,
    required String category,
    required ClassroomPrivacy privacy,
    int? capacity,
    List<String> tags,
  }) onCreate;

  const CreateClassroomDialog({
    super.key,
    required this.onCreate,
  });

  /// Displays the [CreateClassroomDialog] modal.
  static Future<bool?> show(
    BuildContext context, {
    required Future<bool> Function({
      required String name,
      required String description,
      required String category,
      required ClassroomPrivacy privacy,
      int? capacity,
      List<String> tags,
    }) onCreate,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateClassroomDialog(onCreate: onCreate),
    );
  }

  @override
  State<CreateClassroomDialog> createState() => _CreateClassroomDialogState();
}

class _CreateClassroomDialogState extends State<CreateClassroomDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String _selectedCategory = 'Programming';
  ClassroomPrivacy _selectedPrivacy = ClassroomPrivacy.public;
  bool _isCreating = false;
  String? _errorMessage;

  final List<String> _categories = const [
    'Programming',
    'Design',
    'Languages',
    'Business',
    'Mathematics',
    'General',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _capacityController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final capacity = int.tryParse(_capacityController.text.trim());

    try {
      final success = await widget.onCreate(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        privacy: _selectedPrivacy,
        capacity: capacity,
        tags: tags,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _isCreating = false;
            _errorMessage = 'Could not create classroom. Please try again.';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _errorMessage = 'An error occurred while creating classroom.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: LearningColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: LearningColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Classroom',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: LearningColors.heading,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Set up a learning space as host/educator',
                            style: TextStyle(
                              fontSize: 12,
                              color: LearningColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Error message banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Name field
                TextFormField(
                  key: const ValueKey('input_classroom_name'),
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Classroom Name *',
                    hintText: 'e.g. Advanced Kotlin & Coroutines',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Classroom name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Description field
                TextFormField(
                  key: const ValueKey('input_classroom_desc'),
                  controller: _descController,
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Description / Curriculum *',
                    hintText: 'Describe learning goals, schedule, and syllabus',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Category dropdown
                DropdownButtonFormField<String>(
                  key: const ValueKey('dropdown_classroom_category'),
                  isExpanded: true,
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Subject Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 14),

                // Privacy dropdown
                DropdownButtonFormField<ClassroomPrivacy>(
                  key: const ValueKey('dropdown_classroom_privacy'),
                  isExpanded: true,
                  initialValue: _selectedPrivacy,
                  decoration: InputDecoration(
                    labelText: 'Privacy & Admission Model',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ClassroomPrivacy.public,
                      child: Text('Public (Instant Enrollment)'),
                    ),
                    DropdownMenuItem(
                      value: ClassroomPrivacy.requestToJoin,
                      child: Text('Approval Required (Host Decides)'),
                    ),
                    DropdownMenuItem(
                      value: ClassroomPrivacy.closed,
                      child: Text('Private (Invitation Only)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPrivacy = val);
                  },
                ),
                const SizedBox(height: 14),

                // Capacity field (optional)
                TextFormField(
                  key: const ValueKey('input_classroom_capacity'),
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Max Learner Capacity (Optional)',
                    hintText: 'e.g. 50',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Tags field (optional)
                TextFormField(
                  key: const ValueKey('input_classroom_tags'),
                  controller: _tagsController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Tags (Optional, comma-separated)',
                    hintText: 'e.g. Kotlin, Coroutines, Mobile',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isCreating
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(80, 44),
                        foregroundColor: LearningColors.secondaryText,
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      key: const ValueKey('btn_submit_classroom'),
                      onPressed: _isCreating ? null : _handleCreate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LearningColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(110, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
