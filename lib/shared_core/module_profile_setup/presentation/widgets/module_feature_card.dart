import 'package:flutter/material.dart';
import '../../domain/models/module_welcome_config.dart';

/// Interactive feature card showcasing an individual capability of the module.
class ModuleFeatureCard extends StatelessWidget {
  const ModuleFeatureCard({
    super.key,
    required this.feature,
    required this.primaryColor,
  });

  final ModuleFeatureItem feature;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container with soft primary-tinted background
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature.icon,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Feature Title and Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carousel component displaying the module's 3 feature highlights with page indicators.
class ModuleFeatureCarousel extends StatefulWidget {
  const ModuleFeatureCarousel({
    super.key,
    required this.features,
    required this.primaryColor,
    this.onPageChanged,
  });

  final List<ModuleFeatureItem> features;
  final Color primaryColor;
  final ValueChanged<int>? onPageChanged;

  @override
  State<ModuleFeatureCarousel> createState() => _ModuleFeatureCarouselState();
}

class _ModuleFeatureCarouselState extends State<ModuleFeatureCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    widget.onPageChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final cardHeight = (220.0 * textScale.clamp(1.0, 1.3)).clamp(200.0, 300.0);

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.features.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: ModuleFeatureCard(
                  feature: widget.features[index],
                  primaryColor: widget.primaryColor,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Carousel Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.features.length, (index) {
            final isActive = index == _currentIndex;
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? widget.primaryColor
                      : Colors.black.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
