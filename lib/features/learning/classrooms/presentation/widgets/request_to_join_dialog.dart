import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_classroom.dart';

/// Callback when a user submits a join request for an approval-required classroom.
typedef OnSubmitJoinRequest = void Function(String? note);

/// Dialog allowing a learner to request admission to an approval-required classroom.
class RequestToJoinDialog extends StatefulWidget {
  final LearningClassroom classroom;
  final OnSubmitJoinRequest onSubmit;

  const RequestToJoinDialog({
    super.key,
    required this.classroom,
    required this.onSubmit,
  });

  @override
  State<RequestToJoinDialog> createState() => _RequestToJoinDialogState();
}

class _RequestToJoinDialogState extends State<RequestToJoinDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      actionsPadding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.how_to_reg,
              color: Color(0xFFD97706),
              size: 22.0,
            ),
          ),
          const SizedBox(width: 12.0),
          const Expanded(
            child: Text(
              'Request Admission',
              style: TextStyle(
                fontSize: 17.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Classroom: ${widget.classroom.name}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.0,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Educator / Host: ${widget.classroom.hostDisplayName}',
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16.0,
                    color: Color(0xFF475569),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Admission to this classroom requires host review. Your Learning profile display name will be shared with the host.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF475569),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Statement of Interest / Note (Optional):',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6.0),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 250,
              decoration: InputDecoration(
                hintText:
                    'Share your background, goals, or why you want to join...',
                hintStyle: const TextStyle(fontSize: 12.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(10.0),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final note = _noteController.text.trim();
                widget.onSubmit(note.isEmpty ? null : note);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ],
    );
  }
}
