/// Failure codes for photograph validation and ingestion.
enum PhotoValidationError {
  none,
  fileNotFound,
  invalidFormat,
  fileTooLarge,
  resolutionTooSmall,
  resolutionTooLarge,
  corruptedFile,
  processingFailed,
  permissionDenied,
  cancelled,
}

/// Result of source image technical validation before and after processing.
class PhotoValidationResult {
  const PhotoValidationResult._({
    required this.isSuccess,
    required this.error,
    this.message,
    this.width,
    this.height,
    this.byteSize,
  });

  const PhotoValidationResult.success({
    required int width,
    required int height,
    required int byteSize,
  }) : this._(
          isSuccess: true,
          error: PhotoValidationError.none,
          width: width,
          height: height,
          byteSize: byteSize,
        );

  const PhotoValidationResult.failure(
    PhotoValidationError error, {
    String? message,
  }) : this._(
          isSuccess: false,
          error: error,
          message: message,
        );

  final bool isSuccess;
  final PhotoValidationError error;
  final String? message;
  final int? width;
  final int? height;
  final int? byteSize;

  bool get isValid => isSuccess;
  String? get errorMessage => message;
}
