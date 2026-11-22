import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/themes/learning/learning_theme.dart';
import 'package:andril_mobile/features/learning/profile/widgets/learning_preferences_draft_widget.dart';

Widget _buildTestApp(
  Widget child, {
  Size? size,
  TextScaler? textScaler,
}) {
  return MaterialApp(
    theme: LearningTheme.theme,
    home: Scaffold(
      body: size != null
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
    ),
  );
}

void main() {
  group('LearningPreferencesDraftWidget Component Tests (Q07 Draft)', () {
    // 1. Renders all approved draft sections
    testWidgets('1. Renders all approved draft sections', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set Your Learning Preferences'), findsOneWidget);
      expect(find.byKey(const Key('preferences_draft_disclaimer')),
          findsOneWidget);
      expect(find.byKey(const Key('preferences_language_section_title')),
          findsOneWidget);
      expect(find.byKey(const Key('preferences_style_section_title')),
          findsOneWidget);
      expect(find.byKey(const Key('preferences_availability_section_title')),
          findsOneWidget);
      expect(find.byKey(const Key('preferences_notifications_section_title')),
          findsOneWidget);
    });

    // 2. Injected language options render correctly
    testWidgets('2. Injected language options render correctly',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(
            availableLanguages: ['English', 'Tamil', 'French'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('language_chip_English')), findsOneWidget);
      expect(find.byKey(const Key('language_chip_Tamil')), findsOneWidget);
      expect(find.byKey(const Key('language_chip_French')), findsOneWidget);
      expect(find.byKey(const Key('language_chip_Tanglish')), findsNothing);
    });

    // 3. Language selection works
    testWidgets('3. Language selection toggles properly and triggers callback',
        (tester) async {
      List<String> selected = [];

      await tester.pumpWidget(
        _buildTestApp(
          LearningPreferencesDraftWidget(
            onLanguagesChanged: (langs) => selected = langs,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Tamil
      final tamilChip = find.byKey(const Key('language_chip_Tamil'));
      await tester.tap(tamilChip);
      await tester.pumpAndSettle();

      expect(selected, contains('Tamil'));

      // Tap English
      final englishChip = find.byKey(const Key('language_chip_English'));
      await tester.tap(englishChip);
      await tester.pumpAndSettle();

      expect(selected, containsAll(['Tamil', 'English']));

      // Untap Tamil
      await tester.tap(tamilChip);
      await tester.pumpAndSettle();

      expect(selected, isNot(contains('Tamil')));
      expect(selected, contains('English'));
    });

    // 4. Learning style selection works
    testWidgets('4. Learning style multi-selection works and triggers callback',
        (tester) async {
      List<String> selected = [];

      await tester.pumpWidget(
        _buildTestApp(
          LearningPreferencesDraftWidget(
            onLearningStylesChanged: (styles) => selected = styles,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final videoCard =
          find.byKey(const Key('learning_style_card_Video Learning'));
      await tester.tap(videoCard);
      await tester.pumpAndSettle();

      expect(selected, contains('Video Learning'));

      final practiceCard =
          find.byKey(const Key('learning_style_card_Hands-on Practice'));
      await tester.tap(practiceCard);
      await tester.pumpAndSettle();

      expect(selected, containsAll(['Video Learning', 'Hands-on Practice']));
    });

    // 5. Availability remains optional
    testWidgets('5. Availability selection is optional and toggleable',
        (tester) async {
      String? selectedAvail;

      await tester.pumpWidget(
        _buildTestApp(
          LearningPreferencesDraftWidget(
            onAvailabilityChanged: (avail) => selectedAvail = avail,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts unselected (null)
      expect(selectedAvail, isNull);

      final morningCard =
          find.byKey(const Key('availability_card_Morning (6 AM – 12 PM)'));
      await tester.ensureVisible(morningCard);
      await tester.pumpAndSettle();
      await tester.tap(morningCard);
      await tester.pumpAndSettle();

      expect(selectedAvail, 'Morning (6 AM – 12 PM)');

      // Tapping again deselects to null
      await tester.tap(morningCard);
      await tester.pumpAndSettle();

      expect(selectedAvail, isNull);
    });

    // 6. Notification toggles stay local to the draft
    testWidgets('6. Notification toggles stay local to draft state',
        (tester) async {
      Map<String, bool> notifs = {};

      await tester.pumpWidget(
        _buildTestApp(
          LearningPreferencesDraftWidget(
            onNotificationsChanged: (map) => notifs = map,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder =
          find.byKey(const Key('notification_switch_Connection requests'));
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(notifs['Connection requests'], isTrue);
    });

    // 7. No unsupported mandatory policy is enforced
    testWidgets('7. No unsupported mandatory policy blocks draft interaction',
        (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        _buildTestApp(
          LearningPreferencesDraftWidget(
            onComplete: () => completed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final completeBtn = find.byKey(const Key('preferences_complete_button'));
      await tester.ensureVisible(completeBtn);
      await tester.pumpAndSettle();
      await tester.tap(completeBtn);
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    // 8. No duplicate selections
    testWidgets('8. No duplicate selections created in sets', (tester) async {
      List<String> langs = [];

      await tester.pumpWidget(
        _buildTestApp(
          LearningPreferencesDraftWidget(
            initialLanguages: const ['Tamil'],
            onLanguagesChanged: (list) => langs = list,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial shows Tamil
      final tamilChip = find.byKey(const Key('language_chip_Tamil'));
      expect(tamilChip, findsOneWidget);

      // Untap and re-tap
      await tester.tap(tamilChip);
      await tester.pumpAndSettle();
      await tester.tap(tamilChip);
      await tester.pumpAndSettle();

      expect(langs.where((e) => e == 'Tamil').length, 1);
    });

    // 9. Change callbacks receive accurate selections
    testWidgets('9. Change callbacks receive accurate updated data',
        (tester) async {
      List<String> capturedStyles = [];

      await tester.pumpWidget(
        _buildTestApp(
          LearningPreferencesDraftWidget(
            onLearningStylesChanged: (s) => capturedStyles = s,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final miniProjectsCard =
          find.byKey(const Key('learning_style_card_Mini Projects'));
      await tester.ensureVisible(miniProjectsCard);
      await tester.pumpAndSettle();
      await tester.tap(miniProjectsCard);
      await tester.pumpAndSettle();

      expect(capturedStyles, ['Mini Projects']);
    });

    // 10. Initial draft selections render
    testWidgets('10. Initial draft selections render properly', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(
            initialLanguages: ['Tamil', 'English'],
            initialLearningStyles: ['Video Learning'],
            initialAvailability: 'Flexible (Any time)',
            initialNotifications: {'Connection requests': true},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final filterChip = tester.widget<FilterChip>(
        find.byKey(const Key('language_chip_Tamil')),
      );
      expect(filterChip.selected, isTrue);

      final styleCard =
          find.byKey(const Key('learning_style_card_Video Learning'));
      expect(styleCard, findsOneWidget);

      final availCard =
          find.byKey(const Key('availability_card_Flexible (Any time)'));
      await tester.ensureVisible(availCard);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
    });

    // 11. Empty selections render safely
    testWidgets('11. Empty selections render without crashing', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(
            initialLanguages: [],
            initialLearningStyles: [],
            initialAvailability: null,
            initialNotifications: {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set Your Learning Preferences'), findsOneWidget);
    });

    // 12. Missing option catalogue is handled
    testWidgets('12. Missing empty catalogues render fallback message',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(
            availableLanguages: [],
            availableLearningStyles: [],
            availableAvailabilities: [],
            availableNotifications: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No language options available.'), findsOneWidget);
      expect(find.text('No learning styles available.'), findsOneWidget);
      expect(find.text('No availability options available.'), findsOneWidget);
      expect(find.text('No notification options available.'), findsOneWidget);
    });

    // 13. Tamil and Unicode labels are preserved
    testWidgets('13. Tamil and Unicode labels are preserved correctly',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(
            availableLanguages: ['தமிழ்', 'English', 'சிங்களம்'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('தமிழ்'), findsOneWidget);
      expect(find.text('சிங்களம்'), findsOneWidget);
    });

    // 14. 320dp has no overflow
    testWidgets('14. 320dp width without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(),
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // 15. 360dp has no overflow
    testWidgets('15. 360dp width without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(),
          size: const Size(360, 740),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // 16. 412dp has no overflow
    testWidgets('16. 412dp width without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(),
          size: const Size(412, 892),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // 17. 1.5x scaling works
    testWidgets('17. 1.5x text scaling renders without error', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(),
          textScaler: const TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // 18. Screen-reader semantics identify control states
    testWidgets('18. Screen-reader semantics identify control states',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(
            initialLanguages: ['English'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            (w.properties.label ?? '').contains('Language option: English')),
        findsOneWidget,
      );
    });

    // 19. No success or server persistence claim appears
    testWidgets('19. No server persistence or activation claim appears',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Preferences Saved to Server'), findsNothing);
      expect(find.text('Module Activated'), findsNothing);
      expect(find.text('Push Notifications Registered'), findsNothing);
    });

    // 20. No account IDs, JWTs or other module-profile data appear
    testWidgets('20. No account IDs, JWTs or private data exposed',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const LearningPreferencesDraftWidget(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('accountId'), findsNothing);
      expect(find.textContaining('profileId'), findsNothing);
      expect(find.textContaining('eyJ'), findsNothing);
      expect(find.textContaining('Bearer'), findsNothing);
    });
  });
}
