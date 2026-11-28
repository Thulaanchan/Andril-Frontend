/// Immutable model representing a validated, cropped, resized, and metadata-sanitized photograph.
class ProcessedPhoto {
  const ProcessedPhoto({
    required this.path,
    required this.width,
    required this.height,
    required this.byteSize,
    required this.mimeType,
    this.isSquare = false,
  });

  final String path;
  final int width;
  final int height;
  final int byteSize;
  final String mimeType;
  final bool isSquare;

  double get aspectRatio => height == 0 ? 1.0 : width / height;
  bool get isPortrait => height > width;
  bool get isLandscape => width > height;

  /// Returns true if the file size satisfies the 5 MiB (5,242,880 bytes) technical limit.
  bool get isWithinSizeLimit => byteSize <= 5242880;
}
