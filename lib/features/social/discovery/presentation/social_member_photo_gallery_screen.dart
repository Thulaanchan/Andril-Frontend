import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';

/// Screen S51: Member Photo Gallery.
///
/// Follows M5 requirements:
/// - Displays authorized Social profile photos only.
/// - Photo thumbnails grid with interactive selection.
/// - Safe image loading with network error fallback.
/// - Clear empty and access-denied states.
/// - Responsive layout across mobile, compact, and tablet viewports.
/// - Fail-closed: No cross-module photos, no private media credential exposure.
class SocialMemberPhotoGalleryScreen extends StatelessWidget {
  final String memberName;
  final String memberId;
  final List<String> photoUrls;
  final ValueChanged<int>? onPhotoSelected;
  final VoidCallback? onBack;
  final bool isAuthorized;

  const SocialMemberPhotoGalleryScreen({
    super.key,
    required this.memberName,
    required this.memberId,
    required this.photoUrls,
    this.onPhotoSelected,
    this.onBack,
    this.isAuthorized = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AndrilSocialColors.cream,
      appBar: AppBar(
        backgroundColor: AndrilSocialColors.cream,
        foregroundColor: AndrilSocialColors.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$memberName\'s Photos',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AndrilSocialColors.ink,
              ),
            ),
            if (isAuthorized && photoUrls.isNotEmpty)
              Text(
                '${photoUrls.length} ${photoUrls.length == 1 ? 'photo' : 'photos'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!isAuthorized) {
      return _buildAccessDeniedState();
    }

    if (photoUrls.isEmpty) {
      return _buildEmptyState();
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth > 600 ? 4 : (screenWidth > 360 ? 3 : 2);

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: photoUrls.length,
      itemBuilder: (context, index) {
        final url = photoUrls[index];
        return Semantics(
          label: 'Photo ${index + 1} of ${photoUrls.length}',
          button: true,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onPhotoSelected?.call(index),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.black12,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AndrilSocialColors.royalPurple,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFE9E4ED),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 32,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE8F4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 40,
                color: AndrilSocialColors.royalPurple,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Photos Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AndrilSocialColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$memberName hasn\'t uploaded additional gallery photos.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE63946).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: Color(0xFFE63946),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AndrilSocialColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Viewing private member photos requires an active authorized Social session.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
