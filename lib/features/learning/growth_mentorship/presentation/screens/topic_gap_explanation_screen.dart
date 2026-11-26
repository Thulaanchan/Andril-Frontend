import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_topic_gap.dart';
import '../viewmodels/learning_topic_gap_viewmodel.dart';

/// Screen displaying an objective, evidence-grounded Topic Gap Explanation (LRN-04, GRW-01-05).
///
/// Features:
/// 1. Topic header with private indicator ('Learning only • Private').
/// 2. Reviewed evidence artifacts chips list.
/// 3. Contextual narrative ('Why this topic?').
/// 4. Constructive 'Suggested next step'.
/// 5. Insufficient evidence state handling with governance notice.
/// 6. Fully responsive across 320dp, 360dp, 412dp viewports and 1.5x dynamic font scale.
class TopicGapExplanationScreen extends StatefulWidget {
  final LearningTopicGapViewModel viewModel;
  final VoidCallback? onBack;
  final VoidCallback? onExploreMentorship;

  const TopicGapExplanationScreen({
    super.key,
    required this.viewModel,
    this.onBack,
    this.onExploreMentorship,
  });

  @override
  State<TopicGapExplanationScreen> createState() =>
      _TopicGapExplanationScreenState();
}

class _TopicGapExplanationScreenState extends State<TopicGapExplanationScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);

    if (widget.viewModel.status == TopicGapViewStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.viewModel.initialize();
      });
    }
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        key: const ValueKey('btn_topic_gap_back'),
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        tooltip: 'Back',
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Topic Gap Explanation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          Text(
            'Understand a suggested area for learning based on your evidence.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
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

  Widget _buildBody() {
    switch (widget.viewModel.status) {
      case TopicGapViewStatus.initial:
      case TopicGapViewStatus.loading:
        return const Center(
          child: CircularProgressIndicator(
            key: ValueKey('loading_indicator'),
          ),
        );

      case TopicGapViewStatus.accessDenied:
        return _buildAccessDeniedState();

      case TopicGapViewStatus.unavailableService:
        return _buildUnavailableState();

      case TopicGapViewStatus.error:
        return _buildErrorState();

      case TopicGapViewStatus.empty:
        return _buildEmptyState();

      case TopicGapViewStatus.insufficientEvidence:
        return _buildInsufficientEvidenceView();

      case TopicGapViewStatus.ready:
        return _buildReadyView();
    }
  }

  Widget _buildAccessDeniedState() {
    return Center(
      key: const ValueKey('state_access_denied'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline,
                  size: 48, color: Colors.red.shade700),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ??
                  'Authentication and an activated Learning profile are required.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableState() {
    return Center(
      key: const ValueKey('state_unavailable'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_outlined,
                  size: 48, color: Colors.amber.shade700),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Topic Gap Service Unavailable',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ??
                  LearningTopicGap.disconnectedNotice,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              key: const ValueKey('btn_retry_unavailable'),
              onPressed: () => widget.viewModel.initialize(force: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 44),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('state_error'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 48, color: Colors.red.shade700),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Unable to Load Topic Gap',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              key: const ValueKey('btn_retry_error'),
              onPressed: () => widget.viewModel.initialize(force: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 44),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('view_topic_gap_empty'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 48, color: LearningColors.primary),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'No Topic Gaps Identified',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Your recorded evidence does not currently suggest any specific topic gap.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsufficientEvidenceView() {
    final gap = widget.viewModel.topicGap;

    return SingleChildScrollView(
      key: const ValueKey('view_insufficient_evidence'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insufficient Evidence Notice Banner
          Container(
            key: const ValueKey('banner_insufficient_evidence'),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 24, color: Color(0xFFB45309)),
                SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insufficient Evidence',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        LearningTopicGap.insufficientEvidenceNotice,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF78350F),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Suggested Next Step Card
          _buildCard(
            icon: Icons.lightbulb_outline,
            iconColor: const Color(0xFFD97706),
            title: 'Suggested Next Step',
            child: Text(
              gap?.suggestedNextStep ??
                  'Record self-reported practice reflections or complete learning pact activities to substantiate evidence.',
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          // Primary return button
          SizedBox(
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton.icon(
              key: const ValueKey('btn_return_growth'),
              onPressed:
                  widget.onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Learning Growth'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyView() {
    final gap = widget.viewModel.topicGap;
    if (gap == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      key: const ValueKey('view_topic_gap_ready'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Suggested Topic Header Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(
                    Icons.laptop_mac_outlined,
                    size: 28,
                    color: LearningColors.primary,
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Suggested topic to review',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: LearningColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        gap.topicTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: LearningColors.heading,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        key: const ValueKey('chip_private_learning'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline,
                                size: 12, color: Color(0xFF475569)),
                            SizedBox(width: 4.0),
                            Text(
                              'Learning only • Private',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
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
          ),
          const SizedBox(height: 16.0),

          // Evidence Reviewed Card
          _buildCard(
            key: const ValueKey('card_evidence_reviewed'),
            icon: Icons.article_outlined,
            iconColor: LearningColors.primary,
            title: 'Evidence reviewed',
            child: gap.reviewedEvidenceTitles.isEmpty
                ? const Text(
                    'No artifacts linked.',
                    style: TextStyle(
                        fontSize: 13, color: LearningColors.secondaryText),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: gap.reviewedEvidenceTitles.map((title) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.code,
                              size: 16,
                              color: LearningColors.primary,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16.0),

          // Why this topic? Card
          _buildCard(
            key: const ValueKey('card_gap_explanation'),
            icon: Icons.track_changes_outlined,
            iconColor: const Color(0xFF7C3AED),
            title: 'Why this topic?',
            child: Text(
              gap.explanation,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Suggested Next Step Card
          _buildCard(
            key: const ValueKey('card_suggested_next_step'),
            icon: Icons.lightbulb_outline,
            iconColor: const Color(0xFFD97706),
            title: 'Suggested next step',
            child: Text(
              gap.suggestedNextStep,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Review criteria disclaimer
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Example explanation only. Evidence sufficiency and verification criteria are still under review.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton.icon(
              key: const ValueKey('btn_return_growth_ready'),
              onPressed:
                  widget.onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Learning Growth'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.heading,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          if (widget.onExploreMentorship != null) ...[
            const SizedBox(height: 12.0),
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: OutlinedButton.icon(
                key: const ValueKey('btn_explore_mentorship'),
                onPressed: widget.onExploreMentorship,
                icon: const Icon(Icons.people_outline),
                label: const Text('Find a Volunteer Mentor'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LearningColors.primary,
                  side: const BorderSide(color: LearningColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({
    Key? key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      key: key,
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
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8.0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          child,
        ],
      ),
    );
  }
}
