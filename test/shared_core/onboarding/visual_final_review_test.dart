import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/shared_core/authentication/password_recovery/screens/password_reset_screen.dart';
import 'package:andril_mobile/shared_core/module_activation/presentation/screens/starter_module_selection_screen.dart';
import 'package:andril_mobile/shared_core/privacy/screens/eligibility_policies_screen.dart';
import '../authentication/test_doubles/mock_auth_repository.dart';
import '../module_activation/test_doubles/mock_starter_module_repository.dart';
import '../privacy/test_doubles/mock_eligibility_repository.dart';

void main() {
  Future<void> captureFinalScreenshot({
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

  group('Visual Review Screenshot Captures - Screens 08, 09, 10', () {
    testWidgets('captures rendered Screen 08 Password Reset', (tester) async {
      final authRepo = MockAuthRepository(hasActiveRecovery: true);
      await captureFinalScreenshot(
        tester: tester,
        widget: PasswordResetScreen(
          authRepository: authRepo,
          recoveryToken: 'valid-test-token',
        ),
        fileName: 'rendered_screen_08_password_reset.png',
      );
    });

    testWidgets('captures rendered Screen 09 Eligibility & Policies',
        (tester) async {
      final eligRepo = MockEligibilityRepository();
      await captureFinalScreenshot(
        tester: tester,
        widget: EligibilityPoliciesScreen(repository: eligRepo),
        fileName: 'rendered_screen_09_eligibility.png',
      );
    });

    testWidgets('captures rendered Screen 10 Starter Module Selection',
        (tester) async {
      final moduleRepo = MockStarterModuleRepository();
      await captureFinalScreenshot(
        tester: tester,
        widget: StarterModuleSelectionScreen(repository: moduleRepo),
        fileName: 'rendered_screen_10_starter_modules.png',
      );
    });
  });
}
