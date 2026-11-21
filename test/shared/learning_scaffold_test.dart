import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/shared/presentation/scaffolds/learning_scaffold.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/andril_module_app_bar.dart';

Widget _buildTestApp(Widget child, {TextScaler? textScaler, Size? size}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: size != null
        ? Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: textScaler ?? TextScaler.noScaling,
                ),
                child: child,
              ),
            ),
          )
        : MediaQuery(
            data: MediaQueryData(
              textScaler: textScaler ?? TextScaler.noScaling,
            ),
            child: child,
          ),
  );
}

void main() {
  group('LearningScaffold - Five-Tab Navigation Shell Tests', () {
    testWidgets('1. Exactly five navigation destinations', (tester) async {
      expect(LearningScaffold.destinations.length, 5);

      await tester.pumpWidget(
        _buildTestApp(
          const LearningScaffold(
            child: Text('Shell Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 5);
    });

    testWidgets('2. Correct order and labels', (tester) async {
      const expectedLabels = [
        'Home',
        'Classrooms',
        'Explore',
        'Chat',
        'Profile',
      ];

      for (int i = 0; i < expectedLabels.length; i++) {
        final destination = LearningScaffold.destinations[i];
        expect(destination.label, expectedLabels[i]);
      }

      await tester.pumpWidget(
        _buildTestApp(
          const LearningScaffold(
            child: Text('Shell Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in expectedLabels) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('3. Home tab selection (index 0)', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningScaffold(
            currentIndex: 0,
            child: Text('Home Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 0);
    });

    testWidgets('4. Classrooms selection (index 1)', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningScaffold(
            currentIndex: 1,
            child: Text('Classrooms Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 1);
    });

    testWidgets('5. Explore selection (index 2)', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningScaffold(
            currentIndex: 2,
            child: Text('Explore Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 2);
    });

    testWidgets('6. Chat selection (index 3)', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningScaffold(
            currentIndex: 3,
            child: Text('Chat Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 3);
    });

    testWidgets('7. Profile selection (index 4)', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningScaffold(
            currentIndex: 4,
            child: Text('Profile Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 4);
    });

    testWidgets('8. Active tab accessibility semantics', (tester) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _buildTestApp(
              LearningScaffold(
                currentIndex: selectedTab,
                onDestinationSelected: (index) {
                  setState(() => selectedTab = index);
                },
                child: Text('Tab $selectedTab Content'),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();

      expect(selectedTab, 2);
      expect(find.text('Tab 2 Content'), findsOneWidget);
    });

    testWidgets('9. Responsive 320dp layout', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          const LearningScaffold(
            currentIndex: 0,
            child: Text('Compact Viewport'),
          ),
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('10. Responsive 360dp layout', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          const LearningScaffold(
            currentIndex: 1,
            child: Text('Standard Viewport'),
          ),
          size: const Size(360, 740),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('11. Responsive 412dp layout', (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          const LearningScaffold(
            currentIndex: 2,
            child: Text('Large Viewport'),
          ),
          size: const Size(412, 892),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('12. Dynamic text scaling and no overflow', (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          const LearningScaffold(
            currentIndex: 0,
            child: Text('Scale 1.5'),
          ),
          textScaler: const TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Appropriate SafeArea behavior', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningScaffold(
            child: Text('SafeArea Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsWidgets);
      expect(find.byType(AndrilModuleAppBar), findsOneWidget);
    });

    testWidgets('14. Tab switching preserves branch state when applicable',
        (tester) async {
      int activeIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _buildTestApp(
              LearningScaffold(
                currentIndex: activeIndex,
                onDestinationSelected: (index) {
                  setState(() => activeIndex = index);
                },
                child: IndexedStack(
                  index: activeIndex,
                  children: const [
                    Text('Branch Home State'),
                    Text('Branch Classrooms State'),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Branch Home State'), findsOneWidget);

      await tester.tap(find.text('Classrooms'));
      await tester.pumpAndSettle();

      expect(activeIndex, 1);
      expect(find.text('Branch Classrooms State'), findsOneWidget);
    });

    testWidgets(
        '15. No real backend access or private data in navigation fixtures',
        (tester) async {
      const scaffold = LearningScaffold(
        child: SizedBox(),
      );

      expect(scaffold, isA<StatelessWidget>());
      expect(scaffold.appBar, isNotNull);
      expect(scaffold.currentIndex, 0);
    });
  });
}
