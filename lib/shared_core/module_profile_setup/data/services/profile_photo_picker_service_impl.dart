import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/photo_source.dart';
import '../../domain/services/profile_photo_picker_service.dart';

/// Production implementation of [IProfilePhotoPickerService] using Flutter's [ImagePicker].
class ProfilePhotoPickerServiceImpl implements IProfilePhotoPickerService {
  ProfilePhotoPickerServiceImpl({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<String?> pickPhoto(PhotoSource source) async {
    try {
      final ImageSource imageSource = switch (source) {
        PhotoSource.gallery => ImageSource.gallery,
        PhotoSource.camera => ImageSource.camera,
      };

      final XFile? file = await _imagePicker.pickImage(
        source: imageSource,
        requestFullMetadata: false, // Minimizes unnecessary system metadata requests
      );

      return file?.path;
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
        throw Exception('permission_denied');
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
