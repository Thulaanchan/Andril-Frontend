import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/components/m2_buttons.dart';
import '../../../onboarding/presentation/localization/onboarding_localizations.dart';

/// Interactive Square Cropping Screen (Task 03.05).
///
/// Features:
/// - Enforces 1:1 square aspect ratio for the main profile photograph.
/// - Allows user-controlled panning and pinch-to-zoom framing using [InteractiveViewer].
/// - Displays rule-of-thirds grid inside a square viewfinder overlay.
/// - Confirms user-selected crop boundary and returns calculated [Rect].
/// - Allows cancellation without modifying existing profile photo state.
/// - Does NOT use face recognition or biometric processing.
class PhotoCropScreen extends StatefulWidget {
  const PhotoCropScreen({
    super.key,
    required this.imageFile,
    this.initialCropRect,
    this.initialImageSize,
  });

  final File imageFile;
  final Rect? initialCropRect;
  final Size? initialImageSize;

  static Future<Rect?> start(BuildContext context, File imageFile) {
    return Navigator.of(context).push<Rect>(
      MaterialPageRoute(
        builder: (_) => PhotoCropScreen(imageFile: imageFile),
      ),
    );
  }

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  final TransformationController _transformController =
      TransformationController();
  Size? _imageSize;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialImageSize != null) {
      _imageSize = widget.initialImageSize;
      _isLoading = false;
    } else {
      _loadImageSize();
    }
  }

  Future<void> _loadImageSize() async {
    final bytes = await widget.imageFile.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    if (mounted) {
      setState(() {
        _imageSize = Size(
          decoded.width.toDouble(),
          decoded.height.toDouble(),
        );
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _confirmCrop(double viewportSide) {
    if (_imageSize == null) {
      Navigator.of(context).pop(null);
      return;
    }

    final Matrix4 matrix = _transformController.value;
    final double scale = matrix.getMaxScaleOnAxis();
    final double tx = matrix.storage[12];
    final double ty = matrix.storage[13];

    // Map viewport coordinates back to source image pixels
    final double imgW = _imageSize!.width;
    final double imgH = _imageSize!.height;

    // Viewport-to-image scale ratio
    final double displayedW = imgW >= imgH ? viewportSide * (imgW / imgH) : viewportSide;
    final double displayedH = imgH >= imgW ? viewportSide * (imgH / imgW) : viewportSide;

    final double effectiveScale = scale <= 0 ? 1.0 : scale;

    final double normX = (-tx / (displayedW * effectiveScale)).clamp(0.0, 1.0);
    final double normY = (-ty / (displayedH * effectiveScale)).clamp(0.0, 1.0);
    final double normSide = (viewportSide / (math.min(displayedW, displayedH) * effectiveScale))
        .clamp(0.1, 1.0);

    final double cropX = (normX * imgW).clamp(0.0, imgW - 50.0);
    final double cropY = (normY * imgH).clamp(0.0, imgH - 50.0);
    final double maxSide = math.min(imgW - cropX, imgH - cropY);
    final double cropSide = math.max(50.0, math.min(normSide * math.min(imgW, imgH), maxSide));

    final cropRect = Rect.fromLTWH(cropX, cropY, cropSide, cropSide);
    Navigator.of(context).pop(cropRect);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = OnboardingLocalizations.of(context);
    final screenSize = MediaQuery.of(context).size;
    final double viewportSide = math.min(screenSize.width - 48.0, 320.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text(
          l10n.cropPhotoTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: M2Colors.primaryTeal),
              )
            : Column(
                children: [
                  // Subtitle Instructions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Text(
                      l10n.cropPhotoSubtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Center Viewport Area
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: viewportSide,
                        height: viewportSide,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Interactive Viewer
                            InteractiveViewer(
                              transformationController: _transformController,
                              minScale: 1.0,
                              maxScale: 4.0,
                              boundaryMargin: const EdgeInsets.all(double.infinity),
                              child: Image.file(
                                widget.imageFile,
                                fit: BoxFit.contain,
                              ),
                            ),

                            // Grid Overlay (Rule of Thirds)
                            IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: CustomPaint(
                                  painter: _GridOverlayPainter(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: M2SecondaryButton(
                            text: l10n.cancelButton,
                            onPressed: () => Navigator.of(context).pop(null),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: M2PrimaryButton(
                            text: l10n.confirmCrop,
                            onPressed: () => _confirmCrop(viewportSide),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double oneThirdW = size.width / 3.0;
    final double twoThirdsW = oneThirdW * 2.0;
    final double oneThirdH = size.height / 3.0;
    final double twoThirdsH = oneThirdH * 2.0;

    // Vertical grid lines
    canvas.drawLine(Offset(oneThirdW, 0), Offset(oneThirdW, size.height), paint);
    canvas.drawLine(Offset(twoThirdsW, 0), Offset(twoThirdsW, size.height), paint);

    // Horizontal grid lines
    canvas.drawLine(Offset(0, oneThirdH), Offset(size.width, oneThirdH), paint);
    canvas.drawLine(Offset(0, twoThirdsH), Offset(size.width, twoThirdsH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
