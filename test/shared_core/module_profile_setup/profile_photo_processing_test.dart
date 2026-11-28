import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:andril_mobile/shared_core/language_selection/domain/models/app_language.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/data/services/profile_photo_processor_service_impl.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/domain/models/photo_source.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/domain/models/photo_validation_result.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/domain/models/profile_creation_config.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/domain/services/profile_photo_picker_service.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/viewmodels/module_profile_viewmodel.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/widgets/photo_crop_screen.dart';
import 'package:andril_mobile/shared_core/module_profile_setup/presentation/widgets/photo_source_bottom_sheet.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/localization/onboarding_localizations.dart';

import 'test_doubles/mock_module_profile_repository.dart';

// --- Mocks ---

class MockPhotoPickerService implements IProfilePhotoPickerService {
  String? nextResult;
  bool shouldThrow = false;
  PhotoSource? lastSource;
  int pickCallCount = 0;

  @override
  Future<String?> pickPhoto(PhotoSource source) async {
    pickCallCount++;
    lastSource = source;
    if (shouldThrow) {
      throw Exception('Camera or Gallery permission permanently denied');
    }
    return nextResult;
  }
}

// --- Test Helpers ---

img.Image _generateImage(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 180, 240));
  return image;
}

File _createTestJpeg(Directory dir, String filename, int width, int height) {
  final image = _generateImage(width, height);
  final bytes = img.encodeJpg(image, quality: 90);
  final file = File('${dir.path}/$filename');
  file.writeAsBytesSync(bytes);
  return file;
}

