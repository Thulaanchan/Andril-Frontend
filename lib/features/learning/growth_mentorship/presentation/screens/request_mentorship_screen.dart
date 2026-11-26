import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_mentorship.dart';
import '../viewmodels/learning_mentorship_viewmodel.dart';

/// Screen allowing a learner to initiate a voluntary mentorship request (LRN-04, GRW-01-05).
///
/// Features:
/// 1. Volunteer mentor details card.
/// 2. Learning goal and introductory message fields.
/// 3. Clear notice: request stays in Learning and activates ONLY on mentor agreement.
/// 4. Interactive touch targets $\ge 44\text{dp}$.
/// 5. Responsive layout across 320dp, 360dp, 412dp viewports and 1.5x font scale.
class RequestMentorshipScreen extends StatefulWidget {
  final LearningMentorshipViewModel viewModel;
  final LearningMentorshipOffer offer;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const RequestMentorshipScreen({
    super.key,
    required this.viewModel,
    required this.offer,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<RequestMentorshipScreen> createState() =>
      _RequestMentorshipScreenState();
}

class _RequestMentorshipScreenState extends State<RequestMentorshipScreen> {
  late final TextEditingController _goalController;
  late final TextEditingController _messageController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _goalController =
        TextEditingController(text: 'Build better Flutter interfaces');
    _messageController = TextEditingController(
      text:
          'Hello! I would like guidance on building accessible Flutter layouts. Would you be open to mentoring me?',
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final goal = _goalController.text.trim();
    final message = _messageController.text.trim();
    if (goal.isEmpty || message.isEmpty) return;

    setState(() => _isSubmitting = true);

    final success = await widget.viewModel.sendMentorshipRequest(
      offer: widget.offer,
      learningGoal: goal,
      message: message,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.of(context).maybePop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMentorCard(),
              const SizedBox(height: 16.0),
              _buildGoalCard(),
              const SizedBox(height: 16.0),
              _buildMessageCard(),
              const SizedBox(height: 16.0),
              _buildNoticeBox(),
              const SizedBox(height: 24.0),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        key: const ValueKey('btn_request_mentorship_back'),
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onCancel ?? () => Navigator.of(context).maybePop(),
        tooltip: 'Back',
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Request Mentorship',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          Text(
            'Send a request to a volunteer mentor.',
            style: TextStyle(
              fontSize: 12,
              color: LearningColors.secondaryText,
            ),
          ),
        ],
      ),
      backgroundColor: LearningColors.cardSurface,
      elevation: 0,
      iconTheme: const IconThemeData(color: LearningColors.heading),
    );
  }

  Widget _buildMentorCard() {
    final mentor = widget.offer.mentor;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Text(
              mentor.displayName.isNotEmpty ? mentor.displayName[0] : 'M',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: LearningColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mentor.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LearningColors.heading,
                  ),
                ),
                const SizedBox(height: 4.0),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_outlined,
                              size: 12, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 4.0),
                          Text(
                            'Volunteer Mentor',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.offer.specialtyTopics.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          widget.offer.specialtyTopics.first,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.track_changes,
                  size: 18, color: LearningColors.primary),
              SizedBox(width: 8.0),
              Text(
                'Your learning goal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          TextField(
            key: const ValueKey('input_learning_goal'),
            controller: _goalController,
            decoration: InputDecoration(
              hintText: 'e.g. Build better Flutter interfaces',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 18, color: Color(0xFF7C3AED)),
              SizedBox(width: 8.0),
              Text(
                'Message to mentor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          TextField(
            key: const ValueKey('input_mentor_message'),
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Introduce yourself and describe what guidance you seek...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBox() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Color(0xFF1D4ED8)),
          SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Your request stays within Learning. Mentorship starts only if the mentor agrees.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E40AF),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48.0,
            child: OutlinedButton(
              key: const ValueKey('btn_cancel_request_flow'),
              onPressed:
                  widget.onCancel ?? () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: LearningColors.secondaryText,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: SizedBox(
            height: 48.0,
            child: ElevatedButton(
              key: const ValueKey('btn_submit_request'),
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.heading,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Send Request'),
            ),
          ),
        ),
      ],
    );
  }
}
