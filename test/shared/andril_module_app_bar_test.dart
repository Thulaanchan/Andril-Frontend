import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/andril_module_app_bar.dart';

Widget _buildTestApp(Widget child, {TextScaler? textScaler, Size? size}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Scaffold(
      appBar: child is PreferredSizeWidget ? child : null,
      body: child is! PreferredSizeWidget
          ? Center(
              child: SizedBox(
                width: size?.width ?? 360,
                height: size?.height ?? 640,
                child: MediaQuery(
                  data: MediaQueryData(
                    size: size ?? const Size(360, 640),
                    textScaler: textScaler ?? TextScaler.noScaling,
                  ),
                  child: child,
                ),
              ),
            )
          : null,
    ),
  );
}

void main() {
  group('AndrilModuleAppBar Tests', () {
    testWidgets('1. Official existing logo rendered via AssetImage',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AndrilModuleAppBar(),
        ),
      );
      await tester.pumpAndSettle();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<AssetImage>());
      expect(
        (imageWidget.image as AssetImage).assetName,
        'assets/branding/andril_black_logo.png',
      );
    });

    testWidgets('2. Learning badge displays "Learning" with #2563EB background',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AndrilModuleAppBar(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning'), findsOneWidget);

      final badgeContainerFinder = find.ancestor(
        of: find.text('Learning'),
        matching: find.byType(Container),
      );
      expect(badgeContainerFinder, findsOneWidget);

      final Container container =
          tester.widget<Container>(badgeContainerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.color, LearningColors.primary);
      expect(decoration.color, const Color(0xFF2563EB));
    });

    testWidgets('3. Search action renders when onSearchTap provided',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          AndrilModuleAppBar(
            onSearchTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });

    testWidgets(
        '4. Notification action renders when onNotificationTap provided',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          AndrilModuleAppBar(
            onNotificationTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNothing);
    });

    testWidgets('5. Callbacks trigger only when tapped', (tester) async {
      int searchTaps = 0;
      int notificationTaps = 0;

      await tester.pumpWidget(
        _buildTestApp(
          AndrilModuleAppBar(
            onSearchTap: () => searchTaps++,
            onNotificationTap: () => notificationTaps++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(searchTaps, 0);
      expect(notificationTaps, 0);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(searchTaps, 1);
      expect(notificationTaps, 0);

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      expect(searchTaps, 1);
      expect(notificationTaps, 1);
    });

    testWidgets('6. Omitted actions not rendered', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AndrilModuleAppBar(
            onSearchTap: null,
            onNotificationTap: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });

    testWidgets('7. 320dp viewport has no layout overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          AndrilModuleAppBar(
            onSearchTap: () {},
            onNotificationTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AndrilModuleAppBar), findsOneWidget);
    });

    testWidgets('8. 412dp viewport has no layout overflow', (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          AndrilModuleAppBar(
            onSearchTap: () {},
            onNotificationTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AndrilModuleAppBar), findsOneWidget);
    });

    testWidgets(
        '9. Text scaling (TextScaler.linear(1.5)) and accessibility semantics work',
        (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: LearningTheme.theme,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              appBar: AndrilModuleAppBar(
                onSearchTap: () {},
                onNotificationTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsLabel('Search Learning'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Notifications'),
        findsOneWidget,
      );
    });

    testWidgets('10. Component is stateless and accesses no private data',
        (tester) async {
      const appBar = AndrilModuleAppBar();
      expect(appBar, isA<StatelessWidget>());
      expect(appBar.preferredSize.height, kToolbarHeight);
      expect(appBar.moduleName, 'Learning');
      expect(appBar.badgeColor, LearningColors.primary);
      expect(appBar.logoAssetPath, 'assets/branding/andril_black_logo.png');
    });
  });
}