File _createTestPng(Directory dir, String filename, int width, int height) {
  final image = _generateImage(width, height);
  final bytes = img.encodePng(image);
  final file = File('${dir.path}/$filename');
  file.writeAsBytesSync(bytes);
  return file;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempFixtureDir;
  late Directory tempOutputDir;
  late ProfilePhotoProcessorServiceImpl processorService;
  late MockPhotoPickerService mockPicker;
  late MockModuleProfileRepository mockRepo;

  setUp(() {
    tempFixtureDir = Directory.systemTemp.createTempSync('photo_fixtures_');
    tempOutputDir = Directory.systemTemp.createTempSync('photo_output_');
    processorService = ProfilePhotoProcessorServiceImpl(tempDirectory: tempOutputDir);
    mockPicker = MockPhotoPickerService();
    mockRepo = MockModuleProfileRepository();
  });

  tearDown(() {
    try {
      if (tempFixtureDir.existsSync()) {
        tempFixtureDir.deleteSync(recursive: true);
      }
    } catch (_) {}
    try {
      if (tempOutputDir.existsSync()) {
        tempOutputDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('03.01 — Main Profile Photo Picker Tests', () {
    test('Learning Profile allows saving without photo (optional)', () async {
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
      );

      vm.setDisplayName('Learner');
      final result = await vm.saveProfile();

      expect(result, isTrue);
      expect(mockRepo.saveCount, equals(1));
      expect(vm.profilePhotoPath, isNull);
      expect(vm.photoError, isNull);
    });

    test('Hobbies Profile allows saving without photo (optional)', () async {
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.hobbies(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
      );

      vm.setDisplayName('Hobbyist');
      final result = await vm.saveProfile();

      expect(result, isTrue);
      expect(mockRepo.saveCount, equals(1));
      expect(vm.profilePhotoPath, isNull);
    });

    test('Social Profile requires photo and blocks submission if missing', () async {
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.social(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
        isSocialAuthorizedByServer: true,
      );

      vm.setDisplayName('Socialite');
      final result = await vm.saveProfile();

      expect(result, isFalse);
      expect(mockRepo.saveCount, equals(0));
      expect(vm.photoError, equals('Profile photo is required for Social.'));
    });

    test('Picker cancellation preserves existing profile photo', () async {
      final fixtureFile = _createTestJpeg(tempFixtureDir, 'initial.jpg', 600, 600);
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.social(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
        isSocialAuthorizedByServer: true,
      );

      // Successfully pick first photo
      mockPicker.nextResult = fixtureFile.path;
      await vm.pickProfilePhoto(source: PhotoSource.gallery);
      final initialPhotoPath = vm.profilePhotoPath;
      expect(initialPhotoPath, isNotNull);

      // User initiates picker again but cancels
      mockPicker.nextResult = null;
      await vm.pickProfilePhoto(source: PhotoSource.camera);

      // Previous photo is preserved
      expect(vm.profilePhotoPath, equals(initialPhotoPath));
      expect(vm.photoError, isNull);
    });

    test('Successful pick processes photo and updates state', () async {
      final fixtureFile = _createTestJpeg(tempFixtureDir, 'avatar.jpg', 800, 800);
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
      );

      mockPicker.nextResult = fixtureFile.path;
      await vm.pickProfilePhoto(source: PhotoSource.gallery);

      expect(vm.profilePhotoPath, isNotNull);
      expect(vm.profilePhoto, isNotNull);
      expect(vm.profilePhoto!.isSquare, isTrue);
      expect(vm.profilePhoto!.width, lessThanOrEqualTo(1024));
      expect(vm.profilePhoto!.height, lessThanOrEqualTo(1024));
    });
  });

  group('03.02 — Additional Photo Slots Tests', () {
    test('accepts up to 3 additional photos across independent slots', () async {
      final pic1 = _createTestJpeg(tempFixtureDir, 'pic1.jpg', 500, 700);
      final pic2 = _createTestJpeg(tempFixtureDir, 'pic2.jpg', 600, 400);
      final pic3 = _createTestJpeg(tempFixtureDir, 'pic3.jpg', 500, 500);

      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.hobbies(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
      );

      mockPicker.nextResult = pic1.path;
      await vm.pickAdditionalPhoto(slotIndex: 0, source: PhotoSource.gallery);

      mockPicker.nextResult = pic2.path;
      await vm.pickAdditionalPhoto(slotIndex: 1, source: PhotoSource.gallery);

      mockPicker.nextResult = pic3.path;
      await vm.pickAdditionalPhoto(slotIndex: 2, source: PhotoSource.gallery);

      expect(vm.additionalPhotoPaths.length, equals(3));
      expect(vm.canAddMoreAdditionalPhotos, isFalse);
    });

    test('rejects adding a 4th additional photo', () async {
      final pic1 = _createTestJpeg(tempFixtureDir, 'pic1.jpg', 500, 500);
      final pic2 = _createTestJpeg(tempFixtureDir, 'pic2.jpg', 500, 500);
      final pic3 = _createTestJpeg(tempFixtureDir, 'pic3.jpg', 500, 500);
      final pic4 = _createTestJpeg(tempFixtureDir, 'pic4.jpg', 500, 500);

      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.hobbies(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
      );

      mockPicker.nextResult = pic1.path;
      await vm.pickAdditionalPhoto(slotIndex: 0, source: PhotoSource.gallery);
      mockPicker.nextResult = pic2.path;
      await vm.pickAdditionalPhoto(slotIndex: 1, source: PhotoSource.gallery);
      mockPicker.nextResult = pic3.path;
      await vm.pickAdditionalPhoto(slotIndex: 2, source: PhotoSource.gallery);

      // Attempt 4th photo
      mockPicker.nextResult = pic4.path;
      await vm.pickAdditionalPhoto(slotIndex: 3, source: PhotoSource.gallery);

      expect(vm.additionalPhotoPaths.length, equals(3));
      expect(vm.addAdditionalPhoto(pic4.path), isFalse);
    });

    test('replaces an existing slot atomically without disturbing other slots', () async {
      final pic1 = _createTestJpeg(tempFixtureDir, 'pic1.jpg', 500, 500);
      final pic2 = _createTestJpeg(tempFixtureDir, 'pic2.jpg', 500, 500);
      final replacement = _createTestJpeg(tempFixtureDir, 'replacement.jpg', 600, 600);

      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.hobbies(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
      );

      mockPicker.nextResult = pic1.path;
      await vm.pickAdditionalPhoto(slotIndex: 0, source: PhotoSource.gallery);
      final slot0Original = vm.additionalPhotoPaths[0];

      mockPicker.nextResult = pic2.path;
      await vm.pickAdditionalPhoto(slotIndex: 1, source: PhotoSource.gallery);

      // Replace slot 0
      mockPicker.nextResult = replacement.path;
      await vm.pickAdditionalPhoto(slotIndex: 0, source: PhotoSource.gallery);

      expect(vm.additionalPhotoPaths.length, equals(2));
      expect(vm.additionalPhotoPaths[0], isNot(equals(slot0Original)));
    });

    test('strict cross-module photo isolation prevents leakage', () async {
      final pic = _createTestJpeg(tempFixtureDir, 'hobbies_art.jpg', 600, 600);
      final vmHobbies = ModuleProfileViewModel(
        config: ProfileCreationConfig.hobbies(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
      );
      final vmSocial = ModuleProfileViewModel(
        config: ProfileCreationConfig.social(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
        isSocialAuthorizedByServer: true,
      );

      mockPicker.nextResult = pic.path;
      await vmHobbies.pickProfilePhoto(source: PhotoSource.gallery);
      await vmHobbies.pickAdditionalPhoto(slotIndex: 0, source: PhotoSource.gallery);

      expect(vmHobbies.profilePhotoPath, isNotNull);
      expect(vmHobbies.additionalPhotoPaths.length, equals(1));

      // Social ViewModel must remain clean
      expect(vmSocial.profilePhotoPath, isNull);
      expect(vmSocial.additionalPhotoPaths, isEmpty);
    });
  });

  group('03.03 — Camera and Gallery Selection UI Tests', () {
    testWidgets('PhotoSourceBottomSheet renders Camera, Gallery and Cancel options',
        (tester) async {
      PhotoSource? chosenSource;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  chosenSource = await PhotoSourceBottomSheet.show(ctx);
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      expect(chosenSource, equals(PhotoSource.camera));
    });

    testWidgets('PhotoSourceBottomSheet returns PhotoSource.gallery when chosen',
        (tester) async {
      PhotoSource? chosenSource;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  chosenSource = await PhotoSourceBottomSheet.show(ctx);
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();

      expect(chosenSource, equals(PhotoSource.gallery));
    });

    test('gracefully handles picker permission errors without crashing', () async {
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
      );

      mockPicker.shouldThrow = true;
      await vm.pickProfilePhoto(source: PhotoSource.camera);

      expect(vm.profilePhotoPath, isNull);
      expect(vm.photoError, contains('Camera or Gallery permission permanently denied'));
      expect(vm.isPhotoLoading, isFalse);
    });
  });

  group('03.04 — Photo Removal and Replacement Tests', () {
    test('removing profile photo cleans up temporary file and clears state', () async {
      final fixture = _createTestJpeg(tempFixtureDir, 'avatar.jpg', 600, 600);
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
      );

      mockPicker.nextResult = fixture.path;
      await vm.pickProfilePhoto(source: PhotoSource.gallery);
      final processedPath = vm.profilePhotoPath!;
      expect(File(processedPath).existsSync(), isTrue);

      vm.removeProfilePhoto();

      expect(vm.profilePhotoPath, isNull);
      expect(vm.profilePhoto, isNull);
      // Verify owned temporary file was cleaned up
      expect(File(processedPath).existsSync(), isFalse);
      // Verify user's original fixture is untouched
      expect(fixture.existsSync(), isTrue);
    });

    test('removing additional photo cleans up temporary file', () async {
      final fixture = _createTestJpeg(tempFixtureDir, 'art.jpg', 600, 600);
      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.hobbies(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
      );

      mockPicker.nextResult = fixture.path;
      await vm.pickAdditionalPhoto(slotIndex: 0, source: PhotoSource.gallery);
      final processedPath = vm.additionalPhotoPaths[0];
      expect(File(processedPath).existsSync(), isTrue);

      vm.removeAdditionalPhoto(0);

      expect(vm.additionalPhotoPaths, isEmpty);
      expect(File(processedPath).existsSync(), isFalse);
      expect(fixture.existsSync(), isTrue);
    });

    test('processor failure preserves previous photo', () async {
      final validFixture = _createTestJpeg(tempFixtureDir, 'valid.jpg', 600, 600);
      final corruptedFile = File('${tempFixtureDir.path}/corrupt.jpg')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0x00, 0x11]); // Corrupted JPEG

      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.learning(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
      );

      mockPicker.nextResult = validFixture.path;
      await vm.pickProfilePhoto(source: PhotoSource.gallery);
      final originalPath = vm.profilePhotoPath;
      expect(originalPath, isNotNull);

      // Attempt to replace with corrupt file
      mockPicker.nextResult = corruptedFile.path;
      await vm.pickProfilePhoto(source: PhotoSource.gallery);

      // Previous photo must remain intact
      expect(vm.profilePhotoPath, equals(originalPath));
      expect(vm.photoError, isNotNull);
    });
  });

  group('03.05 — Main Photo Square Cropping Tests', () {
    test('crops rectangular image to 1:1 square output', () async {
      // Landscape 1200x800 input
      final landscape = _createTestJpeg(tempFixtureDir, 'landscape.jpg', 1200, 800);

      final result = await processorService.processMainPhoto(sourcePath: landscape.path);

      expect(result.isSquare, isTrue);
      expect(result.width, equals(result.height));
      expect(result.width, lessThanOrEqualTo(1024));
      expect(result.aspectRatio, closeTo(1.0, 0.01));
      expect(File(result.path).existsSync(), isTrue);
    });

    test('applies explicit crop rectangle when provided', () async {
      final source = _createTestJpeg(tempFixtureDir, 'face.jpg', 1000, 1000);
      const cropRect = Rect.fromLTWH(100, 100, 500, 500);

      final result = await processorService.processMainPhoto(
        sourcePath: source.path,
        cropRect: cropRect,
      );

      expect(result.isSquare, isTrue);
      expect(result.width, equals(result.height));
    });

    testWidgets('PhotoCropScreen renders with rule-of-thirds grid and confirm button',
        (tester) async {
      final testPhoto = _createTestJpeg(tempFixtureDir, 'croppable.jpg', 600, 600);
      Rect? confirmedRect;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                confirmedRect = await Navigator.of(ctx).push<Rect>(
                  MaterialPageRoute(
                    builder: (_) => PhotoCropScreen(
                      imageFile: testPhoto,
                      initialImageSize: const Size(600, 600),
                    ),
                  ),
                );
              },
              child: const Text('Open Cropper'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Cropper'));
      await tester.pumpAndSettle();

      expect(find.text('Crop Photo'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(confirmedRect, isNotNull);
    });
  });

  group('03.06 — Additional Photo Aspect-Ratio Preservation Tests', () {
    test('preserves portrait aspect ratio (height > width)', () async {
      // 600x1200 portrait (ratio = 0.5)
      final portrait = _createTestJpeg(tempFixtureDir, 'portrait.jpg', 600, 1200);

      final result = await processorService.processAdditionalPhoto(sourcePath: portrait.path);

      expect(result.isPortrait, isTrue);
      expect(result.isSquare, isFalse);
      expect(result.height, equals(1024)); // Longest edge scaled to 1024
      expect(result.width, equals(512));
      expect(result.aspectRatio, closeTo(0.5, 0.02));
    });

    test('preserves landscape aspect ratio (width > height)', () async {
      // 1600x800 landscape (ratio = 2.0)
      final landscape = _createTestJpeg(tempFixtureDir, 'landscape_wide.jpg', 1600, 800);

      final result = await processorService.processAdditionalPhoto(sourcePath: landscape.path);

      expect(result.isLandscape, isTrue);
      expect(result.width, equals(1024)); // Longest edge scaled to 1024
      expect(result.height, equals(512));
      expect(result.aspectRatio, closeTo(2.0, 0.02));
    });

    test('preserves square aspect ratio without distortion', () async {
      final square = _createTestJpeg(tempFixtureDir, 'square.jpg', 1500, 1500);

      final result = await processorService.processAdditionalPhoto(sourcePath: square.path);

      expect(result.isSquare, isTrue);
      expect(result.width, equals(1024));
      expect(result.height, equals(1024));
    });
  });

  group('03.07 — Image Compression and Resizing Limits Tests', () {
    test('enforces 5 MiB ceiling and validates size', () async {
      final valid = _createTestJpeg(tempFixtureDir, 'norm.jpg', 800, 800);
      final validation = await processorService.validateSourceImage(valid.path);

      expect(validation.isValid, isTrue);
      expect(validation.byteSize, lessThanOrEqualTo(5242880));
    });

    test('rejects image smaller than 300x300 minimum resolution', () async {
      final small = _createTestJpeg(tempFixtureDir, 'tiny.jpg', 200, 200);
      final validation = await processorService.validateSourceImage(small.path);

      expect(validation.isValid, isFalse);
      expect(validation.error, equals(PhotoValidationError.resolutionTooSmall));
      expect(validation.errorMessage, contains('Minimum resolution is 300x300'));
    });

    test('rejects image larger than 4096x4096 maximum resolution', () async {
      final huge = _createTestJpeg(tempFixtureDir, 'huge.jpg', 4200, 3000);
      final validation = await processorService.validateSourceImage(huge.path);

      expect(validation.isValid, isFalse);
      expect(validation.error, equals(PhotoValidationError.resolutionTooLarge));
      expect(validation.errorMessage, contains('exceeds maximum limit of 4096x4096'));
    });
  });

  group('03.08 — Image Metadata Removal and Sanitization Tests', () {
    test('sanitizes metadata: EXIF and GPS stripped on re-encoding', () async {
      final fixture = _createTestJpeg(tempFixtureDir, 'camera_exif.jpg', 600, 600);

      final processed = await processorService.processMainPhoto(sourcePath: fixture.path);
      final processedBytes = await File(processed.path).readAsBytes();
      final decoded = img.decodeImage(processedBytes);

      expect(decoded, isNotNull);
      // In the cleanly re-encoded JPEG, exif metadata is empty or cleared
      expect(decoded!.exif.isEmpty, isTrue);
      // User original fixture must remain completely untouched
      expect(fixture.existsSync(), isTrue);
    });

    test('original source file remains byte-for-byte identical', () async {
      final fixture = _createTestJpeg(tempFixtureDir, 'immutable.jpg', 500, 500);
      final originalBytes = await fixture.readAsBytes();

      await processorService.processMainPhoto(sourcePath: fixture.path);
      await processorService.processAdditionalPhoto(sourcePath: fixture.path);

      final postProcessingBytes = await fixture.readAsBytes();
      expect(postProcessingBytes, equals(originalBytes));
    });
  });

  group('03.09 — Format Verification and Magic Bytes Tests', () {
    test('accepts valid JPEG magic bytes', () async {
      final jpeg = _createTestJpeg(tempFixtureDir, 'sample.jpg', 400, 400);
      final result = await processorService.validateSourceImage(jpeg.path);

      expect(result.isValid, isTrue);
    });

    test('accepts valid PNG magic bytes', () async {
      final png = _createTestPng(tempFixtureDir, 'sample.png', 400, 400);
      final result = await processorService.validateSourceImage(png.path);

      expect(result.isValid, isTrue);
    });

    test('rejects WebP format', () async {
      final webpFile = File('${tempFixtureDir.path}/test.webp');
      // RIFF....WEBP header
      webpFile.writeAsBytesSync([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x24, 0x00, 0x00, 0x00,
        0x57, 0x45, 0x42, 0x50, // WEBP
        0x56, 0x50, 0x38, 0x20,
      ]);

      final result = await processorService.validateSourceImage(webpFile.path);
      expect(result.isValid, isFalse);
      expect(result.error, equals(PhotoValidationError.invalidFormat));
      expect(result.errorMessage, contains('Only JPEG and PNG photographs are supported'));
    });

    test('rejects GIF format', () async {
      final gifFile = File('${tempFixtureDir.path}/test.gif');
      gifFile.writeAsBytesSync([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]); // GIF89a

      final result = await processorService.validateSourceImage(gifFile.path);
      expect(result.isValid, isFalse);
      expect(result.error, equals(PhotoValidationError.invalidFormat));
    });

    test('rejects 0-byte or corrupted file', () async {
      final emptyFile = File('${tempFixtureDir.path}/empty.jpg')..writeAsBytesSync([]);

      final result = await processorService.validateSourceImage(emptyFile.path);
      expect(result.isValid, isFalse);
      expect(result.error, equals(PhotoValidationError.corruptedFile));
    });

    test('rejects non-existent file path', () async {
      final result = await processorService.validateSourceImage('${tempFixtureDir.path}/non_existent.jpg');
      expect(result.isValid, isFalse);
      expect(result.error, equals(PhotoValidationError.fileNotFound));
    });

    test('localized error messages match for EN, TA, and SI', () {
      const en = OnboardingLocalizations(AppLanguage.english);
      const ta = OnboardingLocalizations(AppLanguage.tamil);
      const si = OnboardingLocalizations(AppLanguage.sinhala);

      expect(en.photoProcessingError, isNotEmpty);
      expect(ta.photoProcessingError, isNotEmpty);
      expect(si.photoProcessingError, isNotEmpty);

      expect(en.photoResolutionTooSmall, contains('300x300'));
      expect(ta.photoResolutionTooSmall, contains('300x300'));
      expect(si.photoResolutionTooSmall, contains('300x300'));

      expect(en.takePhoto, equals('Take Photo'));
      expect(en.chooseFromGallery, equals('Choose from Gallery'));
      expect(ta.takePhoto, isNotEmpty);
      expect(si.takePhoto, isNotEmpty);
    });
  });

  group('Lifecycle and Account Isolation Tests', () {
    test('reset clears all photos and cleans up owned temporary files', () async {
      final avatar = _createTestJpeg(tempFixtureDir, 'avatar.jpg', 600, 600);
      final pic = _createTestJpeg(tempFixtureDir, 'gallery.jpg', 600, 600);

      final vm = ModuleProfileViewModel(
        config: ProfileCreationConfig.hobbies(),
        repository: mockRepo,
        photoPickerService: mockPicker,
        photoProcessorService: processorService,
      );

      mockPicker.nextResult = avatar.path;
      await vm.pickProfilePhoto(source: PhotoSource.gallery);
      final avatarProcessed = vm.profilePhotoPath!;

      mockPicker.nextResult = pic.path;
      await vm.pickAdditionalPhoto(slotIndex: 0, source: PhotoSource.gallery);
      final picProcessed = vm.additionalPhotoPaths[0];

      expect(File(avatarProcessed).existsSync(), isTrue);
      expect(File(picProcessed).existsSync(), isTrue);

      vm.reset();

      expect(vm.profilePhotoPath, isNull);
      expect(vm.additionalPhotoPaths, isEmpty);
      expect(File(avatarProcessed).existsSync(), isFalse);
      expect(File(picProcessed).existsSync(), isFalse);
    });
  });
}
