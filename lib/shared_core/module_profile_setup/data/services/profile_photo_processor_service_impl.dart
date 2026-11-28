import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../domain/models/photo_validation_result.dart';
import '../../domain/models/processed_photo.dart';
import '../../domain/services/profile_photo_processor_service.dart';

/// Production implementation of [IProfilePhotoProcessorService].
///
/// Enforces:
/// - Magic-byte format verification (JPEG and PNG only, rejects WebP/GIF/BMP/non-image).
/// - Dimension validation (min 300x300, max 4096x4096).
/// - 5 MiB (5,242,880 bytes) size ceiling.
/// - EXIF orientation normalization (bakes orientation into pixel buffer).
/// - Complete metadata sanitization (GPS, camera make/model, serials stripped).
/// - Main photo: 1:1 square crop, scaled to max 1024x1024 longest edge.
/// - Additional photo: aspect ratio preservation, scaled to max 1024 px longest edge.
/// - Safe temporary-file lifecycle: tracks and cleans only application-owned temp files.
class ProfilePhotoProcessorServiceImpl implements IProfilePhotoProcessorService {
  ProfilePhotoProcessorServiceImpl({Directory? tempDirectory})
      : _customTempDirectory = tempDirectory;

  final Directory? _customTempDirectory;
  final Set<String> _ownedTempFilePaths = <String>{};

  static const int maxFileSizeBytes = 5242880; // 5 MiB
  static const int minDimensionPixels = 300;
  static const int maxDimensionPixels = 4096;
  static const int maxOutputDimensionPixels = 1024;
  static const int defaultJpegQuality = 85;

  /// Returns true if the file header matches JPEG magic bytes [0xFF, 0xD8, 0xFF].
  static bool isJpeg(Uint8List bytes) {
    if (bytes.length < 3) return false;
    return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
  }

  /// Returns true if the file header matches PNG magic bytes [0x89, 0x50, 0x4E, 0x47].
  static bool isPng(Uint8List bytes) {
    if (bytes.length < 8) return false;
    return bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A;
  }

  @override
  Future<PhotoValidationResult> validateSourceImage(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      return const PhotoValidationResult.failure(
        PhotoValidationError.fileNotFound,
        message: 'Photograph file could not be found.',
      );
    }

    final byteSize = await file.length();
    if (byteSize == 0) {
      return const PhotoValidationResult.failure(
        PhotoValidationError.corruptedFile,
        message: 'Photograph file is empty or corrupted.',
      );
    }

    // Safety guard against memory exhaustion (> 50 MB raw upload)
    if (byteSize > 52428800) {
      return const PhotoValidationResult.failure(
        PhotoValidationError.fileTooLarge,
        message: 'Photograph file is too large to process safely.',
      );
    }

    // Inspect magic bytes
    final headerBytes = await file.openRead(0, 16).first;
    final header = Uint8List.fromList(headerBytes);
    if (!isJpeg(header) && !isPng(header)) {
      return const PhotoValidationResult.failure(
        PhotoValidationError.invalidFormat,
        message: 'Unsupported format. Only JPEG and PNG photographs are supported.',
      );
    }

