import 'dart:io';
import 'package:flutter/material.dart';

/// Reusable 3-slot photo gallery uploader component.
///
/// Features:
/// - Supports exactly up to 3 photo slots matching finalized references.
/// - Dashed border placeholder slots with "+" action when unoccupied.
/// - Image thumbnail preview with replace and remove controls when occupied.
/// - Clear section title and helper description.
class ProfileGalleryUploader extends StatelessWidget {
  const ProfileGalleryUploader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.photoPaths,
    required this.maxPhotos,
    required this.primaryColor,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onReplacePhoto,
  });

  final String title;
  final String subtitle;
  final List<String> photoPaths;
  final int maxPhotos;
  final Color primaryColor;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final void Function(int index) onReplacePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),

        // Three slots row
        Row(
          children: List.generate(maxPhotos, (index) {
            final isOccupied = index < photoPaths.length;
            final path = isOccupied ? photoPaths[index] : null;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < maxPhotos - 1 ? 10 : 0,
                ),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: isOccupied
                      ? _buildOccupiedSlot(context, index, path!)
                      : _buildEmptySlot(context, index),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptySlot(BuildContext context, int index) {
    // Only the first unoccupied slot is clickable
    final isClickable = index == photoPaths.length;

    return GestureDetector(
      onTap: isClickable ? onAddPhoto : null,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isClickable
                ? primaryColor.withValues(alpha: 0.5)
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: 28,
              color: isClickable ? primaryColor : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isClickable ? primaryColor : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupiedSlot(BuildContext context, int index, String path) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Thumbnail
        GestureDetector(
          onTap: () => onReplacePhoto(index),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImage(path),
          ),
        ),

        // Remove button at top-right
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => onRemovePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: primaryColor.withValues(alpha: 0.15),
      child: Center(
        child: Icon(Icons.photo_outlined, size: 28, color: primaryColor),
      ),
    );
  }
}
