import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Reusable circular dashed photo uploader component.
///
/// Features:
/// - Dashed circular boundary using custom painter
/// - Camera icon and "Add Photo" label
/// - Required / Optional badge matching module theme
/// - Preview display with Replace and Remove actions
/// - Loading indicator during facial verification
/// - Error text display
class ProfilePhotoUploader extends StatelessWidget {
  const ProfilePhotoUploader({
    super.key,
    required this.primaryColor,
    required this.isRequired,
    this.photoPath,
    this.helperText,
    this.errorText,
    this.isLoading = false,
    this.isFaceVerified = false,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final Color primaryColor;
  final bool isRequired;
  final String? photoPath;
  final String? helperText;
  final String? errorText;
  final bool isLoading;
  final bool isFaceVerified;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.trim().isNotEmpty;

    return Column(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Circular container with dashed border or image preview
              GestureDetector(
                onTap: isLoading ? null : onPickPhoto,
                child: CustomPaint(
                  painter: hasPhoto
                      ? null
                      : _DashedCirclePainter(
                          color: errorText != null
                              ? const Color(0xFFDC2626)
                              : primaryColor.withValues(alpha: 0.6),
                          strokeWidth: 2,
                          dashLength: 6,
                          gapLength: 4,
                        ),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasPhoto
                          ? Colors.grey.shade200
                          : primaryColor.withValues(alpha: 0.05),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isLoading
                        ? Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: primaryColor,
                              ),
                            ),
                          )
                        : hasPhoto
                            ? _buildPhotoPreview(photoPath!)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 32,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add Photo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),

              // Status badge (Required / Optional)
              Positioned(
                top: 0,
                right: -8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isRequired
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF64748B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    isRequired ? 'Required' : 'Optional',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Action buttons (Replace / Remove) when photo is selected
              if (hasPhoto && !isLoading)
                Positioned(
                  bottom: -2,
                  right: -4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Remove button
                      InkWell(
                        onTap: onRemovePhoto,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Replace button
                      InkWell(
                        onTap: onPickPhoto,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Optional helper description
        if (helperText != null) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              helperText!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ),
        ],

        // Error message
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 14, color: Color(0xFFDC2626)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    errorText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoPreview(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    // Fallback for mocked or non-local path
    return Container(
      color: primaryColor.withValues(alpha: 0.15),
      child: Center(
        child: Icon(Icons.person, size: 54, color: primaryColor),
      ),
    );
  }
}

/// Custom painter for dashed circle border
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final circumference = 2 * math.pi * radius;
    final dashGapTotal = dashLength + gapLength;
    final dashCount = (circumference / dashGapTotal).floor();
    final adjustedDashLength = dashLength * (circumference / (dashCount * dashGapTotal));
    final adjustedGapLength = gapLength * (circumference / (dashCount * dashGapTotal));

    final dashAngle = adjustedDashLength / radius;
    final gapAngle = adjustedGapLength / radius;

    double currentAngle = 0.0;
    while (currentAngle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        dashAngle,
        false,
        paint,
      );
      currentAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}