    // Decode image to inspect dimensions
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const PhotoValidationResult.failure(
        PhotoValidationError.corruptedFile,
        message: 'Failed to decode photograph. The image may be corrupted.',
      );
    }

    if (decoded.width < minDimensionPixels || decoded.height < minDimensionPixels) {
      return const PhotoValidationResult.failure(
        PhotoValidationError.resolutionTooSmall,
        message: 'Image resolution is too low. Minimum resolution is 300x300 pixels.',
      );
    }

    if (decoded.width > maxDimensionPixels || decoded.height > maxDimensionPixels) {
      return const PhotoValidationResult.failure(
        PhotoValidationError.resolutionTooLarge,
        message: 'Image resolution exceeds maximum limit of 4096x4096 pixels.',
      );
    }

    return PhotoValidationResult.success(
      width: decoded.width,
      height: decoded.height,
      byteSize: byteSize,
    );
  }

  @override
  Future<ProcessedPhoto> processMainPhoto({
    required String sourcePath,
    Rect? cropRect,
  }) async {
    final validation = await validateSourceImage(sourcePath);
    if (!validation.isSuccess) {
      throw Exception(validation.message ?? 'Validation failed');
    }

    final file = File(sourcePath);
    final rawBytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(rawBytes);
    if (image == null) {
      throw Exception('Failed to decode source image.');
    }

    // 1. Normalize orientation (bake EXIF orientation into pixel matrix)
    image = img.bakeOrientation(image);

    // 2. Apply Square Crop (1:1 aspect ratio)
    img.Image cropped;
    if (cropRect != null) {
      final int x = math.max(0, cropRect.left.round());
      final int y = math.max(0, cropRect.top.round());
      final int w = math.min(image.width - x, cropRect.width.round());
      final int h = math.min(image.height - y, cropRect.height.round());
      final int side = math.min(w, h);
      cropped = img.copyCrop(image, x: x, y: y, width: side, height: side);
    } else {
      final int side = math.min(image.width, image.height);
      final int x = (image.width - side) ~/ 2;
      final int y = (image.height - side) ~/ 2;
      cropped = img.copyCrop(image, x: x, y: y, width: side, height: side);
    }

    // 3. Resize to maximum 1024x1024 if needed
    img.Image resized = cropped;
    if (cropped.width > maxOutputDimensionPixels) {
      resized = img.copyResize(
        cropped,
        width: maxOutputDimensionPixels,
        height: maxOutputDimensionPixels,
        interpolation: img.Interpolation.linear,
      );
    }

    // 4. Encode as clean JPEG (stripping EXIF/GPS metadata)
    Uint8List encodedBytes = Uint8List.fromList(
      img.encodeJpg(resized, quality: defaultJpegQuality),
    );

    // 5. Size check with bounded quality reduction fallback
    if (encodedBytes.lengthInBytes > maxFileSizeBytes) {
      encodedBytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: 70),
      );
    }

    if (encodedBytes.lengthInBytes > maxFileSizeBytes) {
      throw Exception('Processed image exceeds maximum allowed size of 5 MB.');
    }

    // 6. Write to application-owned temporary file
    final tempDir = _customTempDirectory ?? await getTemporaryDirectory();
    final filename =
        'andril_m2_main_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}.jpg';
    final outputFile = File('${tempDir.path}/$filename');
    await outputFile.writeAsBytes(encodedBytes, flush: true);

    _ownedTempFilePaths.add(outputFile.path);

    return ProcessedPhoto(
      path: outputFile.path,
      width: resized.width,
      height: resized.height,
      byteSize: encodedBytes.lengthInBytes,
      mimeType: 'image/jpeg',
      isSquare: true,
    );
  }

  @override
  Future<ProcessedPhoto> processAdditionalPhoto({
    required String sourcePath,
  }) async {
    final validation = await validateSourceImage(sourcePath);
    if (!validation.isSuccess) {
      throw Exception(validation.message ?? 'Validation failed');
    }

    final file = File(sourcePath);
    final rawBytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(rawBytes);
    if (image == null) {
      throw Exception('Failed to decode source image.');
    }

    // 1. Normalize orientation
    image = img.bakeOrientation(image);

    // 2. Preserve original visual aspect ratio while scaling longest edge to 1024 max
    img.Image resized = image;
    final int longestEdge = math.max(image.width, image.height);
    if (longestEdge > maxOutputDimensionPixels) {
      if (image.width >= image.height) {
        resized = img.copyResize(
          image,
          width: maxOutputDimensionPixels,
          interpolation: img.Interpolation.linear,
        );
      } else {
        resized = img.copyResize(
          image,
          height: maxOutputDimensionPixels,
          interpolation: img.Interpolation.linear,
        );
      }
    }

    // 3. Encode as clean JPEG (stripping all metadata)
    Uint8List encodedBytes = Uint8List.fromList(
      img.encodeJpg(resized, quality: defaultJpegQuality),
    );

    if (encodedBytes.lengthInBytes > maxFileSizeBytes) {
      encodedBytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: 70),
      );
    }

    if (encodedBytes.lengthInBytes > maxFileSizeBytes) {
      throw Exception('Processed image exceeds maximum allowed size of 5 MB.');
    }

    // 4. Write to application-owned temporary file
    final tempDir = _customTempDirectory ?? await getTemporaryDirectory();
    final filename =
        'andril_m2_slot_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}.jpg';
    final outputFile = File('${tempDir.path}/$filename');
    await outputFile.writeAsBytes(encodedBytes, flush: true);

    _ownedTempFilePaths.add(outputFile.path);

    return ProcessedPhoto(
      path: outputFile.path,
      width: resized.width,
      height: resized.height,
      byteSize: encodedBytes.lengthInBytes,
      mimeType: 'image/jpeg',
      isSquare: resized.width == resized.height,
    );
  }

  @override
  Future<void> cleanupTemporaryPhoto(String path) async {
    // Only delete files that this service explicitly created
    if (_ownedTempFilePaths.contains(path)) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
      _ownedTempFilePaths.remove(path);
    }
  }
}
