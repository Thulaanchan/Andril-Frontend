import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:andril_mobile/shared_core/language_selection/data/repositories/shared_prefs_language_preference_repository.dart';
import 'package:andril_mobile/shared_core/language_selection/screens/choose_language_screen.dart';
import 'package:andril_mobile/shared_core/language_selection/viewmodels/language_selection_viewmodel.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/splash_screen.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/screens/welcome_screen.dart';
import 'package:andril_mobile/shared_core/onboarding/presentation/viewmodels/splash_viewmodel.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> captureWidgetScreenshot({
    required WidgetTester tester,
    required Widget widget,
    required String fileName,
  }) async {
    final repaintKey = GlobalKey();
    tester.view.physicalSize = const Size(412 * 2.0, 892 * 2.0);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      RepaintBoundary(
        key: repaintKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: widget,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      final element = repaintKey.currentContext!;
      await precacheImage(
        const AssetImage('assets/branding/andril_black_logo.png'),
        element,
      );
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.runAsync(() async {
      final boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final outputDirPath = Platform.environment['VISUAL_REVIEW_DIR'];
        if (outputDirPath != null && outputDirPath.isNotEmpty) {
          final dir = Directory(outputDirPath);
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          File('${dir.path}/$fileName')
              .writeAsBytesSync(byteData.buffer.asUint8List());
        }
      }
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  group('Visual Review Screenshot Captures', () {
    testWidgets('captures rendered Screen 01 Splash Screen', (tester) async {
      final vm = SplashViewModel(splashDuration: const Duration(hours: 10));
      await captureWidgetScreenshot(
        tester: tester,
        widget: SplashScreen(
          viewModel: vm,
        ),
        fileName: 'rendered_screen_01_splash.png',
      );
      vm.dispose();
    });

    testWidgets('captures rendered Screen 02 Choose Your Language',
        (tester) async {
      final repository = SharedPrefsLanguagePreferenceRepository();
      final viewModel = LanguageSelectionViewModel(repository: repository);
      await viewModel.loadSavedLanguage();

      await captureWidgetScreenshot(
        tester: tester,
        widget: ChooseLanguageScreen(
          viewModel: viewModel,
        ),
        fileName: 'rendered_screen_02_language.png',
      );
      viewModel.dispose();
    });

    testWidgets('captures rendered Screen 03 Welcome to Andril',
        (tester) async {
      await captureWidgetScreenshot(
        tester: tester,
        widget: const WelcomeScreen(),
        fileName: 'rendered_screen_03_welcome.png',
      );
    });
  });
}
