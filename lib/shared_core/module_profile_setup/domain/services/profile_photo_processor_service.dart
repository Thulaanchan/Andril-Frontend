import 'dart:ui';
import '../models/photo_validation_result.dart';
import '../models/processed_photo.dart';

/// Contract for image validation, square cropping, aspect-ratio preservation,
/// resizing, compression, and metadata sanitization.
abstract class IProfilePhotoProcessorService {
  /// Validates the source image file before heavy processing:
  /// format magic bytes (JPEG/PNG), dimensions (300 to 4096 px), file size.
  Future<PhotoValidationResult> validateSourceImage(String sourcePath);

  /// Processes the main profile photograph:
  /// - Normalizes orientation (bakes EXIF orientation into pixels).
  /// - Applies square cropping (1:1 aspect ratio).
  /// - Resizes to maximum 1024x1024 longest edge.
  /// - Re-encodes as clean JPEG (quality 85) stripping all EXIF/GPS/device metadata.
  /// - Verifies output size <= 5 MiB.
  /// - Writes to application-owned temporary file.
  Future<ProcessedPhoto> processMainPhoto({
    required String sourcePath,
    Rect? cropRect,
  });

  /// Processes an additional slot photograph:
  /// - Normalizes orientation.
  /// - Preserves original visual aspect ratio (portrait, landscape, square).
  /// - Resizes longest edge to maximum 1024 px.
  /// - Re-encodes as clean JPEG (quality 85) stripping all EXIF/GPS/device metadata.
  /// - Verifies output size <= 5 MiB.
  /// - Writes to application-owned temporary file.
  Future<ProcessedPhoto> processAdditionalPhoto({
    required String sourcePath,
  });

  /// Cleans up an application-owned temporary photograph file.
  /// Never touches original user files.
  Future<void> cleanupTemporaryPhoto(String path);
}
