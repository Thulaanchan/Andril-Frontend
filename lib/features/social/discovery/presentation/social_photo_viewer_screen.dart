import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';

/// Screen S52: Photo Viewer Screen.
///
/// Follows M5 requirements:
/// - Full-screen photo inspection with swipeable PageView carousel.
/// - Preserves selected index with defensive bounds checking.
/// - Responsive presentation across all device orientations and sizes.
/// - Validates current permission; fails closed if unauthorized.
/// - Safe close / back navigation.
/// - Strictly prohibits unapproved media downloads, external sharing, or false screenshot prevention claims.
class SocialPhotoViewerScreen extends StatefulWidget {
  final String memberName;
  final List<String> photoUrls;
  final int initialIndex;
  final VoidCallback? onClose;
  final bool isAuthorized;

  const SocialPhotoViewerScreen({
    super.key,
    required this.memberName,
    required this.photoUrls,
    this.initialIndex = 0,
    this.onClose,
    this.isAuthorized = true,
  });

  @override
  State<SocialPhotoViewerScreen> createState() => _SocialPhotoViewerScreenState();
}

class _SocialPhotoViewerScreenState extends State<SocialPhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    final total = widget.photoUrls.length;
    if (total == 0 || widget.initialIndex < 0 || widget.initialIndex >= total) {
      _currentIndex = 0;
    } else {
      _currentIndex = widget.initialIndex;
    }
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAuthorized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Close',
            onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 48, color: Colors.white70),
                SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'You do not have permission to inspect this member\'s private photo gallery.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.photoUrls.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Close',
            onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 48, color: Colors.white70),
                SizedBox(height: 16),
                Text(
                  'No Photos to Display',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Swipeable Photo Carousel
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photoUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final url = widget.photoUrls[index];
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.5,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AndrilSocialColors.royalPurple,
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded, size: 48, color: Colors.white38),
                              SizedBox(height: 12),
                              Text(
                                'Unable to load photo',
                                style: TextStyle(color: Colors.white60, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            // Top Control Bar
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      tooltip: 'Close',
                      onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.photoUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Member Name Pill
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.memberName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
