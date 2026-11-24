import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_doubles/mock_auth_repository.dart';
import 'package:andril_mobile/shared_core/authentication/login/screens/login_screen.dart';
import 'package:andril_mobile/shared_core/authentication/password_recovery/screens/password_recovery_screen.dart';
import 'package:andril_mobile/shared_core/authentication/registration/screens/registration_screen.dart';
import 'package:andril_mobile/shared_core/authentication/verification/screens/account_verification_screen.dart';

void main() {
  Future<void> captureAuthScreenshot({
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

  group('Visual Review Screenshot Captures - Feature 02', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
    });

    testWidgets('captures rendered Screen 04 Email Registration',
        (tester) async {
      await captureAuthScreenshot(
        tester: tester,
        widget: RegistrationScreen(authRepository: repo),
        fileName: 'rendered_screen_04_registration.png',
      );
    });

    testWidgets('captures rendered Screen 05 Account Verification',
        (tester) async {
      await captureAuthScreenshot(
        tester: tester,
        widget: AccountVerificationScreen(
          email: 'student@andril.app',
          authRepository: repo,
        ),
        fileName: 'rendered_screen_05_verification.png',
      );
    });

    testWidgets('captures rendered Screen 06 Login and Google Sign-In',
        (tester) async {
      await captureAuthScreenshot(
        tester: tester,
        widget: LoginScreen(authRepository: repo),
        fileName: 'rendered_screen_06_login.png',
      );
    });

    testWidgets('captures rendered Screen 07 Password Recovery Request',
        (tester) async {
      await captureAuthScreenshot(
        tester: tester,
        widget: PasswordRecoveryScreen(authRepository: repo),
        fileName: 'rendered_screen_07_recovery.png',
      );
    });
  });
}
