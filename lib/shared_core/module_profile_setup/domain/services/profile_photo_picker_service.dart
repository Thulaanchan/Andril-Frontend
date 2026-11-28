import '../models/photo_source.dart';

/// Contract for selecting a photograph from the camera or device gallery.
abstract class IProfilePhotoPickerService {
  /// Prompts the user to pick an image from the specified [source].
  /// Returns the file path of the picked image, or null if cancelled.
  Future<String?> pickPhoto(PhotoSource source);
}
