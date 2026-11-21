import 'package:flutter/material.dart';
import '../../../../app/themes/learning/learning_colors.dart';

/// Supported preview variants for the Welcome screen feature carousel.
enum WelcomeFeatureVariant {
  /// Variant 01: Skill exchange preview between two peer learners.
  shareAndLearn,

  /// Variant 02: Collaborative learning circles with overlapping avatars.
  learningCircles,

  /// Variant 03: Growth dashboard with CV, portfolio, and progress metrics.
  trackGrowth,
}

/// A reusable feature card widget presenting one of three learning feature previews.
class WelcomeFeatureCard extends StatelessWidget {
  /// The specific preview variant rendered by this card.
  final WelcomeFeatureVariant variant;

  /// Creates a [WelcomeFeatureCard] for the specified [variant].
  const WelcomeFeatureCard({
    super.key,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LearningColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142563EB),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVisualPreview(context),
          const SizedBox(height: 16),
          _buildHeaderRow(context),
          const SizedBox(height: 8),
          _buildDescription(context),
        ],
      ),
    );
  }

  Widget _buildVisualPreview(BuildContext context) {
    switch (variant) {
      case WelcomeFeatureVariant.shareAndLearn:
        return const _ShareAndLearnVisual();
      case WelcomeFeatureVariant.learningCircles:
        return const _LearningCirclesVisual();
      case WelcomeFeatureVariant.trackGrowth:
        return const _TrackGrowthVisual();
    }
  }

  Widget _buildHeaderRow(BuildContext context) {
    final IconData iconData;
    final String title;

    switch (variant) {
      case WelcomeFeatureVariant.shareAndLearn:
        iconData = Icons.school_rounded;
        title = 'Share & Learn Skills';
        break;
      case WelcomeFeatureVariant.learningCircles:
        iconData = Icons.groups_rounded;
        title = 'Join Learning Circles';
        break;
      case WelcomeFeatureVariant.trackGrowth:
        iconData = Icons.insights_rounded;
        title = 'Track Your Growth';
        break;
    }

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(iconData, color: LearningColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: LearningColors.heading,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    final String description;
    switch (variant) {
      case WelcomeFeatureVariant.shareAndLearn:
        description = 'Teach what you know and learn what you need.';
        break;
      case WelcomeFeatureVariant.learningCircles:
        description = 'Study with people who share your goals.';
        break;
      case WelcomeFeatureVariant.trackGrowth:
        description = 'Build your CV, portfolio, and learning progress.';
        break;
    }

    return Text(
      description,
      style: const TextStyle(
        color: LearningColors.secondaryText,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }
}

/// Visual content for Variant 01: Share & Learn Skills.
class _ShareAndLearnVisual extends StatelessWidget {
  const _ShareAndLearnVisual();

  static const String learner1Asset =
      'assets/images/learning/profile/welcome_learner_01.webp';
  static const String learner2Asset =
      'assets/images/learning/profile/welcome_learner_02.webp';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMiniProfileRow(
            assetPath: learner1Asset,
            actionLabel: 'Teach',
            skillName: 'UI Design',
            isTeacher: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A2563EB),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_vert_rounded,
                color: LearningColors.primary,
                size: 18,
              ),
            ),
          ),
          _buildMiniProfileRow(
            assetPath: learner2Asset,
            actionLabel: 'Learn',
            skillName: 'Data Analytics',
            isTeacher: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProfileRow({
    required String assetPath,
    required String actionLabel,
    required String skillName,
    required bool isTeacher,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _SafePortraitAvatar(assetPath: assetPath, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: TextStyle(
                    color: isTeacher
                        ? LearningColors.primary
                        : const Color(0xFF7C3AED),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  skillName,
                  style: const TextStyle(
                    color: LearningColors.heading,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isTeacher ? Icons.north_east_rounded : Icons.south_west_rounded,
            size: 16,
            color: LearningColors.secondaryText,
          ),
        ],
      ),
    );
  }
}

/// Visual content for Variant 02: Join Learning Circles.
class _LearningCirclesVisual extends StatelessWidget {
  const _LearningCirclesVisual();

  static const String learner3Asset =
      'assets/images/learning/profile/welcome_learner_03.webp';
  static const String learner4Asset =
      'assets/images/learning/profile/welcome_learner_04.webp';
  static const String learner5Asset =
      'assets/images/learning/profile/welcome_learner_05.webp';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft decorative background circles
          Positioned(
            left: 20,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE).withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 24,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE).withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Overlapping circular portraits
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBorderedAvatar(learner3Asset),
              Transform.translate(
                offset: const Offset(-12, 0),
                child: _buildBorderedAvatar(learner4Asset),
              ),
              Transform.translate(
                offset: const Offset(-24, 0),
                child: _buildBorderedAvatar(learner5Asset),
              ),
            ],
          ),
          // Community blue icon badge
          Positioned(
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x142563EB),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 16,
                color: LearningColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderedAvatar(String assetPath) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _SafePortraitAvatar(assetPath: assetPath, radius: 24),
    );
  }
}

/// Visual content for Variant 03: Track Your Growth.
class _TrackGrowthVisual extends StatelessWidget {
  const _TrackGrowthVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDashboardRow(
            icon: Icons.description_rounded,
            iconColor: LearningColors.primary,
            label: 'CV',
            trailingWidget: const Icon(
              Icons.chevron_right_rounded,
              color: LearningColors.secondaryText,
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          _buildDashboardRow(
            icon: Icons.folder_special_rounded,
            iconColor: const Color(0xFF7C3AED),
            label: 'Portfolio',
            trailingWidget: const Icon(
              Icons.chevron_right_rounded,
              color: LearningColors.secondaryText,
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          _buildDashboardRow(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF0057FF),
            label: 'Progress',
            trailingWidget: SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.72,
                  minHeight: 6,
                  color: Color(0xFF10B981),
                  backgroundColor: Color(0xFFD1FAE5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget trailingWidget,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: LearningColors.heading,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailingWidget,
        ],
      ),
    );
  }
}

/// Fallback-safe circular portrait widget.
class _SafePortraitAvatar extends StatelessWidget {
  final String assetPath;
  final double radius;

  const _SafePortraitAvatar({
    required this.assetPath,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFE2E8F0),
              alignment: Alignment.center,
              child: Icon(
                Icons.person_rounded,
                size: radius,
                color: const Color(0xFF94A3B8),
              ),
            );
          },
        ),
      ),
    );
  }
}
