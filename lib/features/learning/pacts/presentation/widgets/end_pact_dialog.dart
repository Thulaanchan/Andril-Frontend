import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';

/// Confirmation dialog for ending participation or withdrawing from a Learning Pact (LRN-03).
///
/// Follows design specification ANDRIL_LP_E01:
/// - Explicit withdrawal confirmation.
/// - Clarifies that withdrawal is voluntary and other participants do not need to approve exit.
/// - Minimum 44dp touch targets.
class EndPactDialog extends StatelessWidget {
  final Future<bool> Function() onConfirmEnd;

  const EndPactDialog({
    super.key,
    required this.onConfirmEnd,
  });

  /// Displays the [EndPactDialog].
  static Future<bool?> show(
    BuildContext context, {
    required Future<bool> Function() onConfirmEnd,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EndPactDialog(onConfirmEnd: onConfirmEnd),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('dialog_end_pact_participation'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      contentPadding: const EdgeInsets.all(24.0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 36,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 16.0),

            // Heading
            const Text(
              'End your participation?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),

            // Explanation
            const Text(
              'You can end your own participation after confirmation. Other participants do not need to approve your exit.',
              style: TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),

            // Callout Box
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: Colors.amber.shade900),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'This marks the Pact as cancelled without changing agreed terms.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),

            // Notice Footer
            const Text(
              'XP effects, rewards, and notifications are not defined or awarded.',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: LearningColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44.0,
                    child: OutlinedButton(
                      key: const ValueKey('btn_keep_participating'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LearningColors.secondaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Keep Participating'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: SizedBox(
                    height: 44.0,
                    child: ElevatedButton(
                      key: const ValueKey('btn_confirm_end_participation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: () async {
                        final success = await onConfirmEnd();
                        if (context.mounted) {
                          Navigator.of(context).pop(success);
                        }
                      },
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('End Participation'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
