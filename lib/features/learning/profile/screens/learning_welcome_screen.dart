import 'package:flutter/material.dart';
import '../../../../app/themes/learning/learning_colors.dart';
import '../viewmodels/learning_welcome_viewmodel.dart';
import '../widgets/welcome_feature_card.dart';
import '../widgets/welcome_page_indicator.dart';
import '../widgets/welcome_wave_divider.dart';

/// Complete Learning Welcome screen for new learners.
///
/// Follows the approved visual design specification assembling official branding,
/// realistic study desk hero imagery, layered wave divider, three-card feature
/// carousel, controlled pagination, and purpose-based privacy notice.
class LearningWelcomeScreen extends StatefulWidget {
  /// Callback invoked when the user taps "Continue".
  final VoidCallback? onContinue;

  /// Callback invoked when the user taps "Back".
  final VoidCallback? onBack;

  /// Optional pre-configured ViewModel. If omitted, a local instance is created.
  final LearningWelcomeViewModel? viewModel;

  /// Creates a [LearningWelcomeScreen].
  const LearningWelcomeScreen({
    super.key,
    this.onContinue,
    this.onBack,
    this.viewModel,
  });

  @override
  State<LearningWelcomeScreen> createState() => _LearningWelcomeScreenState();
}

class _LearningWelcomeScreenState extends State<LearningWelcomeScreen> {
  late final LearningWelcomeViewModel _viewModel;
  late final PageController _pageController;
  bool _isNavigating = false;

  static const String logoAsset = 'assets/branding/andril_black_logo.png';
  static const String heroDeskAsset =
      'assets/images/learning/profile/welcome_study_desk.webp';

  static const List<WelcomeFeatureVariant> _cardVariants = [
    WelcomeFeatureVariant.shareAndLearn,
    WelcomeFeatureVariant.learningCircles,
    WelcomeFeatureVariant.trackGrowth,
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? LearningWelcomeViewModel();
    _pageController = PageController(
      initialPage: _viewModel.currentIndex,
      viewportFraction: 0.88,
    );
    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    if (_pageController.hasClients &&
        _pageController.page?.round() != _viewModel.currentIndex) {
      _pageController.animateToPage(
        _viewModel.currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_isNavigating) return;
    _isNavigating = true;
    widget.onContinue?.call();
    Future.microtask(() {
      if (mounted) _isNavigating = false;
    });
  }

  void _handleBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    widget.onBack?.call();
    Future.microtask(() {
      if (mounted) _isNavigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroHeader(context),
                    const WelcomeWaveDivider(height: 48),
                    const SizedBox(height: 8),
                    _buildFeatureCarousel(context),
                    const SizedBox(height: 12),
                    _buildPageIndicator(),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                    const SizedBox(height: 16),
                    _buildPrivacyNotice(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Stack(
      children: [
        // Top-right aligned study desk photo with gradient mask
        Positioned(
          top: 0,
          right: 0,
          width: 240,
          height: 160,
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Colors.black, Colors.transparent],
                stops: [0.4, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              heroDeskAsset,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ),
        // Foreground branding, badge and heading copy
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                logoAsset,
                height: 36,
                fit: BoxFit.contain,
                semanticLabel: 'ANDRIL',
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'ANDRIL',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: LearningColors.heading,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildModuleBadge(),
              const SizedBox(height: 12),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Start Your ',
                      style: TextStyle(
                        color: LearningColors.heading,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: 'Learning Journey',
                      style: TextStyle(
                        color: LearningColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect, collaborate, and grow through Learning.',
                style: TextStyle(
                  color: LearningColors.secondaryText,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModuleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_rounded,
            size: 16,
            color: LearningColors.primary,
          ),
          SizedBox(width: 6),
          Text(
            'Learning',
            style: TextStyle(
              color: LearningColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCarousel(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double carouselHeight =
        (340.0 * textScale.clamp(1.0, 1.6)).clamp(340.0, 500.0);

    return SizedBox(
      height: carouselHeight,
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: _cardVariants.length,
        onPageChanged: (index) {
          _viewModel.setIndex(index);
        },
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: carouselHeight - 8,
                ),
                child: WelcomeFeatureCard(
                  variant: _cardVariants[index],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator() {
    return WelcomePageIndicator(
      activeIndex: _viewModel.currentIndex,
      onIndicatorTapped: (index) {
        _viewModel.setIndex(index);
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: LearningColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _handleBack,
            style: TextButton.styleFrom(
              foregroundColor: LearningColors.secondaryText,
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text(
              'Back',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: LearningColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNotice() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        'Your Learning profile stays private within this module.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: LearningColors.secondaryText,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}
