import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_circle.dart';

/// Modal bottom sheet presenting Circle details, members, and collaborative goals (CF-07, LRN-02).
///
/// Features:
/// - Circle title, category badge, and facilitator info.
/// - Full description.
/// - Collaborative Shared Goals list with self-reported progress bars (0..100).
/// - Enrolled members can add shared goals and update self-reported goal progress.
/// - Action button to Join or Leave Circle.
/// - Accessible >= 44dp touch targets.
class CircleDetailsSheet extends StatefulWidget {
  final LearningCircle circle;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final Future<bool> Function(String goalText)? onAddGoal;
  final Future<bool> Function(String goalId, int progressPercent)?
      onUpdateGoalProgress;

  const CircleDetailsSheet({
    super.key,
    required this.circle,
    this.onJoin,
    this.onLeave,
    this.onAddGoal,
    this.onUpdateGoalProgress,
  });

  /// Displays the [CircleDetailsSheet].
  static Future<void> show(
    BuildContext context, {
    required LearningCircle circle,
    VoidCallback? onJoin,
    VoidCallback? onLeave,
    Future<bool> Function(String goalText)? onAddGoal,
    Future<bool> Function(String goalId, int progressPercent)?
        onUpdateGoalProgress,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CircleDetailsSheet(
        circle: circle,
        onJoin: onJoin,
        onLeave: onLeave,
        onAddGoal: onAddGoal,
        onUpdateGoalProgress: onUpdateGoalProgress,
      ),
    );
  }

  @override
  State<CircleDetailsSheet> createState() => _CircleDetailsSheetState();
}

class _CircleDetailsSheetState extends State<CircleDetailsSheet> {
  final TextEditingController _newGoalController = TextEditingController();
  bool _isAddingGoal = false;

  @override
  void dispose() {
    _newGoalController.dispose();
    super.dispose();
  }

  void _showAddGoalDialog() {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Shared Goal'),
        content: TextField(
          key: const ValueKey('input_new_shared_goal'),
          controller: _newGoalController,
          decoration: const InputDecoration(
            hintText: 'e.g., Read chapter 4 & create summary notes',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const ValueKey('btn_confirm_add_shared_goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: LearningColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final text = _newGoalController.text.trim();
              if (text.isNotEmpty && widget.onAddGoal != null) {
                Navigator.of(dialogCtx).pop(true);
                setState(() => _isAddingGoal = true);
                await widget.onAddGoal!(text);
                _newGoalController.clear();
                if (mounted) setState(() => _isAddingGoal = false);
              }
            },
            child: const Text('Add Goal'),
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressDialog(CircleSharedGoal goal) {
    int selectedProgress = goal.progressPercent;

    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Update Reported Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Self-Reported: $selectedProgress%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.primary,
                ),
              ),
              Slider(
                key: const ValueKey('slider_goal_progress'),
                value: selectedProgress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$selectedProgress%',
                activeColor: LearningColors.primary,
                onChanged: (val) {
                  setDialogState(() => selectedProgress = val.round());
                },
              ),
              const Text(
                'Note: Progress is manually reported for peer study tracking.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const ValueKey('btn_save_goal_progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop(true);
                if (widget.onUpdateGoalProgress != null) {
                  await widget.onUpdateGoalProgress!(
                    goal.id,
                    selectedProgress,
                  );
                }
              },
              child: const Text('Save Progress'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final circle = widget.circle;

    return Container(
      key: const ValueKey('sheet_circle_details'),
      decoration: const BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),

              // Category Badge & Close button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: LearningColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      circle.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: LearningColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              // Circle Title
              Text(
                circle.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 8.0),

              // Facilitator and Member count
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: LearningColors.secondaryText,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Facilitator: ${circle.facilitatorDisplayName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: LearningColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  const Icon(
                    Icons.groups_outlined,
                    size: 16,
                    color: LearningColors.secondaryText,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '${circle.memberCount} members',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: LearningColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Mission / Description
              const Text(
                'Study Mission',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                circle.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: LearningColors.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20.0),

              // Collaborative Shared Goals Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Collaborative Goals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: LearningColors.heading,
                    ),
                  ),
                  if (circle.isMember)
                    TextButton.icon(
                      key: const ValueKey('btn_add_shared_goal'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Goal'),
                      onPressed: _isAddingGoal ? null : _showAddGoalDialog,
                    ),
                ],
              ),
              const SizedBox(height: 8.0),

              // Goals List
              if (circle.goals.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Text(
                    'No collaborative goals added yet. Enrolled members can propose study milestones.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: LearningColors.secondaryText,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: circle.goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10.0),
                  itemBuilder: (ctx, index) {
                    final goal = circle.goals[index];
                    return Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: LearningColors.background,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  goal.text,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: LearningColors.heading,
                                  ),
                                ),
                              ),
                              Text(
                                '${goal.progressPercent}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: goal.isCompleted
                                      ? const Color(0xFF15803D)
                                      : LearningColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: LinearProgressIndicator(
                              value: goal.progressPercent / 100.0,
                              minHeight: 6.0,
                              backgroundColor: Colors.white,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                goal.isCompleted
                                    ? const Color(0xFF15803D)
                                    : LearningColors.primary,
                              ),
                            ),
                          ),
                          if (circle.isMember) ...[
                            const SizedBox(height: 8.0),
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                key: ValueKey('btn_update_progress_${goal.id}'),
                                onTap: () => _showUpdateProgressDialog(goal),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                    vertical: 4.0,
                                  ),
                                  child: Text(
                                    'Update Progress',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: LearningColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24.0),

              // Bottom Action Button (min 44dp height)
              SizedBox(
                width: double.infinity,
                height: 48.0,
                child: circle.canJoin
                    ? ElevatedButton(
                        key: ValueKey('btn_sheet_join_${circle.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LearningColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onJoin?.call();
                        },
                        child: const Text('Join Circle'),
                      )
                    : OutlinedButton(
                        key: ValueKey('btn_sheet_leave_${circle.id}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onLeave?.call();
                        },
                        child: const Text('Leave Circle'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
