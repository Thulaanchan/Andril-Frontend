import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_mentorship.dart';
import '../viewmodels/learning_mentorship_viewmodel.dart';

/// Screen displaying the status, timeline, and mutual terms of a [LearningMentorship] (LRN-04, GRW-01-05).
///
/// Features:
/// 1. Agreement banner when accepted ('Mentorship agreed').
/// 2. Two-column participant presentation (Learner & Mentor).
/// 3. Agreed learning goal and request summary.
/// 4. Step-by-step agreement timeline with checkmarks.
/// 5. Pending and declined state representations.
/// 6. Interactive actions (Accept, Decline, Cancel) guarded by participant roles.
/// 7. Responsive layout across 320dp, 360dp, 412dp viewports and 1.5x font scale.
class MentorshipAgreementScreen extends StatefulWidget {
  final LearningMentorshipViewModel viewModel;
  final String mentorshipId;
  final VoidCallback? onBack;

  const MentorshipAgreementScreen({
    super.key,
    required this.viewModel,
    required this.mentorshipId,
    this.onBack,
  });

  @override
  State<MentorshipAgreementScreen> createState() =>
      _MentorshipAgreementScreenState();
}

class _MentorshipAgreementScreenState extends State<MentorshipAgreementScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  LearningMentorship? get _mentorship => widget.viewModel.mentorships
      .where((m) => m.id == widget.mentorshipId)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final mentorship = _mentorship;
    if (mentorship == null) {
      return Scaffold(
        backgroundColor: LearningColors.background,
        appBar: AppBar(
          title: const Text('Mentorship Details'),
          backgroundColor: LearningColors.cardSurface,
        ),
        body: const Center(child: Text('Mentorship not found.')),
      );
    }

    final isAccepted = mentorship.status.isAccepted;
    final isPending = mentorship.status.isPending;

    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: _buildAppBar(mentorship),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAccepted) _buildAgreedBanner(),
              if (isPending) _buildPendingBanner(),
              if (mentorship.status.isDeclined) _buildDeclinedBanner(),
              if (mentorship.status.isCancelled) _buildCancelledBanner(),
              const SizedBox(height: 16.0),
              _buildParticipantsCard(mentorship),
              const SizedBox(height: 16.0),
              _buildGoalCard(mentorship),
              const SizedBox(height: 16.0),
              _buildMessageSummaryCard(mentorship),
              const SizedBox(height: 16.0),
              _buildTimelineCard(mentorship),
              const SizedBox(height: 16.0),
              _buildNoticeBox(),
              const SizedBox(height: 24.0),
              _buildActionSection(mentorship),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(LearningMentorship mentorship) {
    final title = mentorship.status.isAccepted
        ? 'Mentorship Agreement'
        : mentorship.status.isPending
            ? 'Mentorship Request Pending'
            : 'Mentorship Details';
    final subtitle = mentorship.status.isAccepted
        ? 'Review your mutually agreed learning goal.'
        : mentorship.status.isPending
            ? 'Your request is awaiting the volunteer mentor\'s response.'
            : 'Mentorship request details';

    return AppBar(
      leading: IconButton(
        key: const ValueKey('btn_agreement_back'),
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        tooltip: 'Back',
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
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

  Widget _buildAgreedBanner() {
    return Container(
      key: const ValueKey('banner_mentorship_agreed'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Color(0xFF15803D), size: 22),
          SizedBox(width: 8.0),
          Text(
            'Mentorship agreed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      key: const ValueKey('banner_mentorship_pending'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, color: Color(0xFFB45309), size: 20),
          SizedBox(width: 8.0),
          Text(
            'Awaiting Mentor Response',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclinedBanner() {
    return Container(
      key: const ValueKey('banner_mentorship_declined'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel_outlined, color: Colors.grey, size: 20),
          SizedBox(width: 8.0),
          Text(
            'Mentorship Declined',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledBanner() {
    return Container(
      key: const ValueKey('banner_mentorship_cancelled'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_circle_outline, color: Colors.grey, size: 20),
          SizedBox(width: 8.0),
          Text(
            'Request Cancelled',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsCard(LearningMentorship mentorship) {
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
              Icon(Icons.people_outline,
                  size: 18, color: LearningColors.primary),
              SizedBox(width: 8.0),
              Text(
                'Participants',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              // Learner
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFDBEAFE),
                      child: Text(
                        mentorship.learner.displayName.isNotEmpty
                            ? mentorship.learner.displayName[0]
                            : 'Y',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mentorship.learner.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: LearningColors.heading,
                            ),
                          ),
                          const Text(
                            'Learner',
                            style: TextStyle(
                              fontSize: 11,
                              color: LearningColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
              ),
              // Mentor
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFDCFCE7),
                      child: Text(
                        mentorship.mentor.displayName.isNotEmpty
                            ? mentorship.mentor.displayName[0]
                            : 'M',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mentorship.mentor.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: LearningColors.heading,
                            ),
                          ),
                          const Text(
                            'Volunteer Mentor',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(LearningMentorship mentorship) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes,
                  size: 18, color: LearningColors.primary),
              const SizedBox(width: 8.0),
              Text(
                mentorship.status.isAccepted
                    ? 'Agreed learning goal'
                    : 'Learning goal',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              mentorship.learningGoal,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSummaryCard(LearningMentorship mentorship) {
    return Container(
      width: double.infinity,
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
                'Request summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            mentorship.message,
            style: const TextStyle(
              fontSize: 13,
              color: LearningColors.secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(LearningMentorship mentorship) {
    final isAccepted = mentorship.status.isAccepted;

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
              Icon(Icons.timeline_outlined,
                  size: 18, color: LearningColors.primary),
              SizedBox(width: 8.0),
              Text(
                'Agreement Timeline',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildTimelineRow(
                      icon: Icons.check_circle,
                      iconColor: const Color(0xFF15803D),
                      title: 'Request sent by learner',
                      subtitle: mentorship.learner.displayName,
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 10.0),
                      alignment: Alignment.centerLeft,
                      height: 20.0,
                      width: 2.0,
                      color: isAccepted
                          ? const Color(0xFF15803D)
                          : Colors.grey.shade300,
                    ),
                    _buildTimelineRow(
                      icon: isAccepted
                          ? Icons.check_circle
                          : Icons.access_time_filled,
                      iconColor: isAccepted
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB45309),
                      title: isAccepted
                          ? 'Accepted by volunteer mentor'
                          : 'Mentor response pending',
                      subtitle: mentorship.mentor.displayName,
                    ),
                  ],
                ),
              ),
              if (isAccepted) ...[
                const SizedBox(width: 12.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.handshake_outlined,
                          size: 28, color: Color(0xFF15803D)),
                      SizedBox(height: 4.0),
                      Text(
                        'Both agreed',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
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
              'This mentorship stays within Learning. Only authorized participants can access it.',
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

  Widget _buildActionSection(LearningMentorship mentorship) {
    final isLearner = widget.viewModel.currentProfileId ==
        mentorship.learner.learningProfileId;
    final isMentor = widget.viewModel.currentProfileId ==
        mentorship.mentor.learningProfileId;

    if (mentorship.status.isPending) {
      if (isLearner) {
        return SizedBox(
          width: double.infinity,
          height: 48.0,
          child: OutlinedButton(
            key: const ValueKey('btn_cancel_mentorship_request'),
            onPressed: () => widget.viewModel.cancelMentorship(mentorship.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Cancel Request'),
          ),
        );
      } else if (isMentor) {
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48.0,
                child: OutlinedButton(
                  key: const ValueKey('btn_decline_mentorship'),
                  onPressed: () =>
                      widget.viewModel.declineMentorship(mentorship.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: SizedBox(
                height: 48.0,
                child: ElevatedButton(
                  key: const ValueKey('btn_accept_mentorship'),
                  onPressed: () =>
                      widget.viewModel.acceptMentorship(mentorship.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Accept Agreement'),
                ),
              ),
            ),
          ],
        );
      }
    }

    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: ElevatedButton(
        key: const ValueKey('btn_return_mentorship_hub'),
        onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: LearningColors.heading,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: const Text('Back to Mentorship'),
      ),
    );
  }
}
